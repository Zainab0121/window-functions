DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    name       VARCHAR(50),
    department VARCHAR(50),
    hire_date  DATE,
    salary     NUMERIC(10,2)
);
 
INSERT INTO employees (name, department, hire_date, salary) VALUES
  ('Alice',   'Engineering', '2019-03-15', 95000),
  ('Bob',     'Engineering', '2020-07-01', 82000),
  ('Carol',   'Engineering', '2018-11-20', 110000),
  ('Dave',    'Marketing',   '2021-01-10', 67000),
  ('Eve',     'Marketing',   '2019-06-22', 73000),
  ('Frank',   'Marketing',   '2020-09-05', 69000),
  ('Grace',   'HR',          '2022-02-14', 58000),
  ('Hank',    'HR',          '2020-04-30', 62000),
  ('Iris',    'Engineering', '2021-08-17', 88000),
  ('James',   'HR',          '2019-12-01', 65000);

SELECT * FROM employees;