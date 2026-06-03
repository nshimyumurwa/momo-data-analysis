# MoMo SMS REST API

**Team 2** | ALU – Building and Securing a REST API Assignment

| Name | Role |
|------|------|
| Nshimyumurwa Mary Therese | Team Lead / API Development |
| Aimable Bancunguye | DSA & Data Parsing |
| Davy Dushimiyimana | Frontend and Integration |
| Eloi Mizero | Documentation & API Docs |
| Clive Mushipe | Data Parsing & XML Processing |

---

## Project Overview

A secure REST API that exposes MoMo SMS transaction data. Built with Python's built-in `http.server` module — no external web framework required. The API parses an XML dataset of mobile money transactions, stores them in memory, and exposes full CRUD operations protected by HTTP Basic Authentication.

---

## Repository Structure

```
momo-data-analysis/
├── api/
│   └── api.py                  # REST API server (CRUD + Basic Auth)
├── dsa/
│   └── dsa_comparison.py       # Linear search vs dictionary lookup benchmark
├── data/
│   ├── modified_sms_v2.xml     # MoMo SMS dataset
│   └── generate_sample_xml.py  # Script to regenerate sample data
├── docs/
│   └── api_docs.md             # Full API documentation
├── screenshots/                # Test evidence (curl screenshots)
└── README.md
```

---

## Prerequisites

- Python 3.9 or higher (no external packages required)
- `curl` or Postman for testing

---

## Setup & Running

### 1. Clone the repository
```bash
git clone https://github.com/nshimyumurwa/momo-data-analysis.git
cd momo-data-analysis
```

### 2. (Optional) Regenerate sample XML data
```bash
python data/generate_sample_xml.py
```

### 3. Start the API server
```bash
python api/api.py
```

The server starts at `http://localhost:8080`.

---

## Credentials

| Field    | Value     |
|----------|-----------|
| Username | `admin`   |
| Password | `momo2024`|

---

## Quick API Test

```bash
# List all transactions
curl -u admin:momo2024 http://localhost:8080/transactions

# Get one transaction
curl -u admin:momo2024 http://localhost:8080/transactions/1

# Create a transaction
curl -u admin:momo2024 -X POST http://localhost:8080/transactions \
  -H "Content-Type: application/json" \
  -d '{"transaction_type":"transfer","amount":5000,"sender":"0789876543","receiver":"0781111111","date":"2024-02-01 10:00:00"}'

# Update a transaction
curl -u admin:momo2024 -X PUT http://localhost:8080/transactions/1 \
  -H "Content-Type: application/json" \
  -d '{"status":"reviewed","amount":5500}'

# Delete a transaction
curl -u admin:momo2024 -X DELETE http://localhost:8080/transactions/1

# Test unauthorized access (should return 401)
curl http://localhost:8080/transactions
```

---

## DSA Benchmark

```bash
python dsa/dsa_comparison.py
```

Compares linear search O(n) vs dictionary lookup O(1) across 25 records with 100,000 repetitions per test case.

---

## API Documentation

See [`docs/api_docs.md`](docs/api_docs.md) for full endpoint reference including request/response examples and security discussion.

---

## Scrum Board

[View the project Scrum Board here](https://github.com/users/nshimyumurwa/projects/1/views/1)

