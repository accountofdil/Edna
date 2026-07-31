USE hospital_information_management_system;
GO


-- Relational Analytics & Advanced Combining

-- Retrieve patient encounters alongside physician details, department, room location and total billed services

SELECT
	e.EncounterID,
	CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
	p.BloodType,
	CONCAT(s.FirstName, ' ', s.LastName) AS PhysicianName,
	phy.Specialty,
	d.DepartmentName,
	ISNULL(r.RoomNumber, 'Outpatient / N/A') AS RoomNumber,
	e.EncounterType,
	e.AdmitDateTime,
	e.DischargeDateTime,
	DATEDIFF(DAY, e.AdmitDateTime, ISNULL(e.DischargeDateTime, SYSDATETIME())) AS DaysAdmitted,
	ISNULL(SUM(es.BilledCost), 0.00) AS TotalServiceCharges
FROM Clinical.Encounters AS e
INNER JOIN Clinical.Patients AS p
ON e.PatientID = p.PatientID
INNER JOIN Clinical.Physicians AS phy
ON e.PhysicianID = phy.PhysicianID
INNER JOIN Admin.Staff AS s
ON phy.StaffID = s.StaffID
INNER JOIN Admin.Departments AS d
ON s.DepartmentID = d.DepartmentID
LEFT JOIN Admin.Rooms AS r
ON e.RoomID = r.RoomID
LEFT JOIN Clinical.EncounterServices AS es
ON e.EncounterID = es.EncounterID
GROUP BY
	e.EncounterID,
	p.FirstName,
	p.LastName,
	p.BloodType,
	s.FirstName,
	s.LastName,
	phy.Specialty,
	d.DepartmentName,
	r.RoomNumber,
	e.EncounterType,
	e.AdmitDateTime,
	e.DischargeDateTime
GO

-- Generate a report detailing all staff members, their roles and their direct manager superiors 

SELECT 
	emp.StaffID AS EmployeeID,
	CONCAT(emp.FirstName, ' ', emp.LastName) AS EmployeeName,
	emp.Role AS EmployeeRole,
	d.DepartmentName,
	ISNULL(CONCAT(mgr.FirstName, ' ', mgr.LastName), 'Top Level Executive') AS ManagerName,
	ISNULL(mgr.Role, 'N/A') AS ManagerRole
FROM Admin.Staff AS emp
LEFT JOIN Admin.Staff AS mgr
ON emp.ManagerID = mgr.StaffID
INNER JOIN Admin.Departments AS d
ON emp.DepartmentID = d.DepartmentID
ORDER BY
	mgr.StaffID DESC,
	emp.StaffID ASC;
GO

-- Build a multi-level organisational chart detailing employee hierarchy depth

WITH OrgHierarchy AS (
	SELECT
		StaffID,
		FirstName,
		LastName,
		Role,
		ManagerID,
		1 AS HierarchyLevel,
		CAST(CONCAT(FirstName, ' ', LastName) AS VARCHAR(500)) AS ManagementChain
	FROM Admin.Staff
	WHERE ManagerID IS NULL

	UNION ALL

	SELECT
		s.StaffID,
		s.FirstName,
		s.LastName,
		s.Role,
		s.ManagerID,
		h.HierarchyLevel + 1,
		CAST(CONCAT(h.ManagementChain, ' -> ', s.FirstName, ' ', s.LastName) AS VARCHAR(500))
	FROM Admin.Staff AS s
	INNER JOIN OrgHierarchy AS h
	ON s.ManagerID = h.StaffID
)
SELECT
	StaffID,
	CONCAT(REPLICATE('--- ', HierarchyLevel - 1), FirstName, ' ', LastName) AS IndentedEmployeeName,
	Role,
	HierarchyLevel,
	ManagementChain
FROM OrgHierarchy
ORDER BY ManagementChain;
GO

-- Find encounters where total billed cost exceeds the average billed cost for that encounter type

WITH EncounterBilling AS (
	SELECT
		e.EncounterID,
		e.EncounterType,
		b.TotalAmount,
		(SELECT AVG(b_sub.TotalAmount)
		FROM Admin.Billing AS b_sub
		INNER JOIN Clinical.Encounters AS e_sub
		ON b_sub.EncounterID = e_sub.EncounterID
		WHERE e_sub.EncounterType = e.EncounterType) AS CategoryAverageBilling
	FROM Clinical.Encounters AS e
	INNER JOIN Admin.Billing AS b
	ON e.EncounterID = b.EncounterID
)
SELECT
	EncounterID,
	EncounterType,
	TotalAmount,
	CategoryAverageBilling,
	(TotalAmount - CategoryAverageBilling) AS VarianceFromAverage
FROM EncounterBilling
WHERE TotalAmount > CategoryAverageBilling
ORDER BY
	EncounterType, 
	VarianceFromAverage DESC;
GO

-- Identify high-performing resources and distinct activity lists using set operations

SELECT
	StaffID 
FROM Admin.Staff
WHERE 
	Role Like '%Attending%'
	OR
	Role Like '%Chief%'
INTERSECT 
SELECT
	s.StaffID
FROM Clinical.Physicians AS p
INNER JOIN Admin.Staff AS s
ON p.StaffID = s.StaffID
INNER JOIN Clinical.Encounters AS e
ON p.PhysicianID = e.PhysicianID;

SELECT
	RoomID
FROM Admin.Rooms
EXCEPT
SELECT	
	DISTINCT RoomID
FROM Clinical.Encounters 
WHERE RoomID IS NOT NULL;
GO


-- Advanced Analytics & Window Functions

-- Rank all staff salaries in their respective departments

