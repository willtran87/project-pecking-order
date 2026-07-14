"""Render a short, non-graphic preview of Fox_NeckGrabShake frames."""
from __future__ import annotations

from pathlib import Path
import shutil
import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "assets" / "models" / "predator_fox.glb"
FRAMES = ROOT / "captures" / "predator_fox_shake_frames"


def main() -> None:
    bpy.ops.import_scene.gltf(filepath=str(MODEL))
    # Blender's glTF importer materializes armature display helpers as these
    # meshes; they are not part of the fox and must not enter the preview.
    for helper_name in ["Cube", "Icosphere"]:
        helper = bpy.data.objects.get(helper_name)
        if helper is not None:
            helper.hide_render = True
    if FRAMES.exists():
        shutil.rmtree(FRAMES)
    FRAMES.mkdir(parents=True)
    scene = bpy.context.scene
    scene.render.resolution_x = 720
    scene.render.resolution_y = 720
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
    camera.rotation_euler = (Vector((0, 0, 0.93)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 60
    scene.camera = camera
    fox = bpy.data.objects["FoxArmature"]
    fox.animation_data.action = bpy.data.actions["Fox_NeckGrabShake"]
    # Frame 1 is the lunge; 13/18 are the two opposing whip peaks; 36 settles.
    for image_index, frame in enumerate(range(1, 37, 2), start=1):
        scene.frame_set(frame)
        scene.render.filepath = str(FRAMES / f"shake_{image_index:03d}.png")
        bpy.ops.render.render(write_still=True)
    print(f"SHAKE_FRAME_DIR={FRAMES}")


if __name__ == "__main__":
    main()
