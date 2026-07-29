USE football_club_management_system;


-- Fundamentals & Data Aggregation

-- Summarise player match statistics for games completed in the 2024/25 season
-- Calculate total goals, total assists, average match ratings and total minutes per player
-- Ensure to include players who have accumulated at least 180 minutes of game time

SELECT TOP 10
	p.PlayerID,
	CONCAT(p.FirstName, ' ', p.LastName) AS PlayerName,
	p.PrimaryPosition,
	COUNT(pms.MatchID) AS MatchesPlayed,
	SUM(pms.MinutesPlayed) AS TotalMinutesPlayed,
	SUM(pms.GoalsScored) AS TotalGoals,
	SUM(pms.Assists) AS TotalAssists,
	CAST(AVG(pms.MatchRating) AS DECIMAL(3, 2)) AS AverageMatchRating
FROM club.Players AS p
INNER JOIN club.PlayerMatchStats AS pms
ON p.PlayerID = pms.PlayerID
INNER JOIN club.Matches AS m
ON pms.MatchID = m.MatchID
WHERE 
	m.Season IN ('2024/25', '2025/26')
	AND 
	m.MatchStatus = 'Completed'
GROUP BY 
	p.PlayerID,
	p.FirstName,
	p.LastName,
	p.PrimaryPosition
HAVING SUM(pms.MinutesPlayed) >= 180
ORDER BY 
	TotalGoals DESC,
	AverageMatchRating DESC;
GO

-- The finance team requires a breakdown of active player contract allocations
-- Identify players earning between £20,000 and £60,000 per week whose contracts are active
-- Summarise total earnings, potential release clause values and bonuses per position

SELECT 
	p.PrimaryPosition,
	COUNT(p.PlayerID) AS TotalPlayers,
	SUM(c.WeeklyWage * 52) AS AnnualBaseWageExpenditure,
	SUM(COALESCE(c.SigningBonus, 0.00)) AS TotalSigningBonusesCommitted,
	SUM(COALESCE(c.ReleaseClause, 0.00)) AS TotalReleaseClauseValue,
	SUM(CASE 
			WHEN p.PreferredFoot = 'Left' THEN 1 
			ELSE 0 
			END) AS LeftFootedPlayers,
	SUM(CASE
			WHEN p.PreferredFoot = 'Right' THEN 1
			ELSE 0
			END) AS RightFootedPlayers,
	SUM(CASE
			WHEN p.PreferredFoot = 'Both' THEN 1
			ELSE 0
			END) AS BothFootedPlayers
FROM club.Players AS p
INNER JOIN club.Contracts AS c
ON p.PlayerID = c.PlayerID
WHERE 
	c.ContractStatus IN ('Active', 'Pending')
	AND 
	c.WeeklyWage BETWEEN 20000.00 AND 60000.00
	AND 
	(p.Nationality LIKE '[A-M]%' OR p.Nationality IN ('Brazil', 'Argentina', 'Uruguay'))
GROUP BY p.PrimaryPosition
HAVING COUNT(p.PlayerID) >= 2
ORDER BY AnnualBaseWageExpenditure DESC;
GO

-- The web portal team requires paginated queries returning financial expense transactions
-- For these audit purposes, please provide 20 records per page in descending date order

DECLARE @PageNumber INT = 2;
DECLARE @RowsPerPage INT = 20;

SELECT
	TransactionID,
	TransactionDate,
	Category,
	Amount,
	Description
FROM club.FinancialTransactions
WHERE TransactionType = 'Expense'
ORDER BY 
	TransactionDate DESC, 
	TransactionID DESC
OFFSET (@PageNumber - 1) * @RowsPerPage ROWS
FETCH NEXT @RowsPerPage ROWS ONLY;
GO


-- Advanced Joins, Set Operations & Subqueries

-- The data engineering team needs a report showing all players currently on active contracts who have zero recorded match appearances
-- The purpose of this report is to spot squad members that are sitting idle in comparison to their compensation

SELECT 
	p.PlayerID,
	CONCAT(p.FirstName, ' ', p.LastName) AS PlayerName,
	p.PrimaryPosition,
	t.TeamName,
	c.WeeklyWage,
	c.ContractStatus
FROM club.Players AS p
INNER JOIN club.Teams AS t
ON p.TeamID = t.TeamID
INNER JOIN club.Contracts AS c
ON p.PlayerID = c.PlayerID
LEFT JOIN club.PlayerMatchStats AS pms
ON p.PlayerID = pms.PlayerID
WHERE 
	c.ContractStatus = 'Active'
	AND
	pms.StatID IS NULL
ORDER BY c.WeeklyWage DESC;
GO

-- The technical staff wants to generate an expected training matrix for first team players against recent training sessions
-- The purpose of this matrix is to spot missing log entries where a player was expected to train but has no logged record

