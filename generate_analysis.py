import pandas as pd


def operational_summary(operations, group_columns):
    summary = (
        operations.groupby(group_columns, dropna=False)
        .agg(
            operation_count=("operation_id", "nunique"),
            tasks_assigned=("tasks_assigned", "sum"),
            tasks_completed=("tasks_completed", "sum"),
            average_productivity=("productivity_score", "mean"),
            total_hours_worked=("hours_worked", "sum"),
            total_overtime_hours=("valid_overtime_hours", "sum"),
            delayed_operations=("status", lambda values: (values == "Delayed").sum()),
            missing_productivity=("missing_productivity_flag", "sum"),
            completion_over_assignment=("completion_over_assignment_flag", "sum"),
        )
        .reset_index()
    )
    summary["task_completion_rate"] = (
        summary["tasks_completed"] / summary["tasks_assigned"]
    )
    summary["delayed_operation_rate"] = (
        summary["delayed_operations"] / summary["operation_count"]
    )
    return summary


def cost_summary(costs, group_columns):
    return (
        costs.groupby(group_columns, dropna=False)
        .agg(
            cost_records=("cost_id", "nunique"),
            total_cost=("amount", "sum"),
            missing_cost_amounts=("missing_amount_flag", "sum"),
            high_cost_records=("high_cost_flag", "sum"),
        )
        .reset_index()
    )


