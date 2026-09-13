#!/usr/bin/env python3
"""Rebuild the hand-authored Dashmaru GLB, using only Python's standard library.

Y is up, +Z is the face, metres are arbitrary (height 3.04). The source is a
parametric sculpture based on the supplied three-view and 3D reference pictures;
no reference image is embedded. Every marking follows the curved body surface.
Run: python3 tool/build_dashmaru.py
"""

import json
import math
import struct
from pathlib import Path

PI = math.pi
sin, cos, sqrt = math.sin, math.cos, math.sqrt
OUT = Path(__file__).resolve().parents[1] / "assets" / "models"


def vadd(a, b):
    return tuple(x + y for x, y in zip(a, b))


def vsub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def unit(v):
    length = sqrt(sum(x * x for x in v))
    return tuple(x / max(length, 1e-12) for x in v)


def normals(vertices, faces):
    result = [[0.0, 0.0, 0.0] for _ in vertices]
    for a, b, c in faces:
        n = cross(vsub(vertices[b], vertices[a]), vsub(vertices[c], vertices[a]))
        for i in (a, b, c):
            for j in range(3):
                result[i][j] += n[j]
    return [unit(n) for n in result]


class Glb:
    def __init__(self):
        self.data = bytearray()
        self.doc = {
            "asset": {
                "version": "2.0",
                "generator": "Dashmaru parametric sculpture / Python",
                "copyright": "Dashmaru character: FlutterKaigi. Reference-based fan model for FlutterKaigi mini.",
            },
            "scene": 0,
            "scenes": [{"name": "Dashmaru", "nodes": [0]}],
            "nodes": [],
            "meshes": [],
            "materials": [],
            "animations": [],
            "accessors": [],
            "bufferViews": [],
            "buffers": [],
        }
        self.node("Dashmaru")

    def accessor(self, values, kind, component=5126, target=None):
        while len(self.data) % 4:
            self.data.append(0)
        start = len(self.data)
        scalar = kind == "SCALAR"
        rows = [(x,) for x in values] if scalar else values
        flat = [v for row in rows for v in row]
        self.data.extend(
            struct.pack(
                "<" + {5126: "f", 5125: "I", 5123: "H"}[component] * len(flat), *flat
            )
        )
        view = {"buffer": 0, "byteOffset": start, "byteLength": len(self.data) - start}
        if target:
            view["target"] = target
        self.doc["bufferViews"].append(view)
        acc = {
            "bufferView": len(self.doc["bufferViews"]) - 1,
            "componentType": component,
            "count": len(values),
            "type": kind,
            "min": [min(row[j] for row in rows) for j in range(len(rows[0]))],
            "max": [max(row[j] for row in rows) for j in range(len(rows[0]))],
        }
        self.doc["accessors"].append(acc)
        return len(self.doc["accessors"]) - 1

    def material(self, name, rgb, roughness=0.85):
        # glTF factors are linear, whereas the reference palette is sRGB.
        color = [
            ((c / 255 + 0.055) / 1.055) ** 2.4 if c > 10 else c / 255 / 12.92
            for c in rgb
        ]
        self.doc["materials"].append(
            {
                "name": name,
                "pbrMetallicRoughness": {
                    "baseColorFactor": color + [1],
                    "metallicFactor": 0,
                    "roughnessFactor": roughness,
                },
                "doubleSided": True,
            }
        )
        return len(self.doc["materials"]) - 1

    def node(self, name, parent=None, translation=None, mesh=None):
        node = {"name": name}
        if translation is not None:
            node["translation"] = list(translation)
        if mesh is not None:
            node["mesh"] = mesh
        idx = len(self.doc["nodes"])
        self.doc["nodes"].append(node)
        if parent is not None:
            self.doc["nodes"][parent].setdefault("children", []).append(idx)
        return idx

    def mesh(
        self, name, vertices, faces, material, parent=0, translation=None, weights=None
    ):
        # Weld the two sides of feathers, poles and tube seams before averaging
        # normals. Extra tessellation alone cannot fix split shading at a seam.
        unique, remap, lookup = [], [], {}
        for vertex in vertices:
            key = tuple(round(value, 8) for value in vertex)
            if key not in lookup:
                lookup[key] = len(unique)
                unique.append(vertex)
            remap.append(lookup[key])
        faces = [tuple(remap[i] for i in face) for face in faces]
        faces = [face for face in faces if len(set(face)) == 3]
        vertices = unique
        if parent == 0:
            weights = weights or body_weights
            vertices = [vadd(v, translation or (0, 0, 0)) for v in vertices]
            translation = None
        attrs = {
            "POSITION": self.accessor(vertices, "VEC3", target=34962),
            "NORMAL": self.accessor(normals(vertices, faces), "VEC3", target=34962),
        }
        if weights:
            influences = [[(n, w) for n, w in weights(v) if w > 0] for v in vertices]
            attrs["JOINTS_0"] = self.accessor(
                [
                    tuple(joints.index(n) for n, _ in row) + (0,) * (4 - len(row))
                    for row in influences
                ],
                "VEC4",
                5123,
                34962,
            )
            attrs["WEIGHTS_0"] = self.accessor(
                [
                    tuple(w for _, w in row) + (0,) * (4 - len(row))
                    for row in influences
                ],
                "VEC4",
                target=34962,
            )
        indices = self.accessor(
            [i for face in faces for i in face], "SCALAR", 5125, 34963
        )
        self.doc["meshes"].append(
            {
                "name": name,
                "primitives": [
                    {"attributes": attrs, "indices": indices, "material": material}
                ],
            }
        )
        node = self.node(name, parent, translation, len(self.doc["meshes"]) - 1)
        if weights:
            self.doc["nodes"][node]["skin"] = 0
            # Skin matrices already include the skeleton root transform. Keep
            # mesh nodes at scene root, as required by portable glTF skinning.
            self.doc["nodes"][parent]["children"].remove(node)
            self.doc["scenes"][0]["nodes"].append(node)
        return node

    def clip(self, name, tracks):
        samplers, channels = [], []
        for node, path, times, values in tracks:
            samplers.append(
                {
                    "input": self.accessor(times, "SCALAR"),
                    "output": self.accessor(
                        values, "VEC4" if path == "rotation" else "VEC3"
                    ),
                    "interpolation": "LINEAR",
                }
            )
            channels.append(
                {"sampler": len(samplers) - 1, "target": {"node": node, "path": path}}
            )
        self.doc["animations"].append(
            {"name": name, "samplers": samplers, "channels": channels}
        )

    def save(self):
        self.doc["buffers"] = [{"byteLength": len(self.data)}]
        encoded = json.dumps(self.doc, separators=(",", ":")).encode()
        encoded += b" " * (-len(encoded) % 4)
        self.data += b"\x00" * (-len(self.data) % 4)
        body = (
            struct.pack("<I4s", len(encoded), b"JSON")
            + encoded
            + struct.pack("<I4s", len(self.data), b"BIN\x00")
            + self.data
        )
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / "dashmaru.glb").write_bytes(
            struct.pack("<4sII", b"glTF", 2, 12 + len(body)) + body
        )
        summary = {
            "height": 3.04,
            "front": "+Z",
            "up": "+Y",
            "meshes": len(self.doc["meshes"]),
            "joints": len(joints),
            "rig": "Smooth weighted body, three-joint wings, two-bone IK legs",
            "triangles": sum(
                self.doc["accessors"][m["primitives"][0]["indices"]]["count"] // 3
                for m in self.doc["meshes"]
            ),
            "animations": [
                {"name": a["name"], "tracks": len(a["channels"])}
                for a in self.doc["animations"]
            ],
            "bytes": 12 + len(body),
        }
        (OUT / "dashmaru_manifest.json").write_text(
            json.dumps(summary, indent=2) + "\n"
        )
        print(json.dumps(summary, indent=2))


