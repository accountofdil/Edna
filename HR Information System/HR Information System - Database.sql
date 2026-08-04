-- Database Creation

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'human_resources_information_system')
BEGIN
	ALTER DATABASE human_resources_information_system SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE human_resources_information_system;
END
GO

CREATE DATABASE human_resources_information_system;
GO

USE human_resources_information_system;
GO

CREATE SCHEMA HR;
GO

CREATE SCHEMA Audit;
GO

DROP TABLE IF EXISTS HR.Departments;
CREATE TABLE HR.Departments(
						DepartmentID INT IDENTITY(1, 1) NOT NULL,
						DepartmentCode VARCHAR(10) NOT NULL,
						DepartmentName VARCHAR(100) NOT NULL,
						CostCenter VARCHAR(20) NOT NULL,
						IsActive BIT NOT NULL DEFAULT 1,
						CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
						CONSTRAINT PK_Departments_DepartmentID PRIMARY KEY CLUSTERED (DepartmentID),
						CONSTRAINT UQ_Departments_DepartmentCode UNIQUE (DepartmentCode));
GO

SELECT * FROM HR.Departments;

DROP TABLE IF EXISTS HR.Jobs;
CREATE TABLE HR.Jobs(
					JobID INT IDENTITY(100, 1) NOT NULL,
					JobTitle VARCHAR(100) NOT NULL,
					MinSalary DECIMAL(12, 2) NOT NULL,
					MaxSalary DECIMAL(12, 2) NOT NULL,
					IsSalaried BIT NOT NULL DEFAULT 1,
					CONSTRAINT PK_Jobs_JobID PRIMARY KEY CLUSTERED (JobID),
					CONSTRAINT CK_Jobs_SalaryRange CHECK (MaxSalary >= MinSalary));
GO

SELECT * FROM HR.Jobs;

DROP TABLE IF EXISTS HR.Employees;
CREATE TABLE HR.Employees(
						EmployeeID INT IDENTITY(1000, 1) NOT NULL,
						NINO VARCHAR(9) NOT NULL,
						FirstName VARCHAR(50) NOT NULL,
						LastName VARCHAR(50) NOT NULL,
						Email VARCHAR(100) NOT NULL,
						HireDate DATE NOT NULL,
						TerminationDate DATE NULL,
						DepartmentID INT NOT NULL,
						JobID INT NOT NULL,
						ManagerID INT NULL,
						CurrentSalary DECIMAL(12, 2) NOT NULL,
						EmploymentStatus VARCHAR(20) NOT NULL DEFAULT 'Active',
						CreatedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
						CONSTRAINT PK_Employees_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID),
						CONSTRAINT UQ_Employees_NINO UNIQUE (NINO),
						CONSTRAINT UQ_Employees_Email UNIQUE (Email),
						CONSTRAINT FK_Employees_Departments FOREIGN KEY (DepartmentID) REFERENCES HR.Departments(DepartmentID),
						CONSTRAINT FK_Employees_Jobs FOREIGN KEY (JobID) REFERENCES HR.Jobs(JobID),
						CONSTRAINT FK_Employees_Manager FOREIGN KEY (ManagerID) REFERENCES HR.Employees(EmployeeID),
						CONSTRAINT CK_Employees_EmploymentStatus CHECK (EmploymentStatus IN ('Active', 'On Leave', 'Terminated')),
						CONSTRAINT CK_Employees_Dates CHECK (TerminationDate IS NULL OR TerminationDate >= HireDate));
GO

SELECT * FROM HR.Employees;

DROP TABLE IF EXISTS HR.Salaries;
CREATE TABLE HR.Salaries(
						SalaryID BIGINT IDENTITY(1, 1) NOT NULL,
						EmployeeID INT NOT NULL,
						OldSalary DECIMAL(12, 2) NOT NULL,
						NewSalary DECIMAL(12, 2) NOT NULL,
						ChangeReason VARCHAR(100) NOT NULL,
						EffectiveDate DATE NOT NULL,
						ModifiedBy VARCHAR(100) NOT NULL DEFAULT SUSER_SNAME(),
						CONSTRAINT PK_Salaries_SalaryID PRIMARY KEY CLUSTERED (SalaryID),
						CONSTRAINT FK_Salaries_Employees FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID) ON DELETE CASCADE);
GO

SELECT * FROM HR.Salaries;

DROP TABLE IF EXISTS HR.Payrolls;
CREATE TABLE HR.Payrolls(
						PayrollID INT IDENTITY(5000, 1) NOT NULL,
						PeriodStartDate DATE NOT NULL,
						PeriodEndDate DATE NOT NULL,
						ProcessDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
						TotalGrossPay DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
						TotalDeductions DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
						TotalNetPay DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
						RunStatus VARCHAR(20) NOT NULL DEFAULT 'Draft',
						CONSTRAINT PK_Payrolls_PayrollID PRIMARY KEY CLUSTERED (PayrollID),
						CONSTRAINT CK_Payrolls_RunStatus CHECK (RunStatus IN ('Draft', 'Processing', 'Completed', 'Cancelled')),
						CONSTRAINT CK_Payrolls_PeriodDates CHECK (PeriodEndDate >= PeriodStartDate));
GO

SELECT * FROM HR.Payrolls;

DROP TABLE IF EXISTS HR.Payslips;
CREATE TABLE HR.Payslips(
						PayslipID BIGINT IDENTITY(1, 1) NOT NULL,
						PayrollID INT NOT NULL,
						EmployeeID INT NOT NULL,
						BasePay DECIMAL(12, 2) NOT NULL,
						OvertimePay DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
						BonusPay DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
						GrossPay AS (BasePay + OvertimePay + BonusPay) PERSISTED,
						PAYE DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
						NIC DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
						PensionDeduction DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
						OtherDeductions DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
						NetPay AS ((BasePay + OvertimePay + BonusPay) - (PAYE + NIC + PensionDeduction + OtherDeductions)) PERSISTED,
						CONSTRAINT PK_Payslips_PayslipID PRIMARY KEY CLUSTERED (PayslipID),
						CONSTRAINT FK_Payslips_Payrolls FOREIGN KEY (PayrollID) REFERENCES HR.Payrolls(PayrollID),
						CONSTRAINT FK_Payslips_Employees FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID));
GO

SELECT * FROM HR.Payslips;

DROP TABLE IF EXISTS HR.Absences;
CREATE TABLE HR.Absences(
						AbsenceID INT IDENTITY(1, 1) NOT NULL,
						EmployeeID INT NOT NULL,
						LeaveType VARCHAR(30) NOT NULL,
						StartDate DATE NOT NULL,
						EndDate DATE NOT NULL,
						TotalDays AS (DATEDIFF(DAY, StartDate, EndDate) + 1),
						ApprovalStatus VARCHAR(20) NOT NULL DEFAULT 'Pending',
						ApprovedBy INT NULL,
						CONSTRAINT PK_Absences_AbsenceID PRIMARY KEY CLUSTERED (AbsenceID),
						CONSTRAINT FK_Absences_Employees FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID),
						CONSTRAINT FK_Absences_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES HR.Employees(EmployeeID),
						CONSTRAINT CK_Absences_LeaveType CHECK (LeaveType IN ('Annual Leave', 'Statutory Sick Pay', 'Maternity', 'Paternity', 'Shared Parental', 'Unpaid')),
						CONSTRAINT CK_Absences_ApprovalStatus CHECK (ApprovalStatus IN ('Pending', 'Approved', 'Rejected')));
GO

SELECT * FROM HR.Absences;

DROP TABLE IF EXISTS HR.Reviews;
CREATE TABLE HR.Reviews(
					ReviewID INT IDENTITY(1, 1) NOT NULL,
					EmployeeID INT NOT NULL,
					ReviewerID INT NOT NULL,
					ReviewPeriodYear INT NOT NULL,
					PerformanceScore INT NOT NULL,
					FeedbackComments VARCHAR(MAX) NULL,
					ReviewDate DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
					CONSTRAINT PK_Reviews_ReviewID PRIMARY KEY CLUSTERED (ReviewID),
					CONSTRAINT FK_Reviews_Employees FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID),
					CONSTRAINT FK_Reviews_Reviewer FOREIGN KEY (ReviewerID) REFERENCES HR.Employees(EmployeeID),
					CONSTRAINT CK_Reviews_PerformanceScore CHECK (PerformanceScore BETWEEN 1 AND 5));
GO

SELECT * FROM HR.Reviews;

DROP TABLE IF EXISTS HR.Benefits;
CREATE TABLE HR.Benefits(
						BenefitID INT IDENTITY(1, 1) NOT NULL,
						EmployeeID INT NOT NULL,
						PlanName VARCHAR(100) NOT NULL,
						CoverageType VARCHAR(30) NOT NULL,
						EmployeeContribution DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
						EmployerContribution DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
						StartDate DATE NOT NULL,
						EndDate DATE NULL,
						CONSTRAINT PK_Benefits_BenefitID PRIMARY KEY CLUSTERED (BenefitID),
						CONSTRAINT FK_Benefits_Employees FOREIGN KEY (EmployeeID) REFERENCES HR.Employees(EmployeeID),
						CONSTRAINT CK_Benefits_CoverageType CHECK (CoverageType IN ('Workplace Pension', 'Private Medical', 'Cycle to Work', 'Dental', 'Life Assurance')));
GO

SELECT * FROM HR.Benefits;

DROP TABLE IF EXISTS Audit.AuditLog;
CREATE TABLE Audit.AuditLog(
						AuditID BIGINT IDENTITY(1, 1) NOT NULL,
						TableName VARCHAR(100) NOT NULL,
						ActionType VARCHAR(10) NOT NULL,
						PrimaryKeyValue VARCHAR(50) NOT NULL,
						ModifiedBy VARCHAR(100) NOT NULL DEFAULT SUSER_SNAME(),
						ModifiedDate DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
						OldValuesJSON NVARCHAR(MAX) NULL,
						NewValuesJSON NVARCHAR(MAX) NULL,
						CONSTRAINT PK_AuditLog_AuditID PRIMARY KEY CLUSTERED (AuditID));
GO

SELECT * FROM Audit.AuditLog;


-- Schema Inspection

SELECT 
	s.name AS SchemaName,
	t.name AS TableName,
	p.rows AS TotalRows,
	t.create_date AS CreatedDate
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
INNER JOIN sys.partitions AS p
ON t.object_id = p.object_ID AND p.index_id IN (0, 1)
WHERE s.name = 'HR'
ORDER BY t.name
GO

SELECT 
	s.name AS SchemaName,
	t.name AS TableName,
	p.rows AS TotalRows,
	t.create_date AS CreatedDate
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
INNER JOIN sys.partitions AS p
ON t.object_id = p.object_ID AND p.index_id IN (0, 1)
WHERE s.name = 'Audit'
ORDER BY t.name
GO

SELECT
	s.name AS SchemaName,
	t.name AS TableName,
	c.column_id AS ColumnOrder,
	c.name AS ColumnName,
	type_name(c.user_type_id) AS DataType,
	c.max_length AS MaxByteLength,
	c.precision AS Precision,
	c.scale AS Scale,
	c.is_nullable AS IsNullable,
	c.is_identity AS IsIdentity,
	OBJECT_DEFINITION(c.default_object_id) AS DefaultConstraintDefinition
FROM sys.columns AS c
INNER JOIN sys.tables AS t
ON c.object_id = t.object_id
INNER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
WHERE s.name = 'HR'
ORDER BY t.name, c.column_id;
GO

SELECT
	s.name AS SchemaName,
	t.name AS TableName,
	c.column_id AS ColumnOrder,
	c.name AS ColumnName,
	type_name(c.user_type_id) AS DataType,
	c.max_length AS MaxByteLength,
	c.precision AS Precision,
	c.scale AS Scale,
	c.is_nullable AS IsNullable,
	c.is_identity AS IsIdentity,
	OBJECT_DEFINITION(c.default_object_id) AS DefaultConstraintDefinition
FROM sys.columns AS c
INNER JOIN sys.tables AS t
ON c.object_id = t.object_id
INNER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
WHERE s.name = 'Audit'
ORDER BY t.name, c.column_id;
GO

SELECT 
	fk.name AS ForeignKeyConstraintName,
	s_parent.name AS ParentSchema,
	t_parent.name AS ParentTable,
	c_parent.name AS ParentColumn,
	s_ref.name AS ReferencedSchema,
	t_ref.name AS ReferencedTable,
	c_ref.name AS ReferencedColumn
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS t_parent
ON fkc.parent_object_id = t_parent.object_id
INNER JOIN sys.schemas AS s_parent
ON t_parent.schema_id = s_parent.schema_id
INNER JOIN sys.columns AS c_parent 
ON fkc.parent_object_id = c_parent.object_id AND fkc.parent_column_id = c_parent.column_id
INNER JOIN sys.tables AS t_ref
ON fkc.referenced_object_id = t_ref.object_id
INNER JOIN sys.schemas AS s_ref 
ON t_ref.schema_id = s_ref.schema_id
INNER JOIN sys.columns AS c_ref
ON fkc.referenced_object_id = c_ref.object_id AND fkc.referenced_column_id = c_ref.column_id
WHERE s_parent.name = 'HR'
ORDER BY t_parent.name, fk.name;
GO

SELECT 
	fk.name AS ForeignKeyConstraintName,
	s_parent.name AS ParentSchema,
	t_parent.name AS ParentTable,
	c_parent.name AS ParentColumn,
	s_ref.name AS ReferencedSchema,
	t_ref.name AS ReferencedTable,
	c_ref.name AS ReferencedColumn
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS t_parent
ON fkc.parent_object_id = t_parent.object_id
INNER JOIN sys.schemas AS s_parent
ON t_parent.schema_id = s_parent.schema_id
INNER JOIN sys.columns AS c_parent 
ON fkc.parent_object_id = c_parent.object_id AND fkc.parent_column_id = c_parent.column_id
INNER JOIN sys.tables AS t_ref
ON fkc.referenced_object_id = t_ref.object_id
INNER JOIN sys.schemas AS s_ref 
ON t_ref.schema_id = s_ref.schema_id
INNER JOIN sys.columns AS c_ref
ON fkc.referenced_object_id = c_ref.object_id AND fkc.referenced_column_id = c_ref.column_id
WHERE s_parent.name = 'Audit'
ORDER BY t_parent.name, fk.name;
GO

SELECT
	s.name AS SchemaName,
	t.name AS TableName,
	cc.name AS ConstraintName,
	cc.type_desc AS ConstraintType,
	cc.definition AS ConstraintExpression
FROM sys.check_constraints AS cc
INNER JOIN sys.tables AS t
ON cc.parent_object_id = t.object_id
INNER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
WHERE s.name = 'HR'
ORDER BY t.name, cc.name;
GO

SELECT
	s.name AS SchemaName,
	t.name AS TableName,
	cc.name AS ConstraintName,
	cc.type_desc AS ConstraintType,
	cc.definition AS ConstraintExpression
