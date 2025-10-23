# Apex Coverage Analysis

Date: 2025-10-23

Org-wide coverage from latest run: 64%

## Per-class summary

| Class/Trigger | Covered | Uncovered | Coverage |
|---|---:|---:|---:|
| MovieGluService | 141 | 12 | 92.16% |
| PaymentService | 77 | 32 | 70.64% |
| ReservationController | 106 | 89 | 54.36% |
| SeatManagementService | 35 | 85 | 29.17% |
| ShowtimeTrigger | 1 | 0 | 100.00% |
| ShowtimeTriggerHandler | 35 | 3 | 92.11% |

## Priorities to reach ≥75%

- SeatManagementService: add tests for error branches (invalid params, FLS checks), lock/unlock flows, statistics edge cases.
- ReservationController: cover error paths (validation failures), platform event publishing branches, email future method path, payment path success/failure.
- PaymentService: add scenarios for gateway failure and refund failure handling.

## Notes

- Platform Event fields validated and retrieved from org; local metadata synchronized.
- Data import skipped due to duplicate external IDs (existing seed data in org).


