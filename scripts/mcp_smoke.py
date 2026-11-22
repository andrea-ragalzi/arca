"""Read-only stdio/bridge check, invoked on an isolated snapshot by ai_check.sh."""

import json
import os
from pathlib import Path
import queue
import socket
import subprocess
import sys
import threading
import time


def main():
    if len(sys.argv) != 5:
        raise SystemExit("Use bash scripts/ai_check.sh --mcp")
    project, godot, server_bin, output = map(Path, sys.argv[1:])
    project, output = project.resolve(), output.resolve()
    if project.parent != output or not output.name.startswith("ai-check-"):
        raise SystemExit("Only isolated ai-check snapshots are supported")
    # Do not contend with Zed's port 9080 or another smoke test.
    with socket.socket() as check:
        check.bind(("127.0.0.1", 19080))
    env = dict(os.environ, GODOT_MCP_BRIDGE_URL="ws://127.0.0.1:19080",
               GODOT_MCP_TRANSPORT="stdio", GODOT_MCP_PROJECT_DIR=str(project),
               GODOT_MCP_GODOT_BIN=str(godot), GODOT_MCP_DEFAULT_TOOLSETS="inspection")
    messages = queue.Queue()
    frames = []
    results = {}
    with (output / "server.log").open("w") as server_log, (output / "editor.log").open("w") as editor_log:
        server = subprocess.Popen([str(server_bin)], stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, stderr=server_log, text=True, env=env)
        editor = None

        def reader():
            for line in server.stdout:
                try:
                    frame = json.loads(line)
                    if frame.get("jsonrpc") != "2.0":
                        raise ValueError("Non-protocol stdout: " + line)
                    frames.append(frame)
                    messages.put(frame)
                except Exception as exc:
                    messages.put(exc)
            messages.put(RuntimeError("MCP stdout closed"))

        threading.Thread(target=reader, daemon=True).start()
        request_id = 0

        def request(method, params):
            nonlocal request_id
            request_id += 1
            server.stdin.write(json.dumps({"jsonrpc": "2.0", "id": request_id,
                                           "method": method, "params": params}) + "\n")
            server.stdin.flush()
            end = time.monotonic() + 25
            while time.monotonic() < end:
                frame = messages.get(timeout=max(0.1, end - time.monotonic()))
                if isinstance(frame, Exception):
                    raise frame
                if frame.get("id") == request_id:
                    if "error" in frame:
                        raise RuntimeError(frame["error"])
                    return frame["result"]
            raise TimeoutError(method)

        def call(name, arguments):
            result = request("tools/call", {"name": name, "arguments": arguments})
            results[name + ":" + json.dumps(arguments, sort_keys=True)] = result
            if result.get("isError", False):
                raise RuntimeError(result)
            return result.get("structuredContent", {})

        try:
            results["initialize"] = request("initialize", {
                "protocolVersion": "2025-03-26", "capabilities": {},
                "clientInfo": {"name": "arca-readonly-check", "version": "1"},
            })
            server.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")
            server.stdin.flush()
            results["tools"] = request("tools/list", {})
            editor = subprocess.Popen([str(godot), "--headless", "--editor", "--path",
                                       str(project), "res://arca/mission_room.tscn"],
                                      stdout=editor_log, stderr=subprocess.STDOUT, env=env)
            deadline = time.monotonic() + 40
            while True:
                health = call("godot_health_check", {})
                if health.get("bridge_connected"):
                    break
                if editor.poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError("Godot addon did not connect; inspect editor.log")
                time.sleep(1)
            call("godot_get_server_info", {})
            call("godot_list_toolsets", {})
            info = call("godot_inspection_get_project_info", {})
            if Path(info["project_path"]).resolve() != project or not info["godot_version"].startswith("4.5.1"):
                raise RuntimeError("Wrong project or engine: " + str(info))
            active = call("godot_inspection_get_active_scene", {})
            if active.get("path") != "res://arca/mission_room.tscn":
                raise RuntimeError("Wrong active scene: " + str(active))
            tree = call("godot_inspection_get_scene_tree", {"max_depth": 2})
            if tree.get("tree", {}).get("name") != "ArcaMissionRoom":
                raise RuntimeError("Unexpected mission tree")
            call("godot_inspection_get_node_properties", {"node_path": "."})
            for node, prop in [("Floor", "collision_layer"), ("Player", "position")]:
                value = call("godot_inspection_get_node_property", {"node_path": node, "property": prop})
                if not value.get("exists"):
                    raise RuntimeError("Missing property: " + str(value))
                print(node + "." + prop + " = " + json.dumps(value["value"]))
            print("PASS: real read-only MCP calls; ARCA mission tree; Godot 4.5.1; valid JSON-RPC stdout")
        finally:
            for process in [editor, server]:
                if process is not None:
                    process.terminate()
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
            (output / "mcp-results.json").write_text(json.dumps(results, indent=2))
            (output / "protocol-frames.json").write_text(json.dumps(frames, indent=2))
        if "ERROR:" in (output / "editor.log").read_text():
            raise RuntimeError("Godot reported an error; inspect editor.log")


if __name__ == "__main__":
    main()
