import pandas as pd


TABLES = {
    "employees": "employees.csv",
    "operations": "operations.csv",
    "costs": "costs.csv",
    "targets": "targets.csv",
    "issues": "issues.csv",
}


def main():
    tables = {name: pd.read_csv(path) for name, path in TABLES.items()}
    for name, table in tables.items():
        print(f"\n=== {name} ===")
        print(f"rows={len(table):,}; columns={len(table.columns)}")
        print("columns:", list(table.columns))
        print("dtypes:\n", table.dtypes.to_string())
        print("missing:\n", table.isna().sum()[lambda values: values > 0].to_string())
        print("duplicate_rows:", int(table.duplicated().sum()))
        print("unique_counts:\n", table.nunique(dropna=False).to_string())

    operations = tables["operations"]
    costs = tables["costs"]
    issues = tables["issues"]
    employees = tables["employees"]
    targets = tables["targets"]

    print("\n=== quality checks ===")
    checks = {
        "operation_duplicate_rows": operations.duplicated().sum(),
        "cost_duplicate_rows": costs.duplicated().sum(),
        "missing_hours": operations["hours_worked"].isna().sum(),
        "missing_productivity": operations["productivity_score"].isna().sum(),
        "negative_overtime": (operations["overtime_hours"] < 0).sum(),
        "hours_above_24": (operations["hours_worked"] > 24).sum(),
        "completed_above_assigned": (
            operations["tasks_completed"] > operations["tasks_assigned"]
        ).sum(),
        "missing_cost_amount": costs["amount"].isna().sum(),
        "missing_resolution_hours": issues["resolution_hours"].isna().sum(),
    }
    for name, value in checks.items():
        print(f"{name}={int(value):,}")

    employee_departments = employees["department"].dropna().unique().tolist()
    department_lookup = {
        value.casefold(): value for value in employee_departments
    }
    operation_department = operations["department"].astype(str).str.strip().str.casefold()
    canonical_operation_department = operation_department.map(department_lookup)
    print(
        "department_mismatches_with_employee_master=",
        int(
            (
                canonical_operation_department
                != operations["employee_id"].map(
                    employees.set_index("employee_id")["department"]
                )
            ).sum()
        ),
    )
    print("target_rows=", len(targets))

    print("\n=== date ranges ===")
    for name, column in [
        ("employees", "joining_date"),
        ("operations", "date"),
        ("costs", "date"),
        ("targets", "month"),
    ]:
        parsed = pd.to_datetime(tables[name][column], errors="coerce")
        print(name, column, parsed.min(), parsed.max(), "invalid=", int(parsed.isna().sum()))


if __name__ == "__main__":
    main()