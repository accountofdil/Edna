USE human_resources_information_system
GO


-- Database Security & Granular Access Control

-- Security Roles (Least Privilege Model)

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'HR_Admin')
	CREATE ROLE HR_Admin;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Department_Manager')
	CREATE ROLE Department_Manager;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'HR_Analyst')
	CREATE ROLE HR_Analyst;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Payroll_Officer')
	CREATE ROLE Payroll_Officer;
GO

-- Schema-Level and Table-Level Permission Allocation

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::HR TO HR_Admin;
GRANT SELECT ON SCHEMA::Audit TO HR_Admin;

GRANT SELECT, INSERT, UPDATE ON HR.Payrolls TO Payroll_Officer;
GRANT SELECT, INSERT, UPDATE ON HR.Payslips TO Payroll_Officer;
GRANT SELECT, INSERT, UPDATE ON HR.Salaries TO Payroll_Officer;
GRANT SELECT, INSERT, UPDATE ON HR.Benefits TO Payroll_Officer;
GRANT SELECT ON HR.Employees TO Payroll_Officer;
GRANT SELECT ON HR.Departments TO Payroll_Officer;
GRANT SELECT ON HR.Jobs TO Payroll_Officer;

GRANT SELECT ON HR.Departments TO HR_Analyst;
GRANT SELECT ON HR.Jobs TO HR_Analyst;
GRANT SELECT ON HR.Absences TO HR_Analyst;
GRANT SELECT ON HR.Reviews TO HR_Analyst;

GRANT SELECT ON HR.Employees (EmployeeID, FirstName, LastName, Email, HireDate, TerminationDate, DepartmentID, JobID, ManagerID, EmploymentStatus) TO HR_Analyst;

DENY SELECT ON HR.Salaries TO HR_Analyst;
DENY SELECT ON HR.Payslips TO HR_Analyst;
DENY SELECT ON HR.Employees (NINO, CurrentSalary) TO HR_Analyst;
GO

-- Dynamic Data Masking (DDM) for PII Compliance

ALTER TABLE HR.Employees
ALTER COLUMN NINO VARCHAR(9) MASKED WITH (FUNCTION = 'partial(2, "XXXX", 1)');

ALTER TABLE HR.Employees
ALTER COLUMN Email VARCHAR(100) MASKED WITH (FUNCTION = 'email()');
GO

GRANT UNMASK TO HR_Admin;
GRANT UNMASK TO Payroll_Officer;
GO

-- Test Database Users

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'User_HRAdmin')
	CREATE USER User_HRAdmin WITHOUT LOGIN;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'User_HRAnalyst')
	CREATE USER User_HRAnalyst WITHOUT LOGIN;
GO

ALTER ROLE HR_Admin ADD MEMBER User_HRAdmin;
ALTER ROLE HR_Analyst ADD MEMBER User_HRAnalyst;
GO

-- Security Validation & Permission Testing

EXECUTE AS USER = 'User_HRAnalyst';

SELECT EmployeeID, FirstName, LastName, Email, NINO, CurrentSalary
FROM HR.Employees;

REVERT;
GO

EXECUTE AS USER = 'User_HRAnalyst';

SELECT EmployeeID, FirstName, LastName, Email, EmploymentStatus
FROM HR.Employees;

REVERT;
GO

EXECUTE AS USER = 'User_HRAdmin';

SELECT TOP 5
EmployeeID, FirstName, LastName, Email, NINO, CurrentSalary
FROM HR.Employees;

REVERT;
GO


-- Core Analytical Queries & Reporting Logic

-- Departmental Headcount & Compensation Metrics

SELECT 
	d.DepartmentCode,
	d.DepartmentName,
	COUNT(e.EmployeeID) AS TotalHeadcount,
	SUM(CASE WHEN e.EmploymentStatus = 'Active' THEN 1 ELSE 0 END) AS ActiveHeadcount,
	SUM(CASE WHEN e.EmploymentStatus = 'On Leave' THEN 1 ELSE 0 END) AS OnLeaveHeadcount,
	SUM(CASE WHEN e.EmploymentStatus = 'Terminated' THEN 1 ELSE 0 END) AS TerminatedHeadcount,
	ISNULL(SUM(e.CurrentSalary), 0.00) AS TotalAnnualPayroll,
	ISNULL(ROUND(AVG(e.CurrentSalary), 2), 0.00) AS AverageAnnualSalary,
	ISNULL(MIN(e.CurrentSalary), 0.00) AS MinSalary,
	ISNULL(MAX(e.CurrentSalary), 0.00) AS MaxSalary
FROM HR.Departments AS d
LEFT JOIN HR.Employees AS e
ON d.DepartmentID = e.DepartmentID
GROUP BY
	d.DepartmentCode,
	d.DepartmentName
HAVING COUNT(e.EmployeeID) > 0
ORDER BY TotalAnnualPayroll DESC;
GO