SELECT 
	d.DepartmentName,
	s.StaffID,
	CONCAT(s.FirstName, ' ', s.LastName) AS StaffName,
	s.Role,
	s.Salary,
	ROW_NUMBER() OVER (PARTITION BY s.DepartmentID ORDER BY s.Salary DESC) AS RowNumber,
	RANK() OVER (PARTITION BY s.DepartmentID ORDER BY s.Salary DESC) AS SalaryRank,
	DENSE_RANK() OVER (PARTITION BY s.DepartmentID ORDER BY s.Salary DESC) AS SalaryDenseRank,
	NTILE(4) OVER (PARTITION BY s.DepartmentID ORDER BY s.Salary DESC) AS SalaryQuartile
FROM Admin.Staff AS s
INNER JOIN Admin.Departments AS d 
ON s.DepartmentID = d.DepartmentID
WHERE s.IsActive = 1;
GO

-- Track patient encounter sequences and calculate days elapsed between consecutive hospital visits for each patient

SELECT	
	e.PatientID,
	CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
	e.EncounterID,
	e.EncounterType,
	e.AdmitDateTime,
	LAG(e.AdmitDateTime, 1) OVER (PARTITION BY e.PatientID ORDER BY e.AdmitDateTime) AS PreviousAdmitDateTime,
	DATEDIFF(DAY, LAG(e.AdmitDateTime, 1) OVER (PARTITION BY e.PatientID ORDER BY e.AdmitDateTime), e.AdmitDateTime) AS DaysSinceLastVisit,
	LEAD(e.AdmitDateTime, 1) OVER (PARTITION BY e.PatientID ORDER BY e.AdmitDateTime) AS NextAdmitDateTime
FROM Clinical.Encounters AS e
INNER JOIN Clinical.Patients AS p
ON e.PatientID = p.PatientID;
GO

-- Calculate cumulative revenue and rolling average billings over time

