#!/usr/bin/env python3
"""Extract / apply Vimium C settings over Vivaldi localhost CDP."""

from __future__ import annotations

import base64
import json
import os
import socket
import sys
import urllib.error
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

EXT_ID = os.environ.get("VIMIUM_C_EXT_ID", "hfjbmagddngcpeloejdejnfgbamkjaeg")
SKIP = {
  "findModeRawQueryList",
  "innerCSS",
  "findCSS",
  "omniCSS",
  "newTabUrl_f",
  "vomnibarPage_f",
  "focusNewTabContent",
  "dialogMode",
  "name",
  "time",
  "environment",
  "author",
  "description",
  "chrome",
  "chromium",
  "firefox",
  "edge",
  "safari",
}
META = {"name", "time", "@time", "environment"}


def _timeout() -> float:
  return float(os.environ.get("VIMIUM_C_CDP_TIMEOUT", "5"))


def _cdp_base() -> str:
  host = os.environ.get("VIMIUM_C_CDP_HOST", os.environ.get("VIVALDI_CDP_HOST", "127.0.0.1"))
  port = os.environ.get("VIMIUM_C_CDP_PORT", os.environ.get("VIVALDI_CDP_PORT", "19222"))
  return f"http://{host}:{port}"


def _http_json(url: str, timeout: float):
  parsed = urlparse(url)
  req = urllib.request.Request(
    url,
    headers={
      "Host": parsed.netloc,
      "Origin": f"{parsed.scheme}://{parsed.netloc}",
    },
  )
  with urllib.request.urlopen(req, timeout=timeout) as resp:
    return json.loads(resp.read().decode("utf-8"))


def _recvexact(sock: socket.socket, n: int) -> bytes:
  buf = b""
  while len(buf) < n:
    chunk = sock.recv(n - len(buf))
    if not chunk:
      raise OSError("cdp websocket closed")
    buf += chunk
  return buf


def _ws_connect(ws_url: str, timeout: float) -> socket.socket:
  parsed = urlparse(ws_url)
  host = parsed.hostname or "127.0.0.1"
  port = parsed.port or 80
  path = parsed.path or "/"
  if parsed.query:
    path = f"{path}?{parsed.query}"
  sock = socket.create_connection((host, port), timeout=timeout)
  sock.settimeout(timeout)
  key = base64.b64encode(os.urandom(16)).decode("ascii")
  req = (
    f"GET {path} HTTP/1.1\r\n"
    f"Host: {host}:{port}\r\n"
    "Upgrade: websocket\r\n"
    "Connection: Upgrade\r\n"
    f"Sec-WebSocket-Key: {key}\r\n"
    "Sec-WebSocket-Version: 13\r\n"
    f"Origin: http://{host}:{port}\r\n"
    "\r\n"
  )
  sock.sendall(req.encode("ascii"))
  buf = b""
  while b"\r\n\r\n" not in buf:
    chunk = sock.recv(4096)
    if not chunk:
      sock.close()
      raise OSError("cdp websocket handshake closed")
    buf += chunk
  status = buf.split(b"\r\n", 1)[0]
  if b" 101 " not in status:
    sock.close()
    raise OSError(f"cdp websocket handshake failed: {status!r}")
  return sock


def _ws_send_text(sock: socket.socket, payload: bytes) -> None:
  mask = os.urandom(4)
  masked = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
  header = bytearray([0x81])
  n = len(payload)
  if n < 126:
    header.append(0x80 | n)
  elif n < 65536:
    header.append(0x80 | 126)
    header.extend(n.to_bytes(2, "big"))
  else:
    header.append(0x80 | 127)
    header.extend(n.to_bytes(8, "big"))
  sock.sendall(header + mask + masked)


def _ws_recv_text(sock: socket.socket) -> bytes:
  while True:
    hdr = _recvexact(sock, 2)
    opcode = hdr[0] & 0x0F
    length = hdr[1] & 0x7F
    masked = bool(hdr[1] & 0x80)
    if length == 126:
      length = int.from_bytes(_recvexact(sock, 2), "big")
    elif length == 127:
      length = int.from_bytes(_recvexact(sock, 8), "big")
    mask = _recvexact(sock, 4) if masked else b""
    data = _recvexact(sock, length)
    if mask:
      data = bytes(b ^ mask[i % 4] for i, b in enumerate(data))
    if opcode == 0x8:
      return b""
    if opcode in (0x9, 0xA):
      continue
    return data


def _evaluate(ws_url: str, expression: str, timeout: float):
  sock = _ws_connect(ws_url, timeout)
  try:
    msg_id = 1
    _ws_send_text(
      sock,
      json.dumps(
        {
          "id": msg_id,
          "method": "Runtime.evaluate",
          "params": {
            "expression": expression,
            "returnByValue": True,
            "awaitPromise": True,
          },
        }
      ).encode("utf-8"),
    )
    while True:
      raw = _ws_recv_text(sock)
      if not raw:
        raise OSError("cdp websocket closed")
      data = json.loads(raw.decode("utf-8"))
      if data.get("id") != msg_id:
        continue
      if "error" in data:
        raise RuntimeError(data["error"])
      result = data.get("result") or {}
      if result.get("exceptionDetails"):
        raise RuntimeError(result["exceptionDetails"])
      return (result.get("result") or {}).get("value")
  finally:
    sock.close()


