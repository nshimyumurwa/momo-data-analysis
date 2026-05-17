# MoMo Data Analysis

## Team 2C1 - Team 8

| Name | Role |
|---|---|
| Therese Mary Nshimyumurwa | Team Lead |
| Aimable Bancunguye | Backend and Database |
| Eloi Mizero | ETL and Testing |
| Davy Dushimiyimana | Frontend and Integration |
| Clive Tanaka Mushipe | Documentation and QA |

---

## About the Project

This project processes MoMo SMS data that comes in XML format. The system parses and cleans the raw SMS messages, extracts transaction information, stores everything in a MySQL database, and then displays the results on a simple web dashboard. The main goal is to make it easier to understand how money is moving over time by looking at the transaction patterns.

---

## Repository Structure

```
.
├── README.md
├── architecture-diagram.drawio.png
├── docs/
│   └── erd_diagram.png
├── database/
│   └── database_setup.sql
├── examples/
│   └── json_schemas.json
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

---

## Database Design

### Overview

The database is built in MySQL. We designed it to be normalized so that data is not repeated unnecessarily and queries run efficiently even when the dataset gets large.

### Tables

| Table | Description |
|---|---|
| transaction_categories | Stores all the different types of MoMo transactions such as incoming transfers, merchant payments, and cash out |
| users | Stores all MoMo account holders including individuals, merchants, and agents |
| transactions | The main table that holds every transaction parsed from an SMS message |
| tags | A list of labels that can be applied to transactions for filtering and review purposes |
| transaction_tags | A junction table that links transactions to tags, since one transaction can have multiple tags and one tag can apply to many transactions |
| system_logs | Records every event that happens during the ETL pipeline so we can track errors and audit what was processed |

### Design Decisions

We separated transaction categories into their own table rather than storing the category name directly in the transactions table. This way if a category name changes we only update one row instead of thousands.

The transactions table references the users table twice, once for the sender and once for the receiver. Both are nullable because some transactions like cash in from an agent or an international remittance do not have a registered MoMo user on one side.

The many to many relationship between transactions and tags is handled through the transaction_tags junction table. This is cleaner than storing tags as a comma separated string because it allows proper filtering and integrity checking.

All money columns use DECIMAL instead of FLOAT to avoid rounding errors, which matters a lot when dealing with financial data.

### Running the Database Script

```bash
mysql -u root -p < database/database_setup.sql
```

### JSON Representations

The file at examples/json_schemas.json shows how each database entity looks when it is returned from an API. This includes individual entities like users and categories, a full nested transaction object that includes the related user, category, tags, and logs all in one response, a paginated list example, and a dashboard summary object.

---

## Architecture Diagram

See architecture-diagram.drawio.png in the root of this repository.

---

## How to Run

Clone the repository and install the dependencies:

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

Then open http://localhost:8000 in your browser.

---

## Scrum Board

https://github.com/users/nshimyumurwa/projects/1/views/1