-- Departmental Salary Ranking & Deviation Analysis

WITH EmployeeSalaryStatistics AS (
	SELECT 
		e.EmployeeID,
		CONCAT(e.FirstName, ' ', + e.LastName) AS EmployeeName,
		d.DepartmentName,
		j.JobTitle,
		e.CurrentSalary,
		AVG(e.CurrentSalary) OVER (PARTITION BY e.DepartmentID) AS DepartmentAverageSalary,
		STDEV(e.CurrentSalary) OVER (PARTITION BY e.DepartmentID) AS DepartmentSalaryStandardDeviation,
		RANK() OVER (PARTITION BY e.DepartmentID ORDER BY e.CurrentSalary DESC) AS SalaryRankInDepartment,
		DENSE_RANK() OVER (ORDER BY e.CurrentSalary DESC) AS OverallSalaryRank
	FROM HR.Employees AS e
	INNER JOIN HR.Departments AS d
	ON e.DepartmentID = d.DepartmentID
	INNER JOIN HR.Jobs AS j
	ON e.JobID = j.JobID
	WHERE e.EmploymentStatus = 'Active'
)
SELECT 
	EmployeeID,
	EmployeeName,
	DepartmentName,
	JobTitle,
	CurrentSalary,
	ROUND(DepartmentAverageSalary, 2) AS DepartmentAverageSalary,
	ROUND(CurrentSalary - DepartmentAverageSalary, 2) AS VarianceFromAverage,
	ROUND(((CurrentSalary - DepartmentAverageSalary) / DepartmentAverageSalary) * 100, 2) AS PercentageVarianceFromAverage,
	SalaryRankInDepartment,
	OverallSalaryRank
FROM EmployeeSalaryStatistics
WHERE SalaryRankInDepartment <= 3
ORDER BY DepartmentName, SalaryRankInDepartment;
GO

-- Longitudinal Salary Growth & Increase Percentages

WITH SalaryChanges AS (
	SELECT 
		s.EmployeeID,
		CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
		s.EffectiveDate,
		s.ChangeReason,
		s.OldSalary,
		s.NewSalary,
		s.NewSalary - s.OldSalary AS IncreaseAmount,
		ROUND(((s.NewSalary - s.OldSalary) / s.OldSalary) * 100, 2) AS PercentageIncrease,
		LAG(s.NewSalary, 1) OVER (PARTITION BY s.EmployeeID ORDER BY s.EffectiveDate) AS PriorSalaryRecord
	FROM HR.Salaries AS s
	INNER JOIN HR.Employees AS e
	ON s.EmployeeID = e.EmployeeID
)
SELECT
	EmployeeID,
	EmployeeName,
	EffectiveDate,
	ChangeReason,
	OldSalary,
	NewSalary,
	IncreaseAmount,
	PercentageIncrease
FROM SalaryChanges
ORDER BY 
	EffectiveDate DESC,
	PercentageIncrease DESC;
GO

-- Departmental Absence Matrix

WITH DepartmentAbsenceSummary AS (
	SELECT 
		d.DepartmentName,
		a.LeaveType,
		a.TotalDays
	FROM HR.Absences AS a
	INNER JOIN HR.Employees AS e
	ON a.EmployeeID = e.EmployeeID
	INNER JOIN HR.Departments AS d
	ON e.DepartmentID = d.DepartmentID
	WHERE a.ApprovalStatus = 'Approved'
)
SELECT
	DepartmentName,
	ISNULL([Annual Leave], 0) AS AnnualLeaveDays,
	ISNULL([Statutory Sick Pay], 0) AS SickDays,
	ISNULL([Maternity], 0) AS MaternityDays,
	ISNULL([Paternity], 0) AS PaternityDays,
	ISNULL([Shared Parental], 0) AS SharedParentalDays,
	ISNULL([Unpaid], 0) AS UnpaidDays
FROM DepartmentAbsenceSummary
PIVOT (
	SUM(TotalDays)
	FOR LeaveType IN (
					[Annual Leave], 
					[Statutory Sick Pay],
					[Maternity],
					[Paternity],
					[Shared Parental],
					[Unpaid]
					)) AS PivotedAbsences
ORDER BY DepartmentName;
GO

-- Executive Bonus & Gross-to-Net Payroll Reconciliation

SELECT 
	p.PayrollID,
	p.PeriodStartDate,
	p.PeriodEndDate,
	COUNT(ps.PayslipID) AS TotalPayslipsGenerated,
	SUM(ps.BasePay) AS TotalBasePay,
	SUM(ps.OvertimePay) AS TotalOvertimePay,
	SUM(ps.BonusPay) AS TotalBonusPay,
	SUM(ps.GrossPay) AS TotalGrossPay,
	SUM(ps.PAYE) AS TotalPAYE,
	SUM(ps.NIC) AS TotalNationalInsurance,
	SUM(ps.PensionDeduction) AS TotalPensionDeduction,
	SUM(ps.NetPay) AS TotalNetDisbursed
