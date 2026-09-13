#!/usr/bin/env python3
"""Check the exported model and its animation contract without third-party tools.

Run from any directory: python3 path/to/tool/check_dashmaru.py [path/to/model.glb]
This checks the delivered binary, independently of the model-building code. It is
not a replacement for watching the four gestures in Flutter Scene.
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


class Model:
    COMPONENTS = {
        5120: ("b", 1),
        5121: ("B", 1),
        5122: ("h", 2),
        5123: ("H", 2),
        5125: ("I", 4),
        5126: ("f", 4),
    }
    WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}

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
            f"{label}: expected scalar/vector data for this unskinned model",
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

    def check_animations(self):
        animations = self.doc.get("animations", [])
        names = [animation.get("name") for animation in animations]
        required = {"Walk", "Jump", "Wave", "Blink"}
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
            tracks, durations = {}, []
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
                    same_pose(values[0], neutral, path)
                    and same_pose(values[-1], neutral, path),
                    f"{label}: clip must begin and finish in the node's neutral pose",
                )
                tracks[key] = values
                durations.append(times[-1])
            require(tracks, f"{name}: clip has no channels")
            require(
                max(durations) - min(durations) <= 1e-5,
                f"{name}: tracks do not end together",
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

        # Every clip resets every animated property. Merely returning each clip's
        # own channels to neutral leaves stale limbs when a player switches early.
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

        for leg in ("LeftLeg", "RightLeg"):
            require(
                moves(gesture_track("Walk", leg, "rotation")),
                f"Walk: {leg} does not move",
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
        for eye in ("LeftEye", "RightEye"):
            rows = gesture_track("Blink", eye, "scale")
            require(
                min(row[1] for row in rows) < rows[0][1] * 0.5,
                f"Blink: {eye} does not visibly close",
            )
        return summaries


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
    print("  All clips reset the same properties to neutral; scales stay positive.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
