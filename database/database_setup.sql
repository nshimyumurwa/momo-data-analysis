-- MoMo SMS Data Processing System
-- Database setup script
-- Team 2
-- Members: Therese Mary Nshimyumurwa, Aimable Bancunguye, Eloi Mizero, Davy Dushimiyimana, Clive Tanaka Mushipe

CREATE DATABASE IF NOT EXISTS momo_sms_db;
USE momo_sms_db;


-- This table stores the different types of transactions that MoMo supports
-- For example: sending money, paying a merchant, buying airtime
CREATE TABLE IF NOT EXISTS transaction_categories (
    category_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_code  VARCHAR(50)  NOT NULL UNIQUE,
    category_name  VARCHAR(100) NOT NULL,
    direction      ENUM('CREDIT','DEBIT','NEUTRAL') NOT NULL,
    description    TEXT,
    is_active      TINYINT(1)   NOT NULL DEFAULT 1,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_category_code (category_code)
) ENGINE=InnoDB;


-- This table stores everyone who uses MoMo
-- A user can be a regular person, a shop (merchant), or an agent
CREATE TABLE IF NOT EXISTS users (
    user_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    phone_number   VARCHAR(20)  NOT NULL UNIQUE,
    full_name      VARCHAR(150),
    account_type   ENUM('INDIVIDUAL','MERCHANT','AGENT') NOT NULL DEFAULT 'INDIVIDUAL',
    is_verified    TINYINT(1)   NOT NULL DEFAULT 0,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_phone CHECK (phone_number REGEXP '^\\+[1-9][0-9]{7,14}$'),
    INDEX idx_phone (phone_number)
) ENGINE=InnoDB;


-- This is the main table that stores every transaction parsed from an SMS
-- sender_id and receiver_id can be NULL when the other party is not a registered MoMo user
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    external_ref     VARCHAR(100)  NOT NULL UNIQUE,
    category_id      INT UNSIGNED  NOT NULL,
    sender_id        INT UNSIGNED,
    receiver_id      INT UNSIGNED,
    amount           DECIMAL(15,2) NOT NULL,
    fee              DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    balance_after    DECIMAL(15,2),
    currency         CHAR(3)       NOT NULL DEFAULT 'RWF',
    transaction_date DATETIME      NOT NULL,
    sms_raw_body     TEXT,
    status           ENUM('SUCCESS','FAILED','PENDING','REVERSED') NOT NULL DEFAULT 'SUCCESS',
    parsed_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes            VARCHAR(500),

    -- make sure amounts are never negative
    CONSTRAINT chk_amount  CHECK (amount >= 0),
    CONSTRAINT chk_fee     CHECK (fee >= 0),
    CONSTRAINT chk_balance CHECK (balance_after IS NULL OR balance_after >= 0),

    FOREIGN KEY (category_id)  REFERENCES transaction_categories(category_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (sender_id)    REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (receiver_id)  REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL,

    INDEX idx_date      (transaction_date),
    INDEX idx_status    (status),
    INDEX idx_sender    (sender_id),
    INDEX idx_receiver  (receiver_id),
    INDEX idx_category  (category_id)
) ENGINE=InnoDB;