FROM sys.check_constraints AS cc
INNER JOIN sys.tables AS t
ON cc.parent_object_id = t.object_id
INNER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
WHERE s.name = 'Audit'
ORDER BY t.name, cc.name;
GO


-- Data Loading & Integration

INSERT INTO HR.Departments (DepartmentCode, DepartmentName, CostCenter, IsActive)
VALUES
('EXEC', 'Executive Office', 'CC-100', 1),
('ENG', 'Software Engineering', 'CC-200', 1),
('DATA', 'Data & Analytics', 'CC-250', 1),
('CLOUD', 'Cloud Infrastructure', 'CC-260', 1),
('SEC', 'Cyber Security', 'CC-270', 1),
('HR', 'Human Resources', 'CC-300', 1),
('TA', 'Talent Acquisition', 'CC-350', 1),
('FIN', 'Finance & Accounting', 'CC-400', 1),
('PAY', 'Payroll & Compensation', 'CC-450', 1),
('SALES', 'Enterprise Sales', 'CC-500', 1),
('MKT', 'Global Marketing', 'CC-550', 1),
('LEGAL', 'Legal & Compliance', 'CC-600', 1);
GO

SELECT * FROM HR.Departments;

INSERT INTO HR.Jobs (JobTitle, MinSalary, MaxSalary, IsSalaried)
VALUES
('Chief Executive Officer', 160000.00, 280000.00, 1),   
('Chief Technology Officer', 140000.00, 240000.00, 1),  
('VP of Data & Analytics', 115000.00, 175000.00, 1),   
('VP of Human Resources', 100000.00, 150000.00, 1),   
('Head of Finance', 95000.00, 145000.00, 1),           
('Lead Data Architect', 90000.00, 130000.00, 1),      
('Principal DevOps Engineer', 85000.00, 125000.00, 1),  
('Senior Data Engineer', 70000.00, 95000.00, 1),       
('Data Engineer', 48000.00, 68000.00, 1),            
('Junior Data Engineer', 32000.00, 44000.00, 1),      
('Lead Analytics Engineer', 75000.00, 105000.00, 1), 
('Senior Software Engineer', 68000.00, 92000.00, 1),   
('Software Engineer', 45000.00, 65000.00, 1),         
('Cyber Security Lead', 80000.00, 115000.00, 1),   
('Security Analyst', 42000.00, 60000.00, 1),          
('HR Business Partner', 42000.00, 58000.00, 1),       
('HR Administrator', 26000.00, 34000.00, 1),       
('Talent Acquisition Lead', 50000.00, 72000.00, 1),   
('Senior Financial Analyst', 55000.00, 78000.00, 1),
('Management Accountant', 42000.00, 60000.00, 1),     
('Payroll Specialist', 34000.00, 46000.00, 1),        
('Enterprise Account Executive', 55000.00, 90000.00, 1), 
('Marketing Manager', 48000.00, 68000.00, 1),         
('Legal Counsel', 75000.00, 110000.00, 1),            
('IT Support Technician', 26000.00, 35000.00, 0);     
GO

SELECT * FROM HR.Jobs;

INSERT INTO HR.Employees (NINO, FirstName, LastName, Email, HireDate, TerminationDate, DepartmentID, JobID, ManagerID, CurrentSalary, EmploymentStatus)
VALUES
('AA100000A', 'Arthur', 'Pendelton', 'a.pendelton@company.co.uk', '2014-01-15', NULL, 1, 100, NULL, 210000.00, 'Active'),
('AB100001B', 'Victoria', 'Sterling', 'v.sterling@company.co.uk', '2014-03-01', NULL, 2, 101, 1000, 185000.00, 'Active'),
('AC100002C', 'Charles', 'Montgomery', 'c.montgomery@company.co.uk', '2015-05-10', NULL, 3, 102, 1000, 145000.00, 'Active'),
('AD100003D', 'Eleanor', 'Rutherford', 'e.rutherford@company.co.uk', '2015-08-20', NULL, 6, 103, 1000, 125000.00, 'Active'),
('AE100004E', 'George', 'Blackwood', 'g.blackwood@company.co.uk', '2016-01-11', NULL, 8, 104, 1000, 130000.00, 'Active'),
('AF100005F', 'Alistair', 'Vane', 'a.vane@company.co.uk', '2016-04-18', NULL, 4, 106, 1001, 110000.00, 'Active'),
('AG100006G', 'Fiona', 'Gallagher', 'f.gallagher@company.co.uk', '2016-07-01', NULL, 5, 113, 1001, 105000.00, 'Active'),
('AH100007H', 'Dominic', 'Shaw', 'd.shaw@company.co.uk', '2016-11-15', NULL, 12, 123, 1000, 108000.00, 'Active'),
('AJ100008J', 'Oliver', 'Harrison', 'o.harrison@company.co.uk', '2017-02-01', NULL, 3, 105, 1002, 115000.00, 'Active'),
('AK100009K', 'Hannah', 'Abbott', 'h.abbott@company.co.uk', '2017-03-15', NULL, 3, 110, 1002, 92000.00, 'Active'),
('AL100010L', 'Ian', 'Wright', 'i.wright@company.co.uk', '2017-06-01', NULL, 2, 111, 1001, 88000.00, 'Active'),
('AM100011M', 'Jessica', 'Taylor', 'j.taylor@company.co.uk', '2017-09-10', NULL, 6, 115, 1003, 54000.00, 'Active'),
('AN100012N', 'Liam', 'O''Connor', 'l.oconnor@company.co.uk', '2018-01-15', NULL, 7, 117, 1003, 62000.00, 'Active'),
('AP100013P', 'Charlotte', 'Webb', 'c.webb@company.co.uk', '2018-03-20', NULL, 8, 118, 1004, 72000.00, 'Active'),
('AR100014R', 'Benjamin', 'Hayes', 'b.hayes@company.co.uk', '2018-05-12', NULL, 9, 120, 1004, 44000.00, 'Active'),
('AS100015S', 'Amelia', 'Fletcher', 'a.fletcher@company.co.uk', '2018-08-01', NULL, 10, 121, 1000, 78000.00, 'Active'),
('AT100016T', 'Samuel', 'Barker', 's.barker@company.co.uk', '2018-10-15', NULL, 11, 122, 1000, 64000.00, 'Active'),
('AU100017U', 'Rachel', 'Cole', 'r.cole@company.co.uk', '2019-01-10', NULL, 4, 106, 1005, 95000.00, 'Active'),
('AV100018V', 'Daniel', 'Cross', 'd.cross@company.co.uk', '2019-02-28', NULL, 5, 114, 1006, 58000.00, 'Active'),
('AW100019W', 'Megan', 'Davenport', 'm.davenport@company.co.uk', '2019-04-15', NULL, 3, 107, 1008, 86000.00, 'Active'),
('AX100020X', 'Gavin', 'Edwards', 'g.edwards@company.co.uk', '2019-06-01', NULL, 3, 107, 1008, 84000.00, 'Active'),
('AY100021Y', 'Sophie', 'Turner', 's.turner@company.co.uk', '2019-08-19', NULL, 2, 111, 1010, 76000.00, 'Active'),
('AZ100022Z', 'Edward', 'Fox', 'e.fox@company.co.uk', '2019-11-01', NULL, 2, 111, 1010, 74000.00, 'Active'),
('BA100023A', 'Phoebe', 'Grant', 'p.grant@company.co.uk', '2020-01-15', NULL, 3, 107, 1008, 81000.00, 'Active'),
('BB100024B', 'Lucas', 'Hill', 'l.hill@company.co.uk', '2020-02-01', NULL, 3, 107, 1008, 79000.00, 'Active'),
('BC100025C', 'Chloe', 'Ingram', 'c.ingram@company.co.uk', '2020-03-10', NULL, 3, 108, 1019, 62000.00, 'Active'),
('BD100026D', 'Jack', 'Jarvis', 'j.jarvis@company.co.uk', '2020-04-15', NULL, 3, 108, 1019, 59000.00, 'Active'),
('BE100027E', 'Grace', 'King', 'g.king@company.co.uk', '2020-05-20', NULL, 3, 108, 1020, 64000.00, 'Active'),
('BF100028F', 'Ryan', 'Lambert', 'r.lambert@company.co.uk', '2020-06-01', NULL, 3, 108, 1020, 58000.00, 'Active'),
('BG100029G', 'Ella', 'Morgan', 'e.morgan@company.co.uk', '2020-07-15', NULL, 3, 108, 1021, 61000.00, 'Active'),
('BH100030H', 'Harry', 'Newman', 'h.newman@company.co.uk', '2020-08-01', NULL, 3, 108, 1021, 57000.00, 'Active'),
('BJ100031J', 'Mia', 'Osborne', 'm.osborne@company.co.uk', '2020-09-10', NULL, 2, 112, 1022, 58000.00, 'Active'),
('BK100032K', 'Callum', 'Page', 'c.page@company.co.uk', '2020-10-01', NULL, 2, 112, 1022, 54000.00, 'Active'),
('BL100033L', 'Zoe', 'Quinn', 'z.quinn@company.co.uk', '2020-11-15', NULL, 2, 112, 1023, 56000.00, 'Active'),
('BM100034M', 'Nathan', 'Reid', 'n.reid@company.co.uk', '2021-01-05', NULL, 2, 112, 1023, 52000.00, 'Active'),
('BN100035N', 'Abigail', 'Scott', 'a.scott@company.co.uk', '2021-02-01', NULL, 4, 106, 1017, 88000.00, 'Active'),
('BP100036P', 'Toby', 'Townsend', 't.townsend@company.co.uk', '2021-03-15', NULL, 4, 124, 1017, 32000.00, 'Active'),
('BR100037R', 'Lucy', 'Underwood', 'l.underwood@company.co.uk', '2021-04-20', NULL, 4, 124, 1017, 30000.00, 'Active'),
('BS100038S', 'Oliver', 'Videon', 'o.videon@company.co.uk', '2021-05-10', NULL, 5, 114, 1018, 52000.00, 'Active'),
('BT100039T', 'Emma', 'Walker', 'e.walker@company.co.uk', '2021-06-01', NULL, 5, 114, 1018, 49000.00, 'Active'),
('BU100040U', 'Jacob', 'Yates', 'j.yates@company.co.uk', '2021-07-15', NULL, 6, 116, 1011, 31000.00, 'Active'),
('BV100041V', 'Lily', 'Zimmerman', 'l.zimmerman@company.co.uk', '2021-08-01', NULL, 6, 116, 1011, 29000.00, 'Active'),
('BW100042W', 'Adam', 'Archer', 'a.archer@company.co.uk', '2021-09-10', NULL, 7, 117, 1012, 54000.00, 'Active'),
('BX100043X', 'Bethany', 'Ball', 'b.ball@company.co.uk', '2021-10-15', NULL, 8, 119, 1013, 52000.00, 'Active'),
('BY100044Y', 'Connor', 'Chambers', 'c.chambers@company.co.uk', '2021-11-20', NULL, 8, 119, 1013, 48000.00, 'Active'),
('BZ100045Z', 'Daisy', 'Dawson', 'd.dawson@company.co.uk', '2022-01-10', NULL, 9, 120, 1014, 41000.00, 'Active'),
('CA100046A', 'Ethan', 'Elliott', 'e.elliott@company.co.uk', '2022-02-01', NULL, 9, 120, 1014, 39000.00, 'Active'),
('CB100047B', 'Freya', 'Fletcher', 'f.fletcher@company.co.uk', '2022-03-15', NULL, 10, 121, 1015, 68000.00, 'Active'),
('CC100048C', 'Gabriel', 'Glover', 'g.glover@company.co.uk', '2022-04-01', NULL, 10, 121, 1015, 62000.00, 'Active'),
('CD100049D', 'Holly', 'Hammond', 'h.hammond@company.co.uk', '2022-05-10', NULL, 11, 122, 1016, 55000.00, 'Active'),
('CE100050E', 'Isaac', 'Hardy', 'i.hardy@company.co.uk', '2022-06-15', NULL, 11, 122, 1016, 51000.00, 'Active'),
('CF100051F', 'Jasmine', 'Harper', 'j.harper@company.co.uk', '2022-07-20', NULL, 3, 108, 1019, 56000.00, 'Active'),
('CG100052G', 'Kyle', 'Hawkins', 'k.hawkins@company.co.uk', '2022-08-10', NULL, 3, 108, 1020, 54000.00, 'Active'),
('CH100053H', 'Laura', 'Holloway', 'l.holloway@company.co.uk', '2022-09-01', NULL, 3, 108, 1021, 55000.00, 'Active'),
('CJ100054J', 'Matthew', 'Jarrett', 'm.jarrett@company.co.uk', '2022-10-15', NULL, 2, 112, 1022, 51000.00, 'Active'),
('CK100055K', 'Natasha', 'Keating', 'n.keating@company.co.uk', '2022-11-01', NULL, 2, 112, 1023, 49000.00, 'Active'),
('CL100056L', 'Owen', 'Lawrence', 'o.lawrence@company.co.uk', '2022-12-05', NULL, 4, 124, 1017, 28000.00, 'Active'),
('CM100057M', 'Paige', 'Marsh', 'p.marsh@company.co.uk', '2023-01-10', NULL, 5, 114, 1018, 46000.00, 'Active'),
('CN100058N', 'Quinn', 'Miles', 'q.miles@company.co.uk', '2023-01-15', NULL, 3, 109, 1025, 38000.00, 'Active'),
('CP100059P', 'Rhys', 'Mitchell', 'r.mitchell@company.co.uk', '2023-02-01', NULL, 3, 109, 1025, 36000.00, 'Active'),
('CR100060R', 'Sienna', 'Morgan', 's.morgan@company.co.uk', '2023-02-15', NULL, 3, 109, 1026, 37000.00, 'Active'),
('CS100061S', 'Tristan', 'Nash', 't.nash@company.co.uk', '2023-03-01', NULL, 3, 109, 1026, 35000.00, 'Active'),
('CT100062T', 'Una', 'O''Neill', 'u.oneill@company.co.uk', '2023-03-15', NULL, 3, 109, 1027, 39000.00, 'Active'),
('CU100063U', 'Victor', 'Parry', 'v.parry@company.co.uk', '2023-04-01', NULL, 3, 109, 1027, 34000.00, 'Active'),
('CV100064V', 'Willow', 'Payne', 'w.payne@company.co.uk', '2023-04-15', NULL, 3, 109, 1028, 36500.00, 'Active'),
('CW100065W', 'Xavier', 'Pearce', 'x.pearce@company.co.uk', '2023-05-01', NULL, 3, 109, 1028, 35500.00, 'Active'),
('CX100066X', 'Yasmine', 'Plummer', 'y.plummer@company.co.uk', '2023-05-15', NULL, 3, 109, 1008, 38000.00, 'Active'),
('CY100067Y', 'Zachary', 'Potter', 'z.potter@company.co.uk', '2023-06-01', NULL, 3, 109, 1008, 36000.00, 'Active'),
('CZ100068Z', 'Amber', 'Powell', 'a.powell@company.co.uk', '2023-06-15', NULL, 3, 109, 1008, 37500.00, 'Active'),
('DA100069A', 'Bradley', 'Price', 'b.price@company.co.uk', '2023-07-01', NULL, 3, 109, 1008, 35000.00, 'Active'),
('DB100070B', 'Caitlin', 'Read', 'c.read@company.co.uk', '2023-07-15', NULL, 2, 112, 1031, 46000.00, 'Active'),
('DC100071C', 'Dylan', 'Richards', 'd.richards@company.co.uk', '2023-08-01', NULL, 2, 112, 1032, 45000.00, 'Active'),
('DD100072D', 'Evie', 'Richardson', 'e.richardson@company.co.uk', '2023-08-15', NULL, 2, 112, 1033, 47000.00, 'Active'),
('DE100073E', 'Finley', 'Roberts', 'f.roberts@company.co.uk', '2023-09-01', NULL, 2, 112, 1034, 44000.00, 'Active'),
('DF100074F', 'Georgia', 'Robinson', 'g.robinson@company.co.uk', '2023-09-15', NULL, 4, 124, 1017, 27000.00, 'Active'),
('DG100075G', 'Harrison', 'Rose', 'h.rose@company.co.uk', '2023-10-01', NULL, 4, 124, 1017, 26500.00, 'Active'),
('DH100076H', 'Isabel', 'Russell', 'i.russell@company.co.uk', '2023-10-15', NULL, 5, 114, 1018, 44000.00, 'Active'),
('DJ100077J', 'Joel', 'Saunders', 'j.saunders@company.co.uk', '2023-11-01', NULL, 5, 114, 1018, 43000.00, 'Active'),
('DK100078K', 'Kiera', 'Schofield', 'k.schofield@company.co.uk', '2023-11-15', NULL, 6, 116, 1011, 28000.00, 'Active'),
('DL100079L', 'Leon', 'Sharp', 'l.sharp@company.co.uk', '2023-12-01', NULL, 7, 117, 1012, 51000.00, 'Active'),
('DM100080M', 'Maya', 'Shaw', 'm.shaw2@company.co.uk', '2023-12-15', NULL, 8, 119, 1013, 46000.00, 'Active'),
('DN100081N', 'Noah', 'Simpson', 'n.simpson@company.co.uk', '2024-01-08', NULL, 9, 120, 1014, 36000.00, 'Active'),
('DP100082P', 'Olivia', 'Skinner', 'o.skinner@company.co.uk', '2024-01-15', NULL, 10, 121, 1015, 60000.00, 'Active'),
('DR100083R', 'Peter', 'Slater', 'p.slater@company.co.uk', '2024-02-01', NULL, 11, 122, 1016, 49000.00, 'Active'),
('DS100084S', 'Ruby', 'Smith', 'r.smith@company.co.uk', '2024-02-15', NULL, 3, 109, 1025, 34000.00, 'Active'),
('DT100085T', 'Sean', 'Spencer', 's.spencer@company.co.uk', '2024-03-01', NULL, 3, 109, 1026, 33500.00, 'Active'),
('DU100086U', 'Tia', 'Stevens', 't.stevens@company.co.uk', '2024-03-15', NULL, 3, 109, 1027, 35000.00, 'Active'),
('DV100087V', 'Ulysses', 'Stokes', 'u.stokes@company.co.uk', '2024-04-01', NULL, 3, 109, 1028, 34500.00, 'Active'),
('DW100088W', 'Violet', 'Sutton', 'v.sutton@company.co.uk', '2024-04-15', NULL, 2, 112, 1031, 44000.00, 'Active'),
('DX100089X', 'William', 'Tanner', 'w.tanner@company.co.uk', '2024-05-01', NULL, 2, 112, 1032, 45000.00, 'Active'),
('DY100090Y', 'Xena', 'Underhill', 'x.underhill@company.co.uk', '2024-05-15', NULL, 4, 124, 1017, 26000.00, 'Active'),
('DZ100091Z', 'Yusuf', 'Vaughan', 'y.vaughan@company.co.uk', '2024-06-01', NULL, 5, 114, 1018, 42000.00, 'Active'),
('EA100092A', 'Zara', 'Walsh', 'z.walsh@company.co.uk', '2024-06-15', NULL, 6, 116, 1011, 27500.00, 'Active'),
('EB100093B', 'Aaron', 'Ward', 'a.ward@company.co.uk', '2020-01-15', '2023-05-31', 3, 108, 1019, 58000.00, 'Terminated'),
('EC100094C', 'Bella', 'Watkins', 'b.watkins@company.co.uk', '2020-03-01', '2023-08-15', 3, 108, 1020, 56000.00, 'Terminated'),
('ED100095D', 'Christopher', 'Watson', 'c.watson@company.co.uk', '2020-06-10', '2023-11-30', 2, 112, 1022, 52000.00, 'Terminated'),
('EE100096E', 'Eleanor', 'Watts', 'e.watts@company.co.uk', '2021-01-10', '2024-01-31', 4, 124, 1017, 28000.00, 'Terminated'),
('EF100097F', 'Felix', 'Webb', 'f.webb2@company.co.uk', '2021-04-01', '2024-03-31', 8, 119, 1013, 47000.00, 'Terminated'),
('EG100098G', 'Gemma', 'Wheeler', 'g.wheeler@company.co.uk', '2021-07-15', NULL, 3, 108, 1021, 57000.00, 'On Leave'),
('EH100099H', 'Hugo', 'White', 'h.white@company.co.uk', '2021-09-01', NULL, 2, 112, 1023, 53000.00, 'On Leave'),
('EJ100100J', 'Imogen', 'Wilkins', 'i.wilkins@company.co.uk', '2022-01-15', NULL, 6, 116, 1011, 28500.00, 'On Leave'),
('EK100101K', 'Jacob', 'Wilkinson', 'j.wilkinson@company.co.uk', '2022-04-01', NULL, 7, 117, 1012, 52000.00, 'Active'),
('EL100102L', 'Katherine', 'Williams', 'k.williams@company.co.uk', '2022-06-15', NULL, 8, 119, 1013, 49000.00, 'Active'),
('EM100103M', 'Leo', 'Willis', 'l.willis@company.co.uk', '2022-09-01', NULL, 9, 120, 1014, 40000.00, 'Active'),
('EN100104N', 'Molly', 'Wilson', 'm.wilson@company.co.uk', '2022-11-15', NULL, 10, 121, 1015, 64000.00, 'Active');
GO

