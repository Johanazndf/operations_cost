# Operations and Cost Optimization Analytics

## Project overview

This project investigates where recorded operational costs are concentrated and
which departments or time periods should be examined for possible efficiency
improvements.

The analysis connects cost, workload, productivity, overtime, operational
issues, and monthly targets. It identifies evidence-based investigation
priorities rather than claiming guaranteed savings or causal relationships.

## Operational problem investigated

The project answers these questions:

- Which departments have the highest recorded operational costs?
- Which cost categories contribute most to total cost?
- How do cost, workload, productivity, overtime, and issue volume relate?
- Which departments or department-months are below performance targets?
- Where should management investigate spending, staffing, workload, or process
  problems?

## Data model

The project uses five source tables:

| Table | Role | Grain |
|---|---|---|
| `employees` | Employee dimension | One row per employee |
| `operations` | Main operational fact | One row per operation |
| `costs` | Cost transaction fact | One row per cost record |
| `targets` | Target table | One row per department and month |
| `issues` | Issue fact | One row per operational issue |

The main relationships are:

```text
employees 1 ---- many operations 1 ---- many costs
                         |
                         +------------ many issues

targets department + month ---- operations and costs
```

Costs and issues are separate child facts. They are aggregated independently
before being joined to operations so that one-to-many relationships do not
inflate totals.

## Tools used

- **Python/Pandas:** data profiling, cleaning, validation, and aggregation
- **Excel:** formula-driven analysis, target checks, and PivotTables
- **MySQL:** relational schema and business analysis queries
- **Power BI:** three-page operational and cost reporting
- **DAX:** reusable Power BI KPI measures

## Repository structure

```text
clean_dataset.py              Creates cleaned analytical tables
profile_dataset.py            Profiles source data and quality issues
generate_analysis.py          Generates KPI and summary outputs
build_excel_workbook.ps1      Builds the Excel workbook

employees.csv                 Employee source data
operations.csv                Operations source data
costs.csv                     Cost source data
targets.csv                   Monthly target source data
issues.csv                    Issue source data

data/clean/                   Cleaned tables used by analysis tools
data/quarantine/              Records retained for data-quality review
analysis/                     Generated KPI and summary outputs
sql/                          MySQL schema, load script, and business queries

Operations_Cost_Optimization_Analytics.xlsx
                              Excel analysis workbook
powerbi_measures.dax          Power BI measures
```

## Data-cleaning approach

The cleaning process:

- Parses and standardizes date fields.
- Standardizes department names using the employee master.
- Keeps source department values for auditability.
- Removes exact duplicate rows.
- Quarantines conflicting operation IDs instead of selecting a record
  arbitrarily.
- Creates month, department-month, completion-rate, and quality flags.
- Preserves missing and suspicious values rather than fabricating replacements.
- Excludes negative overtime from valid overtime totals while retaining it as a
  data-quality issue.

Important quality findings include missing cost amounts, missing resolution
times, negative overtime, completed tasks greater than assigned tasks, and
productivity values above 100.

## KPIs

| KPI | Definition |
|---|---|
| Total operational cost | Sum of non-missing cost amounts |
| Total tasks completed | Sum of completed tasks |
| Task completion rate | Total completed tasks divided by total assigned tasks |
| Average productivity | Mean of non-missing productivity scores |
| Valid overtime hours | Sum of overtime hours greater than or equal to zero |
| Overtime cost | Cost where `cost_type = 'Overtime'` |
| Cost per completed task | Total recorded cost divided by completed tasks |
| Cost variance | Actual cost minus the department-month cost target |
| Productivity variance | Average productivity minus the productivity target |
| Issue volume | Count of unique issue IDs |
| Average resolution hours | Mean of non-missing resolution times |

Missing values are not automatically treated as zero. The relevant records
are excluded from calculations and reported separately.

## SQL analysis

The main SQL queries are in
[`sql/02_business_queries.sql`](sql/02_business_queries.sql). They cover:

- Department and status exploration
- Workload, completion, productivity, and overtime by department
- Cost totals by cost type
- Cost per completed task
- Productivity and completion target comparisons
- Monthly cost trends and month-over-month changes
- Department-month cost rankings and running totals
- Actual cost versus target
- Issue volume and resolution time
- High-cost and lower-productivity investigation candidates

The SQL uses CTEs, conditional aggregation, `CASE`, subqueries, `LAG`,
`ROW_NUMBER`, `RANK`, `DENSE_RANK`, and windowed running totals.

