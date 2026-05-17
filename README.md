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

[View here](https://github.com/nshimyumurwa/momo-data-analysis/blob/main/architecture-diagram.drawio.png)

## Week 2: Database Design Deliverables

- ERD Diagram (PDF): [docs/erd_diagram.pdf](docs/erd_diagram.pdf)
- ERD Design Rationale: [docs/erd_design_rationale.md](docs/erd_design_rationale.md)
- ERD Keys and Cardinality Notes: [docs/erd_cardinality_and_keys.md](docs/erd_cardinality_and_keys.md)

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


## Additional Notes

This project was collaboratively developed using GitHub workflow practices including commits, branching, testing, and task management through a Scrum board.

## Scrum Board

[View here](https://github.com/users/nshimyumurwa/projects/1/views/1)