WITH DailyBilling AS (
	SELECT
		BillDate,
		COUNT(BillID) AS TotalBillsIssued,
		SUM(TotalAmount) AS DailyRevenue
	FROM Admin.Billing
	GROUP BY BillDate
)
SELECT
	BillDate,
	TotalBillsIssued,
	DailyRevenue,
	SUM(DailyRevenue) OVER (ORDER BY BillDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeRevenue,
	AVG(DailyRevenue) OVER (ORDER BY BillDate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS Rolling7DayAverageRevenue
FROM DailyBilling;
GO

-- Summarise encounter types side-by-side across medical departments

SELECT
	DepartmentName,
	ISNULL([Emergency], 0) AS EmergencyCount,
	ISNULL([Inpatient], 0) AS InpatientCount,
	ISNULL([Outpatient], 0) AS OutpatientCount,
	(ISNULL([Emergency], 0) + ISNULL([Inpatient], 0) + ISNULL([Outpatient], 0)) AS TotalEncounters
FROM (
	SELECT 
		d.DepartmentName,
		e.EncounterType,
		e.EncounterID
	FROM Clinical.Encounters AS e
	INNER JOIN Clinical.Physicians AS phy
	ON e.PhysicianID = phy.PhysicianID
	INNER JOIN Admin.Staff AS s
	ON phy.StaffID = s.StaffID
	INNER JOIN Admin.Departments AS d
	ON s.DepartmentID = d.DepartmentID) 
	AS SourceTable
PIVOT (
	COUNT(EncounterID)
	FOR EncounterType IN ([Emergency], [Inpatient], [Outpatient])) 
	AS PivotTable
ORDER BY TotalEncounters DESC;
GO

-- Classify encounters into financial risk tiers and calculate departmental unpaid exposure ratios across records

WITH PatientRiskBase AS (
	SELECT
		e.EncounterID,
		CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
		d.DepartmentName,
		b.TotalAmount,
		b.InsuranceCoverage,
		b.PatientAmountDue,
		b.PaymentStatus,
		CASE
			WHEN b.PaymentStatus = 'Written-Off' THEN 'High Risk - Bad Debt'
			WHEN b.PaymentStatus = 'Pending' AND b.PatientAmountDue > 1000.00 THEN 'High Risk - Large Out-of-Pocket'
			WHEN b.PaymentStatus = 'Partial' THEN 'Medium Risk - Partial Payment'
			WHEN b.PaymentStatus = 'Paid' THEN 'Low Risk - Resolved'
			ELSE 'Medium Risk - Standard Pending'
		END AS RiskTier,
		CASE
			WHEN b.PaymentStatus IN ('Pending', 'Partial', 'Written-Off') THEN b.PatientAmountDue 
			ELSE 0.00
		END AS OutstandingAmount
	FROM Admin.Billing AS b
	INNER JOIN Clinical.Encounters AS e
	ON b.EncounterID = e.EncounterID
	INNER JOIN Clinical.Patients AS p
	ON e.PatientID = p.PatientID
	INNER JOIN Clinical.Physicians AS phy
	ON e.PhysicianID = phy.PhysicianID
	INNER JOIN Admin.Staff AS s
	ON phy.StaffID = s.StaffID
	INNER JOIN Admin.Departments AS d
	ON s.DepartmentID = d.DepartmentID
)
SELECT
	EncounterID,
	PatientName,
	DepartmentName,
	TotalAmount,
	PatientAmountDue,
	PaymentStatus,
	RiskTier,
	SUM(OutstandingAmount) OVER (PARTITION BY DepartmentName) AS DepartmentTotalOutstandingBalance,
	COUNT(CASE WHEN RiskTier LIKE 'High Risk%' THEN 1 END) OVER (PARTITION BY DepartmentName) 
	AS DepartmentHighRiskEncounterCount,
	CAST(
		(PatientAmountDue / NULLIF(SUM(OutstandingAmount) OVER (PARTITION BY DepartmentName), 0)) * 100 
		AS DECIMAL(5, 2)) AS PercentageOfDepartmentOutstandingExposure
FROM PatientRiskBase
ORDER BY
	DepartmentTotalOutstandingBalance DESC,
	PatientAmountDue DESC;
GO


-- Database Programmability (Views, UDFs & Stored Procedures)

-- Provide an enterprise reporting view for active inpatient visits

IF OBJECT_ID('Clinical.vw_ActiveInpatients', 'V') IS NOT NULL
	DROP VIEW Clinical.vw_ActiveInpatients;
GO

CREATE VIEW Clinical.vw_ActiveInpatients
AS
SELECT
	e.EncounterID,
	p.PatientID,
	CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
	p.Gender,
	p.BloodType,
	DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS PatientAge,
	r.RoomNumber,
	r.RoomType,
	d.DepartmentName,
	CONCAT(s.FirstName, ' ', s.LastName) AS AttendingPhysician,
	phy.Specialty,
	e.AdmitDateTime,
	DATEDIFF(DAY, e.AdmitDateTime, SYSDATETIME()) AS CurrentDaysAdmitted
FROM Clinical.Encounters AS e
INNER JOIN Clinical.Patients AS p
ON e.PatientID = p.PatientID
INNER JOIN Admin.Rooms AS r
ON e.RoomID = r.RoomID
INNER JOIN Clinical.Physicians AS phy
ON e.PhysicianID = phy.PhysicianID
INNER JOIN Admin.Staff AS s
ON phy.StaffID = s.StaffID
INNER JOIN Admin.Departments AS d
ON r.DepartmentID = d.DepartmentID
WHERE e.Status = 'Admitted';
GO

SELECT * FROM Clinical.vw_ActiveInpatients;
GO

-- Calculate inventory replenishment urgency score based on current stock, reorder levels and unit costs

IF OBJECT_ID('Clinical.fn_CalculateReorderUrgency', 'FN') IS NOT NULL
	DROP FUNCTION Clinical.fn_CalculateReorderUrgency;
GO

CREATE FUNCTION Clinical.fn_CalculateReorderUrgency (@StockQuantity INT, @ReorderLevel INT)
RETURNS DECIMAL(5, 2)
AS 
BEGIN
	DECLARE @UrgencyScore DECIMAL(5, 2);

	IF @StockQuantity = 0
		SET @UrgencyScore = 100.00;
	ELSE IF @StockQuantity <= @ReorderLevel
		SET @UrgencyScore = 50.00 + (((CAST(@ReorderLevel AS DECIMAL) - @StockQuantity) / @ReorderLevel) * 50.00);
	ELSE
		SET @UrgencyScore = (1.00 - (CAST(@StockQuantity - @ReorderLevel AS DECIMAL) / NULLIF(@StockQuantity, 0))) * 49.00;

	IF @UrgencyScore < 0.00
		SET @UrgencyScore = 0.00;

	RETURN @UrgencyScore;
END;
GO

SELECT
	ItemID,
	ItemName,
	StockQuantity,
	ReorderLevel,
	Clinical.fn_CalculateReorderUrgency(StockQuantity, ReorderLevel) AS UrgencyScore
FROM Clinical.Inventory
GO

-- Create a modularised and parameterised query returning patient clinical history

IF OBJECT_ID('Clinical.fn_GetPatientMedicalHistory', 'IF') IS NOT NULL
	DROP FUNCTION Clinical.fn_GetPatientMedicalHistory
GO

CREATE FUNCTION Clinical.fn_GetPatientMedicalHistory (@PatientID INT)
RETURNS TABLE
AS 
RETURN
(
	SELECT
		e.EncounterID,
		e.EncounterType,
		e.AdmitDateTime,
		e.DischargeDateTime,
		CONCAT(s.FirstName, ' ', s.LastName) AS AttendingPhysician,
		phy.Specialty,
		COUNT(es.EncounterServiceID) AS TotalServicesRendered,
		ISNULL(SUM(es.BilledCost), 0.00) AS TotalBilledServices,
		b.PaymentStatus
	FROM Clinical.Encounters AS e
	INNER JOIN Clinical.Physicians AS phy
	ON e.PhysicianID = phy.PhysicianID
	INNER JOIN Admin.Staff AS s
	ON phy.StaffID = s.StaffID
	LEFT JOIN Clinical.EncounterServices AS es
	ON e.EncounterID = es.EncounterID
	LEFT JOIN Admin.Billing AS b
	ON e.EncounterID = b.EncounterID
	WHERE e.PatientID = @PatientID
	GROUP BY
		e.EncounterID,
		e.EncounterType,
		e.AdmitDateTime,
		e.DischargeDateTime,
		s.FirstName,
		s.LastName,
		phy.Specialty,
		b.PaymentStatus);
GO

SELECT * FROM Clinical.fn_GetPatientMedicalHistory(5000);
GO

-- Create a patient admission stored procedure that verifies room availability, updates room status and logs the transaction

IF OBJECT_ID('Clinical.sp_AdmitPatient', 'P') IS NOT NULL
	DROP PROCEDURE Clinical.sp_AdmitPatient;
GO

CREATE PROCEDURE Clinical.sp_AdmitPatient (
										@PatientID INT, 
										@PhysicianID INT, 
										@RoomID INT, 
										@EncounterType VARCHAR(20), 
										@NewEncounterID INT OUTPUT)
AS 
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM Admin.Rooms WHERE RoomID = @RoomID AND IsOccupied = 1)
	BEGIN
		RAISERROR('Error: Selected room is occupied', 16, 1);
		RETURN;
	END

	IF NOT EXISTS (SELECT 1 FROM Clinical.Patients WHERE PatientID = @PatientID)
	BEGIN
		RAISERROR('Error: PatientID does not exist', 16, 1);
		RETURN;
	END 

	BEGIN TRY
	
		BEGIN TRANSACTION;

		INSERT INTO Clinical.Encounters (PatientID, PhysicianID, RoomID, EncounterType, AdmitDateTime, Status)
		VALUES
		(@PatientID, @PhysicianID, @RoomID, @EncounterType, SYSDATETIME(), 'Admitted');

		SET @NewEncounterID = SCOPE_IDENTITY();

		UPDATE Admin.Rooms
		SET IsOccupied = 1
		WHERE RoomID = @RoomID;

		INSERT INTO Admin.Billing (EncounterID, TotalAmount, InsuranceCoverage, PaymentStatus, BillDate)
		VALUES
		(@NewEncounterID, 0.00, 0.00, 'Pending', CAST(SYSDATETIME() AS DATE));

		INSERT INTO Audit.SystemLogs (TableName, OperationType, Details)
		VALUES 
		('Encounters', 'INSERT', CONCAT('PatientID', @PatientID, ' admitted under EncounterID ', @NewEncounterID));

		COMMIT TRANSACTION
		
		PRINT CONCAT('Patient successfully admitted. New Encounter ID: ', @NewEncounterID);

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();

		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

	END CATCH
END;
GO

DECLARE @GeneratedEncounterID INT;

EXEC Clinical.sp_AdmitPatient
	@PatientID = 5003,
	@PhysicianID = 3000,
	@RoomID = 201,
	@EncounterType = 'Inpatient',
	@NewEncounterID = @GeneratedEncounterID OUTPUT;

SELECT * FROM Clinical.Encounters
WHERE PatientID = 5003;

SELECT * FROM Admin.Rooms 
WHERE RoomID = 201;

SELECT * FROM Admin.Billing
WHERE BillDate = '2026-07-31';

SELECT * FROM Audit.SystemLogs 
WHERE TableName = 'Encounters';

-- Create a stored procedure that processes patient discharge, calculates room/service totals and finalises billing

IF OBJECT_ID('Admin.sp_DischargePatientAndFinaliseBill', 'P') IS NOT NULL
	DROP PROCEDURE Admin.sp_DischargePatientAndFinaliseBill;
GO

CREATE PROCEDURE Admin.sp_DischargePatientAndFinaliseBill (
															@EncounterID INT,
															@InsuranceCoverage DECIMAL(10, 2) = 0.00,
															@FinalTotalAmount DECIMAL(10, 2) OUTPUT,
															@PatientAmountDue DECIMAL(10, 2) OUTPUT)
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @PatientID INT;
	DECLARE @RoomID INT;
	DECLARE @AdmitDate DATETIME2;
	DECLARE @DischargeDate DATETIME2 = SYSDATETIME();
	DECLARE @RoomDays INT;
	DECLARE @RoomDailyRate DECIMAL(8, 2) = 0.00;
	DECLARE @TotalRoomCharges DECIMAL(10, 2) = 0.00;
	DECLARE @TotalServiceCharges DECIMAL(10, 2) = 0.00;
	DECLARE @CurrentStatus VARCHAR(20);

	SELECT 
		@PatientID = PatientID,
		@RoomID = RoomID,
		@AdmitDate = AdmitDateTime,
		@CurrentStatus = Status
	FROM Clinical.Encounters
	WHERE EncounterID = @EncounterID;

	IF @PatientID IS NULL
	BEGIN
		RAISERROR('Error: EncounterID %d not found', 16, 1, @EncounterID);
		RETURN;
	END

	IF @CurrentStatus <> 'Admitted'
	BEGIN
		RAISERROR('Error: EncounterID %d is already discharged or cancelled', 16, 1, @EncounterID);
		RETURN;
	END

	BEGIN TRY

		BEGIN TRANSACTION;

		IF @RoomID IS NOT NULL
		BEGIN
			SELECT @RoomDailyRate = DailyRate
			FROM Admin.Rooms
			WHERE RoomID = @RoomID;
			SET @RoomDays = DATEDIFF(DAY, @AdmitDate, @DischargeDate);
			IF @RoomDays < 1 SET @RoomDays = 1;
			SET @TotalRoomCharges = @RoomDays * @RoomDailyRate;
		END

		SELECT @TotalServiceCharges = ISNULL(SUM(BilledCost), 0.00)
		FROM Clinical.EncounterServices
		WHERE EncounterID = @EncounterID;
		SET @FinalTotalAmount = @TotalRoomCharges + @TotalServiceCharges;
		IF @InsuranceCoverage > @FinalTotalAmount
			SET @InsuranceCoverage = @FinalTotalAmount;
		SET @PatientAmountDue = @FinalTotalAmount - @InsuranceCoverage;

		UPDATE Clinical.Encounters
		SET DischargeDateTime = @DischargeDate,
			Status = 'Discharged'
		WHERE EncounterID = @EncounterID;

		IF @RoomID IS NOT NULL
		BEGIN
			UPDATE Admin.Rooms
			SET IsOccupied = 0
			WHERE RoomID = @RoomID;
		END
		
		IF EXISTS (SELECT 1 FROM Admin.Billing WHERE EncounterID = @EncounterID)
		BEGIN
			UPDATE Admin.Billing
			SET TotalAmount = @FinalTotalAmount,
				InsuranceCoverage = @InsuranceCoverage,
				PaymentStatus = CASE WHEN @PatientAmountDue = 0.00 THEN 'Paid' ELSE 'Pending' END,
				BillDate = CAST(@DischargeDate AS DATE)
			WHERE EncounterID = @EncounterID;
		END
		ELSE
		BEGIN
			INSERT INTO Admin.Billing (EncounterID, TotalAmount, InsuranceCoverage, PaymentStatus, BillDate)
			VALUES
			(@EncounterID, @FinalTotalAmount, @InsuranceCoverage, 
			CASE WHEN @PatientAmountDue = 0.00 THEN 'Paid' ELSE 'Pending' END,
			CAST(@DischargeDate AS DATE));
		END

		INSERT INTO Audit.SystemLogs (TableName, OperationType, Details)
		VALUES
		('Encounters', 'UPDATE', CONCAT('EncounterID ', @EncounterID, ' successfully discharged. Total Bill: $', @FinalTotalAmount));

		COMMIT TRANSACTION;

		PRINT CONCAT('Encounter ', @EncounterID, ' discharged. Final Bill Amount: $', @FinalTotalAmount);

	END TRY

	BEGIN CATCH
	
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();

		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

	END CATCH
END;
GO

SELECT 'PRE-EXECUTION' AS TestPhase, EncounterID, RoomID, Status, DischargeDateTime
FROM Clinical.Encounters
WHERE EncounterID = 10082;

SELECT 'PRE-EXECUTION' AS TestPhase, RoomID, RoomNumber, IsOccupied
FROM Admin.Rooms
WHERE RoomID = 207;

SELECT 'PRE-EXECUTION' AS TestPhase, BillID, EncounterID, TotalAmount, InsuranceCoverage, PaymentStatus
FROM Admin.Billing
WHERE EncounterID = 10082;
GO

DECLARE @CalculatedTotal DECIMAL(10, 2);
DECLARE @CalculatedDue DECIMAL(10, 2);

EXEC Admin.sp_DischargePatientAndFinaliseBill
	@EncounterID = 10082,
	@InsuranceCoverage = 400.00,
	@FinalTotalAmount = @CalculatedTotal OUTPUT,
	@PatientAmountDue = @CalculatedDue OUTPUT;

SELECT
	10082 AS TestedEncounterID,
	@CalculatedTotal AS ProcedureCalculatedTotal,
	400.00 AS InsuranceApplied,
	@CalculatedDue AS OutOfPocketAmountDue;
GO

SELECT 
	EncounterID,
	PatientID,
	PhysicianID,
	RoomID,
	Status,
	AdmitDateTime,
	DischargeDateTime,
	CASE
		WHEN Status = 'Discharged' AND DischargeDateTime IS NOT NULL THEN 'PASS'
		ELSE 'FAIL'
	END AS EncountersTableTest
FROM Clinical.Encounters
WHERE EncounterID = 10082;
GO

SELECT 
	r.RoomID,
	r.RoomNumber,
	r.IsOccupied,
	CASE
		WHEN r.IsOccupied = 0 THEN 'PASS'
		ELSE 'FAIL'
	END AS RoomsTableTest
FROM Admin.Rooms AS r
INNER JOIN Clinical.Encounters AS e
ON e.RoomID = r.RoomID
WHERE e.EncounterID = 10082;
GO

SELECT
	BillID,
	EncounterID,
	TotalAmount,
	InsuranceCoverage,
	PatientAmountDue,
	PaymentStatus,
	BillDate,
	CASE
		WHEN TotalAmount > 0 AND BillDate = CAST(SYSDATETIME() AS DATE) THEN 'PASS'
		ELSE 'FAIL'
	END AS BillingTableTest
FROM Admin.Billing
WHERE EncounterID = 10082;
GO

SELECT TOP 1
	LogID,
	TableName,
	OperationType,
	ExecutionTime,
	ExecutedBy,
	Details,
	CASE
		WHEN Details LIKE '%EncounterID 10082 successfully discharged%' THEN 'PASS'
		ELSE 'FAIL'
	END AS AuditLogsTableTest
FROM Audit.SystemLogs
WHERE
	TableName = 'Encounters'
	AND 
	Details LIKE '%10082%'
ORDER BY LogID DESC;
GO


-- Event Automation & Data Integrity

-- Create a trigger to update room as occupied whenever a new active inpatient encounter is inserted

IF OBJECT_ID('Clinical.trg_AfterEncounterInsert_SyncRoom', 'TR') IS NOT NULL
	DROP TRIGGER Clinical.trg_AfterEncounterInsert_SyncRoom;
GO

CREATE TRIGGER Clinical.trg_AfterEncounterInsert_SyncRoom
ON Clinical.Encounters
AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	UPDATE r
	SET r.IsOccupied = 1
	FROM Admin.Rooms AS r
	INNER JOIN inserted AS i
	ON r.RoomID = i.RoomID
	WHERE 
		i.RoomID IS NOT NULL
		AND
		i.status = 'Admitted'

	INSERT INTO Audit.SystemLogs (TableName, OperationType, Details)
	SELECT
		'Rooms',
		'UPDATE',
		CONCAT('Automated Trigger: RoomID ', i.RoomID, ' set to occupied for EncounterID ', i.EncounterID)
	FROM inserted AS i
	WHERE 
		i.RoomID IS NOT NULL
		AND 
		i.Status = 'Admitted';
END;
GO

UPDATE Admin.Rooms 
SET IsOccupied = 0 
WHERE RoomID = 209;

SELECT 'PRE-CHECK' AS TestPhase, RoomID, RoomNumber, IsOccupied
FROM Admin.Rooms 
WHERE RoomID = 209;

INSERT INTO Clinical.Encounters (PatientID, PhysicianID, RoomID, EncounterType, AdmitDateTime, Status)
VALUES (5005, 3001, 209, 'Inpatient', SYSDATETIME(), 'Admitted');

DECLARE @NewEncounterID INT = SCOPE_IDENTITY();

SELECT
	EncounterID,
	PatientID,
	PhysicianID,
	RoomID,
	Status,
	CASE
		WHEN Status = 'Admitted' THEN 'PASS'
		ELSE 'FAIL'
	END AS EncountersTableTest
FROM Clinical.Encounters
WHERE EncounterID = @NewEncounterID;

SELECT
	RoomID,
	RoomNumber,
	IsOccupied,
	CASE
		WHEN IsOccupied = 1 THEN 'PASS'
		ELSE 'FAIL'
	END AS TriggerRoomSyncTest
FROM Admin.Rooms
WHERE RoomID = 209;

SELECT TOP 1
	LogID,
	TableName,
	OperationType,
	ExecutionTime,
	Details,
	CASE 
		WHEN Details LIKE '%Automated Trigger: RoomID 209%' THEN 'PASS'
		ELSE 'FAIL'
	END AS TriggerAuditLogTest
FROM Audit.SystemLogs
WHERE TableName = 'Rooms'
ORDER BY LogID DESC;
GO

-- Create a trigger that fires on staff table whenever compensation or role details are modified

IF OBJECT_ID('Admin.trg_AfterStaffUpdate_AuditSalary', 'TR') IS NOT NULL
	DROP TRIGGER Admin.trg_AfterStaffUpdate_AuditSalary
GO

CREATE TRIGGER Admin.trg_AfterStaffUpdate_AuditSalary
ON Admin.Staff
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF UPDATE(Salary) OR UPDATE(Role)
	BEGIN
		INSERT INTO Audit.SystemLogs (TableName, OperationType, Details)
		SELECT
			'Staff',
			'UPDATE',
			CONCAT(
				'StaffID ', i.StaffID, ' (', i.FirstName, ' ', i.LastName, ') updated. ',
				'Old Role: [', d.Role, '], New Role: [', i.Role, ']. ',
				'Old Salary: $', d.Salary, ', New Salary: $', i.Salary)
		FROM inserted AS i
		INNER JOIN deleted AS d
		ON i.StaffID = d.StaffID
		WHERE d.Salary <> i.Salary OR d.Role <> i.Role;
	END
END;
GO

UPDATE Admin.Staff
SET 
	Salary = Salary + 5000.00,
	Role = 'Senior Radiology Technician'
WHERE StaffID = 1052;

SELECT
	StaffID,
	FirstName,
	LastName,
	Role, 
	Salary
FROM Admin.Staff
WHERE StaffID = 1052;

SELECT TOP 1
	LogID,
	TableName,
	OperationType,
	ExecutionTime,
	Details,
	CASE
		WHEN Details LIKE '%StaffID 1052%' THEN 'PASS'
		ELSE 'FAIL'
	END AS SalaryAuditTriggerTest
FROM Audit.SystemLogs
WHERE 
	TableName = 'Staff'
	AND
	Details LIKE '%1052%'
ORDER BY LogID DESC;
GO

-- Create a trigger that intercepts insertions targeted at the active inpatients view

IF OBJECT_ID('Clinical.trg_InsteadOfInsert_ActiveInpatientsView', 'TR') IS NOT NULL
	DROP TRIGGER Clinical.trg_InsteadOfInsert_ActiveInpatientsView;
GO

CREATE TRIGGER Clinical.trg_InsteadOfInsert_ActiveInpatientsView
ON Clinical.vw_ActiveInpatients
INSTEAD OF INSERT
AS 
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM inserted)
	BEGIN
		INSERT INTO Clinical.Encounters (PatientID, PhysicianID, RoomID, EncounterType, AdmitDateTime, Status)
		SELECT
			i.PatientID,
			(SELECT TOP 1 PhysicianID FROM Clinical.Physicians),
			r.RoomID,
			'Inpatient',
			SYSDATETIME(),
			'Admitted'
		FROM inserted AS i
		LEFT JOIN Admin.Rooms AS r
		ON r.RoomNumber = i.RoomNumber;
	END