SELECT * FROM HR.Employees;

INSERT INTO HR.Salaries (EmployeeID, OldSalary, NewSalary, ChangeReason, EffectiveDate, ModifiedBy)
VALUES
(1000, 195000.00, 210000.00, 'Board Approval - Executive Review', '2023-01-01', 'system_admin'),
(1001, 170000.00, 185000.00, 'Board Approval - Executive Review', '2023-01-01', 'system_admin'),
(1002, 132000.00, 145000.00, 'Annual Market Adjustment', '2022-04-01', 'a.pendelton'),
(1003, 115000.00, 125000.00, 'Annual Market Adjustment', '2022-04-01', 'a.pendelton'),
(1004, 120000.00, 130000.00, 'Executive Performance Merit Increase', '2023-01-01', 'a.pendelton'),
(1005, 100000.00, 110000.00, 'Role Scope Expansion', '2023-04-01', 'v.sterling'),
(1006, 95000.00, 105000.00, 'Annual Market Adjustment', '2023-04-01', 'v.sterling'),
(1007, 98000.00, 108000.00, 'Annual Market Adjustment', '2023-04-01', 'a.pendelton'),
(1008, 102000.00, 115000.00, 'Promotion to Lead Data Architect', '2022-01-01', 'c.montgomery'),
(1009, 82000.00, 92000.00, 'Promotion to Lead Analytics Engineer', '2022-06-01', 'c.montgomery'),
(1010, 80000.00, 88000.00, 'Senior Merit Raise', '2022-04-01', 'v.sterling'),
(1011, 48000.00, 54000.00, 'Annual Merit Increase', '2023-04-01', 'e.rutherford'),
(1012, 55000.00, 62000.00, 'Annual Merit Increase', '2023-04-01', 'e.rutherford'),
(1013, 65000.00, 72000.00, 'Market Adjustment', '2022-04-01', 'g.blackwood'),
(1014, 40000.00, 44000.00, 'Annual Merit Increase', '2023-04-01', 'g.blackwood'),
(1015, 70000.00, 78000.00, 'Sales Target Bonus Conversion', '2023-01-01', 'a.pendelton'),
(1016, 58000.00, 64000.00, 'Annual Market Adjustment', '2023-04-01', 'a.pendelton'),
(1017, 85000.00, 95000.00, 'Promotion to Lead DevOps Architect', '2023-06-01', 'a.vane'),
(1018, 52000.00, 58000.00, 'Annual Merit Increase', '2023-04-01', 'f.gallagher'),
(1019, 78000.00, 86000.00, 'Senior Merit Increase', '2023-04-01', 'o.harrison'),
(1020, 76000.00, 84000.00, 'Senior Merit Increase', '2023-04-01', 'o.harrison'),
(1021, 68000.00, 76000.00, 'Promotion to Senior Software Engineer', '2022-09-01', 'i.wright'),
(1022, 66000.00, 74000.00, 'Promotion to Senior Software Engineer', '2022-09-01', 'i.wright'),
(1023, 72000.00, 81000.00, 'Senior Merit Increase', '2023-04-01', 'o.harrison'),
(1024, 70000.00, 79000.00, 'Senior Merit Increase', '2023-04-01', 'o.harrison'),
(1025, 54000.00, 62000.00, 'Mid-Level Re-evaluation', '2023-04-01', 'm.davenport'),
(1026, 52000.00, 59000.00, 'Annual Merit Increase', '2023-04-01', 'm.davenport'),
(1027, 56000.00, 64000.00, 'Annual Merit Increase', '2023-04-01', 'g.edwards'),
(1028, 51000.00, 58000.00, 'Annual Merit Increase', '2023-04-01', 'g.edwards'),
(1029, 53000.00, 61000.00, 'Annual Merit Increase', '2023-04-01', 'h.abbott'),
(1030, 50000.00, 57000.00, 'Annual Merit Increase', '2023-04-01', 'h.abbott'),
(1031, 51000.00, 58000.00, 'Annual Merit Increase', '2023-04-01', 's.turner'),
(1032, 48000.00, 54000.00, 'Annual Merit Increase', '2023-04-01', 's.turner'),
(1033, 49000.00, 56000.00, 'Annual Merit Increase', '2023-04-01', 'e.fox'),
(1034, 46000.00, 52000.00, 'Annual Merit Increase', '2023-04-01', 'e.fox'),
(1035, 78000.00, 88000.00, 'Senior Infrastructure Alignment', '2023-04-01', 'r.cole'),
(1036, 28000.00, 32000.00, 'Annual Merit Increase', '2023-04-01', 'r.cole'),
(1037, 26000.00, 30000.00, 'Annual Merit Increase', '2023-04-01', 'r.cole'),
(1038, 46000.00, 52000.00, 'Annual Merit Increase', '2023-04-01', 'd.cross'),
(1039, 43000.00, 49000.00, 'Annual Merit Increase', '2023-04-01', 'd.cross'),
(1040, 27000.00, 31000.00, 'Annual Merit Increase', '2023-04-01', 'j.taylor'),
(1041, 25000.00, 29000.00, 'Annual Merit Increase', '2023-04-01', 'j.taylor'),
(1042, 47000.00, 54000.00, 'Annual Merit Increase', '2023-04-01', 'l.oconnor'),
(1043, 45000.00, 52000.00, 'Annual Merit Increase', '2023-04-01', 'c.webb'),
(1044, 42000.00, 48000.00, 'Annual Merit Increase', '2023-04-01', 'c.webb'),
(1045, 36000.00, 41000.00, 'Annual Merit Increase', '2023-04-01', 'b.hayes'),
(1046, 34000.00, 39000.00, 'Annual Merit Increase', '2023-04-01', 'b.hayes'),
(1047, 60000.00, 68000.00, 'Sales Quota Target Re-band', '2023-04-01', 'a.fletcher'),
(1048, 54000.00, 62000.00, 'Sales Quota Target Re-band', '2023-04-01', 'a.fletcher'),
(1049, 48000.00, 55000.00, 'Annual Merit Increase', '2023-04-01', 's.barker'),
(1050, 44000.00, 51000.00, 'Annual Merit Increase', '2023-04-01', 's.barker'),
(1051, 49000.00, 56000.00, 'Annual Merit Increase', '2023-10-01', 'm.davenport'),
(1052, 47000.00, 54000.00, 'Annual Merit Increase', '2023-10-01', 'g.edwards'),
(1053, 48000.00, 55000.00, 'Annual Merit Increase', '2023-10-01', 'h.abbott'),
(1054, 44000.00, 51000.00, 'Annual Merit Increase', '2023-10-01', 's.turner'),
(1055, 43000.00, 49000.00, 'Annual Merit Increase', '2023-10-01', 'e.fox'),
(1056, 25000.00, 28000.00, 'Annual Merit Increase', '2023-10-01', 'r.cole'),
(1057, 40000.00, 46000.00, 'Annual Merit Increase', '2024-01-01', 'd.cross'),
(1058, 34000.00, 38000.00, 'Probation Completion Adjustment', '2023-07-15', 'p.grant'),
(1059, 32000.00, 36000.00, 'Probation Completion Adjustment', '2023-08-01', 'p.grant'),
(1060, 33000.00, 37000.00, 'Probation Completion Adjustment', '2023-08-15', 'l.hill'),
(1061, 31000.00, 35000.00, 'Probation Completion Adjustment', '2023-09-01', 'l.hill'),
(1062, 35000.00, 39000.00, 'Probation Completion Adjustment', '2023-09-15', 'p.grant'),
(1063, 30000.00, 34000.00, 'Probation Completion Adjustment', '2023-10-01', 'p.grant'),
(1064, 32500.00, 36500.00, 'Probation Completion Adjustment', '2023-10-15', 'l.hill'),
(1065, 31500.00, 35500.00, 'Probation Completion Adjustment', '2023-11-01', 'l.hill'),
(1066, 34000.00, 38000.00, 'Probation Completion Adjustment', '2023-11-15', 'o.harrison'),
(1067, 32000.00, 36000.00, 'Probation Completion Adjustment', '2023-12-01', 'o.harrison'),
(1068, 33500.00, 37500.00, 'Probation Completion Adjustment', '2023-12-15', 'o.harrison'),
(1069, 31000.00, 35000.00, 'Probation Completion Adjustment', '2024-01-01', 'o.harrison'),
(1070, 41000.00, 46000.00, 'Annual Merit Increase', '2024-01-01', 'm.osborne'),
(1071, 40000.00, 45000.00, 'Annual Merit Increase', '2024-01-01', 'c.page'),
(1072, 42000.00, 47000.00, 'Annual Merit Increase', '2024-01-01', 'z.quinn'),
(1073, 39000.00, 44000.00, 'Annual Merit Increase', '2024-01-01', 'n.reid'),
(1074, 24000.00, 27000.00, 'Annual Merit Increase', '2024-01-01', 'a.scott'),
(1075, 23500.00, 26500.00, 'Annual Merit Increase', '2024-01-01', 'a.scott'),
(1076, 39000.00, 44000.00, 'Annual Merit Increase', '2024-01-01', 'o.videon'),
(1077, 38000.00, 43000.00, 'Annual Merit Increase', '2024-01-01', 'o.videon'),
(1078, 25000.00, 28000.00, 'Annual Merit Increase', '2024-01-01', 'j.yates'),
(1079, 45000.00, 51000.00, 'Annual Merit Increase', '2024-01-01', 'a.archer'),
(1080, 41000.00, 46000.00, 'Annual Merit Increase', '2024-01-01', 'b.ball'),
(1081, 32000.00, 36000.00, 'Probation Completion Adjustment', '2024-02-01', 'd.dawson'),
(1082, 53000.00, 60000.00, 'Annual Merit Increase', '2024-02-01', 'f.fletcher'),
(1083, 43000.00, 49000.00, 'Annual Merit Increase', '2024-02-01', 'h.hammond'),
(1084, 30000.00, 34000.00, 'Probation Completion Adjustment', '2024-03-01', 'p.grant'),
(1085, 29500.00, 33500.00, 'Probation Completion Adjustment', '2024-04-01', 'l.hill'),
(1086, 31000.00, 35000.00, 'Probation Completion Adjustment', '2024-04-15', 'p.grant'),
(1087, 30500.00, 34500.00, 'Probation Completion Adjustment', '2024-05-01', 'l.hill'),
(1088, 39000.00, 44000.00, 'Annual Merit Increase', '2024-05-01', 'm.osborne'),
(1089, 40000.00, 45000.00, 'Annual Merit Increase', '2024-06-01', 'c.page'),
(1090, 23000.00, 26000.00, 'Annual Merit Increase', '2024-06-01', 'a.scott'),
(1091, 37000.00, 42000.00, 'Annual Merit Increase', '2024-07-01', 'o.videon'),
(1092, 24500.00, 27500.00, 'Annual Merit Increase', '2024-07-01', 'j.yates'),
(1093, 52000.00, 58000.00, 'Pre-exit Retention Review (Failed)', '2022-04-01', 'm.davenport'),
(1094, 50000.00, 56000.00, 'Pre-exit Retention Review (Failed)', '2022-04-01', 'g.edwards'),
(1095, 46000.00, 52000.00, 'Annual Merit Increase', '2022-04-01', 'm.jarrett'),
(1096, 25000.00, 28000.00, 'Annual Merit Increase', '2023-04-01', 'r.cole'),
(1097, 42000.00, 47000.00, 'Annual Merit Increase', '2023-04-01', 'b.ball'),
(1098, 51000.00, 57000.00, 'Maternity Return Leveling Bump', '2023-01-01', 'h.abbott'),
(1099, 47000.00, 53000.00, 'Market Adjustment', '2023-01-01', 'n.keating'),
(1100, 25000.00, 28500.00, 'Annual Merit Increase', '2023-04-01', 'j.yates'),
(1101, 46000.00, 52000.00, 'Annual Merit Increase', '2023-04-01', 'a.archer'),
(1102, 43000.00, 49000.00, 'Annual Merit Increase', '2023-04-01', 'b.ball'),
(1103, 35000.00, 40000.00, 'Annual Merit Increase', '2023-10-01', 'c.chambers'),
(1104, 56000.00, 64000.00, 'Annual Merit Increase', '2023-10-01', 'a.fletcher');
GO

