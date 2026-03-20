# Window Functions — General Reference

## What Is a Window Function?

A window function performs a calculation across a set of rows related to the current row, without collapsing those rows into a single result.

> **One-liner:** A window function **annotates** your rows with a calculation rather than replacing them.

---

## GROUP BY vs Window Functions

| | GROUP BY | Window Function |
|--|----------|----------------|
| Rows returned | One per group | All original rows kept |
| Result | Replaces the table | Adds an extra column |
| Filter results? | `HAVING` | Wrap in CTE, then `WHERE` |
| Keyword | None | `OVER()` |

```sql
-- GROUP BY: collapses rows — individual rows are lost
SELECT region, SUM(sales) AS total
FROM orders
GROUP BY region;
-- Result: 3 rows (one per region)

-- Window function: every row is kept, total added alongside
SELECT region, sales,
       SUM(sales) OVER (PARTITION BY region) AS regional_total
FROM orders;
-- Result: all original rows with regional_total added to each
```

---

## The Golden Rule

> If you see `OVER`, you are looking at a window function. That is the **only** syntax that makes it one.

---

## Full Syntax

```sql
SELECT
    column_name,
    function_name(expression)
        OVER (
            PARTITION BY partition_column   -- defines the group (optional)
            ORDER BY     order_column       -- defines the sort within group (sometimes optional)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  -- frame (optional)
        ) AS alias
FROM table_name;
```

---

## What Each Part Does

**`function_name(expression)`**
The function to run. Some take no argument (`RANK()`), others need a column (`SUM(salary)`).

**`OVER(...)`**
Makes it a window function. Everything inside defines the window — which rows to look at for each calculation.

**`PARTITION BY partition_column`** *(optional)*
Splits rows into groups and restarts the calculation for each group. Like `GROUP BY` but rows are kept. Omit it to treat the entire table as one window.

**`ORDER BY order_column`** *(sometimes optional)*
Sorts rows within each partition before calculating. Required for ranking functions and running totals. Defines what "previous row" means.

**`ROWS BETWEEN ... AND ...`** *(optional)*
The frame clause — defines exactly which rows within the partition to include. See frame section below.

**`AS alias`**
Names the output column.

> **Critical:** The order of clauses inside `OVER()` is fixed — `PARTITION BY` → `ORDER BY` → `ROWS BETWEEN`. Swapping them causes a syntax error.

---

## The Three ORDER BYs — They Do Different Things

This is one of the most confusing parts. There can be up to three separate `ORDER BY` / `PARTITION BY` usages in one query and they all do different things:

| Clause | Where | What it controls |
|--------|-------|-----------------|
| `PARTITION BY` | Inside `OVER()` | Where the **calculation restarts** |
| `ORDER BY` | Inside `OVER()` | The **sequence** for the calculation (ranking, running totals) |
| `ORDER BY` | End of query | How the **result set is displayed** |

```sql
SELECT
    s.sale_date,
    e.department,
    s.amount,
    AVG(amount) OVER (PARTITION BY department   -- calculation restarts per dept
                      ORDER BY sale_date)        -- running avg ordered by date
    AS running_avg
FROM employees e
JOIN sales s ON e.emp_id = s.emp_id
ORDER BY department, sale_date;                 -- display order only
```

The outer `ORDER BY` does not affect any calculation — it only affects what you see.

---

## The Frame Clause

The frame defines exactly which rows are included in the calculation **for the current row**. Think of it as a sliding window physically moving down your rows.

```
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
| `ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING` | Previous, current, and next row | 3-row moving average |
| `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` | All rows in partition | Grand total even with ORDER BY (required for LAST_VALUE) |

### Visualising the frame

`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` — the frame grows as you move down:

```
Calculating for Row 3:        Calculating for Row 4:
Row 1  ✅                     Row 1  ✅
Row 2  ✅                     Row 2  ✅
Row 3  ✅  ← current          Row 3  ✅
Row 4  ❌                     Row 4  ✅  ← current
Row 5  ❌                     Row 5  ❌
```

`ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING` — the frame slides and stays 3 rows wide:

```
Calculating for Row 3:
Row 1  ❌
Row 2  ✅
Row 3  ✅  ← current
Row 4  ✅
Row 5  ❌
```

---

## Default Frame Behaviour

When you add `ORDER BY` inside `OVER()` but no explicit frame clause, PostgreSQL automatically applies:

```
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

This is why `SUM() OVER (ORDER BY date)` gives a running total — not because you specified a frame, but because PostgreSQL applies this default the moment `ORDER BY` is present.

| `ORDER BY` inside `OVER()`? | Default frame | Result |
|-----------------------------|--------------|--------|
| No | All rows in partition | Grand total — same value every row |
| Yes | `UNBOUNDED PRECEDING TO CURRENT ROW` | Running total — grows each row |

---

## Filtering on Window Function Results

Window functions **cannot** be used in a `WHERE` clause. This is because `WHERE` filters rows before window functions are calculated.

```sql
-- This will ERROR:
SELECT name, RANK() OVER (ORDER BY salary DESC) AS rnk
FROM employees
WHERE rnk = 1;  -- rnk does not exist yet at this point
```

**Fix — wrap in a CTE:**
```sql
WITH ranked AS (
    SELECT
        name,
        department,
        salary,
        RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_rank
    FROM employees
)
SELECT * FROM ranked
WHERE dept_rank = 1;
```

**Fix — wrap in a subquery:**
```sql
SELECT * FROM (
    SELECT
        name,
        department,
        salary,
        RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_rank
    FROM employees
) ranked
WHERE dept_rank = 1;
```

Both approaches work identically. CTEs are preferred for readability.

---

## Stacking Multiple Window Functions

You can use as many window functions as you need in the same `SELECT`. Each `OVER()` is independent and can have a different `PARTITION BY`:

```sql
SELECT
    name,
    department,
    salary,
    RANK()         OVER (PARTITION BY department ORDER BY salary DESC) AS dept_rank,
    DENSE_RANK()   OVER (PARTITION BY department ORDER BY salary DESC) AS dept_dense_rank,
    ROW_NUMBER()   OVER (PARTITION BY department ORDER BY salary DESC) AS row_num,
    AVG(salary)    OVER (PARTITION BY department)                      AS dept_avg,
    AVG(salary)    OVER ()                                             AS company_avg
FROM employees
ORDER BY department, dept_rank;
```

---

## All Window Functions at a Glance

### Ranking
| Function | Use case |
|----------|---------|
| `ROW_NUMBER()` | Unique number per row, no ties |
| `RANK()` | Rank with gaps on ties (1,2,2,4) |
| `DENSE_RANK()` | Rank without gaps on ties (1,2,2,3) |
| `NTILE(n)` | Split rows into n equal buckets |
| `PERCENT_RANK()` | Relative rank 0.0 to 1.0 |

### Aggregate
| Function | Use case |
|----------|---------|
| `SUM() OVER` | Group total without collapsing rows |
| `AVG() OVER` | Group average per row |
| `COUNT() OVER` | Group headcount per row |
| `MIN() OVER` | Group minimum per row |
| `MAX() OVER` | Group maximum per row |

### Offset
| Function | Use case |
|----------|---------|
| `LAG(col, n, default)` | Value from n rows before current row |
| `LEAD(col, n, default)` | Value from n rows after current row |
| `FIRST_VALUE(col)` | Value from the first row in the window |
| `LAST_VALUE(col)` | Value from the last row — needs explicit frame |
| `NTH_VALUE(col, n)` | Value from the nth row in the frame |
