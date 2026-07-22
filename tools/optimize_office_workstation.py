"""Batch the authored office workstation without changing its visible geometry.

Run through Blender so the source .blend remains the authority:

    blender --background assets/blender_source/office_workstation.blend \
        --python tools/optimize_office_workstation.py -- --mode optimize \
        --export assets/models/office_workstation.glb

The operation deliberately leaves the runtime-addressed nodes (screen elements,
claim tray, phone receiver, keyboard, cubicle back, and chair root) intact.
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector


CONTRACTS = {
    "OfficeWorkstation": ("EMPTY", None),
    "CubicleBack": ("MESH", "OfficeWorkstation"),
    "Keyboard": ("MESH", "OfficeWorkstation"),
    "TaskChair": ("EMPTY", "OfficeWorkstation"),
    "Screen": ("MESH", "OfficeWorkstation"),
    "ScreenHeader": ("MESH", "OfficeWorkstation"),
    "ScreenLine_0": ("MESH", "OfficeWorkstation"),
    "ScreenAlert": ("MESH", "OfficeWorkstation"),
    "PhoneReceiver": ("MESH", "OfficeWorkstation"),
    "ClaimTray": ("MESH", "OfficeWorkstation"),
}

# Keep the partition back as its own semantic mounting surface. The extra
# primitive is intentional: runtime nameplates and shell lamps inherit this
# node and must not measure against the perpendicular cubicle wing.
TARGET_MAX_PRIMITIVES = 28


JOIN_GROUPS = (
    ("DeskLeg_L", ("DeskLeg_L", "DeskLeg_R")),
    ("Monitor", ("Monitor", "MonitorStand")),
    (
        "Keyboard",
        (
            "Keyboard",
            "KeyboardKey_-0.17",
            "KeyboardKey_-0.10",
            "KeyboardKey_-0.03",
            "KeyboardKey_0.04",
            "KeyboardKey_0.11",
            "KeyboardKey_0.18",
        ),
    ),
    (
        "ChairSeat",
        (
            "ChairSeat",
            "ChairBack",
            "ChairPost",
            "ChairHub",
            "ChairSpoke_0",
            "ChairWheel_0",
            "ChairSpoke_1",
            "ChairWheel_1",
            "ChairSpoke_2",
            "ChairWheel_2",
            "ChairSpoke_3",
            "ChairWheel_3",
            "ChairSpoke_4",
            "ChairWheel_4",
            "ArmPost_-1",
            "ArmPad_-1",
            "ArmPost_1",
            "ArmPad_1",
            "ChairBackInset",
        ),
    ),
    (
        "DrawerPedestal",
        (
            "DrawerPedestal",
            "DrawerFace_0",
            "DrawerFace_1",
            "DrawerFace_2",
            "MonitorTopBar",
        ),
    ),
    (
        "DrawerHandle_0",
        ("DrawerHandle_0", "DrawerHandle_1", "DrawerHandle_2"),
    ),
    ("ClaimFile_0", ("ClaimFile_0", "ClaimFile_1", "ClaimFile_2")),
    ("CoffeeMug", ("CoffeeMug", "MugHandle")),
    ("DeskFrontTrim", ("DeskFrontTrim", "CableTray")),
    ("ScreenLine_0", ("ScreenLine_0", "ScreenLine_1", "ScreenLine_2")),
    ("Memo_A", ("Memo_A", "Memo_C")),
)


def world_spans(obj: bpy.types.Object) -> Vector:
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return Vector(tuple(
        max(point[axis] for point in points) - min(point[axis] for point in points)
        for axis in range(3)
    ))


def restore_cubicle_host_contract() -> None:
    """Split an older batched CubicleBack back into back and side-wing hosts.

    Blender's loose-parts split is geometry-preserving. The broadest X-facing
    component is the actual back partition; the perpendicular component keeps
    the durable CubicleWing_L name. Fresh, already-correct sources are no-ops.
    """
    cubicle_back = bpy.data.objects.get("CubicleBack")
    if cubicle_back is None or cubicle_back.type != "MESH":
        raise RuntimeError("missing mesh contract CubicleBack")
    if bpy.data.objects.get("CubicleWing_L") is not None:
        return
    # An unmerged back is broad in X but only a few centimetres deep in Y.
    if world_spans(cubicle_back).y <= 0.20:
        return

    before = set(bpy.context.scene.objects)
    bpy.ops.object.select_all(action="DESELECT")
    cubicle_back.select_set(True)
    bpy.context.view_layer.objects.active = cubicle_back
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    result = bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    if "FINISHED" not in result:
        raise RuntimeError(f"could not split semantic CubicleBack host: {result}")

    pieces = [cubicle_back] + [
        obj for obj in bpy.context.scene.objects
        if obj not in before and obj.type == "MESH" and obj.parent == cubicle_back.parent
    ]
    if len(pieces) != 2:
        raise RuntimeError(f"CubicleBack split produced {len(pieces)} pieces, expected 2")
    back_piece = max(pieces, key=lambda obj: world_spans(obj).x)
    wing_piece = pieces[0] if pieces[1] == back_piece else pieces[1]
    # Clear auto-generated names first so Blender cannot suffix the contracts.
    cubicle_back.name = "CubicleBack_SplitSource"
    back_piece.name = "CubicleBack"
    back_piece.data.name = "CubicleBack_Mesh"
    wing_piece.name = "CubicleWing_L"
    wing_piece.data.name = "CubicleWing_L_Mesh"

    back_spans = world_spans(back_piece)
    wing_spans = world_spans(wing_piece)
    if back_spans.x < 2.5 or back_spans.y > 0.20 or wing_spans.y < 0.75:
        raise RuntimeError(
            "unexpected cubicle split bounds: "
            f"back={tuple(round(value, 4) for value in back_spans)} "
            f"wing={tuple(round(value, 4) for value in wing_spans)}"
        )


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("inspect", "render", "optimize"), required=True)
    parser.add_argument("--export", type=Path)
    parser.add_argument("--render", type=Path)
    return parser.parse_args(argv)


def material_name(obj: bpy.types.Object, material_index: int) -> str:
    if material_index >= len(obj.material_slots):
        return "<none>"
    material = obj.material_slots[material_index].material
    return material.name if material is not None else "<none>"


def geometry_signature() -> tuple[str, Counter[str], int, tuple[float, ...]]:
    """Return a transform- and material-aware signature of visible mesh faces."""
    faces: list[tuple[object, ...]] = []
    triangles_by_material: Counter[str] = Counter()
    triangle_count = 0
    world_points: list[Vector] = []
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for obj in sorted(bpy.context.scene.objects, key=lambda item: item.name):
        if obj.type != "MESH" or obj.hide_render:
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        for polygon in mesh.polygons:
            name = material_name(obj, polygon.material_index)
            vertices = tuple(
                sorted(
                    tuple(round(value, 4) for value in (evaluated.matrix_world @ mesh.vertices[index].co))
                    for index in polygon.vertices
                )
            )
            faces.append((name, vertices))
        for triangle in mesh.loop_triangles:
            name = material_name(obj, triangle.material_index)
            triangles_by_material[name] += 1
            triangle_count += 1
        world_points.extend(evaluated.matrix_world @ vertex.co for vertex in mesh.vertices)
        evaluated.to_mesh_clear()
    faces.sort()
    digest = hashlib.sha256(repr(faces).encode("utf-8")).hexdigest()
    bounds = tuple(
        round(value, 5)
        for axis in range(3)
        for value in (
            min(point[axis] for point in world_points),
            max(point[axis] for point in world_points),
        )
    )
    return digest, triangles_by_material, triangle_count, bounds


def primitive_count() -> int:
    count = 0
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        used = {polygon.material_index for polygon in obj.data.polygons}
        count += max(1, len(used))
    return count


def print_stats(label: str) -> None:
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    digest, triangles_by_material, triangle_count, bounds = geometry_signature()
    print(
        "WORKSTATION_STATS",
        label,
        f"objects={len(bpy.context.scene.objects)}",
        f"meshes={len(meshes)}",
        f"primitives={primitive_count()}",
        f"triangles={triangle_count}",
        f"materials={len(triangles_by_material)}",
        f"bounds={bounds}",
        f"geometry_sha256={digest}",
    )


def validate_contracts() -> None:
    failures: list[str] = []
    for name, (expected_type, expected_parent) in CONTRACTS.items():
        obj = bpy.data.objects.get(name)
        if obj is None:
            failures.append(f"missing {name}")
            continue
        if obj.type != expected_type:
            failures.append(f"{name} is {obj.type}, expected {expected_type}")
        parent_name = obj.parent.name if obj.parent is not None else None
        if parent_name != expected_parent:
            failures.append(f"{name} parent is {parent_name}, expected {expected_parent}")
    chair = bpy.data.objects.get("TaskChair")
    if chair is not None and not any(child.type == "MESH" for child in chair.children):
        failures.append("TaskChair has no visible mesh child")
    if failures:
        raise RuntimeError("; ".join(failures))


def consolidate_material_slots(obj: bpy.types.Object) -> None:
    materials: list[bpy.types.Material | None] = []
    remap: dict[int, int] = {}
    for old_index, slot in enumerate(obj.material_slots):
        material = slot.material
        try:
            new_index = materials.index(material)
        except ValueError:
            new_index = len(materials)
            materials.append(material)
        remap[old_index] = new_index
    remapped_indices = [remap.get(polygon.material_index, 0) for polygon in obj.data.polygons]
    obj.data.materials.clear()
    for material in materials:
        obj.data.materials.append(material)
    for polygon, material_index in zip(obj.data.polygons, remapped_indices):
        polygon.material_index = material_index


def join_group(active_name: str, member_names: tuple[str, ...]) -> None:
    available = [bpy.data.objects.get(name) for name in member_names]
    if available[0] is None:
        # An already batched file is safe to inspect/export again.
        return
    missing = [name for name, obj in zip(member_names, available) if obj is None]
    if missing:
        if all(obj is None for obj in available[1:]):
            # The active object is the durable name retained by a prior pass.
            consolidate_material_slots(available[0])
            return
        raise RuntimeError(f"incomplete batch group {active_name}: missing {missing}")
    objects = [obj for obj in available if obj is not None]
    if any(obj.type != "MESH" for obj in objects):
        raise RuntimeError(f"batch group {active_name} contains a non-mesh object")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    active = objects[0]
    bpy.context.view_layer.objects.active = active
    bpy.ops.object.join()
    active.name = active_name
    active.data.name = f"{active_name}_BatchedMesh"
    consolidate_material_slots(active)


def apply_mesh_modifiers() -> None:
    """Freeze each authored bevel before joining so no source modifier is lost."""
    for obj in list(bpy.context.scene.objects):
        if obj.type != "MESH" or not obj.modifiers:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        for modifier in list(obj.modifiers):
            result = bpy.ops.object.modifier_apply(modifier=modifier.name)
            if "FINISHED" not in result:
                raise RuntimeError(f"could not apply {obj.name}/{modifier.name}: {result}")


def batch_workstation() -> None:
    restore_cubicle_host_contract()
    before_signature = geometry_signature()
    apply_mesh_modifiers()
    for active_name, members in JOIN_GROUPS:
        join_group(active_name, members)
    after_signature = geometry_signature()
    if after_signature != before_signature:
        print("WORKSTATION_GEOMETRY_BEFORE", before_signature)
        print("WORKSTATION_GEOMETRY_AFTER", after_signature)
        raise RuntimeError(
            "batching changed rendered geometry/materials: "
            f"before={before_signature[0]} after={after_signature[0]}"
        )
    if primitive_count() > TARGET_MAX_PRIMITIVES:
        raise RuntimeError(
            f"workstation still has {primitive_count()} primitives; "
            f"target is at most {TARGET_MAX_PRIMITIVES}"
        )
    validate_contracts()


def export_glb(path: Path) -> None:
    path = path.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    result = bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=False,
        export_yup=True,
        export_apply=False,
        export_animations=False,
        export_extras=True,
    )
    if "FINISHED" not in result:
        raise RuntimeError(f"glTF export failed: {result}")
    print("WORKSTATION_EXPORT", path)


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def render_preview(path: Path) -> None:
    path = path.resolve()
    path.parent.mkdir(parents=True, exist_ok=True)

    world = bpy.context.scene.world or bpy.data.worlds.new("WorkstationAuditWorld")
    bpy.context.scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.026, 0.038, 0.048, 1.0)
    background.inputs["Strength"].default_value = 0.22

    floor_material = bpy.data.materials.new("WorkstationAuditFloorMaterial")
    floor_material.diffuse_color = (0.14, 0.19, 0.20, 1.0)
    floor_material.roughness = 0.88
    bpy.ops.mesh.primitive_plane_add(size=12.0, location=(0.0, 0.28, -0.012))
    floor = bpy.context.object
    floor.name = "WorkstationAuditFloor"
    floor.data.materials.append(floor_material)

    bpy.ops.object.camera_add(location=(4.65, 5.30, 3.70))
    camera = bpy.context.object
    camera.name = "WorkstationAuditCamera"
    camera.data.lens = 58.0
    look_at(camera, Vector((0.0, 0.25, 0.88)))
    bpy.context.scene.camera = camera

    lights = (
        ("WorkstationAuditKey", (3.8, -3.4, 5.4), 1250.0, 4.2, (1.0, 0.82, 0.67)),
        ("WorkstationAuditFill", (-4.1, -1.6, 3.5), 900.0, 4.5, (0.62, 0.82, 1.0)),
        ("WorkstationAuditRim", (0.6, 4.8, 4.2), 1050.0, 3.4, (0.72, 1.0, 0.86)),
    )
    for name, location, energy, size, color in lights:
        light_data = bpy.data.lights.new(name, type="AREA")
        light_data.energy = energy
        light_data.shape = "DISK"
        light_data.size = size
        light_data.color = color
        light = bpy.data.objects.new(name, light_data)
        bpy.context.scene.collection.objects.link(light)
        light.location = location
        look_at(light, Vector((0.0, 0.25, 0.85)))

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 960
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(path)
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)
    print("WORKSTATION_RENDER", path)


def main() -> None:
    args = parse_args()
    validate_contracts()
    print_stats("BEFORE")
    if args.mode == "optimize":
        batch_workstation()
        print_stats("AFTER")
        bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
        if args.export is None:
            raise RuntimeError("--export is required in optimize mode")
        export_glb(args.export)
    if args.render is not None:
        render_preview(args.render)
    elif args.mode == "render":
        raise RuntimeError("--render is required in render mode")


if __name__ == "__main__":
    main()
