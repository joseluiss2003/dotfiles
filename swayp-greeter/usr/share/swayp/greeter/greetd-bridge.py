#!/usr/bin/env python3
import json
import os
import pwd
import socket
import struct
import sys


SOCKET = os.environ.get("GREETD_SOCK")

if not SOCKET:
    print(json.dumps({
        "type": "bridge_error",
        "message": "GREETD_SOCK is not set",
    }), flush=True)
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
    response = recv_exact(length).decode("utf-8")
    return json.loads(response)


def emit(payload):
    print(json.dumps(payload, ensure_ascii=False), flush=True)


def list_users():
    result = []

    for entry in pwd.getpwall():
        if entry.pw_uid < 1000 or entry.pw_uid == 65534:
            continue

        if entry.pw_shell in (
            "/usr/bin/nologin",
            "/bin/nologin",
            "/usr/bin/false",
            "/bin/false",
        ):
            continue

        result.append({
            "name": entry.pw_name,
            "realName": entry.pw_gecos.split(",", 1)[0] or entry.pw_name,
        })

    return sorted(result, key=lambda item: item["name"].lower())


def session_environment(username):
    try:
        entry = pwd.getpwnam(username)
    except KeyError:
        return []

    home = entry.pw_dir or f"/home/{username}"

    return [
        f"HOME={home}",
        f"USER={username}",
        f"LOGNAME={username}",
        "XDG_SESSION_TYPE=wayland",
        "XDG_CURRENT_DESKTOP=sway",
        "XDG_SESSION_DESKTOP=sway",
        "DESKTOP_SESSION=sway",
        "PATH=/usr/local/sbin:/usr/local/bin:/usr/bin",
    ]


def create_session(username):
    return request({
        "type": "create_session",
        "username": username,
    })


def cancel_session():
    return request({"type": "cancel_session"})


emit({
    "type": "users",
    "users": list_users(),
})


for line in sys.stdin:
    line = line.rstrip("\n")

    if not line:
        continue

    try:
        message = json.loads(line)
        action = message.get("action")

        if action == "create_session":
            response = create_session(message["username"])

        elif action == "auth_response":
            response = request({
                "type": "post_auth_message_response",
                "response": message.get("response", ""),
            })

        elif action == "start_session":
            username = message["username"]
            environment = message.get("environment")
            if environment is None:
                environment = session_environment(username)

            response = request({
                "type": "start_session",
                "cmd": message.get("command", ["/usr/bin/sway"]),
                "env": environment,
            })

        elif action == "restart_session":
            cancel_session()
            response = create_session(message["username"])

        elif action == "cancel_session":
            response = cancel_session()

        else:
            emit({
                "type": "bridge_error",
                "message": f"Unknown action: {action}",
            })
            continue

        emit(response)

    except Exception as exc:
        emit({
            "type": "bridge_error",
            "message": str(exc),
        })
