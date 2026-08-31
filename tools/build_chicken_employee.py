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


def feather_mesh(
    name: str,
    location: tuple[float, float, float],
    length: float,
    width: float,
    thickness: float,
    rotation: tuple[float, float, float],
    material: bpy.types.Material,
) -> bpy.types.Object:
    """Make a softly beveled, pointed feather rather than an oval primitive."""
    # Root-to-tip profile: a rounded quill end, generous vane, then a tapered
    # point.  The x-axis is thin, y is vane width, and z is feather length.
    profile = [(0.50, 0.26), (0.25, 0.52), (-0.12, 0.46), (-0.38, 0.28), (-0.50, 0.035)]
    vertices: list[tuple[float, float, float]] = []
    for x in (-thickness, thickness):
        for z_factor, width_factor in profile:
            vertices.append((x, -width * width_factor, length * z_factor))
        for z_factor, width_factor in reversed(profile):
            vertices.append((x, width * width_factor, length * z_factor))
    front = list(range(10))
    back = list(range(10, 20))
    faces = [front, list(reversed(back))]
    for index in range(10):
        next_index = (index + 1) % 10
        faces.append((index, next_index, next_index + 10, index + 10))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = rotation
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    bevel = obj.modifiers.new(name="SoftFeatherEdges", type="BEVEL")
    bevel.width = min(0.016, thickness * 0.72)
    bevel.segments = 3
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    obj.select_set(False)
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


def beveled_prism(
    name: str,
    points: list[tuple[float, float]],
    front_y: float,
    depth: float,
    material: bpy.types.Material,
    bevel: float = 0.006,
) -> bpy.types.Object:
    """Extrude an x/z silhouette into a softly finished accessory panel."""
    back_y = front_y + depth
    count = len(points)
    vertices = [(x, front_y, z) for x, z in points] + [(x, back_y, z) for x, z in points]
    faces: list[tuple[int, ...]] = [tuple(range(count)), tuple(reversed(range(count, count * 2)))]
    for index in range(count):
        next_index = (index + 1) % count
        faces.append((index, next_index, next_index + count, index + count))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    if bevel > 0.0:
        modifier = obj.modifiers.new(name="SoftAccessoryEdges", type="BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)
    triangulate = obj.modifiers.new(name="AccessoryTriangulation", type="TRIANGULATE")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.modifier_apply(modifier=triangulate.name)
    obj.select_set(False)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
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


def join_parts(parts: list[bpy.types.Object], name: str) -> bpy.types.Object:
    """Join separate feather pieces without fusing them into a rounded mass."""
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj


def consolidate_accessory_group(objects: list[bpy.types.Object]) -> list[bpy.types.Object]:
    """Keep one runtime visibility root and one mesh node per authored accessory.

    Accessory detail used to export every stitch, stud, frame bar, and clasp as
    an independent mesh.  Those pieces always move and hide as one unit, so the
    separation spent dozens of draw submissions per flock without adding any
    animation or customization value.  Joining below preserves material slots,
    the stable root name consumed by Godot, and the exact world-space silhouette.
    """
    if len(objects) <= 2:
        return objects
    group, *parts = objects
    joined = join_parts(parts, f"{group.name}_Mesh")
    if joined.parent is not group:
        world_transform = joined.matrix_world.copy()
        joined.parent = group
        joined.matrix_world = world_transform
    bpy.context.view_layer.objects.active = joined
    joined.select_set(True)
    bpy.ops.object.material_slot_remove_unused()
    joined.select_set(False)
    return [group, joined]


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
    ]
    body = join_and_remesh(parts, "Feather_Torso", voxel_size=0.016, target_triangles=7600)
    for material in materials:
        body.data.materials.append(material)

    # Zone the one connected surface by silhouette region. The animated tail
    # is a separate pivoted fan, while the torso remains a stable soft shell.
    for polygon in body.data.polygons:
        center = polygon.center
        if center.y < -0.270 and center.z > 1.185:
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
    rim = torus("GoldenEggPin_Rim", (0.205, -0.529, 0.970), 0.049, 0.007, material, (math.pi / 2.0, 0.0, 0.0))
    egg = ellipsoid("GoldenEggPin_Egg", (0.205, -0.536, 0.970), (0.038, 0.018, 0.050), segments=18, rings=10)
    egg.data.materials.append(material)
    bar = beveled_box("GoldenEggPin_Bar", (0.205, -0.510, 1.025), (0.085, 0.020, 0.018), material, 0.004)
    clasp = ellipsoid("GoldenEggPin_Clasp", (0.205, -0.505, 0.935), (0.018, 0.012, 0.018), segments=12, rings=8)
    clasp.data.materials.append(material)
    return create_accessory_group("AccessoryBadge_GoldenEgg", [rim, egg, bar, clasp])


def create_knit_scarf(cloth: bpy.types.Material, trim: bpy.types.Material) -> list[bpy.types.Object]:
    collar = torus("KnitScarf_Collar", (0.0, -0.090, 1.175), 0.275, 0.040, cloth, (0.0, 0.0, 0.0))
    knot = ellipsoid("KnitScarf_Knot", (0.0, -0.485, 1.125), (0.075, 0.045, 0.070), segments=20, rings=12)
    knot.data.materials.append(cloth)
    left_tail = beveled_prism("KnitScarf_TailL", [(-0.060, 1.105), (-0.145, 0.800), (-0.035, 0.755), (0.010, 1.085)], -0.500, 0.032, cloth, 0.008)
    right_tail = beveled_prism("KnitScarf_TailR", [(0.015, 1.085), (0.045, 0.820), (0.145, 0.855), (0.065, 1.105)], -0.497, 0.032, cloth, 0.008)
    stitches = [
        cylinder_between(f"KnitScarf_Stitch{index}", (-0.112, -0.522, 0.815 + index * 0.050), (-0.057, -0.522, 0.830 + index * 0.050), 0.005, trim, 8)
        for index in range(5)
    ]
    return create_accessory_group("AccessoryNeck_KnitScarf", [collar, knot, left_tail, right_tail, *stitches])


