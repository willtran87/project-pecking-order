"""Deterministically rebuild the chicken employee Blender and glTF assets.

Run with Blender 5.x in background mode from the project root::

    blender --background --factory-startup --python tools/build_chicken_employee.py

The character keeps the legacy empty/object names consumed by Godot while also
shipping a small deformation armature and authored action library.  The feather
shell is voxel-unioned before decimation, so the torso, breast, short neck,
head, folded wings, rump, and tail are one watertight connected mesh.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = PROJECT_ROOT / "assets" / "blender_source" / "chicken_employee.blend"
MODEL_PATH = PROJECT_ROOT / "assets" / "models" / "chicken_employee.glb"
PREVIEW_PATH = PROJECT_ROOT / "captures" / "chicken_employee_rebuild.png"
PECK_PREVIEW_PATH = PROJECT_ROOT / "captures" / "chicken_employee_peck_attached.png"
ACCESSORY_PREVIEW_DIR = PROJECT_ROOT / "captures" / "chicken_accessory_profiles"


def clean_scene() -> None:
    bpy.ops.object.mode_set(mode="OBJECT") if bpy.context.object and bpy.context.object.mode != "OBJECT" else None
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.metaballs,
        bpy.data.armatures,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
        bpy.data.actions,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def make_material(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float,
    metallic: float = 0.0,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Roughness"].default_value = roughness
    principled.inputs["Metallic"].default_value = metallic
    # Keep the asset inside glTF's inexpensive metallic/roughness workflow.
    # A restrained dielectric highlight separates feathers, keratin, cloth,
    # and glossy eyes without relying on Blender-only shaders or textures.
    if "IOR Level" in principled.inputs:
        principled.inputs["IOR Level"].default_value = 0.30 if metallic == 0.0 else 0.50
    return material


def apply_object_transform(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.select_set(False)


def ellipsoid(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    segments: int = 32,
    rings: int = 20,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    apply_object_transform(obj)
    return obj


def cylinder(
    name: str,
    radius: float,
    depth: float,
    location: tuple[float, float, float],
    vertices: int = 20,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        end_fill_type="NGON",
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    apply_object_transform(obj)
    return obj


def beveled_box(
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    material: bpy.types.Material,
    bevel: float = 0.008,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    apply_object_transform(obj)
    obj.data.materials.append(material)
    if bevel > 0.0:
        modifier = obj.modifiers.new(name="SoftAccessoryEdges", type="BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)
    return obj


def torus(
    name: str,
    location: tuple[float, float, float],
    major_radius: float,
    minor_radius: float,
    material: bpy.types.Material,
    rotation: tuple[float, float, float] = (math.pi / 2.0, 0.0, 0.0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(
        major_segments=16,
        minor_segments=6,
        location=location,
        rotation=rotation,
        major_radius=major_radius,
        minor_radius=minor_radius,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    apply_object_transform(obj)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def cylinder_between(
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    radius: float,
    material: bpy.types.Material,
    vertices: int = 8,
) -> bpy.types.Object:
    start_vector = Vector(start)
    end_vector = Vector(end)
    direction = end_vector - start_vector
    obj = cylinder(name, radius, direction.length, (start_vector + end_vector) * 0.5, vertices)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(direction.normalized())
    apply_object_transform(obj)
    obj.rotation_mode = "XYZ"
    obj.data.materials.append(material)
    return obj


def triangle_count(obj: bpy.types.Object) -> int:
    return sum(max(0, len(poly.vertices) - 2) for poly in obj.data.polygons)


def join_and_remesh(
    parts: list[bpy.types.Object],
    name: str,
    voxel_size: float,
    target_triangles: int,
) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    # Joining retains the active primitive's object-space origin.  Bake that
    # origin now so region masks, armature bones, and compatibility pivots all
    # operate in the same character-local coordinates.
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    obj.data.remesh_voxel_size = voxel_size
    obj.data.remesh_voxel_adaptivity = 0.0
    bpy.ops.object.voxel_remesh()

    current_triangles = triangle_count(obj)
    if current_triangles > target_triangles:
        modifier = obj.modifiers.new(name="SilhouetteDecimate", type="DECIMATE")
        modifier.decimate_type = "COLLAPSE"
        modifier.ratio = max(0.05, min(1.0, target_triangles / current_triangles))
        modifier.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)

    triangulate = obj.modifiers.new(name="FinalTriangulation", type="TRIANGULATE")
    triangulate.quad_method = "BEAUTY"
    triangulate.ngon_method = "BEAUTY"
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=triangulate.name)

    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.select_set(False)
    return obj


def create_wedge_beak(material: bpy.types.Material) -> bpy.types.Object:
    # The broad base is intentionally sunk into the head.  The shallow lower
    # point keeps the beak birdlike without turning it into a large muzzle.
    vertices = [
        (-0.105, -0.370, 1.405),
        (0.105, -0.370, 1.405),
        (-0.090, -0.375, 1.300),
        (0.090, -0.375, 1.300),
        (0.000, -0.575, 1.350),
    ]
    faces = [
        (0, 1, 3, 2),
        (0, 4, 1),
        (2, 3, 4),
        (0, 2, 4),
        (1, 4, 3),
    ]
    mesh = bpy.data.meshes.new("BeakMesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    obj = bpy.data.objects.new("Beak", mesh)
    bpy.context.collection.objects.link(obj)
    bevel = obj.modifiers.new(name="SoftBeakEdges", type="BEVEL")
    bevel.width = 0.012
    bevel.segments = 2
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    obj.select_set(False)
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    return obj


def create_body(materials: list[bpy.types.Material]) -> bpy.types.Object:
    parts = [
        # Primary pear-shaped torso, generous breast, and round rear.  All
        # following feather forms overlap these masses before voxel union, so
        # the final character remains one genuinely connected soft shell.
        ellipsoid("TorsoMass", (0.0, 0.020, 0.835), (0.380, 0.430, 0.535)),
        ellipsoid("BreastMass", (0.0, -0.220, 0.815), (0.360, 0.325, 0.455)),
        ellipsoid("RumpMass", (0.0, 0.225, 0.845), (0.355, 0.325, 0.410)),
        # Low feather trousers visually carry the body into each supporting
        # leg instead of ending in an unsupported spherical belly.
        ellipsoid("HaunchL", (-0.180, 0.020, 0.455), (0.198, 0.225, 0.205)),
        ellipsoid("HaunchR", (0.180, 0.020, 0.455), (0.198, 0.225, 0.205)),
        ellipsoid("BellySkirt", (0.0, -0.055, 0.465), (0.325, 0.300, 0.185)),
        # A deep short neck, asymmetric cheek puffs, and a scalloped ruff make
        # the face cozy while avoiding the disconnected 'snowman' profile.
        ellipsoid("NeckMass", (0.0, -0.045, 1.205), (0.285, 0.300, 0.315)),
        ellipsoid("HeadMass", (0.0, -0.125, 1.425), (0.295, 0.305, 0.275)),
        ellipsoid("CheekL", (-0.165, -0.285, 1.335), (0.145, 0.145, 0.150)),
        ellipsoid("CheekR", (0.165, -0.285, 1.335), (0.145, 0.145, 0.150)),
        ellipsoid("RuffL", (-0.155, -0.190, 1.165), (0.155, 0.155, 0.170), (0.06, 0.0, 0.14)),
        ellipsoid("RuffC", (0.0, -0.225, 1.130), (0.175, 0.165, 0.185)),
        ellipsoid("RuffR", (0.155, -0.190, 1.165), (0.155, 0.155, 0.170), (0.06, 0.0, -0.14)),
        # Each folded wing has a broad root and three overlapping feather tips.
        # The union preserves a readable scalloped edge without floating plates.
        ellipsoid("WingRootL", (-0.302, 0.005, 0.900), (0.088, 0.285, 0.325), (0.0, 0.0, -0.04)),
        ellipsoid("WingFeatherL1", (-0.326, -0.010, 0.755), (0.064, 0.205, 0.170), (0.10, 0.0, -0.08)),
        ellipsoid("WingFeatherL2", (-0.322, 0.080, 0.700), (0.064, 0.190, 0.150), (0.18, 0.0, -0.05)),
        ellipsoid("WingFeatherL3", (-0.306, 0.155, 0.680), (0.062, 0.165, 0.135), (0.24, 0.0, -0.03)),
        ellipsoid("WingRootR", (0.302, 0.005, 0.900), (0.088, 0.285, 0.325), (0.0, 0.0, 0.04)),
        ellipsoid("WingFeatherR1", (0.326, -0.010, 0.755), (0.064, 0.205, 0.170), (0.10, 0.0, 0.08)),
        ellipsoid("WingFeatherR2", (0.322, 0.080, 0.700), (0.064, 0.190, 0.150), (0.18, 0.0, 0.05)),
        ellipsoid("WingFeatherR3", (0.306, 0.155, 0.680), (0.062, 0.165, 0.135), (0.24, 0.0, 0.03)),
        # A five-feather upright fan reads as chicken at office scale and can be
        # exaggerated further when this same asset is used for a rooster.
        ellipsoid("TailCenter", (0.0, 0.430, 1.005), (0.105, 0.270, 0.150), (0.52, 0.0, 0.0)),
        ellipsoid("TailInnerL", (-0.095, 0.420, 0.970), (0.092, 0.250, 0.140), (0.46, 0.08, -0.04)),
        ellipsoid("TailInnerR", (0.095, 0.420, 0.970), (0.092, 0.250, 0.140), (0.46, -0.08, 0.04)),
        ellipsoid("TailOuterL", (-0.180, 0.385, 0.920), (0.080, 0.215, 0.125), (0.38, 0.16, -0.05)),
        ellipsoid("TailOuterR", (0.180, 0.385, 0.920), (0.080, 0.215, 0.125), (0.38, -0.16, 0.05)),
    ]
    body = join_and_remesh(parts, "Feather_Torso", voxel_size=0.016, target_triangles=7600)
    for material in materials:
        body.data.materials.append(material)

    # Zone the one connected surface by silhouette region.  This creates a
    # cream breast and subtly darker folded wings/tail without extra meshes.
    for polygon in body.data.polygons:
        center = polygon.center
        if center.y > 0.310 and center.z > 0.700:
            polygon.material_index = 2  # tail
        elif abs(center.x) > 0.285 and 0.535 < center.z < 1.215:
            polygon.material_index = 2  # wings
        elif center.y < -0.270 and center.z > 1.185:
            polygon.material_index = 3  # face and cheek puffs
        elif center.y < -0.255 and 0.470 < center.z < 1.180:
            polygon.material_index = 1  # breast
        else:
            polygon.material_index = 0
    return body


def create_leg(name: str, material: bpy.types.Material, mirrored: bool) -> bpy.types.Object:
    toe_splay = -1.0 if mirrored else 1.0
    parts = [
        cylinder(f"{name}_Shin", radius=0.060, depth=0.345, location=(0.0, 0.0, 0.050), vertices=16),
        ellipsoid(f"{name}_Knee", (0.0, 0.0, 0.205), (0.085, 0.085, 0.105), segments=20, rings=12),
        ellipsoid(f"{name}_Ankle", (0.0, -0.005, -0.125), (0.070, 0.075, 0.088), segments=20, rings=12),
        ellipsoid(f"{name}_Pad", (0.0, -0.050, -0.225), (0.105, 0.155, 0.062), segments=24, rings=14),
        ellipsoid(f"{name}_ToeC", (0.0, -0.180, -0.246), (0.036, 0.140, 0.032), segments=16, rings=10),
        ellipsoid(
            f"{name}_ToeOuter",
            (0.050 * toe_splay, -0.158, -0.244),
            (0.034, 0.125, 0.030),
            (0.0, 0.0, 0.26 * toe_splay),
            segments=16,
            rings=10,
        ),
        ellipsoid(
            f"{name}_ToeInner",
            (-0.050 * toe_splay, -0.155, -0.244),
            (0.034, 0.118, 0.030),
            (0.0, 0.0, -0.25 * toe_splay),
            segments=16,
            rings=10,
        ),
        ellipsoid(f"{name}_BackToe", (0.0, 0.050, -0.232), (0.030, 0.075, 0.027), segments=16, rings=10),
    ]
    leg = join_and_remesh(parts, name, voxel_size=0.012, target_triangles=520)
    leg.data.materials.append(material)
    return leg


def create_comb(material: bpy.types.Material) -> bpy.types.Object:
    parts = [
        ellipsoid("CombFront", (0.0, -0.150, 1.655), (0.054, 0.075, 0.095), segments=20, rings=12),
        ellipsoid("CombCrown", (0.0, -0.080, 1.705), (0.060, 0.080, 0.135), segments=20, rings=12),
        ellipsoid("CombMiddle", (0.0, 0.000, 1.690), (0.060, 0.082, 0.125), segments=20, rings=12),
        ellipsoid("CombBack", (0.0, 0.080, 1.645), (0.054, 0.080, 0.095), segments=20, rings=12),
    ]
    comb = join_and_remesh(parts, "Comb", voxel_size=0.008, target_triangles=380)
    comb.data.materials.append(material)
    return comb


def create_bow_tie(material: bpy.types.Material) -> bpy.types.Object:
    def lobe(name: str, points: list[tuple[float, float]]) -> bpy.types.Object:
        front_y = -0.538
        back_y = -0.505
        vertices = [(x, front_y, z) for x, z in points] + [(x, back_y, z) for x, z in points]
        faces = [
            (0, 1, 2, 3), (4, 7, 6, 5),
            (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0),
        ]
        mesh = bpy.data.meshes.new(name + "Mesh")
        mesh.from_pydata(vertices, [], faces)
        mesh.materials.append(material)
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        return obj

    parts = [
        lobe("BowTie_LobeL", [(-0.025, 1.020), (-0.145, 1.060), (-0.135, 0.925), (-0.025, 0.960)]),
        lobe("BowTie_LobeR", [(0.025, 1.020), (0.145, 1.060), (0.135, 0.925), (0.025, 0.960)]),
        beveled_box("BowTie_Knot", (0.0, -0.536, 0.990), (0.065, 0.040, 0.070), material, 0.010),
    ]
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[-1]
    bpy.ops.object.join()
    tie = bpy.context.object
    tie.name = "BowTie"
    bevel = tie.modifiers.new(name="SoftBowTieEdges", type="BEVEL")
    bevel.width = 0.007
    bevel.segments = 2
    bpy.context.view_layer.objects.active = tie
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    triangulate = tie.modifiers.new(name="BowTieTriangulation", type="TRIANGULATE")
    bpy.ops.object.modifier_apply(modifier=triangulate.name)
    for polygon in tie.data.polygons:
        polygon.use_smooth = True
    tie.select_set(False)
    return tie


def create_empty(
    name: str,
    parent: bpy.types.Object | None = None,
    location: tuple[float, float, float] = (0.0, 0.0, 0.0),
    display: str = "PLAIN_AXES",
    size: float = 0.08,
) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.empty_display_type = display
    obj.empty_display_size = size
    obj.location = location
    obj.parent = parent
    return obj


def create_accessory_group(name: str, parts: list[bpy.types.Object]) -> list[bpy.types.Object]:
    """Create one visibility root while preserving each modeled part in world space."""
    group = create_empty(name, size=0.045)
    for part in parts:
        world_transform = part.matrix_world.copy()
        part.parent = group
        part.matrix_world = world_transform
    return [group, *parts]


def create_round_glasses(material: bpy.types.Material) -> list[bpy.types.Object]:
    parts = [
        torus("RoundGlasses_LensL", (-0.112, -0.424, 1.475), 0.067, 0.010, material),
        torus("RoundGlasses_LensR", (0.112, -0.424, 1.475), 0.067, 0.010, material),
        cylinder_between("RoundGlasses_Bridge", (-0.047, -0.424, 1.475), (0.047, -0.424, 1.475), 0.009, material),
        cylinder_between("RoundGlasses_TempleL", (-0.178, -0.414, 1.478), (-0.260, -0.275, 1.465), 0.008, material),
        cylinder_between("RoundGlasses_TempleR", (0.178, -0.414, 1.478), (0.260, -0.275, 1.465), 0.008, material),
    ]
    return create_accessory_group("AccessoryHead_RoundGlasses", parts)


def create_square_glasses(material: bpy.types.Material) -> list[bpy.types.Object]:
    parts: list[bpy.types.Object] = []
    for side, center_x in (("L", -0.112), ("R", 0.112)):
        parts.extend([
            beveled_box(f"SquareGlasses_{side}_Top", (center_x, -0.424, 1.528), (0.145, 0.020, 0.016), material, 0.004),
            beveled_box(f"SquareGlasses_{side}_Bottom", (center_x, -0.424, 1.422), (0.145, 0.020, 0.016), material, 0.004),
            beveled_box(f"SquareGlasses_{side}_Outer", (center_x + (-0.064 if side == "L" else 0.064), -0.424, 1.475), (0.016, 0.020, 0.116), material, 0.004),
            beveled_box(f"SquareGlasses_{side}_Inner", (center_x + (0.064 if side == "L" else -0.064), -0.424, 1.475), (0.016, 0.020, 0.116), material, 0.004),
        ])
    parts.extend([
        beveled_box("SquareGlasses_Bridge", (0.0, -0.424, 1.478), (0.062, 0.020, 0.014), material, 0.004),
        cylinder_between("SquareGlasses_TempleL", (-0.182, -0.412, 1.485), (-0.260, -0.275, 1.465), 0.008, material),
        cylinder_between("SquareGlasses_TempleR", (0.182, -0.412, 1.485), (0.260, -0.275, 1.465), 0.008, material),
    ])
    return create_accessory_group("AccessoryHead_SquareGlasses", parts)


def create_accountant_visor(
    green_material: bpy.types.Material,
    band_material: bpy.types.Material,
) -> list[bpy.types.Object]:
    brim = ellipsoid("AccountantVisor_Brim", (0.0, -0.365, 1.610), (0.275, 0.185, 0.026), segments=20, rings=10)
    brim.data.materials.append(green_material)
    band = beveled_box("AccountantVisor_Band", (0.0, -0.300, 1.615), (0.475, 0.040, 0.060), band_material, 0.012)
    return create_accessory_group("AccessoryHead_AccountantVisor", [brim, band])


def create_headset(
    frame_material: bpy.types.Material,
    accent_material: bpy.types.Material,
) -> list[bpy.types.Object]:
    parts = [
        cylinder_between("Headset_BandL", (-0.286, -0.045, 1.435), (-0.205, -0.035, 1.650), 0.014, frame_material, 10),
        cylinder_between("Headset_BandTop", (-0.205, -0.035, 1.650), (0.205, -0.035, 1.650), 0.014, frame_material, 10),
        cylinder_between("Headset_BandR", (0.205, -0.035, 1.650), (0.286, -0.045, 1.435), 0.014, frame_material, 10),
    ]
    for side, x in (("L", -0.286), ("R", 0.286)):
        cup = ellipsoid(f"Headset_Cup{side}", (x, -0.075, 1.435), (0.035, 0.060, 0.082), segments=16, rings=10)
        cup.data.materials.append(frame_material)
        pad = ellipsoid(f"Headset_Pad{side}", (x + (0.010 if side == "L" else -0.010), -0.108, 1.435), (0.024, 0.032, 0.065), segments=12, rings=8)
        pad.data.materials.append(accent_material)
        parts.extend([cup, pad])
    parts.extend([
        cylinder_between("Headset_MicArm", (-0.286, -0.105, 1.420), (-0.180, -0.360, 1.370), 0.010, frame_material, 8),
        ellipsoid("Headset_Mic", (-0.175, -0.375, 1.365), (0.025, 0.035, 0.025), segments=12, rings=8),
    ])
    parts[-1].data.materials.append(accent_material)
    return create_accessory_group("AccessoryHead_Headset", parts)


def create_long_tie(material: bpy.types.Material) -> list[bpy.types.Object]:
    knot_vertices = [
        (-0.040, -0.525, 1.060), (0.040, -0.525, 1.060),
        (0.052, -0.525, 0.980), (-0.052, -0.525, 0.980),
        (-0.040, -0.495, 1.060), (0.040, -0.495, 1.060),
        (0.052, -0.495, 0.980), (-0.052, -0.495, 0.980),
    ]
    knot_faces = [
        (0, 1, 2, 3), (4, 7, 6, 5),
        (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0),
    ]
    knot_mesh = bpy.data.meshes.new("LongTieKnotMesh")
    knot_mesh.from_pydata(knot_vertices, [], knot_faces)
    knot_mesh.materials.append(material)
    knot = bpy.data.objects.new("LongTie_Knot", knot_mesh)
    bpy.context.collection.objects.link(knot)
    knot_bevel = knot.modifiers.new(name="SoftTieKnotEdges", type="BEVEL")
    knot_bevel.width = 0.008
    knot_bevel.segments = 2
    bpy.context.view_layer.objects.active = knot
    knot.select_set(True)
    bpy.ops.object.modifier_apply(modifier=knot_bevel.name)
    knot.select_set(False)
    vertices = [
        (-0.046, -0.525, 0.978), (0.046, -0.525, 0.978),
        (-0.062, -0.530, 0.735), (0.0, -0.528, 0.675), (0.062, -0.530, 0.735),
        (-0.046, -0.495, 0.978), (0.046, -0.495, 0.978),
        (-0.062, -0.500, 0.735), (0.0, -0.498, 0.675), (0.062, -0.500, 0.735),
    ]
    faces = [
        (0, 1, 4, 3, 2), (5, 7, 8, 9, 6),
        (0, 5, 6, 1), (1, 6, 9, 4), (4, 9, 8, 3),
        (3, 8, 7, 2), (2, 7, 5, 0),
    ]
    mesh = bpy.data.meshes.new("LongTieBladeMesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    blade = bpy.data.objects.new("LongTie_Blade", mesh)
    bpy.context.collection.objects.link(blade)
    bevel = blade.modifiers.new(name="SoftTieEdges", type="BEVEL")
    bevel.width = 0.009
    bevel.segments = 2
    bpy.context.view_layer.objects.active = blade
    blade.select_set(True)
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    blade.select_set(False)
    return create_accessory_group("AccessoryNeck_LongTie", [knot, blade])


def create_lanyard(
    cord_material: bpy.types.Material,
    badge_material: bpy.types.Material,
    accent_material: bpy.types.Material,
) -> list[bpy.types.Object]:
    parts = [
        cylinder_between("Lanyard_CordL", (-0.205, -0.420, 1.090), (-0.050, -0.515, 0.865), 0.008, cord_material, 8),
        cylinder_between("Lanyard_CordR", (0.205, -0.420, 1.090), (0.050, -0.515, 0.865), 0.008, cord_material, 8),
        beveled_box("Lanyard_Badge", (0.0, -0.530, 0.790), (0.175, 0.026, 0.145), badge_material, 0.012),
        beveled_box("Lanyard_BadgeStripe", (0.0, -0.548, 0.814), (0.120, 0.008, 0.022), accent_material, 0.004),
    ]
    return create_accessory_group("AccessoryNeck_Lanyard", parts)


def create_nameplate(
    plate_material: bpy.types.Material,
    accent_material: bpy.types.Material,
) -> list[bpy.types.Object]:
    parts = [
        beveled_box("Nameplate_Plate", (0.205, -0.515, 0.965), (0.155, 0.026, 0.070), plate_material, 0.010),
        beveled_box("Nameplate_Stripe", (0.205, -0.533, 0.965), (0.095, 0.008, 0.015), accent_material, 0.003),
    ]
    return create_accessory_group("AccessoryBadge_Nameplate", parts)


def create_golden_egg_pin(material: bpy.types.Material) -> list[bpy.types.Object]:
    egg = ellipsoid("GoldenEggPin_Egg", (0.205, -0.525, 0.970), (0.040, 0.020, 0.052), segments=14, rings=8)
    egg.data.materials.append(material)
    bar = beveled_box("GoldenEggPin_Bar", (0.205, -0.510, 1.025), (0.085, 0.020, 0.018), material, 0.004)
    return create_accessory_group("AccessoryBadge_GoldenEgg", [egg, bar])


def create_armature(parent: bpy.types.Object) -> bpy.types.Object:
    armature_data = bpy.data.armatures.new("ChickenArmatureData")
    armature = bpy.data.objects.new("ChickenArmature", armature_data)
    bpy.context.collection.objects.link(armature)
    armature.parent = parent
    armature.show_in_front = True

    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name: str, head: tuple[float, float, float], tail: tuple[float, float, float], parent_name: str | None = None):
        edit_bone = armature_data.edit_bones.new(name)
        edit_bone.head = head
        edit_bone.tail = tail
        if parent_name:
            edit_bone.parent = armature_data.edit_bones[parent_name]
        return edit_bone

    bone("root", (0.0, 0.0, 0.020), (0.0, 0.0, 0.440))
    bone("chest", (0.0, 0.0, 0.440), (0.0, -0.030, 1.170), "root")
    bone("head", (0.0, -0.030, 1.170), (0.0, -0.105, 1.515), "chest")
    bone("wing_L", (-0.090, 0.0, 1.050), (-0.330, 0.0, 0.820), "chest")
    bone("wing_R", (0.090, 0.0, 1.050), (0.330, 0.0, 0.820), "chest")
    bone("leg_L", (-0.170, 0.0, 0.500), (-0.170, 0.0, 0.075), "root")
    bone("leg_R", (0.170, 0.0, 0.500), (0.170, 0.0, 0.075), "root")

    bpy.ops.object.mode_set(mode="POSE")
    for pose_bone in armature.pose.bones:
        pose_bone.rotation_mode = "XYZ"
    bpy.ops.object.mode_set(mode="OBJECT")
    armature.select_set(False)
    return armature


def smoothstep(low: float, high: float, value: float) -> float:
    if high <= low:
        return 0.0
    t = max(0.0, min(1.0, (value - low) / (high - low)))
    return t * t * (3.0 - 2.0 * t)


def skin_body(body: bpy.types.Object, armature: bpy.types.Object) -> None:
    groups = {name: body.vertex_groups.new(name=name) for name in ("root", "chest", "head", "wing_L", "wing_R")}
    for vertex in body.data.vertices:
        co = vertex.co
        head_weight = smoothstep(1.120, 1.390, co.z)
        lower_weight = 1.0 - smoothstep(0.360, 0.650, co.z)
        wing_mask = smoothstep(0.245, 0.385, abs(co.x))
        wing_mask *= 1.0 - smoothstep(1.080, 1.300, co.z)
        wing_mask *= smoothstep(0.430, 0.680, co.z)
        wing_weight = min(0.72, wing_mask * (1.0 - head_weight))
        root_weight = min(0.75, lower_weight * (1.0 - head_weight) * (1.0 - wing_weight))
        chest_weight = max(0.0, 1.0 - head_weight - wing_weight - root_weight)

        if root_weight > 0.0001:
            groups["root"].add([vertex.index], root_weight, "REPLACE")
        if chest_weight > 0.0001:
            groups["chest"].add([vertex.index], chest_weight, "REPLACE")
        if head_weight > 0.0001:
            groups["head"].add([vertex.index], head_weight, "REPLACE")
        if wing_weight > 0.0001:
            wing_name = "wing_L" if co.x < 0.0 else "wing_R"
            groups[wing_name].add([vertex.index], wing_weight, "REPLACE")

    modifier = body.modifiers.new(name="ChickenArmatureDeform", type="ARMATURE")
    modifier.object = armature
    modifier.use_deform_preserve_volume = True


def clear_pose(armature: bpy.types.Object) -> None:
    for pose_bone in armature.pose.bones:
        pose_bone.location = (0.0, 0.0, 0.0)
        pose_bone.rotation_euler = (0.0, 0.0, 0.0)
        pose_bone.scale = (1.0, 1.0, 1.0)


def key_pose(armature: bpy.types.Object, frame: int) -> None:
    for pose_bone in armature.pose.bones:
        pose_bone.keyframe_insert(data_path="location", frame=frame)
        pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame)
        pose_bone.keyframe_insert(data_path="scale", frame=frame)


def create_action(
    armature: bpy.types.Object,
    name: str,
    frame_poses: list[tuple[int, dict[str, dict[str, tuple[float, float, float]]]]],
) -> bpy.types.Action:
    action = bpy.data.actions.new(name=name)
    action.use_fake_user = True
    armature.animation_data_create()
    armature.animation_data.action = action
    for frame, transforms in frame_poses:
        clear_pose(armature)
        for bone_name, values in transforms.items():
            pose_bone = armature.pose.bones[bone_name]
            if "location" in values:
                pose_bone.location = values["location"]
            if "rotation" in values:
                pose_bone.rotation_euler = values["rotation"]
            if "scale" in values:
                pose_bone.scale = values["scale"]
        key_pose(armature, frame)
    return action


def create_actions(armature: bpy.types.Object) -> dict[str, bpy.types.Action]:
    idle = create_action(
        armature,
        "Chicken_Idle",
        [
            (1, {}),
            (16, {
                "chest": {"scale": (1.012, 1.012, 1.022)},
                "head": {"rotation": (0.020, -0.10, -0.025)},
            }),
            (30, {
                "chest": {"scale": (1.020, 1.020, 1.030)},
                "head": {"rotation": (0.035, 0.0, 0.045)},
                "wing_L": {"rotation": (0.0, 0.0, -0.035)},
            }),
            (46, {
                "chest": {"scale": (1.010, 1.010, 1.018)},
                "head": {"rotation": (0.015, 0.12, -0.020)},
            }),
            (60, {
                "head": {"rotation": (-0.015, 0.0, 0.0)},
                "wing_R": {"rotation": (0.0, 0.0, 0.025)},
            }),
            (72, {}),
        ],
    )
    walk = create_action(
        armature,
        "Chicken_Walk",
        [
            (1, {"leg_L": {"rotation": (0.48, 0.0, 0.0)}, "leg_R": {"rotation": (-0.48, 0.0, 0.0)}, "chest": {"rotation": (0.0, 0.0, -0.045)}, "wing_L": {"rotation": (0.0, 0.0, -0.035)}}),
            (7, {"root": {"location": (0.0, 0.0, 0.038)}, "head": {"rotation": (0.060, -0.035, 0.0)}}),
            (13, {"leg_L": {"rotation": (-0.48, 0.0, 0.0)}, "leg_R": {"rotation": (0.48, 0.0, 0.0)}, "chest": {"rotation": (0.0, 0.0, 0.045)}, "wing_R": {"rotation": (0.0, 0.0, 0.035)}}),
            (19, {"root": {"location": (0.0, 0.0, 0.038)}, "head": {"rotation": (0.060, 0.035, 0.0)}}),
            (25, {"leg_L": {"rotation": (0.48, 0.0, 0.0)}, "leg_R": {"rotation": (-0.48, 0.0, 0.0)}, "chest": {"rotation": (0.0, 0.0, -0.045)}, "wing_L": {"rotation": (0.0, 0.0, -0.035)}}),
        ],
    )
    peck = create_action(
        armature,
        "Chicken_Peck",
        [
            (1, {}),
            (8, {"chest": {"rotation": (0.08, 0.0, 0.0)}, "head": {"rotation": (0.25, 0.0, 0.0)}}),
            (12, {"chest": {"rotation": (0.12, 0.0, 0.0)}, "head": {"rotation": (0.40, 0.0, 0.0)}}),
            (18, {"chest": {"rotation": (0.06, 0.0, 0.0)}, "head": {"rotation": (0.18, 0.0, 0.0)}}),
            (28, {}),
        ],
    )
    sit = create_action(
        armature,
        "Chicken_Sit",
        [
            (1, {}),
            (18, {"root": {"location": (0.0, 0.0, -0.110)}, "leg_L": {"rotation": (-1.05, 0.0, 0.0)}, "leg_R": {"rotation": (-1.05, 0.0, 0.0)}, "chest": {"rotation": (0.08, 0.0, 0.0)}}),
            (36, {"root": {"location": (0.0, 0.0, -0.110)}, "leg_L": {"rotation": (-1.05, 0.0, 0.0)}, "leg_R": {"rotation": (-1.05, 0.0, 0.0)}, "chest": {"rotation": (0.08, 0.0, 0.0)}}),
        ],
    )
    lay = create_action(
        armature,
        "Chicken_Lay",
        [
            (1, {
                "root": {"location": (0.0, 0.0, -0.110)},
                "leg_L": {"rotation": (-1.05, 0.0, 0.0)},
                "leg_R": {"rotation": (-1.05, 0.0, 0.0)},
                "chest": {"rotation": (0.08, 0.0, 0.0)},
            }),
            (8, {
                "root": {"location": (0.0, 0.025, -0.145), "scale": (1.025, 1.025, 0.955)},
                "chest": {"rotation": (0.12, 0.0, -0.035), "scale": (1.035, 1.035, 0.960)},
                "head": {"rotation": (-0.10, -0.10, 0.0)},
                "wing_L": {"rotation": (0.0, 0.0, -0.12)},
                "wing_R": {"rotation": (0.0, 0.0, 0.12)},
                "leg_L": {"rotation": (-1.15, 0.0, 0.0)},
                "leg_R": {"rotation": (-1.15, 0.0, 0.0)},
            }),
            (15, {
                "root": {"location": (0.0, 0.050, -0.175), "scale": (1.045, 1.045, 0.920)},
                "chest": {"rotation": (0.16, 0.0, 0.040), "scale": (1.050, 1.050, 0.930)},
                "head": {"rotation": (-0.18, 0.12, -0.035)},
                "wing_L": {"rotation": (0.0, 0.0, -0.20)},
                "wing_R": {"rotation": (0.0, 0.0, 0.20)},
                "leg_L": {"rotation": (-1.20, 0.0, 0.0)},
                "leg_R": {"rotation": (-1.20, 0.0, 0.0)},
            }),
            (22, {
                "root": {"location": (0.0, 0.020, -0.125), "scale": (0.985, 0.985, 1.035)},
                "chest": {"rotation": (0.05, 0.0, 0.0), "scale": (0.990, 0.990, 1.035)},
                "head": {"rotation": (0.10, 0.0, 0.0)},
                "wing_L": {"rotation": (0.0, 0.0, -0.08)},
                "wing_R": {"rotation": (0.0, 0.0, 0.08)},
                "leg_L": {"rotation": (-1.05, 0.0, 0.0)},
                "leg_R": {"rotation": (-1.05, 0.0, 0.0)},
            }),
            (36, {
                "root": {"location": (0.0, 0.0, -0.110)},
                "leg_L": {"rotation": (-1.05, 0.0, 0.0)},
                "leg_R": {"rotation": (-1.05, 0.0, 0.0)},
                "chest": {"rotation": (0.08, 0.0, 0.0)},
            }),
        ],
    )
    armature.animation_data.action = idle
    bpy.context.scene.frame_set(1)
    clear_pose(armature)
    return {"idle": idle, "walk": walk, "peck": peck, "sit": sit, "lay": lay}


def connected_component_count(obj: bpy.types.Object) -> int:
    adjacency = [set() for _ in obj.data.vertices]
    for edge in obj.data.edges:
        a, b = edge.vertices
        adjacency[a].add(b)
        adjacency[b].add(a)
    remaining = set(range(len(obj.data.vertices)))
    components = 0
    while remaining:
        components += 1
        seed = remaining.pop()
        stack = [seed]
        while stack:
            current = stack.pop()
            for neighbor in adjacency[current]:
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    stack.append(neighbor)
    return components


def validate_mesh(obj: bpy.types.Object, require_watertight: bool = True) -> tuple[int, int, int]:
    components = connected_component_count(obj)
    nonmanifold_edges = 0
    edge_face_count = [0] * len(obj.data.edges)
    edge_lookup = {tuple(sorted(edge.vertices)): edge.index for edge in obj.data.edges}
    for polygon in obj.data.polygons:
        vertices = list(polygon.vertices)
        for index, start in enumerate(vertices):
            end = vertices[(index + 1) % len(vertices)]
            edge_face_count[edge_lookup[tuple(sorted((start, end)))]] += 1
    nonmanifold_edges = sum(count != 2 for count in edge_face_count)
    triangles = triangle_count(obj)
    if components != 1:
        raise RuntimeError(f"{obj.name} has {components} disconnected components")
    if require_watertight and nonmanifold_edges:
        raise RuntimeError(f"{obj.name} has {nonmanifold_edges} non-manifold/boundary edges")
    return components, nonmanifold_edges, triangles


def parent_keep_local(child: bpy.types.Object, parent: bpy.types.Object) -> None:
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()


def parent_to_bone_keep_world(
    child: bpy.types.Object,
    armature: bpy.types.Object,
    bone_name: str,
) -> None:
    """Attach a rigid accessory to a deform bone without changing its pose."""
    world_transform = child.matrix_world.copy()
    child.parent = armature
    child.parent_type = "BONE"
    child.parent_bone = bone_name
    child.matrix_world = world_transform


def setup_preview(character_objects: list[bpy.types.Object], materials: dict[str, bpy.types.Material]) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 900
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(PREVIEW_PATH)
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"

    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.035, 0.045, 0.060, 1.0)
    background.inputs["Strength"].default_value = 0.42

    bpy.ops.mesh.primitive_plane_add(size=14.0, location=(0.0, 0.0, -0.005))
    ground = bpy.context.object
    ground.name = "PreviewGround"
    ground.data.materials.append(materials["ground"])

    camera_data = bpy.data.cameras.new("PreviewCameraData")
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = (2.75, -5.10, 2.30)
    camera.rotation_euler = (Vector((0.0, 0.0, 0.86)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.lens = 62
    scene.camera = camera

    def area_light(name: str, energy: float, size: float, location: tuple[float, float, float], color: tuple[float, float, float]):
        data = bpy.data.lights.new(name + "Data", type="AREA")
        data.energy = energy
        data.shape = "DISK"
        data.size = size
        data.color = color
        light = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(light)
        light.location = location
        light.rotation_euler = (Vector((0.0, 0.0, 0.90)) - light.location).to_track_quat("-Z", "Y").to_euler()
        return light

    area_light("PreviewKey", 900.0, 4.0, (-3.0, -4.0, 5.0), (1.0, 0.78, 0.58))
    area_light("PreviewFill", 620.0, 3.0, (3.4, -1.5, 3.0), (0.55, 0.72, 1.0))
    area_light("PreviewRim", 800.0, 3.0, (1.2, 3.0, 4.2), (1.0, 0.46, 0.24))

    # Mark preview-only objects while keeping character selection independent.
    for obj in character_objects:
        obj.select_set(False)


def main() -> None:
    clean_scene()

    materials = {
        "feather": make_material("Feathers_Oat", (0.50, 0.245, 0.085, 1.0), 0.78),
        "breast": make_material("Feathers_Cream", (0.82, 0.600, 0.305, 1.0), 0.82),
        "wing": make_material("Feathers_Wing", (0.29, 0.105, 0.035, 1.0), 0.84),
        "face": make_material("Feathers_Face", (0.70, 0.415, 0.175, 1.0), 0.80),
        "eye": make_material("Eyes_Glossy", (0.012, 0.010, 0.009, 1.0), 0.17),
        "beak": make_material("Beak_and_Feet", (0.95, 0.440, 0.055, 1.0), 0.52),
        "comb": make_material("Comb_Barn_Red", (0.62, 0.055, 0.035, 1.0), 0.60),
        "tie": make_material("Corporate_Navy", (0.035, 0.180, 0.300, 1.0), 0.48),
        "tie_oxblood": make_material("Accessory_Cloth_Oxblood", (0.430, 0.075, 0.110, 1.0), 0.50),
        "frame": make_material("Accessory_Frame_Graphite", (0.025, 0.040, 0.052, 1.0), 0.34, 0.10),
        "visor": make_material("Accessory_Visor_Green", (0.115, 0.310, 0.235, 1.0), 0.42),
        "headset_pad": make_material("Accessory_Headset_Pad", (0.055, 0.115, 0.145, 1.0), 0.62),
        "lanyard": make_material("Accessory_Lanyard_Mustard", (0.760, 0.420, 0.075, 1.0), 0.54),
        "badge": make_material("Accessory_Badge_Cream", (0.845, 0.825, 0.700, 1.0), 0.64),
        "badge_accent": make_material("Accessory_Badge_Ink", (0.035, 0.180, 0.300, 1.0), 0.48),
        "brass": make_material("Accessory_Brass", (0.610, 0.365, 0.080, 1.0), 0.30, 0.55),
        "ground": make_material("Preview_Ground", (0.095, 0.110, 0.125, 1.0), 0.93),
    }

    root = create_empty("ChickenRig", size=0.12)
    body_pivot = create_empty("BodyPivot", root, size=0.11)
    head_pivot = create_empty("HeadPivot", body_pivot, (0.0, -0.105, 1.435), size=0.07)
    wing_left_pivot = create_empty("WingLeftPivot", body_pivot, (-0.295, 0.0, 0.875), size=0.07)
    wing_right_pivot = create_empty("WingRightPivot", body_pivot, (0.295, 0.0, 0.875), size=0.07)
    leg_left_pivot = create_empty("LegLeftPivot", body_pivot, (-0.170, 0.0, 0.320), size=0.065)
    leg_right_pivot = create_empty("LegRightPivot", body_pivot, (0.170, 0.0, 0.320), size=0.065)
    create_empty("FootLeftPivot", leg_left_pivot, (0.0, 0.0, -0.240), size=0.045)
    create_empty("FootRightPivot", leg_right_pivot, (0.0, 0.0, -0.240), size=0.045)

    body = create_body([materials["feather"], materials["breast"], materials["wing"], materials["face"]])
    left_leg = create_leg("LegLeftMesh", materials["beak"], mirrored=False)
    right_leg = create_leg("LegRightMesh", materials["beak"], mirrored=True)
    left_leg.parent = leg_left_pivot
    right_leg.parent = leg_right_pivot
    left_leg.location = (0.0, 0.0, 0.0)
    right_leg.location = (0.0, 0.0, 0.0)

    eyes = []
    for side in (-1, 1):
        eye = ellipsoid(
            f"Eye_{side}",
            (0.112 * side, -0.388, 1.475),
            (0.043, 0.027, 0.050),
            segments=20,
            rings=12,
        )
        eye.data.materials.append(materials["eye"])
        eye.parent = body_pivot
        eyes.append(eye)

    beak = create_wedge_beak(materials["beak"])
    comb = create_comb(materials["comb"])
    bow_tie = create_bow_tie(materials["tie"])
    for accent in (beak, comb, bow_tie):
        accent.parent = body_pivot

    accessory_sets = [
        create_round_glasses(materials["frame"]),
        create_square_glasses(materials["frame"]),
        create_accountant_visor(materials["visor"], materials["frame"]),
        create_headset(materials["frame"], materials["headset_pad"]),
        create_long_tie(materials["tie_oxblood"]),
        create_lanyard(materials["lanyard"], materials["badge"], materials["badge_accent"]),
        create_nameplate(materials["brass"], materials["badge_accent"]),
        create_golden_egg_pin(materials["brass"]),
    ]
    accessory_roots = [objects[0] for objects in accessory_sets]
    accessory_objects = [obj for objects in accessory_sets for obj in objects]

    # The fuller breast/ruff intentionally projects farther forward. Keep all
    # lower accessories resting on top of that new silhouette rather than
    # becoming embedded in it; head accessories retain their facial fit.
    bow_tie.location.y -= 0.075
    for accessory_root in accessory_roots:
        if not accessory_root.name.startswith("AccessoryHead_"):
            accessory_root.location.y -= 0.075

    # Interaction sockets are cheap compatibility points for future data-driven
    # chair, keyboard, peck-target, ground-contact, and egg alignment.
    sockets = [
        create_empty("ChairSocket", body_pivot, (0.0, 0.245, 0.460), "SPHERE", 0.045),
        create_empty("BeakTarget", body_pivot, (0.0, -0.575, 1.350), "SPHERE", 0.035),
        # The actual neck-root bite point.  This socket follows the head bone
        # so gameplay can align it exactly with a predator jaw socket.
        create_empty("NeckGripSocket", body_pivot, (0.0, -0.145, 1.205), "SPHERE", 0.035),
        create_empty("KeyboardTarget", body_pivot, (0.0, -0.500, 0.790), "CUBE", 0.035),
        create_empty("FootGround_L", leg_left_pivot, (0.0, -0.170, -0.285), "SPHERE", 0.025),
        create_empty("FootGround_R", leg_right_pivot, (0.0, -0.170, -0.285), "SPHERE", 0.025),
        create_empty("EggSocket", body_pivot, (0.0, 0.280, 0.320), "SPHERE", 0.035),
    ]

    armature = create_armature(body_pivot)
    body.parent = armature
    skin_body(body, armature)

    # The feather shell deforms with the armature, so every rigid facial piece
    # must follow the same head bone. Parenting them only to BodyPivot makes
    # the skinned face move underneath stationary eyes/beak/comb while pecking.
    for facial_part in (*eyes, beak, comb):
        parent_to_bone_keep_world(facial_part, armature, "head")
    parent_to_bone_keep_world(bow_tie, armature, "chest")
    for accessory_root in accessory_roots:
        target_bone = "head" if accessory_root.name.startswith("AccessoryHead_") else "chest"
        parent_to_bone_keep_world(accessory_root, armature, target_bone)
    for socket in sockets:
        if socket.name in {"BeakTarget", "NeckGripSocket"}:
            parent_to_bone_keep_world(socket, armature, "head")
        elif socket.name == "KeyboardTarget":
            parent_to_bone_keep_world(socket, armature, "chest")

    actions = create_actions(armature)

    body_validation = validate_mesh(body)
    left_validation = validate_mesh(left_leg)
    right_validation = validate_mesh(right_leg)
    base_triangles = sum(
        triangle_count(obj)
        for obj in (body, left_leg, right_leg, *eyes, beak, comb, bow_tie)
    )
    accessory_triangles = {
        objects[0].name: sum(triangle_count(obj) for obj in objects[1:] if obj.type == "MESH")
        for objects in accessory_sets
    }
    head_accessory_max = max(
        triangles for name, triangles in accessory_triangles.items() if name.startswith("AccessoryHead_")
    )
    lower_accessory_max = max(
        triangle_count(bow_tie),
        max(triangles for name, triangles in accessory_triangles.items() if not name.startswith("AccessoryHead_")),
    )
    maximum_visible_triangles = base_triangles - triangle_count(bow_tie) + head_accessory_max + lower_accessory_max
    exported_triangles = base_triangles + sum(accessory_triangles.values())
    if maximum_visible_triangles > 12000:
        raise RuntimeError(f"Visible character triangle budget exceeded: {maximum_visible_triangles}")

    character_objects = [
        root,
        body_pivot,
        head_pivot,
        wing_left_pivot,
        wing_right_pivot,
        leg_left_pivot,
        leg_right_pivot,
        *[obj for obj in bpy.data.objects if obj.name in {"FootLeftPivot", "FootRightPivot"}],
        body,
        left_leg,
        right_leg,
        *eyes,
        beak,
        comb,
        bow_tie,
        *accessory_objects,
        *sockets,
        armature,
    ]

    setup_preview(character_objects, materials)
    SOURCE_PATH.parent.mkdir(parents=True, exist_ok=True)
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_PATH))

    bpy.ops.object.select_all(action="DESELECT")
    for obj in character_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=str(MODEL_PATH),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=False,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_skins=True,
        export_morph=False,
    )

    # The runtime exposes no more than one head and one lower-body accessory.
    # Preview a representative actuary look without hiding anything from glTF.
    preview_accessories = {"AccessoryHead_RoundGlasses", "AccessoryNeck_LongTie"}
    bow_tie.hide_render = True
    for objects in accessory_sets:
        visible_in_preview = objects[0].name in preview_accessories
        for obj in objects[1:]:
            obj.hide_render = not visible_in_preview

    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.scene.render.filepath = str(PREVIEW_PATH)
    bpy.ops.render.render(write_still=True)

    # Render the maximum peck pose as an attachment regression image. Facial
    # pieces are rigidly bone-parented, so this catches any future hierarchy
    # change that would leave them behind while the feather head deforms.
    armature.animation_data.action = actions["peck"]
    bpy.context.scene.frame_set(12)
    bpy.context.scene.render.filepath = str(PECK_PREVIEW_PATH)
    bpy.ops.render.render(write_still=True)

    # Keep a close-up regression render for each live roster combination.  The
    # in-game isometric camera intentionally reads these mainly as silhouettes,
    # so these images catch clipping and floating before export handoff.
    showcase_profiles = [
        ("mabel_round_tie", {"AccessoryHead_RoundGlasses", "AccessoryNeck_LongTie"}),
        ("pip_headset_nameplate", {"AccessoryHead_Headset", "AccessoryBadge_Nameplate"}),
        ("henrietta_square_bow", {"AccessoryHead_SquareGlasses", "BowTie"}),
        ("dot_visor_lanyard", {"AccessoryHead_AccountantVisor", "AccessoryNeck_Lanyard"}),
        ("agnes_round_golden_pin", {"AccessoryHead_RoundGlasses", "AccessoryBadge_GoldenEgg"}),
        ("beatrice_visor_nameplate", {"AccessoryHead_AccountantVisor", "AccessoryBadge_Nameplate"}),
    ]
    ACCESSORY_PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    armature.animation_data.action = actions["idle"]
    bpy.context.scene.frame_set(1)
    for profile_name, visible_accessories in showcase_profiles:
        bow_tie.hide_render = "BowTie" not in visible_accessories
        for objects in accessory_sets:
            visible_in_profile = objects[0].name in visible_accessories
            for obj in objects[1:]:
                obj.hide_render = not visible_in_profile
        bpy.context.scene.render.filepath = str(ACCESSORY_PREVIEW_DIR / f"{profile_name}.png")
        bpy.ops.render.render(write_still=True)

    print("CHICKEN_BUILD_COMPLETE")
    print(f"source={SOURCE_PATH}")
    print(f"model={MODEL_PATH}")
    print(f"preview={PREVIEW_PATH}")
    print(f"peck_preview={PECK_PREVIEW_PATH}")
    print(f"accessory_previews={ACCESSORY_PREVIEW_DIR}")
    print(f"body_components={body_validation[0]} body_nonmanifold={body_validation[1]} body_triangles={body_validation[2]}")
    print(f"left_leg_components={left_validation[0]} left_leg_nonmanifold={left_validation[1]} left_leg_triangles={left_validation[2]}")
    print(f"right_leg_components={right_validation[0]} right_leg_nonmanifold={right_validation[1]} right_leg_triangles={right_validation[2]}")
    print(f"exported_triangles={exported_triangles}")
    print(f"maximum_visible_triangles={maximum_visible_triangles}")
    print("accessory_triangles=" + ",".join(f"{name}:{triangles}" for name, triangles in accessory_triangles.items()))
    print("bones=" + ",".join(armature.data.bones.keys()))
    print("actions=" + ",".join(action.name for action in actions.values()))


if __name__ == "__main__":
    main()