## Main findings

- **Operations** had the largest recorded cost and overtime burden:
  approximately 11.78 million in cost and 258,157 completed tasks.
- **Software** and **Equipment** were the largest recorded cost categories.
- **IT** had the highest recorded cost per completed task at approximately
  92.74, making it a priority for further investigation.
- Overtime cost was material at approximately 4.68 million, but overtime was
  not the largest cost category.
- Productivity was below target in 25 of 72 department-month combinations.
- Operations and Customer Support had the largest issue volumes.
- All 72 department-month cost comparisons were above the supplied target,
  suggesting that target units or grain should be validated before interpreting
  this as 72 genuine failures.

These findings are descriptive associations and should not be interpreted as
proof that a department is inefficient without reviewing workload mix,
complexity, staffing, and data quality.

## Recommendations

1. **Investigate Operations first** by cost type, month, location, employee
   type, workload, overtime, delays, and issue volume.
2. **Review IT cost efficiency** by comparing task complexity, staffing, cost
   composition, and productivity with other departments.
3. **Review Software and Equipment spending** for recurring purchases, asset
   utilization, vendor terms, and high-value transactions.
4. **Analyze overtime alongside issues and delays** to determine whether extra
   hours are associated with specific operational problems.
5. **Validate the target definitions and units** before using cost variances for
   performance decisions.

## Report guardrails

- Recorded cost is not the same as confirmed savings opportunity.
- Scatter plots show associations, not causation.
- Missing resolution hours are not zero.
- Negative overtime remains visible as a quality issue but is excluded from
  valid overtime hours.
- Cost and issue facts must not be directly joined without aggregation.

## Supporting documentation

All project documentation and SQL setup instructions have been consolidated
into this README.

---

# Consolidated project documentation

---

## BUSINESS_FINDINGS

# Evidence-Based Business Findings

All figures below come from the cleaned five-table dataset and are descriptive associations, not guaranteed savings.

## Finding 1: Operations has the largest recorded cost and overtime burden

**Finding:** Operations is the largest recorded-cost department.

**Evidence:** Recorded cost is 11,783,176.97, valid overtime is 9,356.88 hours, and overtime cost is 1,427,099.24. Operations also has 258,157 completed tasks.

**Business impact:** Operations is the first place to investigate cost composition, workload mix, staffing, and overtime drivers because it has the largest absolute exposure.

**Possible action to investigate:** Break Operations cost down by cost type, month, location, and workload before proposing process or staffing changes.

## Finding 2: Software and equipment are the largest cost categories

**Finding:** Software and Equipment together are the largest recorded cost categories.

**Evidence:** Software totals 8,702,926.81, or 22.22% of recorded cost; Equipment totals 8,079,389.89, or 20.63%.

**Business impact:** These categories should be reviewed for recurring purchases, asset utilization, vendor terms, and unusual transactions.

**Possible action to investigate:** Review the highest-value records and recurring monthly patterns with procurement and finance owners.

## Finding 3: IT has the highest cost per completed task

**Finding:** IT has the highest recorded cost per completed task among departments.

**Evidence:** IT records 92.74 per completed task, compared with 33.40 for Customer Support and 42.80 for Logistics. IT average productivity is 90.72, below Logistics at 91.14.

**Business impact:** IT is a priority for understanding cost mix, task complexity, staffing, and whether the task count is comparable across departments.

**Possible action to investigate:** Segment IT by cost type, role, location, and operation status before interpreting the ratio as inefficiency.

## Finding 4: Overtime is material but not the largest cost category

**Finding:** Overtime is a significant recorded cost and workload signal.

**Evidence:** Overtime cost is 4,680,774.57 and valid overtime is 33,249.29 hours. Overtime is 11.95% of recorded cost.

**Business impact:** Overtime reduction may be worth investigating, but overtime is not the first cost category by total value.

**Possible action to investigate:** Compare overtime by department, month, employee type, location, and delayed operations; validate negative overtime records separately.

## Finding 5: Cost per completed task varies by month

**Finding:** Recorded cost efficiency changes across the year.

**Evidence:** January has the highest recorded cost at 3,434,515.52; June has the lowest at 2,987,006.86. Cost per completed task ranges from 43.90 in April to 49.71 in September.

**Business impact:** Monthly changes may reflect workload mix, cost timing, large transactions, or staffing patterns.

**Possible action to investigate:** Compare monthly cost type mix, high-cost records, completed tasks, and department composition before attributing the change to efficiency.