def _worker_ws(timeout: float) -> str:
  base = _cdp_base()
  try:
    targets = _http_json(f"{base}/json/list", timeout)
  except (urllib.error.URLError, TimeoutError, OSError, json.JSONDecodeError):
    try:
      targets = _http_json(f"{base}/json", timeout)
    except (urllib.error.URLError, TimeoutError, OSError, json.JSONDecodeError) as exc:
      print(
        f"Vivaldi CDP not reachable at {base} ({exc}). "
        "Start Vivaldi with ~/.local/bin/vivaldi-stable.",
        file=sys.stderr,
      )
      raise SystemExit(2) from exc
  if not isinstance(targets, list):
    targets = []
  for target in targets:
    url = target.get("url") or ""
    if target.get("type") == "service_worker" and EXT_ID in url:
      ws = target.get("webSocketDebuggerUrl")
      if ws:
        return ws
  print(
    f"Vimium C service worker not found on {base}. "
    "Is the extension installed, and was Vivaldi started with ~/.local/bin/vivaldi-stable?",
    file=sys.stderr,
  )
  raise SystemExit(2)


def dump_path() -> Path | None:
  raw = os.environ.get("VIMIUM_C_CDP_DUMP", "")
  return Path(raw) if raw else None


def apply_path() -> Path | None:
  raw = os.environ.get("VIMIUM_C_CDP_APPLY", "")
  return Path(raw) if raw else None


def skip_key(key: str) -> bool:
  return (
    key in SKIP
    or key.startswith("@")
    or key.startswith("vimiumMark")
    or key.startswith("vimiumGlobalMark")
  )


def from_storage(store: dict, version: str) -> dict:
  export = {
    "name": "Vimium C",
    "environment": {"extension": version, "platform": "linux"},
  }
  for key, value in store.items():
    if skip_key(key):
      continue
    if isinstance(value, str) and "\n" in value:
      export[key] = value.split("\n") + [""]
    else:
      export[key] = value
  return export


def to_storage(data: dict) -> dict:
  out = {}
  for key, value in data.items():
    if key in META or skip_key(key):
      continue
    if isinstance(value, list):
      value = "\n".join(value)
    out[key] = value
  return out


def write_json(path: str | None, data: dict) -> None:
  text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
  if path:
    Path(path).write_text(text, encoding="utf-8")
  else:
    sys.stdout.write(text)


def load_export(path: str) -> dict:
  data = json.loads(Path(path).read_text(encoding="utf-8"))
  if not isinstance(data, dict) or data.get("name") not in ("Vimium C", "Vimium++"):
    raise SystemExit(f"not a Vimium C Export: {path}")
  return data


def extract(dest: str | None) -> int:
  dump = dump_path()
  if dump is not None:
    if not dump.is_file():
      print(f"VIMIUM_C_CDP_DUMP not found: {dump}", file=sys.stderr)
      return 2
    data = json.loads(dump.read_text(encoding="utf-8"))
    if isinstance(data, dict) and data.get("name") in ("Vimium C", "Vimium++"):
      export = data
    else:
      export = from_storage(data, "test")
    write_json(dest, export)
    return 0
  timeout = _timeout()
  ws = _worker_ws(timeout)
  payload = _evaluate(
    ws,
    "(async () => ({"
    "store: await chrome.storage.sync.get(null),"
    "version: chrome.runtime.getManifest().version"
    "}))()",
    timeout,
  )
  if not isinstance(payload, dict):
    raise SystemExit("CDP extract returned no object")
  export = from_storage(payload.get("store") or {}, str(payload.get("version") or ""))
  write_json(dest, export)
  return 0


def apply(src: str) -> int:
  storage = to_storage(load_export(src))
  sink = apply_path()
  if sink is not None:
    write_json(str(sink), storage)
    return 0
  timeout = _timeout()
  ws = _worker_ws(timeout)
  payload = json.dumps(storage)
  expression = (
    "(async (data) => {"
    " await chrome.storage.sync.set(data);"
    " await chrome.storage.local.set(data);"
    " return {ok: true, keys: Object.keys(data)};"
    "})(" + payload + ")"
  )
  result = _evaluate(ws, expression, timeout)
  if not (isinstance(result, dict) and result.get("ok")):
    raise SystemExit(f"CDP apply failed: {result!r}")
  print(f"applied {len(result.get('keys') or [])} keys to Vimium C", flush=True)
  return 0


def main(argv: list[str]) -> int:
  if not argv or argv[0] in ("-h", "--help"):
    print("usage: cdp.py extract [file] | apply <file> | ready", file=sys.stderr)
    return 2
  cmd, *rest = argv
  if cmd == "ready":
    try:
      _worker_ws(_timeout())
    except SystemExit:
      return 1
    return 0
  if cmd == "extract":
    dest = rest[0] if rest else None
    return extract(dest)
  if cmd == "apply":
    if not rest:
      raise SystemExit("usage: cdp.py apply <file>")
    return apply(rest[0])
  raise SystemExit(f"unknown cdp command: {cmd}")


if __name__ == "__main__":
  try:
    raise SystemExit(main(sys.argv[1:]))
  except BrokenPipeError:
    raise SystemExit(0)