FROM HR.Payrolls AS p
INNER JOIN HR.Payslips AS ps
ON p.PayrollID = ps.PayrollID
GROUP BY
	p.PayrollID,
	p.PeriodStartDate,
	p.PeriodEndDate
ORDER BY p.PeriodStartDate DESC;
GO

-- Employee Profiling & Compensation-Experience Deconstruction

WITH EmployeeProfile AS (
	SELECT	
		e.EmployeeID,
		CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
		d.DepartmentName,
		j.JobTitle,
		e.CurrentSalary,
		j.MinSalary,
		j.MaxSalary,
		e.HireDate,
		DATEDIFF(YEAR, e.HireDate, GETDATE()) AS TenureYears,
		CASE
			WHEN e.CurrentSalary >= 100000.00 THEN 'Tier 1: Executive / Lead (£100k+)'
			WHEN e.CurrentSalary >= 70000.00 THEN 'Tier 2: Senior Management (£70k - £99k)'
			WHEN e.CurrentSalary >= 45000.00 THEN 'Tier 3: Mid-Level Professional (£45k - £69k)'
			ELSE 'Tier 4: Junior / Support (< £45k)'
		END SalaryTier,
		CASE
			WHEN e.CurrentSalary > j.MaxSalary THEN 'Above Maximum Band'
			WHEN e.CurrentSalary = j.MaxSalary THEN 'At Maximum Band'
			WHEN e.CurrentSalary >= (j.MinSalary + ((j.MaxSalary - j.MinSalary) * 0.5)) THEN 'Upper Half of Band'
			WHEN e.CurrentSalary >= j.MinSalary THEN 'Lower Half of Band'
			ELSE 'Below Minimum Band'
		END AS PayBandPlacement,
		CASE 
			WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) >= 10 THEN '10+ Years (Veteran)'
			WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) >= 5 THEN '5-9 Years (Established)'
			WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) >= 2 THEN '2-4 Years (Experienced)'
			ELSE '0-1 Years (Recent Joiner)'
		END AS TenureCategory
	FROM HR.Employees AS e
	INNER JOIN HR.Departments AS d
	ON e.DepartmentID = d.DepartmentID
	INNER JOIN HR.Jobs AS j
	ON e.JobID = j.JobID
	WHERE e.EmploymentStatus = 'Active'
)
SELECT 
	EmployeeID,
	EmployeeName,
	DepartmentName,
	JobTitle,
	CurrentSalary,
	SalaryTier,
	PayBandPlacement,
	TenureYears,
	TenureCategory,
	ROUND((CurrentSalary / ((MinSalary + MaxSalary) / 2.0)) * 100, 2) AS CompaRatio
FROM EmployeeProfile
ORDER BY CurrentSalary DESC;
GO


-- Advanced Hierarchical & Complex Data Analytics

-- Organisational Hierarchy & Span of Control Traversal

WITH OrganisationalHierarchy AS (
	SELECT
		e.EmployeeID,
		CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
		e.ManagerID,
		CAST(NULL AS VARCHAR(100)) AS ManagerName,
		j.JobTitle,
		d.DepartmentName,
		1 AS ManagementLevel,
		CAST(e.FirstName + ' ' + e.LastName AS VARCHAR(MAX)) AS ReportingPath
	FROM HR.Employees AS e
	INNER JOIN HR.Jobs AS j 
	ON e.JobID = j.JobID
	INNER JOIN HR.Departments AS d
	ON e.DepartmentID = d.DepartmentID
	WHERE e.ManagerID IS NULL

	UNION ALL

	SELECT
		emp.EmployeeID,
		CONCAT(emp.FirstName, ' ', emp.LastName) AS EmployeeName,
		emp.ManagerID,
		CAST(mgr.EmployeeName AS VARCHAR(100)) AS ManagerName,
		j.JobTitle,
		d.DepartmentName,
		mgr.ManagementLevel + 1 AS ManagementLevel,
		CAST(mgr.ReportingPath + ' -> ' + emp.FirstName + ' ' + emp.LastName AS VARCHAR(MAX)) AS ReportingPath
	FROM HR.Employees AS emp
	INNER JOIN OrganisationalHierarchy AS mgr 
	ON emp.ManagerID = mgr.EmployeeID
	INNER JOIN HR.Jobs AS j
	ON emp.JobID = j.JobID
	INNER JOIN HR.Departments AS d
	ON emp.DepartmentID = d.DepartmentID
)
SELECT
	EmployeeID,
	EmployeeName,
	ManagerName,
	JobTitle,
	DepartmentName,
	ManagementLevel,
	ReportingPath
FROM OrganisationalHierarchy
ORDER BY 
	ManagementLevel,
	ManagerID,
	EmployeeID
GO

-- Direct & Indirect Span of Control Metrics per Manager