WITH ExpectedTrainingMatrix AS(
	SELECT	
		p.PlayerID,
		CONCAT(p.FirstName, ' ', p.LastName) AS PlayerName,
		ts.SessionID,
		ts.FocusArea,
		ts.SessionDate
	FROM club.Players AS p
	CROSS JOIN club.TrainingSessions AS ts
	WHERE 
		p.TeamID = 1
		AND 
		ts.SessionID BETWEEN 3000 AND 3004)
SELECT 
	etm.PlayerID,
	etm.PlayerName,
	etm.SessionID,
	etm.FocusArea
FROM ExpectedTrainingMatrix AS etm
LEFT JOIN club.PlayerTrainingLogs AS ptl
ON etm.SessionID = ptl.SessionID
AND etm.PlayerID = ptl.PlayerID
ORDER BY 
	etm.PlayerID,
	etm.SessionID;
GO

-- The scouting and HR departments need a unified communication contact directory
-- This should contain first team staff and first team players who are currently available

SELECT
	StaffID AS EntityID,
	CONCAT(FirstName, ' ', LastName) AS FullName,
	Role AS PositionOrRole,
	'Staff' As EntityType,
	MonthlySalary * 12 AS AnnualCompensation
FROM club.Staff
WHERE 
	IsActive = 1
	AND 
	MonthlySalary >= 10000.00

UNION ALL

SELECT 
	p.PlayerID AS EntityID,
	CONCAT(p.FirstName, ' ', p.LastName) AS FullName,
	p.PrimaryPosition AS PositionOrRole,
	'Player' AS EntityType,
	c.WeeklyWage * 52 AS AnnualCompensation
FROM club.Players AS p
INNER JOIN club.Contracts AS c
ON p.PlayerID = c.PlayerID
WHERE c.ContractStatus = 'Active'

EXCEPT 

SELECT 
	p.PlayerID AS EntityID,
	CONCAT(p.FirstName, ' ', p.LastName) AS FullName,
	p.PrimaryPosition AS PositionOrRole,
	'Player' AS EntityType,
	c.WeeklyWage * 52 AS AnnualCompensation
FROM club.Players AS p
INNER JOIN club.Contracts AS c
ON p.PlayerID = c.PlayerID
INNER JOIN club.MedicalRecords AS mr
ON p.PlayerID = mr.PlayerID
WHERE mr.MedicalStatus IN ('Active Injury', 'Rehabilitation')
ORDER BY AnnualCompensation DESC;
GO

-- The manager requires comparative analysis on average match ratings of players in the squad
-- Find the players whose average match rating exceeds the average match rating of their position group

SELECT 
	p1.PlayerID,
	CONCAT(p1.FirstName, ' ', p1.LastName) AS PlayerName,
	p1.PrimaryPosition,
	CAST(AVG(pms1.MatchRating) AS DECIMAL(3, 2)) AS PlayerAverageRating
FROM club.Players AS p1
INNER JOIN club.PlayerMatchStats AS pms1
ON p1.PlayerID = pms1.PlayerID
GROUP BY
	p1.PlayerID,
	p1.FirstName,
	p1.LastName,
	p1.PrimaryPosition
HAVING AVG(pms1.MatchRating) > (
								SELECT 
									AVG(pms2.MatchRating)
								FROM club.Players AS p2
								INNER JOIN club.PlayerMatchStats AS pms2
								ON p2.PlayerID = pms2.PlayerID
								WHERE p2.PrimaryPosition = p1.PrimaryPosition)
ORDER BY
	p1.PrimaryPosition, 
	PlayerAverageRating DESC;
GO


-- Window Functions, Pivoting & Complex Transformations

-- The sports science department wants to track player match performance trajectories over time
-- For each player, compare their current match rating against their previous match rating using a lag function
-- Calculate the rating delta and (dense) rank their match performances in their position group 

WITH PlayerMatchSequence AS(
	SELECT 
		pms.StatID,
		p.PlayerID,
		CONCAT(p.FirstName, ' ', p.LastName) AS PlayerName,
		p.PrimaryPosition,
		m.MatchDate,
		pms.MatchRating,
		LAG(pms.MatchRating, 1) OVER (PARTITION BY p.PlayerID ORDER BY m.MatchDate ASC) AS PreviousMatchRating,
		DENSE_RANK() OVER (PARTITION BY p.PrimaryPosition ORDER BY pms.MatchRating DESC) AS PositionRatingRank
	FROM club.PlayerMatchStats AS pms
	INNER JOIN club.Players AS p
	ON pms.PlayerID = p.PlayerID
	INNER JOIN club.Matches AS m
	ON pms.MatchID = m.MatchID
	WHERE m.MatchStatus = 'Completed')
