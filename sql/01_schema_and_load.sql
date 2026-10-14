CREATE DATABASE IF NOT EXISTS operations_cost_optimization
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE operations_cost_optimization;

DROP TABLE IF EXISTS issues;
DROP TABLE IF EXISTS costs;
DROP TABLE IF EXISTS operations;
DROP TABLE IF EXISTS targets;
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    employee_id VARCHAR(10) NOT NULL,
    employee_name VARCHAR(80) NOT NULL,
    department VARCHAR(50) NOT NULL,
    role VARCHAR(80) NOT NULL,
    location VARCHAR(50) NOT NULL,
    joining_date DATE NOT NULL,
    employment_type VARCHAR(30) NOT NULL,
    PRIMARY KEY (employee_id),
    INDEX ix_employee_department (department)
);

CREATE TABLE operations (
    operation_id VARCHAR(12) NOT NULL,
    employee_id VARCHAR(10) NOT NULL,
    operation_date DATE NOT NULL,
    department VARCHAR(50) NOT NULL,
    hours_worked DECIMAL(8, 2) NULL,
    overtime_hours DECIMAL(8, 2) NULL,
    tasks_assigned INT NOT NULL,
    tasks_completed INT NOT NULL,
    productivity_score DECIMAL(8, 2) NULL,
    status VARCHAR(30) NOT NULL,
    department_source VARCHAR(50) NOT NULL,
    employee_department VARCHAR(50) NULL,
    department_mismatch_flag TINYINT NOT NULL,
    negative_overtime_flag TINYINT NOT NULL,
    hours_above_24_flag TINYINT NOT NULL,
    completion_over_assignment_flag TINYINT NOT NULL,
    missing_hours_flag TINYINT NOT NULL,
    missing_productivity_flag TINYINT NOT NULL,
    productivity_above_100_flag TINYINT NOT NULL,
    valid_overtime_hours DECIMAL(8, 2) NULL,
    completion_rate DECIMAL(10, 6) NOT NULL,
    operation_month DATE NOT NULL,
    department_month_key VARCHAR(80) NOT NULL,
    PRIMARY KEY (operation_id),
    CONSTRAINT fk_operations_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    INDEX ix_operations_employee (employee_id),
    INDEX ix_operations_department_month (department, operation_month),
    INDEX ix_operations_date (operation_date)
);

CREATE TABLE costs (
    cost_id VARCHAR(12) NOT NULL,
    operation_id VARCHAR(12) NOT NULL,
    cost_date DATE NOT NULL,
    department VARCHAR(50) NOT NULL,
    cost_type VARCHAR(40) NOT NULL,
    amount DECIMAL(14, 4) NULL,
    department_source VARCHAR(50) NOT NULL,
    missing_amount_flag TINYINT NOT NULL,
    high_cost_flag TINYINT NOT NULL,
    cost_month DATE NOT NULL,
    department_month_key VARCHAR(80) NOT NULL,
    PRIMARY KEY (cost_id),
    CONSTRAINT fk_costs_operation FOREIGN KEY (operation_id) REFERENCES operations(operation_id),
    INDEX ix_costs_operation (operation_id),
    INDEX ix_costs_department_type (department, cost_type),
    INDEX ix_costs_date (cost_date)
);

CREATE TABLE targets (
    department VARCHAR(50) NOT NULL,
    target_month DATE NOT NULL,
    productivity_target DECIMAL(8, 2) NOT NULL,
    cost_target DECIMAL(14, 4) NOT NULL,
    utilization_target DECIMAL(8, 2) NOT NULL,
    task_completion_target DECIMAL(8, 2) NOT NULL,
    department_month_key VARCHAR(80) NOT NULL,
    PRIMARY KEY (department, target_month),
    INDEX ix_targets_month (target_month)
);

CREATE TABLE issues (
    issue_id VARCHAR(12) NOT NULL,
    operation_id VARCHAR(12) NOT NULL,
    issue_type VARCHAR(50) NOT NULL,
    priority VARCHAR(20) NOT NULL,
    resolution_hours DECIMAL(8, 2) NULL,
    status VARCHAR(20) NOT NULL,
    missing_resolution_flag TINYINT NOT NULL,
    PRIMARY KEY (issue_id),
    CONSTRAINT fk_issues_operation FOREIGN KEY (operation_id) REFERENCES operations(operation_id),
    INDEX ix_issues_operation (operation_id),
    INDEX ix_issues_type_status (issue_type, status)
);

LOAD DATA LOCAL INFILE 'E:/sla/data/clean/employees_clean.csv'
INTO TABLE employees
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'E:/sla/data/clean/operations_clean.csv'
INTO TABLE operations
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(
    operation_id, employee_id, operation_date, department, hours_worked,
    overtime_hours, tasks_assigned, tasks_completed, productivity_score,
    status, department_source, employee_department, department_mismatch_flag,
    negative_overtime_flag, hours_above_24_flag, completion_over_assignment_flag,
    missing_hours_flag, missing_productivity_flag, productivity_above_100_flag,
    valid_overtime_hours, completion_rate, operation_month, department_month_key
);

LOAD DATA LOCAL INFILE 'E:/sla/data/clean/costs_clean.csv'
INTO TABLE costs
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'E:/sla/data/clean/targets_clean.csv'
INTO TABLE targets
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'E:/sla/data/clean/issues_clean.csv'
INTO TABLE issues
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

SELECT 'employees' AS table_name, COUNT(*) AS row_count FROM employees
UNION ALL SELECT 'operations', COUNT(*) FROM operations
UNION ALL SELECT 'costs', COUNT(*) FROM costs
UNION ALL SELECT 'targets', COUNT(*) FROM targets
UNION ALL SELECT 'issues', COUNT(*) FROM issues;