g = Glb()
MINT = g.material("Body | pale cyan #C8FCFE", (200, 252, 254))
BLUE = g.material("Feathers and Fuji | sky blue #68D8FB", (104, 216, 251))
INK = g.material("Embroidered outlines | black", (0, 0, 0))
WHITE = g.material("Snow, eyes and bib | white", (255, 255, 255))
RED = g.material("Japan badge | raspberry #E83568", (232, 53, 104))
BROWN = g.material("Beak and feet | warm brown #634936", (99, 73, 54))


def smooth(a, b, t):
    t = max(0, min(1, (t - a) / (b - a)))
    return t * t * (3 - 2 * t)


joints, bind_positions = [], {}


def bone(name, position, parent=0):
    node = g.node(name, parent, vsub(position, bind_positions.get(parent, (0, 0, 0))))
    joints.append(node)
    bind_positions[node] = position
    return node


hips = bone("Hips", (0, 0.68, 0))
torso = bone("Torso", (0, 1.20, 0), hips)
head = bone("Head", (0, 1.75, 0), torso)
wing_nodes, wing_bends, wing_tips, legs, knees, ankles = [], [], [], [], [], []
for side, sign in [("Left", -1), ("Right", 1)]:
    shoulder = bone(side + "Wing", (sign * 0.84, 2.00, 0), head)
    bend = bone(side + "WingBend", (sign * 1.00, 1.65, 0), shoulder)
    tip = bone(side + "WingTip", (sign * 1.03, 1.28, 0), bend)
    wing_nodes.append(shoulder)
    wing_bends.append(bend)
    wing_tips.append(tip)
    leg = bone(side + "Leg", (sign * 0.29, 0.64, 0.02))
    knee = bone(side + "Knee", (sign * 0.29, 0.405, 0.02), leg)
    ankle = bone(side + "Ankle", (sign * 0.29, 0.17, 0.02), knee)
    legs.append(leg)
    knees.append(knee)
    ankles.append(ankle)