def create_sweater_vest(cloth: bpy.types.Material, trim: bpy.types.Material) -> list[bpy.types.Object]:
    panel = beveled_prism(
        "SweaterVest_Panel",
        [(-0.245, 0.565), (-0.300, 0.845), (-0.235, 1.100), (-0.115, 1.125), (0.0, 0.965), (0.115, 1.125), (0.235, 1.100), (0.300, 0.845), (0.245, 0.565)],
        -0.500,
        0.035,
        cloth,
        0.012,
    )
    hem = cylinder_between("SweaterVest_RibbedHem", (-0.230, -0.526, 0.595), (0.230, -0.526, 0.595), 0.015, trim, 12)
    neckline_l = cylinder_between("SweaterVest_NecklineL", (-0.115, -0.526, 1.105), (0.0, -0.526, 0.965), 0.012, trim, 10)
    neckline_r = cylinder_between("SweaterVest_NecklineR", (0.115, -0.526, 1.105), (0.0, -0.526, 0.965), 0.012, trim, 10)
    diamonds: list[bpy.types.Object] = []
    for index, (x, z) in enumerate(((-0.115, 0.765), (0.0, 0.695), (0.115, 0.765), (0.0, 0.855))):
        diamond = beveled_box(f"SweaterVest_Argyle{index}", (x, -0.527, z), (0.080, 0.010, 0.080), trim, 0.004)
        diamond.rotation_euler.y = math.radians(45.0)
        apply_object_transform(diamond)
        diamonds.append(diamond)
    return create_accessory_group("AccessoryBody_SweaterVest", [panel, hem, neckline_l, neckline_r, *diamonds])


def create_newsboy_cap(cloth: bpy.types.Material, trim: bpy.types.Material) -> list[bpy.types.Object]:
    crown = ellipsoid("NewsboyCap_Crown", (0.0, -0.035, 1.720), (0.305, 0.270, 0.115), segments=28, rings=16)
    crown.data.materials.append(cloth)
    brim = ellipsoid("NewsboyCap_Brim", (0.0, -0.315, 1.655), (0.255, 0.170, 0.026), (0.04, 0.0, 0.0), 24, 12)
    brim.data.materials.append(trim)
    band = torus("NewsboyCap_Band", (0.0, -0.035, 1.665), 0.260, 0.018, trim, (0.0, 0.0, 0.0))
    button = ellipsoid("NewsboyCap_Button", (0.0, -0.035, 1.835), (0.030, 0.030, 0.020), segments=14, rings=8)
    button.data.materials.append(trim)
    seams = [
        cylinder_between(f"NewsboyCap_Seam{index}", (0.0, -0.285 + index * 0.095, 1.820), (0.0, -0.310 + index * 0.100, 1.690), 0.004, trim, 8)
        for index in range(4)
    ]
    return create_accessory_group("AccessoryHead_NewsboyCap", [crown, brim, band, button, *seams])


def create_cardigan_collar(cloth: bpy.types.Material, trim: bpy.types.Material) -> list[bpy.types.Object]:
    left = beveled_prism("CardiganCollar_L", [(-0.230, 1.155), (-0.035, 0.970), (-0.070, 0.850), (-0.285, 1.070)], -0.505, 0.032, cloth, 0.009)
    right = beveled_prism("CardiganCollar_R", [(0.230, 1.155), (0.035, 0.970), (0.070, 0.850), (0.285, 1.070)], -0.505, 0.032, cloth, 0.009)
    placket = beveled_box("CardiganCollar_Placket", (0.0, -0.524, 0.800), (0.060, 0.020, 0.330), trim, 0.006)
    buttons: list[bpy.types.Object] = []
    for index in range(4):
        button = ellipsoid(f"CardiganCollar_Button{index}", (0.0, -0.546, 0.680 + index * 0.085), (0.020, 0.010, 0.020), segments=12, rings=8)
        button.data.materials.append(trim)
        buttons.append(button)
    return create_accessory_group("AccessoryNeck_CardiganCollar", [left, right, placket, *buttons])


def create_reading_glasses_chain(frame: bpy.types.Material, chain: bpy.types.Material) -> list[bpy.types.Object]:
    parts = [
        torus("ReadingChain_LensL", (-0.112, -0.424, 1.475), 0.067, 0.010, frame),
        torus("ReadingChain_LensR", (0.112, -0.424, 1.475), 0.067, 0.010, frame),
        cylinder_between("ReadingChain_Bridge", (-0.047, -0.424, 1.475), (0.047, -0.424, 1.475), 0.009, frame),
    ]
    for side, x in (("L", -1.0), ("R", 1.0)):
        points = [(0.178 * x, -0.414, 1.470), (0.250 * x, -0.330, 1.390), (0.235 * x, -0.410, 1.235), (0.180 * x, -0.470, 1.125)]
        for index in range(len(points) - 1):
            parts.append(cylinder_between(f"ReadingChain_{side}{index}", points[index], points[index + 1], 0.0045, chain, 8))
        for index, point in enumerate(points[1:-1]):
            bead = ellipsoid(f"ReadingChain_Bead{side}{index}", point, (0.010, 0.010, 0.010), segments=10, rings=6)
            bead.data.materials.append(chain)
            parts.append(bead)
    return create_accessory_group("AccessoryHead_ReadingGlassesChain", parts)


