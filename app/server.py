#!/usr/bin/env python3
import argparse
import http.server
import json
import socketserver
from pathlib import Path


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, directory=None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

    def do_GET(self):
        if self.path in {"/health", "/healthz"}:
            payload = json.dumps({"status": "ok", "app": "snake-game"}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        super().do_GET()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=18601)
    parser.add_argument("--web-root", default=None)
    args = parser.parse_args()

    web_root = Path(args.web_root).resolve() if args.web_root else Path(__file__).resolve().parent

    class ReusableTCPServer(socketserver.TCPServer):
        allow_reuse_address = True

    with ReusableTCPServer(
        (args.host, args.port),
        lambda *a, **k: Handler(*a, directory=str(web_root), **k),
    ) as httpd:
        print(f"Serving {web_root} on {args.host}:{args.port}")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
