"""Measure demo motions and Celebrate from the restored master GLB.

For each skin influence, bound its vertices in joint space. The union of the
transformed boxes contains every weighted vertex (a convex combination of its
influences). This also includes all four faces at their runtime scale of one.
No model geometry or authoring data is copied into this LT's tracked files.
"""

import itertools
import json
from pathlib import Path
import sys

MASTER = Path(__file__).resolve().parents[3] / "20260919_flutterkaigi_mini"
sys.path.insert(0, str(MASTER / "tool"))

from check_dashmaru import Model, sampled_poses  # noqa: E402


def transformed(matrix, point):
    return tuple(
        sum(matrix[axis + component * 4] * point[component] for component in range(3))
        + matrix[axis + 12]
        for axis in range(3)
    )


def include(bounds, point):
    for axis, value in enumerate(point):
        bounds[0][axis] = min(bounds[0][axis], value)
        bounds[1][axis] = max(bounds[1][axis], value)


def empty_bounds():
    return [[float("inf")] * 3, [-float("inf")] * 3]


def corners(bounds):
    return list(itertools.product(*(zip(*bounds))))


def motion_bounds():
    model = Model(MASTER / "assets/models/dashmaru.glb")
    influence_bounds = {}
    for node_index, node in enumerate(model.nodes):
        if "mesh" not in node:
            continue
        mesh = model.doc["meshes"][node["mesh"]]
        for primitive in mesh["primitives"]:
            attributes = primitive["attributes"]
            positions = model.read(attributes["POSITION"])
            if "skin" not in node:
                bounds = influence_bounds.setdefault(node_index, empty_bounds())
                for position in positions:
                    include(bounds, position)
                continue
            skin = model.doc["skins"][node["skin"]]
            binds = model.read(skin["inverseBindMatrices"])
            joints = model.read(attributes["JOINTS_0"])
            weights = model.read(attributes["WEIGHTS_0"])
            for position, slots, row in zip(positions, joints, weights):
                for slot, weight in zip(slots, row):
                    if weight <= 0:
                        continue
                    joint = skin["joints"][slot]
                    bounds = influence_bounds.setdefault(joint, empty_bounds())
                    include(bounds, transformed(binds[slot], position))

    influence_corners = {
        node: corners(bounds) for node, bounds in influence_bounds.items()
    }
    faces = {
        (index, "scale"): (1, 1, 1)
        for index, node in enumerate(model.nodes)
        if node.get("name") in {"FaceNormal", "FaceSmile", "FaceSpiral", "FaceStrain"}
    }
    result = {}
    for animation in model.doc["animations"]:
        if animation["name"] not in {"Wave", "Run", "Shake", "Jump", "Celebrate"}:
            continue
        tracks, modes = {}, {}
        for channel in animation["channels"]:
            key = (channel["target"]["node"], channel["target"]["path"])
            sampler = animation["samplers"][channel["sampler"]]
            tracks[key] = model.read(sampler["output"])
            modes[key] = sampler.get("interpolation", "LINEAR")
        bounds = empty_bounds()
        samples = 0
        # Baked frames plus midpoint SLERP samples include jump apexes and
        # rotation extrema missed by checking only the neutral/first pose.
        for _, pose in sampled_poses(tracks, 1, modes):
            worlds = model.world_matrices(pose | faces)
            for node, points in influence_corners.items():
                for point in points:
                    x, y, z = transformed(worlds[node], point)
                    # Flutter Scene changes glTF's handedness on import.
                    include(bounds, (x, y, -z))
            samples += 1
        result[animation["name"]] = {"min": bounds[0], "max": bounds[1], "samples": samples}
    return result


if __name__ == "__main__":
    print(json.dumps(motion_bounds()))
