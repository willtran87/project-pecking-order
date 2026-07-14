"""Print connected-component bounds for the chicken's feather mesh."""

import bpy
from mathutils import Vector


obj = bpy.data.objects["Feather_Torso"]
mesh = obj.data
adjacency = [set() for _ in mesh.vertices]
for edge in mesh.edges:
    a, b = edge.vertices
    adjacency[a].add(b)
    adjacency[b].add(a)

remaining = set(range(len(mesh.vertices)))
components = []
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

for index, component in enumerate(sorted(components, key=len, reverse=True)):
    coords = [obj.matrix_world @ mesh.vertices[i].co for i in component]
    mins = Vector(tuple(min(point[axis] for point in coords) for axis in range(3)))
    maxs = Vector(tuple(max(point[axis] for point in coords) for axis in range(3)))
    center = (mins + maxs) * 0.5
    print(
        f"component={index} vertices={len(component)} "
        f"min={tuple(round(v, 3) for v in mins)} "
        f"max={tuple(round(v, 3) for v in maxs)} "
        f"center={tuple(round(v, 3) for v in center)}"
    )
