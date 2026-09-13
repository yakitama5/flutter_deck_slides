#!/usr/bin/env python3
"""Check the exported model and its animation contract without third-party tools.

Run from any directory: python3 path/to/tool/check_dashmaru.py [path/to/model.glb]
This checks the delivered binary, independently of the model-building code. It is
not a replacement for watching the five gestures in Flutter Scene.
"""

import argparse
import json
import math
from pathlib import Path
import struct
import sys


class InvalidModel(Exception):
    """An exported asset violates a required model or animation invariant."""


def require(condition, message):
    if not condition:
        raise InvalidModel(message)


def finite_json(value, location="JSON"):
    if isinstance(value, float):
        require(math.isfinite(value), f"{location}: non-finite number")
    elif isinstance(value, list):
        for index, item in enumerate(value):
            finite_json(item, f"{location}[{index}]")
    elif isinstance(value, dict):
        for key, item in value.items():
            finite_json(item, f"{location}.{key}")


def close(a, b):
    return len(a) == len(b) and all(
        math.isclose(x, y, rel_tol=1e-5, abs_tol=1e-6) for x, y in zip(a, b)
    )


def same_pose(a, b, path):
    # q and -q represent the same orientation.
    return close(a, b) or (path == "rotation" and close(a, tuple(-v for v in b)))


IDENTITY = (1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)


def multiply(a, b):
    """Multiply glTF's column-major matrices without importing the exporter."""
    return tuple(
        sum(a[row + k * 4] * b[k + column * 4] for k in range(4))
        for column in range(4)
        for row in range(4)
    )


def node_matrix(node):
    if "matrix" in node:
        matrix = node["matrix"]
        require(len(matrix) == 16, "Node matrix must contain 16 values")
        require(
            not any(key in node for key in ("translation", "rotation", "scale")),
            "Node cannot contain both matrix and TRS transforms",
        )
        return tuple(matrix)
    translation = node.get("translation", (0, 0, 0))
    rotation = node.get("rotation", (0, 0, 0, 1))
    scale = node.get("scale", (1, 1, 1))
    require(
        len(translation) == len(scale) == 3 and len(rotation) == 4,
        "Node has malformed TRS transforms",
    )
    require(
        math.isclose(sum(v * v for v in rotation), 1, abs_tol=1e-5),
        "Node has a non-unit default quaternion",
    )
    x, y, z, w = rotation
    sx, sy, sz = scale
    return (
        (1 - 2 * (y * y + z * z)) * sx,
        2 * (x * y + z * w) * sx,
        2 * (x * z - y * w) * sx,
        0,
        2 * (x * y - z * w) * sy,
        (1 - 2 * (x * x + z * z)) * sy,
        2 * (y * z + x * w) * sy,
        0,
        2 * (x * z + y * w) * sz,
        2 * (y * z - x * w) * sz,
        (1 - 2 * (x * x + y * y)) * sz,
        0,
        *translation,
        1,
    )