END;
GO

INSERT INTO Clinical.vw_ActiveInpatients (PatientID, RoomNumber)
VALUES (5008, '101-GW');

SELECT TOP 1
	EncounterID,
	PatientID,
	PhysicianID,
	RoomID,
	Status,
	AdmitDateTime,
	CASE
		WHEN PatientID = 5008 AND Status = 'Admitted' THEN 'PASS'
		ELSE 'FAIL'
	END AS InsteadOfTriggerEncounterTest
FROM Clinical.Encounters
WHERE PatientID = 5008
ORDER BY EncounterID DESC;

SELECT
	EncounterID,
	PatientID,
	PatientName,
	RoomNumber
FROM Clinical.vw_ActiveInpatients
WHERE PatientID = 5008;
GO


-- Transactions, Concurrency & Security

-- Process a batch financial adjustment and reconciliation with partial savepoint recovery

BEGIN TRANSACTION BatchPaymentReconciliation;

BEGIN TRY

		UPDATE Admin.Billing
		SET PaymentStatus = 'Paid'
		WHERE BillID = 7018;

		SAVE TRANSACTION PostPrimaryUpdate;

		UPDATE Admin.Billing
		SET TotalAmount = TotalAmount - 100.00
		WHERE BillID = 7030;

		IF EXISTS (SELECT 1 FROM Admin.Billing WHERE BillID = 7030 AND TotalAmount < 0)
		BEGIN
			RAISERROR('Invalid negative billing total detected', 16, 1);
		END

		COMMIT TRANSACTION BatchPaymentReconciliation;

		PRINT 'Batch reconciliation committed successfully';

