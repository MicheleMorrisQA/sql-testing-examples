# SQL & Database Testing

This section contains SQL examples demonstrating how SQL can be used to support software quality assurance and database testing.

The examples focus on validating data, business rules, transaction processing, data integrity, relationships between tables, and reporting results.

---

## SQL Testing Areas

### Transaction Testing

Examples include:

- Transaction status validation
- Successful transactions
- Failed transactions
- Pending transactions
- Invalid transaction amounts
- Missing transaction data
- Future transaction dates
- Invalid transaction statuses

### Data Integrity Testing

Examples include:

- Duplicate transaction IDs
- Duplicate customer records
- NULL values
- Missing required data
- Orphan records
- Referential integrity

### JOIN Testing

Examples include:

- Customer-to-transaction validation
- Customers without transactions
- Transactions without customers

### Payment Testing

Examples include:

- Failed payments
- Invalid payment methods
- Payment-to-transaction validation
- Transaction/payment status mismatches

### Boundary Testing

Examples include:

- Minimum transaction amounts
- Maximum transaction amounts
- Values below allowed limits
- Values above allowed limits

### Reporting Validation

Examples include:

- Transaction counts by status
- Transaction amounts by status
- Daily transaction counts

---

## Testing Approach

SQL queries in this section are written from a QA perspective.

Each example is intended to demonstrate how database queries can be used to:

1. Validate application behavior.
2. Verify business rules.
3. Identify invalid data.
4. Detect data integrity issues.
5. Support defect investigation.
6. Validate expected database results.
7. Support regression testing.

---

## Example

```sql
-- Test Objective:
-- Validate failed transactions.
--
-- Test Type:
-- Database / Functional
--
-- Expected Result:
-- Returned transactions should have a status of FAILED.

SELECT transaction_id, transaction_type, amount, status
FROM transactions
WHERE status = 'FAILED'
ORDER BY created_at DESC;