SELECT 
	PlayerID,
	PlayerName,
	PrimaryPosition,
	CONVERT(VARCHAR(10), MatchDate, 120) AS MatchDate,
	MatchRating,
	COALESCE(PreviousMatchRating, 0.0) AS PreviousMatchRating,
	CAST(MatchRating - COALESCE(PreviousMatchRating, MatchRating) AS DECIMAL(3, 1)) AS RatingChange,
	PositionRatingRank
FROM PlayerMatchSequence 
WHERE MatchRating IS NOT NULL
ORDER BY 
	PrimaryPosition,
	PlayerID,
	MatchDate;
GO

-- The financial controller needs a month-by-month running ledger of revenue and expenses for the 2024/25 fiscal period
-- This ledger should include a 3-transaction moving average of transaction amounts to smooth out revenue spikes

SELECT 
	TransactionID,
	CONVERT(VARCHAR(10), TransactionDate, 120) AS TxDate,
	TransactionType,
	Category,
	Amount,
	SUM(CASE
			WHEN TransactionType = 'Revenue' THEN Amount
			ELSE -Amount 
			END)
		OVER (ORDER BY TransactionDate ASC, TransactionID ASC 
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
		AS CumulativeNetCashFlow,
	CAST(AVG(Amount) OVER (PARTITION BY TransactionType ORDER BY TransactionDate ASC, TransactionID ASC
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
		AS DECIMAL(12, 2)) 
		AS MovingAverage3Tx
FROM club.FinancialTransactions
ORDER BY TransactionDate ASC, TransactionID ASC;
GO

-- The executive management team requires a matrix report summarising total weekly wage expenditure
-- The matrix report should include expenditure broken down by team type and across all positions

WITH SquadWageBase AS(
	SELECT 
		t.TeamType,
		p.PrimaryPosition,
		c.WeeklyWage
	FROM club.Players AS p
	INNER JOIN club.Teams AS t
	ON p.TeamID = t.TeamID
	INNER JOIN club.Contracts AS c
	ON p.PlayerID = c.PlayerID
	WHERE c.ContractStatus = 'Active')
SELECT
	TeamType,
	ISNULL(Goalkeeper, 0.00) AS GoalkeeperWages,
	ISNULL(Defender, 0.00) AS DefenderWages,
	ISNULL(Midfielder, 0.00) AS MidfielderWages,
	ISNULL(Forward, 0.00) AS ForwardWages,
	(ISNULL(Goalkeeper, 0.00) + ISNULL(Defender, 0.00) + ISNULL(Midfielder, 0.00) + ISNULL(Forward, 0.00)) AS TotalSquadWeeklyWage
FROM SquadWageBase
PIVOT (SUM(WeeklyWage) FOR PrimaryPosition IN ([Goalkeeper], [Defender], [Midfielder], [Forward])) AS PivotedWages
ORDER BY TotalSquadWeeklyWage DESC;
GO


-- Common Table Expressions & Recursive CTEs

-- The sports science and coaching staff need an automated alert report flagging high injury-risk players
-- Flagged if recent average training fatigue score is above squad average or if 2+ medical incidents are on their file

WITH PlayerWorkload AS(
	SELECT 
		PlayerID,
		CAST(AVG(FatigueScore) AS DECIMAL(3, 1)) AS AverageFatigue,
		CAST(AVG(CAST(RPERating AS DECIMAL(3, 1))) AS DECIMAL(3, 1)) AS AverageRPE,
		SUM(DistanceCoveredKM) AS TotalDistance
	FROM club.PlayerTrainingLogs
	GROUP BY PlayerID
),
MedicalRisk AS(
	SELECT
		PlayerID,
		COUNT(RecordID) AS TotalInjuries,
		SUM(CASE
				WHEN MedicalStatus IN ('Active Injury', 'Rehabilitation') THEN 1
				ELSE 0
			END) AS ActiveInjuries
	FROM club.MedicalRecords
	GROUP BY PlayerID
),
SquadBenchmarks AS(
	SELECT 
		AVG(AverageFatigue) AS BenchmarkFatigue
	FROM PlayerWorkload
)
SELECT 
	p.PlayerID,
	CONCAT(p.FirstName, ' ', p.LastName) AS PlayerName,
	p.PrimaryPosition,
	sb.BenchmarkFatigue,
	pw.AverageFatigue,
	pw.AverageRPE,
	mr.TotalInjuries,
	mr.ActiveInjuries,
	CASE
		WHEN pw.AverageFatigue > sb.BenchmarkFatigue AND mr.TotalInjuries >= 2 THEN 'Critical Risk'
		WHEN pw.AverageFatigue > sb.BenchmarkFatigue OR mr.ActiveInjuries > 0 THEN 'Moderate Risk'
		ELSE 'Low Risk'
	END AS RiskCategory
FROM club.Players AS p
INNER JOIN PlayerWorkload AS pw
ON p.PlayerID = pw.PlayerID
INNER JOIN MedicalRisk AS mr
ON p.PlayerID = mr.PlayerID
CROSS JOIN SquadBenchmarks AS sb
WHERE 
	pw.AverageFatigue > sb.BenchmarkFatigue
	OR
	mr.TotalInjuries >= 2
ORDER BY 
	pw.AverageFatigue DESC,
	mr.TotalInjuries DESC;
GO

-- The executive board requires a hierarchy tree of the coaching and technical department under the head coach
-- Simulate the reporting hierarchy using a temporary table and run a recursive CTE to traverse the management chain
-- Furthermore, compute organisational hierarchy levels and construct the reporting path

DECLARE @OrgHierarchy TABLE(
						StaffID INT PRIMARY KEY,
						ManagerID INT NULL)

INSERT INTO @OrgHierarchy (StaffID, ManagerID)
VALUES
(100, NULL), 
(101, 100),  
(102, 100),  
(103, 102), 
(104, 100),  
(105, 104),  
(106, 100);

WITH CoachingOrgChart AS(
	SELECT
		s.StaffID,
		CONCAT(s.FirstName, ' ', s.LastName) AS StaffName,
		s.Role,
		o.ManagerID,
		0 AS HierarchyLevel,
		CAST(s.FirstName + ' ' + s.LastName AS VARCHAR(255)) AS ReportingPath
	FROM club.Staff AS s
	INNER JOIN @OrgHierarchy AS o
	ON s.StaffID = o.StaffID
	WHERE o.ManagerID IS NULL

	UNION ALL

	SELECT 
		s.StaffID,
		CONCAT(s.FirstName, ' ', s.LastName) AS StaffName,
		s.Role,
		o.ManagerID,
		c.HierarchyLevel + 1 AS HierarchyLevel,
		CAST(c.ReportingPath + ' -> ' + s.FirstName + ' ' + s.LastName AS VARCHAR(255)) AS ReportingPath
	FROM club.Staff AS s
	INNER JOIN @OrgHierarchy AS o
	ON s.StaffID = o.StaffID
	INNER JOIN CoachingOrgChart AS c
	ON o.ManagerID = c.StaffID
)
SELECT
	REPLICATE('--- ', HierarchyLevel) + StaffName AS IndentedName,
	Role,
	HierarchyLevel,
	ReportingPath
FROM CoachingOrgChart
ORDER BY HierarchyLevel, StaffID;
GO


-- Views, Dynamic SQL & Built-In Functions

-- The operations team requires a view that exposes player biographies, team affiliations, active contract dates and primary injury status
-- The view should be created such that it does not expose sensitive contract bonuses or personal contact details

IF OBJECT_ID('club.vw_FirstTeamRoster', 'V') IS NOT NULL
	DROP VIEW club.vw_FirstTeamRoster;
GO

CREATE VIEW club.vw_FirstTeamRoster
AS 
SELECT 
	p.PlayerID,
	CONCAT(p.FirstName, ' ', p.LastName) AS PlayerName,
	p.SquadNumber,
	p.PrimaryPosition,
	p.Nationality,
	DATEDIFF(YEAR, p.DateOfBirth, GETDATE()) AS Age,
	t.TeamName,
	c.StartDate AS ContractStart,
	c.EndDate AS ContractEnd,
	COALESCE(mr.MedicalStatus, 'Fully Fit') AS CurrentFitnessStatus
FROM club.Players AS p
INNER JOIN club.Teams AS t
ON p.TeamID = t.TeamID
INNER JOIN club.Contracts AS c
ON p.PlayerID = c.PlayerID
LEFT JOIN club.MedicalRecords AS mr
ON 
	p.PlayerID = mr.PlayerID
	AND 
	mr.MedicalStatus IN ('Active Injury', 'Rehabilitation')
WHERE c.ContractStatus = 'Active';
GO

SELECT * FROM club.vw_FirstTeamRoster
WHERE PrimaryPosition = 'Midfielder'
ORDER BY SquadNumber;
GO

-- The analytics dashboard requires a dynamic query tool that allows analysts to pass custom column filters and sort parameters
-- The dynamic query tool should not risk SQL injection and filters like PrimaryPosition or ContractStatus should be considered

DECLARE @PositionFilter VARCHAR(20) = 'Forward';
DECLARE @MinWage DECIMAL(10, 2) = 25000.00;
DECLARE @SortColumn VARCHAR(30) = 'WeeklyWage';

DECLARE @SQL NVARCHAR(MAX);
DECLARE @ParamList NVARCHAR(500);

SET @SQL = N'
	SELECT 
		p.PlayerID,
		CONCAT(p.FirstName, '' '', p.LastName) AS PlayerName, 
		p.PrimaryPosition,
		c.WeeklyWage,
		c.ContractStatus
	FROM club.Players AS p
	INNER JOIN club.Contracts AS c
	ON p.PlayerID = c.PlayerID
	WHERE 
		p.PrimaryPosition = @Position
		AND 
		c.WeeklyWage >= @Wage';

IF @SortColumn = 'WeeklyWage'
	SET @SQL = @SQL + N' ORDER BY c.WeeklyWage DESC;';
ELSE
	SET @SQL = @SQL + N' ORDER BY p.PlayerID ASC;';

SET @ParamList = N'@Position VARCHAR(20), @Wage DECIMAL(10, 2)';

EXEC sp_executesql
	@stmt = @SQL,
	@params = @ParamList,
	@Position = @PositionFilter,
	@Wage = @MinWage;
GO

-- The data engineering team require a JSON payload for an external medical API
-- This should group squad members and output a comma-delimited list of their recorded injury types alongside their biographical data

SELECT 
	p.PlayerID,
	CONCAT(p.FirstName, ' ', p.LastName) AS PlayerName,
	p.PrimaryPosition,
	STRING_AGG(mr.InjuryType, ' | ') WITHIN GROUP (ORDER BY mr.InjuryDate DESC) AS HistoricalInjuries,
	COUNT(mr.RecordID) AS TotalMedicalIncidents 
FROM club.Players AS p
INNER JOIN club.MedicalRecords AS mr
ON p.PlayerID = mr.PlayerID
GROUP BY
	p.PlayerID,
	p.FirstName,
	p.LastName,
	p.PrimaryPosition
HAVING COUNT(mr.RecordID) >= 2

FOR JSON PATH, ROOT('MedicalInjuries');
GO


-- Stored Procedures, UDFs, Triggers & Error Handling

-- Create a Scalar UDF to return a player's exact age in years based on their date of birth

IF OBJECT_ID('club.fn_CalculatePlayerAge', 'FN') IS NOT NULL
	DROP FUNCTION club.fn_CalculatePlayerAge;
GO

CREATE FUNCTION club.fn_CalculatePlayerAge (@DateOfBirth DATE)
RETURNS INT
AS 
BEGIN
	DECLARE @Age INT;
	SET @Age = DATEDIFF(YEAR, @DateOfBirth, GETDATE()) -
											CASE 
												WHEN DATEADD(YEAR, DATEDIFF(YEAR, @DateOfBirth, GETDATE()), @DateOfBirth) > GETDATE() THEN 1
												ELSE 0
											END;
	RETURN @Age;
END;
GO

SELECT
	PlayerID,
	FirstName,
	LastName,
	DateOfBirth,
	club.fn_CalculatePlayerAge(DateOfBirth) AS CalculatedAge
FROM club.Players
WHERE PlayerID BETWEEN 1000 AND 1005;

-- Create an Inline Table-Valued Function that accepts a PlayerID and returns their structured injury timeline

IF OBJECT_ID('club.fn_GetPlayerMedicalHistory', 'IF') IS NOT NULL
	DROP FUNCTION club.fn_GetPlayerMedicalHistory;
GO

CREATE FUNCTION club.fn_GetPlayerMedicalHistory (@PlayerID INT)
RETURNS TABLE
AS 
RETURN(
	SELECT 
		mr.RecordID,
		mr.PlayerID,
		CONCAT(p.FirstName, ' ', p.LastName) AS PlayerName,
		mr.InjuryType,
		mr.Severity,
		mr.InjuryDate,
		mr.EstimatedReturnDate,
		mr.ActualReturnDate,
		mr.MedicalStatus,
		DATEDIFF(DAY, mr.InjuryDate, COALESCE(mr.ActualReturnDate, GETDATE())) AS TotalDaysSidelined
	FROM club.MedicalRecords AS mr
	INNER JOIN club.Players AS p 
	ON mr.PlayerID = p.PlayerID
	WHERE mr.PlayerID = @PlayerID)
GO

SELECT * FROM club.fn_GetPlayerMedicalHistory(1004);
GO

-- Build a stored procedure that processes an outbound player transfer
-- The procedure should wrap all in an explicit transaction block with automatic ROLLBACK on failure
-- The procedure should validate the player exists and is active whilst updating contract status to 'Terminated'
-- The procedure should insert an outbound transfer record into club.TransferTransactions
-- The procedure should insert a revenue record into club.FinancialTransactions

IF OBJECT_ID('club.sp_ExecutePlayerTransfer', 'P') IS NOT NULL
	DROP PROCEDURE club.sp_ExecutePlayerTransfer;
GO

CREATE PROCEDURE club.sp_ExecutePlayerTransfer(
											@PlayerID INT,
											@DestinationClub VARCHAR(100),
											@TransferFee DECIMAL(12, 2),
											@AgentFee DECIMAL(12, 2),
											@TransferDate DATE)
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM club.Players WHERE PlayerID = @PlayerID)
	BEGIN
		RAISERROR('Target PlayerID %d does not exist in club records', 16, 1, @PlayerID);
		RETURN;
	END

	BEGIN TRY

		BEGIN TRANSACTION;

		UPDATE club.Contracts
			SET ContractStatus = 'Terminated',
				EndDate = @TransferDate
			WHERE 
				PlayerID = @PlayerID
				AND
				ContractStatus = 'Active';

		INSERT INTO club.TransferTransactions (PlayerID, TransferType, OtherClub, TransferFee, AgentFee, TransferDate)
		VALUES
		(@PlayerID, 'Outbound', @DestinationClub, @TransferFee, @AgentFee, @TransferDate);

		INSERT INTO club.FinancialTransactions (TransactionDate, Category, Amount, TransactionType, Description)
		VALUES
		(CAST(@TransferDate AS DATETIME), 
		'Transfer Fee', 
		(@TransferFee - @AgentFee), 
		'Revenue', 
		CONCAT('Outbound transfer proceeds for PlayerID ', @PlayerID, ' to ', @DestinationClub));

		COMMIT TRANSACTION;

		PRINT 'Player transfer successfully executed and financial ledgers updated';

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

DECLARE @CurrentDate DATE = GETDATE();

EXEC club.sp_ExecutePlayerTransfer
								@PlayerID = 1009,
								@DestinationClub = 'Sevilla FC',
								@TransferFee = 14500000.00,
								@AgentFee = 1200000.00,
								@TransferDate = @CurrentDate;
GO

DECLARE @TargetPlayerID INT = 1009;

SELECT
	p.PlayerID,
	CONCAT(p.FirstName, ' ', p.LastName) AS PlayerName,
	p.PrimaryPosition,
	c.ContractStatus,
	CONVERT(VARCHAR(10), c.StartDate, 120) AS ContractStart,
	CONVERT(VARCHAR(10), c.EndDate, 120) AS ContractEnd
FROM club.Players AS p
INNER JOIN club.Contracts AS c
ON p.PlayerID = c.PlayerID
WHERE p.PlayerID = @TargetPlayerID;

DECLARE @TargetPlayerID INT = 1009;

SELECT 
	TransferID,
	PlayerID,
	TransferType,
	TransferFee,
	AgentFee,
	(TransferFee - AgentFee) AS NetTransferProceeds,
	CONVERT(VARCHAR(10), TransferDate, 120) AS TransferDate
FROM club.TransferTransactions
WHERE PlayerID = @TargetPlayerID;

DECLARE @TargetPlayerID INT = 1009;

SELECT TOP 5
	TransactionID,
	CONVERT(VARCHAR(10), TransactionDate, 120) AS TxDate,
	Category,
	TransactionType,
	Amount,
	Description
FROM club.FinancialTransactions
WHERE 
	Category = 'Transfer Fee'
	AND 
	Description LIKE CONCAT('%PlayerID ', @TargetPlayerID, '%')
ORDER BY TransactionID DESC;
GO

DECLARE @CurrentDate DATE = GETDATE();

EXEC club.sp_ExecutePlayerTransfer
								@PlayerID = 9999,
								@DestinationClub = 'Sevilla FC',
								@TransferFee = 14500000.00,
								@AgentFee = 1200000.00,
								@TransferDate = @CurrentDate;
GO

-- Create an audit table and an AFTER UPDATE trigger that logs changes made to a player's weekly wage
-- The audit table should capture the old wage, new wage, modification timestamp and database user

IF OBJECT_ID('club.ContractWageAudit', 'U') IS NOT NULL
	DROP TABLE club.ContractWageAudit;
GO

CREATE TABLE club.ContractWageAudit(
								AuditID INT IDENTITY(1, 1) PRIMARY KEY,
								ContractID INT NOT NULL,
								PlayerID INT NOT NULL,
								OldWeeklyWage DECIMAL(10, 2) NOT NULL,
								NewWeeklyWage DECIMAL(10, 2) NOT NULL,
								WageDifference DECIMAL(10, 2) NOT NULL,
								ModifiedBy VARCHAR(100) NOT NULL DEFAULT SUSER_SNAME(),
								ModifiedDate DATETIME NOT NULL DEFAULT GETDATE());
GO

IF OBJECT_ID('club.trg_AuditContractWageChange', 'TR') IS NOT NULL
	DROP TRIGGER club.trg_AuditContractWageChange;
GO

CREATE TRIGGER club.trg_AuditContractWageChange
ON club.Contracts
AFTER UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	IF UPDATE(WeeklyWage)
	BEGIN
		INSERT INTO club.ContractWageAudit (ContractID, PlayerID, OldWeeklyWage, NewWeeklyWage, WageDifference, ModifiedBy, ModifiedDate)
		SELECT
			i.ContractID,
			i.PlayerID,
			d.WeeklyWage AS OldWeeklyWage,
			i.WeeklyWage AS NewWeeklyWage,
			(i.WeeklyWage - d.WeeklyWage) AS WageDifference,
			SUSER_SNAME(),
			GETDATE()
		FROM inserted AS i
		INNER JOIN deleted AS d
		ON i.ContractID = d.ContractID
		WHERE i.WeeklyWage <> d.WeeklyWage;
	END
END;
GO

UPDATE club.Contracts
SET WeeklyWage = 45000.00
WHERE PlayerID = 1000;

SELECT * FROM club.ContractWageAudit;
GO

-- The medical department needs an automated stored procedure to log a new medical incident for a player
-- The procedure should validate that both the player and attending physio exist in the system
-- The procedure should check if the player has an unclosed active injury to prevent duplicate cases
-- The procedure should insert the new record into club.MedicalRecords
-- The procedure should return the generated RecordID back to the calling application via an OUTPUT parameter

IF OBJECT_ID('club.sp_RegisterNewInjury', 'P') IS NOT NULL
    DROP PROCEDURE club.sp_RegisterNewInjury;
GO

CREATE PROCEDURE club.sp_RegisterNewInjury(
										@PlayerID INT,
										@InjuryType VARCHAR(100),
										@Severity VARCHAR(20),
										@InjuryDate DATE,
										@EstimatedReturnDate DATE,
										@AttendingPhysioID INT,
										@NewRecordID INT OUTPUT)
AS 
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT 1 FROM club.Players WHERE PlayerID = @PlayerID)
	BEGIN
		RAISERROR('Validation Error: PlayerID %d does not exist', 16, 1, @PlayerID);
		RETURN -1;
	END

	IF NOT EXISTS (SELECT 1 FROM club.Staff WHERE StaffID = @AttendingPhysioID)
	BEGIN
		RAISERROR('Validation Error: Physio StaffID %d does not exist', 16, 1, @AttendingPhysioID);
		RETURN -1;
	END

	IF EXISTS (
			SELECT 1 FROM club.MedicalRecords 
			WHERE 
				PlayerID = @PlayerID
				AND 
				MedicalStatus = 'Active Injury')
	BEGIN
		RAISERROR('Business Rule Error: PlayerID %d has an existing open active injury log', 16, 1, @PlayerID);
		RETURN -1;
	END

	BEGIN TRY

		BEGIN TRANSACTION;

		INSERT INTO club.MedicalRecords (PlayerID, InjuryType, Severity, InjuryDate, EstimatedReturnDate, ActualReturnDate, MedicalStatus, AttendingPhysioID)
		VALUES
		(@PlayerID, @InjuryType, @Severity, @InjuryDate, @EstimatedReturnDate, NULL, 'Active Injury', @AttendingPhysioID);

		SET @NewRecordID = SCOPE_IDENTITY();

		COMMIT TRANSACTION;

		PRINT CONCAT('Medical record successfully created with RecordID: ', @NewRecordID);

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		SET @NewRecordID = NULL;

		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();

		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

	END CATCH