## Finding 6: Productivity target misses are concentrated in specific department-months

**Finding:** Productivity targets are not consistently achieved.

**Evidence:** 25 of 72 department-month rows are below productivity target. The largest gaps include Logistics in September, 90.79 versus a 95.0 target, and IT in May, 90.60 versus a 94.5 target.

**Business impact:** These periods are candidates for operational review, especially where overtime, issue volume, or high cost occurs at the same time.

**Possible action to investigate:** Compare staffing, workload, overtime, issue mix, and missing productivity records for the affected months.

## Finding 7: Cost targets require validation before business interpretation

**Finding:** Every 72 department-month rows is above the supplied cost target.

**Evidence:** The actual monthly department cost values are generally near 1 million, while the target values are generally tens of thousands.

**Business impact:** This pattern may indicate a target-unit mismatch, target grain issue, or intentionally aggressive targets. It should not be presented as 72 genuine operational failures until confirmed.

**Possible action to investigate:** Confirm whether targets are monthly department totals, per-operation targets, or another unit, and confirm whether cost records are comparable to target values.

## Finding 8: Operations and Customer Support have the largest issue volumes

**Finding:** Issue volume is concentrated in Operations and Customer Support.

**Evidence:** Operations has 2,233 issues and Customer Support has 1,737. Process Delay is the most common issue type with 1,926 issues; Quality Issue has the highest average resolution time among issue types at 16.47 hours.

**Business impact:** These areas are useful candidates for root-cause review, but issue volume alone does not prove higher cost or poorer performance.

**Possible action to investigate:** Link issue hotspots to department-month cost and productivity, then review representative issue records with process owners.

## Data limitations

- 60 cost records have missing amounts and are not imputed.
- 45 issue records have missing resolution times and are excluded from duration averages.
- 25 negative overtime rows are preserved and excluded from valid overtime totals.
- 3,432 operations have tasks completed above tasks assigned and remain flagged.
- Two conflicting operation IDs are quarantined rather than selected arbitrarily.

---

## DATA_PROFILE

# Five-Table Dataset Profile

The profile was generated with `profile_dataset.py` using Pandas only. No replacement data was created.

## Table roles and grain

| Table | Rows | Columns | Role | Likely key |
|---|---:|---:|---|---|
| employees | 250 | 7 | Employee dimension | `employee_id` |
| operations | 30,120 | 10 | Main operational fact; one row per operation record | `operation_id` after duplicate handling |
| costs | 20,070 | 6 | Cost transaction fact; multiple costs can belong to one operation | `cost_id` |
| targets | 72 | 6 | Monthly department target table | (`department`, `month`) |
| issues | 8,000 | 6 | Issue fact; multiple issues can belong to one operation | `issue_id` |

## Relationships

- `employees.employee_id` -> `operations.employee_id`: one employee to many operations. All operation employee IDs matched the employee table.
- `operations.operation_id` -> `costs.operation_id`: one operation to many cost records. All cost operation IDs matched the operations table.
- `operations.operation_id` -> `issues.operation_id`: one operation to many issues. All issue operation IDs matched the operations table.
- `targets.department + targets.month` is unique and joins to department-month operational summaries after department normalization.
- `operations` is the central operational fact. `costs` and `issues` are separate child facts and must be aggregated before joining to operations to avoid multiplying rows.

## Dates

- Employees joining dates: 2021-01-03 through 2025-11-18; 0 invalid dates.
- Operations and costs: 2025-01-01 through 2025-12-31; 0 invalid dates.
- Targets cover 2025-01-01 through 2025-12-01; 12 months for each of 6 departments.

## Source quality findings

| Table | Finding | Count |
|---|---|---:|
| operations | Exact duplicate rows | 118 |
| operations | Duplicate operation IDs | 120 duplicate rows beyond first; 2 IDs remain conflicting after exact deduplication |
| operations | Missing `hours_worked` | 120 |
| operations | Missing `productivity_score` | 100 |
| operations | Negative `overtime_hours` | 25 |
| operations | `hours_worked > 24` | 35 |
| operations | `tasks_completed > tasks_assigned` | 3,432 |
| operations | Department spelling/case variants | 204 mismatches against employee master |
| costs | Exact duplicate rows | 70 |
| costs | Missing `amount` | 60 |
| costs | Very high amount above the observed 99th percentile of 6,780.31 | 201 |
| issues | Missing `resolution_hours` | 45 |

Other observations:

