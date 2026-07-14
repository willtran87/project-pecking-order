"""Start the BlenderMCP socket after Blender finishes opening its UI."""

import bpy


def start_blender_mcp() -> None:
    scene = bpy.context.scene
    scene.blendermcp_port = 9876

    if scene.blendermcp_server_running:
        print("BlenderMCP socket is already running on localhost:9876")
        return None

    result = bpy.ops.blendermcp.start_server()
    print(f"BlenderMCP start result: {result}")
    return None


bpy.app.timers.register(start_blender_mcp, first_interval=1.0)