def create_comb_pencil(body_material: bpy.types.Material, eraser_material: bpy.types.Material, graphite: bpy.types.Material) -> list[bpy.types.Object]:
    start = (-0.175, -0.005, 1.690)
    end = (0.170, 0.065, 1.815)
    shaft = cylinder_between("CombPencil_Shaft", start, end, 0.014, body_material, 12)
    eraser = cylinder_between("CombPencil_Eraser", (-0.205, -0.011, 1.679), start, 0.016, eraser_material, 12)
    tip = cylinder_between("CombPencil_Tip", end, (0.205, 0.072, 1.828), 0.011, graphite, 10)
    ferrule = cylinder_between("CombPencil_Ferrule", (-0.185, -0.007, 1.686), (-0.160, -0.002, 1.695), 0.0165, graphite, 12)
    return create_accessory_group("AccessoryComb_Pencil", [shaft, eraser, tip, ferrule])


def create_pocket_protector(pocket: bpy.types.Material, ink: bpy.types.Material, brass: bpy.types.Material) -> list[bpy.types.Object]:
    sleeve = beveled_prism("PocketProtector_Sleeve", [(0.095, 1.000), (0.290, 1.000), (0.270, 0.790), (0.115, 0.790)], -0.520, 0.028, pocket, 0.009)
    lip = beveled_box("PocketProtector_Lip", (0.192, -0.540, 0.985), (0.205, 0.018, 0.028), ink, 0.005)
    pencils = [
        cylinder_between("PocketProtector_PencilA", (0.155, -0.550, 0.955), (0.145, -0.550, 1.105), 0.009, brass, 10),
        cylinder_between("PocketProtector_PencilB", (0.210, -0.550, 0.955), (0.230, -0.550, 1.080), 0.009, ink, 10),
    ]
    return create_accessory_group("AccessoryBody_PocketProtector", [sleeve, lip, *pencils])


def create_earmuffs(cloth: bpy.types.Material, trim: bpy.types.Material) -> list[bpy.types.Object]:
    parts = [
        cylinder_between("Earmuffs_BandL", (-0.300, -0.010, 1.440), (-0.195, 0.000, 1.710), 0.018, trim, 12),
        cylinder_between("Earmuffs_BandTop", (-0.195, 0.000, 1.710), (0.195, 0.000, 1.710), 0.018, trim, 12),
        cylinder_between("Earmuffs_BandR", (0.195, 0.000, 1.710), (0.300, -0.010, 1.440), 0.018, trim, 12),
    ]
    for side, x in (("L", -0.300), ("R", 0.300)):
        outer = ellipsoid(f"Earmuffs_Outer{side}", (x, -0.060, 1.430), (0.050, 0.075, 0.105), segments=22, rings=14)
        outer.data.materials.append(cloth)
        inner = torus(f"Earmuffs_KnitRing{side}", (x, -0.118, 1.430), 0.060, 0.012, trim, (math.pi / 2.0, 0.0, 0.0))
        parts.extend([outer, inner])
    return create_accessory_group("AccessoryHead_Earmuffs", parts)


def create_neckerchief(cloth: bpy.types.Material, trim: bpy.types.Material) -> list[bpy.types.Object]:
    band = torus("Neckerchief_Band", (0.0, -0.080, 1.155), 0.268, 0.022, cloth, (0.0, 0.0, 0.0))
    bib = beveled_prism("Neckerchief_Bib", [(-0.175, 1.130), (0.175, 1.130), (0.0, 0.820)], -0.505, 0.028, cloth, 0.009)
    knot = ellipsoid("Neckerchief_Knot", (0.0, -0.535, 1.125), (0.055, 0.030, 0.052), segments=18, rings=10)
    knot.data.materials.append(trim)
    edging = [
        cylinder_between("Neckerchief_EdgeL", (-0.158, -0.528, 1.115), (0.0, -0.528, 0.840), 0.008, trim, 8),
        cylinder_between("Neckerchief_EdgeR", (0.158, -0.528, 1.115), (0.0, -0.528, 0.840), 0.008, trim, 8),
    ]
    return create_accessory_group("AccessoryNeck_Neckerchief", [band, bib, knot, *edging])


def create_satchel(cloth: bpy.types.Material, trim: bpy.types.Material, brass: bpy.types.Material) -> list[bpy.types.Object]:
    strap = [
        cylinder_between("Satchel_StrapA", (-0.235, -0.405, 1.150), (0.085, -0.495, 0.760), 0.018, trim, 12),
        cylinder_between("Satchel_StrapB", (0.085, -0.495, 0.760), (0.305, -0.350, 0.610), 0.018, trim, 12),
    ]
    bag = beveled_box("Satchel_Bag", (0.315, -0.335, 0.585), (0.245, 0.110, 0.230), cloth, 0.025)
    flap = beveled_prism("Satchel_Flap", [(0.190, 0.675), (0.440, 0.675), (0.405, 0.555), (0.225, 0.555)], -0.405, 0.035, trim, 0.010)
    buckle = torus("Satchel_Buckle", (0.315, -0.430, 0.575), 0.035, 0.007, brass, (math.pi / 2.0, 0.0, 0.0))
    return create_accessory_group("AccessoryBody_Satchel", [*strap, bag, flap, buckle])


