DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    sale_id    SERIAL PRIMARY KEY,
    emp_id     INT REFERENCES employees(emp_id),
    sale_date  DATE,
    amount     NUMERIC(10,2),
    region     VARCHAR(30)
);
 
INSERT INTO sales (emp_id, sale_date, amount, region) VALUES
  (1, '2024-01-05', 4200, 'North'), (1, '2024-01-18', 3100, 'North'),
  (2, '2024-01-07', 5500, 'South'), (2, '2024-02-14', 2900, 'South'),
  (3, '2024-01-11', 7800, 'East'),  (3, '2024-02-03', 6100, 'East'),
  (4, '2024-01-20', 3300, 'West'),  (4, '2024-02-28', 4100, 'West'),
  (5, '2024-01-09', 2800, 'North'), (5, '2024-02-17', 3600, 'North'),
  (6, '2024-01-25', 4900, 'South'), (6, '2024-03-01', 5200, 'South'),
  (7, '2024-02-05', 1900, 'East'),  (8, '2024-02-19', 3400, 'East'),
  (9, '2024-01-14', 6200, 'West'),  (9, '2024-03-10', 5800, 'West'),
  (10,'2024-02-22', 2100, 'North'), (10,'2024-03-15', 2700, 'North');

SELECT * FROM sales;