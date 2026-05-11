# MoMo Data Analysis

## Team 8

| Name |
|------|
| Nshimyumurwa Mary Therese |
| Aimable BANCUNGUYE |
| Mizero Eloi |

## About the Project

This project takes MoMo SMS data in XML format, processes and cleans it, stores it in a SQLite database, and displays the results on a simple web dashboard. The goal is to make it easy to understand transaction patterns over time.

## Architecture Diagram

[View here](#) ← replace with your link

## Project Structure

```
.
├── README.md
├── .env.example
├── requirements.txt
├── index.html
├── web/
│   ├── styles.css
│   ├── chart_handler.js
│   └── assets/
├── data/
│   ├── raw/
│   │   └── momo.xml
│   ├── processed/
│   │   └── dashboard.json
│   ├── db.sqlite3
│   └── logs/
│       ├── etl.log
│       └── dead_letter/
├── etl/
│   ├── config.py
│   ├── parse_xml.py
│   ├── clean_normalize.py
│   ├── categorize.py
│   ├── load_db.py
│   └── run.py
├── scripts/
│   ├── run_etl.sh
│   ├── export_json.sh
│   └── serve_frontend.sh
└── tests/
    ├── test_parse_xml.py
    ├── test_clean_normalize.py
    └── test_categorize.py
```

## How to Run

Clone the repo and install dependencies:

```bash
git clone https://github.com/nshimyumurwa/momo-data-analysis.git
cd momo-data-analysis
pip install -r requirements.txt
```

Run the ETL pipeline:

```bash
bash scripts/run_etl.sh
```

Start the frontend:

```bash
bash scripts/serve_frontend.sh
```

Then open `http://localhost:8000` in your browser.

## Scrum Board

[View here](#) ← replace with your link