SELECT * FROM HR.Salaries;

INSERT INTO HR.Payrolls (PeriodStartDate, PeriodEndDate, ProcessDate, TotalGrossPay, TotalDeductions, TotalNetPay, RunStatus)
VALUES
('2024-04-01', '2024-04-30', '2024-04-26 14:00:00', 485000.00, 145500.00, 339500.00, 'Completed'),
('2024-05-01', '2024-05-31', '2024-05-28 14:00:00', 486200.00, 145860.00, 340340.00, 'Completed'),
('2024-06-01', '2024-06-30', '2024-06-27 14:00:00', 488500.00, 146550.00, 341950.00, 'Completed'),
('2024-07-01', '2024-07-31', '2024-07-26 14:00:00', 491000.00, 147300.00, 343700.00, 'Completed'),
('2024-08-01', '2024-08-31', '2024-08-28 14:00:00', 489500.00, 146850.00, 342650.00, 'Completed'),
('2024-09-01', '2024-09-30', '2024-09-27 14:00:00', 492800.00, 147840.00, 344960.00, 'Completed'),
('2024-10-01', '2024-10-31', '2024-10-28 14:00:00', 495000.00, 148500.00, 346500.00, 'Completed'),
('2024-11-01', '2024-11-30', '2024-11-27 14:00:00', 496200.00, 148860.00, 347340.00, 'Completed'),
('2024-12-01', '2024-12-31', '2024-12-20 14:00:00', 545000.00, 163500.00, 381500.00, 'Completed'), 
('2025-01-01', '2025-01-31', '2025-01-28 14:00:00', 498000.00, 149400.00, 348600.00, 'Completed'),
('2025-02-01', '2025-02-28', '2025-02-26 14:00:00', 498500.00, 149550.00, 348950.00, 'Completed'),
('2025-03-01', '2025-03-31', '2025-03-27 14:00:00', 501000.00, 150300.00, 350700.00, 'Completed'),
('2025-04-01', '2025-04-30', '2025-04-25 14:00:00', 505000.00, 151500.00, 353500.00, 'Completed'),
('2025-05-01', '2025-05-31', '2025-05-28 14:00:00', 506500.00, 151950.00, 354550.00, 'Completed'),
('2025-06-01', '2025-06-30', '2025-06-27 14:00:00', 508000.00, 152400.00, 355600.00, 'Completed'),
('2025-07-01', '2025-07-31', '2025-07-28 14:00:00', 510200.00, 153060.00, 357140.00, 'Completed'),
('2025-08-01', '2025-08-31', '2025-08-27 14:00:00', 511000.00, 153300.00, 357700.00, 'Completed'),
('2025-09-01', '2025-09-30', '2025-09-26 14:00:00', 513500.00, 154050.00, 359450.00, 'Completed'),
('2025-10-01', '2025-10-31', '2025-10-28 14:00:00', 515000.00, 154500.00, 360500.00, 'Completed'),
('2025-11-01', '2025-11-30', '2025-11-27 14:00:00', 516800.00, 155040.00, 361760.00, 'Completed'),
('2025-12-01', '2025-12-31', '2025-12-19 14:00:00', 57000.00, 171000.00, 399000.00, 'Completed'),
('2026-01-01', '2026-01-31', '2026-01-28 14:00:00', 520000.00, 156000.00, 364000.00, 'Completed'),
('2026-02-01', '2026-02-28', '2026-02-26 14:00:00', 521500.00, 156450.00, 365050.00, 'Completed'),
('2026-03-01', '2026-03-31', '2026-03-27 14:00:00', 525000.00, 157500.00, 367500.00, 'Completed');
GO

SELECT * FROM HR.Payrolls;

INSERT INTO HR.Payslips (PayrollID, EmployeeID, BasePay, OvertimePay, BonusPay, PAYE, NIC, PensionDeduction, OtherDeductions)
VALUES
(5021, 1000, 17500.00, 0.00, 5000.00, 7850.00, 680.00, 875.00, 0.00),
(5021, 1001, 15416.67, 0.00, 3500.00, 6200.00, 590.00, 770.83, 0.00),
(5021, 1002, 12083.33, 0.00, 2000.00, 4450.00, 480.00, 604.17, 0.00),
(5021, 1003, 10416.67, 0.00, 1500.00, 3650.00, 420.00, 520.83, 0.00),
(5021, 1004, 10833.33, 0.00, 1500.00, 3850.00, 435.00, 541.67, 0.00),
(5021, 1005, 9166.67, 0.00, 1000.00, 3050.00, 370.00, 458.33, 0.00),
(5021, 1006, 8750.00, 0.00, 1000.00, 2850.00, 355.00, 437.50, 0.00),
(5021, 1007, 9000.00, 0.00, 1000.00, 2980.00, 365.00, 450.00, 0.00),
(5021, 1008, 9583.33, 0.00, 1200.00, 3250.00, 388.00, 479.17, 0.00),
(5021, 1009, 7666.67, 0.00, 800.00, 2350.00, 312.00, 383.33, 0.00),
(5021, 1010, 7333.33, 0.00, 500.00, 2180.00, 298.00, 366.67, 0.00),
(5021, 1011, 4500.00, 250.00, 0.00, 920.00, 185.00, 225.00, 0.00),
(5021, 1012, 5166.67, 300.00, 0.00, 1150.00, 211.00, 258.33, 0.00),
(5021, 1013, 6000.00, 0.00, 600.00, 1580.00, 245.00, 300.00, 0.00),
(5021, 1014, 3666.67, 150.00, 0.00, 610.00, 151.00, 183.33, 0.00),
(5021, 1015, 6500.00, 0.00, 2500.00, 2380.00, 265.00, 325.00, 0.00),
(5021, 1016, 5333.33, 0.00, 500.00, 1280.00, 218.00, 266.67, 0.00),
(5021, 1017, 7916.67, 0.00, 1000.00, 2480.00, 321.00, 395.83, 0.00),
(5021, 1018, 4833.33, 200.00, 0.00, 1040.00, 198.00, 241.67, 0.00),
(5021, 1019, 7166.67, 0.00, 750.00, 2100.00, 291.00, 358.33, 0.00),
(5021, 1020, 7000.00, 0.00, 750.00, 2020.00, 285.00, 350.00, 0.00),
(5021, 1021, 6333.33, 0.00, 500.00, 1720.00, 258.00, 316.67, 0.00),
(5021, 1022, 6166.67, 0.00, 500.00, 1650.00, 251.00, 308.33, 0.00),
(5021, 1023, 6750.00, 0.00, 600.00, 1910.00, 275.00, 337.50, 0.00),
(5021, 1024, 6583.33, 0.00, 600.00, 1830.00, 268.00, 329.17, 0.00),
(5021, 1025, 5166.67, 350.00, 0.00, 1170.00, 211.00, 258.33, 0.00),
(5021, 1026, 4916.67, 250.00, 0.00, 1070.00, 201.00, 245.83, 0.00),
(5021, 1027, 5333.33, 400.00, 0.00, 1240.00, 218.00, 266.67, 0.00),
(5021, 1028, 4833.33, 200.00, 0.00, 1040.00, 198.00, 241.67, 0.00),
(5021, 1029, 5083.33, 300.00, 0.00, 1140.00, 208.00, 254.17, 0.00),
(5021, 1030, 4750.00, 150.00, 0.00, 1000.00, 195.00, 237.50, 0.00),
(5021, 1031, 4833.33, 200.00, 0.00, 1040.00, 198.00, 241.67, 0.00),
(5021, 1032, 4500.00, 150.00, 0.00, 910.00, 185.00, 225.00, 0.00),
(5021, 1033, 4666.67, 200.00, 0.00, 970.00, 191.00, 233.33, 0.00),
(5021, 1034, 4333.33, 100.00, 0.00, 840.00, 178.00, 216.67, 0.00),
(5021, 1035, 7333.33, 0.00, 800.00, 2210.00, 298.00, 366.67, 0.00),
(5021, 1036, 2666.67, 100.00, 0.00, 280.00, 111.00, 133.33, 0.00),
(5021, 1037, 2500.00, 100.00, 0.00, 230.00, 105.00, 125.00, 0.00),
(5021, 1038, 4333.33, 150.00, 0.00, 850.00, 178.00, 216.67, 0.00),
(5021, 1039, 4083.33, 100.00, 0.00, 750.00, 168.00, 204.17, 0.00),
(5021, 1040, 2583.33, 50.00, 0.00, 250.00, 108.00, 129.17, 0.00),
(5021, 1041, 2416.67, 50.00, 0.00, 200.00, 101.00, 120.83, 0.00),
(5021, 1042, 4500.00, 200.00, 0.00, 920.00, 185.00, 225.00, 0.00),
(5021, 1043, 4333.33, 150.00, 0.00, 850.00, 178.00, 216.67, 0.00),
(5021, 1044, 4000.00, 100.00, 0.00, 720.00, 165.00, 200.00, 0.00),
(5021, 1045, 3416.67, 100.00, 0.00, 500.00, 141.00, 170.83, 0.00),
(5021, 1046, 3250.00, 50.00, 0.00, 440.00, 135.00, 162.50, 0.00),
(5021, 1047, 5666.67, 0.00, 1200.00, 1820.00, 231.00, 283.33, 0.00),
(5021, 1048, 5166.67, 0.00, 1000.00, 1580.00, 211.00, 258.33, 0.00),
(5021, 1049, 4583.33, 150.00, 0.00, 940.00, 188.00, 229.17, 0.00),
(5021, 1050, 4250.00, 100.00, 0.00, 810.00, 175.00, 212.50, 0.00),
(5021, 1051, 4666.67, 200.00, 0.00, 970.00, 191.00, 233.33, 0.00),
(5021, 1052, 4500.00, 150.00, 0.00, 910.00, 185.00, 225.00, 0.00),
(5021, 1053, 4583.33, 150.00, 0.00, 940.00, 188.00, 229.17, 0.00),
(5021, 1054, 4250.00, 100.00, 0.00, 810.00, 175.00, 212.50, 0.00),
(5021, 1055, 4083.33, 100.00, 0.00, 750.00, 168.00, 204.17, 0.00),
(5021, 1056, 2333.33, 50.00, 0.00, 180.00, 98.00, 116.67, 0.00),
(5021, 1057, 3833.33, 100.00, 0.00, 660.00, 158.00, 191.67, 0.00),
(5021, 1058, 3166.67, 100.00, 0.00, 410.00, 131.00, 158.33, 0.00),
(5021, 1059, 3000.00, 100.00, 0.00, 350.00, 125.00, 150.00, 0.00),
(5021, 1060, 3083.33, 100.00, 0.00, 380.00, 128.00, 154.17, 0.00),
(5021, 1061, 2916.67, 50.00, 0.00, 320.00, 121.00, 145.83, 0.00),
(5021, 1062, 3250.00, 100.00, 0.00, 440.00, 135.00, 162.50, 0.00),
(5021, 1063, 2833.33, 50.00, 0.00, 290.00, 118.00, 141.67, 0.00),
(5021, 1064, 3041.67, 100.00, 0.00, 370.00, 126.00, 152.08, 0.00),
(5021, 1065, 2958.33, 50.00, 0.00, 330.00, 123.00, 147.92, 0.00),
(5021, 1066, 3166.67, 100.00, 0.00, 410.00, 131.00, 158.33, 0.00),
(5021, 1067, 3000.00, 50.00, 0.00, 350.00, 125.00, 150.00, 0.00),
(5021, 1068, 3125.00, 100.00, 0.00, 390.00, 130.00, 156.25, 0.00),
(5021, 1069, 2916.67, 50.00, 0.00, 320.00, 121.00, 145.83, 0.00),
(5021, 1070, 3833.33, 150.00, 0.00, 660.00, 158.00, 191.67, 0.00),
(5021, 1071, 3750.00, 100.00, 0.00, 630.00, 155.00, 187.50, 0.00),
(5021, 1072, 3916.67, 150.00, 0.00, 690.00, 161.00, 195.83, 0.00),
(5021, 1073, 3666.67, 100.00, 0.00, 600.00, 151.00, 183.33, 0.00),
(5021, 1074, 2250.00, 50.00, 0.00, 150.00, 95.00, 112.50, 0.00),
(5021, 1075, 2208.33, 50.00, 0.00, 130.00, 93.00, 110.42, 0.00),
(5021, 1076, 3666.67, 100.00, 0.00, 600.00, 151.00, 183.33, 0.00),
(5021, 1077, 3583.33, 100.00, 0.00, 570.00, 148.00, 179.17, 0.00),
(5021, 1078, 2333.33, 50.00, 0.00, 180.00, 98.00, 116.67, 0.00),
(5021, 1079, 4250.00, 150.00, 0.00, 810.00, 175.00, 212.50, 0.00),
(5021, 1080, 3833.33, 100.00, 0.00, 660.00, 158.00, 191.67, 0.00),
(5021, 1081, 3000.00, 50.00, 0.00, 350.00, 125.00, 150.00, 0.00),
(5021, 1082, 5000.00, 200.00, 0.00, 1100.00, 205.00, 250.00, 0.00),
(5021, 1083, 4083.33, 100.00, 0.00, 750.00, 168.00, 204.17, 0.00),
(5021, 1084, 2833.33, 50.00, 0.00, 290.00, 118.00, 141.67, 0.00),
(5021, 1085, 2791.67, 50.00, 0.00, 270.00, 116.00, 139.58, 0.00),
(5021, 1086, 2916.67, 50.00, 0.00, 320.00, 121.00, 145.83, 0.00),
(5021, 1087, 2875.00, 50.00, 0.00, 300.00, 120.00, 143.75, 0.00),
(5021, 1088, 3666.67, 100.00, 0.00, 600.00, 151.00, 183.33, 0.00),
(5021, 1089, 3750.00, 100.00, 0.00, 630.00, 155.00, 187.50, 0.00),
(5021, 1090, 2166.67, 50.00, 0.00, 120.00, 91.00, 108.33, 0.00),
(5021, 1091, 3500.00, 100.00, 0.00, 540.00, 145.00, 175.00, 0.00),
(5021, 1092, 2291.67, 50.00, 0.00, 160.00, 96.00, 114.58, 0.00),
(5021, 1093, 4833.33, 0.00, 0.00, 1040.00, 198.00, 241.67, 0.00),
(5021, 1094, 4666.67, 0.00, 0.00, 970.00, 191.00, 233.33, 0.00),
(5021, 1095, 4333.33, 0.00, 0.00, 840.00, 178.00, 216.67, 0.00),
(5021, 1096, 2333.33, 0.00, 0.00, 180.00, 98.00, 116.67, 0.00),
(5021, 1097, 3916.67, 0.00, 0.00, 690.00, 161.00, 195.83, 0.00),
(5021, 1098, 4750.00, 100.00, 0.00, 1000.00, 195.00, 237.50, 0.00),
(5021, 1099, 4416.67, 100.00, 0.00, 880.00, 181.00, 220.83, 0.00),
(5021, 1100, 2375.00, 50.00, 0.00, 190.00, 100.00, 118.75, 0.00),
(5021, 1101, 4333.33, 100.00, 0.00, 840.00, 178.00, 216.67, 0.00),
(5021, 1102, 4083.33, 100.00, 0.00, 750.00, 168.00, 204.17, 0.00),
(5021, 1103, 3333.33, 50.00, 0.00, 470.00, 138.00, 166.67, 0.00),
(5021, 1104, 5333.33, 200.00, 0.00, 1240.00, 218.00, 266.67, 0.00);
GO