END;
GO

DECLARE @ReturnedRecordID INT;

EXEC club.sp_RegisterNewInjury
	@PlayerID = 1000,
    @InjuryType = 'Hamstring Strain (Grade 1)',
    @Severity = 'Minor',
    @InjuryDate = '2026-07-29',
    @EstimatedReturnDate = '2026-08-15',
    @AttendingPhysioID = 102,
    @NewRecordID = @ReturnedRecordID OUTPUT;

SELECT 
    name AS TriggerName,
    is_disabled,
    is_instead_of_trigger
FROM sys.triggers
WHERE name = 'trg_AuditContractWageChange';


-- Transactions, Isolation Levels & Locking Mechanisms

-- The finance department is running an audit report on match ticket revenues while parallel box office systems are updating sales numbers
-- Demonstrate how changing isolation levels affects data visibility during concurrent transactions

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

SELECT 
	Category,
	COUNT(TransactionID) AS TransactionCount,
	SUM(Amount) AS TotalRevenue
FROM club.FinancialTransactions
WHERE TransactionType = 'Revenue'
GROUP BY Category;
GO

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRANSACTION;

SELECT	
	SUM(CASE WHEN TransactionType = 'Revenue' THEN Amount ELSE 0 END) AS TotalRevenue,
	SUM(CASE WHEN TransactionType = 'Expense' THEN Amount ELSE 0 END) AS TotalExpenses,
	SUM(CASE WHEN TransactionType = 'Revenue' THEN Amount ELSE -Amount END) AS NetPosition
