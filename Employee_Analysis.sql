-- Project: PostgreSQL Employee Analysis
-- Author: [Your Name]
-- Description: Full-stack SQL project covering data modeling, constraints, inserts, updates, views, aggregations, and advanced window functions.
-- =======================================================================

-- Task 1.1: Create an 'employees' table to store all employee details with appropriate constraints
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    position_title TEXT NOT NULL,
    salary DECIMAL(8,2),
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    birth_date DATE NOT NULL CHECK (birth_date < CURRENT_DATE),
    store_id INT,
    department_id INT NOT NULL,
    manager_id INT,
    end_date DATE
);

-- Task 1.2: Create a 'departments' table to categorize departments and divisions
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department TEXT NOT NULL,
    division TEXT NOT NULL
);

-- Task 2: Modify the 'employees' table to enforce stricter rules and add additional columns
ALTER TABLE employees
    ALTER COLUMN department_id SET NOT NULL,
    ALTER COLUMN start_date SET DEFAULT CURRENT_DATE,
    ADD COLUMN end_date DATE,
    ADD CONSTRAINT birth_check CHECK (birth_date < CURRENT_DATE);

ALTER TABLE employees
    RENAME COLUMN job_position TO position_title;

-- Task 3.1: Insert a batch of sample employee records for analysis
-- (Insert all employee rows here as shown previously)

-- Task 3.2: Insert values into the 'departments' table
INSERT INTO departments (department_id, department, division) VALUES
(1, 'Analytics', 'Business Intelligence'),
(2, 'Engineering', 'Tech'),
(3, 'Marketing', 'Sales'),
(4, 'Web', 'Tech'),
(5, 'Support', 'Customer Service');

-- Task 4: Perform various updates and queries for employee promotion, title changes, and salary adjustments
-- 4.1 Jack gets promoted
UPDATE employees
SET position_title = 'Senior SQL Analyst', salary = 7200
WHERE first_name = 'Jack' AND last_name = 'Franklin';

-- 4.2 Rename "Customer Support" to "Customer Specialist"
UPDATE employees
SET position_title = 'Customer Specialist'
WHERE position_title = 'Customer Support';

-- 4.3 6% raise to all SQL Analysts
UPDATE employees
SET salary = salary * 1.06
WHERE position_title IN ('SQL Analyst', 'Senior SQL Analyst');

-- 4.4 Average salary of SQL Analyst (excluding Senior)
SELECT ROUND(AVG(salary), 2)
FROM employees
WHERE position_title = 'SQL Analyst';

-- Task 5: Add derived columns and create a view to simplify employee reporting
-- 5.1 Manager name + is_active flag
SELECT
  e.emp_id,
  e.first_name,
  e.last_name,
  e.position_title,
  e.salary,
  CONCAT(m.first_name, ' ', m.last_name) AS manager,
  CASE WHEN e.end_date IS NULL THEN 'true' ELSE 'false' END AS is_active
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- 5.2 Create view for reuse
CREATE VIEW v_employees_info AS
SELECT
  e.emp_id,
  e.first_name,
  e.last_name,
  e.position_title,
  e.salary,
  CONCAT(m.first_name, ' ', m.last_name) AS manager,
  CASE WHEN e.end_date IS NULL THEN 'true' ELSE 'false' END AS is_active
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- Task 6: Calculate average salaries grouped by position
SELECT
  position_title,
  ROUND(AVG(salary), 2) AS avg_salary
FROM employees
GROUP BY position_title;

-- Task 7: Calculate average salaries grouped by department
SELECT
  d.department,
  ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department;

-- Task 8: Advanced salary analytics using window functions
-- 8.1 Salary + average by title
SELECT
  emp_id,
  first_name,
  last_name,
  position_title,
  salary,
  ROUND(AVG(salary) OVER (PARTITION BY position_title), 2) AS avg_position_salary
FROM employees
ORDER BY emp_id;

-- 8.2 Count of employees earning below avg for their title
SELECT COUNT(*) AS below_average_count
FROM (
  SELECT salary,
         AVG(salary) OVER (PARTITION BY position_title) AS avg_salary
  FROM employees
) sub
WHERE salary < avg_salary;

-- Task 9: Running total of salaries over time (not considering end dates)
SELECT
  start_date,
  salary,
  SUM(salary) OVER (ORDER BY start_date) AS running_total
FROM employees
WHERE start_date > '2018-12-31';

-- Task 10: Running salary total while accounting for employees who left
WITH active AS (
  SELECT start_date, salary FROM employees WHERE end_date IS NULL
),
left_job AS (
  SELECT end_date AS start_date, -salary AS salary FROM employees WHERE end_date IS NOT NULL
),
combined AS (
  SELECT * FROM active
  UNION ALL
  SELECT * FROM left_job
)
SELECT
  start_date,
  SUM(salary) OVER (ORDER BY start_date) AS running_total
FROM combined
WHERE start_date > '2018-12-31';

-- Task 11: Find top earners per role and refine the result by salary comparisons
-- 11.1 Top earners
WITH ranked AS (
  SELECT *, RANK() OVER (PARTITION BY position_title ORDER BY salary DESC) AS rnk
  FROM employees
)
SELECT emp_id, first_name, position_title, salary
FROM ranked
WHERE rnk = 1;

-- 11.2 Add average salary to each
WITH ranked AS (
  SELECT *,
         RANK() OVER (PARTITION BY position_title ORDER BY salary DESC) AS rnk,
         AVG(salary) OVER (PARTITION BY position_title) AS avg_salary
  FROM employees
)
SELECT emp_id, first_name, position_title, salary, ROUND(avg_salary, 2)
FROM ranked
WHERE rnk = 1;

-- 11.3 Remove employees whose salary equals avg (unique role holders)
WITH ranked AS (
  SELECT *,
         RANK() OVER (PARTITION BY position_title ORDER BY salary DESC) AS rnk,
         AVG(salary) OVER (PARTITION BY position_title) AS avg_salary
  FROM employees
)
SELECT emp_id, first_name, position_title, salary
FROM ranked
WHERE rnk = 1 AND salary != avg_salary;

-- Task 12: Aggregate salary and employee counts across organizational hierarchy
SELECT
  d.division,
  d.department,
  e.position_title,
  SUM(e.salary) AS total_salary,
  COUNT(*) AS num_employees,
  ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY GROUPING SETS (
  (d.division),
  (d.division, d.department),
  (d.division, d.department, e.position_title)
)
ORDER BY 1, 2, 3;

-- Task 13: Rank salaries within each department
SELECT
  e.emp_id,
  e.position_title,
  d.department,
  e.salary,
  RANK() OVER (PARTITION BY d.department ORDER BY salary DESC) AS salary_rank
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

-- Task 14: Identify the single highest earner in each department
WITH ranked AS (
  SELECT
    e.emp_id,
    e.position_title,
    d.department,
    e.salary,
    RANK() OVER (PARTITION BY d.department ORDER BY salary DESC) AS rnk
  FROM employees e
  JOIN departments d ON e.department_id = d.department_id
)
SELECT emp_id, position_title, department, salary
FROM ranked
WHERE rnk = 1;