SELECT * FROM HR.Payslips;

INSERT INTO HR.Absences (EmployeeID, LeaveType, StartDate, EndDate, ApprovalStatus, ApprovedBy)
VALUES
(1000, 'Annual Leave', '2024-06-10', '2024-06-21', 'Approved', 1000),
(1001, 'Annual Leave', '2024-07-01', '2024-07-12', 'Approved', 1000),
(1002, 'Annual Leave', '2024-08-05', '2024-08-16', 'Approved', 1000),
(1003, 'Annual Leave', '2024-05-13', '2024-05-17', 'Approved', 1000),
(1004, 'Annual Leave', '2024-09-02', '2024-09-13', 'Approved', 1000),
(1005, 'Annual Leave', '2024-06-24', '2024-06-28', 'Approved', 1001),
(1006, 'Annual Leave', '2024-07-15', '2024-07-26', 'Approved', 1001),
(1007, 'Annual Leave', '2024-08-19', '2024-08-30', 'Approved', 1000),
(1008, 'Annual Leave', '2024-04-10', '2024-04-17', 'Approved', 1002),
(1008, 'Statutory Sick Pay', '2024-11-04', '2024-11-06', 'Approved', 1002),
(1009, 'Annual Leave', '2024-05-20', '2024-05-31', 'Approved', 1002),
(1010, 'Annual Leave', '2024-06-03', '2024-06-14', 'Approved', 1001),
(1011, 'Annual Leave', '2024-07-08', '2024-07-19', 'Approved', 1003),
(1012, 'Annual Leave', '2024-08-12', '2024-08-23', 'Approved', 1003),
(1013, 'Annual Leave', '2024-09-16', '2024-09-27', 'Approved', 1004),
(1014, 'Annual Leave', '2024-10-07', '2024-10-18', 'Approved', 1004),
(1015, 'Annual Leave', '2024-06-17', '2024-06-28', 'Approved', 1000),
(1016, 'Annual Leave', '2024-07-22', '2024-08-02', 'Approved', 1000),
(1017, 'Annual Leave', '2024-08-05', '2024-08-16', 'Approved', 1005),
(1018, 'Annual Leave', '2024-09-09', '2024-09-20', 'Approved', 1006),
(1019, 'Annual Leave', '2024-05-06', '2024-05-17', 'Approved', 1008),
(1020, 'Annual Leave', '2024-06-10', '2024-06-21', 'Approved', 1008),
(1021, 'Paternity', '2024-02-12', '2024-02-23', 'Approved', 1010),
(1022, 'Annual Leave', '2024-07-01', '2024-07-12', 'Approved', 1010),
(1023, 'Annual Leave', '2024-08-12', '2024-08-23', 'Approved', 1008),
(1024, 'Statutory Sick Pay', '2024-03-11', '2024-03-15', 'Approved', 1008),
(1025, 'Annual Leave', '2024-05-13', '2024-05-24', 'Approved', 1019),
(1026, 'Annual Leave', '2024-06-17', '2024-06-28', 'Approved', 1019),
(1027, 'Annual Leave', '2024-07-15', '2024-07-26', 'Approved', 1020),
(1028, 'Annual Leave', '2024-08-19', '2024-08-30', 'Approved', 1020),
(1029, 'Annual Leave', '2024-09-02', '2024-09-13', 'Approved', 1021),
(1030, 'Annual Leave', '2024-04-22', '2024-04-26', 'Approved', 1021),
(1031, 'Annual Leave', '2024-05-27', '2024-06-07', 'Approved', 1022),
(1032, 'Annual Leave', '2024-07-08', '2024-07-19', 'Approved', 1022),
(1033, 'Annual Leave', '2024-08-05', '2024-08-16', 'Approved', 1023),
(1034, 'Annual Leave', '2024-09-09', '2024-09-20', 'Approved', 1023),
(1035, 'Maternity', '2024-01-15', '2024-07-15', 'Approved', 1017),
(1036, 'Annual Leave', '2024-06-10', '2024-06-21', 'Approved', 1017),
(1037, 'Annual Leave', '2024-07-15', '2024-07-26', 'Approved', 1017),
(1038, 'Annual Leave', '2024-08-12', '2024-08-23', 'Approved', 1018),
(1039, 'Annual Leave', '2024-09-16', '2024-09-27', 'Approved', 1018),
(1040, 'Annual Leave', '2024-05-20', '2024-05-31', 'Approved', 1011),
(1041, 'Annual Leave', '2024-06-17', '2024-06-28', 'Approved', 1011),
(1042, 'Annual Leave', '2024-07-22', '2024-08-02', 'Approved', 1012),
(1043, 'Annual Leave', '2024-08-19', '2024-08-30', 'Approved', 1013),
(1044, 'Annual Leave', '2024-09-23', '2024-10-04', 'Approved', 1013),
(1045, 'Annual Leave', '2024-04-15', '2024-04-26', 'Approved', 1014),
(1046, 'Annual Leave', '2024-05-13', '2024-05-24', 'Approved', 1014),
(1047, 'Annual Leave', '2024-06-10', '2024-06-21', 'Approved', 1015),
(1048, 'Annual Leave', '2024-07-15', '2024-07-26', 'Approved', 1015),
(1049, 'Annual Leave', '2024-08-12', '2024-08-23', 'Approved', 1016),
(1050, 'Annual Leave', '2024-09-16', '2024-09-27', 'Approved', 1016),
(1051, 'Annual Leave', '2024-05-06', '2024-05-17', 'Approved', 1019),
(1052, 'Annual Leave', '2024-06-03', '2024-06-14', 'Approved', 1020),
(1053, 'Annual Leave', '2024-07-01', '2024-07-12', 'Approved', 1021),
(1054, 'Annual Leave', '2024-08-05', '2024-08-16', 'Approved', 1022),
(1055, 'Annual Leave', '2024-09-02', '2024-09-13', 'Approved', 1023),
(1056, 'Annual Leave', '2024-10-07', '2024-10-18', 'Approved', 1017),
(1057, 'Annual Leave', '2024-11-04', '2024-11-15', 'Approved', 1018),
(1058, 'Annual Leave', '2024-06-17', '2024-06-28', 'Approved', 1025),
(1059, 'Annual Leave', '2024-07-22', '2024-08-02', 'Approved', 1025),
(1060, 'Annual Leave', '2024-08-19', '2024-08-30', 'Approved', 1026),
(1061, 'Annual Leave', '2024-09-23', '2024-10-04', 'Approved', 1026),
(1062, 'Annual Leave', '2024-05-13', '2024-05-24', 'Approved', 1027),
(1063, 'Annual Leave', '2024-06-10', '2024-06-21', 'Approved', 1027),
(1064, 'Annual Leave', '2024-07-15', '2024-07-26', 'Approved', 1028),
(1065, 'Annual Leave', '2024-08-12', '2024-08-23', 'Approved', 1028),
(1066, 'Annual Leave', '2024-09-16', '2024-09-27', 'Approved', 1008),
(1067, 'Annual Leave', '2024-10-14', '2024-10-25', 'Approved', 1008),
(1068, 'Annual Leave', '2024-05-20', '2024-05-31', 'Approved', 1008),
(1069, 'Annual Leave', '2024-06-24', '2024-07-05', 'Approved', 1008),
(1070, 'Annual Leave', '2024-07-29', '2024-08-09', 'Approved', 1031),
(1071, 'Annual Leave', '2024-08-26', '2024-09-06', 'Approved', 1032),
(1072, 'Annual Leave', '2024-09-30', '2024-10-11', 'Approved', 1033),
(1073, 'Annual Leave', '2024-11-11', '2024-11-22', 'Approved', 1034),
(1074, 'Statutory Sick Pay', '2024-02-05', '2024-02-09', 'Approved', 1017),
(1075, 'Annual Leave', '2024-06-03', '2024-06-14', 'Approved', 1017),
(1076, 'Annual Leave', '2024-07-08', '2024-07-19', 'Approved', 1018),
(1077, 'Annual Leave', '2024-08-12', '2024-08-23', 'Approved', 1018),
(1078, 'Annual Leave', '2024-09-16', '2024-09-27', 'Approved', 1011),
(1079, 'Shared Parental', '2024-04-01', '2024-06-01', 'Approved', 1012),
(1080, 'Annual Leave', '2024-07-15', '2024-07-26', 'Approved', 1013),
(1081, 'Annual Leave', '2024-08-19', '2024-08-30', 'Approved', 1014),
(1082, 'Annual Leave', '2024-09-23', '2024-10-04', 'Approved', 1015),
(1083, 'Annual Leave', '2024-10-21', '2024-11-01', 'Approved', 1016),
(1084, 'Annual Leave', '2024-06-10', '2024-06-21', 'Approved', 1025),
(1085, 'Annual Leave', '2024-07-15', '2024-07-26', 'Approved', 1026),
(1086, 'Annual Leave', '2024-08-12', '2024-08-23', 'Approved', 1027),
(1087, 'Annual Leave', '2024-09-16', '2024-09-27', 'Approved', 1028),
(1088, 'Annual Leave', '2024-05-20', '2024-05-31', 'Approved', 1031),
(1089, 'Annual Leave', '2024-06-17', '2024-06-28', 'Approved', 1032),
(1090, 'Unpaid', '2024-03-04', '2024-03-08', 'Approved', 1017),
(1091, 'Annual Leave', '2024-07-22', '2024-08-02', 'Approved', 1018),
(1092, 'Annual Leave', '2024-08-19', '2024-08-30', 'Approved', 1011),
(1093, 'Annual Leave', '2023-04-10', '2023-04-21', 'Approved', 1019),
(1094, 'Annual Leave', '2023-05-15', '2023-05-26', 'Approved', 1020),
(1095, 'Annual Leave', '2023-06-12', '2023-06-23', 'Approved', 1022),
(1096, 'Annual Leave', '2023-11-06', '2023-11-17', 'Approved', 1017),
(1097, 'Annual Leave', '2023-12-04', '2023-12-15', 'Approved', 1013),
(1098, 'Maternity', '2023-02-01', '2023-11-01', 'Approved', 1021),
(1099, 'Annual Leave', '2024-08-05', '2024-08-16', 'Approved', 1023),
(1100, 'Annual Leave', '2024-09-09', '2024-09-20', 'Approved', 1011),
(1101, 'Annual Leave', '2024-10-14', '2024-10-25', 'Approved', 1012),
(1102, 'Annual Leave', '2024-11-11', '2024-11-22', 'Approved', 1013),
(1103, 'Annual Leave', '2024-12-02', '2024-12-13', 'Pending', NULL),
(1104, 'Annual Leave', '2024-12-16', '2024-12-27', 'Rejected', 1015);
GO