class Model:
    COMPONENTS = {
        5120: ("b", 1),
        5121: ("B", 1),
        5122: ("h", 2),
        5123: ("H", 2),
        5125: ("I", 4),
        5126: ("f", 4),
    }
    WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}

    def __init__(self, path):
        blob = path.read_bytes()
        require(len(blob) >= 20, "GLB is too short")
        magic, version, length = struct.unpack_from("<4sII", blob)
        require(magic == b"glTF" and version == 2, "Expected glTF 2.0 binary")
        require(length == len(blob), "GLB header length does not match file")
        chunks = []
        offset = 12
        while offset < length:
            require(offset + 8 <= length, "Truncated GLB chunk header")
            size, kind = struct.unpack_from("<I4s", blob, offset)
            require(size % 4 == 0, "GLB chunk is not four-byte aligned")
            offset += 8
            require(offset + size <= length, "GLB chunk extends beyond file")
            chunks.append((kind, blob[offset : offset + size]))
            offset += size
        require(
            [kind for kind, _ in chunks] == [b"JSON", b"BIN\x00"],
            "Expected one JSON chunk followed by one embedded BIN chunk",
        )
        self.doc = json.loads(chunks[0][1])
        self.binary = chunks[1][1]
        finite_json(self.doc)
        require(
            self.doc.get("asset", {}).get("version") == "2.0", "Invalid asset version"
        )
        buffers = self.doc.get("buffers", [])
        require(
            len(buffers) == 1 and "uri" not in buffers[0],
            "Model must be self-contained in one embedded buffer",
        )
        self.buffer_length = buffers[0]["byteLength"]
        require(
            0 <= len(self.binary) - self.buffer_length <= 3,
            "BIN size does not match declared buffer and alignment padding",
        )
        self.accessors = self.doc.get("accessors", [])
        self.views = self.doc.get("bufferViews", [])
        self.nodes = self.doc.get("nodes", [])
        self.cache = {}
        for index, view in enumerate(self.views):
            start, size = view.get("byteOffset", 0), view["byteLength"]
            require(view["buffer"] == 0, f"bufferView {index}: invalid buffer")
            require(
                start >= 0 and size > 0 and start + size <= self.buffer_length,
                f"bufferView {index}: invalid binary bounds",
            )
        for index in range(len(self.accessors)):
            self.read(index)

    def read(self, index):
        if index in self.cache:
            return self.cache[index]
        require(
            isinstance(index, int) and 0 <= index < len(self.accessors),
            f"Invalid accessor index: {index}",
        )
        accessor = self.accessors[index]
        label = f"accessor {index}"
        require(
            "sparse" not in accessor,
            f"{label}: sparse data is outside this model contract",
        )
        view_index = accessor["bufferView"]
        require(0 <= view_index < len(self.views), f"{label}: invalid bufferView")
        view = self.views[view_index]
        component = accessor["componentType"]
        require(component in self.COMPONENTS, f"{label}: invalid component type")
        require(
            accessor["type"] in self.WIDTHS,
            f"{label}: unsupported accessor shape",
        )
        require(
            accessor["type"] != "MAT4" or component == 5126,
            f"{label}: inverse-bind matrices must contain floats",
        )
        fmt, unit = self.COMPONENTS[component]
        width = self.WIDTHS[accessor["type"]]
        packed = width * unit
        stride = view.get("byteStride", packed)
        start, count = accessor.get("byteOffset", 0), accessor["count"]
        require(
            count > 0 and start >= 0 and stride >= packed and stride % unit == 0,
            f"{label}: invalid count, offset, or stride",
        )
        absolute = view.get("byteOffset", 0) + start
        require(absolute % unit == 0, f"{label}: misaligned component")
        require(
            start + (count - 1) * stride + packed <= view["byteLength"],
            f"{label}: data exceeds its bufferView",
        )
        values = [
            struct.unpack_from("<" + fmt * width, self.binary, absolute + i * stride)
            for i in range(count)
        ]
        require(
            all(math.isfinite(value) for row in values for value in row),
            f"{label}: contains NaN or infinity",
        )
        for bound, operation in (("min", min), ("max", max)):
            if bound in accessor:
                actual = tuple(
                    operation(row[axis] for row in values) for axis in range(width)
                )
                require(
                    close(accessor[bound], actual),
                    f"{label}: incorrect declared {bound}",
                )
        self.cache[index] = values
        return values

    def check_meshes(self):
        meshes = self.doc.get("meshes", [])
        require(meshes, "Model contains no geometry")
        triangles = 0
        for mesh_index, mesh in enumerate(meshes):
            for primitive in mesh["primitives"]:
                label = f"mesh {mesh_index} ({mesh.get('name', 'unnamed')})"
                attributes = primitive["attributes"]
                require("POSITION" in attributes, f"{label}: no positions")
                positions = self.read(attributes["POSITION"])
                require(
                    self.accessors[attributes["POSITION"]]["type"] == "VEC3",
                    f"{label}: positions must be VEC3",
                )
                for semantic, accessor in attributes.items():
                    require(
                        len(self.read(accessor)) == len(positions),
                        f"{label}: {semantic} count differs from positions",
                    )
                require(primitive.get("mode", 4) == 4, f"{label}: expected triangles")
                if "indices" in primitive:
                    accessor = self.accessors[primitive["indices"]]
                    require(
                        accessor["type"] == "SCALAR"
                        and accessor["componentType"] in (5121, 5123, 5125),
                        f"{label}: invalid index format",
                    )
                    indices = self.read(primitive["indices"])
                    require(
                        all(0 <= row[0] < len(positions) for row in indices),
                        f"{label}: vertex index out of bounds",
                    )
                    count = len(indices)
                else:
                    count = len(positions)
                require(count % 3 == 0, f"{label}: incomplete triangle")
                triangles += count // 3
        for index, node in enumerate(self.nodes):
            require(
                all(value > 0 for value in node.get("scale", [1, 1, 1])),
                f"node {index}: non-positive default scale",
            )
            if "mesh" in node:
                require(0 <= node["mesh"] < len(meshes), f"node {index}: invalid mesh")
            require(
                all(0 <= child < len(self.nodes) for child in node.get("children", [])),
                f"node {index}: invalid child",
            )
        return len(meshes), triangles

    def world_matrices(self, overrides=None):
        parents = {}
        for parent, node in enumerate(self.nodes):
            for child in node.get("children", []):
                require(child not in parents, f"node {child}: multiple parents")
                parents[child] = parent
        worlds, visiting = {}, set()

        def visit(index):
            if index in worlds:
                return worlds[index]
            require(index not in visiting, "Node hierarchy contains a cycle")
            visiting.add(index)
            node = dict(self.nodes[index])
            if overrides:
                for (target, path), value in overrides.items():
                    if target == index:
                        node[path] = value
            parent = visit(parents[index]) if index in parents else IDENTITY
            worlds[index] = multiply(parent, node_matrix(node))
            visiting.remove(index)
            return worlds[index]

        for index in range(len(self.nodes)):
            visit(index)
        return worlds

    def check_skins(self):
        skins = self.doc.get("skins", [])
        require(skins, "Model must contain a deformable skeleton")
        worlds = self.world_matrices()
        inverse_binds = {}
        for index, skin in enumerate(skins):
            label = f"skin {index}"
            joints = skin.get("joints", [])
            require(
                joints and len(joints) == len(set(joints)), f"{label}: invalid joints"
            )
            require(
                all(
                    isinstance(joint, int) and 0 <= joint < len(self.nodes)
                    for joint in joints
                ),
                f"{label}: joint index is out of bounds",
            )
            if "skeleton" in skin:
                require(
                    0 <= skin["skeleton"] < len(self.nodes),
                    f"{label}: invalid skeleton root",
                )
            require("inverseBindMatrices" in skin, f"{label}: missing inverse binds")
            accessor = self.accessors[skin["inverseBindMatrices"]]
            require(
                accessor["type"] == "MAT4" and accessor["componentType"] == 5126,
                f"{label}: inverse binds must be floating-point MAT4",
            )
            matrices = self.read(skin["inverseBindMatrices"])
            require(
                len(matrices) == len(joints),
                f"{label}: inverse bind count differs from joints",
            )
            for matrix in matrices:
                require(
                    close((matrix[3], matrix[7], matrix[11], matrix[15]), (0, 0, 0, 1)),
                    f"{label}: inverse bind is not an affine transform",
                )
                determinant = (
                    matrix[0] * (matrix[5] * matrix[10] - matrix[9] * matrix[6])
                    - matrix[4] * (matrix[1] * matrix[10] - matrix[9] * matrix[2])
                    + matrix[8] * (matrix[1] * matrix[6] - matrix[5] * matrix[2])
                )
                require(abs(determinant) > 1e-8, f"{label}: singular inverse bind")
            inverse_binds[index] = matrices

        deformed = {"body": 0, "wing": 0, "leg": 0}
        blended_vertices = 0
        for node_index, node in enumerate(self.nodes):
            if "mesh" not in node:
                require("skin" not in node, f"node {node_index}: skin without geometry")
                continue
            mesh = self.doc["meshes"][node["mesh"]]
            label = f"node {node_index} ({mesh.get('name', 'unnamed')})"
            for primitive in mesh["primitives"]:
                attributes = primitive["attributes"]
                if "skin" not in node:
                    require(
                        "JOINTS_0" not in attributes and "WEIGHTS_0" not in attributes,
                        f"{label}: skin attributes have no skin",
                    )
                    continue
                skin_index = node["skin"]
                require(0 <= skin_index < len(skins), f"{label}: invalid skin")
                skin = skins[skin_index]
                require(
                    "JOINTS_0" in attributes and "WEIGHTS_0" in attributes,
                    f"{label}: skinned geometry needs joint indices and weights",
                )
                joint_accessor = self.accessors[attributes["JOINTS_0"]]
                weight_accessor = self.accessors[attributes["WEIGHTS_0"]]
                require(
                    joint_accessor["type"] == "VEC4"
                    and joint_accessor["componentType"] in (5121, 5123)
                    and not joint_accessor.get("normalized", False),
                    f"{label}: joint indices must be unsigned byte/short VEC4",
                )
                weight_component = weight_accessor["componentType"]
                require(
                    weight_accessor["type"] == "VEC4"
                    and (
                        weight_component == 5126
                        or (
                            weight_component in (5121, 5123)
                            and weight_accessor.get("normalized", False)
                        )
                    ),
                    f"{label}: weights must be float or normalized unsigned VEC4",
                )
                indices = self.read(attributes["JOINTS_0"])
                weights = self.read(attributes["WEIGHTS_0"])
                divisor = {5121: 255, 5123: 65535, 5126: 1}[weight_component]
                used, blend_count = set(), 0
                for slots, raw in zip(indices, weights):
                    row = tuple(value / divisor for value in raw)
                    require(
                        all(0 <= slot < len(skin["joints"]) for slot in slots),
                        f"{label}: vertex joint index is outside the skin",
                    )
                    require(
                        all(0 <= weight <= 1 for weight in row)
                        and math.isclose(
                            sum(row), 1, abs_tol=2 / divisor if divisor != 1 else 1e-5
                        ),
                        f"{label}: vertex weights must be nonnegative and sum to one",
                    )
                    active = {slot for slot, weight in zip(slots, row) if weight > 1e-4}
                    used.update(active)
                    if len(active) > 1:
                        blend_count += 1
                # A bind-pose error makes parts jump away before animation starts.
                for slot in used:
                    joint = skin["joints"][slot]
                    restored = multiply(worlds[joint], inverse_binds[skin_index][slot])
                    require(
                        close(restored, worlds[node_index]),
                        f"{label}: inverse bind does not preserve the default mesh pose",
                    )
                blended_vertices += blend_count
                name = mesh.get("name", "").lower()
                for part in deformed:
                    if (
                        (part in name or (part == "leg" and "shin" in name))
                        and blend_count > 0
                        and len(used) > 1
                    ):
                        deformed[part] += 1
        require(deformed["body"] >= 1, "Body has no vertices blended between bones")
        require(
            deformed["wing"] >= 2, "Both wings must flex across blended bone weights"
        )
        require(deformed["leg"] >= 2, "Both legs must bend across blended bone weights")
        return f"{len(skins)} skins; {blended_vertices:,} vertices blend between bones"

    def check_animations(self):
        animations = self.doc.get("animations", [])
        names = [animation.get("name") for animation in animations]
        required = {"Idle", "Walk", "Jump", "Wave", "Blink"}
        require(len(names) == len(set(names)), "Animation names are not unique")
        require(
            required <= set(names),
            f"Missing required clips: {sorted(required - set(names))}",
        )
        defaults = {
            "translation": (0, 0, 0),
            "rotation": (0, 0, 0, 1),
            "scale": (1, 1, 1),
        }
        expected_types = {"translation": "VEC3", "rotation": "VEC4", "scale": "VEC3"}
        clips = {}
        summaries = []
        for animation in animations:
            name = animation["name"]
            tracks, durations, timelines = {}, [], []
            for channel in animation["channels"]:
                target = channel["target"]
                node_index, path = target["node"], target["path"]
                require(
                    0 <= node_index < len(self.nodes), f"{name}: invalid animated node"
                )
                require(
                    path in defaults, f"{name}: unexpected animated property {path}"
                )
                key = (node_index, path)
                require(key not in tracks, f"{name}: duplicate channel target {key}")
                node = self.nodes[node_index]
                label = f"{name}/{node.get('name', node_index)}/{path}"
                require(
                    "matrix" not in node,
                    f"{label}: animated node must use TRS transforms",
                )
                sampler_index = channel["sampler"]
                require(
                    0 <= sampler_index < len(animation["samplers"]),
                    f"{label}: invalid sampler",
                )
                sampler = animation["samplers"][sampler_index]
                require(
                    sampler.get("interpolation", "LINEAR") in ("LINEAR", "STEP"),
                    f"{label}: interpolation must preserve positive scale between keys",
                )
                times = self.read(sampler["input"])
                input_accessor = self.accessors[sampler["input"]]
                require(
                    input_accessor["type"] == "SCALAR"
                    and input_accessor["componentType"] == 5126,
                    f"{label}: timeline must contain floating-point scalars",
                )
                times = [row[0] for row in times]
                require(
                    len(times) >= 2 and abs(times[0]) <= 1e-6,
                    f"{label}: timeline must start at zero and have at least two keys",
                )
                require(
                    all(b > a for a, b in zip(times, times[1:])),
                    f"{label}: timeline is not strictly increasing",
                )
                values = self.read(sampler["output"])
                output_accessor = self.accessors[sampler["output"]]
                require(
                    output_accessor["type"] == expected_types[path]
                    and output_accessor["componentType"] == 5126,
                    f"{label}: invalid output format",
                )
                require(
                    len(values) == len(times),
                    f"{label}: input/output key counts differ",
                )
                if path == "scale":
                    require(
                        all(value > 0 for row in values for value in row),
                        f"{label}: zero/negative scale makes the transform singular",
                    )
                if path == "rotation":
                    require(
                        all(
                            math.isclose(sum(v * v for v in row), 1, abs_tol=1e-5)
                            for row in values
                        ),
                        f"{label}: quaternion is not normalized",
                    )
                neutral = node.get(path, defaults[path])
                require(
                    same_pose(values[0], values[-1], path),
                    f"{label}: first and last poses must match for a seamless loop",
                )
                # A steady walk starts inside its gait cycle, avoiding a stop at
                # every repeat. The player blends its fully keyed pose on entry.
                if name != "Walk":
                    require(
                        same_pose(values[0], neutral, path)
                        and same_pose(values[-1], neutral, path),
                        f"{label}: gesture must begin and finish in the neutral pose",
                    )
                tracks[key] = values
                durations.append(times[-1])
                timelines.append(times)
            require(tracks, f"{name}: clip has no channels")
            require(
                max(durations) - min(durations) <= 1e-5,
                f"{name}: tracks do not end together",
            )
            require(
                all(close(timelines[0], timeline) for timeline in timelines),
                f"{name}: baked rig channels must use a common timeline",
            )
            changed = sum(
                not all(same_pose(rows[0], row, key[1]) for row in rows)
                for key, rows in tracks.items()
            )
            require(changed > 0, f"{name}: clip has no actual motion")
            clips[name] = tracks
            summaries.append(
                f"{name}: {max(durations):.2f}s, {len(tracks)} tracks, {changed} moving"
            )

        # Every clip keys every animated property. Omitting another clip's
        # channels leaves stale limbs when the player blends between gestures.
        union = set().union(*(set(tracks) for tracks in clips.values()))
        for name, tracks in clips.items():
            require(
                set(tracks) == union,
                f"{name}: missing channels needed to reset another clip's pose",
            )

        named_nodes = {node.get("name"): index for index, node in enumerate(self.nodes)}

        def gesture_track(clip, node_name, path):
            require(
                node_name in named_nodes, f"{clip}: missing gesture node {node_name}"
            )
            key = (named_nodes[node_name], path)
            require(key in clips[clip], f"{clip}: missing {node_name}/{path} channel")
            return clips[clip][key]

        def moves(rows):
            return any(
                max(abs(a - b) for a, b in zip(rows[0], row)) > 1e-3 for row in rows
            )

        def node_moves(clip, node_name):
            require(
                node_name in named_nodes, f"{clip}: missing gesture node {node_name}"
            )
            return any(
                moves(rows)
                for (node, _), rows in clips[clip].items()
                if node == named_nodes[node_name]
            )

        for leg in ("LeftLeg", "RightLeg"):
            require(
                moves(gesture_track("Walk", leg, "rotation")),
                f"Walk: {leg} does not move",
            )
        for knee in ("LeftKnee", "RightKnee"):
            require(
                moves(gesture_track("Walk", knee, "rotation")),
                f"Walk: {knee} never bends",
            )
        jump = gesture_track("Jump", "Dashmaru", "translation")
        require(
            max(row[1] for row in jump) > jump[0][1] + 0.05,
            "Jump: body never visibly leaves its rest height",
        )
        require(
            any(
                moves(gesture_track("Wave", wing, "rotation"))
                for wing in ("LeftWing", "RightWing")
            ),
            "Wave: neither wing moves",
        )
        for wing in ("LeftWing", "RightWing"):
            require(
                moves(gesture_track("Jump", wing, "rotation")),
                f"Jump: {wing} never flaps",
            )
            require(
                moves(gesture_track("Jump", wing + "Bend", "rotation")),
                f"Jump: {wing} stays rigid throughout the flap",
            )
        require(
            any(
                moves(gesture_track("Wave", wing, "rotation"))
                for wing in ("LeftWingBend", "RightWingBend")
            ),
            "Wave: neither wing bends",
        )
        require(
            node_moves("Idle", "Torso") and node_moves("Idle", "Head"),
            "Idle: torso and head need visible breathing/secondary motion",
        )
        for eye in ("LeftEye", "RightEye"):
            rows = gesture_track("Blink", eye, "scale")
            require(
                min(row[1] for row in rows) < rows[0][1] * 0.5,
                f"Blink: {eye} does not visibly close",
            )
        self.check_foot_contacts(clips)
        return summaries

    def check_foot_contacts(self, clips):
        feet = []
        for index, node in enumerate(self.nodes):
            if "mesh" not in node:
                continue
            mesh = self.doc["meshes"][node["mesh"]]
            if "rounded foot" in mesh.get("name", "").lower():
                require("skin" not in node, "Foot geometry must follow its ankle joint")
                positions = [
                    vertex
                    for primitive in mesh["primitives"]
                    for vertex in self.read(primitive["attributes"]["POSITION"])
                ]
                feet.append((index, positions))
        require(len(feet) == 2, "Expected two rounded feet for ground-contact checks")
        for name, tracks in clips.items():
            bottoms = []
            # Inspect the actual transformed foot vertices at every baked key,
            # independently of the exporter's IK and motion formulae.
            for frame in range(len(next(iter(tracks.values())))):
                worlds = self.world_matrices(
                    {key: rows[frame] for key, rows in tracks.items()}
                )
                heights = []
                for node, positions in feet:
                    world = worlds[node]
                    heights.append(
                        min(
                            world[1] * x + world[5] * y + world[9] * z + world[13]
                            for x, y, z in positions
                        )
                    )
                require(
                    min(heights) > -0.015,
                    f"{name}: a foot penetrates the floor at frame {frame}",
                )
                if name != "Jump":
                    require(
                        min(heights) < 0.025,
                        f"{name}: neither foot supports the body at frame {frame}",
                    )
                bottoms.append(heights)
            if name == "Walk":
                require(
                    all(max(row[foot] for row in bottoms) > 0.055 for foot in range(2)),
                    "Walk: each foot must lift clear of the floor during its swing",
                )
            if name == "Jump":
                require(
                    any(min(row) > 0.15 for row in bottoms),
                    "Jump: both feet never leave the floor together",
                )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "model",
        nargs="?",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "assets/models/dashmaru.glb",
    )
    args = parser.parse_args()
    try:
        model = Model(args.model)
        mesh_count, triangle_count = model.check_meshes()
        skin_summary = model.check_skins()
        summaries = model.check_animations()
    except (
        InvalidModel,
        OSError,
        ValueError,
        KeyError,
        IndexError,
        TypeError,
        struct.error,
    ) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    print(
        f"PASS: {args.model.name} — {mesh_count} meshes, {triangle_count:,} triangles, "
        f"{len(model.accessors)} bounded finite accessors"
    )
    for summary in summaries:
        print(f"  {summary}")
    print(f"  {skin_summary}")
    print("  Every loop joins matching poses and keys all shared properties.")
    print("  Non-walking clips return to neutral; all scales stay positive.")
    print("  Baked foot poses stay above the floor; walking retains a supporting foot.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
