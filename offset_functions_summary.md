# Offset Functions — Summary

## The Core Idea

Offset functions let you look at **other rows** from the perspective of the current row — the row before it, the row after it, or the first/last row in the partition.

> **Main use case:** Period-over-period comparisons — *"how did this sale compare to the previous one?"*

---

## The Functions

### `LAG(column, n, default)`
Looks **backwards** — returns the value from a row **before** the current row.

```sql
LAG(amount, 1, 0) OVER (PARTITION BY s.emp_id ORDER BY s.sale_date) AS prev_sale
```

| Argument | Meaning |
|----------|---------|
| `column` | Which column to look at |
| `n` | How many rows back to look (default is 1 if omitted) |
| `default` | What to return if no previous row exists |

| name | sale_date | amount | prev_sale |
|------|-----------|--------|-----------|
| Alice | 2024-01-05 | 4200 | 0 |
| Alice | 2024-02-10 | 3100 | 4200 |

Alice's first sale has no previous row so it returns the default `0`. Her second sale looks back one row and returns `4200`.

---

### `LEAD(column, n, default)`
Looks **forwards** — returns the value from a row **after** the current row. Exact opposite of `LAG`.

```sql
LEAD(amount, 1, NULL) OVER (PARTITION BY s.emp_id ORDER BY s.sale_date) AS next_sale
```

| name | sale_date | amount | next_sale |
|------|-----------|--------|-----------|
| Alice | 2024-01-05 | 4200 | 3100 |
| Alice | 2024-02-10 | 3100 | NULL |

The last row has no next row so it returns `NULL`.

---

### `FIRST_VALUE(column)`
Returns the value from the **first row** in the window frame — same value for every row in the partition.

```sql
FIRST_VALUE(amount) OVER (PARTITION BY s.emp_id ORDER BY s.sale_date) AS first_sale_ever
```

| name | sale_date | amount | first_sale_ever |
|------|-----------|--------|----------------|
| Alice | 2024-01-05 | 4200 | 4200 |
| Alice | 2024-02-10 | 3100 | 4200 |

Every row gets Alice's very first sale because `FIRST_VALUE` always anchors to the first row of the partition.

---

### `LAST_VALUE(column)` ⚠️
Returns the value from the **last row** in the window frame — but has a critical gotcha.

**The gotcha:** The default frame is `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. So without an explicit frame, `LAST_VALUE` returns the **current row's own value** — completely useless.

```sql
-- ❌ Wrong — returns the current row's value every time
LAST_VALUE(amount) OVER (PARTITION BY s.emp_id ORDER BY s.sale_date)

-- ✅ Correct — returns the last sale for that employee
LAST_VALUE(amount) OVER (
    PARTITION BY s.emp_id
    ORDER BY s.sale_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
```

Always add `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` when using `LAST_VALUE`.

---

## Calculating Differences with LAG

The most common real-world use — comparing each row to the previous one:

```sql
SELECT
    e.name,
    s.sale_date,
    s.amount,
    LAG(s.amount, 1, 0) OVER (PARTITION BY s.emp_id ORDER BY s.sale_date) AS prev_sale,
    s.amount - LAG(s.amount, 1, 0) OVER (PARTITION BY s.emp_id ORDER BY s.sale_date) AS change_vs_prev
FROM sales s
JOIN employees e ON s.emp_id = e.emp_id;
```

| name | sale_date | amount | prev_sale | change_vs_prev |
|------|-----------|--------|-----------|----------------|
| Alice | 2024-01-05 | 4200 | 0 | 4200 |
| Alice | 2024-02-10 | 3100 | 4200 | -1100 |

Positive = improvement. Negative = decline.

---

## Why LAG Appears Twice for Differences

You cannot reference a column alias in the same `SELECT` it was defined in. So this does **not** work:

```sql
LAG(amount, 1, 0) OVER (...) AS prev_sale,
amount - prev_sale AS change_vs_prev  -- ❌ prev_sale doesn't exist yet
```

You have to repeat the full expression:

```sql
LAG(amount, 1, 0) OVER (...) AS prev_sale,
amount - LAG(amount, 1, 0) OVER (...) AS change_vs_prev  -- ✅ spell it out again
```

Both `LAG` calls produce the exact same number — it is not doing anything new, it is purely a SQL limitation workaround.

**Cleaner alternative — use a CTE:**

```sql
WITH lag_calculated AS (
    SELECT
        e.name,
        s.sale_date,
        s.amount,
        LAG(s.amount, 1, 0) OVER (PARTITION BY s.emp_id ORDER BY s.sale_date) AS prev_sale
    FROM sales s
    JOIN employees e ON s.emp_id = e.emp_id
)
SELECT
    name,
    sale_date,
    amount,
    prev_sale,
    amount - prev_sale AS change_vs_prev  -- ✅ now this works
FROM lag_calculated;
```

Define `LAG` once in the CTE, reference the alias freely in the outer query.

---

## LAG vs LEAD vs FIRST_VALUE — What Each Compares

Given three sales rows for Alice:

| Row | amount | LAG | LEAD | FIRST_VALUE |
|-----|--------|-----|------|-------------|
| 1st | 4200 | 0 | 3100 | 4200 |
| 2nd | 3100 | 4200 | 6100 | 4200 |
| 3rd | 6100 | 3100 | NULL | 4200 |

- `amount - LAG` → how this sale compares to the **previous** sale
- `amount - LEAD` → how this sale compares to the **next** sale
- `amount - FIRST_VALUE` → how this sale compares to the **very first** sale

---

## Why PARTITION BY Matters for Offset Functions

Without `PARTITION BY`, `LAG` and `LEAD` look across **all rows** — so Alice's "previous sale" could end up being Bob's last sale, which makes no sense.

```sql
-- ❌ Wrong — LAG crosses employee boundaries
LAG(amount) OVER (ORDER BY sale_date)

-- ✅ Correct — LAG stays within each employee's own history
LAG(amount) OVER (PARTITION BY s.emp_id ORDER BY s.sale_date)
```

Always ask: *"should this comparison stay within a group, or span the whole table?"*

---

## Quick Reference

| Function | Direction | Returns | Default if no row |
|----------|-----------|---------|------------------|
| `LAG(col, n, default)` | Backwards | Value n rows before current | Your specified default |
| `LEAD(col, n, default)` | Forwards | Value n rows after current | Your specified default |
| `FIRST_VALUE(col)` | Backwards | First row in the partition | N/A — always exists |
| `LAST_VALUE(col)` | Forwards | Last row — needs explicit frame | N/A — but frame gotcha applies |

---

## Common Mistake Summary

| Mistake | Fix |
|---------|-----|
| `LAG()` with no column argument | Always specify the column: `LAG(amount, 1, 0)` |
| `LAST_VALUE` returning current row's value | Add `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` |
| `LAG` crossing group boundaries | Add `PARTITION BY` to keep comparisons within the right group |
| Repeating `LAG` for difference calculation | Use a CTE to define it once and reuse the alias |
| Missing table alias on column inside `OVER()` when using JOINs | Always prefix: `PARTITION BY s.emp_id` not just `emp_id` |