tail = bone("Tail", (0, 0.94, -0.78), hips)

# All authored vertices use model-space bind coordinates. Eye parts are rigid
# children of Head so their tiny blink scales do not distort neighbouring skin.
inverse_binds = []
for node in joints:
    x, y, z = bind_positions[node]
    inverse_binds.append((1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -x, -y, -z, 1))
g.doc["skins"] = [
    {
        "name": "Dashmaru soft character rig",
        "skeleton": 0,
        "joints": joints,
        "inverseBindMatrices": g.accessor(inverse_binds, "MAT4"),
    }
]


def body_weights(v):
    y = v[1]
    upper = smooth(1.06, 1.47, y)
    lower = smooth(0.69, 1.10, y)
    return [
        (hips, (1 - upper) * (1 - lower)),
        (torso, (1 - upper) * lower),
        (head, upper),
    ]


def ellipsoid(name, center, radii, material, parent=0, segments=80, rings=48):
    vertices = []
    for j in range(rings + 1):
        lat = PI * j / rings
        for i in range(segments):
            a = 2 * PI * i / segments
            vertices.append(
                (
                    radii[0] * sin(lat) * cos(a),
                    radii[1] * cos(lat),
                    radii[2] * sin(lat) * sin(a),
                )
            )
    faces = []
    for j in range(rings):
        for i in range(segments):
            a = j * segments + i
            b = j * segments + (i + 1) % segments
            faces.extend([(a, b, a + segments), (b, b + segments, a + segments)])
    return g.mesh(name, vertices, faces, material, parent, center)


BODY_Y = 1.58
RX, RY, RZ = 1.0, 1.02, 0.95
ellipsoid("Body", (0, BODY_Y, 0), (RX, RY, RZ), MINT, segments=128, rings=80)


def surface(x, y, offset=0):
    radial = (x / RX) ** 2 + ((y - BODY_Y) / RY) ** 2
    if radial > 0.996:
        scale = sqrt(0.996 / radial)
        x *= scale
        y = BODY_Y + (y - BODY_Y) * scale
    q = max(0.004, 1 - (x / RX) ** 2 - ((y - BODY_Y) / RY) ** 2)
    return (x, y, RZ * sqrt(q) + offset)


def bezier(start, segments, samples=12):
    pts = []
    a = start
    for b, c, d in segments:
        for i in range(samples):
            t = i / samples
            u = 1 - t
            pts.append(
                tuple(
                    u * u * u * a[j]
                    + 3 * u * u * t * b[j]
                    + 3 * u * t * t * c[j]
                    + t * t * t * d[j]
                    for j in range(2)
                )
            )
        a = d
    return pts


def circle(cx, cy, rx, ry=None, n=96):
    if ry is None:
        ry = rx
    return [
        (cx + rx * cos(2 * PI * i / n), cy + ry * sin(2 * PI * i / n)) for i in range(n)
    ]


