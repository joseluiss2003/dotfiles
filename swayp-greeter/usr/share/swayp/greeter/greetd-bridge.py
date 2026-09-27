#!/usr/bin/env python3
import json
import os
import pwd
import socket
import struct
import sys

SOCKET = os.environ.get("GREETD_SOCK")
if not SOCKET:
    print(json.dumps({"type": "bridge_error", "message": "GREETD_SOCK is not set"}), flush=True)
    sys.exit(1)

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.connect(SOCKET)

def recv_exact(size):
    data = b""
    while len(data) < size:
        chunk = sock.recv(size - len(data))
        if not chunk:
            raise EOFError("greetd socket closed")
        data += chunk
    return data

def request(payload):
    raw = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    sock.sendall(struct.pack("@I", len(raw)) + raw)
    length = struct.unpack("@I", recv_exact(4))[0]
    return json.loads(recv_exact(length).decode("utf-8"))

def emit(payload):
    print(json.dumps(payload, ensure_ascii=False), flush=True)

def users():
    result = []
    for entry in pwd.getpwall():
        if entry.pw_uid < 1000 or entry.pw_uid == 65534:
            continue
        if entry.pw_shell in ("/usr/bin/nologin", "/bin/nologin", "/usr/bin/false", "/bin/false"):
            continue
        result.append({
            "name": entry.pw_name,
            "realName": entry.pw_gecos.split(",", 1)[0] or entry.pw_name,
        })
    return sorted(result, key=lambda item: item["name"].lower())

emit({"type": "users", "users": users()})

for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue

    try:
        message = json.loads(line)
        action = message.get("action")

        if action == "create_session":
            response = request({
                "type": "create_session",
                "username": message["username"],
            })

        elif action == "auth_response":
            response = request({
                "type": "post_auth_message_response",
                "response": message.get("response", ""),
            })

        elif action == "start_session":
            response = request({
                "type": "start_session",
                "cmd": message.get("command", ["/usr/bin/sway"]),
                "env": message.get("environment", []),
            })

        elif action == "cancel_session":
            response = request({"type": "cancel_session"})

        else:
            emit({"type": "bridge_error", "message": "Unknown action: " + str(action)})
            continue

        emit(response)

    except Exception as exc:
        emit({"type": "bridge_error", "message": str(exc)})
