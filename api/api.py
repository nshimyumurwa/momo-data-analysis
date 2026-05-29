"""
MoMo SMS REST API
=================
A secure REST API built with Python's http.server module.
Provides full CRUD operations on MoMo SMS transaction data.
Secured with HTTP Basic Authentication.

Usage:
    python api/api.py

Credentials:
    username: admin
    password: momo2024
"""

import json
import base64
import xml.etree.ElementTree as ET
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse
import os
import sys

# ──────────────────────────────────────────────
# 1. Configuration
# ──────────────────────────────────────────────
HOST = "localhost"
PORT = 8080

# Basic Auth credentials (in production use hashed passwords / env vars)
VALID_USERNAME = "admin"
VALID_PASSWORD = "momo2024"

XML_FILE = os.path.join(os.path.dirname(__file__), "..", "data", "modified_sms_v2.xml")

# ──────────────────────────────────────────────
# 2. Data Parsing – XML → JSON (list of dicts)
# ──────────────────────────────────────────────
def parse_xml(filepath):
    """Parse the MoMo XML file and return a list of transaction dicts."""
    transactions = []
    try:
        tree = ET.parse(filepath)
        root = tree.getroot()
        for sms in root.findall("sms"):
            transaction = {
                "id": sms.get("id"),
                "transaction_type": sms.get("transaction_type"),
                "amount": float(sms.get("amount", 0)),
                "sender": sms.get("sender"),
                "receiver": sms.get("receiver"),
                "date": sms.get("date"),
                "currency": sms.get("currency", "RWF"),
                "status": sms.get("status", "completed"),
                "body": sms.get("body"),
            }
            transactions.append(transaction)
    except FileNotFoundError:
        print(f"[ERROR] XML file not found: {filepath}")
    except ET.ParseError as e:
        print(f"[ERROR] Failed to parse XML: {e}")
    return transactions


# ──────────────────────────────────────────────
# 3. In-memory data store (list + dict for DSA)
# ──────────────────────────────────────────────
transactions_list = parse_xml(XML_FILE)          # list  – for linear search
transactions_dict = {t["id"]: t for t in transactions_list}  # dict  – O(1) lookup

next_id = max((int(t["id"]) for t in transactions_list), default=0) + 1


# ──────────────────────────────────────────────
# 4. Auth Helper
# ──────────────────────────────────────────────
def check_auth(handler):
    """Return True if the request carries valid Basic Auth credentials."""
    auth_header = handler.headers.get("Authorization", "")
    if not auth_header.startswith("Basic "):
        return False
    try:
        decoded = base64.b64decode(auth_header[6:]).decode("utf-8")
        username, password = decoded.split(":", 1)
        return username == VALID_USERNAME and password == VALID_PASSWORD
    except Exception:
        return False


