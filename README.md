# SQL Window Functions

Window functions were one of those things that clicked slowly and then all at once. This is a full breakdown of how they work in PostgreSQL :- ranking, aggregate, and offset functions, with exercises, summaries, gotchas, and everything I wished was in one place when I was learning them.

---

## Repo Structure

```
├── window_functions_general_reference.md   ← start here
│
├── employees_insert.sql
├── sales_insert.sql
│
├── Ranking_Functions.sql
├── ranking_functions_summary.md
│
├── Aggregate_Functions.sql
├── aggregate_window_functions_summary.md
│
├── Offset_Functions.sql
└── offset_functions_summary.md
```

---

## Ranking Functions

| Function | Behaviour |
|----------|-----------|
| `ROW_NUMBER()` | Unique number per row, no ties |
| `RANK()` | Ties get same rank, next rank skips (1, 2, 2, 4) |
| `DENSE_RANK()` | Ties get same rank, no skipping (1, 2, 2, 3) |
| `NTILE(n)` | Splits rows into n equal buckets |
| `PERCENT_RANK()` | Relative rank from 0.0 to 1.0 |

> Can't filter on a ranking function in `WHERE` — wrap in a CTE first.

---

## Aggregate Window Functions

| Function | Use |
|----------|-----|
| `SUM() OVER` | Group total per row |
| `AVG() OVER` | Group average per row |
| `COUNT() OVER` | Group headcount per row |
| `MIN() / MAX() OVER` | Group min/max per row |

> Adding `ORDER BY` inside `OVER()` turns these into running totals/averages.

---

## Frame Clauses

| Frame | Rows included | Use case |
|-------|--------------|----------|
| *(no frame, no ORDER BY)* | All rows in partition | Grand total / overall average |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | First row to current | Running total / running average |
| `ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING` | Previous, current, next | 3-row moving average |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` | All rows in partition | Grand total even with ORDER BY — required for `LAST_VALUE` |

---

## Offset Functions

| Function | Returns |
|----------|---------|
| `LAG(col, n, default)` | Value n rows before current |
| `LEAD(col, n, default)` | Value n rows after current |
| `FIRST_VALUE(col)` | First row in the partition |
| `LAST_VALUE(col)` | Last row — needs explicit frame clause  |

> `LAST_VALUE` requires `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` to work as expected.