def patch(
    name,
    contour,
    material,
    offset=0.005,
    parent=0,
    origin=(0, 0, 0),
    center=None,
    rings=14,
):
    # Radial tessellation maps the marking onto the ellipsoid, not a flat decal.
    if center is None:
        center = tuple(sum(p[j] for p in contour) / len(contour) for j in range(2))
    n = len(contour)
    vertices = [vsub(surface(*center, offset), origin)]
    for k in range(1, rings + 1):
        r = k / rings
        for x, y in contour:
            vertices.append(
                vsub(
                    surface(
                        center[0] + r * (x - center[0]),
                        center[1] + r * (y - center[1]),
                        offset,
                    ),
                    origin,
                )
            )
    faces = [(0, 1 + i, 1 + (i + 1) % n) for i in range(n)]
    for k in range(rings - 1):
        for i in range(n):
            a = 1 + k * n + i
            b = 1 + k * n + (i + 1) % n
            faces.extend([(a, b, a + n), (b, b + n, a + n)])
    # Ensure front-facing normals, independent of clockwise artist path.
    if (
        sum(
            cross(vsub(vertices[b], vertices[a]), vsub(vertices[c], vertices[a]))[2]
            for a, b, c in faces
        )
        < 0
    ):
        faces = [(a, c, b) for a, b, c in faces]
    return g.mesh(name, vertices, faces, material, parent)


def tube(name, points, radius, material, parent=0, closed=True, origin=(0, 0, 0)):
    n = len(points)
    sides = 20
    vertices = []
    for i, p in enumerate(points):
        tangent = unit(
            vsub(
                points[(i + 1) % n] if closed or i < n - 1 else p,
                points[(i - 1) % n] if closed or i > 0 else p,
            )
        )
        side = unit(cross(tangent, (0, 0, 1)))
        other = unit(cross(tangent, side))
        for j in range(sides):
            angle = 2 * PI * j / sides
            vertices.append(
                vsub(
                    vadd(
                        p,
                        tuple(
                            radius * (cos(angle) * side[k] + sin(angle) * other[k])
                            for k in range(3)
                        ),
                    ),
                    origin,
                )
            )
    faces = []
    for i in range(n if closed else n - 1):
        for j in range(sides):
            a = i * sides + j
            b = i * sides + (j + 1) % sides
            c = ((i + 1) % n) * sides + j
            d = ((i + 1) % n) * sides + (j + 1) % sides
            faces.extend([(a, b, c), (b, d, c)])
    return g.mesh(name, vertices, faces, material, parent)


def outlined_patch(name, contour, material, width=0.018, offset=0.012, center=None):
    patch(name, contour, material, offset, center=center)
    tube(
        name + " outline",
        [surface(x, y, offset + 0.002) for x, y in contour],
        width,
        INK,
    )


mask = bezier(
    (0, 2.04),
    [
        ((0.19, 2.30), (0.52, 2.28), (0.63, 2.04)),
        ((0.81, 1.67), (0.49, 1.42), (0.20, 1.47)),
        ((0.10, 1.48), (0.04, 1.52), (0, 1.52)),
        ((-0.04, 1.52), (-0.10, 1.48), (-0.20, 1.47)),
        ((-0.49, 1.42), (-0.81, 1.67), (-0.63, 2.04)),
        ((-0.52, 2.28), (-0.19, 2.30), (0, 2.04)),
    ],
    20,
)
mask = [(x * 0.96, 1.80 + (y - 1.80) * 0.96) for x, y in mask]
outlined_patch("Joined blue face mask", mask, BLUE, 0.019, center=(0, 1.80))

bib = bezier(
    (-0.32, 1.34),
    [
        ((-0.12, 1.18), (0.11, 1.18), (0.32, 1.36)),
        ((0.46, 1.22), (0.59, 1.02), (0.70, 0.80)),
        ((0.49, 0.61), (0.27, 0.574), (0, 0.565)),
        ((-0.27, 0.574), (-0.49, 0.61), (-0.70, 0.80)),
        ((-0.59, 1.02), (-0.46, 1.22), (-0.32, 1.34)),
    ],
    20,
)
outlined_patch("White bib", bib, WHITE, 0.017, center=(0, 0.97))
outlined_patch("Red roundel", circle(0, 0.94, 0.204), RED, 0.017, 0.023)

