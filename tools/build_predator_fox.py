"""Build the non-graphic predator fox encounter asset for Pecking Order.

Run from the project root with Blender 5.x:
  & 'C:/Program Files/Blender Foundation/Blender 5.1/blender.exe' --background --factory-startup --python tools/build_predator_fox.py

The exported GLB contains named animation clips: Fox_Idle, Fox_NeckGrabShake,
Fox_CarryWalk, and Fox_PickupRotateShake. The latter three keep a limp,
non-graphic chicken prop
bone-parented to the fox's jaw for reliable in-game playback.
"""
from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "blender_source" / "predator_fox.blend"
MODEL = ROOT / "assets" / "models" / "predator_fox.glb"
PREVIEW = ROOT / "captures" / "predator_fox_carry.png"


def material(name, color, roughness=0.8):
    value = bpy.data.materials.new(name)
    value.diffuse_color = color
    value.use_nodes = True
    shader = value.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = roughness
    return value


def smooth(obj):
    for polygon in obj.data.polygons:
        polygon.use_smooth = True


def sphere(name, location, scale, mat, segments=20, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    smooth(obj)
    return obj


def cone(name, location, radius1, radius2, depth, mat, rotation=(0, 0, 0), vertices=16):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    smooth(obj)
    return obj


def tailored_tie(name, location, mat):
    """A single front-facing diamond: one clean blue shape in the office view."""
    outline = [(0.0, 0.155), (-0.092, 0.092), (-0.048, -0.115), (0.0, -0.205), (0.048, -0.115), (0.092, 0.092)]
    vertices = [(x, 0.0, z) for x, z in outline]
    faces = [list(range(6))]
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    return obj


def cylinder_between(name, start, end, radius, mat):
    start, end = Vector(start), Vector(end)
    delta = end - start
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=delta.length, location=(start + end) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(delta.normalized())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(mat)
    smooth(obj)
    return obj


def tapered_segment_between(name, start, end, root_radius, tip_radius, mat, vertices=16):
    """Create a smooth, tapered segment aligned to its rig bone."""
    start, end = Vector(start), Vector(end)
    delta = end - start
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=root_radius, radius2=tip_radius, depth=delta.length, location=(start + end) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(delta.normalized())
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.data.materials.append(mat)
    smooth(obj)
    return obj


def parent_bone(obj, armature, bone):
    matrix = obj.matrix_world.copy()
    obj.parent = armature
    obj.parent_type = "BONE"
    obj.parent_bone = bone
    obj.matrix_world = matrix


def empty(name, location, display_size=0.035):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.empty_display_type = "SPHERE"
    obj.empty_display_size = display_size
    obj.location = location
    return obj


def add_bones():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.object
    armature.name = "FoxArmature"
    armature.data.name = "FoxArmature"
    edit = armature.data.edit_bones
    root = edit[0]
    root.name, root.head, root.tail = "root", (0, 0, 0), (0, 0, 0.58)
    specs = {
        "spine": ((0, 0, 0.48), (0, 0, 1.22), "root"),
        "head": ((0, -0.12, 1.12), (0, -0.52, 1.40), "spine"),
        "jaw": ((0, -0.52, 1.27), (0, -0.72, 1.24), "head"),
        "tail": ((0, 0.34, 0.88), (0, 0.72, 0.96), "spine"),
        "tail_mid": ((0, 0.72, 0.96), (0, 1.10, 1.05), "tail"),
        "tail_tip": ((0, 1.10, 1.05), (0, 1.38, 1.12), "tail_mid"),
        "leg_FL": ((-0.26, -0.30, 0.57), (-0.26, -0.31, 0.34), "root"),
        "leg_FR": ((0.26, -0.30, 0.57), (0.26, -0.31, 0.34), "root"),
        "leg_BL": ((-0.28, 0.28, 0.55), (-0.28, 0.29, 0.33), "root"),
        "leg_BR": ((0.28, 0.28, 0.55), (0.28, 0.29, 0.33), "root"),
        "shin_FL": ((-0.26, -0.31, 0.34), (-0.26, -0.32, 0.07), "leg_FL"),
        "shin_FR": ((0.26, -0.31, 0.34), (0.26, -0.32, 0.07), "leg_FR"),
        "shin_BL": ((-0.28, 0.29, 0.33), (-0.28, 0.30, 0.07), "leg_BL"),
        "shin_BR": ((0.28, 0.29, 0.33), (0.28, 0.30, 0.07), "leg_BR"),
    }
    for name, (head, tail, parent_name) in specs.items():
        bone = edit.new(name)
        bone.head, bone.tail = head, tail
        bone.parent = edit[parent_name]
    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def key_pose(pose_bone, frame, rotation=(0, 0, 0), location=None):
    pose_bone.rotation_mode = "XYZ"
    pose_bone.rotation_euler = rotation
    pose_bone.keyframe_insert("rotation_euler", frame=frame)
    if location is not None:
        pose_bone.location = location
        pose_bone.keyframe_insert("location", frame=frame)


def action(armature, name, frames, loop=False):
    clip = bpy.data.actions.new(name)
    # Keep every authored clip in the source .blend.  Only the active action
    # has a direct user on save otherwise, which makes a later rig edit lose
    # the alternate clips even though the immediate GLB export succeeded.
    clip.use_fake_user = True
    armature.animation_data_create()
    armature.animation_data.action = clip
    for frame, values in frames:
        for bone_name, attrs in values.items():
            key_pose(armature.pose.bones[bone_name], frame, **attrs)
    # Blender 5 stores keyframe curves inside action slots/layers rather than
    # exposing Action.fcurves. The explicit first/last poses make the intended
    # loop boundary clear to the glTF exporter without relying on curve APIs.
    return clip


def make_actions(armature):
    neutral = {bone: {"rotation": (0, 0, 0)} for bone in armature.pose.bones.keys()}
    idle = action(armature, "Fox_Idle", [
        (1, neutral),
        (20, {"spine": {"rotation": (0.025, 0, 0)}, "head": {"rotation": (-0.035, 0.02, 0)}, "tail": {"rotation": (0, 0.08, 0)}}),
        (40, neutral),
    ], True)
    grab = action(armature, "Fox_NeckGrabShake", [
        (1, neutral),
        (8, {"spine": {"rotation": (0.20, 0, 0)}, "head": {"rotation": (0.24, 0, 0)}, "jaw": {"rotation": (0.16, 0, 0)}, "leg_FL": {"rotation": (-0.15, 0, 0)}, "leg_FR": {"rotation": (-0.15, 0, 0)}}),
        # Two sharp, opposing whips read as a forceful dispatch without gore;
        # the jaw-parented chicken follows as one limp, weighty body.
        (13, {"spine": {"rotation": (-0.10, 0, 0.15)}, "head": {"rotation": (-0.26, 0, 0.58)}, "jaw": {"rotation": (0.12, 0, 0)}, "tail": {"rotation": (0, 0, -0.30)}}),
        (18, {"spine": {"rotation": (-0.10, 0, -0.15)}, "head": {"rotation": (-0.26, 0, -0.58)}, "jaw": {"rotation": (0.12, 0, 0)}, "tail": {"rotation": (0, 0, 0.30)}}),
        (25, {"head": {"rotation": (-0.10, 0, 0.16)}, "spine": {"rotation": (0.08, 0, 0)}}),
        (36, neutral),
    ])
    carry = action(armature, "Fox_CarryWalk", [
        # Alternating roll through the torso and a smaller counter-tilt in the
        # head create a confident, unhurried swagger without destabilizing
        # the jaw-held chicken.
        (1, {"spine": {"rotation": (0.025, 0, 0.045)}, "head": {"rotation": (-0.12, 0, -0.028)}, "jaw": {"rotation": (0.06, 0, 0)}, "leg_FL": {"rotation": (0.48, 0, 0)}, "leg_FR": {"rotation": (-0.48, 0, 0)}, "leg_BL": {"rotation": (-0.38, 0, 0)}, "leg_BR": {"rotation": (0.38, 0, 0)}, "shin_FL": {"rotation": (-0.30, 0, 0)}, "shin_FR": {"rotation": (0.12, 0, 0)}, "shin_BL": {"rotation": (0.10, 0, 0)}, "shin_BR": {"rotation": (-0.26, 0, 0)}, "tail": {"rotation": (0, 0, 0.12)}}),
        # Passing pose: knees soften and the tail chain eases through center.
        # Explicit keys prevent the lower legs and tail tips from feeling like
        # they snap between the two contact poses.
        (6, {"spine": {"rotation": (-0.025, 0, 0.010)}, "head": {"rotation": (-0.09, 0, -0.006)}, "jaw": {"rotation": (0.06, 0, 0)}, "leg_FL": {"rotation": (0.08, 0, 0)}, "leg_FR": {"rotation": (-0.08, 0, 0)}, "leg_BL": {"rotation": (-0.10, 0, 0)}, "leg_BR": {"rotation": (0.10, 0, 0)}, "shin_FL": {"rotation": (-0.08, 0, 0)}, "shin_FR": {"rotation": (0.04, 0, 0)}, "shin_BL": {"rotation": (0.05, 0, 0)}, "shin_BR": {"rotation": (-0.07, 0, 0)}, "tail": {"rotation": (0, 0, 0.03)}}),
        (12, {"spine": {"rotation": (0.025, 0, -0.045)}, "head": {"rotation": (-0.12, 0, 0.028)}, "jaw": {"rotation": (0.06, 0, 0)}, "leg_FL": {"rotation": (-0.48, 0, 0)}, "leg_FR": {"rotation": (0.48, 0, 0)}, "leg_BL": {"rotation": (0.38, 0, 0)}, "leg_BR": {"rotation": (-0.38, 0, 0)}, "shin_FL": {"rotation": (0.12, 0, 0)}, "shin_FR": {"rotation": (-0.30, 0, 0)}, "shin_BL": {"rotation": (-0.26, 0, 0)}, "shin_BR": {"rotation": (0.10, 0, 0)}, "tail": {"rotation": (0, 0, -0.12)}}),
        (18, {"spine": {"rotation": (-0.025, 0, -0.010)}, "head": {"rotation": (-0.09, 0, 0.006)}, "jaw": {"rotation": (0.06, 0, 0)}, "leg_FL": {"rotation": (-0.08, 0, 0)}, "leg_FR": {"rotation": (0.08, 0, 0)}, "leg_BL": {"rotation": (0.10, 0, 0)}, "leg_BR": {"rotation": (-0.10, 0, 0)}, "shin_FL": {"rotation": (0.04, 0, 0)}, "shin_FR": {"rotation": (-0.08, 0, 0)}, "shin_BL": {"rotation": (-0.07, 0, 0)}, "shin_BR": {"rotation": (0.05, 0, 0)}, "tail": {"rotation": (0, 0, -0.03)}}),
        (24, {"spine": {"rotation": (0.025, 0, 0.045)}, "head": {"rotation": (-0.12, 0, -0.028)}, "jaw": {"rotation": (0.06, 0, 0)}, "leg_FL": {"rotation": (0.48, 0, 0)}, "leg_FR": {"rotation": (-0.48, 0, 0)}, "leg_BL": {"rotation": (-0.38, 0, 0)}, "leg_BR": {"rotation": (0.38, 0, 0)}, "shin_FL": {"rotation": (-0.30, 0, 0)}, "shin_FR": {"rotation": (0.12, 0, 0)}, "shin_BL": {"rotation": (0.10, 0, 0)}, "shin_BR": {"rotation": (-0.26, 0, 0)}, "tail": {"rotation": (0, 0, 0.12)}}),
    ], True)
    pickup_rotate_shake = action(armature, "Fox_PickupRotateShake", [
        (1, neutral),
        # Lower and bite at the neck.
        (9, {"spine": {"rotation": (0.16, 0, 0)}, "head": {"rotation": (0.30, 0, 0)}, "jaw": {"rotation": (0.19, 0, 0)}, "leg_FL": {"rotation": (-0.14, 0, 0)}, "leg_FR": {"rotation": (-0.14, 0, 0)}}),
        # Lift and roll the head; this is the setup that transfers the limp
        # chicken from the floor into the jaw-gripped hanging pose.
        (18, {"spine": {"rotation": (-0.08, 0, 0.18)}, "head": {"rotation": (-0.20, 0, 0.34)}, "jaw": {"rotation": (0.08, 0, 0)}, "tail": {"rotation": (0, 0, -0.28)}}),
        (26, {"spine": {"rotation": (-0.10, 0, -0.20)}, "head": {"rotation": (-0.22, 0, -0.42)}, "jaw": {"rotation": (0.08, 0, 0)}, "tail": {"rotation": (0, 0, 0.32)}}),
        # Two deliberately hard shakes after the rotation.
        (33, {"spine": {"rotation": (-0.13, 0, 0.22)}, "head": {"rotation": (-0.30, 0, 0.65)}, "jaw": {"rotation": (0.11, 0, 0)}, "tail": {"rotation": (0, 0, -0.52)}}),
        (39, {"spine": {"rotation": (-0.13, 0, -0.22)}, "head": {"rotation": (-0.30, 0, -0.65)}, "jaw": {"rotation": (0.11, 0, 0)}, "tail": {"rotation": (0, 0, 0.52)}}),
        (50, neutral),
    ])
    armature.animation_data.action = idle
    return [idle, grab, carry, pickup_rotate_shake]


def build_fox(armature, mats):
    orange, cream, dark, black, paw, navy, blue, shirt, gold, ruff = mats["orange"], mats["cream"], mats["dark"], mats["black"], mats["paw"], mats["navy"], mats["blue"], mats["shirt"], mats["gold"], mats["ruff"]
    parts = []
    parts += [sphere("FoxBody", (0, 0.03, 0.84), (0.41, 0.62, 0.48), orange), sphere("FoxChest", (0, -0.28, 0.95), (0.31, 0.28, 0.38), cream)]
    # Layered chest ruff softens the silhouette and makes the torso feel more
    # tactile than a single primitive under the office lighting.
    parts += [
        sphere("FoxChestRuffL", (-0.135, -0.405, 0.995), (0.105, 0.070, 0.135), ruff, 16, 10),
        sphere("FoxChestRuffC", (0.0, -0.390, 0.920), (0.115, 0.075, 0.145), ruff, 16, 10),
        sphere("FoxChestRuffR", (0.135, -0.405, 0.995), (0.105, 0.070, 0.135), ruff, 16, 10),
    ]
    # Keep the shirt front quiet so the blue tie is the one clear professional
    # accent visible from the office camera.
    shirt_front = sphere("FoxShirtFront", (0, -0.555, 1.085), (0.145, 0.028, 0.145), shirt, 16, 8)
    tie_blade = tailored_tie("FoxTieBlade", (0, -0.607, 1.000), blue)
    parts += [shirt_front, tie_blade]
    parts += [sphere("FoxNeck", (0, -0.25, 1.18), (0.30, 0.28, 0.34), orange), sphere("FoxHead", (0, -0.43, 1.40), (0.33, 0.36, 0.30), orange)]
    muzzle = sphere("FoxMuzzle", (0, -0.72, 1.32), (0.22, 0.25, 0.15), cream)
    # A real lower jaw closes the visual gap beneath the muzzle. It follows
    # the jaw bone rather than the head, making the bite read as one connected
    # head assembly while it animates.
    lower_jaw = sphere("FoxLowerJaw", (0, -0.73, 1.235), (0.18, 0.21, 0.070), cream)
    nose = sphere("FoxNose", (0, -0.95, 1.34), (0.09, 0.075, 0.07), black, 16, 8)
    cheek_l = sphere("FoxCheekL", (-0.235, -0.58, 1.34), (0.14, 0.105, 0.13), cream, 16, 10)
    cheek_r = sphere("FoxCheekR", (0.235, -0.58, 1.34), (0.14, 0.105, 0.13), cream, 16, 10)
    parts += [muzzle, lower_jaw, nose, cheek_l, cheek_r]
    for side in (-1, 1):
        ear = cone("FoxEar", (side * 0.20, -0.40, 1.73), 0.17, 0.025, 0.40, orange, rotation=(0.15, 0, side * 0.10))
        inner = cone("FoxEarInner", (side * 0.20, -0.455, 1.73), 0.085, 0.012, 0.29, dark, rotation=(0.15, 0, side * 0.10), vertices=12)
        eye = sphere("FoxEye", (side * 0.15, -0.71, 1.47), (0.055, 0.025, 0.07), black, 12, 8)
        # A restrained catchlight makes the eyes read as glossy and attentive
        # from the office camera, without changing the dark, cozy expression.
        eye_glint = sphere("FoxEyeGlint", (side * 0.136, -0.736, 1.495), (0.016, 0.009, 0.019), shirt, 10, 6)
        brow = sphere("FoxBrow", (side * 0.16, -0.69, 1.535), (0.095, 0.026, 0.030), dark, 12, 8)
        parts += [ear, inner, eye, eye_glint, brow]
    for side, bone in [(-1, "leg_FL"), (1, "leg_FR"), (-1, "leg_BL"), (1, "leg_BR")]:
        y = -0.30 if "F" in bone else 0.30
        upper_leg = cylinder_between("FoxUpperLeg", (side * 0.25, y, 0.58), (side * 0.25, y - 0.010, 0.34), 0.115, orange)
        shin = cylinder_between("FoxShin", (side * 0.25, y - 0.010, 0.34), (side * 0.25, y - 0.025, 0.14), 0.090, orange)
        foot = sphere("FoxPaw", (side * 0.25, y - 0.10, 0.09), (0.13, 0.20, 0.075), paw)
        shin_bone = "shin_" + bone.split("_")[1]
        parent_bone(upper_leg, armature, bone); parent_bone(shin, armature, shin_bone); parent_bone(foot, armature, shin_bone)
        for toe_index, toe_x in enumerate((-0.052, 0.0, 0.052)):
            toe = sphere("FoxToe_%s_%d" % (bone, toe_index), (side * 0.25 + toe_x, y - 0.245, 0.082), (0.030, 0.045, 0.022), dark, 10, 6)
            parent_bone(toe, armature, shin_bone)
    # Short whiskers add facial readability in close views while remaining
    # bone-bound and stable throughout the head shake animation.
    for side in (-1, 1):
        for whisker_index, dz in enumerate((-0.025, 0.040)):
            whisker = cylinder_between("FoxWhisker_%d_%d" % (side, whisker_index), (side * 0.21, -0.805, 1.35 + dz), (side * 0.48, -0.845, 1.33 + dz * 0.55), 0.008, dark)
            parent_bone(whisker, armature, "head")
    # Overlapping rounded tufts give the tail a warm, plush curl while the
    # matching bone chain supplies a gentle delayed follow-through.
    tail = cone("FoxTailBase", (0, 0.60, 0.94), 0.23, 0.10, 0.72, orange, rotation=(math.pi / 2.65, 0, 0))
    tail_mid = cone("FoxTailMid", (0, 0.98, 1.04), 0.18, 0.075, 0.68, orange, rotation=(math.pi / 2.65, 0, 0))
    tail_tip = cone("FoxTailTip", (0, 1.24, 1.10), 0.135, 0.040, 0.50, orange, rotation=(math.pi / 2.65, 0, 0))
    parent_bone(tail, armature, "tail")
    # The visible tufts share the root pivot. Their child bones remain in the
    # rig for future deformation work, while a complete tail swing can never
    # pull the decorative segments apart at an offset pivot.
    parent_bone(tail_mid, armature, "tail")
    parent_bone(tail_tip, armature, "tail")
    for item in parts:
        if item == tail or item.name in ["FoxLeg", "FoxPaw"]:
            continue
        if item.name == "FoxLowerJaw":
            parent_bone(item, armature, "jaw")
        elif item.name == "FoxNeck" or item.name.startswith(("FoxHead", "FoxMuzzle", "FoxNose", "FoxCheek", "FoxEar", "FoxEye", "FoxBrow")):
            # The neck is part of the head chain. Keeping it on the head bone
            # prevents a seam from opening when the head turns during a shake.
            parent_bone(item, armature, "head")
        else:
            parent_bone(item, armature, "spine")


def build_limp_chicken(armature, mats):
    # Simple stylized prop: eyes closed and wings relaxed, no wounds or gore.
    # The neck is at the jaw while the body hangs below it: readable in the
    # office camera without becoming a bulky foreground occluder.
    body = sphere("LimpChickenBody", (0, -0.94, 0.98), (0.15, 0.18, 0.29), mats["chicken"])
    neck = cylinder_between("LimpChickenNeck", (0, -0.92, 1.25), (0, -0.91, 1.12), 0.045, mats["chicken"])
    head = sphere("LimpChickenHead", (0, -0.91, 1.28), (0.08, 0.09, 0.075), mats["chicken"])
    beak = cone("LimpChickenBeak", (0, -1.00, 1.28), 0.037, 0.008, 0.09, mats["beak"], rotation=(math.pi / 2, 0, 0), vertices=8)
    wing_l = sphere("LimpChickenWingL", (-0.14, -0.94, 0.99), (0.035, 0.11, 0.12), mats["wing"])
    wing_r = sphere("LimpChickenWingR", (0.14, -0.94, 0.99), (0.035, 0.11, 0.12), mats["wing"])
    # Parent each component directly to the jaw while preserving its displayed
    # world transform. This keeps the chicken centered in the mouth on export.
    for obj in [body, neck, head, beak, wing_l, wing_r]:
        parent_bone(obj, armature, "jaw")


def setup_preview(mats, armature):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(PREVIEW)
    scene.world.color = (0.055, 0.060, 0.072)
    bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, 0))
    ground = bpy.context.object
    ground.name = "PreviewFloor"
    ground.data.materials.append(mats["ground"])
    bpy.ops.object.light_add(type="AREA", location=(-3, -4, 5)); bpy.context.object.data.energy = 850; bpy.context.object.data.shape = "DISK"; bpy.context.object.data.size = 4
    bpy.ops.object.light_add(type="AREA", location=(3, 2, 3)); bpy.context.object.data.energy = 450; bpy.context.object.data.color = (0.55, 0.70, 1.0); bpy.context.object.data.size = 3
    bpy.ops.object.camera_add(location=(3.4, -5.6, 2.5))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0, 0, 0.93)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 60
    scene.camera = camera
    # The carried chicken is an export/reference prop. Runtime replaces it
    # with a live ChickenView, so omit it from the fox beauty render.
    for obj in bpy.context.scene.objects:
        if obj.name.startswith("LimpChicken"):
            obj.hide_render = True
    armature.animation_data.action = bpy.data.actions["Fox_CarryWalk"]
    scene.frame_set(1)
    bpy.ops.render.render(write_still=True)