END TRY

BEGIN CATCH

	PRINT 'Error encountered in batch step 2. Rolling back to savepoint PostPrimaryUpdate';

	ROLLBACK TRANSACTION PostPrimaryUpdate;

	INSERT INTO Audit.SystemLogs (TableName, OperationType, Details)
	VALUES ('Billing', 'UPDATE', CONCAT('Partial transaction rollback executed: ', ERROR_MESSAGE()));

	COMMIT TRANSACTION BatchPaymentReconciliation;

	PRINT 'Primary batch update preserved and committed';

END CATCH;
GO

SELECT
	BillID,
	PaymentStatus,
	CASE
		WHEN PaymentStatus = 'Paid' THEN 'PASS'
		ELSE 'FAIL'
	END AS PrimaryUpdateTest
FROM Admin.Billing
WHERE BillID = 7018;

SELECT TOP 1
	LogID,
	TableName,
	OperationType,
	ExecutionTime,
	Details,
	CASE
		WHEN Details LIKE '%Partial transaction rollback%' THEN 'PASS'
		ELSE 'FAIL'
	END AS SavepointAuditTest
FROM Audit.SystemLogs
WHERE TableName = 'Billing'
ORDER BY LogID DESC;
GO

-- Safely read and update pharmacy stock without dirty or non-repeatable reads