- `costs.amount` is always non-negative and ranges from 179.73 to 27,417.14.
- `resolution_hours` is non-negative and ranges from 0.9 to 172.3 among non-missing values.
- Operation productivity ranges from 52.9 to 110.0. Values above 100 are flagged for interpretation, not automatically treated as invalid.
- Operation status values are `Completed`, `In Progress`, and `Delayed`.
- Cost types are Overtime, Transportation, Equipment, Maintenance, Software, Other, Utilities, and Training.
- Issue resolution time is missing for 39 Resolved, 4 Open, and 2 Escalated issues; missingness is not proof of zero time.

---

## DATA_QUALITY_DECISIONS

# Data Quality Decisions

| Problem | Why it matters | Handling decision |
|---|---|---|
| Exact duplicate operation rows | Inflates tasks, hours, productivity, and cost joins if retained | Remove exact duplicate rows in the clean analytical copy and record the count. |
| Two conflicting duplicate operation IDs | There is no defensible basis for choosing one record | Quarantine all rows for those IDs; exclude them from the primary fact table and retain the quarantine file for investigation. |
| Exact duplicate cost rows | Inflates total cost | Remove exact duplicate rows; do not aggregate duplicates as separate charges. |
| Department case/spacing variants | Splits the same department in groupings and breaks target joins | Standardize through a case-insensitive lookup to the employee master; retain mismatch flags. |
| Missing hours | Prevents hour-based averages for those records | Preserve missing values and exclude only from hour-specific averages; do not impute without a business rule. |
| Hours above 24 | May represent a data-entry problem or multi-shift record | Preserve and flag for investigation; do not delete automatically. |
| Negative overtime | Invalid for an overtime-hours KPI | Preserve raw value and flag it; exclude negative values from valid-overtime KPI totals rather than silently converting them to zero. |
| Completed tasks greater than assigned | Distorts completion-rate interpretation | Preserve both raw measures and flag the record; report the anomaly rate separately. |
| Missing productivity | Prevents productivity averages for those records | Preserve missing values and use non-missing observations only in averages. |
| Missing cost amount | Total cost would be understated if silently treated as zero | Preserve the record, exclude missing amount from numeric sums, and report missing-cost-record count. |
| Extreme cost amount | May be a legitimate large charge or an entry error | Flag values above the observed 99th percentile; investigate with source owner before exclusion. |
| Missing issue resolution time | Cannot support a duration KPI for that issue | Preserve the issue and exclude it from average-resolution calculations; do not replace with zero. |
| Productivity above 100 | Could reflect a score scale rather than an error | Preserve and flag for documentation; do not cap at 100 without a confirmed definition. |

The cleaned dataset is designed for transparent analysis, not silent correction. Every excluded row has a reason and a quarantine or quality-check record.

---

## INTERVIEW_PREPARATION

# Interview Preparation

## SQL

1. **Question:** What is the grain of the operations table? **Testing:** Data modeling. **Answer:** One cleaned row represents one operation record identified by `operation_id`. **Follow-up:** Why not use employee as the key? **Verbal:** “An employee has many operations, so employee_id is a foreign key, not the fact key.”
2. **Question:** Why aggregate costs before joining to operations? **Testing:** Join correctness. **Answer:** Costs are one-to-many; joining raw costs to other child facts can multiply rows and overstate totals. **Follow-up:** How did you prevent it? **Verbal:** “I grouped costs by operation_id first, then joined the one-row-per-operation result.”
3. **Question:** What does `COUNT(DISTINCT issue_id)` do? **Testing:** Counting. **Answer:** It counts unique issues rather than all joined rows. **Follow-up:** When can COUNT(*) be unsafe? **Verbal:** “After a one-to-many join, COUNT(*) may count duplicated parent rows.”
4. **Question:** Why use `NULLIF` in cost per task? **Testing:** Defensive SQL. **Answer:** It prevents division-by-zero errors when completed tasks are zero. **Follow-up:** What result does it produce? **Verbal:** “The denominator becomes NULL, so the ratio is NULL rather than an invalid error.”
5. **Question:** What is a CTE? **Testing:** Query structure. **Answer:** A named temporary result used inside one query to make steps readable. **Follow-up:** Is it always materialized? **Verbal:** “Not necessarily; the optimizer decides, but logically it defines a reusable query step.”
6. **Question:** How does CASE help this project? **Testing:** Business labeling. **Answer:** It converts numeric comparisons into labels such as cost over target or productivity below target. **Follow-up:** Where else could it be used? **Verbal:** “For quality bands, target status, or high-cost investigation flags.”
7. **Question:** What does LAG return? **Testing:** Window functions. **Answer:** The prior row’s value within an ordered result. **Follow-up:** Why order by month? **Verbal:** “To compare each month with the immediately prior month.”
8. **Question:** Difference between RANK and DENSE_RANK? **Testing:** Ranking. **Answer:** RANK leaves gaps after ties; DENSE_RANK does not. **Follow-up:** Which would you use for cost tiers? **Verbal:** “DENSE_RANK when I want consecutive tier numbers.”
9. **Question:** What does SUM() OVER do? **Testing:** Window aggregation. **Answer:** It calculates an aggregate while retaining row detail, such as a running cost total. **Follow-up:** How do you define a running total? **Verbal:** “Partition if needed, order by month, and use unbounded preceding through current row.”
10. **Question:** Why use a subquery for average cost per task? **Testing:** Layered aggregation. **Answer:** First calculate the department ratio, then compare each department to the average of those ratios. **Follow-up:** Why not average raw cost rows? **Verbal:** “That would answer a different question and could weight departments incorrectly.”