WITH DirectReports AS (
	SELECT
		ManagerID,
		COUNT(EmployeeID) AS DirectReportCount
	FROM HR.Employees
	WHERE 
		ManagerID IS NOT NULL
		AND 
		EmploymentStatus = 'Active'
	GROUP BY ManagerID
)
SELECT 
	m.EmployeeID AS ManagerID,
	CONCAT(m.FirstName, ' ', m.LastName) AS ManagerName,
	j.JobTitle,
	d.DepartmentName,
	ISNULL(dr.DirectReportCount, 0) AS NumberOfDirectReports,
	m.CurrentSalary
FROM HR.Employees AS m
INNER JOIN HR.Jobs AS j
ON m.JobID = j.JobID
INNER JOIN HR.Departments AS d
ON m.DepartmentID = d.DepartmentID
LEFT JOIN DirectReports AS dr
ON m.EmployeeID = dr.ManagerID
WHERE dr.DirectReportCount > 0
ORDER BY NumberOfDirectReports DESC;
GO

-- Out-of-Band Salary Outlier Detection

WITH DepartmentSalaryStatistics AS (
	SELECT 
		e.EmployeeID,
		CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
		d.DepartmentName,
		j.JobTitle,
		e.CurrentSalary,
		j.MinSalary AS MinimumBand,
		j.MaxSalary AS MaximumBand,
		PERCENT_RANK() OVER (ORDER BY e.CurrentSalary) AS SalaryPercentile,
		NTILE(4) OVER (ORDER BY e.CurrentSalary) AS SalaryQuartile
	FROM HR.Employees AS e
	INNER JOIN HR.Departments AS d
	ON e.DepartmentID = d.DepartmentID
	INNER JOIN HR.Jobs AS j
	ON e.JobID = j.JobID
	WHERE e.EmploymentStatus = 'Active'
)
SELECT
	EmployeeID,
	EmployeeName,
	DepartmentName,
	JobTitle,
	CurrentSalary,
	MinimumBand,
	MaximumBand,
	ROUND(SalaryPercentile * 100, 2) AS CompanyPercentileRank,
	SalaryQuartile,
	CASE
		WHEN CurrentSalary > MaximumBand THEN 'ALERT: Above Allowed Maximum'
		WHEN CurrentSalary < MinimumBand THEN 'ALERT: Below Allowed Minimum'
		ELSE 'Within Approved Band'
	END AS BandComplianceStatus
FROM DepartmentSalaryStatistics
WHERE 
	CurrentSalary > MaximumBand
	OR 
	CurrentSalary < MinimumBand
	OR
	SalaryPercentile >= 0.90
ORDER BY CurrentSalary DESC;
GO

-- Annual Employee Attrition & Retention Cohort Analysis

WITH YearlyHireExitStatistics AS (
	SELECT
		YEAR(HireDate) AS CalendarYear,
		COUNT(EmployeeID) AS NewHires,
		SUM(CASE WHEN EmploymentStatus = 'Terminated' THEN 1 ELSE 0 END) AS TotalLeavers,
		AVG(CurrentSalary) AS AverageHireSalary
	FROM HR.Employees
	GROUP BY YEAR(HireDate)
)
SELECT
	CalendarYear,
	NewHires,
	TotalLeavers,
	ROUND(AverageHireSalary, 2) AS AverageHireSalary,
	ROUND((CAST(TotalLeavers AS DECIMAL(10, 2)) / NULLIF(NewHires, 0)) * 100, 2) AS AttritionRatePercentage
FROM YearlyHireExitStatistics
WHERE CalendarYear >= 2018;
GO


-- Programmable Objects, Custom Functions & Dynamic Views

-- Income Tax Calculator

IF OBJECT_ID ('HR.fn_CalculateUKTax', 'FN') IS NOT NULL
	DROP FUNCTION HR.fn_CalculateUKTax;
GO

CREATE FUNCTION HR.fn_CalculateUKTax (@GrossMonthlyPay DECIMAL(12, 2))
RETURNS DECIMAL(12, 2)
AS 
BEGIN
	DECLARE @AnnualPay DECIMAL(12, 2) = @GrossMonthlyPay * 12.00;
	DECLARE @AnnualTax DECIMAL(12, 2) = 0.00;
	DECLARE @PersonalAllowance DECIMAL(12, 2) = 12570.00;
	DECLARE @BasicRateThreshold DECIMAL(12, 2) = 50270.00;
	DECLARE @HigherRateThreshold DECIMAL(12, 2) = 125140.00;

	IF @AnnualPay > @HigherRateThreshold
	BEGIN
		SET @AnnualTax = ((@AnnualPay - @HigherRateThreshold) * 0.45)
					   + ((@HigherRateThreshold - @BasicRateThreshold) * 0.40)
					   + ((@BasicRateThreshold - @PersonalAllowance) * 0.20);
	END

	ELSE IF @AnnualPay > @BasicRateThreshold
	BEGIN
		SET @AnnualTax = ((@AnnualPay - @BasicRateThreshold) * 0.40)
					   + ((@BasicRateThreshold - @PersonalAllowance) * 0.20);
	END

	ELSE IF @AnnualPay > @PersonalAllowance
	BEGIN
		SET @AnnualTax = (@AnnualPay - @PersonalAllowance) * 0.20;
	END

	RETURN ROUND(@AnnualTax / 12.00, 2);