# Each eye has its own pivot, so Blink closes only the eye, retaining the mask.
eyes = []
lids = []
for side, x in [("Left", -0.167), ("Right", 0.167)]:
    eyey = 1.81
    origin = surface(x, eyey, 0.04)
    pivot = g.node(side + "Eye", head, vsub(origin, bind_positions[head]))
    eyes.append(pivot)
    patch(
        side + " eye ink",
        circle(x, eyey, 0.170, 0.158),
        INK,
        0.029,
        pivot,
        origin,
        center=(x, eyey),
        rings=8,
    )
    patch(
        side + " eye white",
        circle(x, eyey, 0.134, 0.126),
        WHITE,
        0.034,
        pivot,
        origin,
        center=(x, eyey),
        rings=8,
    )
    patch(
        side + " pupil",
        circle(x, eyey, 0.036),
        INK,
        0.040,
        pivot,
        origin,
        center=(x, eyey),
        rings=5,
    )
    lid = g.node(side + "Lid", head, vsub(origin, bind_positions[head]))
    lids.append(lid)
    g.doc["nodes"][lid]["scale"] = [0.001, 0.001, 0.001]
    lid_points = []
    for i in range(33):
        dx = 0.138 * (2 * i / 32 - 1)
        lid_points.append(
            surface(x + dx, eyey - 0.014 * (1 - (dx / 0.138) ** 2), 0.057)
        )
    tube(
        side + " closed eyelid",
        lid_points,
        0.012,
        INK,
        lid,
        closed=False,
        origin=origin,
    )

# Circular beak base, tapering forward to the pointed side silhouette.
verts = []
faces = []
for j in range(17):
    t = j / 16
    r = 0.144 * (1 - t)
    for i in range(64):
        a = 2 * PI * i / 64
        verts.append((r * cos(a), 1.568 + r * sin(a), RZ + 0.019 + 0.54 * t))
for j in range(16):
    for i in range(64):
        a = j * 64 + i
        b = j * 64 + (i + 1) % 64
        faces.extend([(a, b, a + 64), (b, b + 64, a + 64)])
g.mesh("Pointed brown beak", verts, faces, BROWN)

# Fuji is a truncated mountain, not a party hat: wide base, flat summit,
# and an undulating black snowline that wraps all the way around.
hatbase = 2.50
hatheight = 0.54
verts = []
faces = []
for j in range(17):
    t = j / 16
    y = hatbase + hatheight * t
    r = 0.337 * (1 - t) + 0.118 * t
    for i in range(96):
        a = 2 * PI * i / 96
        verts.append((r * cos(a), y, r * sin(a)))
for j in range(16):
    for i in range(96):
        a = j * 96 + i
        b = j * 96 + (i + 1) % 96
        faces.extend([(a, a + 96, b), (b, a + 96, b + 96)])
g.mesh("Fuji blue mountain", verts, faces, BLUE)
verts = []
faces = []
snowline = []
for j in range(13):
    t = j / 12
    for i in range(96):
        a = 2 * PI * i / 96
        bottom = 2.880 + 0.024 * cos(3 * a + 0.8) + 0.01 * cos(5 * a)
        y = bottom + (3.04 - bottom) * t
        r = 0.337 + (0.118 - 0.337) * (y - hatbase) / hatheight + 0.002
        verts.append((r * cos(a), y, r * sin(a)))
        if j == 0:
            snowline.append((r * cos(a), y, r * sin(a)))
for j in range(12):
    for i in range(96):
        a = j * 96 + i
        b = j * 96 + (i + 1) % 96
        faces.extend([(a, a + 96, b), (b, a + 96, b + 96)])
# Summit cap.
verts.append((0, 3.04, 0))
cap = len(verts) - 1
for i in range(96):
    faces.append((cap, 12 * 96 + (i + 1) % 96, 12 * 96 + i))
g.mesh("Fuji white snowcap", verts, faces, WHITE)
tube("Fuji wavy snowline", snowline, 0.015, INK)

