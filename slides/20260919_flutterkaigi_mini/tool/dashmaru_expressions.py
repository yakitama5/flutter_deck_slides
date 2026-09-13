"""Reference-based, curved face markings for the Dashmaru glTF sculpture.

The drawing references use the same round eye outlines for a tiny-pupil blank
look, happy arches and dizzy spirals. Geometry stays a rigid child of Head,
matching the normal eyes while the soft body bends around it. The Flutter app
selects a group independently of the locomotion animation.
"""

import math


def build_expressions(g, head, head_position, patch, tube, surface, circle, ink, white):
    """Add hidden FaceDeadpan, FaceSmile and FaceSpiral groups; return their IDs.

    All contour coordinates are authored in model space and converted to Head
    local space exactly once. Groups start scaled down for generic glTF viewers;
    the Flutter expression selector restores the selected group's unit scale.
    """
    groups = []
    for expression in ("Deadpan", "Smile", "Spiral"):
        group = g.node("Face" + expression, head, (0, 0, 0))
        g.doc["nodes"][group]["scale"] = [0.001, 0.001, 0.001]
        groups.append(group)
        for side, x in (("Left", -0.167), ("Right", 0.167)):
            y = 1.81
            prefix = expression + " " + side
            for name, radii, material, offset in (
                ("eye ink", (0.170, 0.158), ink, 0.029),
                ("eye white", (0.134, 0.126), white, 0.034),
            ):
                patch(
                    prefix + " " + name,
                    circle(x, y, *radii),
                    material,
                    offset,
                    group,
                    head_position,
                    center=(x, y),
                    rings=8,
                )

            if expression == "Deadpan":
                # magao.PNG: centred pin-dot pupils, without angry half lids.
                patch(
                    prefix + " tiny pupil",
                    circle(x, y, 0.025),
                    ink,
                    0.042,
                    group,
                    head_position,
                    center=(x, y),
                    rings=5,
                )
                continue

            if expression == "Smile":
                # clap.PNG: round, upward arches inside the white of each eye.
                points = [
                    (
                        x + 0.063 * math.cos(math.pi * i / 48),
                        y - 0.030 + 0.077 * math.sin(math.pi * i / 48),
                    )
                    for i in range(49)
                ]
                radius = 0.0185
            else:
                # guruguru.PNG: an open spiral, with space between the turns so
                # the pupil remains readable at the demo's normal camera size.
                points = []
                for i in range(105):
                    t = i / 104
                    angle = -0.60 * math.pi + 2.35 * math.pi * t
                    r = 0.014 + 0.077 * t
                    points.append((x + r * math.cos(angle), y + r * math.sin(angle)))
                radius = 0.0145

            stroke_points = [surface(px, py, 0.055) for px, py in points]
            tube(
                prefix + " expression stroke",
                stroke_points,
                radius,
                ink,
                group,
                closed=False,
                origin=head_position,
            )
            # The shared tube helper leaves open ends. Small rounded caps make
            # the embroidered strokes continuous from an oblique camera too.
            for end, center in enumerate((stroke_points[0], stroke_points[-1])):
                _round_cap(
                    g,
                    prefix + " stroke cap " + str(end),
                    center,
                    radius,
                    ink,
                    group,
                    head_position,
                )
    return groups


def _round_cap(g, name, center, radius, material, parent, origin):
    """A small smooth sphere closes the end of an embroidered eye stroke."""
    segments, rings = 20, 12
    vertices, faces = [], []
    for j in range(rings + 1):
        latitude = math.pi * j / rings
        for i in range(segments):
            longitude = 2 * math.pi * i / segments
            delta = (
                radius * math.sin(latitude) * math.cos(longitude),
                radius * math.cos(latitude),
                radius * math.sin(latitude) * math.sin(longitude),
            )
            vertices.append(tuple(center[k] + delta[k] - origin[k] for k in range(3)))
    for j in range(rings):
        for i in range(segments):
            a = j * segments + i
            b = j * segments + (i + 1) % segments
            faces.extend(((a, b, a + segments), (b, b + segments, a + segments)))
    g.mesh(name, vertices, faces, material, parent)