END;
GO

SELECT 
	SalaryID,
	EmployeeID,
	NewSalary,
	HR.fn_CalculateUKTax(NewSalary / 12.00) AS MonthlyTax
FROM HR.Salaries;

-- Real-Time Statutory Leave Balance Calculation

IF OBJECT_ID ('HR.fn_GetEmployeeLeaveBalance', 'IF') IS NOT NULL
	DROP FUNCTION HR.fn_GetEmployeeLeaveBalance;
GO

CREATE FUNCTION HR.fn_GetEmployeeLeaveBalance (@EmployeeID INT, @Year INT)
RETURNS TABLE
AS 
RETURN (
	WITH LeaveCalculations AS (
		SELECT 
			e.EmployeeID,
			CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
			28 AS UKStatutoryEntitlementDays,
			ISNULL(SUM(CASE
							WHEN a.LeaveType = 'Annual Leave' AND a.ApprovalStatus = 'Approved'
							THEN a.TotalDays 
							ELSE 0
					   END), 0) AS ApprovedLeaveDays,
			ISNULL(SUM(CASE
							WHEN a.LeaveType = 'Annual Leave' AND a.ApprovalStatus = 'Pending'
							THEN a.TotalDays 
							ELSE 0
					   END), 0) AS PendingLeaveDays,
			ISNULL(SUM(CASE
							WHEN a.LeaveType = 'Statutory Sick Pay' AND a.ApprovalStatus = 'Approved'
							THEN a.TotalDays
							ELSE 0
					   END), 0) AS SickLeaveDays
		FROM HR.Employees AS e
		LEFT JOIN HR.Absences AS a
		ON 
			e.EmployeeID = a.EmployeeID
			AND 
			YEAR(a.StartDate) = @Year
		WHERE e.EmployeeID = @EmployeeID
		GROUP BY
			e.EmployeeID,
			e.FirstName,
			e.LastName
)
SELECT
	EmployeeID,
	EmployeeName,
	UKStatutoryEntitlementDays,
	ApprovedLeaveDays,
	PendingLeaveDays,
	SickLeaveDays, 
	(UKStatutoryEntitlementDays - ApprovedLeaveDays) AS RemainingLeaveDays
FROM LeaveCalculations
);
GO

SELECT lb.*
FROM HR.Employees AS e
CROSS APPLY HR.fn_GetEmployeeLeaveBalance(e.EmployeeID, 2023) AS lb;

SELECT lb.*
FROM HR.Employees AS e
CROSS APPLY HR.fn_GetEmployeeLeaveBalance(e.EmployeeID, 2024) AS lb;

SELECT lb.*
FROM HR.Employees AS e
CROSS APPLY HR.fn_GetEmployeeLeaveBalance(e.EmployeeID, 2025) AS lb;

-- Executive Workforce Summarisation

IF OBJECT_ID('HR.vw_ExecutiveWorkforceSummary', 'V') IS NOT NULL
	DROP VIEW HR.vw_ExecutiveWorkforceSummary;
GO

CREATE VIEW HR.vw_ExecutiveWorkforceSummary
AS
SELECT	
	e.EmployeeID,
	e.NINO,
	CONCAT(e.FirstName, ' ', e.LastName) AS FullName,
	e.Email,
	d.DepartmentCode,
	d.DepartmentName,
	j.JobTitle,
	e.CurrentSalary,
	ISNULL(m.FirstName + ' ' + m.LastName, 'Executive Board') AS ReportingManager,
	DATEDIFF(YEAR, e.HireDate, GETDATE()) AS TenureYears,
	e.EmploymentStatus,
	HR.fn_CalculateUKTax(e.CurrentSalary / 12.00) AS EstimatedMonthlyPAYE,
	ROUND((e.CurrentSalary / j.MaxSalary) * 100, 2) AS MaximumBandUtilisationPercentage,
	(SELECT TOP 1 r.PerformanceScore 
		FROM HR.Reviews AS r
	 WHERE r.EmployeeID = e.EmployeeID
	 ORDER BY r.ReviewPeriodYear DESC) AS LatestPerformanceScore
FROM HR.Employees AS e
INNER JOIN HR.Departments AS d
ON e.DepartmentID = d.DepartmentID
INNER JOIN HR.Jobs AS j
ON e.JobID = j.JobID
LEFT JOIN HR.Employees AS m
ON e.ManagerID = m.EmployeeID;
GO

SELECT * 
FROM HR.vw_ExecutiveWorkforceSummary

