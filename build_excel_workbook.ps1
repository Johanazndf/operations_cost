$ErrorActionPreference = "Stop"

$root = (Get-Location).Path
$outputPath = Join-Path $root "Operations_Cost_Optimization_Analytics.xlsx"
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

function Add-CsvSheet($workbook, $sheetName, $csvPath) {
    $sheet = $workbook.Worksheets.Add()
    $sheet.Name = $sheetName
    $source = $workbook.Application.Workbooks.Open($csvPath, $false, $true)
    $source.Worksheets.Item(1).UsedRange.Copy() | Out-Null
    $sheet.Range("A1").PasteSpecial(-4163) | Out-Null
    $source.Close($false) | Out-Null
    $sheet.Rows.Item(1).Font.Bold = $true
    $sheet.UsedRange.Columns.AutoFit() | Out-Null
    $sheet.UsedRange.Rows.Item(1).AutoFilter() | Out-Null
    return $sheet
}

try {
    $workbook = $excel.Workbooks.Add()
    $first = $workbook.Worksheets.Item(1)
    $first.Name = "Read Me"
    $first.Range("A1").Value2 = "Operations & Cost Optimization Analytics"
    $first.Range("A1").Font.Bold = $true
    $first.Range("A3").Value2 = "Excel is used for formula-based validation, target checks, and a shipping-cost PivotTable. SQL is used for relational analysis; Power BI is reserved for the final three-page report."
    $first.Range("A3:H3").Merge()
    $first.Range("A5:B10").Value2 = @(
        @("Source", "Pandas-cleaned files in data/clean"),
        @("Grain", "Operations has one row per cleaned operation; costs and issues are child facts"),
        @("Missing values", "Missing numeric values are preserved and excluded only from relevant averages/sums"),
        @("Targets", "Department-month targets are joined through a normalized department-month key"),
        @("Cost limitation", "Recorded costs are analyzed; no savings claim is made"),
        @("Workbook role", "Practical Excel analysis, separate from the Power BI dashboard")
    )
    $first.Columns("A:B").AutoFit()

    $operationsSheet = Add-CsvSheet $workbook "Clean_Operations" (Join-Path $root "data\clean\operations_clean.csv")
    $costsSheet = Add-CsvSheet $workbook "Clean_Costs" (Join-Path $root "data\clean\costs_clean.csv")
    $employeesSheet = Add-CsvSheet $workbook "Clean_Employees" (Join-Path $root "data\clean\employees_clean.csv")
    $targetsSheet = Add-CsvSheet $workbook "Clean_Targets" (Join-Path $root "data\clean\targets_clean.csv")
    $issuesSheet = Add-CsvSheet $workbook "Clean_Issues" (Join-Path $root "data\clean\issues_clean.csv")

    $targetsSheet.Range("G1").Value2 = "target_key"
    $targetsSheet.Range("G1").Font.Bold = $true
    $targetLastRow = $targetsSheet.UsedRange.Rows.Count
    for ($row = 2; $row -le $targetLastRow; $row++) {
        $targetsSheet.Cells.Item($row, 7).Formula = '=A{0}&"|"&TEXT(B{0},"yyyy-mm")' -f $row
    }

    $kpi = $workbook.Worksheets.Add()
    $kpi.Name = "KPI_Calculations"
    $kpi.Range("A1").Value2 = "KPI Calculations"
    $kpi.Range("A1").Font.Bold = $true
    $kpi.Range("A3:C3").Value2 = @(@("KPI", "Value", "Excel formula / meaning"))
    $kpi.Range("A3:C3").Font.Bold = $true
    $kpis = @(
        @("Total Operational Cost", '=SUM(Clean_Costs!$F:$F)', "SUMIFS-ready recorded cost total"),
        @("Total Tasks Completed", '=SUM(Clean_Operations!$H:$H)', "SUM of completed tasks"),
        @("Total Tasks Assigned", '=SUM(Clean_Operations!$G:$G)', "SUM of assigned tasks"),
        @("Task Completion Rate", '=B5/B6', "Completed divided by assigned"),
        @("Average Productivity", '=AVERAGE(Clean_Operations!$I:$I)', "AVERAGE ignores missing productivity"),
        @("Total Valid Overtime Hours", '=SUM(Clean_Operations!$T:$T)', "Negative overtime is excluded from valid KPI field"),
        @("Overtime Cost", '=SUMIFS(Clean_Costs!$F:$F,Clean_Costs!$E:$E,"Overtime")', "SUMIFS by cost type"),
        @("Cost per Completed Task", '=B4/B5', "Recorded cost divided by completed tasks"),
        @("Issue Volume", '=COUNTA(Clean_Issues!$A:$A)-1', "Count of issue IDs"),
        @("Average Resolution Hours", '=AVERAGE(Clean_Issues!$E:$E)', "AVERAGE ignores missing resolution hours"),
        @("Operations Missing Hours", '=COUNTIFS(Clean_Operations!$Q:$Q,1)', "COUNTIFS quality flag"),
        @("Operations Missing Productivity", '=COUNTIFS(Clean_Operations!$R:$R,1)', "COUNTIFS quality flag")
    )
    $row = 4
    foreach ($metric in $kpis) {
        $kpi.Cells.Item($row, 1).Value2 = $metric[0]
        $kpi.Cells.Item($row, 2).Formula = $metric[1]
        $kpi.Cells.Item($row, 3).Value2 = $metric[2]
        $row++
    }
    $kpi.Range("B7:B7").NumberFormat = "0.00%"
    $kpi.Range("B8:B8").NumberFormat = "0.00"
    $kpi.Range("B10:B10").NumberFormat = "#,##0.00"
    $kpi.Range("B4:B4").NumberFormat = "#,##0.00"
    $kpi.Range("B9:B9").NumberFormat = "#,##0.00"
    $kpi.Range("A18").Value2 = "XLOOKUP example"
    $kpi.Range("A18").Font.Bold = $true
    $kpi.Range("A19:B20").Value2 = @(@("Employee ID", "Location"), @("E0001", ""))
    $kpi.Range("B19").Formula = '=XLOOKUP(A20,Clean_Employees!$A:$A,Clean_Employees!$E:$E,"Not found")'
    $kpi.Range("A23:B23").Value2 = @(@("Shipping mode", "Late-status band"))
    $kpi.Range("A23:B23").Font.Bold = $true
    $modes = @("Standard Class", "Second Class", "First Class", "Same Day")
    $row = 24
    foreach ($mode in $modes) {
        $kpi.Cells.Item($row, 1).Value2 = $mode
        $kpi.Cells.Item($row, 2).Formula = '=IFS(COUNTIFS(Clean_Operations!$D:$D,A{0})=0,"No data",COUNTIFS(Clean_Operations!$D:$D,A{0},Clean_Operations!$J:$J,"Delayed")/COUNTIFS(Clean_Operations!$D:$D,A{0})>=0.1,"High delay",TRUE,"Lower delay")' -f $row
        $row++
    }
    $kpi.Columns("A:C").AutoFit()
    $kpi.Range("B7:B7").FormatConditions.Add(2, 1, 0.9).Interior.ColorIndex = 36

    $department = $workbook.Worksheets.Add()
    $department.Name = "Department_Analysis"
    $department.Range("A1:L1").Value2 = @(@("Department", "Operations", "Total Cost", "Tasks Completed", "Completion Rate", "Avg Productivity", "Valid Overtime", "Overtime Cost", "Cost per Task", "Missing Productivity", "Target Check", "Location Lookup"))
    $department.Range("A1:L1").Font.Bold = $true
    $departments = @("Operations", "Customer Support", "IT", "Finance", "Logistics", "HR")
    $row = 2
    foreach ($name in $departments) {
        $department.Cells.Item($row, 1).Value2 = $name
        $department.Cells.Item($row, 2).Formula = '=COUNTIFS(Clean_Operations!$D:$D,A{0})' -f $row
        $department.Cells.Item($row, 3).Formula = '=SUMIFS(Clean_Costs!$F:$F,Clean_Costs!$D:$D,A{0})' -f $row
        $department.Cells.Item($row, 4).Formula = '=SUMIFS(Clean_Operations!$H:$H,Clean_Operations!$D:$D,A{0})' -f $row
        $department.Cells.Item($row, 5).Formula = '=SUMIFS(Clean_Operations!$H:$H,Clean_Operations!$D:$D,A{0})/SUMIFS(Clean_Operations!$G:$G,Clean_Operations!$D:$D,A{0})' -f $row
        $department.Cells.Item($row, 6).Formula = '=AVERAGEIFS(Clean_Operations!$I:$I,Clean_Operations!$D:$D,A{0})' -f $row
        $department.Cells.Item($row, 7).Formula = '=SUMIFS(Clean_Operations!$T:$T,Clean_Operations!$D:$D,A{0})' -f $row
        $department.Cells.Item($row, 8).Formula = '=SUMIFS(Clean_Costs!$F:$F,Clean_Costs!$D:$D,A{0},Clean_Costs!$E:$E,"Overtime")' -f $row
        $department.Cells.Item($row, 9).Formula = '=C{0}/D{0}' -f $row
        $department.Cells.Item($row, 10).Formula = '=COUNTIFS(Clean_Operations!$D:$D,A{0},Clean_Operations!$R:$R,1)' -f $row
        $department.Cells.Item($row, 11).Formula = '=IFS(E{0}>=0.9,"Strong completion",E{0}>=0.85,"Review",TRUE,"Priority review")' -f $row
        $department.Cells.Item($row, 12).Formula = '=XLOOKUP(A{0},Clean_Employees!$C:$C,Clean_Employees!$E:$E,"Multiple/Review")' -f $row
        $row++
    }
    $department.Columns("A:L").AutoFit()
    $department.Range("E2:E7").NumberFormat = "0.00%"
    $department.Range("C2:C7").FormatConditions.AddColorScale(3)
    $department.Range("I2:I7").FormatConditions.AddColorScale(3)

    $monthly = $workbook.Worksheets.Add()
    $monthly.Name = "Monthly_Analysis"
    $monthly.Range("A1:H1").Value2 = @(@("Month", "Year", "Month Number", "Total Cost", "Completed Tasks", "Completion Rate", "Overtime Cost", "Cost per Task"))
    $monthly.Range("A1:H1").Font.Bold = $true
    for ($month = 1; $month -le 12; $month++) {
        $row = $month + 1
        $monthly.Cells.Item($row, 1).Value = (Get-Date -Year 2025 -Month $month -Day 1)
        $monthly.Cells.Item($row, 1).NumberFormat = "yyyy-mm-dd"
        $monthly.Cells.Item($row, 2).Formula = '=YEAR(A{0})' -f $row
        $monthly.Cells.Item($row, 3).Formula = '=MONTH(A{0})' -f $row
        $monthly.Cells.Item($row, 4).Formula = '=SUMIFS(Clean_Costs!$F:$F,Clean_Costs!$C:$C,">="&A{0},Clean_Costs!$C:$C,"<"&EDATE(A{0},1))' -f $row
        $monthly.Cells.Item($row, 5).Formula = '=SUMIFS(Clean_Operations!$H:$H,Clean_Operations!$W:$W,A{0})' -f $row
        $monthly.Cells.Item($row, 6).Formula = '=E{0}/SUMIFS(Clean_Operations!$G:$G,Clean_Operations!$W:$W,A{0})' -f $row
        $monthly.Cells.Item($row, 7).Formula = '=SUMIFS(Clean_Costs!$F:$F,Clean_Costs!$E:$E,"Overtime",Clean_Costs!$C:$C,">="&A{0},Clean_Costs!$C:$C,"<"&EDATE(A{0},1))' -f $row
        $monthly.Cells.Item($row, 8).Formula = '=D{0}/E{0}' -f $row
    }
    $monthly.Columns("A:H").AutoFit()
    $monthly.Range("F2:F13").NumberFormat = "0.00%"
    $monthly.Range("D2:H13").FormatConditions.AddColorScale(3)

    $targets = $workbook.Worksheets.Add()
    $targets.Name = "Target_Actual"
    $targets.Range("A1:J1").Value2 = @(@("Department", "Month", "Actual Cost", "Cost Target", "Cost Variance", "Productivity", "Productivity Target", "Productivity Variance", "Task Completion", "Target Status"))
    $targets.Range("A1:J1").Font.Bold = $true
    $row = 2
    foreach ($departmentName in $departments) {
        for ($month = 1; $month -le 12; $month++) {
            $targets.Cells.Item($row, 1).Value2 = $departmentName
            $targets.Cells.Item($row, 2).Value = (Get-Date -Year 2025 -Month $month -Day 1)
            $targets.Cells.Item($row, 2).NumberFormat = "yyyy-mm-dd"
            $targets.Cells.Item($row, 3).Formula = '=SUMIFS(Clean_Costs!$F:$F,Clean_Costs!$D:$D,A{0},Clean_Costs!$C:$C,">="&B{0},Clean_Costs!$C:$C,"<"&EDATE(B{0},1))' -f $row
            $targets.Cells.Item($row, 4).Formula = '=XLOOKUP(A{0}&"|"&TEXT(B{0},"yyyy-mm"),Clean_Targets!$G:$G,Clean_Targets!$D:$D,"Not found")' -f $row
            $targets.Cells.Item($row, 5).Formula = '=C{0}-D{0}' -f $row
            $targets.Cells.Item($row, 6).Formula = '=AVERAGEIFS(Clean_Operations!$I:$I,Clean_Operations!$D:$D,A{0},Clean_Operations!$W:$W,B{0})' -f $row
            $targets.Cells.Item($row, 7).Formula = '=XLOOKUP(A{0}&"|"&TEXT(B{0},"yyyy-mm"),Clean_Targets!$G:$G,Clean_Targets!$C:$C,"Not found")' -f $row
            $targets.Cells.Item($row, 8).Formula = '=F{0}-G{0}' -f $row
            $targets.Cells.Item($row, 9).Formula = '=SUMIFS(Clean_Operations!$H:$H,Clean_Operations!$D:$D,A{0},Clean_Operations!$W:$W,B{0})/SUMIFS(Clean_Operations!$G:$G,Clean_Operations!$D:$D,A{0},Clean_Operations!$W:$W,B{0})' -f $row
            $targets.Cells.Item($row, 10).Formula = '=IFS(E{0}>0,"Cost over target",H{0}<0,"Productivity below target",TRUE,"Review")' -f $row
            $row++
        }
    }
    $targets.Columns("A:J").AutoFit()
    $targets.Range("E2:E73").FormatConditions.AddColorScale(3)
    $targets.Range("H2:H73").FormatConditions.AddColorScale(3)

    $pivotSheet = $workbook.Worksheets.Add()
    $pivotSheet.Name = "Cost_Pivot"
    $sourceRange = $costsSheet.UsedRange.Address($true, $true, 1, $true)
    $pivotCache = $workbook.PivotCaches().Create(1, $sourceRange)
    $pivotTable = $pivotCache.CreatePivotTable($pivotSheet.Range("A3"), "CostByDepartmentPivot")
    $pivotTable.PivotFields("department").Orientation = 1
    $pivotTable.PivotFields("cost_type").Orientation = 1
    $pivotTable.AddDataField($pivotTable.PivotFields("amount"), "Total Recorded Cost", -4157)
    $pivotSheet.Range("A1").Value2 = "PivotTable: recorded cost by department and cost type"
    $pivotSheet.Range("A1").Font.Bold = $true
    $pivotSheet.Columns("A:H").AutoFit()
    $chart = $pivotSheet.Shapes.AddChart2(201, 51, 430, 35, 560, 300)
    $chart.Chart.SetSourceData($pivotTable.TableRange1)
    $chart.Chart.HasTitle = $true
    $chart.Chart.ChartTitle.Text = "Recorded Cost by Department and Cost Type"

    $kpi.Activate()
    $workbook.SaveAs($outputPath, 51)
    $workbook.Close($true)
    Write-Output "Created $outputPath"
}
finally {
    if ($workbook -ne $null) { try { $workbook.Close($false) } catch {} }
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}