FROM club.FinancialTransactions
WHERE TransactionDate >= '2026-01-01';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- The ticketholder administration system processes high-volume matchday gate receipts
-- Take an explicit UPDLOCK when updating financial transaction balances to ensure two concurrent processes don't affect the same record

BEGIN TRANSACTION; 

DECLARE @CurrentAmount DECIMAL(12, 2);
DECLARE @TargetTxID INT = 8000;

SELECT @CurrentAmount = Amount
FROM club.FinancialTransactions WITH (UPDLOCK, ROWLOCK)
WHERE TransactionID = @TargetTxID;

DECLARE @NewAmount DECIMAL(12, 2) = @CurrentAmount + 5000.00;

UPDATE club.FinancialTransactions
SET 
	Amount = @NewAmount,
	Description = CONCAT(Description, ' [Adjusted via UPDLOCK Session]')
WHERE TransactionID = @TargetTxID;

COMMIT TRANSACTION;
PRINT 'Transaction completed with zero risk of concurrency race condition';

-- System administrators need diagnostic scripts to inspect active locks, blocked sessions and wait resource types
-- Create a diagnostic script for these purposes by querying dynamic management views

SELECT 
	tl.resource_type AS ResourceType,
	tl.resource_associated_entity_id AS EntityID,
	tl.request_mode AS LockMode,
	tl.request_status AS LockStatus,
	er.session_id AS SessionID,
	er.blocking_session_id AS BlockedBySessionID,
	SUBSTRING(st.text, (er.statement_start_offset / 2) + 1, 
										((CASE er.statement_end_offset
											WHEN -1 THEN DATALENGTH(st.text)
											ELSE er.statement_end_offset 
										  END - er.statement_start_offset) / 2) + 1) AS ExecutingSQLText