IF OBJECT_ID('Clinical.sp_DeductInventoryStock', 'P') IS NOT NULL
	DROP PROCEDURE Clinical.sp_DeductInventoryStock
GO

CREATE PROCEDURE Clinical.sp_DeductInventoryStock (@ItemID INT, @DeductQuantity INT)
AS 
BEGIN
	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

	BEGIN TRY

		BEGIN TRANSACTION;

		DECLARE @CurrentStock INT;

		SELECT @CurrentStock = StockQuantity 
		FROM Clinical.Inventory WITH (UPDLOCK, HOLDLOCK)
		WHERE ItemID = @ItemID;

		IF @CurrentStock < @DeductQuantity
		BEGIN
			RAISERROR('Insufficient stock quantity available', 16, 1);
		END

		UPDATE Clinical.Inventory
		SET StockQuantity = StockQuantity - @DeductQuantity 
		WHERE ItemID = @ItemID;

		INSERT INTO Audit.SystemLogs (TableName, OperationType, Details)
		VALUES ('Inventory', 'UPDATE', CONCAT('Deducted ', @DeductQuantity, ' units from ItemID ', @ItemID));

		COMMIT TRANSACTION;

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION;

		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		RAISERROR(@ErrorMessage, 16, 1);
	
	END CATCH
