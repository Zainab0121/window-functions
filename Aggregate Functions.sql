--Write a query showing each employee's name, department, salary, and the average salary in their department as a column called 'dept_avg'. Use AVG() OVER (PARTITION BY ...).
SELECT
	name,
	department,
	salary,
	ROUND(AVG(salary) OVER(PARTITION BY department),2) AS dept_avg
FROM employees;

--Add a column 'diff_from_avg': the difference between the employee's salary and their department average. Positive = above average, negative = below average.
SELECT
	name,
	department,
	salary,
	ROUND(AVG(salary) OVER(PARTITION BY department),2) AS dept_avg,
	ROUND(salary - AVG(salary) OVER(PARTITION BY department),2) AS diff_from_avg
FROM employees;

--Add a column 'dept_max_salary' using MAX() OVER and a column 'dept_min_salary' using MIN() OVER.
SELECT
	name,
	department,
	salary,
	ROUND(MAX(salary) OVER(PARTITION BY department),2) AS dept_max_avg
FROM employees;
---
SELECT
	name,
	department,
	salary,
	ROUND(MIN(salary) OVER(PARTITION BY department),2) AS dept_max_avg
FROM employees;

--Add a column 'dept_headcount' using COUNT(*) OVER (PARTITION BY department) — the number of people in each employee's department.
SELECT
	name,
	department,
	salary,
	COUNT(*) OVER(PARTITION BY department) AS dept_headcount
FROM employees;

-- Join the sales and employees tables. Write a query showing: sale_date, employee name, department, amount.
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id;

--Add a column 'running_total_overall': the cumulative sum of amount ordered by sale_date across all sales (no PARTITION BY)
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount,
	SUM(amount) OVER(ORDER BY sale_date) AS running_total_overall
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id;
-- For a running total you need ORDER BY inside OVER().
-- Without ORDER BY, SUM OVER gives you the grand total for every row — not a running total.

--Add a column 'running_total_dept': the cumulative sum of amount ordered by sale_date, restarting for each department. Use PARTITION BY department.
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount,
	SUM(amount) OVER(PARTITION BY department ORDER BY sale_date) AS running_total_dept
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id;

--Add a column 'running_avg_dept': the running average (not sum) per department using AVG() with the same frame.
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount,
	AVG(amount) OVER(PARTITION BY department ORDER BY sale_date) AS running_avg_dept -- what is the average sale amount in this department up to and including this date?
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id;

--Order the final result by department, then sale_date. Study the output — does the running total restart when the department changes?
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount,
	AVG(amount) OVER(PARTITION BY department ORDER BY sale_date) AS running_avg_dept 
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id
ORDER BY department, sale_date;

-- Add a column 'best_sale_in_region' using MAX() OVER (PARTITION BY region) — the highest single sale ever made in that sale's region.
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount,
	s.region,
	MAX(amount) OVER(PARTITION BY region) AS best_sale_in_region
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id;