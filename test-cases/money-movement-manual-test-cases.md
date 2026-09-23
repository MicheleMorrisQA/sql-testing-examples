# Money Movement Test Suite — Mobile & Web Banking

**Domain:** FinTech | **Integration Points:** Visa DPS · Core Ledger · Internal APIs · Webhooks · AWS CloudWatch

## Overview

This test suite validates an end-to-end funds transfer flow across mobile and web banking channels. It covers positive execution paths, negative/failure scenarios (declines, service outages, duplicate submissions), and observability validation via AWS CloudWatch to confirm system behavior matches expected logging, error handling, and reconciliation logic.

**System Under Test — Flow:**

```
Mobile/Web App → API Gateway → Payment Orchestration Service → Visa DPS → Core Ledger → Webhook (status callback) → App UI Update
```

Every hop is expected to emit structured logs to a dedicated CloudWatch log group, enabling transaction-level tracing by ID across all systems.

---

## Test Case Summary

| ID | Title | Type | Priority | Focus Area |
|----|-------|------|----------|------------|
| TC-001 | Successful Funds Transfer via Mobile App | Positive | Critical | End-to-end happy path |
| TC-002 | Successful Funds Transfer via Web App | Positive | High | Cross-channel consistency |
| TC-003 | Visa DPS Decline | Negative | Critical | No funds movement on decline |
| TC-004 | Core Ledger Failure After DPS Approval | Negative | Critical | Partial failure / reversal |
| TC-005 | Webhook Delivery Failure | Negative | High | Retry & fallback resolution |
| TC-006 | Duplicate Submission (Idempotency) | Negative | Critical | No duplicate postings |
| TC-007 | API Gateway Timeout Under Load | Negative | Medium | Graceful degradation |

---

## TC-001 — Successful Funds Transfer via Mobile App

**Type:** Positive | **Priority:** Critical

**Preconditions**
- User logged in on mobile app
- Source account funded ($500 balance)
- Visa DPS sandbox/prod environment healthy
- Webhook endpoint subscribed and active

**Test Data**
- Source account balance: $500
- Transfer amount: $100
- Destination: valid linked Visa debit card

**Steps**
1. Initiate transfer in mobile app (Send Money)
2. Confirm amount/destination, submit
3. App calls Payment API → orchestration service
4. Orchestration service calls Visa DPS for auth/settlement
5. Visa DPS returns approval code
6. Core ledger debits source account, credits destination
7. Webhook fires transaction-status event back to app
8. App UI updates to "Completed"

**Expected Result**
- Transaction status = Success
- Visa DPS approval code returned and logged
- Ledger balance updates correctly (source: $400)
- Webhook received within SLA (< 5s)
- Confirmation displayed in app
- Transaction ID consistent across app, ledger, and DPS

**CloudWatch Validation**
- Query orchestration and DPS log groups for the transaction ID
- Confirm 200/success response codes at every hop
- Confirm no ERROR or WARN entries
- Confirm latency within threshold (p99 < 2s)

**Postcondition**
- Ledger reconciled
- Audit log entry created with timestamp, user ID, amount, approval code

---

## TC-002 — Successful Funds Transfer via Web App

**Type:** Positive | **Priority:** High

**Objective**
Verify identical backend behavior when a transfer is initiated from web vs. mobile, since both channels share the same API layer.

**Steps**
Same as TC-001, initiated via web banking UI instead of mobile.

**Expected Result**
- Same ledger, DPS, and webhook behavior as TC-001
- Balance reflects identically on both mobile and web after refresh (real-time sync)

**CloudWatch Validation**
- Confirm request logged with `channel=web` metadata tag
- Confirm no discrepancy in processing path compared to mobile-originated request

---

## TC-003 — Visa DPS Decline (Insufficient Authorization / Card Issue)

**Type:** Negative | **Priority:** Critical

**Preconditions**
- Use test card configured to trigger a DPS decline (e.g., DPS test decline code 05 – "Do Not Honor")

**Steps**
1. Initiate transfer using decline-triggering test card
2. Submit transaction

**Expected Result**
- DPS returns decline code
- Orchestration service does **not** post to core ledger (no partial debit)
- App displays a clear, specific decline message — not a generic error
- No funds move on either side