FROM sys.dm_tran_locks AS tl
INNER JOIN sys.dm_exec_requests AS er
ON tl.request_session_id = er.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
WHERE er.session_id <> @@SPID
ORDER BY er.blocking_session_id DESC;
GO


-- Performance Tuning, Execution Plans & Index Optimisation

-- The scouting team frequently runs high-volume searches filtering on PrimaryPosition and PreferredFoot
-- Create a covering Non-Clustered Index to avoid reading the entire table and verify optimisation statistics

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Players_Position_PreferredFoot' AND object_id = OBJECT_ID('club.Players'))
	DROP INDEX IX_Players_Position_PreferredFoot ON club.Players;
GO

CREATE NONCLUSTERED INDEX IX_Players_Position_PreferredFoot
ON club.Players (PrimaryPosition, PreferredFoot)
INCLUDE (FirstName, LastName, SquadNumber, TeamID);
GO

SELECT 
	PlayerID,
	FirstName,
	LastName,
	SquadNumber,
	TeamID
FROM club.Players
WHERE 
	PrimaryPosition = 'Midfielder'
	AND 
	PreferredFoot = 'Right';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Medical analysts frequently query active injury records and indexing all historical cleared records is wasteful
-- Construct a Filtered Index that indexes active or rehabilitating medical cases alone

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MedicalRecords_ActiveInjuries' AND object_id = OBJECT_ID('club.MedicalRecords'))
	DROP INDEX IX_MedicalRecords_ActiveInjuries ON club.MedicalRecords;
