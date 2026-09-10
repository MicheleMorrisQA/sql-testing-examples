-- QA Test: Identify Missing Transaction Data
-- Purpose: Verify required transaction fields are not NULL.

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    transaction_amount
FROM transactions
WHERE transaction_id IS NULL
   OR customer_id IS NULL
   OR transaction_date IS NULL
   OR transaction_amount IS NULL;