SELECT * FROM HR.Absences;

INSERT INTO HR.Reviews (EmployeeID, ReviewerID, ReviewPeriodYear, PerformanceScore, FeedbackComments, ReviewDate)
VALUES
(1000, 1000, 2025, 5, 'Exceeded strategic growth targets and successfully steered corporate expansion.', '2025-12-15'),
(1001, 1000, 2025, 5, 'Outstanding technical leadership across cloud migration and platform scalability.', '2025-12-16'),
(1002, 1000, 2025, 4, 'Strong oversight of enterprise data architecture and governance initiatives.', '2025-12-17'),
(1003, 1000, 2025, 4, 'Successfully implemented progressive UK hybrid work policy and talent strategy.', '2025-12-18'),
(1004, 1000, 2025, 4, 'Maintained tight fiscal management and audit compliance across all cost centers.', '2025-12-19'),
(1005, 1001, 2025, 5, 'Architected world-class platform resilient to multi-region cloud outages.', '2025-12-20'),
(1006, 1001, 2025, 4, 'Proactive defense operations; achieved zero high-severity incidents this fiscal year.', '2025-12-21'),
(1007, 1000, 2025, 4, 'Navigated complex regulatory GDPR updates seamlessly.', '2025-12-22'),
(1008, 1002, 2025, 5, 'Masterful execution of real-time data streaming infrastructure.', '2025-12-10'),
(1009, 1002, 2025, 4, 'Transformed data modeling practices using modern semantic layer patterns.', '2025-12-11'),
(1010, 1001, 2025, 4, 'Delivered high uptime for core monolithic and microservice platforms.', '2025-12-12'),
(1011, 1003, 2025, 3, 'Solid performance in business partner support; focus on employee retention metrics.', '2025-12-13'),
(1012, 1003, 2025, 4, 'Reduced average hiring cycle time by 20% across engineering roles.', '2025-12-14'),
(1013, 1004, 2025, 4, 'Exemplary execution of statutory financial reporting and forecasts.', '2025-12-15'),
(1014, 1004, 2025, 3, 'Accurate month-end pay run calculations; target automated reconciliation next year.', '2025-12-16'),
(1015, 1000, 2025, 5, 'Exceeded sales target quota by 140% in enterprise accounts.', '2025-12-17'),
(1016, 1000, 2025, 4, 'Spearheaded rebranding campaign across all major UK tech events.', '2025-12-18'),
(1017, 1005, 2025, 5, 'Pioneered infrastructure-as-code patterns across the organization.', '2025-12-19'),
(1018, 1006, 2025, 4, 'Demonstrated excellent response times during automated vulnerability scans.', '2025-12-20'),
(1019, 1008, 2025, 4, 'Consistently delivers complex ETL/ELT pipelines with minimal production bugs.', '2025-12-21'),
(1020, 1008, 2025, 4, 'Strong technical mentor for mid-level engineers on vector databases.', '2025-12-22'),
(1021, 1010, 2025, 3, 'Met all product features deadlines; work on expanding unit test coverage.', '2025-12-23'),
(1022, 1010, 2025, 4, 'Great workrefactoring legacy codebases into modern containerized services.', '2025-12-24'),
(1023, 1008, 2025, 4, 'Consistently reliable pipeline development; great focus on data quality.', '2025-12-01'),
(1024, 1008, 2025, 3, 'Good execution overall; needs to streamline communication on system alerts.', '2025-12-01'),
(1025, 1019, 2025, 4, 'High code output and effective adoption of automated testing framework.', '2025-12-02'),
(1026, 1019, 2025, 3, 'Meets performance metrics consistently.', '2025-12-02'),
(1027, 1020, 2025, 4, 'Proactive in monitoring pipeline execution performance.', '2025-12-03'),
(1028, 1020, 2025, 3, 'Satisfactory delivery on core transformation tasks.', '2025-12-03'),
(1029, 1021, 2025, 4, 'Excellent work on real-time stream analytical queries.', '2025-12-04'),
(1030, 1021, 2025, 3, 'Meets expectations on assigned features.', '2025-12-04'),
(1031, 1022, 2025, 4, 'Great contribution to microservices scaling.', '2025-12-05'),
(1032, 1022, 2025, 3, 'Good team player; solid code review participation.', '2025-12-05'),
(1033, 1023, 2025, 4, 'Delivered API Gateway overhaul on schedule.', '2025-12-06'),
(1034, 1023, 2025, 3, 'Meets expectations on core sprint objectives.', '2025-12-06'),
(1035, 1017, 2025, 5, 'Outstanding contributions to Kubernetes automated cluster management.', '2025-12-07'),
(1036, 1017, 2025, 3, 'Provides reliable tier-1 tech support.', '2025-12-07'),
(1037, 1017, 2025, 3, 'Consistently resolves hardware support tickets within SLA.', '2025-12-08'),
(1038, 1018, 2025, 4, 'Effective management of identity provider configuration and security policies.', '2025-12-08'),
(1039, 1018, 2025, 3, 'Reliable execution of daily security operations checks.', '2025-12-09'),
(1040, 1011, 2025, 3, 'Handles onboarding queries efficiently.', '2025-12-09'),
(1041, 1011, 2025, 3, 'Accurate maintenance of HR record data.', '2025-12-10'),
(1042, 1012, 2025, 4, 'Targeted sourcing strategies yielded high-quality candidate pipelines.', '2025-12-10'),
(1043, 1013, 2025, 4, 'Clear budget variance reporting across all operational cost centers.', '2025-12-11'),
(1044, 1013, 2025, 3, 'Thorough reconciliation of internal inter-company ledgers.', '2025-12-11'),
(1045, 1014, 2025, 4, 'Accurate processing of HMRC tax submittals and pension file uploads.', '2025-12-12'),
(1046, 1014, 2025, 3, 'Good attention to detail regarding statutory deductions.', '2025-12-12'),
(1047, 1015, 2025, 4, 'Closed several high-value mid-market enterprise deals.', '2025-12-13'),
(1048, 1015, 2025, 3, 'Solid sales pipeline growth across UK regional markets.', '2025-12-13'),
(1049, 1016, 2025, 4, 'Successful execution of digital marketing campaigns.', '2025-12-14'),
(1050, 1016, 2025, 3, 'Good content creation for product launch announcements.', '2025-12-14'),
(1051, 1019, 2025, 4, 'Showed great ownership during database engine upgrades.', '2025-12-15'),
(1052, 1020, 2025, 4, 'Proactively built data validation routines.', '2025-12-15'),
(1053, 1021, 2025, 4, 'Delivered key components of enterprise data warehouse.', '2025-12-16'),
(1054, 1022, 2025, 3, 'Steady contribution to front-end interface components.', '2025-12-16'),
(1055, 1023, 2025, 3, 'Consistently completes backlog tasks on schedule.', '2025-12-17'),
(1056, 1017, 2025, 3, 'Helpful tech support team member.', '2025-12-17'),
(1057, 1018, 2025, 3, 'Reliable execution of basic SOC analytical tasks.', '2025-12-18'),
(1058, 1025, 2025, 4, 'Fast progress following probation; developing good SQL skills.', '2025-12-18'),
(1059, 1025, 2025, 3, 'Good progress; continue strengthening python automation scripts.', '2025-12-19'),
(1060, 1026, 2025, 4, 'Strong analytical mind; quick to learn complex schemas.', '2025-12-19'),
(1061, 1026, 2025, 3, 'Meets expectations for entry-level data engineer.', '2025-12-20'),
(1062, 1027, 2025, 4, 'Demonstrates great enthusiasm and code cleanlines.', '2025-12-20'),
(1063, 1027, 2025, 3, 'Steady progression through training objectives.', '2025-12-21'),
(1064, 1028, 2025, 3, 'Asks good questions and implements feedback effectively.', '2025-12-21'),
(1065, 1028, 2025, 3, 'Meets all core objectives for junior level.', '2025-12-22'),
(1066, 1008, 2025, 4, 'Solid technical contributions across data team sprints.', '2025-12-22'),
(1067, 1008, 2025, 3, 'Consistently delivers on data modeling assignments.', '2025-12-23'),
(1068, 1008, 2025, 4, 'Active contributor to data quality testing routines.', '2025-12-23'),
(1069, 1008, 2025, 3, 'Solid performance in day-to-day data engineering.', '2025-12-24'),
(1070, 1031, 2025, 4, 'Great work on web service integration.', '2025-12-24'),
(1071, 1032, 2025, 3, 'Meets expectations for software development sprint deliverables.', '2025-12-24'),
(1072, 1033, 2025, 4, 'Effective contributions to cloud deployment scripts.', '2025-12-24'),
(1073, 1034, 2025, 3, 'Good entry-level developer skills.', '2025-12-24'),
(1074, 1017, 2025, 3, 'Good customer service skills on the helpdesk.', '2025-12-24'),
(1075, 1017, 2025, 3, 'Meets all support ticket volume metrics.', '2025-12-24'),
(1076, 1018, 2025, 3, 'Reliable support for security policy enforcement.', '2025-12-24'),
(1077, 1018, 2025, 3, 'Good execution of standard monitoring procedures.', '2025-12-24'),
(1078, 1011, 2025, 3, 'Consistently accurate administrative data entry.', '2025-12-24'),
(1079, 1012, 2025, 4, 'Proactive talent recruitment efforts.', '2025-12-24'),
(1080, 1013, 2025, 4, 'Strong financial variance analysis.', '2025-12-24'),
(1081, 1014, 2025, 3, 'Reliable payroll processing tasks.', '2025-12-24'),
(1082, 1015, 2025, 4, 'Good performance hitting quarterly sales numbers.', '2025-12-24'),
(1083, 1016, 2025, 3, 'Solid support on social media marketing campaigns.', '2025-12-24'),
(1084, 1025, 2025, 3, 'Meets expectations on data loading tasks.', '2025-12-24'),
(1085, 1026, 2025, 3, 'Meets core entry requirements.', '2025-12-24'),
(1086, 1027, 2025, 3, 'Good baseline technical capability.', '2025-12-24'),
(1087, 1028, 2025, 3, 'Meets core expectations.', '2025-12-24'),
(1088, 1031, 2025, 3, 'Good progress on software sprint tasks.', '2025-12-24'),
(1089, 1032, 2025, 3, 'Meets development team standards.', '2025-12-24'),
(1090, 1017, 2025, 2, 'Performance impacted by attendance issues; clear development plan in place.', '2025-12-24'),
(1091, 1018, 2025, 3, 'Satisfactory execution of daily security checks.', '2025-12-24'),
(1092, 1011, 2025, 3, 'Meets core HR administration expectations.', '2025-12-24'),
(1093, 1019, 2022, 3, 'Historical review prior to resignation.', '2022-12-15'),
(1094, 1020, 2022, 3, 'Historical review prior to resignation.', '2022-12-16'),
(1095, 1022, 2022, 3, 'Historical review prior to resignation.', '2022-12-17'),
(1096, 1017, 2023, 3, 'Historical review prior to departure.', '2023-12-18'),
(1097, 1013, 2023, 3, 'Historical review prior to departure.', '2023-12-19'),
(1098, 1021, 2024, 4, 'Exceeded performance goals despite leave period.', '2024-12-20'),
(1099, 1023, 2025, 3, 'Good technical contributions.', '2025-12-21'),
(1100, 1011, 2025, 3, 'Meets expectations.', '2025-12-22'),
(1101, 1012, 2025, 3, 'Solid work across hiring drives.', '2025-12-23'),
(1102, 1013, 2025, 3, 'Satisfactory execution of financial reconciliations.', '2025-12-24'),
(1103, 1014, 2025, 3, 'Accurate data processing work.', '2025-12-24'),
(1104, 1015, 2025, 4, 'Good overall sales lead generation.', '2025-12-24');
GO

SELECT * FROM HR.Reviews;

