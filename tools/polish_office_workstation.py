"""Refine authored workstation edges; retain every gameplay attachment node.

Run: blender --background --python tools/polish_office_workstation.py
The named modifiers make this pass safe to repeat without accumulating bevels.
"""
from pathlib import Path
import math
import bpy

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/blender_source/office_workstation.blend"
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
root = bpy.data.objects["OfficeWorkstation"]
parts = [root, *root.children_recursive]
contracts = {obj.name: (obj.parent.name if obj.parent else None) for obj in parts}

# Replace the solid mug with a rounded hollow vessel and an open loop handle.
# Keep its object, local origin, material count and attachment parent intact.
mug = bpy.data.objects["CoffeeMug"]
ceramic = mug.data.materials[0]
vertices, faces, colors = [], [], []
cream = (0.78, 0.72, 0.57, 1.0)
profile = [(0, -.12), (.083, -.12), (.099, -.108), (.105, .105),
           (.102, .12), (.087, .12), (.082, .106), (.077, -.088), (0, -.088)]
segments = 24
for radius, height in profile:
    for index in range(segments):
        angle = math.tau * index / segments
        vertices.append((radius * math.cos(angle), radius * math.sin(angle), height))
        colors.append(cream)
for row in range(len(profile) - 1):
    for index in range(segments):
        a, b = row * segments + index, row * segments + (index + 1) % segments
        if row == 0:
            faces.append((a, b + segments, a + segments))
        elif row == len(profile) - 2:
            faces.append((a, b, b + segments))
        else:
            faces.append((a, b, b + segments, a + segments))
offset = len(vertices)
for major in range(24):
    angle = math.tau * major / 24
    for minor in range(8):
        tube = math.tau * minor / 8
        vertices.append((.135 + (.075 + .018 * math.cos(tube)) * math.cos(angle),
                         .018 * math.sin(tube), (.075 + .018 * math.cos(tube)) * math.sin(angle)))
        colors.append(cream)
for major in range(24):
    for minor in range(8):
        a = offset + major * 8 + minor
        b = offset + major * 8 + (minor + 1) % 8
        c = offset + ((major + 1) % 24) * 8 + (minor + 1) % 8
        d = offset + ((major + 1) % 24) * 8 + minor
        faces.append((a, b, c, d))
# Opaque coffee surface below the lip; vertex color keeps one draw surface.
offset = len(vertices)
vertices.append((0, 0, .065))
colors.append((.065, .027, .010, 1))
for index in range(segments):
    angle = math.tau * index / segments
    vertices.append((.082 * math.cos(angle), .082 * math.sin(angle), .065))
    colors.append((.10, .045, .016, 1))
for index in range(segments):
    faces.append((offset, offset + 1 + index, offset + 1 + (index + 1) % segments))
mesh = bpy.data.meshes.new("HollowCeramicMug")
mesh.from_pydata(vertices, [], faces)
mesh.materials.append(ceramic)
paint = mesh.color_attributes.new(name="MugTint", type="FLOAT_COLOR", domain="POINT")
for index, color in enumerate(colors):
    paint.data[index].color = color
for polygon in mesh.polygons:
    polygon.use_smooth = True
mug.data = mesh
# Put the mug on the desktop beside the photograph, clear of the claim tray.
mug.location = (.40, -.40, 1.0)
mug.rotation_euler = (0.0, 0.0, math.pi)
ceramic.use_nodes = True
color_node = ceramic.node_tree.nodes.get("MugTint") or ceramic.node_tree.nodes.new("ShaderNodeVertexColor")
color_node.name = "MugTint"
color_node.layer_name = "MugTint"
ceramic.node_tree.links.new(color_node.outputs["Color"], ceramic.node_tree.nodes.get("Principled BSDF").inputs["Base Color"])
ceramic.node_tree.nodes.get("Principled BSDF").inputs["Roughness"].default_value = .32
targets = {
    "DeskSurface": 0.018,
    "DeskFrontTrim": 0.010,
    "Monitor": 0.014,
    "DrawerPedestal": 0.012,
    "ChairSeat": 0.014,
    "PhoneReceiver": 0.010,
    "Keyboard": 0.006,
    "ClaimTray": 0.008,
}
for name, width in targets.items():
    obj = bpy.data.objects.get(name)
    if obj is None or obj.type != "MESH":
        raise RuntimeError(f"Missing workstation contract: {name}")
    for modifier in list(obj.modifiers):
        if modifier.name.startswith("OfficeEdgePolish"):
            obj.modifiers.remove(modifier)
    bevel = obj.modifiers.new("OfficeEdgePolish", "BEVEL")
    bevel.width = width
    bevel.segments = 3
    bevel.limit_method = "ANGLE"
    bevel.angle_limit = 0.65
    bevel.use_clamp_overlap = True
    bevel.harden_normals = True
    print(f"POLISHED {name} width={width} scale={tuple(obj.scale)}")

assert contracts == {obj.name: (obj.parent.name if obj.parent else None) for obj in parts}
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
bpy.ops.object.select_all(action="DESELECT")
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = root
bpy.ops.export_scene.gltf(filepath=str(ROOT / "assets/models/office_workstation.glb"),
    export_format="GLB", use_selection=True, export_yup=True, export_apply=True,
    export_animations=False, export_extras=True)
print(f"WORKSTATION_POLISH_COMPLETE nodes={len(parts)} contracts=preserved")
