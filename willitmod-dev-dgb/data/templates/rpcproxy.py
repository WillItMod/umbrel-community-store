import json
import os
import sys
import http.client
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


TARGET_RPC_URL = os.environ.get("TARGET_RPC_URL", "http://dgbd:14022/")
FORCE_ALGO = os.environ.get("FORCE_ALGO", "sha256d")
LISTEN_HOST = os.environ.get("LISTEN_HOST", "0.0.0.0")
LISTEN_PORT = int(os.environ.get("LISTEN_PORT", "14022"))


def _read_body(handler: BaseHTTPRequestHandler) -> bytes:
    length_header = handler.headers.get("Content-Length")
    if not length_header:
        return b""
    return handler.rfile.read(int(length_header))


def _force_algo(payload: object) -> object:
    if not isinstance(payload, dict):
        return payload
    if payload.get("method") != "getblocktemplate":
        return payload

    params = payload.get("params")
    if params is None:
        payload["params"] = [{}, FORCE_ALGO]
        return payload

    if not isinstance(params, list):
        return payload

    if len(params) == 0:
        payload["params"] = [{}, FORCE_ALGO]
        return payload

    if len(params) == 1:
        template_req = params[0]
        if template_req is None:
            template_req = {}
        payload["params"] = [template_req, FORCE_ALGO]
        return payload

    # If the caller already provided algo, leave it alone.
    return payload


class Handler(BaseHTTPRequestHandler):
    server_version = "axedgb-rpcproxy/1.0"

    def do_POST(self) -> None:
        body = _read_body(self)
        try:
            request_json = json.loads(body.decode("utf-8")) if body else None
        except Exception:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b"invalid json")
            return

        if isinstance(request_json, list):
            request_json = [_force_algo(item) for item in request_json]
        else:
            request_json = _force_algo(request_json)

        out_body = json.dumps(request_json).encode("utf-8")

        content_type = self.headers.get("Content-Type") or "application/json"
        auth = self.headers.get("Authorization")

        conn = http.client.HTTPConnection("dgbd", 14022, timeout=15)
        headers = {
            "Content-Type": content_type,
            "Content-Length": str(len(out_body)),
        }
        if auth:
            headers["Authorization"] = auth

        try:
            conn.request("POST", "/", body=out_body, headers=headers)
            resp = conn.getresponse()
            resp_body = resp.read()
            self.send_response(resp.status)
            for key, value in resp.getheaders():
                if key.lower() in {"connection", "transfer-encoding"}:
                    continue
                self.send_header(key, value)
            self.end_headers()
            try:
                self.wfile.write(resp_body)
            except BrokenPipeError:
                return
        except Exception as e:
            self.send_response(502)
            self.end_headers()
            try:
                self.wfile.write(str(e).encode("utf-8"))
            except BrokenPipeError:
                return
        finally:
            try:
                conn.close()
            except Exception:
                pass

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), fmt % args))


def main() -> None:
    httpd = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler)
    sys.stderr.write(f"[rpcproxy] listening on {LISTEN_HOST}:{LISTEN_PORT}, forwarding to {TARGET_RPC_URL}, force_algo={FORCE_ALGO}\n")
    httpd.serve_forever()


if __name__ == "__main__":
    main()