**CloudWatch Validation**
- Confirm DPS decline code logged accurately
- Confirm **no** ledger-write log entry exists for this transaction ID (proves rollback/no-op logic worked)
- Confirm the decline is logged as a handled WARN — not an unhandled ERROR/exception

**Risk Focus**
Validates that no money moves when DPS declines, and that no ledger drift occurs.

---

## TC-004 — Core Ledger Failure After DPS Approval (Partial Failure / Reversal)

**Type:** Negative | **Priority:** Critical

**Preconditions**
- Simulate a ledger service outage or forced 500 error immediately after DPS approval (chaos/fault injection)

**Steps**
1. Initiate a valid transfer
2. DPS approves the transaction
3. Ledger service call fails or times out

**Expected Result**
- System detects the DPS-approved / ledger-not-updated mismatch
- Triggers an automatic reversal/void call to DPS, or queues the transaction for retry using its idempotency key
- Transaction status is marked "Pending / Failed – Reconciliation"
- Transaction is **never** silently shown as "Success" to the user

**CloudWatch Validation**
- Confirm the error is captured in the ledger service log group
- Confirm a compensating transaction (reversal) log entry exists
- Confirm a CloudWatch Alarm triggers if configured on ledger 5xx error rate

**Risk Focus**
This is the highest-risk scenario in money movement QA — a DPS/ledger desync. Also validates that idempotency key reuse on retry does not cause duplicate posting.

---

## TC-005 — Webhook Delivery Failure / Delay

**Type:** Negative | **Priority:** High

**Preconditions**
- Simulate the webhook endpoint returning a 500 error or timing out

**Steps**
1. Complete a valid transfer (DPS and ledger both succeed)
2. Webhook callback fails to deliver

**Expected Result**
- Retry mechanism triggers per configured backoff policy (e.g., 3 retries, exponential backoff)
- If all retries fail, transaction status remains resolvable via a polling/status API fallback, so the app never shows a stale "Pending" state indefinitely

**CloudWatch Validation**
- Confirm retry attempts are logged with timestamps matching the backoff policy
- Confirm no duplicate ledger postings occur as a result of retries (idempotency check)
- Confirm a Dead Letter Queue (if SQS-backed) captures the failed webhook after max retries

---

## TC-006 — Duplicate Submission / Idempotency Check

**Type:** Negative | **Priority:** Critical

**Steps**
1. Submit a transfer
2. Immediately resubmit the same request using the same idempotency key (simulating a network retry or accidental double-tap)

**Expected Result**
- Only one debit is posted to the ledger
- The second request returns the same transaction ID/result as the first (idempotent response), not a new duplicate transaction

**CloudWatch Validation**
- Confirm two inbound API requests are logged, but only one downstream DPS/ledger call executes
- Confirm logs show idempotency key match / short-circuit logic firing correctly

---

## TC-007 — API Gateway Timeout Under Load

**Type:** Negative | **Priority:** Medium

**Steps**
Initiate a transfer during a simulated high-latency/high-load condition (e.g., a load testing tool hitting the API concurrently).

**Expected Result**
- Graceful timeout handling — user sees a "processing, check status" state rather than a false failure
- Transaction eventually resolves consistently once the backend recovers

**CloudWatch Validation**
- Check API Gateway 4xx/5xx metrics and latency (p90/p99) during the load window
- Confirm no silent request drops — all requests are logged even under load

---

## CloudWatch Insights Queries (Reusable)

```sql
-- Trace all logs for a specific transaction ID across a log group
fields @timestamp, @message
| filter @message like /TXN-ID-HERE/
| sort @timestamp asc
```

```sql
-- Find ERROR-level entries within a test execution window
fields @timestamp, @message, logLevel
| filter logLevel = "ERROR"
| filter @timestamp > <start> and @timestamp < <end>
```

```sql
-- Check Visa DPS response code distribution
fields @timestamp, responseCode, txnId
| filter service = "visa-dps-connector"
| stats count() by responseCode
```

---

## Notes for Reviewers

- Test cases are written to be tool-agnostic (executable manually or automated via Tosca, Worksoft, Selenium/Playwright, or API-level tools like Postman/RestAssured)
- Negative scenarios prioritize **financial integrity** (no silent fund loss, no duplicate postings, no ledger drift) over simple error-message validation, reflecting FinTech risk priorities
- CloudWatch validation steps are included in every case to demonstrate observability-driven QA, not just functional pass/fail testing