GO

CREATE NONCLUSTERED INDEX IX_MedicalRecords_ActiveInjuries
ON club.MedicalRecords (PlayerID, MedicalStatus)
INCLUDE (InjuryType, Severity, InjuryDate, EstimatedReturnDate)
WHERE MedicalStatus IN ('Active Injury', 'Rehabilitation');
GO

SELECT 
	RecordID,
	PlayerID,
	InjuryType,
	Severity,
	InjuryDate,
	EstimatedReturnDate,
	MedicalStatus
FROM club.MedicalRecords
WHERE MedicalStatus = 'Active Injury';
GO

-- The sports science data warehouse processes large volumes of training performance logs
-- Create a Non-Clustered Columnstore Index on club.PlayerTrainingLogs to accelerate analytical workloads

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'NCCI_PlayerTrainingLogs_Analytics' AND object_id = OBJECT_ID('club.PlayerTrainingLogs'))
	DROP INDEX NCCI_PlayerTrainingLogs_Analytics ON club.PlayerTrainingLogs;
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_PlayerTrainingLogs_Analytics
ON club.PlayerTrainingLogs (PlayerID, SessionID, DistanceCoveredKM, RPERating, FatigueScore);
GO

SELECT 
	PlayerID,
	COUNT(LogID) AS TotalSessionsLogged,
	CAST(AVG(DistanceCoveredKM) AS DECIMAL(4, 2)) AS AverageDistanceKM,
	CAST(AVG(CAST(RPERating AS DECIMAL(3, 1))) AS DECIMAL(3, 1)) AS AverageRPE,
	CAST(AVG(CAST(FatigueScore AS DECIMAL(3, 1))) AS DECIMAL(3, 1)) AS AverageFatigueScore
FROM club.PlayerTrainingLogs
GROUP BY PlayerID
ORDER BY AverageDistanceKM DESC;
GO