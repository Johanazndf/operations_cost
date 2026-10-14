import pandas as pd


def canonical_department(series, employee_departments):
    lookup = {value.casefold(): value for value in employee_departments}
    normalized = series.astype("string").str.strip().str.casefold()
    return normalized.map(lookup)


def main():
    employees = pd.read_csv("employees.csv")
    operations = pd.read_csv("operations.csv")
    costs = pd.read_csv("costs.csv")
    targets = pd.read_csv("targets.csv")
    issues = pd.read_csv("issues.csv")

    employee_departments = employees["department"].dropna().unique().tolist()
    employee_department_by_id = employees.set_index("employee_id")["department"]

    employees["joining_date"] = pd.to_datetime(employees["joining_date"], errors="coerce")
    employees.to_csv("data/clean/employees_clean.csv", index=False)

    operations["department_source"] = operations["department"]
    operations["department"] = canonical_department(
        operations["department"], employee_departments
    )
    operations["employee_department"] = operations["employee_id"].map(
        employee_department_by_id
    )
    operations["department_mismatch_flag"] = (
        operations["department"] != operations["employee_department"]
    ).astype(int)
    operations["date"] = pd.to_datetime(operations["date"], errors="coerce")
    operations["negative_overtime_flag"] = (operations["overtime_hours"] < 0).astype(int)
    operations["hours_above_24_flag"] = (operations["hours_worked"] > 24).astype(int)
    operations["completion_over_assignment_flag"] = (
        operations["tasks_completed"] > operations["tasks_assigned"]
    ).astype(int)
    operations["missing_hours_flag"] = operations["hours_worked"].isna().astype(int)
    operations["missing_productivity_flag"] = operations["productivity_score"].isna().astype(int)
    operations["productivity_above_100_flag"] = (
        operations["productivity_score"] > 100
    ).astype(int)
    operations["valid_overtime_hours"] = operations["overtime_hours"].where(
        operations["overtime_hours"] >= 0
    )
    operations["completion_rate"] = (
        operations["tasks_completed"] / operations["tasks_assigned"]
    )
    operations["month"] = operations["date"].dt.to_period("M").dt.to_timestamp()
    operations["department_month_key"] = (
        operations["department"] + "|" + operations["month"].dt.strftime("%Y-%m")
    )

    exact_duplicate_operations = operations[operations.duplicated(keep=False)].copy()
    operations_deduped = operations.drop_duplicates().copy()
    conflicting_ids = operations_deduped.loc[
        operations_deduped.duplicated("operation_id", keep=False), "operation_id"
    ].unique()
    conflicting_operations = operations_deduped[
        operations_deduped["operation_id"].isin(conflicting_ids)
    ].copy()
    operations_clean = operations_deduped[
        ~operations_deduped["operation_id"].isin(conflicting_ids)
    ].copy()
    exact_duplicate_operations.to_csv(
        "data/quarantine/operations_exact_duplicates.csv", index=False
    )
    conflicting_operations.to_csv(
        "data/quarantine/operations_conflicting_ids.csv", index=False
    )
    operations_clean.to_csv("data/clean/operations_clean.csv", index=False)

    costs["department_source"] = costs["department"]
    costs["department"] = canonical_department(costs["department"], employee_departments)
    costs["date"] = pd.to_datetime(costs["date"], errors="coerce")
    costs["month"] = costs["date"].dt.to_period("M").dt.to_timestamp()
    costs["department_month_key"] = (
        costs["department"] + "|" + costs["month"].dt.strftime("%Y-%m")
    )
    costs["missing_amount_flag"] = costs["amount"].isna().astype(int)
    non_missing_costs = costs["amount"].dropna()
    cost_p99 = non_missing_costs.quantile(0.99)
    costs["high_cost_flag"] = (costs["amount"] > cost_p99).astype(int)
    costs_clean = costs.drop_duplicates().copy()
    costs_clean.to_csv("data/clean/costs_clean.csv", index=False)

    targets["month"] = pd.to_datetime(targets["month"], errors="coerce")
    targets["department"] = canonical_department(targets["department"], employee_departments)
    targets["department_month_key"] = (
        targets["department"] + "|" + targets["month"].dt.strftime("%Y-%m")
    )
    targets.to_csv("data/clean/targets_clean.csv", index=False)

    issues["missing_resolution_flag"] = issues["resolution_hours"].isna().astype(int)
    issues_clean = issues.drop_duplicates().copy()
    issues_clean.to_csv("data/clean/issues_clean.csv", index=False)

    quality_checks = pd.DataFrame(
        [
            ["operations_source_rows", 30120, len(operations), "Source row count"],
            ["operations_clean_rows", len(operations), len(operations_clean), "Exact duplicates removed; conflicting IDs quarantined"],
            ["operations_exact_duplicates", int(operations.duplicated().sum()), int(exact_duplicate_operations.shape[0]), "Quarantined for audit"],
            ["operations_conflicting_ids", len(conflicting_ids), len(conflicting_ids), "All rows for conflicting IDs quarantined"],
            ["costs_source_rows", 20070, len(costs), "Source row count"],
            ["costs_clean_rows", len(costs), len(costs_clean), "Exact duplicate rows removed"],
            ["cost_missing_amount_rows", int(costs["amount"].isna().sum()), int(costs["amount"].isna().sum()), "Preserved and excluded only from numeric sums"],
            ["negative_overtime_rows", int((operations["overtime_hours"] < 0).sum()), int((operations["overtime_hours"] < 0).sum()), "Preserved and flagged"],
            ["department_mismatch_rows", int(operations["department_mismatch_flag"].sum()), int(operations["department_mismatch_flag"].sum()), "Standardized and flagged"],
            ["missing_issue_resolution_rows", int(issues["resolution_hours"].isna().sum()), int(issues["resolution_hours"].isna().sum()), "Preserved and excluded from duration averages"],
        ],
        columns=["check", "source_value", "clean_value", "decision"],
    )
    quality_checks.to_csv("data/quality_checks.csv", index=False)
    print("Clean datasets and quality outputs written successfully.")
    print("operations_clean_rows", len(operations_clean))
    print("costs_clean_rows", len(costs_clean))
    print("conflicting_operation_ids", len(conflicting_ids))


if __name__ == "__main__":
    main()