SELECT 
	FullName,
	JobTitle,
	CurrentSalary,
	EstimatedMonthlyPAYE,
	ReportingManager,
	LatestPerformanceScore
FROM HR.vw_ExecutiveWorkforceSummary
ORDER BY CurrentSalary DESC;

SELECT TOP 5
	FullName,
	JobTitle,
	CurrentSalary,
	EstimatedMonthlyPAYE,
	ReportingManager,
	LatestPerformanceScore
FROM HR.vw_ExecutiveWorkforceSummary
WHERE DepartmentCode = 'ENG'
ORDER BY CurrentSalary DESC;

SELECT TOP 5
	FullName,
	JobTitle,
	CurrentSalary,
	EstimatedMonthlyPAYE,
	ReportingManager,
	LatestPerformanceScore
FROM HR.vw_ExecutiveWorkforceSummary
WHERE DepartmentCode = 'DATA'
ORDER BY CurrentSalary DESC;

SELECT TOP 5
	FullName,
	JobTitle,
	CurrentSalary,
	EstimatedMonthlyPAYE,
	ReportingManager,
	LatestPerformanceScore
FROM HR.vw_ExecutiveWorkforceSummary
WHERE DepartmentCode = 'FIN'
ORDER BY CurrentSalary DESC;


-- Stored Procedures, Error Handling & Transactions

-- Employee Compensation Adjustments 

IF OBJECT_ID('HR.sp_ProcessSalaryAdjustment', 'P') IS NOT NULL
	DROP PROCEDURE HR.sp_ProcessSalaryAdjustment;
GO

CREATE PROCEDURE HR.sp_ProcessSalaryAdjustment (
											@EmployeeID INT,
											@NewSalary DECIMAL(12, 2),
											@ChangeReason VARCHAR(100),
											@ModifiedBy VARCHAR(100))
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @OldSalary DECIMAL(12, 2);
	DECLARE @MinSalary DECIMAL(12, 2);
	DECLARE @MaxSalary DECIMAL(12, 2);
	DECLARE @JobID INT;

	BEGIN TRY

		SELECT
			@OldSalary = e.CurrentSalary,
			@JobID = e.JobID,
			@MinSalary = j.MinSalary,
			@MaxSalary = j.MaxSalary
		FROM HR.Employees AS e
		INNER JOIN HR.Jobs AS j 
		ON e.JobID = j.JobID
		WHERE e.EmployeeID = @EmployeeID;

		IF @OldSalary IS NULL
		BEGIN
			RAISERROR ('Validation Failure: EmployeeID %d does not exist', 16, 1, @EmployeeID);
			RETURN;
		END;

		IF @NewSalary < @MinSalary OR @NewSalary > @MaxSalary
		BEGIN
			DECLARE @ErrorMessageSalary VARCHAR(200);
			SET @ErrorMessageSalary = 'Validation Failure: Proposed salary (£'
									  + CONVERT(VARCHAR(20), @NewSalary)
									  + ') violates job salary range (£'
									  + CONVERT(VARCHAR(20), @MinSalary)
									  + ' - £'
									  + CONVERT(VARCHAR(20), @MaxSalary)
									  + ')';
			RAISERROR (@ErrorMessageSalary, 16, 1);
			RETURN;
		END;

		BEGIN TRANSACTION;

		UPDATE HR.Employees
		SET CurrentSalary = @NewSalary
		WHERE EmployeeID = @EmployeeID;

		INSERT INTO HR.Salaries (EmployeeID, OldSalary, NewSalary, ChangeReason, EffectiveDate, ModifiedBy)
		VALUES (@EmployeeID, @OldSalary, @NewSalary, @ChangeReason, CAST(SYSDATETIME() AS DATE), @ModifiedBy);

		COMMIT TRANSACTION;

		PRINT 'SUCCESS! Salary updated successfully for Employee ID ' + CAST(@EmployeeID AS VARCHAR(10));

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();

		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

	END CATCH;
END;
GO

EXEC HR.sp_ProcessSalaryAdjustment
	@EmployeeID = 1008,
	@NewSalary = 118000.00,
	@ChangeReason = 'Mid-Year Merit Bump',
	@ModifiedBy = 'c.montgomery';

SELECT
	EmployeeID,
	CurrentSalary
FROM HR.Employees
WHERE EmployeeID = 1008;

SELECT TOP 1 *
FROM HR.Salaries
WHERE EmployeeID = 1008
ORDER BY SalaryID DESC;

EXEC HR.sp_ProcessSalaryAdjustment
	@EmployeeID = 1008,
	@NewSalary = 200000.00,
	@ChangeReason = 'Invalid salary test',
	@ModifiedBy = 'test_user';

-- Automation of Monthly Payroll Run

IF OBJECT_ID('HR.sp_ExecuteMonthlyPayroll', 'P') IS NOT NULL
	DROP PROCEDURE HR.sp_ExecuteMonthlyPayroll;