# Rounded three-feather wings: sculpted in the sagittal plane with a puffy
# cross-section and outward slope, preserving the front AND side silhouettes.
wing_contour = bezier(
    (0.18, 0.04),
    [
        ((0.42, -0.02), (0.48, -0.36), (0.36, -0.70)),
        ((0.30, -0.90), (0.16, -0.94), (0.09, -0.76)),
        ((0.04, -0.99), (-0.15, -0.99), (-0.19, -0.78)),
        ((-0.29, -0.93), (-0.47, -0.85), (-0.44, -0.64)),
        ((-0.44, -0.37), (-0.23, 0.12), (0.18, 0.04)),
    ],
    16,
)
for side_index, (side, sign) in enumerate([("Left", -1), ("Right", 1)]):
    n, nr = len(wing_contour), 28
    vertices = []
    # The feather lies alongside the body. A buried, tapered shoulder joins a
    # padded palm, then three round lobes. Both half-surfaces share edge normals.
    for half in [1, -1]:
        for k in range(nr + 1):
            r = k / nr
            for z, y in wing_contour:
                zz = r * z
                yy = -0.40 + r * (y + 0.40)
                shoulder_taper = smooth(-0.30, 0.08, yy)
                xx = sign * (
                    1.045
                    - 0.20 * shoulder_taper
                    + half * 0.14 * sqrt(max(0, 1 - r * r))
                )
                vertices.append((xx, 2.0 + yy, zz))
    faces = []
    halfsize = (nr + 1) * n
    for half in range(2):
        for k in range(nr):
            for i in range(n):
                a = half * halfsize + k * n + i
                b = half * halfsize + k * n + (i + 1) % n
                ts = [(a, b, a + n), (b, b + n, a + n)]
                if (half == 0) == (sign == 1):
                    ts = [(a, c, b) for a, b, c in ts]
                faces.extend(ts)

    def wing_weights(v, i=side_index):
        d = 2.02 - v[1]
        # The very top is attached to the torso; the shoulder then carries the
        # main sweep while two softer joints distribute the bend to the tip.
        if d < 0.21:
            w = smooth(-0.02, 0.21, d)
            return [(head, 1 - w), (wing_nodes[i], w)]
        if d < 0.59:
            w = smooth(0.21, 0.59, d)
            return [(wing_nodes[i], 1 - w), (wing_bends[i], w)]
        w = smooth(0.59, 0.91, d)
        return [(wing_bends[i], 1 - w), (wing_tips[i], w)]

    g.mesh(
        side + " sculpted three-feather wing",
        vertices,
        faces,
        BLUE,
        weights=wing_weights,
    )

for i, (side, x) in enumerate([("Left", -0.29), ("Right", 0.29)]):
    vertices, faces = [], []
    segments, rings = 64, 44
    # A continuous soft leg avoids exposed ball joints. Its end disappears into
    # the rounded foot and its upper cap is buried safely inside the body.
    for j in range(rings + 1):
        t = j / rings
        y = 0.16 + 0.54 * t
        radius = 0.097 + 0.011 * cos(PI * t)
        for k in range(segments):
            a = 2 * PI * k / segments
            vertices.append((x + radius * cos(a), y, 0.02 + radius * sin(a)))
    for j in range(rings):
        for k in range(segments):
            a, b = j * segments + k, j * segments + (k + 1) % segments
            faces.extend([(a, a + segments, b), (b, a + segments, b + segments)])

    def leg_weights(v, i=i):
        if v[1] > 0.405:
            w = smooth(0.405, 0.64, v[1])
            return [(knees[i], 1 - w), (legs[i], w)]
        w = smooth(0.17, 0.405, v[1])
        return [(ankles[i], 1 - w), (knees[i], w)]

    g.mesh(side + " flexible leg", vertices, faces, BROWN, weights=leg_weights)
    ellipsoid(
        side + " rounded foot",
        (x * 0.12, 0, 0.14),
        (0.23, 0.168, 0.32),
        BROWN,
        ankles[i],
        96,
        56,
    )

# Short raised fan on the back, visibly projecting beyond the body in profile.
verts = []
faces = []
for j in range(25):
    t = j / 24
    width = 0.16 + 0.16 * sin(t * PI * 0.72)
    cy = 0.02 - 0.10 * sin(t * PI) + 0.10 * t
    cz = -0.40 * t
    for i in range(48):
        a = 2 * PI * i / 48
        verts.append(
            (width * cos(a), cy + 0.09 * sin(a) * sin(PI * (0.08 + 0.84 * t)), cz)
        )
for j in range(24):
    for i in range(48):
        a = j * 48 + i
        b = j * 48 + (i + 1) % 48
        faces.extend([(a, b, a + 48), (b, b + 48, a + 48)])
g.mesh("Blue raised tail fan", verts, faces, BLUE, tail)


def quat(axis, angle):
    return tuple(sin(angle / 2) * v for v in axis) + (cos(angle / 2),)


def qmul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (
        aw * bx + ax * bw + ay * bz - az * by,
        aw * by - ax * bz + ay * bw + az * bx,
        aw * bz + ax * by - ay * bx + az * bw,
        aw * bw - ax * bx - ay * by - az * bz,
    )


def animate(name, duration, samples, pose):
    times = [duration * i / samples for i in range(samples + 1)]
    poses = [pose(t / duration) for t in times]
    # All clips key every animated property, including rest values. This prevents
    # stale limb/eyelid poses when switching clips in glTF animation players.
    tracks = []
    for node, path in poses[0]:
        tracks.append((node, path, times, [p[(node, path)] for p in poses]))
    g.clip(name, tracks)


