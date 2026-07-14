"""Render actual game-model proof frames for the fox jaw-grab sequence.

The employee chicken GLB is held at its neck by the fox jaw.  A damped
two-axis pendulum integrates the jaw's motion into delayed body swing, while
the chicken's real armature relaxes its wings and legs.  It is a visual
prototype of the runtime ragdoll response, not a replacement for Godot joints.
"""
from __future__ import annotations

from pathlib import Path
import math
import shutil
import bpy
from mathutils import Matrix, Vector


ROOT = Path(__file__).resolve().parents[1]
FOX = ROOT / "assets" / "models" / "predator_fox.glb"
CHICKEN = ROOT / "assets" / "models" / "chicken_employee.glb"
FRAMES = ROOT / "captures" / "predator_fox_pickup_rotate_ragdoll_frames"


def hide_nonvisual_helpers(objects) -> None:
    for obj in objects:
        if obj.name in {"Cube", "Icosphere"} or any(token in obj.name for token in [
            "Accessory", "BowTie", "Headset", "Glasses", "Visor", "Tie", "Lanyard", "Badge",
        ]):
            obj.hide_render = True


def main() -> None:
    bpy.ops.import_scene.gltf(filepath=str(FOX))
    fox_objects = list(bpy.context.scene.objects)
    hide_nonvisual_helpers(fox_objects)
    for obj in fox_objects:
        if obj.name.startswith("LimpChicken"):
            obj.hide_render = True

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(CHICKEN))
    chicken_objects = [obj for obj in bpy.data.objects if obj not in before]
    hide_nonvisual_helpers(chicken_objects)
    chicken_root = bpy.data.objects["ChickenRig"]
    chicken_armature = bpy.data.objects["ChickenArmature"]
    fox_armature = bpy.data.objects["FoxArmature"]

    if FRAMES.exists():
        shutil.rmtree(FRAMES)
    FRAMES.mkdir(parents=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.world.color = (0.055, 0.060, 0.072)
    bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, 0))
    bpy.ops.object.light_add(type="AREA", location=(-3, -4, 5))
    bpy.context.object.data.energy, bpy.context.object.data.shape, bpy.context.object.data.size = 850, "DISK", 4
    bpy.ops.object.light_add(type="AREA", location=(3, 2, 3))
    bpy.context.object.data.energy, bpy.context.object.data.color, bpy.context.object.data.size = 450, (0.55, 0.70, 1.0), 3
    bpy.ops.object.camera_add(location=(3.4, -5.6, 2.5))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0, 0, 0.91)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 60
    scene.camera = camera

    fox_armature.animation_data.action = bpy.data.actions["Fox_PickupRotateShake"]
    swing_x = swing_z = velocity_x = velocity_z = 0.0
    previous_jaw_yaw = 0.0
    ground_root = Vector((-0.12, -1.00, 0.0))
    for image_index, frame in enumerate(range(1, 51, 2), start=1):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        jaw = fox_armature.matrix_world @ fox_armature.pose.bones["jaw"].matrix
        jaw_yaw = jaw.to_euler().z
        jaw_acceleration = jaw_yaw - previous_jaw_yaw
        previous_jaw_yaw = jaw_yaw
        pickup = max(0.0, min(1.0, (frame - 9) / 15.0))
        # Once grabbed, the body becomes a delayed, heavily damped pendulum.
        # The larger range is intentional: the neck stays in the jaws while
        # the chicken's weight, wings, and legs continue to flop behind it.
        if pickup > 0.0:
            velocity_z = (velocity_z + (-jaw_acceleration * 2.8 - swing_z * 0.20)) * 0.76
            velocity_x = (velocity_x + (math.sin(frame * 0.52) * 0.085 - swing_x * 0.18)) * 0.78
            swing_z += velocity_z
            swing_x += velocity_x
        swing_z = max(-0.48, min(0.48, swing_z))
        swing_x = max(-0.30, min(0.30, swing_x))
        neck_root = jaw.translation + Vector((0.0, -0.39, -0.88))
        root_position = ground_root.lerp(neck_root, pickup)
        pickup_roll = math.sin(pickup * math.pi) * 0.52
        # Grip point is at the neck/head. The body returns to a predominantly
        # vertical hang after the pickup rotation, then reacts to each shake.
        chicken_root.matrix_world = (
            Matrix.Translation(root_position)
            @ Matrix.Rotation(pickup_roll + swing_z, 4, "Z")
            @ Matrix.Rotation(swing_x, 4, "X")
            @ Matrix.Diagonal((0.59, 0.59, 0.59, 1.0))
        )
        neck_flop = pickup * (0.34 * math.sin(frame * 0.82) + swing_x * 0.72)
        wing_flop = pickup * (0.46 + 0.28 * math.sin(frame * 0.94))
        leg_flop = pickup * (-0.74 + 0.32 * math.sin(frame * 0.64))
        for bone_name, rotation in {
            # chest/head bend in opposing directions, making the real chicken
            # rig articulate through the neck instead of moving as a board.
            "chest": (neck_flop * 0.45, 0.0, swing_z * 0.30),
            "head": (-neck_flop, 0.0, -swing_z * 0.68),
            "wing_L": (0.0, 0.0, -wing_flop), "wing_R": (0.0, 0.0, wing_flop),
            "leg_L": (leg_flop, 0.16, 0.0), "leg_R": (leg_flop * 0.92, -0.16, 0.0),
        }.items():
            bone = chicken_armature.pose.bones[bone_name]
            bone.rotation_mode = "XYZ"
            bone.rotation_euler = rotation
        bpy.context.view_layer.update()
        scene.render.filepath = str(FRAMES / f"ragdoll_{image_index:03d}.png")
        bpy.ops.render.render(write_still=True)
    print(f"REAL_RAGDOLL_FRAME_DIR={FRAMES}")


if __name__ == "__main__":
    main()
