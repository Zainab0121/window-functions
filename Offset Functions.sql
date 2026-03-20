--Using the sales table joined to employees, write a query that shows for each sale: employee name, sale_date, amount, and the amount of that employee's PREVIOUS sale using LAG(). 
-- For the first sale (no previous), show 0.
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount,
	LAG(amount, 1, 0) OVER(PARTITION BY s.emp_id ORDER BY sale_date) AS previous_sale
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id;

--Add a column 'change_vs_prev': amount minus the previous sale amount. Positive = improvement.
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount,
	LAG(amount, 1, 0) OVER(PARTITION BY s.emp_id ORDER BY sale_date) AS previous_sale,
	amount - LAG(amount, 1, 0) OVER(PARTITION BY s.emp_id ORDER BY sale_date) AS change_vs_prev
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id;

--Add a column 'next_sale_amount' using LEAD() — the amount of the employee's next sale.
-- Show NULL if there is no next sale.
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount,
	LEAD(amount, 1, NULL) OVER(PARTITION BY s.emp_id ORDER BY sale_date) AS next_sale
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id;

--Add a column 'first_sale_ever' using FIRST_VALUE(): the amount of the employee's very first sale (lowest sale_date) for comparison.
SELECT
	s.sale_date,
	e.name,
	e.department,
	s.amount,
	FIRST_VALUE(amount) OVER(PARTITION BY s.emp_id ORDER BY sale_date) AS first_sale_ever
FROM employees e
JOIN sales s
ON e.emp_id = s.emp_id;

