# ERD Keys and Cardinality Notes

Use these notes to validate the final diagram labels:

## Primary Keys
- `USERS.user_id` (PK)
- `TRANSACTION_CATEGORIES.category_id` (PK)
- `TRANSACTIONS.transaction_id` (PK)
- `SYSTEM_LOGS.log_id` (PK)
- `TRANSACTION_PARTICIPANTS` composite PK: (`transaction_id`, `user_id`, `participant_role`)

## Foreign Keys
- `TRANSACTIONS.category_id` -> `TRANSACTION_CATEGORIES.category_id`
- `TRANSACTION_PARTICIPANTS.transaction_id` -> `TRANSACTIONS.transaction_id`
- `TRANSACTION_PARTICIPANTS.user_id` -> `USERS.user_id`
- `SYSTEM_LOGS.transaction_id` -> `TRANSACTIONS.transaction_id`
- `SYSTEM_LOGS.actor_user_id` -> `USERS.user_id`

## Relationship Cardinality
- `TRANSACTION_CATEGORIES` 1:M `TRANSACTIONS`
- `TRANSACTIONS` M:N `USERS` via `TRANSACTION_PARTICIPANTS`
- `TRANSACTIONS` 1:M `SYSTEM_LOGS`
- `USERS` 1:M `SYSTEM_LOGS` (actor)
