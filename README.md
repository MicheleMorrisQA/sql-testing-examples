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

```sql
SELECT transaction_id, transaction_type, amount, status
FROM transactions
WHERE status = 'FAILED'
ORDER BY created_at DESC;