INSERT INTO HR.Benefits (EmployeeID, PlanName, CoverageType, EmployeeContribution, EmployerContribution, StartDate, EndDate)
VALUES
(1000, 'Standard Life Executive Director Pension', 'Workplace Pension', 875.00, 1750.00, '2014-01-15', NULL),
(1000, 'Aviva Premier Health Care', 'Private Medical', 0.00, 450.00, '2014-01-15', NULL),
(1001, 'Standard Life Executive Director Pension', 'Workplace Pension', 770.83, 1541.67, '2014-03-01', NULL),
(1001, 'Aviva Premier Health Care', 'Private Medical', 0.00, 420.00, '2014-03-01', NULL),
(1002, 'Legal & General Corporate Pension', 'Workplace Pension', 604.17, 725.00, '2015-05-10', NULL),
(1002, 'Bupa Select Executive', 'Private Medical', 50.00, 250.00, '2015-05-10', NULL),
(1003, 'Legal & General Corporate Pension', 'Workplace Pension', 520.83, 625.00, '2015-08-20', NULL),
(1004, 'Legal & General Corporate Pension', 'Workplace Pension', 541.67, 650.00, '2016-01-11', NULL),
(1005, 'Legal & General Corporate Pension', 'Workplace Pension', 458.33, 550.00, '2016-04-18', NULL),
(1006, 'Legal & General Corporate Pension', 'Workplace Pension', 437.50, 525.00, '2016-07-01', NULL),
(1007, 'Legal & General Corporate Pension', 'Workplace Pension', 450.00, 540.00, '2016-11-15', NULL),
(1008, 'Legal & General Staff Pension', 'Workplace Pension', 479.17, 575.00, '2017-02-01', NULL),
(1008, 'Halfords Green Commute Scheme', 'Cycle to Work', 83.33, 0.00, '2023-01-01', '2024-01-01'),
(1009, 'Legal & General Staff Pension', 'Workplace Pension', 383.33, 460.00, '2017-03-15', NULL),
(1010, 'Legal & General Staff Pension', 'Workplace Pension', 366.67, 440.00, '2017-06-01', NULL),
(1011, 'Aviva Workplace Pension', 'Workplace Pension', 225.00, 270.00, '2017-09-10', NULL),
(1012, 'Aviva Workplace Pension', 'Workplace Pension', 258.33, 310.00, '2018-01-15', NULL),
(1013, 'Aviva Workplace Pension', 'Workplace Pension', 300.00, 360.00, '2018-03-20', NULL),
(1014, 'Aviva Workplace Pension', 'Workplace Pension', 183.33, 220.00, '2018-05-12', NULL),
(1015, 'Aviva Workplace Pension', 'Workplace Pension', 325.00, 390.00, '2018-08-01', NULL),
(1016, 'Aviva Workplace Pension', 'Workplace Pension', 266.67, 320.00, '2018-10-15', NULL),
(1017, 'Legal & General Staff Pension', 'Workplace Pension', 395.83, 475.00, '2019-01-10', NULL),
(1018, 'Aviva Workplace Pension', 'Workplace Pension', 241.67, 290.00, '2019-02-28', NULL),
(1019, 'Legal & General Staff Pension', 'Workplace Pension', 358.33, 430.00, '2019-04-15', NULL),
(1020, 'Legal & General Staff Pension', 'Workplace Pension', 350.00, 420.00, '2019-06-01', NULL),
(1021, 'Legal & General Staff Pension', 'Workplace Pension', 316.67, 380.00, '2019-08-19', NULL),
(1022, 'Legal & General Staff Pension', 'Workplace Pension', 308.33, 370.00, '2019-11-01', NULL),
(1023, 'Aviva Workplace Pension', 'Workplace Pension', 337.50, 405.00, '2020-01-15', NULL),
(1024, 'Aviva Workplace Pension', 'Workplace Pension', 329.17, 395.00, '2020-02-01', NULL),
(1025, 'Aviva Workplace Pension', 'Workplace Pension', 258.33, 310.00, '2020-03-10', NULL),
(1026, 'Aviva Workplace Pension', 'Workplace Pension', 245.83, 295.00, '2020-04-15', NULL),
(1027, 'Aviva Workplace Pension', 'Workplace Pension', 266.67, 320.00, '2020-05-20', NULL),
(1028, 'Aviva Workplace Pension', 'Workplace Pension', 241.67, 290.00, '2020-06-01', NULL),
(1029, 'Aviva Workplace Pension', 'Workplace Pension', 254.17, 305.00, '2020-07-15', NULL),
(1030, 'Aviva Workplace Pension', 'Workplace Pension', 237.50, 285.00, '2020-08-01', NULL),
(1031, 'Aviva Workplace Pension', 'Workplace Pension', 241.67, 290.00, '2020-09-10', NULL),
(1032, 'Aviva Workplace Pension', 'Workplace Pension', 225.00, 270.00, '2020-10-01', NULL),
(1033, 'Aviva Workplace Pension', 'Workplace Pension', 233.33, 280.00, '2020-11-15', NULL),
(1034, 'Aviva Workplace Pension', 'Workplace Pension', 216.67, 260.00, '2021-01-05', NULL),
(1035, 'Legal & General Staff Pension', 'Workplace Pension', 366.67, 440.00, '2021-02-01', NULL),
(1036, 'Denplan Corporate Optical & Dental', 'Dental', 15.00, 15.00, '2021-03-15', NULL),
(1037, 'Denplan Corporate Optical & Dental', 'Dental', 15.00, 15.00, '2021-04-20', NULL),
(1038, 'Aviva Workplace Pension', 'Workplace Pension', 216.67, 260.00, '2021-05-10', NULL),
(1039, 'Aviva Workplace Pension', 'Workplace Pension', 204.17, 245.00, '2021-06-01', NULL),
(1040, 'Aviva Workplace Pension', 'Workplace Pension', 129.17, 155.00, '2021-07-15', NULL),
(1041, 'Aviva Workplace Pension', 'Workplace Pension', 120.83, 145.00, '2021-08-01', NULL),
(1042, 'Aviva Workplace Pension', 'Workplace Pension', 225.00, 270.00, '2021-09-10', NULL),
(1043, 'Aviva Workplace Pension', 'Workplace Pension', 216.67, 260.00, '2021-10-15', NULL),
(1044, 'Aviva Workplace Pension', 'Workplace Pension', 200.00, 240.00, '2021-11-20', NULL),
(1045, 'Aviva Workplace Pension', 'Workplace Pension', 170.83, 205.00, '2022-01-10', NULL),
(1046, 'Aviva Workplace Pension', 'Workplace Pension', 162.50, 195.00, '2022-02-01', NULL),
(1047, 'Aviva Workplace Pension', 'Workplace Pension', 283.33, 340.00, '2022-03-15', NULL),
(1048, 'Aviva Workplace Pension', 'Workplace Pension', 258.33, 310.00, '2022-04-01', NULL),
(1049, 'Aviva Workplace Pension', 'Workplace Pension', 229.17, 275.00, '2022-05-10', NULL),
(1050, 'Aviva Workplace Pension', 'Workplace Pension', 212.50, 255.00, '2022-06-15', NULL),
(1051, 'Aviva Workplace Pension', 'Workplace Pension', 233.33, 280.00, '2022-07-20', NULL),
(1052, 'Aviva Workplace Pension', 'Workplace Pension', 225.00, 270.00, '2022-08-10', NULL),
(1053, 'Aviva Workplace Pension', 'Workplace Pension', 229.17, 275.00, '2022-09-01', NULL),
(1054, 'Aviva Workplace Pension', 'Workplace Pension', 212.50, 255.00, '2022-10-15', NULL),
(1055, 'Aviva Workplace Pension', 'Workplace Pension', 204.17, 245.00, '2022-11-01', NULL),
(1056, 'Halfords Green Commute Scheme', 'Cycle to Work', 45.00, 0.00, '2023-01-01', '2024-01-01'),
(1057, 'Aviva Workplace Pension', 'Workplace Pension', 191.67, 230.00, '2023-01-10', NULL),
(1058, 'Aviva Workplace Pension', 'Workplace Pension', 158.33, 190.00, '2023-01-15', NULL),
(1059, 'Aviva Workplace Pension', 'Workplace Pension', 150.00, 180.00, '2023-02-01', NULL),
(1060, 'Aviva Workplace Pension', 'Workplace Pension', 154.17, 185.00, '2023-02-15', NULL),
(1061, 'Aviva Workplace Pension', 'Workplace Pension', 145.83, 175.00, '2023-03-01', NULL),
(1062, 'Aviva Workplace Pension', 'Workplace Pension', 162.50, 195.00, '2023-03-15', NULL),
(1063, 'Aviva Workplace Pension', 'Workplace Pension', 141.67, 170.00, '2023-04-01', NULL),
(1064, 'Aviva Workplace Pension', 'Workplace Pension', 152.08, 182.50, '2023-04-15', NULL),
(1065, 'Aviva Workplace Pension', 'Workplace Pension', 147.92, 177.50, '2023-05-01', NULL),
(1066, 'Aviva Workplace Pension', 'Workplace Pension', 158.33, 190.00, '2023-05-15', NULL),
(1067, 'Aviva Workplace Pension', 'Workplace Pension', 150.00, 180.00, '2023-06-01', NULL),
(1068, 'Aviva Workplace Pension', 'Workplace Pension', 156.25, 187.50, '2023-06-15', NULL),
(1069, 'Aviva Workplace Pension', 'Workplace Pension', 145.83, 175.00, '2023-07-01', NULL),
(1070, 'Aviva Workplace Pension', 'Workplace Pension', 191.67, 230.00, '2023-07-15', NULL),
(1071, 'Aviva Workplace Pension', 'Workplace Pension', 187.50, 225.00, '2023-08-01', NULL),
(1072, 'Aviva Workplace Pension', 'Workplace Pension', 195.83, 235.00, '2023-08-15', NULL),
(1073, 'Aviva Workplace Pension', 'Workplace Pension', 183.33, 220.00, '2023-09-01', NULL),
(1074, 'Unum Life Policy', 'Life Assurance', 0.00, 20.00, '2023-09-15', NULL),
(1075, 'Unum Life Policy', 'Life Assurance', 0.00, 20.00, '2023-10-01', NULL),
(1076, 'Aviva Workplace Pension', 'Workplace Pension', 183.33, 220.00, '2023-10-15', NULL),
(1077, 'Aviva Workplace Pension', 'Workplace Pension', 179.17, 215.00, '2023-11-01', NULL),
(1078, 'Aviva Workplace Pension', 'Workplace Pension', 116.67, 140.00, '2023-11-15', NULL),
(1079, 'Aviva Workplace Pension', 'Workplace Pension', 212.50, 255.00, '2023-12-01', NULL),
(1080, 'Aviva Workplace Pension', 'Workplace Pension', 191.67, 230.00, '2023-12-15', NULL),
(1081, 'Aviva Workplace Pension', 'Workplace Pension', 150.00, 180.00, '2024-01-08', NULL),
(1082, 'Aviva Workplace Pension', 'Workplace Pension', 250.00, 300.00, '2024-01-15', NULL),
(1083, 'Aviva Workplace Pension', 'Workplace Pension', 204.17, 245.00, '2024-02-01', NULL),
(1084, 'Aviva Workplace Pension', 'Workplace Pension', 141.67, 170.00, '2024-02-15', NULL),
(1085, 'Aviva Workplace Pension', 'Workplace Pension', 139.58, 167.50, '2024-03-01', NULL),
(1086, 'Aviva Workplace Pension', 'Workplace Pension', 145.83, 175.00, '2024-03-15', NULL),
(1087, 'Aviva Workplace Pension', 'Workplace Pension', 143.75, 172.50, '2024-04-01', NULL),
(1088, 'Aviva Workplace Pension', 'Workplace Pension', 183.33, 220.00, '2024-04-15', NULL),
(1089, 'Aviva Workplace Pension', 'Workplace Pension', 187.50, 225.00, '2024-05-01', NULL),
(1090, 'Denplan Corporate Optical & Dental', 'Dental', 12.00, 12.00, '2024-05-15', NULL),
(1091, 'Aviva Workplace Pension', 'Workplace Pension', 175.00, 210.00, '2024-06-01', NULL),
(1092, 'Aviva Workplace Pension', 'Workplace Pension', 114.58, 137.50, '2024-06-15', NULL),
(1093, 'Aviva Workplace Pension', 'Workplace Pension', 241.67, 290.00, '2020-01-15', '2023-05-31'),
(1094, 'Aviva Workplace Pension', 'Workplace Pension', 233.33, 280.00, '2020-03-01', '2023-08-15'),
(1095, 'Aviva Workplace Pension', 'Workplace Pension', 216.67, 260.00, '2020-06-10', '2023-11-30'),
(1096, 'Aviva Workplace Pension', 'Workplace Pension', 116.67, 140.00, '2021-01-10', '2024-01-31'),
(1097, 'Aviva Workplace Pension', 'Workplace Pension', 195.83, 235.00, '2021-04-01', '2024-03-31'),
(1098, 'Aviva Workplace Pension', 'Workplace Pension', 237.50, 285.00, '2021-07-15', NULL),
(1099, 'Aviva Workplace Pension', 'Workplace Pension', 220.83, 265.00, '2021-09-01', NULL),
(1100, 'Aviva Workplace Pension', 'Workplace Pension', 118.75, 142.50, '2022-01-15', NULL),
(1101, 'Aviva Workplace Pension', 'Workplace Pension', 216.67, 260.00, '2022-04-01', NULL),
(1102, 'Aviva Workplace Pension', 'Workplace Pension', 204.17, 245.00, '2022-06-15', NULL),
(1103, 'Aviva Workplace Pension', 'Workplace Pension', 166.67, 200.00, '2022-09-01', NULL),
(1104, 'Aviva Workplace Pension', 'Workplace Pension', 266.67, 320.00, '2022-11-15', NULL);
GO

SELECT * FROM HR.Benefits;