## MySQL and database design

1. **Question:** What are the primary keys? **Testing:** Schema design. **Answer:** employee_id, operation_id, cost_id, issue_id, and department plus month for targets. **Follow-up:** Why is operation_id not a cost key? **Verbal:** “One operation can have multiple cost records.”
2. **Question:** What foreign keys did you use? **Testing:** Referential integrity. **Answer:** Operations references employees; costs and issues reference operations. **Follow-up:** What does a foreign key prevent? **Verbal:** “It prevents child rows from referencing missing parent keys.”
3. **Question:** Why index department and month? **Testing:** Performance. **Answer:** They are common filters and grouping fields for target and monthly analysis. **Follow-up:** What is the tradeoff? **Verbal:** “Indexes improve reads but add storage and write maintenance.”
4. **Question:** Why keep costs and issues separate? **Testing:** Normalization. **Answer:** They are separate child facts with different grains. **Follow-up:** What happens if one wide table combines them? **Verbal:** “Repeated combinations can inflate totals.”
5. **Question:** What would you validate after loading? **Testing:** ETL controls. **Answer:** Row counts, unique keys, null keys, foreign-key matches, and duplicate counts. **Follow-up:** What row counts do you expect? **Verbal:** “29,998 cleaned operations, 20,000 cleaned costs, 72 targets, and 8,000 issues.”

## Excel

1. **Question:** Why use SUMIFS here? **Testing:** Practical analysis. **Answer:** It calculates cost or tasks for a department, date range, or cost type using multiple criteria. **Follow-up:** How did you calculate overtime cost? **Verbal:** “SUMIFS on amount where cost_type equals Overtime.”
2. **Question:** Why use COUNTIFS? **Testing:** Quality/KPI formulas. **Answer:** It counts flagged missing or abnormal records under conditions. **Follow-up:** Give an example. **Verbal:** “COUNTIFS counts operations where the missing-productivity flag is 1.”
3. **Question:** Why use AVERAGEIFS? **Testing:** Conditional averages. **Answer:** It calculates productivity for a selected department or month while ignoring blank productivity values. **Follow-up:** What is the missing-value risk? **Verbal:** “The result describes observed scores, so I report missingness separately.”
4. **Question:** Why use XLOOKUP? **Testing:** Lookup skills. **Answer:** It retrieves a related location or target from a key without relying on column position. **Follow-up:** What happens when there is no match? **Verbal:** “I return a visible ‘Not found’ result for investigation.”
5. **Question:** Why use a PivotTable? **Testing:** Excel judgment. **Answer:** It supports fast interactive cost breakdowns by department and cost type without duplicating the Power BI report. **Follow-up:** What did you add around it? **Verbal:** “I added formula-based KPIs, monthly targets, and conditional formatting.”

## Pandas

