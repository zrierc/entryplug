"""Publish the running Steam game to Vesktop as Discord rich presence.

Vesktop's bundled arRPC ships no process scanner for darwin (its process
getters only exist for linux and win32), so it never detects a Steam game by
itself. Steam logs every game start and stop, so this watches that log and
sends the matching activity over arRPC's IPC socket. Vesktop forwards it to
Discord, which resolves the game name from the app id.
"""

import json
import os
import re
import socket
import struct
import time

STEAM = os.path.join(os.path.expanduser("~"), "Library/Application Support/Steam")
LOG = os.path.join(STEAM, "logs/console_log.txt")
DB_CACHE = os.path.join(os.path.expanduser("~"), "Library/Caches/steam-presence/games.tsv")
DB_URL = "https://discord.com/api/v9/applications/detectable"
DB_MAX_AGE = 7 * 24 * 3600
RESEND_EVERY = 30
TAIL_BYTES = 200_000

ADDED = re.compile(r"Game process added : AppID (\d+) \"(.*?)\",")
REMOVED = re.compile(r"Game process removed: AppID (\d+)")
ACF_NAME = re.compile(r'^\s*"name"\s*"(.*)"\s*$', re.MULTILINE)


def log(*parts):
    print(time.strftime("[%Y-%m-%d %H:%M:%S]"), *parts, flush=True)


def normalize(name):
    return re.sub(r"[^0-9a-z]+", "", name.casefold())


def refresh_db():
    """Fetch Discord's detectable games and cache them as name<TAB>id lines."""
    # imported here so the idle process never pays for ssl/email at startup
    import urllib.request

    log("refreshing Discord game database")
    request = urllib.request.Request(
        DB_URL, headers={"User-Agent": "steam-presence", "Accept-Encoding": "identity"}
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        apps = json.load(response)
    games = {}
    for app in apps:
        if not app.get("id") or not app.get("name"):
            continue
        for alias in [app["name"], *(app.get("aliases") or [])]:
            games.setdefault(normalize(alias), app["id"])
    DB_CACHE_DIR = os.path.dirname(DB_CACHE)
    os.makedirs(DB_CACHE_DIR, exist_ok=True)
    with open(DB_CACHE, "w") as cache:
        cache.writelines("%s\t%s\n" % item for item in games.items())


def discord_app_id(name):
    """Discord app id for a game name; scans the cache instead of holding it."""
    if not name:
        return None
    if not os.path.exists(DB_CACHE) or time.time() - os.path.getmtime(DB_CACHE) >= DB_MAX_AGE:
        refresh_db()
    wanted = normalize(name)
    with open(DB_CACHE) as cache:
        for line in cache:
            cached, _, app_id = line.partition("\t")
            if cached == wanted:
                return app_id.strip()
    return None


def steam_name(app_id, path):
    """Display name for a Steam app id, read from its appmanifest."""
    marker = "/steamapps/common/"
    if marker in path:
        apps_dir = os.path.join(path.split(marker)[0], "steamapps")
    else:
        apps_dir = os.path.join(STEAM, "steamapps")
    try:
        with open(os.path.join(apps_dir, "appmanifest_%s.acf" % app_id), errors="replace") as handle:
            manifest = handle.read()
    except OSError:
        return None
    match = ACF_NAME.search(manifest)
    return match.group(1) if match else None


class RPC:
    """Minimal Discord IPC client for Vesktop's arRPC socket."""

    def __init__(self):
        self.sock = None
        self.app_id = None

    @staticmethod
    def _send(sock, op, payload):
        data = json.dumps(payload).encode()
        sock.sendall(struct.pack("<II", op, len(data)) + data)

    @staticmethod
    def _recv(sock):
        head = b""
        while len(head) < 8:
            chunk = sock.recv(8 - len(head))
            if not chunk:
                raise OSError("arRPC closed the socket")
            head += chunk
        _, length = struct.unpack("<II", head)
        body = b""
        while len(body) < length:
            chunk = sock.recv(length - len(body))
            if not chunk:
                raise OSError("arRPC closed the socket")
            body += chunk
        return json.loads(body)

    def _connect(self, app_id):
        for base in (os.environ.get("TMPDIR"), os.environ.get("XDG_RUNTIME_DIR"), "/tmp"):
            path = os.path.join(base, "discord-ipc-0") if base else None
            if not path or not os.path.exists(path):
                continue
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(path)
            sock.settimeout(5)
            self._send(sock, 0, {"v": 1, "client_id": app_id})
            self._recv(sock)
            self.sock, self.app_id = sock, app_id
            return
        raise OSError("no arRPC socket, is Vesktop running?")

    def _activity(self, activity):
        self._send(self.sock, 1, {
            "cmd": "SET_ACTIVITY",
            "nonce": str(time.time()),
            "args": {"pid": os.getpid(), "activity": activity},
        })
        self._recv(self.sock)

    def show(self, app_id, started_ms):
        try:
            if self.sock and self.app_id != app_id:
                self.hide()
            if not self.sock:
                self._connect(app_id)
            self._activity({
                "application_id": app_id,
                "type": 0,
                "timestamps": {"start": started_ms},
            })
        except OSError as error:
            log("activity not sent:", error)
            self.close()

    def hide(self):
        try:
            if self.sock:
                self._activity(None)
        except OSError:
            pass
        self.close()

    def clear_stale(self):
        """Drop activity left behind by an instance that was killed mid-game."""
        try:
            self._connect("0")
            self._activity(None)
        except OSError:
            pass
        self.close()

    def close(self):
        if self.sock:
            try:
                self.sock.close()
            except OSError:
                pass
        self.sock = self.app_id = None


def events():
    """Yield new Steam log lines, then None once per idle second.

    The last TAIL_BYTES are replayed first, so a game that was already running
    when this started is picked up.
    """
    try:
        position = max(0, os.path.getsize(LOG) - TAIL_BYTES)
    except OSError:
        position = 0
    while True:
        # stat before open: an idle second costs one syscall, not four
        try:
            size = os.path.getsize(LOG)
        except OSError:
            size = position
        if size > position:
            try:
                with open(LOG, "rb") as handle:
                    handle.seek(position)
                    fresh = handle.read()
            except OSError:
                fresh = b""
            # only consume complete lines, a half-written line waits for the next read
            end = fresh.rfind(b"\n") + 1
            if end:
                position += end
                for raw in fresh[:end].splitlines():
                    yield raw.decode(errors="replace")
                continue
        yield None
        time.sleep(1)


def main():
    rpc = RPC()
    rpc.clear_stale()
    current = None  # (steam app id, discord app id, started ms)
    sent_at = 0.0

    for line in events():
        if line is not None:
            added = ADDED.search(line)
            if added:
                steam_id, path = added.group(1), added.group(2).strip("'")
                name = steam_name(steam_id, path)
                app_id = discord_app_id(name)
                if app_id:
                    current = (steam_id, app_id, int(time.time() * 1000))
                    sent_at = time.time()
                    rpc.show(app_id, current[2])
                    log("playing", name)
                else:
                    current = None
                    log("no Discord app for AppID %s (%r)" % (steam_id, name))
                continue
            removed = REMOVED.search(line)
            if removed and current and removed.group(1) == current[0]:
                rpc.hide()
                log("stopped")
                current = None

        # resend so a Vesktop restart mid-game gets the activity back
        if current and time.time() - sent_at >= RESEND_EVERY:
            sent_at = time.time()
            rpc.show(current[1], current[2])


if __name__ == "__main__":
    main()
