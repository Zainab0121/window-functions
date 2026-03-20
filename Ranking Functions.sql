-- Write a query that shows every employee with their name, department, salary, and their salary rank within their department (highest salary = rank 1). Use RANK().
-- RANK():-Tied rows get the same rank. The next rank skips numbers.(1,2,2,4)
SELECT
	name,
	department,
	salary,
	RANK() OVER(PARTITION BY department ORDER BY salary DESC) AS dept_rank
FROM employees
ORDER BY department, dept_rank; -- tells PostgreSQL how to sort the result set you see

-- Add a second column using DENSE_RANK() alongside RANK(). 
-- Run the query — are the results different? Write a comment in your notes explaining why or why not with this specific dataset
SELECT
	name,
	department,
	salary,
	RANK() OVER(PARTITION BY department ORDER BY salary DESC) AS dept_rank,
	DENSE_RANK() OVER(PARTITION BY department ORDER BY salary DESC) AS dept_dense_rank
-- Results are the same due to lack of duplicates	
FROM employees
ORDER BY department, dept_rank;


-- DENSE_RANK():- Tied rows get the same rank. The next rank does NOT skip(1,2,2,3)
SELECT
	name,
	department,
	salary,
	DENSE_RANK() OVER(PARTITION BY department ORDER BY salary DESC) AS dept_dense_rank
FROM employees
ORDER BY department, dept_rank;

-- ROW_NUMBER():- Unique integer for every row. No ties — if two rows are equal, one gets a higher number arbitrarily. (1,2,3,4)
SELECT
	name,
	department,
	salary,
	ROW_NUMBER() OVER()
FROM employees;

--Write a query using NTILE(4) to split all employees into 4 salary quartiles. Label the quartile column 'salary_quartile'. Quartile 1 = lowest paid.
SELECT
	name,
	department,
	salary,
	NTILE(4) OVER(ORDER BY salary ASC) AS salary_quartile
FROM employees;

--Add PERCENT_RANK() OVER (ORDER BY salary) as a column called 'pct_rank'. Round it to 2 decimal places.
SELECT
	name,
	department,
	salary,
	ROUND(PERCENT_RANK() OVER(ORDER BY salary)::NUMERIC,2) AS pct_rank
FROM employees;
