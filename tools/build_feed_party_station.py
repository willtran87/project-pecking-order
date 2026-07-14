"""Build the Feed Party station asset, export it to glTF, and render a preview.

Run with Blender in background mode. The script deliberately starts from an
empty scene so its output is deterministic and safe to regenerate.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

import bpy
from mathutils import Vector


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = PROJECT_ROOT / "assets" / "blender_source" / "feed_party_station.blend"
MODEL_PATH = PROJECT_ROOT / "assets" / "models" / "feed_party_station.glb"
PREVIEW_PATH = PROJECT_ROOT / "captures" / "feed_party_station_preview.png"

random.seed(82471)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.curves,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def material(
    name: str,
    color: tuple[float, float, float, float],
    *,
    metallic: float = 0.0,
    roughness: float = 0.55,
    transmission: float = 0.0,
) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if transmission:
        bsdf.inputs["Transmission Weight"].default_value = transmission
        bsdf.inputs["Alpha"].default_value = color[3]
        mat.surface_render_method = "DITHERED"
    return mat


def assign(obj: bpy.types.Object, mat: bpy.types.Material) -> bpy.types.Object:
    if hasattr(obj.data, "materials"):
        obj.data.materials.append(mat)
    return obj


def parent(obj: bpy.types.Object, root: bpy.types.Object) -> bpy.types.Object:
    obj.parent = root
    return obj


def rounded_cube(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat: bpy.types.Material,
    *,
    bevel: float = 0.06,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    root: bpy.types.Object,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] * 0.5, scale[1] * 0.5, scale[2] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        modifier = obj.modifiers.new("Soft farm-safe edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        modifier.limit_method = "ANGLE"
    assign(obj, mat)
    return parent(obj, root)


def cylinder(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    depth: float,
    mat: bpy.types.Material,
    *,
    vertices: int = 24,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    root: bpy.types.Object,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    bevel = obj.modifiers.new("Rounded rims", "BEVEL")
    bevel.width = min(0.025, radius * 0.12)
    bevel.segments = 2
    assign(obj, mat)
    return parent(obj, root)


def uv_sphere(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat: bpy.types.Material,
    *,
    root: bpy.types.Object,
    segments: int = 24,
    rings: int = 12,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    assign(obj, mat)
    return parent(obj, root)


def create_text(
    name: str,
    text: str,
    location: tuple[float, float, float],
    size: float,
    mat: bpy.types.Material,
    *,
    root: bpy.types.Object,
    extrude: float = 0.008,
    align: str = "CENTER",
) -> bpy.types.Object:
    curve = bpy.data.curves.new(f"{name}Curve", type="FONT")
    curve.body = text
    curve.align_x = align
    curve.align_y = "CENTER"
    curve.size = size
    curve.extrude = extrude
    curve.bevel_depth = 0.002
    curve.bevel_resolution = 2
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    # Font faces local +Z. Rotate it onto the front (-Y) side of the prop.
    obj.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    assign(obj, mat)
    parent(obj, root)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj.select_set(False)
    return obj


def create_end_wall(
    name: str,
    x: float,
    metal: bpy.types.Material,
    root: bpy.types.Object,
) -> bpy.types.Object:
    # A tapered cap closes the U-shaped trough without visually filling it.
    thickness = 0.10
    inner_y = 0.22
    outer_y = 0.39
    bottom_z = 0.28
    top_z = 0.72
    verts = [
        (x - thickness / 2, -inner_y, bottom_z),
        (x - thickness / 2, inner_y, bottom_z),
        (x - thickness / 2, outer_y, top_z),
        (x - thickness / 2, -outer_y, top_z),
        (x + thickness / 2, -inner_y, bottom_z),
        (x + thickness / 2, inner_y, bottom_z),
        (x + thickness / 2, outer_y, top_z),
        (x + thickness / 2, -outer_y, top_z),
    ]
    faces = [
        (0, 1, 2, 3),
        (4, 7, 6, 5),
        (0, 4, 5, 1),
        (3, 2, 6, 7),
        (1, 5, 6, 2),
        (0, 3, 7, 4),
    ]
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bevel = obj.modifiers.new("Safe cap edges", "BEVEL")
    bevel.width = 0.025
    bevel.segments = 2
    assign(obj, metal)
    return parent(obj, root)


def create_sack(
    prefix: str,
    x: float,
    y: float,
    lean: float,
    canvas: bpy.types.Material,
    green: bpy.types.Material,
    ink: bpy.types.Material,
    twine: bpy.types.Material,
    root: bpy.types.Object,
) -> None:
    sack = rounded_cube(
        f"{prefix}_Sack",
        (x, y, 0.66),
        (0.60, 0.30, 0.88),
        canvas,
        bevel=0.16,
        rotation=(0.0, lean, 0.0),
        root=root,
    )
    # Soft side bulges make the bag read as stuffed cloth rather than a box.
    for side in (-1.0, 1.0):
        uv_sphere(
            f"{prefix}_SideBulge_{'L' if side < 0 else 'R'}",
            (x + side * 0.275, y, 0.61),
            (0.10, 0.13, 0.31),
            canvas,
            root=root,
            segments=16,
            rings=8,
        )
    rounded_cube(
        f"{prefix}_GreenLabel",
        (x, y - 0.166, 0.67),
        (0.49, 0.022, 0.49),
        green,
        bevel=0.035,
        root=root,
    )
    create_text(
        f"{prefix}_MoraleText",
        "MORALE",
        (x, y - 0.184, 0.77),
        0.105,
        canvas,
        root=root,
        extrude=0.004,
    )
    create_text(
        f"{prefix}_PelletsText",
        "PELLETS",
        (x, y - 0.184, 0.64),
        0.096,
        canvas,
        root=root,
        extrude=0.004,
    )
    create_text(
        f"{prefix}_HRText",
        "HR APPROVED",
        (x, y - 0.184, 0.51),
        0.045,
        ink,
        root=root,
        extrude=0.003,
    )
    cylinder(
        f"{prefix}_Neck",
        (x, y, 1.12),
        0.17,
        0.18,
        canvas,
        vertices=20,
        root=root,
    )
    cylinder(
        f"{prefix}_Twine",
        (x, y, 1.14),
        0.185,
        0.035,
        twine,
        vertices=20,
        root=root,
    )
    # Deliberate fold on the bag top.
    rounded_cube(
        f"{prefix}_Fold",
        (x + 0.09, y, 1.22),
        (0.25, 0.16, 0.22),
        canvas,
        bevel=0.07,
        rotation=(0.0, -0.22, 0.05),
        root=root,
    )


def join_objects(objects: list[bpy.types.Object], name: str, root: bpy.types.Object) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    objects[0].name = name
    objects[0].parent = root
    return objects[0]


def build_asset() -> bpy.types.Object:
    root = bpy.data.objects.new("FeedPartyStation", None)
    bpy.context.collection.objects.link(root)
    root["asset_role"] = "feed_party_station"
    root["nominal_width_m"] = 3.5

    galvanized = material("Galvanized Metal", (0.46, 0.54, 0.57, 1.0), metallic=0.72, roughness=0.29)
    galvanized_dark = material("Galvanized Shadow", (0.20, 0.27, 0.28, 1.0), metallic=0.68, roughness=0.34)
    rubber = material("Trough Mat", (0.045, 0.13, 0.13, 1.0), metallic=0.0, roughness=0.83)
    pellet = material("Morale Pellets", (0.56, 0.29, 0.09, 1.0), roughness=0.82)
    pellet_light = material("Morale Pellet Highlights", (0.79, 0.48, 0.16, 1.0), roughness=0.76)
    canvas = material("Feed Sack Canvas", (0.83, 0.72, 0.48, 1.0), roughness=0.92)
    corporate_green = material("Compliance Green", (0.07, 0.30, 0.25, 1.0), roughness=0.57)
    cream = material("Warm Lettering", (0.95, 0.88, 0.67, 1.0), roughness=0.66)
    red = material("Waterer Red", (0.55, 0.08, 0.055, 1.0), roughness=0.48)
    water = material("Water Reservoir", (0.38, 0.67, 0.72, 0.62), roughness=0.20, transmission=0.35)
    twine = material("Baling Twine", (0.32, 0.18, 0.07, 1.0), roughness=0.96)

    rounded_cube("FeedParty_RubberMat", (0.0, 0.0, 0.045), (3.42, 2.12, 0.09), rubber, bevel=0.10, root=root)
    # Small inlaid stripes keep the floor footprint readable from an isometric view.
    for x in (-1.42, 1.42):
        rounded_cube(
            f"Mat_ComplianceStripe_{'L' if x < 0 else 'R'}",
            (x, -0.01, 0.097),
            (0.065, 1.74, 0.012),
            cream,
            bevel=0.015,
            root=root,
        )

    # Low chicken-facing galvanized trough.
    rounded_cube("Trough_Floor", (0.0, -0.20, 0.29), (2.52, 0.44, 0.15), galvanized_dark, bevel=0.055, root=root)
    rounded_cube(
        "Trough_WallFront",
        (0.0, -0.41, 0.49),
        (2.74, 0.10, 0.50),
        galvanized,
        bevel=0.045,
        rotation=(math.radians(-11.0), 0.0, 0.0),
        root=root,
    )
    rounded_cube(
        "Trough_WallBack",
        (0.0, 0.01, 0.49),
        (2.74, 0.10, 0.50),
        galvanized,
        bevel=0.045,
        rotation=(math.radians(11.0), 0.0, 0.0),
        root=root,
    )
    create_end_wall("Trough_EndCap_L", -1.32, galvanized, root)
    create_end_wall("Trough_EndCap_R", 1.32, galvanized, root)
    for side, y in (("Front", -0.65), ("Back", 0.25)):
        cylinder(
            f"Trough_Rim_{side}",
            (0.0, y, 0.72),
            0.055,
            2.82,
            galvanized_dark,
            vertices=20,
            rotation=(0.0, math.radians(90.0), 0.0),
            root=root,
        )
    for x in (-1.05, 1.05):
        for y in (-0.38, -0.02):
            cylinder(
                f"Trough_Leg_{x:+.2f}_{y:+.2f}",
                (x, y, 0.20),
                0.045,
                0.34,
                galvanized_dark,
                vertices=16,
                root=root,
            )
    for x in (-1.05, 1.05):
        rounded_cube(
            f"Trough_Foot_{x:+.2f}",
            (x, -0.20, 0.13),
            (0.12, 0.68, 0.07),
            galvanized_dark,
            bevel=0.025,
            root=root,
        )

    # A solid feed bed plus irregular pellets ensures it remains visible at game scale.
    rounded_cube("Trough_FeedBed", (0.0, -0.20, 0.57), (2.42, 0.36, 0.10), pellet, bevel=0.055, root=root)
    pellets: list[bpy.types.Object] = []
    for index in range(54):
        x = random.uniform(-1.13, 1.13)
        y = random.uniform(-0.34, -0.08)
        z = random.uniform(0.61, 0.665)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.0, location=(x, y, z))
        grain = bpy.context.object
        grain.name = f"Pellet_{index:02d}"
        grain.scale = (
            random.uniform(0.025, 0.045),
            random.uniform(0.018, 0.032),
            random.uniform(0.013, 0.024),
        )
        grain.rotation_euler = (random.random(), random.random(), random.random())
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        assign(grain, pellet_light if index % 4 == 0 else pellet)
        parent(grain, root)
        pellets.append(grain)
    join_objects(pellets, "Trough_VisiblePellets", root)

    # Corporate plaque is readable in close-up but remains a simple color block at distance.
    rounded_cube("Trough_CompliancePlaque", (0.0, -0.682, 0.46), (1.42, 0.035, 0.29), corporate_green, bevel=0.035, root=root)
    create_text("FeedParty_Title", "FEED PARTY", (0.0, -0.706, 0.51), 0.16, cream, root=root, extrude=0.006)
    create_text("FeedParty_Subtitle", "ATTENDANCE REQUIRED", (0.0, -0.708, 0.385), 0.055, cream, root=root, extrude=0.004)

    create_sack("FeedSack_A", -1.15, 0.67, math.radians(-4.0), canvas, corporate_green, galvanized_dark, twine, root)
    create_sack("FeedSack_B", -0.48, 0.72, math.radians(5.0), canvas, corporate_green, galvanized_dark, twine, root)

    # Poultry waterer: reservoir, cap, and annular-looking red drinking tray.
    cylinder("Waterer_Tray", (0.92, 0.67, 0.22), 0.43, 0.13, red, vertices=32, root=root)
    cylinder("Waterer_TrayInset", (0.92, 0.67, 0.30), 0.32, 0.055, galvanized_dark, vertices=32, root=root)
    cylinder("Waterer_Reservoir", (0.92, 0.67, 0.66), 0.28, 0.72, water, vertices=32, root=root)
    cylinder("Waterer_Cap", (0.92, 0.67, 1.04), 0.17, 0.10, red, vertices=28, root=root)
    cylinder("Waterer_Handle", (0.92, 0.67, 1.14), 0.025, 0.30, galvanized_dark, vertices=16, rotation=(0.0, math.radians(90.0), 0.0), root=root)

    # Galvanized scoop rests beside the trough, with its broad bowl facing the camera.
    uv_sphere("FeedScoop_Bowl", (1.44, 0.42, 0.27), (0.24, 0.12, 0.095), galvanized, root=root, segments=24, rings=12)
    cylinder(
        "FeedScoop_Handle",
        (1.27, 0.57, 0.50),
        0.035,
        0.60,
        galvanized_dark,
        vertices=16,
        rotation=(math.radians(-42.0), math.radians(-18.0), 0.0),
        root=root,
    )
    cylinder("FeedScoop_Grip", (1.16, 0.67, 0.72), 0.065, 0.16, corporate_green, vertices=20, rotation=(math.radians(-42.0), math.radians(-18.0), 0.0), root=root)

    # Six exported transforms are the explicit gathering locations used by gameplay.
    attendance_positions = (
        (-1.08, -0.97, 0.10),
        (0.00, -0.97, 0.10),
        (1.08, -0.97, 0.10),
        (-1.08, 0.98, 0.10),
        (0.00, 0.98, 0.10),
        (1.08, 0.98, 0.10),
    )
    for index, position in enumerate(attendance_positions):
        socket = bpy.data.objects.new(f"AttendanceSocket_{index}", None)
        bpy.context.collection.objects.link(socket)
        socket.empty_display_type = "CIRCLE"
        socket.empty_display_size = 0.20
        socket.location = position
        socket.rotation_euler.z = 0.0 if index < 3 else math.pi
        socket["station_role"] = "attendance_socket"
        socket["attendance_index"] = index
        parent(socket, root)

    return root


def asset_descendants(root: bpy.types.Object) -> list[bpy.types.Object]:
    result = [root]
    stack = list(root.children)
    while stack:
        obj = stack.pop()
        result.append(obj)
        stack.extend(obj.children)
    return result


def export_asset(root: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in asset_descendants(root):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=str(MODEL_PATH),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_cameras=False,
        export_lights=False,
    )


def render_preview(root: bpy.types.Object) -> None:
    studio = bpy.data.collections.new("PreviewStudio")
    bpy.context.scene.collection.children.link(studio)

    ground_mat = material("Preview Ground", (0.055, 0.072, 0.073, 1.0), roughness=0.94)
    bpy.ops.mesh.primitive_plane_add(size=20.0, location=(0.0, 0.0, -0.015))
    ground = bpy.context.object
    ground.name = "PreviewGround"
    assign(ground, ground_mat)
    for collection in list(ground.users_collection):
        collection.objects.unlink(ground)
    studio.objects.link(ground)

    target = Vector((0.0, -0.02, 0.55))
    camera_data = bpy.data.cameras.new("FeedPartyPreviewCamera")
    camera = bpy.data.objects.new("FeedPartyPreviewCamera", camera_data)
    studio.objects.link(camera)
    camera.location = (4.35, -6.20, 3.55)
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.lens = 56
    bpy.context.scene.camera = camera

    def area_light(name: str, location: tuple[float, float, float], energy: float, size: float, color: tuple[float, float, float]) -> None:
        data = bpy.data.lights.new(name, type="AREA")
        data.energy = energy
        data.shape = "DISK"
        data.size = size
        data.color = color
        obj = bpy.data.objects.new(name, data)
        studio.objects.link(obj)
        obj.location = location
        obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()

    area_light("PreviewKey", (-3.5, -4.2, 6.0), 1100.0, 4.2, (1.0, 0.82, 0.62))
    area_light("PreviewFill", (4.2, -1.5, 3.7), 750.0, 3.2, (0.60, 0.80, 1.0))
    area_light("PreviewRim", (0.0, 4.2, 4.8), 950.0, 3.0, (0.78, 0.95, 0.82))

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(PREVIEW_PATH)
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    scene.world.color = (0.018, 0.026, 0.028)
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)


def verify(root: bpy.types.Object) -> None:
    required = {
        "FeedPartyStation",
        "Trough_WallFront",
        "Trough_WallBack",
        "Trough_VisiblePellets",
        "FeedSack_A_Sack",
        "FeedSack_B_Sack",
        "Waterer_Reservoir",
        "FeedScoop_Bowl",
        *(f"AttendanceSocket_{index}" for index in range(6)),
    }
    descendants = {obj.name for obj in asset_descendants(root)}
    missing = sorted(required - descendants)
    if missing:
        raise RuntimeError(f"Feed Party asset is missing objects: {missing}")

    mesh_points: list[Vector] = []
    for obj in asset_descendants(root):
        if obj.type != "MESH":
            continue
        mesh_points.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    width = max(point.x for point in mesh_points) - min(point.x for point in mesh_points)
    if width > 3.55:
        raise RuntimeError(f"Feed Party station is too wide: {width:.3f}m")
    if not 3.30 <= width:
        raise RuntimeError(f"Feed Party station does not fill its intended footprint: {width:.3f}m")
    print(f"Verified asset width: {width:.3f}m")


def main() -> None:
    SOURCE_PATH.parent.mkdir(parents=True, exist_ok=True)
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    clear_scene()
    root = build_asset()
    verify(root)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_PATH))
    export_asset(root)
    render_preview(root)
    print(f"Saved source: {SOURCE_PATH}")
    print(f"Exported model: {MODEL_PATH}")
    print(f"Rendered preview: {PREVIEW_PATH}")


if __name__ == "__main__":
    main()