-- Tags are short labels we can attach to transactions, like "flagged" or "reconciled"
CREATE TABLE IF NOT EXISTS tags (
    tag_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tag_name   VARCHAR(80) NOT NULL UNIQUE,
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- This table connects transactions to tags
-- One transaction can have many tags and one tag can be used on many transactions
-- This is how we handle the many-to-many relationship
CREATE TABLE IF NOT EXISTS transaction_tags (
    transaction_id INT UNSIGNED NOT NULL,
    tag_id         INT UNSIGNED NOT NULL,
    tagged_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tagged_by      VARCHAR(100),

    PRIMARY KEY (transaction_id, tag_id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id)         REFERENCES tags(tag_id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- This table keeps a record of everything that happens during the data processing pipeline
-- It helps us find errors and keep track of what was processed
CREATE TABLE IF NOT EXISTS system_logs (
    log_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    log_level      ENUM('DEBUG','INFO','WARNING','ERROR','CRITICAL') NOT NULL DEFAULT 'INFO',
    event_type     VARCHAR(100) NOT NULL,
    transaction_id INT UNSIGNED,
    message        TEXT NOT NULL,
    source_file    VARCHAR(200),
    ip_address     VARCHAR(45),
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL,
    INDEX idx_level   (log_level),
    INDEX idx_created (created_at)
) ENGINE=InnoDB;


-- -------------------------------------------------------
-- Sample data for transaction categories
-- -------------------------------------------------------
INSERT INTO transaction_categories (category_code, category_name, direction, description) VALUES
    ('INCOMING_TRANSFER', 'Incoming Money Transfer',     'CREDIT',  'Money received from another MoMo user'),
    ('OUTGOING_TRANSFER', 'Outgoing Money Transfer',     'DEBIT',   'Money sent to another MoMo user'),
    ('PAYMENT_MERCHANT',  'Merchant Payment',            'DEBIT',   'Payment made to a registered MoMo merchant'),
    ('AIRTIME_PURCHASE',  'Airtime Top-Up',              'DEBIT',   'Buying mobile airtime through MoMo'),
    ('BANK_DEPOSIT',      'Bank to MoMo Deposit',        'CREDIT',  'Deposit coming from a linked bank account'),
    ('CASH_IN',           'Cash In via Agent',           'CREDIT',  'Cash deposited through a MoMo agent'),
    ('CASH_OUT',          'Cash Out via Agent',          'DEBIT',   'Cash withdrawn through a MoMo agent'),
    ('UTILITY_PAYMENT',   'Utility Bill Payment',        'DEBIT',   'Paying electricity, water, or internet bills'),
    ('INTERNATIONAL_IN',  'International Remittance In', 'CREDIT',  'Money received from outside the country'),
    ('REVERSAL',          'Transaction Reversal',        'NEUTRAL', 'A refund or reversal of a previous transaction');


-- -------------------------------------------------------
-- Sample data for users
-- -------------------------------------------------------
INSERT INTO users (phone_number, full_name, account_type, is_verified) VALUES
    ('+250788100001', 'Therese Mary Nshimyumurwa', 'INDIVIDUAL', 1),
    ('+250788100002', 'Aimable Bancunguye',         'INDIVIDUAL', 1),
    ('+250788100003', 'Eloi Mizero',                'INDIVIDUAL', 1),
    ('+250788100004', 'Davy Dushimiyimana',         'INDIVIDUAL', 1),
    ('+250788100005', 'Clive Tanaka Mushipe',        'INDIVIDUAL', 1),
    ('+250788200001', 'Kigali Mart Ltd',             'MERCHANT',   1),
    ('+250788300001', 'Jean Claude Agent',           'AGENT',      1);


-- -------------------------------------------------------
-- Sample data for transactions
-- -------------------------------------------------------
INSERT INTO transactions (external_ref, category_id, sender_id, receiver_id, amount, fee, balance_after, currency, transaction_date, status, sms_raw_body) VALUES
    ('TXN20250501001', 1, 2, 1,  50000.00, 0.00,    150000.00, 'RWF', '2025-05-01 08:15:00', 'SUCCESS', 'You have received 50,000 RWF from Aimable Bancunguye. Balance: 150,000 RWF. TxnID: TXN20250501001'),
    ('TXN20250502001', 3, 1, 6,  20000.00, 100.00,  129900.00, 'RWF', '2025-05-02 10:30:00', 'SUCCESS', 'Payment of 20,000 RWF to Kigali Mart Ltd was successful. Fee: 100 RWF. Balance: 129,900 RWF.'),
    ('TXN20250503001', 4, 1, NULL, 5000.00, 0.00,   124900.00, 'RWF', '2025-05-03 12:00:00', 'SUCCESS', 'Airtime purchase of 5,000 RWF was successful. Balance: 124,900 RWF.'),
    ('TXN20250504001', 6, NULL, 3, 100000.00, 0.00, 200000.00, 'RWF', '2025-05-04 09:00:00', 'SUCCESS', 'Cash In: 100,000 RWF deposited by agent. Balance: 200,000 RWF.'),
    ('TXN20250505001', 7, 2, NULL, 30000.00, 200.00, 169800.00,'RWF', '2025-05-05 14:20:00', 'SUCCESS', 'Cash Out: 30,000 RWF withdrawn. Fee: 200 RWF. Balance: 169,800 RWF.'),
    ('TXN20250506001', 8, 4, NULL, 15000.00, 0.00,  109900.00, 'RWF', '2025-05-06 07:45:00', 'SUCCESS', 'Utility payment of 15,000 RWF was processed. Balance: 109,900 RWF.'),
    ('TXN20250507001', 9, NULL, 5, 250000.00, 0.00, 450000.00, 'RWF', '2025-05-07 11:00:00', 'SUCCESS', 'International remittance of 250,000 RWF received. Balance: 450,000 RWF.'),
    ('TXN20250508001', 2, 3, 4,  10000.00, 100.00,  189900.00, 'RWF', '2025-05-08 16:10:00', 'FAILED',  'Transfer of 10,000 RWF to Davy Dushimiyimana failed. TxnID: TXN20250508001');


-- -------------------------------------------------------
-- Sample data for tags
-- -------------------------------------------------------
INSERT INTO tags (tag_name) VALUES
    ('flagged'),
    ('reconciled'),
    ('high_value'),
    ('duplicate_check'),
    ('international');


-- -------------------------------------------------------
-- Sample data for transaction_tags (many-to-many)
-- -------------------------------------------------------
INSERT INTO transaction_tags (transaction_id, tag_id, tagged_by) VALUES
    (7, 3, 'system'),
    (7, 5, 'system'),
    (8, 1, 'system'),
    (1, 2, 'system'),
    (4, 3, 'system');


-- -------------------------------------------------------
-- Sample data for system_logs
-- -------------------------------------------------------
INSERT INTO system_logs (log_level, event_type, transaction_id, message, source_file, ip_address) VALUES
    ('INFO',    'PARSE_SUCCESS',    1,    'SMS parsed successfully for TXN20250501001',           'etl/parse_xml.py',      '10.0.0.1'),
    ('INFO',    'DB_INSERT_OK',     1,    'Transaction TXN20250501001 saved to database',          'etl/load_db.py',        '10.0.0.1'),
    ('INFO',    'PARSE_SUCCESS',    2,    'SMS parsed successfully for TXN20250502001',            'etl/parse_xml.py',      '10.0.0.1'),
    ('ERROR',   'DB_INSERT_FAIL',   8,    'Transaction TXN20250508001 failed to insert',           'etl/load_db.py',        '10.0.0.1'),
    ('WARNING', 'AMOUNT_ANOMALY',   7,    'Amount 250,000 is above the high value limit of 200,000','etl/clean_normalize.py','10.0.0.1'),
    ('INFO',    'ETL_RUN_COMPLETE', NULL, 'Pipeline finished. 8 records processed, 1 failed.',    'etl/run.py',            '10.0.0.1');


-- -------------------------------------------------------
-- Test queries to check that everything works
-- -------------------------------------------------------

-- 1. Show all transactions with the sender name, receiver name, and category
SELECT
    t.transaction_id,
    t.external_ref,
    tc.category_name,
    sender.full_name  AS sender,
    receiver.full_name AS receiver,
    t.amount,
    t.fee,
    t.balance_after,
    t.status,
    t.transaction_date
FROM transactions t
JOIN transaction_categories tc ON t.category_id = tc.category_id
LEFT JOIN users sender          ON t.sender_id   = sender.user_id
LEFT JOIN users receiver        ON t.receiver_id = receiver.user_id
ORDER BY t.transaction_date DESC;

-- 2. Show how much money moved per category
SELECT
    tc.category_name,
    tc.direction,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount)           AS total_amount,
    AVG(t.fee)              AS average_fee
FROM transactions t
JOIN transaction_categories tc ON t.category_id = tc.category_id
WHERE t.status = 'SUCCESS'
GROUP BY tc.category_id, tc.category_name, tc.direction
ORDER BY total_amount DESC;

-- 3. Show each transaction and the tags attached to it
SELECT
    t.external_ref,
    t.amount,
    t.transaction_date,
    GROUP_CONCAT(tg.tag_name ORDER BY tg.tag_name SEPARATOR ', ') AS tags
FROM transactions t
JOIN transaction_tags tt ON t.transaction_id = tt.transaction_id
JOIN tags tg             ON tt.tag_id = tg.tag_id
GROUP BY t.transaction_id, t.external_ref, t.amount, t.transaction_date;

-- 4. Show a summary of errors and warnings from the log
SELECT
    log_level,
    event_type,
    COUNT(*) AS times_it_happened,
    MAX(created_at) AS last_time
FROM system_logs
GROUP BY log_level, event_type
ORDER BY log_level, times_it_happened DESC;

-- 5. Update a transaction note
UPDATE transactions
SET notes = 'Reviewed and confirmed by team lead'
WHERE external_ref = 'TXN20250507001';

-- 6. A view that shows daily totals for the dashboard
CREATE OR REPLACE VIEW v_daily_summary AS
    SELECT
        DATE(transaction_date) AS txn_date,
        tc.direction,
        COUNT(*)               AS total_transactions,
        SUM(amount)            AS total_volume,
        SUM(fee)               AS total_fees
    FROM transactions t
    JOIN transaction_categories tc ON t.category_id = tc.category_id
    WHERE t.status = 'SUCCESS'
    GROUP BY DATE(transaction_date), tc.direction;

-- 7. A view that only shows verified merchants
CREATE OR REPLACE VIEW v_verified_merchants AS
    SELECT user_id, phone_number, full_name
    FROM users
    WHERE account_type = 'MERCHANT'
    AND is_verified = 1;
