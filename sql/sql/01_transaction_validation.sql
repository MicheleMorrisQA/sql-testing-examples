# sql-testing-examples

This repository contains SQL examples demonstrating database validation and data testing techniques used in QA.

## QA Skills Demonstrated

- SQL data validation
- Database testing
- Data integrity checks
- Transaction validation
- Duplicate data detection
- Filtering and sorting
- Aggregation and reporting
- JOIN validation
- Negative testing

## Examples

### 1. Validate Transaction Status

-- Test Objective:
-- Validate failed transactions.

SELECT transaction_id, transaction_type, amount, status
FROM transactions
WHERE status = 'FAILED'
ORDER BY created_at DESC;

### 2. successful_transactions
-- Test Objective:
-- Validate successful transactions.

SELECT transaction_id, transaction_type, amount, status
FROM transactions
WHERE status = 'SUCCESS'
ORDER BY created_at DESC;

###03. pending_transactions.sql
-- Test Objective:
-- Identify transactions that remain pending.

SELECT transaction_id, transaction_type, amount, status
FROM transactions
WHERE status = 'PENDING'
ORDER BY created_at DESC;

### 4. invalid_transaction_amounts.sql
-- Test Objective:
-- Identify transactions with invalid amounts.

SELECT transaction_id, amount, status
FROM transactions
WHERE amount <= 0;

###5. Missing_transaction_data.sql
- Test Objective:
-- Identify transactions with missing required data.

SELECT transaction_id, transaction_type, amount, status
FROM transactions
WHERE transaction_id IS NULL
   OR transaction_type IS NULL
   OR amount IS NULL
   OR status IS NULL;