GO

CREATE PROCEDURE HR.sp_ExecuteMonthlyPayroll (
											@PeriodStartDate DATE,
											@PeriodEndDate DATE)
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @NewPayrollID INT;
	DECLARE @TotalGross DECIMAL(15, 2) = 0.00;
	DECLARE @TotalDeductions DECIMAL(15, 2) = 0.00;
	DECLARE @TotalNet DECIMAL(15, 2) = 0.00;

	BEGIN TRY
		
		DECLARE @StartDateText VARCHAR(10);
		DECLARE @EndDateText VARCHAR(10);
		SET @StartDateText = CONVERT(VARCHAR(10), @PeriodStartDate, 23);
		SET @EndDateText = CONVERT(VARCHAR(10), @PeriodEndDate, 23);

		IF EXISTS (SELECT 1 FROM HR.Payrolls WHERE PeriodStartDate = @PeriodStartDate AND PeriodEndDate = @PeriodEndDate)
		BEGIN
			RAISERROR ('Validation Failure: Payroll for period %s to %s has already been processed', 16, 1, @StartDateText, @EndDateText);
			RETURN;
		END;

		BEGIN TRANSACTION;

		INSERT INTO HR.Payrolls (PeriodStartDate, PeriodEndDate, ProcessDate, RunStatus)
		VALUES (@PeriodStartDate, @PeriodEndDate, SYSDATETIME(), 'Processing');

		SET @NewPayrollID = SCOPE_IDENTITY();

		INSERT INTO HR.Payslips (
								PayrollID,
								EmployeeID,
								BasePay,
								OvertimePay,
								BonusPay,
								PAYE,
								NIC,
								PensionDeduction,
								OtherDeductions
		)
		SELECT
			@NewPayrollID,
			e.EmployeeID,
			ROUND(e.CurrentSalary / 12.00, 2) AS BasePay,
			0.00 AS OvertimePay,
			0.00 AS BonusPay,
			HR.fn_CalculateUKTax(e.CurrentSalary / 12.00) AS PAYE,
			ROUND(CASE
					WHEN (e.CurrentSalary / 12.00) > 1048.00 THEN ((e.CurrentSalary / 12.00) - 1048.00) * 0.08
					ELSE 0.00
				  END, 2) AS NIC,
			ROUND((e.CurrentSalary / 12.00) * 0.05, 2) AS PensionDeduction,
			0.00 AS OtherDeductions
		FROM HR.Employees AS e
		WHERE e.EmploymentStatus = 'Active';

		SELECT 
			@TotalGross = SUM(GrossPay),
			@TotalDeductions = SUM(PAYE + NIC + PensionDeduction + OtherDeductions),
			@TotalNet = SUM(NetPay)
		FROM HR.Payslips
		WHERE PayrollID = @NewPayrollID;

		UPDATE HR.Payrolls
		SET TotalGrossPay = ISNULL(@TotalGross, 0.00),
			TotalDeductions = ISNULL(@TotalDeductions, 0.00),
			TotalNetPay = ISNULL(@TotalNet, 0.00),
			RunStatus = 'Completed'
		WHERE PayrollID = @NewPayrollID;

		COMMIT TRANSACTION;

		PRINT 'SUCCESS! Monthly Payroll ID ' + CAST(@NewPayrollID AS VARCHAR(10)) + ' executed successfully';

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	
	END CATCH;
END;
GO

EXEC HR.sp_ExecuteMonthlyPayroll
	@PeriodStartDate = '2026-05-01',
	@PeriodEndDate = '2026-05-31';

SELECT TOP 1 *
FROM HR.Payrolls
ORDER BY PayrollID DESC;

SELECT TOP 5
	PayslipID,
	PayrollID,
	EmployeeID,
	BasePay,
	GrossPay,
	PAYE,
	NIC,
	PensionDeduction,
	NetPay
FROM HR.Payslips
WHERE PayrollID = (SELECT MAX(PayrollID) FROM HR.Payrolls)
ORDER BY EmployeeID


-- Event-Driven Automation & Auditing

-- Data Manipulation Language (DML) Audit Trigger

IF OBJECT_ID('HR.trg_Employees_Audit', 'TR') IS NOT NULL
	DROP TRIGGER HR.trg_EmployeesAudit;
GO

