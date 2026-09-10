-- QA Test: Identify Duplicate Transactions
-- Purpose: Verify that transaction IDs are unique.

SELECT
    transaction_id,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;