def main():
    employees = pd.read_csv("data/clean/employees_clean.csv")
    operations = pd.read_csv("data/clean/operations_clean.csv")
    costs = pd.read_csv("data/clean/costs_clean.csv")
    targets = pd.read_csv("data/clean/targets_clean.csv")
    issues = pd.read_csv("data/clean/issues_clean.csv")

    operations["date"] = pd.to_datetime(operations["date"])
    operations["month"] = pd.to_datetime(operations["month"])
    costs["date"] = pd.to_datetime(costs["date"])
    targets["month"] = pd.to_datetime(targets["month"])

    operations_with_employee = operations.merge(
        employees[["employee_id", "location"]],
        on="employee_id",
        how="left",
        validate="many_to_one",
    )
    costs_by_operation = (
        costs.groupby("operation_id", dropna=False)
        .agg(
            total_cost=("amount", "sum"),
            overtime_cost=("amount", lambda values: 0),
            missing_cost_records=("missing_amount_flag", "sum"),
        )
        .reset_index()
    )
    overtime_costs = (
        costs.loc[costs["cost_type"] == "Overtime"]
        .groupby("operation_id", dropna=False)["amount"]
        .sum()
        .rename("overtime_cost")
    )
    costs_by_operation = costs_by_operation.drop(columns="overtime_cost").merge(
        overtime_costs, on="operation_id", how="left"
    )
    costs_by_operation["overtime_cost"] = costs_by_operation["overtime_cost"].fillna(0)

    operation_finance = operations_with_employee.merge(
        costs_by_operation, on="operation_id", how="left", validate="one_to_one"
    )
    operation_finance["total_cost"] = operation_finance["total_cost"].fillna(0)
    operation_finance["overtime_cost"] = operation_finance["overtime_cost"].fillna(0)
    operation_finance["cost_per_completed_task"] = operation_finance["total_cost"] / operation_finance["tasks_completed"]

    department = operational_summary(operation_finance, ["department"])
    department_costs = cost_summary(costs, ["department"])
    department = department.merge(department_costs, on="department", how="left")
    department["total_cost"] = department["total_cost"].fillna(0)
    department["cost_per_completed_task"] = department["total_cost"] / department["tasks_completed"]
    department["overtime_cost"] = operation_finance.groupby("department")["overtime_cost"].sum().reindex(department["department"]).values
    department.to_csv("analysis/department_summary.csv", index=False)

    location = operational_summary(operation_finance, ["location"])
    location_costs = operation_finance.groupby("location", dropna=False).agg(total_cost=("total_cost", "sum")).reset_index()
    location = location.merge(location_costs, on="location", how="left")
    location["cost_per_completed_task"] = location["total_cost"] / location["tasks_completed"]
    location.to_csv("analysis/location_summary.csv", index=False)

    cost_summary(costs, ["cost_type"]).sort_values("total_cost", ascending=False).to_csv(
        "analysis/cost_type_summary.csv", index=False
    )
    cost_summary(costs, ["department", "cost_type"]).to_csv(
        "analysis/department_cost_type_summary.csv", index=False
    )

    monthly_operations = operational_summary(operation_finance, ["month"])
    monthly_costs = cost_summary(costs.assign(month=costs["date"].dt.to_period("M").dt.to_timestamp()), ["month"])
    monthly = monthly_operations.merge(monthly_costs, on="month", how="left")
    monthly["cost_per_completed_task"] = monthly["total_cost"] / monthly["tasks_completed"]
    monthly = monthly.sort_values("month")
    monthly["prior_month_cost"] = monthly["total_cost"].shift(1)
    monthly["month_over_month_cost_change"] = monthly["total_cost"] - monthly["prior_month_cost"]
    monthly.to_csv("analysis/monthly_summary.csv", index=False)

    department_month = operational_summary(operation_finance, ["department", "month"])
    costs_month = cost_summary(
        costs.assign(month=costs["date"].dt.to_period("M").dt.to_timestamp()),
        ["department", "month"],
    )
    department_month = department_month.merge(costs_month, on=["department", "month"], how="left")
    department_month = department_month.merge(targets, on=["department", "month"], how="left", validate="one_to_one")
    department_month["cost_variance_to_target"] = department_month["total_cost"] - department_month["cost_target"]
    department_month["productivity_variance_to_target"] = department_month["average_productivity"] - department_month["productivity_target"]
    department_month["task_completion_variance_to_target"] = department_month["task_completion_rate"] * 100 - department_month["task_completion_target"]
    department_month.to_csv("analysis/department_month_target_summary.csv", index=False)

    issues_with_operations = issues.merge(
        operations[["operation_id", "department", "month"]],
        on="operation_id",
        how="left",
        validate="many_to_one",
    )
    issue_summary = (
        issues_with_operations.groupby(["department", "issue_type"], dropna=False)
        .agg(
            issue_count=("issue_id", "nunique"),
            average_resolution_hours=("resolution_hours", "mean"),
            missing_resolution_hours=("missing_resolution_flag", "sum"),
        )
        .reset_index()
        .sort_values("issue_count", ascending=False)
    )
    issue_summary.to_csv("analysis/issue_summary.csv", index=False)

    kpis = pd.DataFrame(
        [
            ["Total operational cost", operation_finance["total_cost"].sum(), "SUM(non-missing cost amounts)"],
            ["Total tasks completed", operation_finance["tasks_completed"].sum(), "SUM(tasks_completed)"],
            ["Total tasks assigned", operation_finance["tasks_assigned"].sum(), "SUM(tasks_assigned)"],
            ["Task completion rate", operation_finance["tasks_completed"].sum() / operation_finance["tasks_assigned"].sum(), "SUM(completed) / SUM(assigned)"],
            ["Average productivity", operation_finance["productivity_score"].mean(), "AVERAGE(non-missing productivity_score)"],
            ["Total valid overtime hours", operation_finance["valid_overtime_hours"].sum(), "SUM(overtime_hours where overtime_hours >= 0)"],
            ["Overtime cost", operation_finance["overtime_cost"].sum(), "SUM(costs where cost_type = Overtime)"],
            ["Cost per completed task", operation_finance["total_cost"].sum() / operation_finance["tasks_completed"].sum(), "Total cost / total tasks completed"],
            ["Issue volume", issues["issue_id"].nunique(), "COUNT(DISTINCT issue_id)"],
            ["Average resolution hours", issues["resolution_hours"].mean(), "AVERAGE(non-missing resolution_hours)"],
            ["Missing cost amount records", costs["missing_amount_flag"].sum(), "COUNT(missing amount)"],
        ],
        columns=["kpi", "value", "definition"],
    )
    kpis.to_csv("analysis/kpis.csv", index=False)
    print("Analysis summaries written successfully.")


if __name__ == "__main__":
    main()