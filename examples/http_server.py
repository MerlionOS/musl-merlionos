#!/usr/bin/env python3
"""Simple HTTP server — Python on MerlionOS."""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
import sys

class MerlionHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            body = "Hello from Python HTTP server on MerlionOS!\n"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(body.encode())

        elif self.path == "/status":
            status = {
                "os": "MerlionOS",
                "python": sys.version,
                "pid": os.getpid(),
            }
            body = json.dumps(status, indent=2) + "\n"
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(body.encode())

        elif self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK\n")

        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found\n")

    def log_message(self, format, *args):
        print(f"[python-http] {args[0]}")

if __name__ == "__main__":
    port = 8080
    server = HTTPServer(("0.0.0.0", port), MerlionHandler)
    print(f"Python HTTP server on :{port}")
    server.serve_forever()