1. **Question:** Why use `drop_duplicates()`? **Testing:** Cleaning judgment. **Answer:** Only exact duplicate rows were removed; conflicting operation IDs were quarantined. **Follow-up:** Why not drop duplicate keys blindly? **Verbal:** “Two IDs had conflicting records, so selecting one would invent certainty.”
2. **Question:** Why standardize department names? **Testing:** Data quality. **Answer:** Case and whitespace variants split groups and broke target joins. **Follow-up:** What was the reference? **Verbal:** “The employee master supplied the canonical department values.”
3. **Question:** Why preserve missing values? **Testing:** Statistical integrity. **Answer:** Imputing hours, costs, productivity, or resolution time without a business rule would fabricate data. **Follow-up:** How are they handled in KPIs? **Verbal:** “Relevant averages and sums exclude missing values, and missing counts are reported.”
4. **Question:** How did you avoid inflated joins? **Testing:** Pandas relationships. **Answer:** I aggregated costs by operation before merging them to operations and merged issues separately. **Follow-up:** What validation did you use? **Verbal:** “I used merge validation and checked row counts and key uniqueness.”
5. **Question:** How did you create monthly analysis? **Testing:** Date handling. **Answer:** I converted date columns with `pd.to_datetime` and derived a month period/timestamp. **Follow-up:** Why not group by the original string? **Verbal:** “Date types support reliable sorting, filtering, and month calculations.”

## Power BI and DAX

1. **Question:** Why are costs and issues separate facts? **Testing:** Semantic modeling. **Answer:** They have different grains and should be aggregated independently. **Follow-up:** What relationship direction did you use? **Verbal:** “Single-direction parent-to-child relationships.”
2. **Question:** How is Total Cost calculated? **Testing:** DAX basics. **Answer:** `SUM(Costs[amount])`. **Follow-up:** What about missing amounts? **Verbal:** “Missing values are not imputed and are counted with a quality measure.”
3. **Question:** How is Completion Rate calculated? **Testing:** DIVIDE. **Answer:** `DIVIDE([Total Tasks Completed], [Total Tasks Assigned])`. **Follow-up:** Why DIVIDE? **Verbal:** “It safely handles a zero denominator.”
4. **Question:** What does CALCULATE do in Overtime Cost? **Testing:** Filter context. **Answer:** It evaluates Total Cost under the filter where cost_type is Overtime. **Follow-up:** How does a slicer affect it? **Verbal:** “The overtime filter combines with the current report context.”
5. **Question:** Why create a department-month key? **Testing:** Relationship design. **Answer:** Targets are unique at department-month grain, so the key supports reliable target comparisons. **Follow-up:** What would happen without it? **Verbal:** “A department-only join would match a full year of targets to each row.”

## Business and analytics

1. **Question:** What is the largest recorded cost driver? **Testing:** Evidence use. **Answer:** Operations has the largest department total; Software is the largest cost category. **Follow-up:** Does that prove inefficiency? **Verbal:** “No, it identifies where to investigate, not causation.”
2. **Question:** Why is IT a priority area? **Testing:** Ratio interpretation. **Answer:** IT has the highest recorded cost per completed task at 92.74 and productivity of 90.72. **Follow-up:** What would you check next? **Verbal:** “Task mix, cost type, staffing, location, and workload comparability.”
3. **Question:** How would you explain all cost targets being missed? **Testing:** Critical thinking. **Answer:** The actuals are near one million per department-month while targets are tens of thousands, suggesting a possible unit or definition mismatch. **Follow-up:** Would you report it as failure? **Verbal:** “I would validate the target definition first.”
4. **Question:** What is a responsible cost-optimization recommendation? **Testing:** Business judgment. **Answer:** Investigate Software and Equipment transactions, Operations overtime, and IT cost per task before proposing changes. **Follow-up:** Why not promise savings? **Verbal:** “The dataset has recorded costs but no causal or savings baseline.”
5. **Question:** How do issues support the operational story? **Testing:** Synthesis. **Answer:** Operations and Customer Support have the highest issue volumes, and Process Delay is the most common type. **Follow-up:** What is the limitation? **Verbal:** “Issue volume does not alone prove cost impact; I would link it to month and department metrics.”

---

## KPI_FRAMEWORK

# KPI Framework

All KPIs use the cleaned tables and preserve the source grain. Costs and issues are aggregated by `operation_id` before joining to operations so one-to-many relationships do not inflate totals.