CREATE TRIGGER HR.trg_Employees_Audit
ON HR.Employees
AFTER UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ActionType VARCHAR(10);

	IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
		SET @ActionType = 'UPDATE';
	ELSE IF EXISTS (SELECT 1 FROM deleted)
		SET @ActionType = 'DELETE';
	ELSE
		RETURN;

	INSERT INTO Audit.AuditLog (
							TableName,
							ActionType,
							PrimaryKeyValue,
							ModifiedBy,
							ModifiedDate,
							OldValuesJSON,
							NewValuesJSON
	)
	SELECT 
		'HR.Employees' AS TableName,
		@ActionType AS ActionType,
		CAST(d.EmployeeID AS VARCHAR(50)) AS PrimaryKeyValue,
		SUSER_SNAME() AS ModifiedBy,
		SYSDATETIME() AS ModifiedDate,
		(SELECT d.EmployeeID, d.FirstName, d.LastName, d.Email, d.CurrentSalary, d.EmploymentStatus
		 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS OldValuesJSON,
		(SELECT i.EmployeeID, i.FirstName, i.LastName, i.Email, i.CurrentSalary, i.EmploymentStatus
		 FROM inserted AS i
		 WHERE i.EmployeeID = d.EmployeeID
		 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS NewValuesJSON
	FROM deleted AS d;
END;
GO

UPDATE HR.Employees
	SET Email = 'o.harrison.updated@company.co.uk',
		EmploymentStatus = 'On Leave'
	WHERE EmployeeID = 1008;

SELECT TOP 1
	AuditID,
	TableName,
	ActionType,
	PrimaryKeyValue,
	ModifiedBy,
	ModifiedDate,
	OldValuesJSON,
	NewValuesJSON
FROM Audit.AuditLog
WHERE 
	TableName = 'HR.Employees'
	AND
	PrimaryKeyValue = '1008'
ORDER BY AuditID DESC;

-- Leave Request Interception Trigger

IF OBJECT_ID('HR.trg_Absences_PreventOverlap', 'TR') IS NOT NULL
	DROP TRIGGER HR.trg_Absences_PreventOverlap;
GO

CREATE TRIGGER HR.trg_Absences_PreventOverlap
ON HR.Absences 
INSTEAD OF INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (
			SELECT 1
			FROM inserted AS i
			INNER JOIN HR.Absences AS existing 
			ON i.EmployeeID = existing.EmployeeID
			WHERE 
				existing.ApprovalStatus IN ('Approved', 'Pending')
				AND
				i.StartDate <= existing.EndDate
				AND
				i.EndDate >= existing.StartDate)

	BEGIN
		RAISERROR ('Business Constraint Violation: Employee already has an overlapping absence request submitted or approved for those dates', 16, 1);
		RETURN;
	END;

	INSERT INTO HR.Absences (EmployeeID, LeaveType, StartDate, EndDate, ApprovalStatus, ApprovedBy)
	SELECT 
		EmployeeID,
		LeaveType,
		StartDate,
		EndDate,
		ApprovalStatus,
		ApprovedBy
	FROM inserted;
END;
GO

INSERT INTO HR.Absences (EmployeeID, LeaveType, StartDate, EndDate, ApprovalStatus, ApprovedBy)
VALUES 
(1008, 'Annual Leave', '2026-11-10', '2026-11-15', 'Approved', 1002),
(1008, 'Statutory Sick Pay', '2026-11-12', '2026-11-14', 'Pending', NULL);

SELECT *
FROM HR.Absences
WHERE 
	EmployeeID = 1008
	AND
	StartDate >= '2026-11-01';


-- Performance Tuning, Indexing Strategy & Execution Plan Testing

-- Composite Non-Clustered Index for Organisational Tree Lookups

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Employees_ManagerID_Status')
	DROP INDEX IX_Employees_ManagerID_Status ON HR.Employees;
GO

CREATE NONCLUSTERED INDEX IX_Employees_ManagerID_Status
ON HR.Employees (ManagerID, EmploymentStatus)
INCLUDE (FirstName, LastName, DepartmentID, JobID, CurrentSalary)
WITH (FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = ON);
GO

-- Filtered Non-Clustered Index for Active Employees

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Employees_Active_DepartmentJob')
	DROP INDEX IX_Employees_Active_DepartmentJob ON HR.Employees;
GO

CREATE NONCLUSTERED INDEX IX_Employees_Active_DepartmentJob
ON HR.Employees (DepartmentID, JobID)
INCLUDE (CurrentSalary, HireDate, Email)
WHERE EmploymentStatus = 'Active';
GO

-- Covering Index for Payroll Processing & Line Items

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Payslips_PayrollID_Covering')
	DROP INDEX IX_Payslips_PayrollID_Covering ON HR.Payslips;
GO

CREATE NONCLUSTERED INDEX IX_Payslips_PayrollID_Covering
ON HR.Payslips (PayrollID, EmployeeID)
INCLUDE (BasePay, OvertimePay, BonusPay, PAYE, NIC, PensionDeduction);
GO

-- Filtered Index for Approved Absence Date Overlaps

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Absences_Approved_EmployeeDates')
	DROP INDEX IX_Absences_Approved_EmployeeDates ON HR.Absences
GO

CREATE NONCLUSTERED INDEX IX_Absences_Approved_EmployeeDates
ON HR.Absences (EmployeeID, StartDate, EndDate)
WHERE ApprovalStatus IN ('Approved', 'Pending');
GO

