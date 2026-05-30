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
│   └── erd_design_explanation.md
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

## DSA Benchmark

```bash
python dsa/dsa_comparison.py
```

Compares linear search O(n) vs dictionary lookup O(1) across 25 records with 100,000 repetitions per test case.

---

## Scrum Board

[View the project Scrum Board here](https://github.com/users/nshimyumurwa/projects/1/views/1)

> **Note to grader:** The Scrum board link is a public GitHub Project. If access is restricted, please visit the repository's **Projects** tab directly.
