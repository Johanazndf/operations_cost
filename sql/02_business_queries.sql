USE operations_cost_optimization;

-- The operations table has one row per cleaned operation. Costs and issues are
-- child facts, so aggregate each child table by operation before joining.

-- BEGINNER: SELECT, WHERE, ORDER BY, LIMIT, DISTINCT
SELECT DISTINCT department FROM operations ORDER BY department;

SELECT operation_id, department, tasks_assigned, tasks_completed,
       productivity_score, status
FROM operations
WHERE status = 'Delayed'
ORDER BY productivity_score ASC
LIMIT 20;

-- INTERMEDIATE: COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING
SELECT
    department,
    COUNT(*) AS operations,
    SUM(tasks_completed) AS tasks_completed,
    SUM(tasks_assigned) AS tasks_assigned,
    SUM(tasks_completed) / NULLIF(SUM(tasks_assigned), 0) AS completion_rate,
    AVG(productivity_score) AS average_productivity,
    SUM(valid_overtime_hours) AS valid_overtime_hours
FROM operations
GROUP BY department
HAVING COUNT(*) >= 1000
ORDER BY completion_rate DESC;

SELECT
    cost_type,
    COUNT(*) AS cost_records,
    SUM(amount) AS total_cost,
    MIN(amount) AS minimum_cost,
    MAX(amount) AS maximum_cost,
    AVG(amount) AS average_cost
FROM costs
GROUP BY cost_type
ORDER BY total_cost DESC;

-- JOIN: aggregate costs before joining to operations to avoid row multiplication.
WITH cost_by_operation AS (
    SELECT operation_id, SUM(amount) AS total_cost
    FROM costs
    GROUP BY operation_id
)
SELECT
    o.department,
    SUM(c.total_cost) AS total_cost,
    SUM(o.tasks_completed) AS tasks_completed,
    SUM(c.total_cost) / NULLIF(SUM(o.tasks_completed), 0) AS cost_per_completed_task
FROM operations AS o
INNER JOIN cost_by_operation AS c ON c.operation_id = o.operation_id
GROUP BY o.department
ORDER BY total_cost DESC;

-- CASE: create target and investigation labels.
WITH monthly_actuals AS (
    SELECT
        department,
        operation_month,
        AVG(productivity_score) AS average_productivity,
        SUM(tasks_completed) / NULLIF(SUM(tasks_assigned), 0) * 100 AS completion_rate
    FROM operations
    GROUP BY department, operation_month
)
SELECT
    a.department,
    a.operation_month,
    a.average_productivity,
    t.productivity_target,
    CASE
        WHEN a.average_productivity >= t.productivity_target THEN 'Met productivity target'
        ELSE 'Below productivity target'
    END AS productivity_result,
    a.completion_rate,
    t.task_completion_target,
    CASE
        WHEN a.completion_rate >= t.task_completion_target THEN 'Met completion target'
        ELSE 'Below completion target'
    END AS completion_result
FROM monthly_actuals AS a
INNER JOIN targets AS t
    ON t.department = a.department AND t.target_month = a.operation_month;

-- SUBQUERY: departments above the overall cost-per-completed-task average.
WITH department_costs AS (
    SELECT o.department,
           SUM(c.amount) AS total_cost,
           SUM(o.tasks_completed) AS tasks_completed,
           SUM(c.amount) / NULLIF(SUM(o.tasks_completed), 0) AS cost_per_task
    FROM operations AS o
    INNER JOIN costs AS c ON c.operation_id = o.operation_id
    GROUP BY o.department
)
SELECT department, total_cost, tasks_completed, cost_per_task
FROM department_costs
WHERE cost_per_task > (SELECT AVG(cost_per_task) FROM department_costs)
ORDER BY cost_per_task DESC;

-- CTE: monthly costs and month-over-month change.
WITH monthly_costs AS (
    SELECT
        DATE_FORMAT(cost_date, '%Y-%m-01') AS month_start,
        SUM(amount) AS total_cost,
        SUM(CASE WHEN cost_type = 'Overtime' THEN amount ELSE 0 END) AS overtime_cost
    FROM costs
    GROUP BY DATE_FORMAT(cost_date, '%Y-%m-01')
)
SELECT month_start, total_cost, overtime_cost,
       total_cost - LAG(total_cost) OVER (ORDER BY month_start) AS month_over_month_change,
       AVG(total_cost) OVER (
           ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS three_month_average_cost
FROM monthly_costs
ORDER BY month_start;

-- WINDOW FUNCTIONS: ranking and running totals by department/month.
WITH department_month_costs AS (
    SELECT department, DATE_FORMAT(cost_date, '%Y-%m-01') AS month_start,
           SUM(amount) AS total_cost
    FROM costs
    GROUP BY department, DATE_FORMAT(cost_date, '%Y-%m-01')
), ranked AS (
    SELECT
        department,
        month_start,
        total_cost,
        ROW_NUMBER() OVER (PARTITION BY month_start ORDER BY total_cost DESC) AS row_number_in_month,
        RANK() OVER (PARTITION BY month_start ORDER BY total_cost DESC) AS cost_rank,
        DENSE_RANK() OVER (ORDER BY total_cost DESC) AS overall_dense_rank,
        SUM(total_cost) OVER (
            PARTITION BY department ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_department_cost
    FROM department_month_costs
)
SELECT *
FROM ranked
WHERE row_number_in_month <= 3
ORDER BY month_start, row_number_in_month;

-- TARGET VARIANCE: actual cost versus monthly department target.
WITH actuals AS (
    SELECT department, DATE_FORMAT(cost_date, '%Y-%m-01') AS month_start,
           SUM(amount) AS actual_cost
    FROM costs
    GROUP BY department, DATE_FORMAT(cost_date, '%Y-%m-01')
)
SELECT
    a.department,
    a.month_start,
    a.actual_cost,
    t.cost_target,
    a.actual_cost - t.cost_target AS cost_variance,
    CASE WHEN a.actual_cost > t.cost_target THEN 'Over target' ELSE 'At or below target' END AS target_status
FROM actuals AS a
INNER JOIN targets AS t
    ON t.department = a.department AND t.target_month = a.month_start
ORDER BY cost_variance DESC;

-- ISSUE ANALYSIS: volume and resolution time by department/type.
SELECT
    o.department,
    i.issue_type,
    COUNT(DISTINCT i.issue_id) AS issue_count,
    AVG(i.resolution_hours) AS average_resolution_hours,
    SUM(i.missing_resolution_flag) AS missing_resolution_count
FROM issues AS i
INNER JOIN operations AS o ON o.operation_id = i.operation_id
GROUP BY o.department, i.issue_type
ORDER BY issue_count DESC;

-- HIGH-COST / LOW-PRODUCTIVITY INVESTIGATION CANDIDATES.
WITH department_metrics AS (
    SELECT
        o.department,
        SUM(c.amount) AS total_cost,
        AVG(o.productivity_score) AS average_productivity,
        SUM(o.tasks_completed) AS tasks_completed
    FROM operations AS o
    INNER JOIN costs AS c ON c.operation_id = o.operation_id
    GROUP BY o.department
), thresholds AS (
    SELECT AVG(total_cost) AS average_cost,
           AVG(average_productivity) AS average_productivity
    FROM department_metrics
)
SELECT m.*,
       CASE
           WHEN m.total_cost > t.average_cost
            AND m.average_productivity < t.average_productivity
           THEN 'High-cost / lower-productivity investigation'
           ELSE 'Other'
       END AS investigation_label
FROM department_metrics AS m
CROSS JOIN thresholds AS t
ORDER BY m.total_cost DESC;