# ──────────────────────────────────────────────
# 5. Request Handler
# ──────────────────────────────────────────────
class MoMoAPIHandler(BaseHTTPRequestHandler):

    def send_json(self, status, data):
        body = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_401(self):
        self.send_response(401)
        self.send_header("WWW-Authenticate", 'Basic realm="MoMo API"')
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"error": "Unauthorized. Provide valid Basic Auth credentials."}).encode())

    def read_body(self):
        length = int(self.headers.get("Content-Length", 0))
        return self.rfile.read(length).decode("utf-8") if length else ""

    def log_message(self, format, *args):
        print(f"[{self.client_address[0]}] {format % args}")

    # ── GET ──────────────────────────────────
    def do_GET(self):
        if not check_auth(self):
            return self.send_401()

        global transactions_list, transactions_dict
        parsed = urlparse(self.path)
        path_parts = [p for p in parsed.path.strip("/").split("/") if p]

        # GET /transactions
        if path_parts == ["transactions"]:
            self.send_json(200, {
                "count": len(transactions_list),
                "transactions": transactions_list
            })

        # GET /transactions/{id}
        elif len(path_parts) == 2 and path_parts[0] == "transactions":
            txn_id = path_parts[1]
            txn = transactions_dict.get(txn_id)
            if txn:
                self.send_json(200, txn)
            else:
                self.send_json(404, {"error": f"Transaction with id '{txn_id}' not found."})

        else:
            self.send_json(404, {"error": "Endpoint not found. See /docs for available routes."})

    # ── POST ─────────────────────────────────
    def do_POST(self):
        if not check_auth(self):
            return self.send_401()

        global transactions_list, transactions_dict, next_id
        parsed = urlparse(self.path)
        path_parts = [p for p in parsed.path.strip("/").split("/") if p]

        if path_parts == ["transactions"]:
            try:
                data = json.loads(self.read_body())
            except json.JSONDecodeError:
                return self.send_json(400, {"error": "Invalid JSON body."})

            required = ["transaction_type", "amount", "sender", "receiver", "date"]
            missing = [f for f in required if f not in data]
            if missing:
                return self.send_json(400, {"error": f"Missing required fields: {missing}"})

            new_txn = {
                "id": str(next_id),
                "transaction_type": data["transaction_type"],
                "amount": float(data["amount"]),
                "sender": data["sender"],
                "receiver": data["receiver"],
                "date": data["date"],
                "currency": data.get("currency", "RWF"),
                "status": data.get("status", "completed"),
                "body": data.get("body", ""),
            }
            next_id += 1
            transactions_list.append(new_txn)
            transactions_dict[new_txn["id"]] = new_txn
            self.send_json(201, {"message": "Transaction created.", "transaction": new_txn})
        else:
            self.send_json(404, {"error": "Endpoint not found."})

    # ── PUT ──────────────────────────────────
    def do_PUT(self):
        if not check_auth(self):
            return self.send_401()

        global transactions_list, transactions_dict
        parsed = urlparse(self.path)
        path_parts = [p for p in parsed.path.strip("/").split("/") if p]

        if len(path_parts) == 2 and path_parts[0] == "transactions":
            txn_id = path_parts[1]
            if txn_id not in transactions_dict:
                return self.send_json(404, {"error": f"Transaction '{txn_id}' not found."})

            try:
                data = json.loads(self.read_body())
            except json.JSONDecodeError:
                return self.send_json(400, {"error": "Invalid JSON body."})

            txn = transactions_dict[txn_id]
            updatable = ["transaction_type", "amount", "sender", "receiver", "date", "currency", "status", "body"]
            for field in updatable:
                if field in data:
                    txn[field] = float(data[field]) if field == "amount" else data[field]

            # Sync list
            for i, t in enumerate(transactions_list):
                if t["id"] == txn_id:
                    transactions_list[i] = txn
                    break

            self.send_json(200, {"message": "Transaction updated.", "transaction": txn})
        else:
            self.send_json(404, {"error": "Endpoint not found."})

    # ── DELETE ───────────────────────────────
    def do_DELETE(self):
        if not check_auth(self):
            return self.send_401()

        global transactions_list, transactions_dict
        parsed = urlparse(self.path)
        path_parts = [p for p in parsed.path.strip("/").split("/") if p]

        if len(path_parts) == 2 and path_parts[0] == "transactions":
            txn_id = path_parts[1]
            if txn_id not in transactions_dict:
                return self.send_json(404, {"error": f"Transaction '{txn_id}' not found."})

            del transactions_dict[txn_id]
            transactions_list = [t for t in transactions_list if t["id"] != txn_id]
            self.send_json(200, {"message": f"Transaction '{txn_id}' deleted successfully."})
        else:
            self.send_json(404, {"error": "Endpoint not found."})


# ──────────────────────────────────────────────
# 6. Start Server
# ──────────────────────────────────────────────
if __name__ == "__main__":
    print(f"[INFO] Loaded {len(transactions_list)} transactions from XML.")
    print(f"[INFO] Starting MoMo API at http://{HOST}:{PORT}")
    print(f"[INFO] Credentials → username: {VALID_USERNAME} | password: {VALID_PASSWORD}")
    server = HTTPServer((HOST, PORT), MoMoAPIHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[INFO] Server stopped.")
