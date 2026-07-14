"""Repair the chicken employee's attachment transforms and re-export it.

Run with Blender in background mode. The source file is expected to already be
open; this script only makes small, deterministic hierarchy corrections.
"""

from pathlib import Path

import bpy
from mathutils import Vector


PROJECT_ROOT = Path(bpy.data.filepath).parents[2]
MODEL_PATH = PROJECT_ROOT / "assets" / "models" / "chicken_employee.glb"
SOURCE_PATH = PROJECT_ROOT / "assets" / "blender_source" / "chicken_employee.blend"
PREVIEW_PATH = PROJECT_ROOT / "captures" / "chicken_connected_runtime_source.png"


def object_named(name: str) -> bpy.types.Object:
    obj = bpy.data.objects.get(name)
    if obj is None:
        raise RuntimeError(f"Missing required chicken object: {name}")
    return obj


# The previous source accidentally stored the leg's lateral position on both
# the pivot and the child mesh. Keep the animation pivot at the hip and center
# the fused leg/foot mesh beneath it so the offset is applied exactly once.
left_pivot = object_named("LegLeftPivot")
right_pivot = object_named("LegRightPivot")
left_leg = object_named("LegLeftMesh")
right_leg = object_named("LegRightMesh")

left_pivot.location.x = -0.18
right_pivot.location.x = 0.18
left_leg.location.x = 0.0
right_leg.location.x = 0.0

# Sink every remaining accent slightly into the feather volume. These overlaps
# survive glTF import and keep the face/accessories visually attached at small
# in-game sizes without changing their material colors.
object_named("Eye_-1").location.y = -0.406
object_named("Eye_1").location.y = -0.406
object_named("Beak").location.y = -0.440
object_named("Comb").location.z = 1.455
object_named("BowTie").location.y = -0.365

# Feather_Torso was a single object but still contained three disconnected
# islands: the central bird and two detached wing ovals. Move only the smaller
# islands into the torso, then voxel-remesh the overlaps into one watertight
# feather volume. On later runs the mesh has one component, so this is stable.
torso = object_named("Feather_Torso")
mesh = torso.data
adjacency = [set() for _ in mesh.vertices]
for edge in mesh.edges:
    a, b = edge.vertices
    adjacency[a].add(b)
    adjacency[b].add(a)

remaining = set(range(len(mesh.vertices)))
components: list[set[int]] = []
while remaining:
    seed = remaining.pop()
    stack = [seed]
    component = {seed}
    while stack:
        current = stack.pop()
        for neighbor in adjacency[current]:
            if neighbor in remaining:
                remaining.remove(neighbor)
                component.add(neighbor)
                stack.append(neighbor)
    components.append(component)

if len(components) > 1:
    central_component = max(components, key=len)
    for component in components:
        if component is central_component:
            continue
        center_x = sum(mesh.vertices[index].co.x for index in component) / len(component)
        inward_shift = -0.095 if center_x > 0.0 else 0.095
        for index in component:
            mesh.vertices[index].co.x += inward_shift

    bpy.context.view_layer.objects.active = torso
    torso.select_set(True)
    torso.data.remesh_voxel_size = 0.018
    torso.data.remesh_voxel_adaptivity = 0.0
    bpy.ops.object.voxel_remesh()
    for polygon in torso.data.polygons:
        polygon.use_smooth = True

# The old wing islands were also egg-shaped and oversized. Once fused, tuck
# their outer volume into the torso so they read as soft folded wings instead
# of separate floating eggs. The custom marker keeps repeat runs idempotent.
if not torso.get("folded_wing_tuck_v2", False):
    for vertex in torso.data.vertices:
        x = vertex.co.x
        if abs(x) <= 0.30:
            continue
        side = 1.0 if x > 0.0 else -1.0
        vertex.co.x = side * (0.255 + (abs(x) - 0.255) * 0.52)
        vertex.co.y *= 0.78
        vertex.co.z = 0.04 + (vertex.co.z - 0.04) * 0.88

    bpy.context.view_layer.objects.active = torso
    torso.select_set(True)
    torso.data.remesh_voxel_size = 0.016
    torso.data.remesh_voxel_adaptivity = 0.0
    bpy.ops.object.voxel_remesh()
    for polygon in torso.data.polygons:
        polygon.use_smooth = True
    torso["folded_wing_tuck_v2"] = True

bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_PATH))

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(
    filepath=str(MODEL_PATH),
    export_format="GLB",
    use_selection=True,
    export_apply=True,
    export_yup=True,
)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(PREVIEW_PATH)

camera_data = bpy.data.cameras.new("ConnectionPreviewCamera")
camera = bpy.data.objects.new("ConnectionPreviewCamera", camera_data)
bpy.context.collection.objects.link(camera)
camera.location = (2.8, -5.1, 2.25)
camera.rotation_euler = (Vector((0.0, -0.02, 0.92)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.lens = 58
scene.camera = camera

key_data = bpy.data.lights.new("ConnectionPreviewKey", type="AREA")
key_data.energy = 900
key_data.shape = "DISK"
key_data.size = 4.0
key = bpy.data.objects.new("ConnectionPreviewKey", key_data)
bpy.context.collection.objects.link(key)
key.location = (-2.8, -3.5, 5.0)
key.rotation_euler = (Vector((0.0, 0.0, 0.9)) - key.location).to_track_quat("-Z", "Y").to_euler()

fill_data = bpy.data.lights.new("ConnectionPreviewFill", type="AREA")
fill_data.energy = 500
fill_data.size = 3.0
fill = bpy.data.objects.new("ConnectionPreviewFill", fill_data)
bpy.context.collection.objects.link(fill)
fill.location = (3.5, -1.0, 3.0)
fill.rotation_euler = (Vector((0.0, 0.0, 0.9)) - fill.location).to_track_quat("-Z", "Y").to_euler()

scene.world.color = (0.025, 0.035, 0.055)
bpy.ops.render.render(write_still=True)

print(f"Saved source: {SOURCE_PATH}")
print(f"Exported model: {MODEL_PATH}")
print(f"Rendered preview: {PREVIEW_PATH}")
