# Aggregate Window Functions — Summary

## The Core Idea

Aggregate functions you already know (`SUM`, `AVG`, `COUNT`, `MIN`, `MAX`) work as window functions when you add `OVER()`. The difference:

| | Regular Aggregate | Window Aggregate |
|--|------------------|-----------------|
| Syntax | `SUM(salary)` | `SUM(salary) OVER (...)` |
| Collapses rows? | Yes — one row per group | No — every original row is kept |
| Result | One total per group | Total added as extra column per row |

> **Mental model:** `GROUP BY` replaces your table. A window function annotates your table.

---

## The Functions

**`SUM() OVER`** — group total without collapsing rows
```sql
SUM(amount) OVER (PARTITION BY region) AS region_total
```
Every row gets the total for its region alongside its own amount.

---

**`AVG() OVER`** — group average per row
```sql
AVG(salary) OVER (PARTITION BY department) AS dept_avg
```
Every row gets the average salary of its department.

---

**`COUNT() OVER`** — group headcount per row
```sql
COUNT(*) OVER (PARTITION BY department) AS dept_headcount
```
Every row gets the number of people in its department.

---

**`MIN() / MAX() OVER`** — group min/max per row
```sql
MIN(salary) OVER (PARTITION BY department) AS dept_min,
MAX(salary) OVER (PARTITION BY department) AS dept_max
```

---

## Calculating Differences

Treat the window function result like any regular column and apply arithmetic:

```sql
SELECT
    name,
    department,
    salary,
    AVG(salary) OVER (PARTITION BY department)            AS dept_avg,
    salary - AVG(salary) OVER (PARTITION BY department)   AS diff_from_avg,
    salary - MAX(salary) OVER (PARTITION BY department)   AS diff_from_max
FROM employees;
```
Positive `diff_from_avg` = above average. Negative = below average.

---

## Running Totals & Running Averages

Adding `ORDER BY` inside `OVER()` changes the behaviour — instead of the whole partition total, you get a **cumulative** result up to the current row.

```sql
-- Running total
SUM(amount) OVER (PARTITION BY department ORDER BY sale_date) AS running_total

-- Running average
AVG(amount) OVER (PARTITION BY department ORDER BY sale_date) AS running_avg
```

This works because when you add `ORDER BY` without an explicit frame clause, PostgreSQL automatically applies the frame `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

### Running total example (Engineering dept):

| sale_date | amount | running_total | running_avg |
|-----------|--------|--------------|-------------|
| 2024-01-05 | 4200 | 4200 | 4200.00 |
| 2024-01-11 | 7800 | 12000 | 6000.00 |
| 2024-02-03 | 6100 | 18100 | 6033.33 |
| 2024-02-14 | 5500 | 23600 | 5900.00 |
| 2024-03-10 | 6200 | 29800 | 5960.00 |

Each row includes itself and all previous rows in the calculation.

---

## The Frame Clause

The frame defines exactly which rows are included in the calculation for the current row. Think of it as a sliding window moving down your rows.

```sql
ROWS BETWEEN [start] AND [end]
```

### Frame vocabulary

| Term | Meaning |
|------|---------|
| `UNBOUNDED PRECEDING` | The very first row of the partition |
| `UNBOUNDED FOLLOWING` | The very last row of the partition |
| `CURRENT ROW` | The row currently being calculated |
| `n PRECEDING` | n rows before the current row |
| `n FOLLOWING` | n rows after the current row |

### Common frames

| Frame | Rows included | Use case |
|-------|--------------|---------|
| *(no frame, no ORDER BY)* | All rows in partition | Grand total / overall average |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` | First row up to current row | Running total / running average |
| `ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING` | Previous, current, next row | 3-row moving average |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` | All rows in partition | Grand total even with ORDER BY (needed for LAST_VALUE) |

### Visualising the frame moving down

`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`:
```
Calculating for Row 3:        Calculating for Row 4:
Row 1  ✅                     Row 1  ✅
Row 2  ✅                     Row 2  ✅
Row 3  ✅  ← current          Row 3  ✅
Row 4  ❌                     Row 4  ✅  ← current
Row 5  ❌                     Row 5  ❌
```
The frame grows by one row each time — that's what makes it a running total.

---

## PARTITION BY vs ORDER BY vs outer ORDER BY

These three things do completely different jobs:

| Clause | Where | What it does |
|--------|-------|-------------|
| `PARTITION BY` | Inside `OVER()` | Controls where the **calculation restarts** |
| `ORDER BY` | Inside `OVER()` | Controls the **sequence** within each partition for the calculation |
| `ORDER BY` | End of query | Controls how the **results are displayed** |

```sql
SELECT
    s.sale_date,
    e.name,
    e.department,
    s.amount,
    AVG(amount) OVER (PARTITION BY department ORDER BY sale_date) AS running_avg
FROM employees e
JOIN sales s ON e.emp_id = s.emp_id
ORDER BY department, sale_date;  -- only affects display, not the calculation
```

- `PARTITION BY department` — running average restarts for each department
- `ORDER BY sale_date` inside `OVER()` — defines "previous" as earlier sale dates
- `ORDER BY department, sale_date` at the end — makes the restart visually obvious in output

---

## Stacking Multiple Window Functions

You can use as many aggregate window functions as you need in the same `SELECT`. Each `OVER()` can have a different `PARTITION BY`:

```sql
SELECT
    name,
    department,
    salary,
    AVG(salary)   OVER (PARTITION BY department) AS dept_avg,
    MAX(salary)   OVER (PARTITION BY department) AS dept_max,
    MIN(salary)   OVER (PARTITION BY department) AS dept_min,
    COUNT(*)      OVER (PARTITION BY department) AS dept_headcount,
    AVG(salary)   OVER ()                        AS company_avg  -- no PARTITION BY = whole table
FROM employees;
```

---

## Filtering on Window Function Results

You **cannot** use a window function in a `WHERE` clause directly. Wrap the query in a CTE or subquery first:

```sql
-- This will ERROR:
WHERE salary > AVG(salary) OVER (PARTITION BY department)

-- Correct approach — wrap in a CTE:
WITH dept_avgs AS (
    SELECT
        name,
        department,
        salary,
        AVG(salary) OVER (PARTITION BY department) AS dept_avg
    FROM employees
)
SELECT * FROM dept_avgs
WHERE salary > dept_avg;
```