| KPI | Formula | Business meaning | Caveat |
|---|---|---|---|
| Total Operational Cost | Sum of non-missing `costs.amount` | Recorded cost captured in the cost table | Missing amounts are reported separately, not treated as zero in data quality analysis. |
| Total Tasks Completed | Sum of `operations.tasks_completed` | Work completed in the period | Includes records flagged where completed exceeds assigned. |
| Task Completion Rate | Total completed / total assigned | Overall workload completion | Anomaly records are retained and reported. |
| Average Productivity | Mean non-missing `productivity_score` | Average recorded productivity score | Values above 100 are preserved and flagged because the score scale is not documented. |
| Total Valid Overtime Hours | Sum of overtime hours >= 0 | Overtime volume for KPI reporting | Negative overtime is retained as a quality issue and excluded from this KPI. |
| Overtime Cost | Sum of cost records where `cost_type = Overtime` | Recorded overtime-related spend | Missing cost amounts are not imputed. |
| Cost per Completed Task | Total cost / total completed tasks | Cost efficiency proxy | It is based on recorded cost and task measures, not causal savings. |
| Cost vs Target | Actual cost - monthly department cost target | Positive values indicate target overrun | Requires department normalization and month alignment. |
| Productivity vs Target | Actual average productivity - target | Positive values indicate above-target score | Missing productivity rows are excluded from the average. |
| Issue Volume | Count of issue IDs | Operational issue burden | Issues linked to quarantined operations are retained but have no clean department join. |
| Average Resolution Hours | Mean non-missing resolution hours | Typical recorded resolution duration | Missing durations are not treated as zero. |

---

## POWER_BI_MODEL_AND_REPORT

# Power BI Model and Three-Page Report

## Model setup

Import these cleaned files from `data/clean/`:

- `employees_clean.csv`
- `operations_clean.csv`
- `costs_clean.csv`
- `targets_clean.csv`
- `issues_clean.csv`

Create these single-direction relationships:

| From | To | Cardinality | Reason |
|---|---|---|---|
| Employees[employee_id] | Operations[employee_id] | 1 to many | Employee attributes describe operation records. |
| Operations[operation_id] | Costs[operation_id] | 1 to many | One operation can have multiple cost records. |
| Operations[operation_id] | Issues[operation_id] | 1 to many | One operation can have multiple issues. |
| Targets[department_month_key] | Operations[department_month_key] | 1 to many | Department-month target filters operations. |
| Targets[department_month_key] | Costs[department_month_key] | 1 to many | Department-month target filters costs. |

Do not directly join costs and issues. They are sibling child facts and would multiply rows. Use measures that aggregate each table independently.

## Page 1: Operations Overview

Purpose: answer whether workload, completion, productivity, cost, and overtime are moving together.

Use these KPI cards:

- Total Cost
- Total Tasks Completed
- Task Completion Rate
- Average Productivity
- Cost per Completed Task
- Valid Overtime Hours

Use these visuals:

1. Line chart: Month and Total Cost, with Overtime Cost as a second series. Question: how does recorded cost change over time?
2. Clustered bar chart: Department and Total Tasks Completed. Question: which departments carry the most completed workload?
3. Combo chart: Department with Average Productivity and Task Completion Rate. Question: which departments combine productivity and completion performance?
4. Matrix: Department and Month with Cost, Productivity, Completion Rate, and target variance. Question: where are operational results above or below target?

Useful slicers: Month, Department, Location, Employment Type.

## Page 2: Cost Optimization

Purpose: identify recorded-cost concentration and investigation priorities, not guaranteed savings.

Use these visuals:

1. Bar chart: Cost Type and Total Cost. Question: which cost categories contribute most?
2. Bar chart: Department and Total Cost. Question: which departments have the largest recorded cost?
3. Line chart: Month and Total Cost. Question: which months show cost increases?
4. Scatter chart: Department with Total Cost on X, Average Productivity on Y, and Cost per Completed Task as size. Question: which areas are high-cost with comparatively lower productivity?
5. Matrix: Department and Cost Type with Total Cost, Overtime Cost, and high-cost-record count. Question: where should cost records be investigated?

Useful slicers: Cost Type, Department, Month, Location.

## Page 3: Operational Performance

Purpose: connect workload, overtime, issues, resolution time, and target achievement.

Use these visuals:

1. Combo chart: Department with Tasks Assigned, Tasks Completed, and Completion Rate. Question: where is workload completion weakest?
2. Bar chart: Department and Valid Overtime Hours. Question: where is overtime concentrated?
3. Bar chart: Issue Type and Issue Count. Question: which issue types create the most volume?
4. Matrix: Department and Issue Type with Issue Count and Average Resolution Hours. Question: which teams and issue types need operational investigation?
5. Scatter chart: Department with Issue Count on X, Average Resolution Hours on Y, and Total Cost as size. Question: which areas combine issue burden, slower resolution, and high recorded cost?
6. Target table: Department-month with Cost Variance, Productivity Variance, and Target Status. Question: which targets are missed?

Useful slicers: Issue Type, Priority, Issue Status, Department, Month.