def create_tea_mug_charm(cord: bpy.types.Material, cup_material: bpy.types.Material, accent: bpy.types.Material) -> list[bpy.types.Object]:
    cord_part = cylinder_between("TeaCharm_Cord", (0.155, -0.495, 0.920), (0.225, -0.525, 0.735), 0.006, cord, 8)
    cup = cylinder("TeaCharm_Cup", 0.040, 0.075, (0.225, -0.540, 0.695), 18)
    cup.data.materials.append(cup_material)
    rim = torus("TeaCharm_Rim", (0.225, -0.540, 0.733), 0.034, 0.005, accent, (0.0, 0.0, 0.0))
    handle = torus("TeaCharm_Handle", (0.270, -0.540, 0.700), 0.025, 0.006, accent, (math.pi / 2.0, 0.0, 0.0))
    tag = beveled_box("TeaCharm_Tag", (0.165, -0.548, 0.665), (0.045, 0.012, 0.065), cord, 0.004)
    return create_accessory_group("AccessoryBody_TeaMugCharm", [cord_part, cup, rim, handle, tag])


def create_sleep_mask(cloth: bpy.types.Material, trim: bpy.types.Material) -> list[bpy.types.Object]:
    parts: list[bpy.types.Object] = []
    for side, x in (("L", -0.105), ("R", 0.105)):
        pad = ellipsoid(f"SleepMask_Pad{side}", (x, -0.405, 1.610), (0.115, 0.035, 0.065), (0.0, 0.0, 0.03 if side == "L" else -0.03), 22, 12)
        pad.data.materials.append(cloth)
        star = ellipsoid(f"SleepMask_Stitch{side}", (x, -0.442, 1.610), (0.025, 0.008, 0.025), segments=12, rings=8)
        star.data.materials.append(trim)
        parts.extend([pad, star])
    parts.extend([
        cylinder_between("SleepMask_Bridge", (-0.015, -0.430, 1.610), (0.015, -0.430, 1.610), 0.012, trim, 10),
        cylinder_between("SleepMask_StrapL", (-0.220, -0.375, 1.610), (-0.290, -0.160, 1.590), 0.010, trim, 10),
        cylinder_between("SleepMask_StrapR", (0.220, -0.375, 1.610), (0.290, -0.160, 1.590), 0.010, trim, 10),
    ])
    return create_accessory_group("AccessoryHead_SleepMask", parts)


def create_quilted_capelet(cloth: bpy.types.Material, trim: bpy.types.Material) -> list[bpy.types.Object]:
    collar = torus("Capelet_Collar", (0.0, -0.020, 1.185), 0.285, 0.030, trim, (0.0, 0.0, 0.0))
    back = beveled_prism("Capelet_Back", [(-0.285, 1.155), (-0.320, 0.855), (-0.155, 0.775), (0.0, 0.805), (0.155, 0.775), (0.320, 0.855), (0.285, 1.155)], 0.225, 0.040, cloth, 0.014)
    shoulder_l = ellipsoid("Capelet_ShoulderL", (-0.245, -0.005, 1.095), (0.120, 0.155, 0.075), (0.0, 0.0, -0.18), 20, 12)
    shoulder_r = ellipsoid("Capelet_ShoulderR", (0.245, -0.005, 1.095), (0.120, 0.155, 0.075), (0.0, 0.0, 0.18), 20, 12)
    shoulder_l.data.materials.append(cloth)
    shoulder_r.data.materials.append(cloth)
    quilting: list[bpy.types.Object] = []
    for row, z in enumerate((0.865, 0.945, 1.025)):
        for column, x in enumerate((-0.155, 0.0, 0.155)):
            stud = ellipsoid(f"Capelet_QuiltStud{row}_{column}", (x, 0.200, z), (0.012, 0.010, 0.012), segments=10, rings=6)
            stud.data.materials.append(trim)
            quilting.append(stud)
    return create_accessory_group("AccessoryBody_QuiltedCapelet", [collar, back, shoulder_l, shoulder_r, *quilting])