END;
GO

DECLARE @InitialStock INT;

SELECT @InitialStock = StockQuantity 
FROM Clinical.Inventory 
WHERE ItemID = 800;

EXEC Clinical.sp_DeductInventoryStock 
	@ItemID = 800,
	@DeductQuantity = 10;

SELECT 
	ItemID,
	ItemName,
	StockQuantity,
	CASE
		WHEN StockQuantity = (@InitialStock - 10) THEN 'PASS'
		ELSE 'FAIL'
	END AS ConcurrencyStockDeductionTest
FROM Clinical.Inventory
WHERE ItemID = 800;

SELECT TOP 1
	LogID,
	TableName,
	OperationType,
	Details,
	CASE
		WHEN Details LIKE '%ItemID 800%' THEN 'PASS'
		ELSE 'FAIL'
	END AS ConcurrencyAuditTest
FROM Audit.SystemLogs
WHERE TableName = 'Inventory'
ORDER BY LogID DESC;
GO

-- Define and customise role-based access control across Clinical and Admin schemas 

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ClinicalPhysicianRole')
	CREATE ROLE ClinicalPhysicianRole;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BillingAdminRole')
	CREATE ROLE BillingAdminRole;
GO

GRANT SELECT ON Clinical.Patients TO ClinicalPhysicianRole;
GRANT SELECT, INSERT, UPDATE ON Clinical.Encounters TO ClinicalPhysicianRole;
GRANT SELECT, INSERT ON Clinical.EncounterServices TO ClinicalPhysicianRole;
GRANT EXECUTE ON SCHEMA::Clinical TO ClinicalPhysicianRole;
DENY SELECT, UPDATE, DELETE ON Admin.Billing TO ClinicalPhysicianRole;
GRANT SELECT, UPDATE ON Admin.Billing TO BillingAdminRole;
GRANT SELECT ON Clinical.vw_ActiveInpatients TO BillingAdminRole;
GRANT EXECUTE ON Admin.sp_DischargePatientAndFinaliseBill TO BillingAdminRole;
GO

SELECT 
	name AS RoleName,
	type_desc,
	CASE 
		WHEN name IN ('ClinicalPhysicianRole', 'BillingAdminRole') THEN 'PASS'
		ELSE 'FAIL'
	END AS RoleExistenceTest
FROM sys.database_principals
WHERE name IN ('ClinicalPhysicianRole', 'BillingAdminRole')

SELECT
	pr.name AS RoleName,
	pe.permission_name,
	pe.state_desc,
	OBJECT_NAME(pe.major_id) AS ObjectName
FROM sys.database_permissions AS pe
INNER JOIN sys.database_principals AS pr
ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name IN ('ClinicalPhysicianRole', 'BillingAdminRole')
ORDER BY RoleName, ObjectName;
GO