## Report guardrails

- Explain that Total Cost is the sum of recorded non-missing cost amounts.
- Explain that negative overtime is excluded from Valid Overtime Hours but remains visible through quality flags.
- Explain that missing resolution hours are not zero and are excluded from the average.
- Do not label recorded cost as savings opportunity or claim causal relationships from a scatter plot.

---

## RESUME_BULLETS

# Resume Bullets

**Operations & Cost Optimization Analytics | SQL, MySQL, Excel, Python/Pandas, Power BI**

- Cleaned and validated five related operational CSV tables with Pandas, standardizing department keys, removing exact duplicates, quarantining two conflicting operation IDs, and preserving auditable quality flags for missing values, negative overtime, abnormal hours, and task anomalies.
- Built a relational MySQL model for employees, operations, costs, targets, and issues, using indexed primary/foreign keys and CTE, CASE, JOIN, subquery, and window-function analyses to prevent one-to-many cost and issue overcounting.
- Calculated 39.16M in recorded operational cost, 833,152 completed tasks, a 91.05% task completion rate, 33,249.29 valid overtime hours, and a 47.01 recorded cost per completed task from the cleaned dataset.
- Created an Excel analysis workbook with SUMIFS, COUNTIFS, AVERAGEIFS, IF/IFS, XLOOKUP, date-based analysis, conditional formatting, and a cost PivotTable/PivotChart for department, cost-category, monthly, productivity, overtime, and target analysis.
- Designed a three-page Power BI reporting model with DAX measures for cost, completion, productivity, overtime, issues, resolution time, and target variance, identifying Operations as the largest recorded-cost department and IT as the highest recorded cost-per-completed-task department for investigation.

---

## SQL_QUERY_GUIDE

# SQL Query Explanations

## Department cost per completed task

**Business question:** Which departments have the highest recorded cost per completed task?

**Key SQL:** The query in `sql/02_business_queries.sql` first aggregates `costs` by `operation_id` in `cost_by_operation`, then joins that one-row-per-operation result to `operations`, groups by department, and divides total cost by completed tasks.

**Execution logic:** The CTE is evaluated first; the join matches each operation once; `GROUP BY` calculates department totals; `NULLIF` prevents division by zero; `ORDER BY` ranks the result.

**Expected output:** One row per department with total cost, completed tasks, and cost per completed task.

**Interpretation:** This is a recorded-cost efficiency ratio. It is an investigation signal, not proof that a department causes higher cost.

## Monthly cost trend with LAG and rolling average

**Business question:** How does recorded cost change month over month?

**Key SQL:** `monthly_costs` aggregates total and overtime cost by month. `LAG(total_cost)` retrieves the previous month. `SUM() OVER` or `AVG() OVER` calculates running or rolling values without collapsing the monthly rows.

**Expected output:** One row per month with total cost, overtime cost, prior-month cost, change, and a three-month average.

**Interpretation:** The change shows movement, while the rolling average reduces attention on one-month spikes.

## Target variance with CASE

**Business question:** Which department-month combinations are above the supplied cost target?

**Key SQL:** Aggregate actual cost by department and month, join to `targets` on the normalized department-month key, subtract target from actual, and use `CASE` to label the result.

**Important caveat:** All 72 rows are above target, so the target units must be validated before treating the labels as confirmed operational failures.

## High-cost / lower-productivity candidates

**Business question:** Which departments combine above-average recorded cost with below-average productivity?

**Key SQL:** The `department_metrics` CTE calculates department cost and average productivity. The `thresholds` CTE calculates the overall averages. A `CROSS JOIN` attaches those thresholds to each department, and `CASE` labels investigation candidates.

**Expected output:** One row per department with metrics and an investigation label.

**Interpretation:** This narrows the review list; it does not establish causation or forecast savings.


---

## SQL directory instructions

# MySQL Layer

Use MySQL 8.0 or later. Run `01_schema_and_load.sql` after updating the absolute CSV paths if needed, then run sections of `02_business_queries.sql`.

The schema keeps `employees`, `operations`, `costs`, `targets`, and `issues` as separate relational tables. `operation_id` is the parent key for costs and issues. The child tables are deliberately aggregated before joins in analytical queries; otherwise one operation with several costs and issues would multiply rows and overstate KPIs.

The loader expects the Pandas-cleaned files in `data/clean/`. The two conflicting operation IDs are excluded from `operations_clean.csv` and documented in `data/quarantine/operations_conflicting_ids.csv`.