def create_leg_watch(strap_material: bpy.types.Material, face_material: bpy.types.Material, metal: bpy.types.Material) -> list[bpy.types.Object]:
    strap = torus("LegWatch_Strap", (-0.170, 0.0, 0.190), 0.072, 0.015, strap_material, (0.0, 0.0, 0.0))
    face = beveled_box("LegWatch_Face", (-0.170, -0.075, 0.190), (0.075, 0.026, 0.070), face_material, 0.012)
    rim = torus("LegWatch_Rim", (-0.170, -0.092, 0.190), 0.032, 0.006, metal, (math.pi / 2.0, 0.0, 0.0))
    hand = cylinder_between("LegWatch_Hand", (-0.170, -0.101, 0.190), (-0.154, -0.101, 0.210), 0.0035, metal, 8)
    return create_accessory_group("AccessoryLeg_Watch", [strap, face, rim, hand])


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
    # The shoulder is the actual visible hinge.  Keeping the bone root on the
    # exterior of the torso prevents wing motion from pulling body vertices.
    bone("wing_L", (-0.350, 0.0, 0.960), (-0.455, 0.030, 0.765), "chest")
    bone("wing_R", (0.350, 0.0, 0.960), (0.455, 0.030, 0.765), "chest")
    # A second feather-tip joint lets the outer wing scallops curl after the
    # shoulder has lifted, rather than treating the whole wing as one rigid
    # paddle. The short chains remain inexpensive for the office flock.
    bone("wing_L_tip", (-0.455, 0.030, 0.765), (-0.485, 0.145, 0.555), "wing_L")
    bone("wing_R_tip", (0.455, 0.030, 0.765), (0.485, 0.145, 0.555), "wing_R")
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
    # The torso has no wing-bone weights. Wings are independent skinned meshes
    # attached at the shoulder sockets, so a flap can never stretch the body.
    groups = {name: body.vertex_groups.new(name=name) for name in ("root", "chest", "head")}
    for vertex in body.data.vertices:
        co = vertex.co
        head_weight = smoothstep(1.120, 1.390, co.z)
        lower_weight = 1.0 - smoothstep(0.360, 0.650, co.z)
        root_weight = min(0.75, lower_weight * (1.0 - head_weight))
        chest_weight = max(0.0, 1.0 - head_weight - root_weight)

        if root_weight > 0.0001:
            groups["root"].add([vertex.index], root_weight, "REPLACE")
        if chest_weight > 0.0001:
            groups["chest"].add([vertex.index], chest_weight, "REPLACE")
        if head_weight > 0.0001:
            groups["head"].add([vertex.index], head_weight, "REPLACE")
    modifier = body.modifiers.new(name="ChickenArmatureDeform", type="ARMATURE")
    modifier.object = armature
    modifier.use_deform_preserve_volume = True


def create_articulated_wing(
    side: int,
    covert_material: bpy.types.Material,
    flight_material: bpy.types.Material,
) -> bpy.types.Object:
    """Create a separate three-feather fan hinged from the shoulder bone."""
    suffix = "L" if side < 0 else "R"
    x = float(side)
    # Each feather is deliberately separate geometry. Together they read as a
    # wing fan while keeping clear air around the body and a single hinge point.
    coverts = [
        # Rounded covert anchors the wing visually at the hinge, then three
        # increasingly narrow flight feathers form the familiar chicken fan.
        ellipsoid(f"Wing{suffix}_Covert", (x * 0.418, 0.030, 0.842), (0.052, 0.135, 0.200), (0.08, 0.0, -x * 0.08), 20, 12),
        ellipsoid(f"Wing{suffix}_Secondary", (x * 0.452, 0.068, 0.755), (0.044, 0.125, 0.190), (0.13, 0.0, -x * 0.10), 18, 10),
    ]
    primaries = [
        ellipsoid(f"Wing{suffix}_PrimaryA", (x * 0.478, 0.115, 0.685), (0.034, 0.098, 0.205), (0.20, 0.0, -x * 0.13), 18, 10),
        ellipsoid(f"Wing{suffix}_PrimaryB", (x * 0.495, 0.168, 0.620), (0.030, 0.083, 0.175), (0.28, 0.0, -x * 0.16), 18, 10),
        ellipsoid(f"Wing{suffix}_PrimaryC", (x * 0.500, 0.210, 0.568), (0.026, 0.068, 0.140), (0.36, 0.0, -x * 0.18), 16, 8),
    ]
    for feather in coverts:
        feather.data.materials.append(covert_material)
    for feather in primaries:
        feather.data.materials.append(flight_material)
    for feather in (*coverts, *primaries):
        for polygon in feather.data.polygons:
            polygon.use_smooth = True
    wing = join_parts([*coverts, *primaries], f"ArticulatedWing_{suffix}")
    return wing


def create_wing_pivot(side: int, material: bpy.types.Material) -> bpy.types.Object:
    """A small stationary shoulder socket that makes the hinge visible."""
    suffix = "L" if side < 0 else "R"
    pivot = ellipsoid(
        f"WingPivot_{suffix}",
        (float(side) * 0.350, 0.010, 0.960),
        (0.055, 0.060, 0.060),
        segments=14,
        rings=8,
    )
    pivot.data.materials.append(material)
    return pivot


def create_tail_fan(pivot: bpy.types.Object, material: bpy.types.Material) -> list[bpy.types.Object]:
    """Build a cozy five-feather tail as a separate pivoted fan."""
    parts = [
        ellipsoid("TailFeather_Center", (0.0, 0.440, 1.000), (0.090, 0.245, 0.135), (0.52, 0.0, 0.0), 16, 10),
        ellipsoid("TailFeather_InnerL", (-0.085, 0.430, 0.965), (0.076, 0.225, 0.125), (0.46, 0.08, -0.05), 16, 10),
        ellipsoid("TailFeather_InnerR", (0.085, 0.430, 0.965), (0.076, 0.225, 0.125), (0.46, -0.08, 0.05), 16, 10),
        ellipsoid("TailFeather_OuterL", (-0.155, 0.395, 0.915), (0.064, 0.195, 0.108), (0.36, 0.16, -0.08), 14, 8),
        ellipsoid("TailFeather_OuterR", (0.155, 0.395, 0.915), (0.064, 0.195, 0.108), (0.36, -0.16, 0.08), 14, 8),
    ]
    for feather in parts:
        feather.data.materials.append(material)
        for polygon in feather.data.polygons:
            polygon.use_smooth = True
        world_transform = feather.matrix_world.copy()
        feather.parent = pivot
        feather.matrix_world = world_transform
    return parts


