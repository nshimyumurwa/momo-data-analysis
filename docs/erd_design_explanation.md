## ERD Design Explanation

The ERD is based on MoMo SMS transaction data and is implemented in MySQL.

TRANSACTION_CATEGORIES holds the different types of transactions like deposits, withdrawals, and transfers. One category can have many transactions (1:M with TRANSACTIONS).

USERS stores anyone involved in a transaction — sender or receiver. A single user can appear in many transactions, and each transaction links to two users through `sender_id` and `receiver_id` (both FK to USERS).

TRANSACTIONS is the main table. It holds the parsed SMS data including amount, fee, balance, status, and the original SMS body. It references TRANSACTION_CATEGORIES, and both user parties.

TAGS and TRANSACTION_TAGS allow labelling transactions. Since one transaction can have many tags and one tag can apply to many transactions, TRANSACTION_TAGS is a junction table resolving that M:N relationship.

SYSTEM_LOGS tracks ETL events and errors. Each log can optionally link to a transaction. One transaction can produce many log entries (1:M).