-- Performance Tuning & Verification Suite

-- Build optimised non-clustered indexes to satisfy critical reporting queries and requirements 

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Encounters_ActiveAdmissions')
	DROP INDEX IX_Encounters_ActiveAdmissions ON Clinical.Encounters;
GO

CREATE NONCLUSTERED INDEX IX_Encounters_ActiveAdmissions
ON Clinical.Encounters (PatientID, PhysicianID, RoomID)
INCLUDE (AdmitDateTime, EncounterType)
WHERE Status = 'Admitted';
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_BillingStatus_Coverage')
	DROP INDEX IX_BillingStatus_Coverage ON Admin.Billing;
GO

CREATE NONCLUSTERED INDEX IX_BillingStatus_Coverage
ON Admin.Billing (PaymentStatus, BillDate)
INCLUDE (EncounterID, TotalAmount, InsuranceCoverage, PatientAmountDue);
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EncounterServices_EncounterID_ServiceID')
	DROP INDEX IX_EncounterServices_EncounterID_ServiceID ON Clinical.EncounterServices;
GO

CREATE NONCLUSTERED INDEX IX_EncounterServices_EncounterID_ServiceID
ON Clinical.EncounterServices (EncounterID, ServiceID)
INCLUDE (BilledCost, ServiceDateTime);
GO

SELECT 
	i.name AS IndexName,
	t.name AS TableName,
	i.type_desc AS IndexType,
	i.is_primary_key,
	i.has_filter,
	i.filter_definition,
	CASE
		WHEN i.name IS NOT NULL THEN 'PASS'
		ELSE 'FAIL'
	END AS IndexCreationTest
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
ON i.object_id = t.object_id
WHERE i.name IN ('IX_Encounters_ActiveAdmissions', 
				 'IX_BillingStatus_Coverage', 
				 'IX_EncounterServices_EncounterID_ServiceID')
ORDER BY TableName, IndexName;
GO

-- Transform a non-SARGable query into a SARGable format for the purpose of an index seek

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT 
	BillID,
	EncounterID,
	TotalAmount,
	BillDate
FROM Admin.Billing
WHERE 
	YEAR(BillDate) = 2023
	AND
	MONTH(BillDate) = 11;
GO

SELECT 
	BillID,
	EncounterID,
	TotalAmount,
	BillDate
FROM Admin.Billing
WHERE 
	BillDate >= '2023-11-01'
	AND 
	BillDate < '2023-12-01';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

WITH NonSargableResults AS (
						SELECT BillID, EncounterID, TotalAmount
						FROM Admin.Billing
						WHERE 
							YEAR(BillDate) = 2023
							AND
							MONTH(BillDate) = 11
),
SargableResults AS (
				SELECT
					BillID,
					EncounterID,
					TotalAmount
				FROM Admin.Billing 
				WHERE
					BillDate >= '2023-11-01'
					AND 
					BillDate < '2023-12-01'
)
SELECT 
	(SELECT COUNT(*) FROM NonSargableResults) AS NonSargableRowCount,
	(SELECT COUNT(*) FROM SargableResults) AS SargableRowCount,
	CASE	
		WHEN (SELECT COUNT(*) FROM (SELECT * FROM NonSargableResults EXCEPT SELECT * FROM SargableResults) AS Difference) = 0
		THEN 'PASS'
		ELSE 'FAIL'
	END AS RewriteAccuracyTest;
GO

-- Execute an audit across tables, views, functions and procedures to confirm the project is operational 

SELECT 
	'Admin.Departments' AS ObjectName, 
	'Table' AS ObjectType, 
	COUNT(*) AS RecordCount 
FROM Admin.Departments
UNION ALL SELECT 'Admin.Staff', 'Table', COUNT(*) FROM Admin.Staff
UNION ALL SELECT 'Clinical.Patients', 'Table', COUNT(*) FROM Clinical.Patients
UNION ALL SELECT 'Admin.Rooms', 'Table', COUNT(*) FROM Admin.Rooms
UNION ALL SELECT 'Clinical.Physicians', 'Table', COUNT(*) FROM Clinical.Physicians
UNION ALL SELECT 'Clinical.MedicalServices', 'Table', COUNT(*) FROM Clinical.MedicalServices
UNION ALL SELECT 'Clinical.Inventory', 'Table', COUNT(*) FROM Clinical.Inventory
UNION ALL SELECT 'Clinical.Encounters', 'Table', COUNT(*) FROM Clinical.Encounters
UNION ALL SELECT 'Clinical.EncounterServices', 'Table', COUNT(*) FROM Clinical.EncounterServices
UNION ALL SELECT 'Admin.Billing', 'Table', COUNT(*) FROM Admin.Billing
UNION ALL SELECT 'Audit.SystemLogs', 'Table', COUNT(*) FROM Audit.SystemLogs
UNION ALL SELECT 'Clinical.vw_ActiveInpatients', 'View', COUNT(*) FROM Clinical.vw_ActiveInpatients
UNION ALL SELECT 'Clinical.fn_CalculateReorderUrgency', 'Scalar Function', 1
UNION ALL SELECT 'Clinical.fn_GetPatientMedicalHistory', 'Table Function', 1
UNION ALL SELECT 'Clinical.sp_AdmitPatient', 'Stored Procedure', 1
UNION ALL SELECT 'Admin.sp_DischargePatientAndFinaliseBill', 'Stored Procedure', 1
UNION ALL SELECT 'Clinical.sp_DeductInventoryStock', 'Stored Procedure', 1;
GO
