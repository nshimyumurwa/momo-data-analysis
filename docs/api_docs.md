# MoMo SMS API Documentation

**Base URL:** `http://localhost:8080`  
**Authentication:** HTTP Basic Auth (`username: admin`, `password: momo2024`)  
**Content-Type:** `application/json`

---

## Authentication

All endpoints require HTTP Basic Authentication. Requests without valid credentials receive a `401 Unauthorized` response.

### How to include credentials

**curl:**
```bash
curl -u admin:momo2024 http://localhost:8080/transactions
```

**Authorization header (manual):**
```
Authorization: Basic YWRtaW46bW9tbzIwMjQ=
```
The value is `Base64("admin:momo2024")`.

---

## Endpoints

### 1. List All Transactions

| Field  | Value |
|--------|-------|
| Method | `GET` |
| URL    | `/transactions` |
| Auth   | Required |

**Request:**
```bash
curl -u admin:momo2024 http://localhost:8080/transactions
```

**Success Response – 200 OK:**
```json
{
  "count": 25,
  "transactions": [
    {
      "id": "1",
      "transaction_type": "incoming_money",
      "amount": 5000.0,
      "sender": "0781234567",
      "receiver": "0789876543",
      "date": "2024-01-03 08:12:00",
      "currency": "RWF",
      "status": "completed",
      "body": "You have received 5000 RWF from Alice..."
    }
  ]
}
```

---

### 2. Get Single Transaction

| Field  | Value |
|--------|-------|
| Method | `GET` |
| URL    | `/transactions/{id}` |
| Auth   | Required |

**Request:**
```bash
curl -u admin:momo2024 http://localhost:8080/transactions/1
```

**Success Response – 200 OK:**
```json
{
  "id": "1",
  "transaction_type": "incoming_money",
  "amount": 5000.0,
  "sender": "0781234567",
  "receiver": "0789876543",
  "date": "2024-01-03 08:12:00",
  "currency": "RWF",
  "status": "completed",
  "body": "You have received 5000 RWF from Alice (0781234567). Your new balance is 15000 RWF. TxnId: TXN001"
}
```

**Error Response – 404 Not Found:**
```json
{
  "error": "Transaction with id '99' not found."
}
```

---

### 3. Create Transaction

| Field  | Value |
|--------|-------|
| Method | `POST` |
| URL    | `/transactions` |
| Auth   | Required |
| Body   | JSON |

**Required fields:** `transaction_type`, `amount`, `sender`, `receiver`, `date`

**Request:**
```bash
curl -u admin:momo2024 \
  -X POST http://localhost:8080/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_type": "transfer",
    "amount": 5000,
    "sender": "0789876543",
    "receiver": "0781111111",
    "date": "2024-02-01 10:00:00",
    "currency": "RWF",
    "status": "completed",
    "body": "You have transferred 5000 RWF to John."
  }'
```

**Success Response – 201 Created:**
```json
{
  "message": "Transaction created.",
  "transaction": {
    "id": "26",
    "transaction_type": "transfer",
    "amount": 5000.0,
    "sender": "0789876543",
    "receiver": "0781111111",
    "date": "2024-02-01 10:00:00",
    "currency": "RWF",
    "status": "completed",
    "body": "You have transferred 5000 RWF to John."
  }
}
```

**Error Response – 400 Bad Request (missing fields):**
```json
{
  "error": "Missing required fields: ['amount', 'date']"
}
```

---

### 4. Update Transaction

| Field  | Value |
|--------|-------|
| Method | `PUT` |
| URL    | `/transactions/{id}` |
| Auth   | Required |
| Body   | JSON (partial updates allowed) |

**Request:**
```bash
curl -u admin:momo2024 \
  -X PUT http://localhost:8080/transactions/1 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "reviewed",
    "amount": 5500
  }'
```

**Success Response – 200 OK:**
```json
{
  "message": "Transaction updated.",
  "transaction": {
    "id": "1",
    "transaction_type": "incoming_money",
    "amount": 5500.0,
    "sender": "0781234567",
    "receiver": "0789876543",
    "date": "2024-01-03 08:12:00",
    "currency": "RWF",
    "status": "reviewed",
    "body": "You have received 5000 RWF from Alice..."
  }
}
```

**Error Response – 404 Not Found:**
```json
{
  "error": "Transaction '99' not found."
}
```

---

### 5. Delete Transaction

| Field  | Value |
|--------|-------|
| Method | `DELETE` |
| URL    | `/transactions/{id}` |
| Auth   | Required |

**Request:**
```bash
curl -u admin:momo2024 -X DELETE http://localhost:8080/transactions/1
```

**Success Response – 200 OK:**
```json
{
  "message": "Transaction '1' deleted successfully."
}
```

**Error Response – 404 Not Found:**
```json
{
  "error": "Transaction '1' not found."
}
```

---

## Error Code Reference

| HTTP Status | Meaning | When It Occurs |
|-------------|---------|----------------|
| `200 OK` | Success | GET, PUT, DELETE succeeded |
| `201 Created` | Resource created | POST succeeded |
| `400 Bad Request` | Invalid request | Missing fields or malformed JSON |
| `401 Unauthorized` | Auth failed | Missing or wrong credentials |
| `404 Not Found` | Resource missing | Unknown endpoint or transaction ID |

---

## Security: Why Basic Auth is Weak

### Limitations of Basic Authentication

1. **Credentials sent on every request.** Every API call transmits the username and password (Base64-encoded, *not* encrypted). If HTTPS is not enforced, credentials travel in plain text over the network.

2. **No token expiry.** There is no concept of a session or timeout. A stolen credential remains valid until the password is manually changed.

3. **No fine-grained access control.** Basic Auth is binary — a user either has access or they don't. There is no way to give read-only access to one client and write access to another.

4. **No audit trail.** It is difficult to track which client performed which action since every request uses the same static credential.

### Stronger Alternatives

#### JSON Web Tokens (JWT)
- The client logs in once and receives a **signed token** valid for a limited time (e.g., 1 hour).
- Subsequent requests carry the token in the `Authorization: Bearer <token>` header — no password transmitted again.
- Tokens can carry **claims** (user ID, roles) and expire automatically.
- Implementation libraries: `PyJWT` (Python), `jsonwebtoken` (Node.js).

#### OAuth 2.0
- Industry-standard protocol for **delegated authorization**.
- Supports scopes (read-only, write, admin), refresh tokens, and multiple grant flows.
- Used by Google, GitHub, and MTN for third-party API access.
- Ideal when external apps need access to the MoMo API on behalf of a user.

#### API Keys with HTTPS
- A stepping stone above Basic Auth: a long random key per client, stored server-side and rotated periodically.
- Must always be used over HTTPS (TLS) to prevent interception.

**Recommendation:** Migrate to JWT for internal apps and OAuth 2.0 for any third-party integrations, with all traffic over HTTPS/TLS.
