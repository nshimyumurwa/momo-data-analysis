-- ============================================================
-- MoMo SMS Data Processing System
-- Database Setup Script
-- Team 2C1 Team 8: Therese Mary Nshimyumurwa, Aimable Bancunguye, Eloi Mizero, Davy Dushimiyimana, Clive Tanaka Mushipe
-- Week 2 Assignment
-- ============================================================

-- Create and select the database
CREATE DATABASE IF NOT EXISTS momo_sms_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE momo_sms_db;

-- ============================================================
-- TABLE: transaction_categories
-- Lookup table for MoMo transaction types
-- ============================================================
CREATE TABLE IF NOT EXISTS transaction_categories (
    category_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique category identifier',
    category_code    VARCHAR(50)  NOT NULL UNIQUE           COMMENT 'Short machine-readable code (e.g. INCOMING_TRANSFER)',
    category_name    VARCHAR(100) NOT NULL                  COMMENT 'Human-readable category label',
    direction        ENUM('CREDIT','DEBIT','NEUTRAL') NOT NULL COMMENT 'Whether this category credits or debits the wallet',
    description      TEXT                                   COMMENT 'Detailed description of the category',
    is_active        TINYINT(1)   NOT NULL DEFAULT 1        COMMENT '1 = active, 0 = deprecated',
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',

    INDEX idx_category_code (category_code),
    INDEX idx_direction     (direction)
) ENGINE=InnoDB COMMENT='Lookup table for all supported MoMo transaction categories';


-- ============================================================
-- TABLE: users
-- Stores MoMo customers (senders and receivers)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    user_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique user identifier',
    phone_number     VARCHAR(20)  NOT NULL UNIQUE           COMMENT 'MSISDN in E.164 format e.g. +250788000001',
    full_name        VARCHAR(150)                           COMMENT 'Full name as registered with MoMo',
    account_type     ENUM('INDIVIDUAL','MERCHANT','AGENT') NOT NULL DEFAULT 'INDIVIDUAL' COMMENT 'Type of MoMo account',
    is_verified      TINYINT(1)   NOT NULL DEFAULT 0        COMMENT '1 = KYC verified, 0 = unverified',
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Account registration timestamp',
    updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last profile update',

    CONSTRAINT chk_phone_format CHECK (phone_number REGEXP '^\\+[1-9][0-9]{7,14}$'),

    INDEX idx_phone_number  (phone_number),
    INDEX idx_account_type  (account_type)
) ENGINE=InnoDB COMMENT='MoMo registered users – both senders and receivers';


-- ============================================================
-- TABLE: transactions
-- Core table storing every processed MoMo SMS transaction
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate primary key',
    external_ref     VARCHAR(100) NOT NULL UNIQUE           COMMENT 'Original transaction ID from MoMo SMS (e.g. TxnID from XML)',
    category_id      INT UNSIGNED NOT NULL                  COMMENT 'FK → transaction_categories',
    sender_id        INT UNSIGNED                           COMMENT 'FK → users (NULL for incoming from external)',
    receiver_id      INT UNSIGNED                           COMMENT 'FK → users (NULL for outgoing to external)',
    amount           DECIMAL(15,2) NOT NULL                 COMMENT 'Transaction amount in RWF',
    fee              DECIMAL(10,2) NOT NULL DEFAULT 0.00    COMMENT 'Transaction fee charged in RWF',
    balance_after    DECIMAL(15,2)                          COMMENT 'Wallet balance after transaction (from SMS)',
    currency         CHAR(3)      NOT NULL DEFAULT 'RWF'    COMMENT 'ISO 4217 currency code',
    transaction_date DATETIME     NOT NULL                  COMMENT 'Timestamp when transaction occurred',
    sms_raw_body     TEXT                                   COMMENT 'Original SMS text before parsing',
    status           ENUM('SUCCESS','FAILED','PENDING','REVERSED') NOT NULL DEFAULT 'SUCCESS' COMMENT 'Processing outcome',
    parsed_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when SMS was parsed',
    notes            VARCHAR(500)                           COMMENT 'Optional human notes or flags',

    CONSTRAINT chk_amount_positive    CHECK (amount    >= 0),
    CONSTRAINT chk_fee_non_negative   CHECK (fee       >= 0),
    CONSTRAINT chk_balance_positive   CHECK (balance_after IS NULL OR balance_after >= 0),

    FOREIGN KEY fk_txn_category (category_id)
        REFERENCES transaction_categories(category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    FOREIGN KEY fk_txn_sender (sender_id)
        REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE SET NULL,

    FOREIGN KEY fk_txn_receiver (receiver_id)
        REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE SET NULL,

    INDEX idx_external_ref      (external_ref),
    INDEX idx_transaction_date  (transaction_date),
    INDEX idx_status            (status),
    INDEX idx_sender_id         (sender_id),
    INDEX idx_receiver_id       (receiver_id),
    INDEX idx_category_id       (category_id)
) ENGINE=InnoDB COMMENT='Main fact table for all MoMo transactions parsed from SMS';