def skin_articulated_wing(wing: bpy.types.Object, armature: bpy.types.Object, side: int) -> None:
    """Bind the panel to the real shoulder/tip chain; the outer feathers lag the lift."""
    suffix = "L" if side < 0 else "R"
    root_group = wing.vertex_groups.new(name=f"wing_{suffix}")
    tip_group = wing.vertex_groups.new(name=f"wing_{suffix}_tip")
    for vertex in wing.data.vertices:
        # The low, rear scallops are deliberately tip-driven, giving the flap
        # a soft folding edge rather than one rigid board-like rotation.
        tip_weight = smoothstep(0.590, 0.790, 0.820 - vertex.co.z)
        tip_weight = max(0.0, min(0.78, tip_weight))
        root_group.add([vertex.index], 1.0 - tip_weight, "REPLACE")
        if tip_weight > 0.0001:
            tip_group.add([vertex.index], tip_weight, "REPLACE")
    modifier = wing.modifiers.new(name="ArticulatedWingDeform", type="ARMATURE")
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
            # A slow, planted breathing cycle.  The torso expands around the
            # chest bone while the feet stay completely still; head and wing
            # easing make the inhale read through the whole silhouette.
            (18, {
                "chest": {"location": (0.0, 0.0, 0.006), "scale": (1.014, 1.010, 1.022)},
                "head": {"location": (0.0, 0.0, 0.007), "rotation": (0.014, -0.035, -0.010)},
                "wing_L": {"rotation": (0.0, 0.0, -0.010)},
                "wing_R": {"rotation": (0.0, 0.0, 0.010)},
            }),
            (36, {
                "chest": {"location": (0.0, 0.0, 0.012), "scale": (1.026, 1.018, 1.040)},
                "head": {"location": (0.0, 0.0, 0.014), "rotation": (0.020, 0.018, 0.016)},
                "wing_L": {"rotation": (0.0, 0.0, -0.020)},
                "wing_R": {"rotation": (0.0, 0.0, 0.020)},
            }),
            (54, {
                "chest": {"location": (0.0, 0.0, 0.004), "scale": (1.010, 1.008, 1.016)},
                "head": {"location": (0.0, 0.0, 0.004), "rotation": (0.004, 0.035, -0.008)},
                "wing_L": {"rotation": (0.0, 0.0, -0.006)},
                "wing_R": {"rotation": (0.0, 0.0, 0.006)},
            }),
            (72, {
                "chest": {"location": (0.0, 0.0, 0.008), "scale": (1.018, 1.012, 1.028)},
                "head": {"location": (0.0, 0.0, 0.009), "rotation": (0.010, -0.025, 0.010)},
                "wing_L": {"rotation": (0.0, 0.0, -0.013)},
                "wing_R": {"rotation": (0.0, 0.0, 0.013)},
            }),
            (96, {}),
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
    flap = create_action(
        armature,
        "Chicken_Flap",
        [
            (1, {}),
            (5, {
                # Mirror the shoulder lift away from the torso so the wings
                # open to the sides on the upstroke instead of clamping in.
                "wing_L": {"rotation": (0.08, 0.0, 1.05)},
                "wing_R": {"rotation": (0.08, 0.0, -1.05)},
                "wing_L_tip": {"rotation": (0.04, 0.0, 0.58)},
                "wing_R_tip": {"rotation": (0.04, 0.0, -0.58)},
            }),
            (9, {}),
            (13, {
                "wing_L": {"rotation": (0.08, 0.0, 1.05)},
                "wing_R": {"rotation": (0.08, 0.0, -1.05)},
                "wing_L_tip": {"rotation": (0.04, 0.0, 0.58)},
                "wing_R_tip": {"rotation": (0.04, 0.0, -0.58)},
            }),
            (17, {}),
        ],
    )
    panic = create_action(
        armature,
        "Chicken_Panic",
        [
            (1, {"head": {"rotation": (-0.10, -0.24, -0.08)}, "leg_L": {"rotation": (0.38, 0.0, 0.0)}, "leg_R": {"rotation": (-0.30, 0.0, 0.0)}}),
            (4, {
                "root": {"location": (0.0, 0.0, 0.055)},
                "head": {"rotation": (-0.18, 0.28, 0.10)},
                "wing_L": {"rotation": (0.10, 0.0, 1.05)}, "wing_R": {"rotation": (0.10, 0.0, -1.05)},
                "wing_L_tip": {"rotation": (0.04, 0.0, 0.58)}, "wing_R_tip": {"rotation": (0.04, 0.0, -0.58)},
                "leg_L": {"rotation": (-0.38, 0.0, 0.0)}, "leg_R": {"rotation": (0.42, 0.0, 0.0)},
            }),
            (7, {"head": {"rotation": (-0.10, -0.30, -0.10)}, "leg_L": {"rotation": (0.42, 0.0, 0.0)}, "leg_R": {"rotation": (-0.38, 0.0, 0.0)}}),
            (10, {
                "root": {"location": (0.0, 0.0, 0.050)},
                "head": {"rotation": (-0.17, 0.30, 0.10)},
                "wing_L": {"rotation": (0.10, 0.0, 1.05)}, "wing_R": {"rotation": (0.10, 0.0, -1.05)},
                "wing_L_tip": {"rotation": (0.04, 0.0, 0.58)}, "wing_R_tip": {"rotation": (0.04, 0.0, -0.58)},
                "leg_L": {"rotation": (-0.38, 0.0, 0.0)}, "leg_R": {"rotation": (0.42, 0.0, 0.0)},
            }),
            (14, {"head": {"rotation": (-0.08, -0.20, -0.06)}, "leg_L": {"rotation": (0.34, 0.0, 0.0)}, "leg_R": {"rotation": (-0.30, 0.0, 0.0)}}),
            (18, {}),
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
    return {"idle": idle, "walk": walk, "peck": peck, "flap": flap, "panic": panic, "sit": sit, "lay": lay}


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
        "wing_covert": make_material("Feathers_Wing_Covert", (0.46, 0.215, 0.075, 1.0), 0.78),
        "face": make_material("Feathers_Face", (0.70, 0.415, 0.175, 1.0), 0.80),
        "eye": make_material("Eyes_Glossy", (0.012, 0.010, 0.009, 1.0), 0.17),
        "beak": make_material("Beak_and_Feet", (0.95, 0.440, 0.055, 1.0), 0.52),
        "comb": make_material("Comb_Barn_Red", (0.62, 0.055, 0.035, 1.0), 0.60),
        "tie": make_material("Corporate_Navy", (0.035, 0.180, 0.300, 1.0), 0.48),
        "tie_oxblood": make_material("Accessory_Cloth_Oxblood", (0.430, 0.075, 0.110, 1.0), 0.50),
        "knit": make_material("Accessory_Cloth_Knit", (0.315, 0.420, 0.455, 1.0), 0.88),
        "knit_trim": make_material("Accessory_Trim_Wool", (0.830, 0.755, 0.605, 1.0), 0.90),
        "leather": make_material("Accessory_Cloth_Leather", (0.285, 0.125, 0.060, 1.0), 0.64),
        "frame": make_material("Accessory_Frame_Graphite", (0.025, 0.040, 0.052, 1.0), 0.34, 0.10),
        "visor": make_material("Accessory_Visor_Green", (0.115, 0.310, 0.235, 1.0), 0.42),
        "headset_pad": make_material("Accessory_Headset_Pad", (0.055, 0.115, 0.145, 1.0), 0.62),
        "lanyard": make_material("Accessory_Lanyard_Mustard", (0.760, 0.420, 0.075, 1.0), 0.54),
        "badge": make_material("Accessory_Badge_Cream", (0.845, 0.825, 0.700, 1.0), 0.64),
        "badge_accent": make_material("Accessory_Badge_Ink", (0.035, 0.180, 0.300, 1.0), 0.48),
        "brass": make_material("Accessory_Brass", (0.610, 0.365, 0.080, 1.0), 0.30, 0.55),
        "ceramic": make_material("Accessory_Ceramic_Cream", (0.875, 0.825, 0.680, 1.0), 0.38),
        "pencil": make_material("Accessory_Pencil_Mustard", (0.890, 0.480, 0.055, 1.0), 0.55),
        "eraser": make_material("Accessory_Eraser_Rose", (0.760, 0.275, 0.255, 1.0), 0.68),
        "ground": make_material("Preview_Ground", (0.095, 0.110, 0.125, 1.0), 0.93),
    }

    root = create_empty("ChickenRig", size=0.12)
    body_pivot = create_empty("BodyPivot", root, size=0.11)
    head_pivot = create_empty("HeadPivot", body_pivot, (0.0, -0.105, 1.435), size=0.07)
    wing_left_pivot = create_empty("WingLeftPivot", body_pivot, (-0.295, 0.0, 0.875), size=0.07)
    wing_right_pivot = create_empty("WingRightPivot", body_pivot, (0.295, 0.0, 0.875), size=0.07)
    tail_feather_pivot = create_empty("TailFeatherPivot", body_pivot, (0.0, 0.330, 0.860), size=0.07)
    leg_left_pivot = create_empty("LegLeftPivot", body_pivot, (-0.170, 0.0, 0.320), size=0.065)
    leg_right_pivot = create_empty("LegRightPivot", body_pivot, (0.170, 0.0, 0.320), size=0.065)
    create_empty("FootLeftPivot", leg_left_pivot, (0.0, 0.0, -0.240), size=0.045)
    create_empty("FootRightPivot", leg_right_pivot, (0.0, 0.0, -0.240), size=0.045)

    body = create_body([materials["feather"], materials["breast"], materials["wing"], materials["face"]])
    tail_feathers = [join_parts(
        create_tail_fan(tail_feather_pivot, materials["wing"]),
        "TailFeatherFan",
    )]
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
        create_knit_scarf(materials["knit"], materials["knit_trim"]),
        create_sweater_vest(materials["knit"], materials["knit_trim"]),
        create_newsboy_cap(materials["knit"], materials["knit_trim"]),
        create_cardigan_collar(materials["knit"], materials["knit_trim"]),
        create_reading_glasses_chain(materials["frame"], materials["brass"]),
        create_comb_pencil(materials["pencil"], materials["eraser"], materials["frame"]),
        create_pocket_protector(materials["badge"], materials["badge_accent"], materials["brass"]),
        create_earmuffs(materials["knit"], materials["knit_trim"]),
        create_neckerchief(materials["knit"], materials["knit_trim"]),
        create_satchel(materials["leather"], materials["knit_trim"], materials["brass"]),
        create_tea_mug_charm(materials["lanyard"], materials["ceramic"], materials["brass"]),
        create_sleep_mask(materials["knit"], materials["knit_trim"]),
        create_quilted_capelet(materials["knit"], materials["knit_trim"]),
        create_leg_watch(materials["leather"], materials["frame"], materials["brass"]),
    ]
    accessory_sets = [consolidate_accessory_group(objects) for objects in accessory_sets]
    accessory_roots = [objects[0] for objects in accessory_sets]
    accessory_objects = [obj for objects in accessory_sets for obj in objects]

    # The fuller breast/ruff intentionally projects farther forward. Keep all
    # lower accessories resting on top of that new silhouette rather than
    # becoming embedded in it; head accessories retain their facial fit.
    bow_tie.location.y -= 0.075
    for accessory_root in accessory_roots:
        if accessory_root.name.startswith(("AccessoryNeck_", "AccessoryBody_", "AccessoryBadge_")):
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
    articulated_wing_left = create_articulated_wing(-1, materials["wing_covert"], materials["wing"])
    articulated_wing_right = create_articulated_wing(1, materials["wing_covert"], materials["wing"])
    wing_pivot_left = create_wing_pivot(-1, materials["wing"])
    wing_pivot_right = create_wing_pivot(1, materials["wing"])
    for wing, side in ((articulated_wing_left, -1), (articulated_wing_right, 1)):
        wing.parent = armature
        skin_articulated_wing(wing, armature, side)
    for pivot in (wing_pivot_left, wing_pivot_right):
        parent_to_bone_keep_world(pivot, armature, "chest")

    # The feather shell deforms with the armature, so every rigid facial piece
    # must follow the same head bone. Parenting them only to BodyPivot makes
    # the skinned face move underneath stationary eyes/beak/comb while pecking.
    for facial_part in (*eyes, beak, comb):
        parent_to_bone_keep_world(facial_part, armature, "head")
    parent_to_bone_keep_world(bow_tie, armature, "chest")
    for accessory_root in accessory_roots:
        if accessory_root.name.startswith("AccessoryHead_"):
            parent_to_bone_keep_world(accessory_root, armature, "head")
        elif accessory_root.name.startswith("AccessoryComb_"):
            world_transform = accessory_root.matrix_world.copy()
            accessory_root.parent = comb
            accessory_root.matrix_world = world_transform
        elif accessory_root.name.startswith("AccessoryLeg_"):
            parent_to_bone_keep_world(accessory_root, armature, "leg_L")
        else:
            parent_to_bone_keep_world(accessory_root, armature, "chest")
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
        for obj in (body, articulated_wing_left, articulated_wing_right, wing_pivot_left, wing_pivot_right, *tail_feathers, left_leg, right_leg, *eyes, beak, comb, bow_tie)
    )
    accessory_triangles = {
        objects[0].name: sum(triangle_count(obj) for obj in objects[1:] if obj.type == "MESH")
        for objects in accessory_sets
    }
    def accessory_max(prefix: str) -> int:
        candidates = [triangles for name, triangles in accessory_triangles.items() if name.startswith(prefix)]
        return max(candidates) if candidates else 0

    # The runtime profiles allow one item per compatibility slot. Budget the
    # most detailed legal silhouette rather than the sum of every hidden mesh.
    maximum_visible_triangles = (
        base_triangles
        - triangle_count(bow_tie)
        + accessory_max("AccessoryHead_")
        + max(triangle_count(bow_tie), accessory_max("AccessoryNeck_"))
        + accessory_max("AccessoryBody_")
        + accessory_max("AccessoryBadge_")
        + accessory_max("AccessoryComb_")
        + accessory_max("AccessoryLeg_")
    )
    exported_triangles = base_triangles + sum(accessory_triangles.values())
    # Layered feathers and softly beveled knit/leather details stay below a
    # practical office-flock budget even in the richest legal profile.
    if maximum_visible_triangles > 28000:
        raise RuntimeError(f"Visible character triangle budget exceeded: {maximum_visible_triangles}")

    character_objects = [
        root,
        body_pivot,
        head_pivot,
        wing_left_pivot,
        wing_right_pivot,
        tail_feather_pivot,
        leg_left_pivot,
        leg_right_pivot,
        *[obj for obj in bpy.data.objects if obj.name in {"FootLeftPivot", "FootRightPivot"}],
        body,
        articulated_wing_left,
        articulated_wing_right,
        wing_pivot_left,
        wing_pivot_right,
        *tail_feathers,
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
        ("cozy_librarian", {"AccessoryHead_NewsboyCap", "AccessoryNeck_KnitScarf", "AccessoryBody_PocketProtector", "AccessoryLeg_Watch"}),
        ("soft_accountant", {"AccessoryHead_ReadingGlassesChain", "AccessoryNeck_CardiganCollar", "AccessoryBadge_GoldenEgg"}),
        ("cozy_coder", {"AccessoryHead_Earmuffs", "AccessoryBody_SweaterVest", "AccessoryComb_Pencil"}),
        ("tea_runner", {"AccessoryHead_RoundGlasses", "AccessoryNeck_KnitScarf", "AccessoryBody_TeaMugCharm"}),
        ("messenger", {"AccessoryHead_AccountantVisor", "AccessoryNeck_Neckerchief", "AccessoryBody_Satchel", "AccessoryLeg_Watch"}),
        ("sleepy_clerk", {"AccessoryHead_SleepMask", "AccessoryBody_QuiltedCapelet"}),
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