def rest():
    pose = {(0, "translation"): (0, 0, 0)}
    for n in joints:
        pose[(n, "translation")] = tuple(g.doc["nodes"][n]["translation"])
        pose[(n, "rotation")] = quat((1, 0, 0), 0)
        pose[(n, "scale")] = (1, 1, 1)
    for n in eyes:
        pose[(n, "scale")] = (1, 1, 1)
    for n in lids:
        pose[(n, "scale")] = (0.001, 0.001, 0.001)
    return pose


def bend_body(p, bob=0, lean=0, nod=0, breathe=0):
    p[(hips, "translation")] = (0, 0.68 + bob, 0)
    p[(hips, "scale")] = (1 + breathe * 0.25, 1 - breathe * 0.35, 1 + breathe * 0.20)
    p[(torso, "rotation")] = quat((0, 0, 1), lean)
    p[(head, "rotation")] = quat((1, 0, 0), nod)
    p[(torso, "scale")] = (1 + breathe * 0.30, 1 - breathe * 0.25, 1 + breathe * 0.25)


def plant_leg(p, i, foot_y=0.17, foot_z=0.02, hip_bob=0, pitch=0):
    # Two-bone IK in the sagittal plane. On the stance phase the ankle stays
    # on the floor; the knee bends during swing, anticipation and landing.
    # Tiny length changes give the short toy-like legs a soft, stretchy gait.
    hip_y = 0.64 + hip_bob
    dy, dz = foot_y - hip_y, foot_z - 0.02
    d = sqrt(dy * dy + dz * dz)
    stretch = max(1, d / 0.4699)
    length = 0.235 * stretch
    aim = math.atan2(-dz, -dy)
    flex = math.acos(max(-1, min(1, d / (2 * length))))
    upper, lower = aim - flex, 2 * flex
    p[(legs[i], "translation")] = (bind_positions[legs[i]][0], hip_y, 0.02)
    p[(legs[i], "rotation")] = quat((1, 0, 0), upper)
    p[(knees[i], "translation")] = (0, -length, 0)
    p[(knees[i], "rotation")] = quat((1, 0, 0), lower)
    p[(ankles[i], "translation")] = (0, -length, 0)
    p[(ankles[i], "rotation")] = quat((1, 0, 0), pitch - upper - lower)


def blink_eyes(p, close):
    for n in eyes:
        p[(n, "scale")] = (1, max(0.001, 1 - close), 1)
    lid_scale = max(0.001, smooth(0.65, 0.94, close))
    for n in lids:
        p[(n, "scale")] = (lid_scale,) * 3


def pulse(t, center, width):
    return 1 - smooth(0, width, abs(t - center))


def idle(t):
    p = rest()
    phase = 2 * PI * t
    breath = (1 - cos(phase)) / 2
    bend_body(
        p,
        bob=0.012 * breath,
        lean=0.012 * sin(phase),
        nod=0.018 * sin(phase),
        breathe=-0.035 * breath,
    )
    for i, sign in enumerate([-1, 1]):
        p[(wing_nodes[i], "rotation")] = quat((0, 0, 1), sign * 0.025 * breath)
        p[(wing_bends[i], "rotation")] = quat((1, 0, 0), 0.018 * sin(phase))
    p[(tail, "rotation")] = quat((1, 0, 0), 0.035 * sin(phase))
    blink_eyes(p, pulse(t, 0.70, 0.028))
    return p


def walk(t):
    p = rest()
    # A periodic gait has identical endpoints, without stopping between cycles.
    # The Flutter player blends this moving pose with the other full-body clips.
    envelope = 1
    phase = 2 * PI * t
    bob = -0.028 * envelope * (0.55 + 0.45 * cos(2 * phase))
    bend_body(
        p,
        bob=bob,
        lean=0.038 * envelope * sin(phase),
        nod=-0.018 * envelope * sin(2 * phase),
        breathe=0.025 * envelope,
    )
    for i in range(2):
        step = phase + i * PI
        forward = 0.15 * sin(step) * envelope
        lift = 0.12 * max(0, cos(step)) ** 2 * envelope
        plant_leg(
            p,
            i,
            0.17 + lift,
            0.02 + forward,
            bob,
            pitch=-0.13 * max(0, cos(step)) * envelope,
        )
        p[(wing_nodes[i], "rotation")] = quat((1, 0, 0), -0.11 * sin(step) * envelope)
        p[(wing_bends[i], "rotation")] = quat(
            (1, 0, 0), -0.065 * sin(step - 0.5) * envelope
        )
        p[(wing_tips[i], "rotation")] = quat(
            (1, 0, 0), -0.045 * sin(step - 0.9) * envelope
        )
    p[(tail, "rotation")] = quat((1, 0, 0), 0.04 * sin(2 * phase) * envelope)
    return p


