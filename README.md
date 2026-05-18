# MoMo Data Analysis

## Team 2

| Name | Role |
|---|---|
| Therese Mary Nshimyumurwa | Team Lead |
| Aimable Bancunguye | Backend and Database |
| Eloi Mizero | ETL and Testing |
| Davy Dushimiyimana | Frontend and Integration |
| Clive Tanaka Mushipe | Documentation and QA |

---

## What this project does

This project takes MoMo SMS messages that are stored in XML format, reads through them, pulls out the transaction details, saves everything into a database, and shows the results on a simple web dashboard. The idea is to make it easy to see what kinds of transactions are happening and how much money is moving around.

---

## ERD Diagram

- ERD Diagram (PDF): [docs/ERD Diagram.drawio.pdf](docs/ERD%20Diagram.drawio.pdf)
- ERD Design Explanation: [docs/erd_design_explanation.md](docs/erd_design_explanation.md)

## Folder structure

```
.
├── README.md
├── docs/
│   ├── ERD Diagram.drawio.pdf
│   └── erd_design_explanation.md
├── database/
│   └── database_setup.sql
├── examples/
│   └── json_schemas.json
├── data/
│   ├── raw/
│   │   └── momo.xml
│   ├── processed/
│   │   └── dashboard.json
│   └── logs/
├── etl/
│   ├── parse_xml.py
│   ├── clean_normalize.py
│   ├── categorize.py
│   ├── load_db.py
│   └── run.py
├── scripts/
│   ├── run_etl.sh
│   └── serve_frontend.sh
└── tests/
    ├── test_parse_xml.py
    └── test_categorize.py
```

---

## Database design

We used MySQL to build the database. There are six tables in total.

| Table | What it stores |
|---|---|
| transaction_categories | The different types of MoMo transactions, for example sending money or paying a merchant |
| users | Everyone who uses MoMo including individuals, merchants, and agents |
| transactions | Every single transaction that was read from an SMS message |
| tags | Short labels that can be attached to transactions like flagged or reconciled |
| transaction_tags | Connects transactions to tags since one transaction can have more than one tag |
| system_logs | A record of everything that happens when the system is processing data |

### Why we designed it this way

We kept transaction categories in a separate table so we do not repeat the same category name in thousands of rows. If a category name ever changes, we only update it in one place.

The transactions table links to the users table twice, once for the sender and once for the receiver. Both can be empty because sometimes the other party is not a registered MoMo user, for example when receiving money from abroad.

The transaction_tags table exists because one transaction can have many tags and one tag can be used on many transactions. This is called a many-to-many relationship and the transaction_tags table is how we handle it properly.

We used DECIMAL for all money columns instead of FLOAT because FLOAT causes small rounding errors which is a big problem when dealing with financial data.

### How to run the database script

```bash
mysql -u root -p < database/database_setup.sql
```

---

## How to run the project

```bash
git clone https://github.com/nshimyumurwa/momo-data-analysis.git
cd momo-data-analysis
pip install -r requirements.txt
mysql -u root -p < database/database_setup.sql # To Initialize the Database
bash scripts/run_etl.sh
bash scripts/serve_frontend.sh
```

Then open http://localhost:8000 in your browser.

---

## Scrum board

https://github.com/users/nshimyumurwa/projects/1/views/1

---

## AI usage

We used Claude to check the grammar in our documentation and to verify some SQL syntax.
