"""Render a proof image of the fox carrying the real employee-chicken GLB.

This is intentionally a visual proof only: it does not alter the gameplay
office or the shipped fox GLB's self-contained placeholder victim.
"""
from __future__ import annotations

from pathlib import Path
import bpy


ROOT = Path(__file__).resolve().parents[1]
FOX_SOURCE = ROOT / "assets" / "blender_source" / "predator_fox.blend"
CHICKEN_MODEL = ROOT / "assets" / "models" / "chicken_employee.glb"
OUTPUT = ROOT / "captures" / "predator_fox_real_chicken_proof.png"


def main() -> None:
    bpy.ops.wm.open_mainfile(filepath=str(FOX_SOURCE))
    # Remove the simplified built-in victim; the imported employee GLB is the
    # same asset instantiated by ChickenView in the live office.
    for obj in list(bpy.data.objects):
        if obj.name.startswith("LimpChicken"):
            bpy.data.objects.remove(obj, do_unlink=True)

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(CHICKEN_MODEL))
    imported = [obj for obj in bpy.data.objects if obj not in before]
    chicken_root = next((obj for obj in imported if obj.name == "ChickenRig"), None)
    if chicken_root is None:
        raise RuntimeError("The employee chicken root was not found after import")

    # The chicken remains upright but hangs naturally below the fox's mouth;
    # its head/neck align with the jaw and its real armature/model stays intact.
    chicken_root.location = (-0.12, -0.91, 0.38)
    chicken_root.scale = (0.59, 0.59, 0.59)
    fox = bpy.data.objects.get("FoxArmature")
    if fox is None:
        raise RuntimeError("Fox armature not found")
    for obj in imported:
        if any(marker in obj.name for marker in ["Accessory", "BowTie", "Headset", "Glasses", "Visor", "Tie", "Lanyard", "Badge"]):
            obj.hide_render = True
    fox.animation_data.action = bpy.data.actions["Fox_CarryWalk"]
    bpy.context.scene.frame_set(1)
    bpy.context.scene.render.resolution_x = 2560
    bpy.context.scene.render.resolution_y = 1600
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.filepath = str(OUTPUT)
    bpy.ops.render.render(write_still=True)
    print(f"REAL_CHICKEN_PROOF={OUTPUT}")


if __name__ == "__main__":
    main()