def jump(t):
    p = rest()
    crouch = pulse(t, 0.14, 0.14)
    air = smooth(0.23, 0.31, t) * (1 - smooth(0.72, 0.79, t))
    flight_t = max(0, min(1, (t - 0.23) / 0.56))
    height = 0.66 * 4 * flight_t * (1 - flight_t)
    land = pulse(t, 0.83, 0.10)
    bob = -0.095 * crouch - 0.075 * land
    bend_body(
        p,
        bob=bob,
        lean=0,
        nod=0.055 * crouch - 0.04 * air,
        breathe=0.13 * crouch + 0.10 * land - 0.035 * air,
    )
    p[(0, "translation")] = (0, height, 0)
    # Upstroke before takeoff; three broad downstrokes with a delayed wrist.
    flap_phase = 2 * PI * 3 * (t - 0.21) / 0.60
    wings = smooth(0.04, 0.23, t) * (1 - smooth(0.78, 0.97, t))
    for i, sign in enumerate([-1, 1]):
        shoulder = wings * (0.83 + 0.49 * cos(flap_phase))
        p[(wing_nodes[i], "rotation")] = quat((0, 0, 1), sign * shoulder)
        p[(wing_bends[i], "rotation")] = quat(
            (0, 0, 1), sign * wings * 0.30 * sin(flap_phase - 0.65)
        )
        p[(wing_tips[i], "rotation")] = quat(
            (0, 0, 1), sign * wings * 0.24 * sin(flap_phase - 1.05)
        )
        plant_leg(p, i, 0.17 + 0.10 * air, 0.02 - 0.075 * air, bob, -0.16 * air)
    p[(tail, "rotation")] = quat((1, 0, 0), -0.14 * air + 0.08 * land)
    blink_eyes(p, 0.75 * land)
    return p


def wave(t):
    p = rest()
    envelope = smooth(0, 0.22, t) * (1 - smooth(0.78, 1, t))
    phase = 2 * PI * 3 * t
    bend_body(
        p,
        bob=-0.014 * envelope,
        lean=-0.075 * envelope,
        nod=0.025 * sin(phase) * envelope,
        breathe=0.025 * envelope,
    )
    # The shoulder raises the wing once; middle and tip follow the wave with
    # delayed curves, keeping the rooted edge on the body throughout the arc.
    p[(wing_nodes[1], "rotation")] = qmul(
        quat((0, 0, 1), envelope * (1.62 + 0.10 * sin(phase))),
        quat((0, 1, 0), -0.95 * envelope),
    )
    p[(wing_bends[1], "rotation")] = quat(
        (0, 0, 1), envelope * (0.22 + 0.26 * sin(phase - 0.5))
    )
    p[(wing_tips[1], "rotation")] = quat(
        (0, 0, 1), envelope * (0.14 + 0.30 * sin(phase - 0.95))
    )
    p[(wing_nodes[0], "rotation")] = quat((0, 0, 1), -0.07 * envelope)
    p[(wing_bends[0], "rotation")] = quat((1, 0, 0), 0.05 * sin(phase) * envelope)
    for i in range(2):
        plant_leg(p, i, hip_bob=-0.014 * envelope)
    blink_eyes(p, pulse(t, 0.67, 0.035))
    return p


def blink(t):
    p = idle(t)
    blink_eyes(p, max(pulse(t, 0.34, 0.085), pulse(t, 0.62, 0.075)))
    return p


# Sampled smooth curves are portable to glTF players and Flutter Scene. Gestures
# return to bind pose; walking stays in its continuous periodic gait.
for name, duration, samples, pose in [
    ("Walk", 1.4, 84, walk),
    ("Jump", 2.1, 126, jump),
    ("Wave", 3.2, 192, wave),
    ("Blink", 2.2, 132, blink),
    ("Idle", 4.8, 288, idle),
]:
    animate(
        name,
        duration,
        samples,
        pose
        if name == "Walk"
        else lambda t, fn=pose: rest() if t <= 0 or t >= 1 else fn(t),
    )
g.save()
