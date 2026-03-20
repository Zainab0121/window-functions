# Ranking Functions — Summary

## The Core Idea

Ranking functions assign a position number to each row within a partition. They always require `ORDER BY` inside `OVER()` — without it, there is no defined sequence to rank against.

---

## The Functions

### `ROW_NUMBER()`
Assigns a **unique sequential number** to every row. Never produces ties — even if two rows are completely identical, one gets a higher number than the other. PostgreSQL decides which is which based on internal row order, so it is arbitrary.

```sql
ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC)
```

**Best for:** Deduplication — filter `WHERE row_num = 1` to keep exactly one row per group.

---

### `RANK()`
Ranks rows but respects ties. Tied rows get the **same rank**, but the next rank **skips** numbers to account for the tie.

```sql
RANK() OVER (PARTITION BY department ORDER BY salary DESC)
```

| salary | RANK |
|--------|------|
| 110000 | 1 |
| 95000 | 2 |
| 95000 | 2 |
| 82000 | 4 |

Rank 3 is skipped — like a race where two people tie for 2nd, the next person is 4th not 3rd.

---

### `DENSE_RANK()`
Same as `RANK()` but the next rank **never skips**. Ties still get the same number but the sequence stays consecutive.

```sql
DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC)
```

| salary | DENSE_RANK |
|--------|------------|
| 110000 | 1 |
| 95000 | 2 |
| 95000 | 2 |
| 82000 | 3 |

**Use `DENSE_RANK` when** gaps in the sequence would be confusing — telling an employee they are "4th highest paid" when only 3 distinct salary levels exist above them feels wrong.

---

### `NTILE(n)`
Divides all rows into `n` roughly equal buckets and returns the bucket number (1 to n). Useful for percentile banding like salary quartiles or customer tiers.

```sql
NTILE(4) OVER (ORDER BY salary ASC) AS salary_quartile
```

- `ORDER BY salary ASC` → bucket 1 = lowest paid, bucket 4 = highest paid
- `ORDER BY salary DESC` → bucket 1 = highest paid (opposite — be careful)
- When rows don't divide evenly, earlier buckets get one extra row

**Example — 10 employees into 4 buckets:**

| name | salary | NTILE(4) |
|------|--------|----------|
| Grace | 58000 | 1 |
| Hank | 62000 | 1 |
| James | 65000 | 1 |
| Dave | 67000 | 2 |
| Frank | 69000 | 2 |
| Eve | 73000 | 2 |
| Bob | 82000 | 3 |
| Iris | 88000 | 3 |
| Alice | 95000 | 4 |
| Carol | 110000 | 4 |

10 rows into 4 buckets = groups of 3, 3, 2, 2.

---

### `PERCENT_RANK()`
Expresses each row's rank as a percentage between 0.0 and 1.0, answering: *"what fraction of rows rank below this one?"*

```sql
ROUND(PERCENT_RANK() OVER (ORDER BY salary)::NUMERIC, 2) AS pct_rank
```

- Formula: `(rank - 1) / (total rows - 1)`
- First row is always **0.0**, last row is always **1.0**
- Requires `::NUMERIC` cast before `ROUND()` since PostgreSQL's `ROUND()` does not accept `DOUBLE PRECISION`

**Best for:** Saying things like "this employee is in the 80th percentile for salary."

---

## Side-by-Side Comparison

Same dataset, all five functions:

| name | salary | ROW_NUMBER | RANK | DENSE_RANK | NTILE(4) | PERCENT_RANK |
|------|--------|-----------|------|------------|----------|--------------|
| Grace | 58000 | 1 | 1 | 1 | 1 | 0.00 |
| Hank | 62000 | 2 | 2 | 2 | 1 | 0.11 |
| James | 65000 | 3 | 3 | 3 | 1 | 0.22 |
| Dave | 67000 | 4 | 4 | 4 | 2 | 0.33 |
| Frank | 69000 | 5 | 5 | 5 | 2 | 0.44 |
| Eve | 73000 | 6 | 6 | 6 | 2 | 0.56 |
| Bob | 82000 | 7 | 7 | 7 | 3 | 0.67 |
| Iris | 88000 | 8 | 8 | 8 | 3 | 0.78 |
| Alice | 95000 | 9 | 9 | 9 | 4 | 0.89 |
| Carol | 110000 | 10 | 10 | 10 | 4 | 1.00 |

> No ties in this dataset so `RANK`, `DENSE_RANK`, and `ROW_NUMBER` look identical here. The differences only appear when two rows share the same value.

---

## RANK vs DENSE_RANK on tied data

| salary | RANK | DENSE_RANK |
|--------|------|------------|
| 110000 | 1 | 1 |
| 95000 | 2 | 2 |
| 95000 | 2 | 2 |
| 82000 | **4** | **3** |

`RANK` skips 3. `DENSE_RANK` does not.

---

## Filtering on Rank Results

You **cannot** use a ranking function in a `WHERE` clause directly. Wrap in a CTE first:

```sql
-- Find the top earner per department
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

---

## Syntax Reference

```sql
-- With PARTITION BY (ranking restarts per group)
RANK()        OVER (PARTITION BY department ORDER BY salary DESC)
DENSE_RANK()  OVER (PARTITION BY department ORDER BY salary DESC)
ROW_NUMBER()  OVER (PARTITION BY department ORDER BY salary DESC)
NTILE(4)      OVER (ORDER BY salary ASC)
PERCENT_RANK() OVER (ORDER BY salary)

-- Without PARTITION BY (ranking across entire table)
RANK()        OVER (ORDER BY salary DESC)  -- global rank
```

---

## Quick Decision Guide

| I need to... | Use |
|-------------|-----|
| Give every row a unique number | `ROW_NUMBER()` |
| Rank with gaps on ties (1, 2, 2, 4) | `RANK()` |
| Rank without gaps on ties (1, 2, 2, 3) | `DENSE_RANK()` |
| Split rows into equal bands / tiers | `NTILE(n)` |
| Know what percentile a row falls in | `PERCENT_RANK()` |
| Deduplicate — keep one row per group | `ROW_NUMBER()` + filter `WHERE row_num = 1` |
| Find top N per group | Any ranking function + filter in CTE |