def main():
    bpy.ops.object.select_all(action="SELECT"); bpy.ops.object.delete(use_global=False)
    mats = {
        "orange": material("Fox_Russet", (0.60, 0.18, 0.055, 1)), "cream": material("Fox_Cream", (0.86, 0.70, 0.46, 1)),
        "dark": material("Fox_Ear_Dark", (0.14, 0.045, 0.028, 1)), "black": material("Fox_Eye_Nose", (0.012, 0.010, 0.010, 1), 0.22),
        "paw": material("Fox_Paw_Dark", (0.17, 0.070, 0.035, 1)), "navy": material("Fox_Suit_Navy", (0.025, 0.065, 0.14, 1), 0.62), "blue": material("Fox_Tie_Cobalt", (0.055, 0.28, 0.78, 1), 0.38), "shirt": material("Fox_Shirt_White", (0.92, 0.94, 0.96, 1), 0.52), "gold": material("Fox_Tie_Pin_Gold", (0.88, 0.52, 0.08, 1), 0.45), "ruff": material("Fox_Ruff_Cream", (0.94, 0.80, 0.60, 1), 0.78), "chicken": material("Chicken_Oat", (0.66, 0.43, 0.22, 1)),
        "wing": material("Chicken_Wing", (0.31, 0.13, 0.05, 1)), "beak": material("Chicken_Beak", (0.95, 0.46, 0.06, 1)), "ground": material("PreviewFloor", (0.10, 0.12, 0.13, 1)),
    }
    armature = add_bones(); build_fox(armature, mats); build_limp_chicken(armature, mats)
    # This is the true clamp center: just forward of the jaw hinge and below
    # the snout.  Gameplay aligns the live chicken's NeckGripSocket to it.
    jaw_grip_socket = empty("JawGripSocket", (0.0, -0.92, 1.25))
    # Empty transforms are lazily evaluated in Blender.  Resolve it before
    # bone parenting so the socket retains this mouth-space world position.
    bpy.context.view_layer.update()
    parent_bone(jaw_grip_socket, armature, "jaw")
    make_actions(armature); setup_preview(mats, armature)
    SOURCE.parent.mkdir(parents=True, exist_ok=True); MODEL.parent.mkdir(parents=True, exist_ok=True); PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.type in {"MESH", "ARMATURE", "EMPTY"} and obj.name != "PreviewFloor": obj.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(filepath=str(MODEL), export_format="GLB", use_selection=True, export_yup=True, export_apply=False, export_animations=True, export_animation_mode="ACTIONS", export_force_sampling=True, export_skins=True)
    print("PREDATOR_FOX_BUILD_COMPLETE")
    print(f"source={SOURCE}")
    print(f"model={MODEL}")
    print(f"preview={PREVIEW}")
    print("actions=Fox_Idle,Fox_NeckGrabShake,Fox_CarryWalk,Fox_PickupRotateShake")


if __name__ == "__main__":
    main()