-- ============================================================
-- TABLE: transaction_tags  (junction / M:N resolution)
-- Allows multiple descriptive tags per transaction
-- ============================================================
CREATE TABLE IF NOT EXISTS tags (
    tag_id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique tag identifier',
    tag_name         VARCHAR(80)  NOT NULL UNIQUE           COMMENT 'Tag label (e.g. "flagged","reconciled","duplicate")',
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Tag creation timestamp'
) ENGINE=InnoDB COMMENT='Taxonomy of labels that can be applied to transactions';

CREATE TABLE IF NOT EXISTS transaction_tags (
    transaction_id   INT UNSIGNED NOT NULL COMMENT 'FK → transactions',
    tag_id           INT UNSIGNED NOT NULL COMMENT 'FK → tags',
    tagged_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the tag was applied',
    tagged_by        VARCHAR(100)           COMMENT 'System or user that applied the tag',

    PRIMARY KEY (transaction_id, tag_id),

    FOREIGN KEY fk_tt_transaction (transaction_id)
        REFERENCES transactions(transaction_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    FOREIGN KEY fk_tt_tag (tag_id)
        REFERENCES tags(tag_id)
        ON UPDATE CASCADE ON DELETE CASCADE,

    INDEX idx_tag_id (tag_id)
) ENGINE=InnoDB COMMENT='Junction table resolving M:N between transactions and tags';


-- ============================================================
-- TABLE: system_logs
-- Tracks every ETL pipeline event for auditing & debugging
-- ============================================================
CREATE TABLE IF NOT EXISTS system_logs (
    log_id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique log entry ID',
    log_level        ENUM('DEBUG','INFO','WARNING','ERROR','CRITICAL') NOT NULL DEFAULT 'INFO' COMMENT 'Severity level',
    event_type       VARCHAR(100) NOT NULL                  COMMENT 'Short event code (e.g. PARSE_SUCCESS, DB_INSERT_FAIL)',
    transaction_id   INT UNSIGNED                           COMMENT 'FK → transactions if log is tied to a specific txn',
    message          TEXT         NOT NULL                  COMMENT 'Full log message',
    source_file      VARCHAR(200)                           COMMENT 'ETL script that emitted the log',
    ip_address       VARCHAR(45)                            COMMENT 'Server IP (IPv4 or IPv6)',
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the log was emitted',

    FOREIGN KEY fk_log_transaction (transaction_id)
        REFERENCES transactions(transaction_id)
        ON UPDATE CASCADE ON DELETE SET NULL,

    INDEX idx_log_level     (log_level),
    INDEX idx_event_type    (event_type),
    INDEX idx_log_created   (created_at),
    INDEX idx_log_txn       (transaction_id)
) ENGINE=InnoDB COMMENT='Audit log for all ETL pipeline events';


-- ============================================================
-- SAMPLE DATA – Transaction Categories
-- ============================================================
INSERT INTO transaction_categories
    (category_code, category_name, direction, description)
VALUES
    ('INCOMING_TRANSFER',  'Incoming Money Transfer',     'CREDIT',  'Money received from another MoMo user'),
    ('OUTGOING_TRANSFER',  'Outgoing Money Transfer',     'DEBIT',   'Money sent to another MoMo user'),
    ('PAYMENT_MERCHANT',   'Merchant Payment',            'DEBIT',   'Payment made to a registered MoMo merchant'),
    ('AIRTIME_PURCHASE',   'Airtime Top-Up',              'DEBIT',   'Purchase of mobile airtime via MoMo'),
    ('BANK_DEPOSIT',       'Bank to MoMo Deposit',        'CREDIT',  'Deposit from linked bank account'),
    ('CASH_IN',            'Cash In via Agent',           'CREDIT',  'Physical cash deposited through MoMo agent'),
    ('CASH_OUT',           'Cash Out via Agent',          'DEBIT',   'Physical cash withdrawn through MoMo agent'),
    ('UTILITY_PAYMENT',    'Utility Bill Payment',        'DEBIT',   'Payment for electricity, water, or internet'),
    ('INTERNATIONAL_IN',   'International Remittance In', 'CREDIT',  'Money received from abroad'),
    ('REVERSAL',           'Transaction Reversal',        'NEUTRAL', 'Reversal or refund of a prior transaction');


-- ============================================================
-- SAMPLE DATA – Users
-- ============================================================
INSERT INTO users
    (phone_number, full_name, account_type, is_verified)
VALUES
    ('+250788100001', 'Therese Mary Nshimyumurwa', 'INDIVIDUAL', 1),
    ('+250788100002', 'Aimable Bancunguye',         'INDIVIDUAL', 1),
    ('+250788100003', 'Eloi Mizero',                'INDIVIDUAL', 1),
    ('+250788100006', 'Davy Dushimiyimana',         'INDIVIDUAL', 1),
    ('+250788100007', 'Clive Tanaka Mushipe',        'INDIVIDUAL', 1),
    ('+250788200001', 'Kigali Mart Ltd',            'MERCHANT',   1),
    ('+250788300001', 'Jean Claude Habimana',       'AGENT',      1),
    ('+250788100004', 'Alice Mukamana',             'INDIVIDUAL', 0),
    ('+250788100005', 'Patrick Nkurunziza',         'INDIVIDUAL', 0);


-- ============================================================
-- SAMPLE DATA – Transactions
-- ============================================================
INSERT INTO transactions
    (external_ref, category_id, sender_id, receiver_id,
     amount, fee, balance_after, currency, transaction_date, status,
     sms_raw_body)
VALUES
    ('TXN20250501001', 1, 2, 1,  50000.00, 0.00,    150000.00, 'RWF', '2025-05-01 08:15:00', 'SUCCESS',
     'You have received 50,000 RWF from Aimable Bancunguye (+250788100002). Your new balance: 150,000 RWF. TxnID:TXN20250501001'),
    ('TXN20250502001', 2, 1, 4,  20000.00, 100.00,  129900.00, 'RWF', '2025-05-02 10:30:00', 'SUCCESS',
     'Your payment of 20,000 RWF to Kigali Mart Ltd was successful. Fee: 100 RWF. Balance: 129,900 RWF. TxnID:TXN20250502001'),
    ('TXN20250503001', 4, 1, NULL, 5000.00, 0.00,   124900.00, 'RWF', '2025-05-03 12:00:00', 'SUCCESS',
     'Airtime purchase of 5,000 RWF successful. Balance: 124,900 RWF. TxnID:TXN20250503001'),
    ('TXN20250504001', 6, NULL, 3, 100000.00, 0.00, 200000.00, 'RWF', '2025-05-04 09:00:00', 'SUCCESS',
     'Cash In: 100,000 RWF deposited by agent Jean Claude Habimana. Balance: 200,000 RWF. TxnID:TXN20250504001'),
    ('TXN20250505001', 7, 2, NULL, 30000.00, 200.00,169800.00, 'RWF', '2025-05-05 14:20:00', 'SUCCESS',
     'Cash Out: 30,000 RWF withdrawn. Fee: 200 RWF. Balance: 169,800 RWF. TxnID:TXN20250505001'),
    ('TXN20250506001', 8, 1, NULL, 15000.00, 0.00,  109900.00, 'RWF', '2025-05-06 07:45:00', 'SUCCESS',
     'Utility payment of 15,000 RWF processed. Balance: 109,900 RWF. TxnID:TXN20250506001'),
    ('TXN20250507001', 9, NULL, 3, 250000.00,0.00,  450000.00, 'RWF', '2025-05-07 11:00:00', 'SUCCESS',
     'International remittance of 250,000 RWF received. Balance: 450,000 RWF. TxnID:TXN20250507001'),
    ('TXN20250508001', 2, 3, 6,  10000.00, 100.00,  439900.00,'RWF', '2025-05-08 16:10:00', 'FAILED',
     'Transfer of 10,000 RWF to Alice Mukamana FAILED. TxnID:TXN20250508001');


-- ============================================================
-- SAMPLE DATA – Tags
-- ============================================================
INSERT INTO tags (tag_name) VALUES
    ('flagged'),
    ('reconciled'),
    ('high_value'),
    ('duplicate_check'),
    ('international');


-- ============================================================
-- SAMPLE DATA – Transaction Tags (M:N junction)
-- ============================================================
INSERT INTO transaction_tags (transaction_id, tag_id, tagged_by) VALUES
    (7, 3, 'etl_pipeline'),   -- international remittance is high_value
    (7, 5, 'etl_pipeline'),   -- international remittance tagged international
    (8, 1, 'etl_pipeline'),   -- failed transfer flagged
    (1, 2, 'etl_pipeline'),   -- successful transfer reconciled
    (4, 3, 'etl_pipeline');   -- large cash-in is high_value


-- ============================================================
-- SAMPLE DATA – System Logs
-- ============================================================
INSERT INTO system_logs
    (log_level, event_type, transaction_id, message, source_file, ip_address)
VALUES
    ('INFO',    'PARSE_SUCCESS',    1, 'SMS parsed successfully for TXN20250501001',          'etl/parse_xml.py',       '10.0.0.1'),
    ('INFO',    'DB_INSERT_OK',     1, 'Transaction TXN20250501001 inserted into DB',         'etl/load_db.py',         '10.0.0.1'),
    ('INFO',    'PARSE_SUCCESS',    2, 'SMS parsed successfully for TXN20250502001',          'etl/parse_xml.py',       '10.0.0.1'),
    ('ERROR',   'DB_INSERT_FAIL',   8, 'Foreign key violation: receiver_id 6 is unverified', 'etl/load_db.py',         '10.0.0.1'),
    ('WARNING', 'AMOUNT_ANOMALY',   7, 'Amount 250000 exceeds high-value threshold of 200000','etl/clean_normalize.py', '10.0.0.1'),
    ('INFO',    'ETL_RUN_COMPLETE', NULL, 'ETL pipeline run completed. 8 records processed, 1 failed.', 'etl/run.py', '10.0.0.1');


-- ============================================================
-- BASIC CRUD VERIFICATION QUERIES
-- ============================================================

-- 1. READ: All transactions with category and user info
SELECT
    t.transaction_id,
    t.external_ref,
    tc.category_name,
    u_s.full_name  AS sender,
    u_r.full_name  AS receiver,
    t.amount,
    t.fee,
    t.balance_after,
    t.status,
    t.transaction_date
FROM transactions t
JOIN  transaction_categories tc ON t.category_id  = tc.category_id
LEFT JOIN users u_s              ON t.sender_id    = u_s.user_id
LEFT JOIN users u_r              ON t.receiver_id  = u_r.user_id
ORDER BY t.transaction_date DESC;

-- 2. READ: Total credits and debits per category
SELECT
    tc.category_name,
    tc.direction,
    COUNT(t.transaction_id)       AS txn_count,
    SUM(t.amount)                 AS total_amount,
    AVG(t.fee)                    AS avg_fee
FROM transactions t
JOIN transaction_categories tc ON t.category_id = tc.category_id
WHERE t.status = 'SUCCESS'
GROUP BY tc.category_id, tc.category_name, tc.direction
ORDER BY total_amount DESC;

-- 3. READ: High-value flagged transactions
SELECT
    t.external_ref,
    t.amount,
    t.transaction_date,
    GROUP_CONCAT(tg.tag_name ORDER BY tg.tag_name SEPARATOR ', ') AS tags
FROM transactions t
JOIN transaction_tags tt ON t.transaction_id = tt.transaction_id
JOIN tags tg             ON tt.tag_id        = tg.tag_id
GROUP BY t.transaction_id, t.external_ref, t.amount, t.transaction_date;

-- 4. READ: System error summary
SELECT
    log_level,
    event_type,
    COUNT(*) AS occurrences,
    MAX(created_at) AS last_seen
FROM system_logs
GROUP BY log_level, event_type
ORDER BY log_level, occurrences DESC;

-- 5. UPDATE: Mark a transaction as reconciled (add tag)
-- (already done via INSERT into transaction_tags; shown here for demo)
UPDATE transactions
SET notes = 'Manually reviewed and confirmed'
WHERE external_ref = 'TXN20250507001';

-- 6. DELETE: Remove a stale test log entry (safe – uses surrogate key)
-- DELETE FROM system_logs WHERE log_id = 999; -- (placeholder for demo)


-- ============================================================
-- UNIQUE / SECURITY CONSTRAINTS (additional)
-- ============================================================

-- Prevent duplicate SMS processing
ALTER TABLE transactions
    ADD CONSTRAINT uq_external_ref UNIQUE (external_ref);          -- already declared above; shown for clarity

-- Prevent the same tag being applied twice to the same transaction
-- (already enforced by the composite PRIMARY KEY on transaction_tags)

-- Enforce that merchant and agent phone numbers differ from individual ranges
-- (handled by account_type ENUM + application layer; shown as a view guard below)
CREATE OR REPLACE VIEW v_verified_merchants AS
    SELECT user_id, phone_number, full_name
    FROM users
    WHERE account_type = 'MERCHANT'
      AND is_verified = 1;

-- View: daily transaction summary for dashboard
CREATE OR REPLACE VIEW v_daily_summary AS
    SELECT
        DATE(transaction_date)           AS txn_date,
        tc.direction,
        COUNT(*)                         AS txn_count,
        SUM(amount)                      AS total_volume,
        SUM(fee)                         AS total_fees
    FROM transactions t
    JOIN transaction_categories tc ON t.category_id = tc.category_id
    WHERE t.status = 'SUCCESS'
    GROUP BY DATE(transaction_date), tc.direction;

-- ============================================================
-- END OF SCRIPT
-- ============================================================