INSERT INTO Audit.AuditLog (TableName, ActionType, PrimaryKeyValue, ModifiedBy, ModifiedDate, OldValuesJSON, NewValuesJSON)
VALUES
('HR.Employees', 'INSERT', '1000', 'system_admin', '2014-01-15 09:00:00', NULL, '{"NINO":"AA100000A","CurrentSalary":210000.00}'),
('HR.Employees', 'INSERT', '1001', 'system_admin', '2014-03-01 09:00:00', NULL, '{"NINO":"AB100001B","CurrentSalary":185000.00}'),
('HR.Employees', 'INSERT', '1002', 'system_admin', '2015-05-10 09:00:00', NULL, '{"NINO":"AC100002C","CurrentSalary":145000.00}'),
('HR.Employees', 'INSERT', '1003', 'system_admin', '2015-08-20 09:00:00', NULL, '{"NINO":"AD100003D","CurrentSalary":125000.00}'),
('HR.Employees', 'INSERT', '1004', 'system_admin', '2016-01-11 09:00:00', NULL, '{"NINO":"AE100004E","CurrentSalary":130000.00}'),
('HR.Employees', 'INSERT', '1005', 'system_admin', '2016-04-18 09:00:00', NULL, '{"NINO":"AF100005F","CurrentSalary":110000.00}'),
('HR.Employees', 'INSERT', '1006', 'system_admin', '2016-07-01 09:00:00', NULL, '{"NINO":"AG100006G","CurrentSalary":105000.00}'),
('HR.Employees', 'INSERT', '1007', 'system_admin', '2016-11-15 09:00:00', NULL, '{"NINO":"AH100007H","CurrentSalary":108000.00}'),
('HR.Employees', 'INSERT', '1008', 'system_admin', '2017-02-01 09:00:00', NULL, '{"NINO":"AJ100008J","CurrentSalary":115000.00}'),
('HR.Employees', 'INSERT', '1009', 'system_admin', '2017-03-15 09:00:00', NULL, '{"NINO":"AK100009K","CurrentSalary":92000.00}'),
('HR.Employees', 'INSERT', '1010', 'system_admin', '2017-06-01 09:00:00', NULL, '{"NINO":"AL100010L","CurrentSalary":88000.00}'),
('HR.Employees', 'INSERT', '1011', 'system_admin', '2017-09-10 09:00:00', NULL, '{"NINO":"AM100011M","CurrentSalary":54000.00}'),
('HR.Employees', 'INSERT', '1012', 'system_admin', '2018-01-15 09:00:00', NULL, '{"NINO":"AN100012N","CurrentSalary":62000.00}'),
('HR.Employees', 'INSERT', '1013', 'system_admin', '2018-03-20 09:00:00', NULL, '{"NINO":"AP100013P","CurrentSalary":72000.00}'),
('HR.Employees', 'INSERT', '1014', 'system_admin', '2018-05-12 09:00:00', NULL, '{"NINO":"AR100014R","CurrentSalary":44000.00}'),
('HR.Employees', 'INSERT', '1015', 'system_admin', '2018-08-01 09:00:00', NULL, '{"NINO":"AS100015S","CurrentSalary":78000.00}'),
('HR.Employees', 'INSERT', '1016', 'system_admin', '2018-10-15 09:00:00', NULL, '{"NINO":"AT100016T","CurrentSalary":64000.00}'),
('HR.Employees', 'INSERT', '1017', 'system_admin', '2019-01-10 09:00:00', NULL, '{"NINO":"AU100017U","CurrentSalary":95000.00}'),
('HR.Employees', 'INSERT', '1018', 'system_admin', '2019-02-28 09:00:00', NULL, '{"NINO":"AV100018V","CurrentSalary":58000.00}'),
('HR.Employees', 'INSERT', '1019', 'system_admin', '2019-04-15 09:00:00', NULL, '{"NINO":"AW100019W","CurrentSalary":86000.00}'),
('HR.Employees', 'INSERT', '1020', 'system_admin', '2019-06-01 09:00:00', NULL, '{"NINO":"AX100020X","CurrentSalary":84000.00}'),
('HR.Employees', 'INSERT', '1021', 'system_admin', '2019-08-19 09:00:00', NULL, '{"NINO":"AY100021Y","CurrentSalary":76000.00}'),
('HR.Employees', 'INSERT', '1022', 'system_admin', '2019-11-01 09:00:00', NULL, '{"NINO":"AZ100022Z","CurrentSalary":74000.00}'),
('HR.Employees', 'INSERT', '1023', 'system_admin', '2020-01-15 09:00:00', NULL, '{"NINO":"BA100023A","CurrentSalary":81000.00}'),
('HR.Employees', 'INSERT', '1024', 'system_admin', '2020-02-01 09:00:00', NULL, '{"NINO":"BB100024B","CurrentSalary":79000.00}'),
('HR.Employees', 'UPDATE', '1000', 'system_admin', '2023-01-01 10:00:00', '{"CurrentSalary":195000.00}', '{"CurrentSalary":210000.00}'),
('HR.Employees', 'UPDATE', '1001', 'system_admin', '2023-01-01 10:00:00', '{"CurrentSalary":170000.00}', '{"CurrentSalary":185000.00}'),
('HR.Employees', 'UPDATE', '1002', 'a.pendelton', '2022-04-01 10:00:00', '{"CurrentSalary":132000.00}', '{"CurrentSalary":145000.00}'),
('HR.Employees', 'UPDATE', '1003', 'a.pendelton', '2022-04-01 10:00:00', '{"CurrentSalary":115000.00}', '{"CurrentSalary":125000.00}'),
('HR.Employees', 'UPDATE', '1004', 'a.pendelton', '2023-01-01 10:00:00', '{"CurrentSalary":120000.00}', '{"CurrentSalary":130000.00}'),
('HR.Employees', 'UPDATE', '1005', 'v.sterling', '2023-04-01 10:00:00', '{"CurrentSalary":100000.00}', '{"CurrentSalary":110000.00}'),
('HR.Employees', 'UPDATE', '1006', 'v.sterling', '2023-04-01 10:00:00', '{"CurrentSalary":95000.00}', '{"CurrentSalary":105000.00}'),
('HR.Employees', 'UPDATE', '1007', 'a.pendelton', '2023-04-01 10:00:00', '{"CurrentSalary":98000.00}', '{"CurrentSalary":108000.00}'),
('HR.Employees', 'UPDATE', '1008', 'c.montgomery', '2022-01-01 10:00:00', '{"CurrentSalary":102000.00}', '{"CurrentSalary":115000.00}'),
('HR.Employees', 'UPDATE', '1009', 'c.montgomery', '2022-06-01 10:00:00', '{"CurrentSalary":82000.00}', '{"CurrentSalary":92000.00}'),
('HR.Employees', 'UPDATE', '1010', 'v.sterling', '2022-04-01 10:00:00', '{"CurrentSalary":80000.00}', '{"CurrentSalary":88000.00}'),
('HR.Employees', 'UPDATE', '1011', 'e.rutherford', '2023-04-01 10:00:00', '{"CurrentSalary":48000.00}', '{"CurrentSalary":54000.00}'),
('HR.Employees', 'UPDATE', '1012', 'e.rutherford', '2023-04-01 10:00:00', '{"CurrentSalary":55000.00}', '{"CurrentSalary":62000.00}'),
('HR.Employees', 'UPDATE', '1013', 'g.blackwood', '2022-04-01 10:00:00', '{"CurrentSalary":65000.00}', '{"CurrentSalary":72000.00}'),
('HR.Employees', 'UPDATE', '1014', 'g.blackwood', '2023-04-01 10:00:00', '{"CurrentSalary":40000.00}', '{"CurrentSalary":44000.00}'),
('HR.Employees', 'UPDATE', '1015', 'a.pendelton', '2023-01-01 10:00:00', '{"CurrentSalary":70000.00}', '{"CurrentSalary":78000.00}'),
('HR.Employees', 'UPDATE', '1016', 'a.pendelton', '2023-04-01 10:00:00', '{"CurrentSalary":58000.00}', '{"CurrentSalary":64000.00}'),
('HR.Employees', 'UPDATE', '1017', 'a.vane', '2023-06-01 10:00:00', '{"CurrentSalary":85000.00}', '{"CurrentSalary":95000.00}'),
('HR.Employees', 'UPDATE', '1018', 'f.gallagher', '2023-04-01 10:00:00', '{"CurrentSalary":52000.00}', '{"CurrentSalary":58000.00}'),
('HR.Employees', 'UPDATE', '1019', 'o.harrison', '2023-04-01 10:00:00', '{"CurrentSalary":78000.00}', '{"CurrentSalary":86000.00}'),
('HR.Employees', 'UPDATE', '1020', 'o.harrison', '2023-04-01 10:00:00', '{"CurrentSalary":76000.00}', '{"CurrentSalary":84000.00}'),
('HR.Employees', 'UPDATE', '1021', 'i.wright', '2022-09-01 10:00:00', '{"CurrentSalary":68000.00}', '{"CurrentSalary":76000.00}'),
('HR.Employees', 'UPDATE', '1022', 'i.wright', '2022-09-01 10:00:00', '{"CurrentSalary":66000.00}', '{"CurrentSalary":74000.00}'),
('HR.Employees', 'UPDATE', '1023', 'o.harrison', '2023-04-01 10:00:00', '{"CurrentSalary":72000.00}', '{"CurrentSalary":81000.00}'),
('HR.Employees', 'UPDATE', '1024', 'o.harrison', '2023-04-01 10:00:00', '{"CurrentSalary":70000.00}', '{"CurrentSalary":79000.00}'),
('HR.Employees', 'UPDATE', '1025', 'm.davenport', '2023-04-01 10:00:00', '{"CurrentSalary":54000.00}', '{"CurrentSalary":62000.00}'),
('HR.Employees', 'UPDATE', '1026', 'm.davenport', '2023-04-01 10:00:00', '{"CurrentSalary":52000.00}', '{"CurrentSalary":59000.00}'),
('HR.Employees', 'UPDATE', '1027', 'g.edwards', '2023-04-01 10:00:00', '{"CurrentSalary":56000.00}', '{"CurrentSalary":64000.00}'),
('HR.Employees', 'UPDATE', '1028', 'g.edwards', '2023-04-01 10:00:00', '{"CurrentSalary":51000.00}', '{"CurrentSalary":58000.00}'),
('HR.Employees', 'UPDATE', '1029', 'h.abbott', '2023-04-01 10:00:00', '{"CurrentSalary":53000.00}', '{"CurrentSalary":61000.00}'),
('HR.Employees', 'UPDATE', '1030', 'h.abbott', '2023-04-01 10:00:00', '{"CurrentSalary":50000.00}', '{"CurrentSalary":57000.00}'),
('HR.Employees', 'UPDATE', '1031', 's.turner', '2023-04-01 10:00:00', '{"CurrentSalary":51000.00}', '{"CurrentSalary":58000.00}'),
('HR.Employees', 'UPDATE', '1032', 's.turner', '2023-04-01 10:00:00', '{"CurrentSalary":48000.00}', '{"CurrentSalary":54000.00}'),
('HR.Employees', 'UPDATE', '1033', 'e.fox', '2023-04-01 10:00:00', '{"CurrentSalary":49000.00}', '{"CurrentSalary":56000.00}'),
('HR.Employees', 'UPDATE', '1034', 'e.fox', '2023-04-01 10:00:00', '{"CurrentSalary":46000.00}', '{"CurrentSalary":52000.00}'),
('HR.Employees', 'UPDATE', '1035', 'r.cole', '2023-04-01 10:00:00', '{"CurrentSalary":78000.00}', '{"CurrentSalary":88000.00}'),
('HR.Employees', 'UPDATE', '1036', 'r.cole', '2023-04-01 10:00:00', '{"CurrentSalary":28000.00}', '{"CurrentSalary":32000.00}'),
('HR.Employees', 'UPDATE', '1037', 'r.cole', '2023-04-01 10:00:00', '{"CurrentSalary":26000.00}', '{"CurrentSalary":30000.00}'),
('HR.Employees', 'UPDATE', '1038', 'd.cross', '2023-04-01 10:00:00', '{"CurrentSalary":46000.00}', '{"CurrentSalary":52000.00}'),
('HR.Employees', 'UPDATE', '1039', 'd.cross', '2023-04-01 10:00:00', '{"CurrentSalary":43000.00}', '{"CurrentSalary":49000.00}'),
('HR.Employees', 'UPDATE', '1040', 'j.taylor', '2023-04-01 10:00:00', '{"CurrentSalary":25000.00}', '{"CurrentSalary":29000.00}'),
('HR.Employees', 'UPDATE', '1041', 'j.taylor', '2023-04-01 10:00:00', '{"CurrentSalary":25000.00}', '{"CurrentSalary":29000.00}'),
('HR.Employees', 'UPDATE', '1042', 'l.oconnor', '2023-04-01 10:00:00', '{"CurrentSalary":47000.00}', '{"CurrentSalary":54000.00}'),
('HR.Employees', 'UPDATE', '1043', 'c.webb', '2023-04-01 10:00:00', '{"CurrentSalary":45000.00}', '{"CurrentSalary":52000.00}'),
('HR.Employees', 'UPDATE', '1044', 'c.webb', '2023-04-01 10:00:00', '{"CurrentSalary":42000.00}', '{"CurrentSalary":48000.00}'),
('HR.Employees', 'UPDATE', '1045', 'b.hayes', '2023-04-01 10:00:00', '{"CurrentSalary":36000.00}', '{"CurrentSalary":41000.00}'),
('HR.Employees', 'UPDATE', '1046', 'b.hayes', '2023-04-01 10:00:00', '{"CurrentSalary":34000.00}', '{"CurrentSalary":39000.00}'),
('HR.Employees', 'UPDATE', '1047', 'a.fletcher', '2023-04-01 10:00:00', '{"CurrentSalary":60000.00}', '{"CurrentSalary":68000.00}'),
('HR.Employees', 'UPDATE', '1048', 'a.fletcher', '2023-04-01 10:00:00', '{"CurrentSalary":54000.00}', '{"CurrentSalary":62000.00}'),
('HR.Employees', 'UPDATE', '1049', 's.barker', '2023-04-01 10:00:00', '{"CurrentSalary":48000.00}', '{"CurrentSalary":55000.00}'),
('HR.Employees', 'UPDATE', '1050', 's.barker', '2023-04-01 10:00:00', '{"CurrentSalary":44000.00}', '{"CurrentSalary":51000.00}'),
('HR.Employees', 'UPDATE', '1051', 'm.davenport', '2023-10-01 10:00:00', '{"CurrentSalary":49000.00}', '{"CurrentSalary":56000.00}'),
('HR.Employees', 'UPDATE', '1052', 'g.edwards', '2023-10-01 10:00:00', '{"CurrentSalary":47000.00}', '{"CurrentSalary":54000.00}'),
('HR.Employees', 'UPDATE', '1053', 'h.abbott', '2023-10-01 10:00:00', '{"CurrentSalary":48000.00}', '{"CurrentSalary":55000.00}'),
('HR.Employees', 'UPDATE', '1054', 's.turner', '2023-10-01 10:00:00', '{"CurrentSalary":44000.00}', '{"CurrentSalary":51000.00}'),
('HR.Employees', 'UPDATE', '1055', 'e.fox', '2023-10-01 10:00:00', '{"CurrentSalary":43000.00}', '{"CurrentSalary":49000.00}'),
('HR.Employees', 'UPDATE', '1056', 'r.cole', '2023-10-01 10:00:00', '{"CurrentSalary":25000.00}', '{"CurrentSalary":28000.00}'),
('HR.Employees', 'UPDATE', '1057', 'd.cross', '2024-01-01 10:00:00', '{"CurrentSalary":40000.00}', '{"CurrentSalary":46000.00}'),
('HR.Employees', 'UPDATE', '1093', 'system_admin', '2023-05-31 17:00:00', '{"EmploymentStatus":"Active"}', '{"EmploymentStatus":"Terminated"}'),
('HR.Employees', 'UPDATE', '1094', 'system_admin', '2023-08-15 17:00:00', '{"EmploymentStatus":"Active"}', '{"EmploymentStatus":"Terminated"}'),
('HR.Employees', 'UPDATE', '1095', 'system_admin', '2023-11-30 17:00:00', '{"EmploymentStatus":"Active"}', '{"EmploymentStatus":"Terminated"}'),
('HR.Employees', 'UPDATE', '1096', 'system_admin', '2024-01-31 17:00:00', '{"EmploymentStatus":"Active"}', '{"EmploymentStatus":"Terminated"}'),
('HR.Employees', 'UPDATE', '1097', 'system_admin', '2024-03-31 17:00:00', '{"EmploymentStatus":"Active"}', '{"EmploymentStatus":"Terminated"}');
GO

SELECT * FROM Audit.AuditLog;

USE human_resources_information_system;
GO


-- Schema Inspection

SELECT 
	s.name AS SchemaName,
	t.name AS TableName,
	p.rows AS TotalRows,
	t.create_date AS CreatedDate
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
INNER JOIN sys.partitions AS p
ON t.object_id = p.object_ID AND p.index_id IN (0, 1)
WHERE s.name = 'HR'
ORDER BY t.name
GO

SELECT 
	s.name AS SchemaName,
	t.name AS TableName,
	p.rows AS TotalRows,
	t.create_date AS CreatedDate
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
INNER JOIN sys.partitions AS p
ON t.object_id = p.object_ID AND p.index_id IN (0, 1)
WHERE s.name = 'Audit'
ORDER BY t.name
GO

SELECT 'HR.Departments' AS TableName, COUNT(*) AS RecordCount FROM HR.Departments
UNION ALL SELECT 'HR.Jobs', COUNT(*) FROM HR.Jobs
UNION ALL SELECT 'HR.Employees', COUNT(*) FROM HR.Employees
UNION ALL SELECT 'HR.Salaries', COUNT(*) FROM HR.Salaries
UNION ALL SELECT 'HR.Payrolls', COUNT(*) FROM HR.Payrolls
UNION ALL SELECT 'HR.Payslips', COUNT(*) FROM HR.Payslips
UNION ALL SELECT 'HR.Absences', COUNT(*) FROM HR.Absences
UNION ALL SELECT 'HR.Reviews', COUNT(*) FROM HR.Reviews
UNION ALL SELECT 'HR.Benefits', COUNT(*) FROM HR.Benefits
UNION ALL SELECT 'Audit.AuditLog', COUNT(*) FROM Audit.AuditLog
ORDER BY RecordCount DESC;
