-- Database Creation

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'hospital_information_management_system')
BEGIN
	ALTER DATABASE hospital_information_management_system SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE hospital_information_management_system;
END
GO

CREATE DATABASE hospital_information_management_system;
GO

USE hospital_information_management_system;
GO

CREATE SCHEMA Admin;
GO

CREATE SCHEMA Clinical;
GO

CREATE SCHEMA Audit;
GO

DROP TABLE IF EXISTS Admin.Departments;
CREATE TABLE Admin.Departments(
							DepartmentID INT IDENTITY(100, 1) NOT NULL,
							DepartmentName VARCHAR(100) NOT NULL,
							LocationFloor INT NOT NULL,
							Budget DECIMAL(12, 2) NOT NULL,
							CONSTRAINT PK_Departments PRIMARY KEY (DepartmentID),
							CONSTRAINT UQ_DepartmentName UNIQUE (DepartmentName),
							CONSTRAINT CK_LocationFloor CHECK (LocationFloor BETWEEN 1 AND 15));
GO

SELECT * FROM Admin.Departments;

DROP TABLE IF EXISTS Admin.Staff;
CREATE TABLE Admin.Staff(
						StaffID INT IDENTITY(1000, 1) NOT NULL,
						FirstName VARCHAR(50) NOT NULL,
						LastName VARCHAR(50) NOT NULL,
						Role VARCHAR(50) NOT NULL,
						DepartmentID INT NOT NULL,
						ManagerID INT NULL,
						HireDate DATE NOT NULL,
						Salary DECIMAL(10, 2) NOT NULL,
						IsActive BIT NOT NULL CONSTRAINT DF_Staff_IsActive DEFAULT 1,
						CONSTRAINT PK_Staff PRIMARY KEY (StaffID),
						CONSTRAINT FK_Staff_Departments FOREIGN KEY (DepartmentID) REFERENCES Admin.Departments(DepartmentID),
						CONSTRAINT FK_Staff_Manager FOREIGN KEY (ManagerID) REFERENCES Admin.Staff(StaffID),
						CONSTRAINT CK_Staff_Salary CHECK (Salary > 0));
GO

SELECT * FROM Admin.Staff;

DROP TABLE IF EXISTS Clinical.Patients;
CREATE TABLE Clinical.Patients(
							PatientID INT IDENTITY(5000, 1) NOT NULL,
							FirstName VARCHAR(50) NOT NULL,
							LastName VARCHAR(50) NOT NULL,
							DateOfBirth DATE NOT NULL,
							Gender CHAR(1) NOT NULL,
							BloodType VARCHAR(3) NOT NULL,
							PhoneNumber VARCHAR(15) NOT NULL,
							EmergencyContact VARCHAR(100) NOT NULL,
							CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Patients_CreatedAt DEFAULT SYSDATETIME(),
							CONSTRAINT PK_Patients PRIMARY KEY (PatientID),
							CONSTRAINT CK_Patients_Gender CHECK (Gender IN ('M', 'F', 'O')),
							CONSTRAINT CK_Patients_BloodType CHECK (BloodType IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')));
GO

SELECT * FROM Clinical.Patients;

DROP TABLE IF EXISTS Admin.Rooms;
CREATE TABLE Admin.Rooms(
						RoomID INT IDENTITY(200, 1) NOT NULL,
						RoomNumber VARCHAR(10) NOT NULL,
						DepartmentID INT NOT NULL,
						RoomType VARCHAR(30) NOT NULL,
						DailyRate DECIMAL(8, 2) NOT NULL,
						IsOccupied BIT NOT NULL CONSTRAINT DF_Rooms_IsOccupied DEFAULT 0,
						CONSTRAINT PK_Rooms PRIMARY KEY (RoomID),
						CONSTRAINT UQ_RoomNumber UNIQUE (RoomNumber),
						CONSTRAINT FK_Rooms_Departments FOREIGN KEY (DepartmentID) REFERENCES Admin.Departments(DepartmentID),
						CONSTRAINT CK_Rooms_RoomType CHECK (RoomType IN ('General Ward', 'Semi-Private', 'Private', 'ICU', 'Operating Room')));
GO

SELECT * FROM Admin.Rooms;

DROP TABLE IF EXISTS Clinical.Physicians;
CREATE TABLE Clinical.Physicians(
								PhysicianID INT IDENTITY(3000, 1) NOT NULL,
								StaffID INT NOT NULL,
								Specialty VARCHAR(100) NOT NULL,
								MedicalLicenseNumber VARCHAR(50) NOT NULL,
								ConsultationFee DECIMAL(8, 2) NOT NULL,
								CONSTRAINT PK_Physicians PRIMARY KEY (PhysicianID),
								CONSTRAINT UQ_MedicalLicenseNumber UNIQUE (MedicalLicenseNumber),
								CONSTRAINT FK_Physicians_Staff FOREIGN KEY (StaffID) REFERENCES Admin.Staff(StaffID));
GO

SELECT * FROM Clinical.Physicians;

DROP TABLE IF EXISTS Clinical.Encounters;
CREATE TABLE Clinical.Encounters(
								EncounterID INT IDENTITY(10000, 1) NOT NULL,
								PatientID INT NOT NULL,
								PhysicianID INT NOT NULL,
								RoomID INT NULL,
								EncounterType VARCHAR(20) NOT NULL,
								AdmitDateTime DATETIME2 NOT NULL,
								DischargeDateTime DATETIME2 NULL,
								Status VARCHAR(20) NOT NULL,
								CONSTRAINT PK_Encounters PRIMARY KEY (EncounterID),
								CONSTRAINT FK_Encounters_Patients FOREIGN KEY (PatientID) REFERENCES Clinical.Patients(PatientID),
								CONSTRAINT FK_Encounters_Physicians FOREIGN KEY (PhysicianID) REFERENCES Clinical.Physicians(PhysicianID),
								CONSTRAINT FK_Encounters_Rooms FOREIGN KEY (RoomID) REFERENCES Admin.Rooms(RoomID),
								CONSTRAINT CK_EncounterType CHECK (EncounterType IN ('Inpatient', 'Outpatient', 'Emergency')),
								CONSTRAINT CK_Status CHECK (Status IN ('Admitted', 'Discharged', 'Cancelled', 'In-Progress')),
								CONSTRAINT CK_DischargeDateTime CHECK (DischargeDateTime IS NULL OR DischargeDateTime >= AdmitDateTime));
GO

SELECT * FROM Clinical.Encounters;

DROP TABLE IF EXISTS Clinical.MedicalServices;
CREATE TABLE Clinical.MedicalServices(
									ServiceID INT IDENTITY(400, 1) NOT NULL,
									ServiceName VARCHAR(100) NOT NULL,
									Category VARCHAR(50) NOT NULL,
									StandardCost DECIMAL(8, 2) NOT NULL,
									CONSTRAINT PK_MedicalServices PRIMARY KEY (ServiceID),
									CONSTRAINT UQ_ServiceName UNIQUE (ServiceName));
GO

SELECT * FROM Clinical.MedicalServices;

DROP TABLE IF EXISTS Clinical.EncounterServices;
CREATE TABLE Clinical.EncounterServices(
									EncounterServiceID INT IDENTITY(50000, 1) NOT NULL,
									EncounterID INT NOT NULL,
									ServiceID INT NOT NULL,
									ServiceDateTime DATETIME2 NOT NULL,
									Quantity INT NOT NULL CONSTRAINT DF_EncounterServices_Quantity DEFAULT 1,
									BilledCost DECIMAL(8, 2) NOT NULL
									CONSTRAINT PK_EncounterServices PRIMARY KEY (EncounterServiceID),
									CONSTRAINT FK_EncounterServices_Encounters FOREIGN KEY (EncounterID) REFERENCES Clinical.Encounters(EncounterID),
									CONSTRAINT FK_EncounterServices_MedicalServices FOREIGN KEY (ServiceID) REFERENCES Clinical.MedicalServices(ServiceID),
									CONSTRAINT CK_Quantity CHECK (Quantity > 0));
GO

SELECT * FROM Clinical.EncounterServices;

DROP TABLE IF EXISTS Admin.Billing;
CREATE TABLE Admin.Billing(
						BillID INT IDENTITY(7000, 1) NOT NULL,
						EncounterID INT NOT NULL,
						TotalAmount DECIMAL(10, 2) NOT NULL,
						InsuranceCoverage DECIMAL(10, 2) NOT NULL CONSTRAINT DF_Billing_InsuranceCoverage DEFAULT 0.00,
						PatientAmountDue AS (TotalAmount - InsuranceCoverage) PERSISTED,
						PaymentStatus VARCHAR(20) NOT NULL,
						BillDate DATE NOT NULL,
						CONSTRAINT PK_Billing PRIMARY KEY (BillID),
						CONSTRAINT UQ_Billing_Encounters UNIQUE (EncounterID),
						CONSTRAINT FK_Billing_Encounters FOREIGN KEY (EncounterID) REFERENCES Clinical.Encounters(EncounterID),
						CONSTRAINT CK_PaymentStatus CHECK (PaymentStatus IN ('Pending', 'Partial', 'Paid', 'Written-Off')));
GO

SELECT * FROM Admin.Billing;

DROP TABLE IF EXISTS Clinical.Inventory;
CREATE TABLE Clinical.Inventory(
							ItemID INT IDENTITY(800, 1) NOT NULL,
							ItemName VARCHAR(100) NOT NULL,
							StockQuantity INT NOT NULL,
							ReorderLevel INT NOT NULL,
							UnitPrice DECIMAL(8, 2) NOT NULL,
							CONSTRAINT PK_Inventory PRIMARY KEY (ItemID),
							CONSTRAINT UQ_ItemName UNIQUE (ItemName),
							CONSTRAINT CK_StockQuantity CHECK (StockQuantity >= 0));
GO

SELECT * FROM Clinical.Inventory;

DROP TABLE IF EXISTS Audit.SystemLogs;
CREATE TABLE Audit.SystemLogs(
							LogID INT IDENTITY(1, 1) NOT NULL,
							TableName VARCHAR(50) NOT NULL,
							OperationType VARCHAR(10) NOT NULL,
							ExecutionTime DATETIME2 NOT NULL CONSTRAINT DF_SystemLogs_ExecutionTime DEFAULT SYSDATETIME(),
							ExecutedBy VARCHAR(100) NOT NULL CONSTRAINT DF_SystemLogs_ExecutedBy DEFAULT SUSER_SNAME(),
							Details VARCHAR(MAX) NULL,
							CONSTRAINT PK_SystemLogs PRIMARY KEY (LogID));
GO

SELECT * FROM Audit.SystemLogs;


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
WHERE s.name = 'Admin'
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
WHERE s.name = 'Clinical'
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
WHERE s.name = 'Admin'
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
WHERE s.name = 'Clinical'
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
WHERE s_parent.name = 'Admin'
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
WHERE s_parent.name = 'Clinical'
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
WHERE s.name = 'Admin'
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
WHERE s.name = 'Clinical'
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

SET IDENTITY_INSERT Admin.Departments ON;

INSERT INTO Admin.Departments (DepartmentID, DepartmentName, LocationFloor, Budget)
VALUES 
(100, 'Cardiology', 3, 2500000.00),
(101, 'Neurology', 4, 3100000.00),
(102, 'Orthopedics', 2, 1800000.00),
(103, 'Pediatrics', 5, 1500000.00),
(104, 'Emergency Medicine', 1, 4500000.00),
(105, 'General Surgery', 6, 3800000.00),
(106, 'Oncology', 7, 4200000.00),
(107, 'Radiology', 1, 2900000.00),
(108, 'Intensive Care Unit', 3, 5000000.00),
(109, 'Internal Medicine', 2, 2100000.00),
(110, 'Anesthesiology', 6, 1900000.00),
(111, 'Pharmacy', 1, 1200000.00);

SET IDENTITY_INSERT Admin.Departments OFF;
GO

SELECT * FROM Admin.Departments;

SET IDENTITY_INSERT Admin.Staff ON;

INSERT INTO Admin.Staff (StaffID, FirstName, LastName, Role, DepartmentID, ManagerID, HireDate, Salary, IsActive)
VALUES
(1000, 'Arthur', 'Pendelton', 'Chief Medical Officer', 104, NULL, '2010-01-15', 380000.00, 1),
(1001, 'Eleanor', 'Vance', 'Chief of Surgery', 105, 1000, '2011-03-22', 350000.00, 1),
(1002, 'Marcus', 'Aurelius', 'Head of Cardiology', 100, 1000, '2012-06-01', 310000.00, 1),
(1003, 'Sophia', 'Loren', 'Head of Neurology', 101, 1000, '2013-08-14', 325000.00, 1),
(1004, 'David', 'Sterling', 'Head of Orthopedics', 102, 1000, '2014-02-10', 295000.00, 1),
(1005, 'Clara', 'Barton', 'Head of Pediatrics', 103, 1000, '2015-11-05', 270000.00, 1),
(1006, 'Robert', 'Oppenheimer', 'Head of Oncology', 106, 1000, '2012-04-18', 340000.00, 1),
(1007, 'Marie', 'Curie', 'Head of Radiology', 107, 1000, '2013-09-30', 285000.00, 1),
(1008, 'Gregory', 'Houseman', 'Head of Internal Medicine', 109, 1000, '2011-07-04', 300000.00, 1),
(1009, 'Florence', 'Nightingale', 'Chief Nursing Officer', 108, 1000, '2009-05-12', 210000.00, 1),
(1010, 'James', 'Wilson', 'Attending Oncologist', 106, 1006, '2015-01-10', 250000.00, 1),
(1011, 'Allison', 'Cameron', 'Attending Immunologist', 109, 1008, '2016-03-15', 220000.00, 1),
(1012, 'Robert', 'Chase', 'Attending Surgeon', 105, 1001, '2015-08-20', 260000.00, 1),
(1013, 'Eric', 'Foreman', 'Attending Neurologist', 101, 1003, '2014-12-01', 255000.00, 1),
(1014, 'Christopher', 'Taubman', 'Attending Plastic Surgeon', 105, 1001, '2017-04-11', 240000.00, 1),
(1015, 'Remy', 'Hadley', 'Attending Internist', 109, 1008, '2018-02-19', 215000.00, 1),
(1016, 'Lawrence', 'Kutner', 'Attending Sports Med', 102, 1004, '2018-06-25', 210000.00, 1),
(1017, 'Meredith', 'Greyson', 'Attending Surgeon', 105, 1001, '2012-07-01', 270000.00, 1),
(1018, 'Derek', 'Shepherd', 'Attending Neurosurgeon', 101, 1003, '2011-10-15', 360000.00, 1),
(1019, 'Cristina', 'Yang', 'Attending Cardio Surgeon', 100, 1002, '2013-05-20', 310000.00, 1),
(1020, 'Alexander', 'Karev', 'Attending Pediatrician', 103, 1005, '2014-09-12', 230000.00, 1),
(1021, 'Miranda', 'Bailey', 'Chief Resident Surgeon', 105, 1001, '2010-06-01', 280000.00, 1),
(1022, 'Richard', 'Webber', 'Senior Consultant', 105, 1000, '2005-01-01', 390000.00, 1),
(1023, 'Owen', 'Hunter', 'Attending Trauma Surgeon', 104, 1000, '2015-03-30', 290000.00, 1),
(1024, 'Amelia', 'Shepherd', 'Attending Neurosurgeon', 101, 1003, '2016-11-14', 330000.00, 1),
(1025, 'Jackson', 'Avery', 'Attending Surgeon', 105, 1001, '2015-02-28', 265000.00, 1),
(1026, 'April', 'Kepner', 'Attending ER Physician', 104, 1023, '2015-05-05', 225000.00, 1),
(1027, 'Calliope', 'Torres', 'Attending Ortho Surgeon', 102, 1004, '2013-08-19', 285000.00, 1),
(1028, 'Arizona', 'Robbins', 'Attending Ped Surgeon', 103, 1005, '2014-01-10', 275000.00, 1),
(1029, 'Marcus', 'Sloan', 'Attending Plastic Surgeon', 105, 1001, '2012-09-01', 290000.00, 1),
(1030, 'Alexandra', 'Greyson', 'Surgical Resident', 105, 1021, '2017-06-15', 95000.00, 1),
(1031, 'Josephine', 'Wilson', 'Surgical Resident', 105, 1021, '2018-06-15', 92000.00, 1),
(1032, 'Andrew', 'DeLuca', 'Surgical Resident', 105, 1021, '2019-06-15', 88000.00, 1),
(1033, 'Levi', 'Schmitt', 'Surgical Resident', 105, 1021, '2020-06-15', 82000.00, 1),
(1034, 'Taryn', 'Helm', 'Surgical Resident', 105, 1021, '2020-06-15', 82000.00, 1),
(1035, 'Atticus', 'Lincoln', 'Attending Ortho Surgeon', 102, 1004, '2019-01-10', 260000.00, 1),
(1036, 'Nicolas', 'Kim', 'Attending Ortho Surgeon', 102, 1004, '2019-03-22', 240000.00, 1),
(1037, 'Cormac', 'Hayes', 'Attending Ped Surgeon', 103, 1005, '2020-02-01', 270000.00, 1),
(1038, 'Winston', 'Ndugu', 'Attending Cardio Surgeon', 100, 1002, '2021-01-15', 280000.00, 1),
(1039, 'Kaitlyn', 'Bartley', 'Neuro Researcher', 101, 1003, '2021-08-01', 140000.00, 1),
(1040, 'Margaret', 'Pierce', 'Attending Cardio Surgeon', 100, 1002, '2016-09-01', 305000.00, 1),
(1041, 'Benjamin', 'Warren', 'Anesthesiologist', 110, 1000, '2014-04-01', 260000.00, 1),
(1042, 'Carina', 'DeLuca', 'OBGYN Attending', 109, 1008, '2017-10-10', 235000.00, 1),
(1043, 'John', 'Watson', 'Senior Nurse Supervisor', 108, 1009, '2013-02-14', 115000.00, 1),
(1044, 'Clara', 'Oswald', 'ICU Charge Nurse', 108, 1043, '2015-07-20', 98000.00, 1),
(1045, 'Amy', 'Pond', 'ICU Registered Nurse', 108, 1043, '2016-09-15', 85000.00, 1),
(1046, 'Rory', 'Williams', 'ICU Registered Nurse', 108, 1043, '2016-09-15', 84000.00, 1),
(1047, 'Rosalie', 'Tyler', 'ER Charge Nurse', 104, 1009, '2014-11-01', 99000.00, 1),
(1048, 'Martha', 'Jones', 'ER Registered Nurse', 104, 1047, '2017-01-15', 86000.00, 1),
(1049, 'Donna', 'Noble', 'ER Staff Nurse', 104, 1047, '2018-04-01', 82000.00, 1),
(1050, 'Sarah', 'Jane', 'Pediatric Charge Nurse', 103, 1009, '2012-03-10', 102000.00, 1),
(1051, 'Jack', 'Harkness', 'Trauma Nurse Specialist', 104, 1047, '2013-06-01', 94000.00, 1),
(1052, 'Michael', 'Smith', 'Radiology Technician', 107, 1007, '2016-02-20', 72000.00, 1),
(1053, 'Wilfred', 'Mott', 'Patient Transport Coord', 104, 1000, '2015-10-05', 52000.00, 1),
(1054, 'Sylvia', 'Noble', 'Admin Assistant', 104, 1000, '2017-05-12', 48000.00, 1),
(1055, 'Peter', 'Tyler', 'Supply Chain Manager', 111, 1000, '2011-12-01', 105000.00, 1),
(1056, 'Jacqueline', 'Tyler', 'Pharmacy Assistant', 111, 1055, '2015-08-08', 46000.00, 1),
(1057, 'Harriet', 'Jones', 'Hospital Administrator', 104, 1000, '2008-01-15', 160000.00, 1),
(1058, 'Oscar', 'Peterson', 'Lab Technician Lead', 109, 1008, '2016-04-18', 78000.00, 1),
(1059, 'Katherine', 'Lethbridge', 'Chief Information Officer', 104, 1000, '2014-09-01', 195000.00, 1),
(1060, 'Grace', 'Holloway', 'Cardiology Nurse Lead', 100, 1002, '2015-01-20', 96000.00, 1),
(1061, 'Chang', 'Lee', 'Cardiology Staff Nurse', 100, 1060, '2018-11-11', 81000.00, 1),
(1062, 'Cassandra', 'O''Brien', 'Surgical Nurse Specialist', 105, 1001, '2017-07-07', 91000.00, 1),
(1063, 'Anthony', 'Bourdain', 'Anesthesia Specialist', 110, 1041, '2016-12-01', 130000.00, 1),
(1064, 'Natalie', 'Hame', 'Oncology Staff Nurse', 106, 1006, '2019-02-14', 83000.00, 1),
(1065, 'William', 'Kindness', 'Oncology Nurse Lead', 106, 1006, '2014-05-05', 97000.00, 1),
(1066, 'Patricia', 'Jones', 'Pediatric Staff Nurse', 103, 1050, '2019-08-20', 79000.00, 1),
(1067, 'Leonard', 'Jones', 'Neurology Technician', 101, 1003, '2020-01-15', 68000.00, 1),
(1068, 'Francine', 'Jones', 'Admin Officer', 103, 1005, '2018-03-30', 50000.00, 1),
(1069, 'Clyde', 'Langer', 'Lab Assistant', 109, 1058, '2021-06-01', 45000.00, 1),
(1070, 'Rani', 'Chandra', 'Radiology Specialist', 107, 1007, '2020-09-15', 88000.00, 1),
(1071, 'Lucas', 'Smith', 'IT Database Admin', 104, 1059, '2021-02-10', 95000.00, 1),
(1072, 'Skyler', 'Smith', 'Data Analyst', 104, 1059, '2021-11-01', 85000.00, 1),
(1073, 'Maria', 'Jackson', 'Billing Supervisor', 104, 1057, '2016-01-15', 88000.00, 1),
(1074, 'Gita', 'Jackson', 'Billing Specialist', 104, 1073, '2018-05-20', 58000.00, 1),
(1075, 'Haresh', 'Chandra', 'Financial Auditor', 104, 1057, '2015-10-10', 105000.00, 1),
(1076, 'Kevin', 'Swenson', 'Facilities Manager', 104, 1000, '2013-04-12', 82000.00, 1),
(1077, 'Liam', 'Sontar', 'Security Chief', 104, 1000, '2012-08-08', 90000.00, 1),
(1078, 'Steven', 'Sontar', 'Security Officer', 104, 1077, '2017-09-01', 52000.00, 1),
(1079, 'Stan', 'Sontar', 'Security Officer', 104, 1077, '2019-01-15', 50000.00, 1),
(1080, 'Simon', 'Sontar', 'Orderly Lead', 104, 1000, '2016-11-20', 55000.00, 1),
(1081, 'Valerie', 'Silurian', 'Pathologist Lead', 109, 1008, '2011-03-03', 240000.00, 1),
(1082, 'Jennifer', 'Flint', 'Pathology Assistant', 109, 1081, '2014-06-12', 62000.00, 1),
(1083, 'Dorian', 'Maldovar', 'Inventory Lead', 111, 1055, '2015-12-01', 75000.00, 1),
(1084, 'Kendra', 'Madame', 'Quality Assurance', 104, 1057, '2016-08-15', 110000.00, 1),
(1085, 'Canton', 'Delaware', 'Legal Counsel', 104, 1057, '2013-01-20', 175000.00, 1),
(1086, 'Richard', 'Boyd', 'Facilities Maintenance', 104, 1076, '2020-04-05', 48000.00, 1),
(1087, 'Ashley', 'Meadows', 'Archivist', 104, 1057, '2018-10-10', 56000.00, 1),
(1088, 'William', 'Potts', 'Patient Liaison', 103, 1005, '2019-05-01', 50000.00, 1),
(1089, 'Nathan', 'Valeyard', 'Operations Coordinator', 104, 1000, '2017-02-14', 78000.00, 1),
(1090, 'Daniel', 'Lewis', 'Volunteer Coordinator', 103, 1005, '2021-03-15', 46000.00, 1),
(1091, 'Yasmin', 'Khan', 'Compliance Officer', 104, 1057, '2020-01-10', 82000.00, 1),
(1092, 'Ryan', 'Sinclair', 'BioMed Technician', 107, 1007, '2020-06-01', 65000.00, 1),
(1093, 'Graham', 'O''Brien', 'Facilities Driver', 104, 1076, '2019-09-12', 49000.00, 1),
(1094, 'Grace', 'O''Connor', 'Registered Nurse', 102, 1004, '2018-01-20', 84000.00, 0), 
(1095, 'Jericho', 'Nevin', 'Research Assistant', 106, 1006, '2021-04-18', 58000.00, 1),
(1096, 'Victor', 'Koren', 'Security Specialist', 104, 1077, '2021-10-10', 68000.00, 1),
(1097, 'Bella', 'Koren', 'Patient Advocate', 103, 1005, '2021-10-10', 54000.00, 1),
(1098, 'Samuel', 'Ravager', 'IT Security Specialist', 104, 1059, '2022-01-15', 105000.00, 0), 
(1099, 'Azure', 'D''Angelo', 'Systems Analyst', 104, 1059, '2022-01-15', 90000.00, 1);

SET IDENTITY_INSERT Admin.Staff OFF;
GO

SELECT * FROM Admin.Staff;

SET IDENTITY_INSERT Clinical.Patients ON;

INSERT INTO Clinical.Patients (PatientID, FirstName, LastName, DateOfBirth, Gender, BloodType, PhoneNumber, EmergencyContact, CreatedAt)
VALUES
(5000, 'Liam', 'Smith', '1985-03-12', 'M', 'O+', '555-0101', 'Sarah Smith (Spouse) - 555-0102', '2023-01-10 08:30:00'),
(5001, 'Olivia', 'Johnson', '1992-07-24', 'F', 'A+', '555-0103', 'Mark Johnson (Father) - 555-0104', '2023-01-12 09:15:00'),
(5002, 'Noah', 'Williams', '1978-11-05', 'M', 'B+', '555-0105', 'Emma Williams (Spouse) - 555-0106', '2023-01-15 11:00:00'),
(5003, 'Emma', 'Brown', '2001-04-18', 'F', 'AB+', '555-0107', 'David Brown (Father) - 555-0108', '2023-01-18 14:20:00'),
(5004, 'Oliver', 'Jones', '1965-09-30', 'M', 'O-', '555-0109', 'Martha Jones (Spouse) - 555-0110', '2023-01-20 10:45:00'),
(5005, 'Ava', 'Garcia', '1989-12-14', 'F', 'A-', '555-0111', 'Carlos Garcia (Brother) - 555-0112', '2023-01-22 16:00:00'),
(5006, 'Elijah', 'Miller', '1954-06-22', 'M', 'B-', '555-0113', 'Susan Miller (Daughter) - 555-0114', '2023-01-25 09:30:00'),
(5007, 'Sophia', 'Davis', '1995-01-08', 'F', 'O+', '555-0115', 'James Davis (Father) - 555-0116', '2023-01-28 13:10:00'),
(5008, 'James', 'Rodriguez', '1982-08-17', 'M', 'AB-', '555-0117', 'Maria Rodriguez (Spouse) - 555-0118', '2023-02-01 08:00:00'),
(5009, 'Isabella', 'Martinez', '2010-05-03', 'F', 'A+', '555-0119', 'Elena Martinez (Mother) - 555-0120', '2023-02-03 15:40:00'),
(5010, 'Benjamin', 'Hernandez', '1973-10-29', 'M', 'O+', '555-0121', 'Ana Hernandez (Spouse) - 555-0122', '2023-02-05 11:25:00'),
(5011, 'Mia', 'Lopez', '1988-02-14', 'F', 'B+', '555-0123', 'Jose Lopez (Husband) - 555-0124', '2023-02-08 10:00:00'),
(5012, 'Lucas', 'Gonzalez', '1998-04-01', 'M', 'O+', '555-0125', 'Sofia Gonzalez (Sister) - 555-0126', '2023-02-10 12:30:00'),
(5013, 'Charlotte', 'Wilson', '1961-07-19', 'F', 'A-', '555-0127', 'Robert Wilson (Son) - 555-0128', '2023-02-12 14:15:00'),
(5014, 'Alexander', 'Anderson', '1990-11-23', 'M', 'AB+', '555-0129', 'Rachel Anderson (Spouse) - 555-0130', '2023-02-15 09:05:00'),
(5015, 'Amelia', 'Thomas', '1983-05-11', 'F', 'O-', '555-0131', 'Paul Thomas (Husband) - 555-0132', '2023-02-18 16:50:00'),
(5016, 'Ethan', 'Taylor', '1970-08-04', 'M', 'A+', '555-0133', 'Laura Taylor (Spouse) - 555-0134', '2023-02-20 08:20:00'),
(5017, 'Harper', 'Moore', '2005-12-09', 'F', 'B+', '555-0135', 'Karen Moore (Mother) - 555-0136', '2023-02-22 13:45:00'),
(5018, 'Henry', 'Jackson', '1948-03-31', 'M', 'O+', '555-0137', 'William Jackson (Son) - 555-0138', '2023-02-25 10:10:00'),
(5019, 'Evelyn', 'Martin', '1994-09-15', 'F', 'A+', '555-0139', 'Daniel Martin (Brother) - 555-0140', '2023-02-28 15:00:00'),
(5020, 'Daniel', 'Lee', '1981-01-20', 'M', 'AB-', '555-0141', 'Jennifer Lee (Spouse) - 555-0142', '2023-03-02 11:30:00'),
(5021, 'Abigail', 'Perez', '1968-06-14', 'F', 'O+', '555-0143', 'Miguel Perez (Husband) - 555-0144', '2023-03-05 09:40:00'),
(5022, 'Michael', 'Thompson', '1987-10-08', 'M', 'B-', '555-0145', 'Jessica Thompson (Spouse) - 555-0146', '2023-03-08 14:05:00'),
(5023, 'Emily', 'White', '1999-04-25', 'F', 'A-', '555-0147', 'Christopher White (Father) - 555-0148', '2023-03-10 10:15:00'),
(5024, 'Mason', 'Harris', '1959-12-03', 'M', 'O+', '555-0149', 'Patricia Harris (Spouse) - 555-0150', '2023-03-12 16:30:00'),
(5025, 'Elizabeth', 'Sanchez', '1991-08-18', 'F', 'A+', '555-0151', 'Juan Sanchez (Husband) - 555-0152', '2023-03-15 08:45:00'),
(5026, 'Sebastian', 'Clark', '2008-02-28', 'M', 'B+', '555-0153', 'Nancy Clark (Mother) - 555-0154', '2023-03-18 12:00:00'),
(5027, 'Sofia', 'Ramirez', '1986-11-12', 'F', 'O-', '555-0155', 'Diego Ramirez (Brother) - 555-0156', '2023-03-20 15:10:00'),
(5028, 'Logan', 'Lewis', '1975-07-07', 'M', 'AB+', '555-0157', 'Amanda Lewis (Spouse) - 555-0158', '2023-03-22 09:25:00'),
(5029, 'Avery', 'Robinson', '2003-05-19', 'F', 'A+', '555-0159', 'Brian Robinson (Father) - 555-0160', '2023-03-25 11:50:00'),
(5030, 'Jackson', 'Walker', '1963-09-02', 'M', 'O+', '555-0161', 'Donna Walker (Spouse) - 555-0162', '2023-03-28 14:35:00'),
(5031, 'Ella', 'Young', '1996-03-14', 'F', 'B-', '555-0163', 'Matthew Young (Brother) - 555-0164', '2023-03-30 10:00:00'),
(5032, 'Jacob', 'Allen', '1984-12-21', 'M', 'A-', '555-0165', 'Megan Allen (Spouse) - 555-0166', '2023-04-02 08:15:00'),
(5033, 'Scarlett', 'King', '1979-06-05', 'F', 'O+', '555-0167', 'Andrew King (Husband) - 555-0168', '2023-04-05 13:20:00'),
(5034, 'Grayson', 'Wright', '1993-10-16', 'M', 'AB-', '555-0169', 'Hannah Wright (Sister) - 555-0170', '2023-04-08 09:50:00'),
(5035, 'Grace', 'Scott', '1952-01-11', 'F', 'B+', '555-0171', 'Edward Scott (Son) - 555-0172', '2023-04-10 16:05:00'),
(5036, 'Jack', 'Torres', '1988-08-29', 'M', 'O-', '555-0173', 'Lisa Torres (Spouse) - 555-0174', '2023-04-12 11:15:00'),
(5037, 'Chloe', 'Nguyen', '2000-04-03', 'F', 'A+', '555-0175', 'Kevin Nguyen (Father) - 555-0176', '2023-04-15 14:40:00'),
(5038, 'Julian', 'Hill', '1972-11-27', 'M', 'O+', '555-0177', 'Rachel Hill (Spouse) - 555-0178', '2023-04-18 08:50:00'),
(5039, 'Victoria', 'Flores', '1997-02-15', 'F', 'AB+', '555-0179', 'Gabriel Flores (Brother) - 555-0180', '2023-04-20 12:10:00'),
(5040, 'Levi', 'Green', '1966-07-08', 'M', 'B+', '555-0181', 'Sandra Green (Spouse) - 555-0182', '2023-04-22 15:30:00'),
(5041, 'Riley', 'Adams', '2004-09-21', 'O', 'A-', '555-0183', 'Thomas Adams (Father) - 555-0184', '2023-04-25 10:25:00'),
(5042, 'Dennis', 'O''Connor', '1980-05-17', 'M', 'O+', '555-0185', 'Siobhan O''Connor (Spouse) - 555-0186', '2023-04-28 09:00:00'),
(5043, 'Nora', 'Baker', '1991-12-30', 'F', 'B-', '555-0187', 'Jason Baker (Husband) - 555-0188', '2023-05-01 13:15:00'),
(5044, 'Patrick', 'O''Brien', '1969-03-04', 'M', 'A+', '555-0189', 'Kathleen O''Brien (Spouse) - 555-0190', '2023-05-03 11:40:00'),
(5045, 'Lily', 'Gonzalez', '2012-08-12', 'F', 'O-', '555-0191', 'Maria Gonzalez (Mother) - 555-0192', '2023-05-05 16:20:00'),
(5046, 'Wyatt', 'Nelson', '1987-01-25', 'M', 'AB+', '555-0193', 'Heather Nelson (Spouse) - 555-0194', '2023-05-08 08:30:00'),
(5047, 'Zoey', 'Carter', '1994-06-19', 'F', 'A+', '555-0195', 'Brandon Carter (Brother) - 555-0196', '2023-05-10 14:05:00'),
(5048, 'Carter', 'Mitchell', '1957-10-14', 'M', 'B+', '555-0197', 'Carol Mitchell (Spouse) - 555-0198', '2023-05-12 10:50:00'),
(5049, 'Penelope', 'Perez', '2002-02-07', 'F', 'O+', '555-0199', 'Luis Perez (Father) - 555-0200', '2023-05-15 12:35:00'),
(5050, 'Luke', 'Roberts', '1983-11-03', 'M', 'A-', '555-0201', 'Amy Roberts (Spouse) - 555-0202', '2023-05-18 09:10:00'),
(5051, 'Layla', 'Turner', '1990-07-28', 'F', 'AB-', '555-0203', 'Justin Turner (Husband) - 555-0204', '2023-05-20 15:00:00'),
(5052, 'Dylan', 'Phillips', '1976-04-16', 'M', 'O+', '555-0205', 'Kelly Phillips (Spouse) - 555-0206', '2023-05-22 11:20:00'),
(5053, 'Lillian', 'Campbell', '1962-09-09', 'F', 'B+', '555-0207', 'George Campbell (Husband) - 555-0208', '2023-05-25 14:45:00'),
(5054, 'Gabriel', 'Parker', '1998-01-30', 'M', 'A+', '555-0209', 'Samantha Parker (Sister) - 555-0210', '2023-05-28 08:05:00'),
(5055, 'Addison', 'Evans', '1986-05-22', 'F', 'O-', '555-0211', 'Timothy Evans (Husband) - 555-0212', '2023-05-30 13:30:00'),
(5056, 'Isaac', 'Edwards', '1950-12-18', 'M', 'B-', '555-0213', 'Helen Edwards (Spouse) - 555-0214', '2023-06-02 10:15:00'),
(5057, 'Aubrey', 'Collins', '2006-08-04', 'F', 'A+', '555-0215', 'Mark Collins (Father) - 555-0216', '2023-06-05 16:10:00'),
(5058, 'Jayden', 'Stewart', '1992-03-27', 'M', 'AB+', '555-0217', 'Nicole Stewart (Spouse) - 555-0218', '2023-06-08 09:40:00'),
(5059, 'Ellie', 'Sanchez', '1981-10-11', 'F', 'O+', '555-0219', 'Ricardo Sanchez (Husband) - 555-0220', '2023-06-10 12:00:00'),
(5060, 'Anthony', 'Morris', '1974-06-01', 'M', 'A-', '555-0221', 'Christina Morris (Spouse) - 555-0222', '2023-06-12 15:25:00'),
(5061, 'Stella', 'Rogers', '1995-11-20', 'F', 'B+', '555-0223', 'Bradley Rogers (Brother) - 555-0224', '2023-06-15 08:50:00'),
(5062, 'Jaxon', 'Reed', '2011-01-14', 'M', 'O+', '555-0225', 'Valerie Reed (Mother) - 555-0226', '2023-06-18 11:05:00'),
(5063, 'Natalie', 'Cook', '1967-07-03', 'F', 'AB-', '555-0227', 'Arthur Cook (Husband) - 555-0228', '2023-06-20 14:15:00'),
(5064, 'Lincoln', 'Morgan', '1989-04-09', 'M', 'A+', '555-0229', 'Vanessa Morgan (Spouse) - 555-0230', '2023-06-22 10:30:00'),
(5065, 'Zoe', 'Bell', '2003-09-17', 'F', 'O-', '555-0231', 'Gregory Bell (Father) - 555-0232', '2023-06-25 13:50:00'),
(5066, 'Joshua', 'Murphy', '1977-02-23', 'M', 'B+', '555-0233', 'Eileen Murphy (Spouse) - 555-0234', '2023-06-28 09:15:00'),
(5067, 'Leah', 'Bailey', '1993-05-06', 'F', 'A-', '555-0235', 'Sean Bailey (Brother) - 555-0236', '2023-07-01 16:00:00'),
(5068, 'Christopher', 'Rivera', '1985-08-31', 'M', 'O+', '555-0237', 'Carmen Rivera (Spouse) - 555-0238', '2023-07-03 11:45:00'),
(5069, 'Hazel', 'Cooper', '1955-12-12', 'F', 'AB+', '555-0239', 'Donald Cooper (Husband) - 555-0240', '2023-07-05 08:25:00'),
(5070, 'Andrew', 'Richardson', '1998-10-24', 'M', 'B-', '555-0241', 'Laura Richardson (Mother) - 555-0242', '2023-07-08 14:30:00'),
(5071, 'Violet', 'Cox', '1982-03-07', 'F', 'A+', '555-0243', 'Stephen Cox (Husband) - 555-0244', '2023-07-10 10:00:00'),
(5072, 'Theodore', 'Howard', '1971-09-18', 'M', 'O-', '555-0245', 'Diane Howard (Spouse) - 555-0246', '2023-07-12 15:15:00'),
(5073, 'Aurora', 'Ward', '2007-06-30', 'F', 'B+', '555-0247', 'Jeffrey Ward (Father) - 555-0248', '2023-07-15 09:35:00'),
(5074, 'Caleb', 'Torres', '1988-01-05', 'M', 'O+', '555-0249', 'Monica Torres (Spouse) - 555-0250', '2023-07-18 12:50:00'),
(5075, 'Savannah', 'Peterson', '1990-11-15', 'F', 'A+', '555-0251', 'Eric Peterson (Husband) - 555-0252', '2023-07-20 08:40:00'),
(5076, 'Ryan', 'Gray', '1964-04-28', 'M', 'AB-', '555-0253', 'Janet Gray (Spouse) - 555-0254', '2023-07-22 14:10:00'),
(5077, 'Brooklyn', 'Ramirez', '2001-07-13', 'F', 'O+', '555-0255', 'Pedro Ramirez (Father) - 555-0256', '2023-07-25 10:45:00'),
(5078, 'Asher', 'James', '1996-02-02', 'M', 'B+', '555-0257', 'Taylor James (Sister) - 555-0258', '2023-07-28 16:00:00'),
(5079, 'Bella', 'Watson', '1983-09-26', 'F', 'A-', '555-0259', 'Nathan Watson (Husband) - 555-0260', '2023-07-30 11:25:00'),
(5080, 'Nathan', 'Brooks', '1979-12-08', 'M', 'O-', '555-0261', 'Christine Brooks (Spouse) - 555-0262', '2023-08-02 09:10:00'),
(5081, 'Claire', 'Kelly', '1992-05-14', 'F', 'AB+', '555-0263', 'Patrick Kelly (Brother) - 555-0264', '2023-08-05 13:40:00'),
(5082, 'Leo', 'Sanders', '1958-08-21', 'M', 'B-', '555-0265', 'Barbara Sanders (Spouse) - 555-0266', '2023-08-08 15:05:00'),
(5083, 'Skylar', 'Price', '2005-03-09', 'O', 'A+', '555-0267', 'Wayne Price (Father) - 555-0268', '2023-08-10 10:30:00'),
(5084, 'Thomas', 'Bennett', '1986-10-02', 'M', 'O+', '555-0269', 'Angela Bennett (Spouse) - 555-0270', '2023-08-12 08:15:00'),
(5085, 'Lucy', 'Wood', '1997-06-23', 'F', 'A-', '555-0271', 'Trevor Wood (Brother) - 555-0272', '2023-08-15 12:20:00'),
(5086, 'Isaiah', 'Barnes', '1973-01-17', 'M', 'B+', '555-0273', 'Denise Barnes (Spouse) - 555-0274', '2023-08-18 14:50:00'),
(5087, 'Paisley', 'Ross', '1989-07-31', 'F', 'O-', '555-0275', 'Marcus Ross (Husband) - 555-0276', '2023-08-20 09:05:00'),
(5088, 'Charles', 'Henderson', '1946-04-12', 'M', 'A+', '555-0277', 'Margaret Henderson (Spouse) - 555-0278', '2023-08-22 11:35:00'),
(5089, 'Everly', 'Coleman', '2009-10-28', 'F', 'AB-', '555-0279', 'Scott Coleman (Father) - 555-0280', '2023-08-25 16:15:00'),
(5090, 'Josiah', 'Jenkins', '1991-02-04', 'M', 'O+', '555-0281', 'Amber Jenkins (Spouse) - 555-0282', '2023-08-28 08:45:00'),
(5091, 'Anna', 'Perry', '1980-09-19', 'F', 'B+', '555-0283', 'Russell Perry (Husband) - 555-0284', '2023-08-30 13:00:00'),
(5092, 'Hudson', 'Powell', '1995-12-07', 'M', 'A+', '555-0285', 'Victoria Powell (Sister) - 555-0286', '2023-09-02 10:20:00'),
(5093, 'Caroline', 'Long', '1960-05-25', 'F', 'O-', '555-0287', 'Philip Long (Husband) - 555-0288', '2023-09-05 15:40:00'),
(5094, 'Christian', 'Patterson', '1987-08-08', 'M', 'AB+', '555-0289', 'Julie Patterson (Spouse) - 555-0290', '2023-09-08 09:10:00'),
(5095, 'Genesis', 'Hughes', '2002-11-14', 'F', 'B-', '555-0291', 'Carl Hughes (Father) - 555-0292', '2023-09-10 12:45:00'),
(5096, 'Hunter', 'Flores', '1978-03-29', 'M', 'A-', '555-0293', 'Lori Flores (Spouse) - 555-0294', '2023-09-12 14:10:00'),
(5097, 'Aaliyah', 'Washington', '1993-06-02', 'F', 'O+', '555-0295', 'Derek Washington (Brother) - 555-0296', '2023-09-15 08:30:00'),
(5098, 'Connor', 'Butler', '1981-10-21', 'M', 'B+', '555-0297', 'Staci Butler (Spouse) - 555-0298', '2023-09-18 11:55:00'),
(5099, 'Kennedy', 'Simmons', '1998-07-05', 'F', 'A+', '555-0299', 'Todd Simmons (Father) - 555-0300', '2023-09-20 16:30:00');

SET IDENTITY_INSERT Clinical.Patients OFF;
GO

SELECT * FROM Clinical.Patients;

SET IDENTITY_INSERT Admin.Rooms ON;

INSERT INTO Admin.Rooms (RoomID, RoomNumber, DepartmentID, RoomType, DailyRate, IsOccupied)
VALUES
(200, '101-GW', 104, 'General Ward', 250.00, 1),
(201, '102-GW', 104, 'General Ward', 250.00, 0),
(202, '103-GW', 104, 'General Ward', 250.00, 1),
(203, '104-GW', 104, 'General Ward', 250.00, 0),
(204, '105-RAD', 107, 'General Ward', 300.00, 0),
(205, '106-RAD', 107, 'General Ward', 300.00, 0),
(206, '107-PHM', 111, 'General Ward', 200.00, 0),
(207, '201-GW', 102, 'General Ward', 280.00, 1),
(208, '202-GW', 102, 'General Ward', 280.00, 1),
(209, '203-SP', 102, 'Semi-Private', 450.00, 0),
(210, '204-SP', 102, 'Semi-Private', 450.00, 1),
(211, '205-PR', 102, 'Private', 750.00, 0),
(212, '206-PR', 102, 'Private', 750.00, 1),
(213, '207-GW', 109, 'General Ward', 300.00, 1),
(214, '208-GW', 109, 'General Ward', 300.00, 0),
(215, '209-SP', 109, 'Semi-Private', 500.00, 1),
(216, '210-PR', 109, 'Private', 800.00, 1),
(217, '301-ICU', 108, 'ICU', 2200.00, 1),
(218, '302-ICU', 108, 'ICU', 2200.00, 1),
(219, '303-ICU', 108, 'ICU', 2200.00, 1),
(220, '304-ICU', 108, 'ICU', 2200.00, 0),
(221, '305-ICU', 108, 'ICU', 2200.00, 1),
(222, '306-ICU', 108, 'ICU', 2200.00, 0),
(223, '307-CAR', 100, 'Semi-Private', 600.00, 1),
(224, '308-CAR', 100, 'Semi-Private', 600.00, 0),
(225, '309-CAR', 100, 'Private', 950.00, 1),
(226, '310-CAR', 100, 'Private', 950.00, 1),
(227, '401-NEU', 101, 'General Ward', 320.00, 0),
(228, '402-NEU', 101, 'Semi-Private', 550.00, 1),
(229, '403-NEU', 101, 'Private', 900.00, 0),
(230, '404-NEU', 101, 'Private', 900.00, 1),
(231, '405-NEU', 101, 'ICU', 2500.00, 1),
(232, '501-PED', 103, 'General Ward', 260.00, 0),
(233, '502-PED', 103, 'General Ward', 260.00, 1),
(234, '503-PED', 103, 'Semi-Private', 420.00, 0),
(235, '504-PED', 103, 'Semi-Private', 420.00, 1),
(236, '505-PED', 103, 'Private', 700.00, 0),
(237, '506-PED', 103, 'Private', 700.00, 1),
(238, '601-OR', 105, 'Operating Room', 3500.00, 1),
(239, '602-OR', 105, 'Operating Room', 3500.00, 0),
(240, '603-OR', 105, 'Operating Room', 3500.00, 1),
(241, '604-OR', 105, 'Operating Room', 3500.00, 0),
(242, '605-SUR', 105, 'Semi-Private', 520.00, 1),
(243, '606-SUR', 105, 'Private', 850.00, 0),
(244, '607-SUR', 105, 'Private', 850.00, 1),
(245, '701-ONC', 106, 'General Ward', 350.00, 1),
(246, '702-ONC', 106, 'Semi-Private', 580.00, 0),
(247, '703-ONC', 106, 'Semi-Private', 580.00, 1),
(248, '704-ONC', 106, 'Private', 920.00, 1),
(249, '705-ONC', 106, 'Private', 920.00, 0),
(250, '108-GW', 104, 'General Ward', 250.00, 0),
(251, '109-GW', 104, 'General Ward', 250.00, 1),
(252, '110-GW', 104, 'General Ward', 250.00, 0),
(253, '211-GW', 102, 'General Ward', 280.00, 0),
(254, '212-SP', 102, 'Semi-Private', 450.00, 1),
(255, '213-PR', 102, 'Private', 750.00, 0),
(256, '214-GW', 109, 'General Ward', 300.00, 1),
(257, '215-SP', 109, 'Semi-Private', 500.00, 0),
(258, '216-PR', 109, 'Private', 800.00, 0),
(259, '311-ICU', 108, 'ICU', 2200.00, 1),
(260, '312-ICU', 108, 'ICU', 2200.00, 1),
(261, '313-CAR', 100, 'Semi-Private', 600.00, 0),
(262, '314-CAR', 100, 'Private', 950.00, 1),
(263, '406-NEU', 101, 'Semi-Private', 550.00, 0),
(264, '407-NEU', 101, 'Private', 900.00, 1),
(265, '507-PED', 103, 'General Ward', 260.00, 0),
(266, '508-PED', 103, 'Semi-Private', 420.00, 1),
(267, '509-PED', 103, 'Private', 700.00, 0),
(268, '608-OR', 105, 'Operating Room', 3500.00, 0),
(269, '609-SUR', 105, 'Private', 850.00, 1),
(270, '706-ONC', 106, 'Semi-Private', 580.00, 1),
(271, '707-ONC', 106, 'Private', 920.00, 0),
(272, '111-GW', 104, 'General Ward', 250.00, 0),
(273, '112-GW', 104, 'General Ward', 250.00, 1),
(274, '217-SP', 102, 'Semi-Private', 450.00, 0),
(275, '218-PR', 102, 'Private', 750.00, 1),
(276, '219-GW', 109, 'General Ward', 300.00, 0),
(277, '220-PR', 109, 'Private', 800.00, 1),
(278, '315-ICU', 108, 'ICU', 2200.00, 0),
(279, '316-ICU', 108, 'ICU', 2200.00, 1),
(280, '317-CAR', 100, 'Private', 950.00, 0),
(281, '408-NEU', 101, 'Private', 900.00, 0),
(282, '510-PED', 103, 'Semi-Private', 420.00, 0),
(283, '610-OR', 105, 'Operating Room', 3500.00, 1),
(284, '708-ONC', 106, 'Private', 920.00, 1),
(285, '113-GW', 104, 'General Ward', 250.00, 0),
(286, '221-PR', 102, 'Private', 750.00, 0),
(287, '222-SP', 109, 'Semi-Private', 500.00, 1),
(288, '318-ICU', 108, 'ICU', 2200.00, 1),
(289, '319-CAR', 100, 'Semi-Private', 600.00, 0),
(290, '409-NEU', 101, 'Semi-Private', 550.00, 1),
(291, '511-PED', 103, 'Private', 700.00, 0),
(292, '611-SUR', 105, 'Semi-Private', 520.00, 0),
(293, '709-ONC', 106, 'General Ward', 350.00, 0),
(294, '114-GW', 104, 'General Ward', 250.00, 1),
(295, '223-PR', 102, 'Private', 750.00, 1),
(296, '320-ICU', 108, 'ICU', 2200.00, 0),
(297, '410-NEU', 101, 'ICU', 2500.00, 0),
(298, '612-OR', 105, 'Operating Room', 3500.00, 0),
(299, '710-ONC', 106, 'Private', 920.00, 0);

SET IDENTITY_INSERT Admin.Rooms OFF;
GO

SELECT * FROM Admin.Rooms;

SET IDENTITY_INSERT Clinical.Physicians ON;

INSERT INTO Clinical.Physicians (PhysicianID, StaffID, Specialty, MedicalLicenseNumber, ConsultationFee)
VALUES
(3000, 1000, 'Emergency Medicine', 'MD-LIC-10001', 300.00),
(3001, 1001, 'General Surgery', 'MD-LIC-10002', 350.00),
(3002, 1002, 'Cardiology', 'MD-LIC-10003', 320.00),
(3003, 1003, 'Neurology', 'MD-LIC-10004', 330.00),
(3004, 1004, 'Orthopedic Surgery', 'MD-LIC-10005', 280.00),
(3005, 1005, 'Pediatrics', 'MD-LIC-10006', 220.00),
(3006, 1006, 'Oncology', 'MD-LIC-10007', 340.00),
(3007, 1007, 'Radiology', 'MD-LIC-10008', 260.00),
(3008, 1008, 'Internal Medicine', 'MD-LIC-10009', 300.00),
(3009, 1010, 'Medical Oncology', 'MD-LIC-10010', 290.00),
(3010, 1011, 'Immunology', 'MD-LIC-10011', 250.00),
(3011, 1012, 'General Surgery', 'MD-LIC-10012', 280.00),
(3012, 1013, 'Neurology', 'MD-LIC-10013', 270.00),
(3013, 1014, 'Plastic & Reconstructive Surgery', 'MD-LIC-10014', 310.00),
(3014, 1015, 'Internal Medicine', 'MD-LIC-10015', 240.00),
(3015, 1016, 'Sports Medicine', 'MD-LIC-10016', 230.00),
(3016, 1017, 'General Surgery', 'MD-LIC-10017', 310.00),
(3017, 1018, 'Neurosurgery', 'MD-LIC-10018', 450.00),
(3018, 1019, 'Cardiothoracic Surgery', 'MD-LIC-10019', 420.00),
(3019, 1020, 'Pediatrics', 'MD-LIC-10020', 230.00),
(3020, 1021, 'General Surgery', 'MD-LIC-10021', 290.00),
(3021, 1022, 'General Surgery', 'MD-LIC-10022', 400.00),
(3022, 1023, 'Trauma Surgery', 'MD-LIC-10023', 350.00),
(3023, 1024, 'Neurosurgery', 'MD-LIC-10024', 440.00),
(3024, 1025, 'Plastic Surgery', 'MD-LIC-10025', 300.00),
(3025, 1026, 'Emergency Medicine', 'MD-LIC-10026', 260.00),
(3026, 1027, 'Orthopedic Surgery', 'MD-LIC-10027', 320.00),
(3027, 1028, 'Pediatric Surgery', 'MD-LIC-10028', 330.00),
(3028, 1029, 'Plastic Surgery', 'MD-LIC-10029', 310.00),
(3029, 1041, 'Anesthesiology', 'MD-LIC-10030', 270.00);

SET IDENTITY_INSERT Clinical.Physicians OFF;
GO

SELECT * FROM Clinical.Physicians;

SET IDENTITY_INSERT Clinical.MedicalServices ON;

INSERT INTO Clinical.MedicalServices (ServiceID, ServiceName, Category, StandardCost)
VALUES
(400, 'Standard Initial Consultation', 'Consultation', 150.00),
(401, 'Specialist Follow-Up Visit', 'Consultation', 200.00),
(402, 'Emergency Room Evaluation', 'Emergency', 450.00),
(403, 'Comprehensive Metabolic Panel (CMP)', 'Laboratory', 85.00),
(404, 'Complete Blood Count (CBC)', 'Laboratory', 45.00),
(405, 'Lipid Panel', 'Laboratory', 60.00),
(406, 'Hemoglobin A1C Test', 'Laboratory', 55.00),
(407, 'Urinalysis Complete', 'Laboratory', 35.00),
(408, 'Chest X-Ray Single View', 'Radiology', 120.00),
(409, 'Chest X-Ray 2 Views', 'Radiology', 180.00),
(410, 'CT Scan Head/Brain', 'Radiology', 1100.00),
(411, 'CT Scan Abdomen and Pelvis', 'Radiology', 1450.00),
(412, 'MRI Brain without Contrast', 'Radiology', 1850.00),
(413, 'MRI Lumbar Spine', 'Radiology', 1950.00),
(414, 'Ultrasound Abdominal Complete', 'Radiology', 380.00),
(415, 'Echocardiogram Complete', 'Cardiology', 750.00),
(416, 'Electrocardiogram (ECG/EKG)', 'Cardiology', 125.00),
(417, 'Cardiac Catheterization Diagnostic', 'Cardiology', 4200.00),
(418, 'Coronary Artery Bypass Surgery', 'Surgery', 18500.00),
(419, 'Laparoscopic Cholecystectomy', 'Surgery', 6500.00),
(420, 'Appendectomy Laparoscopic', 'Surgery', 5800.00),
(421, 'Total Knee Replacement', 'Surgery', 14200.00),
(422, 'Total Hip Replacement', 'Surgery', 15800.00),
(423, 'Craniotomy for Tumor Resection', 'Surgery', 24500.00),
(424, 'General Anesthesia per Hour', 'Anesthesia', 450.00),
(425, 'Epidural Anesthesia', 'Anesthesia', 850.00),
(426, 'Physical Therapy Session', 'Rehabilitation', 140.00),
(427, 'Occupational Therapy Session', 'Rehabilitation', 150.00),
(428, 'Speech Therapy Evaluation', 'Rehabilitation', 175.00),
(429, 'Dialysis Single Session', 'Nephrology', 650.00),
(430, 'IV Infusion Administration', 'Nursing Care', 95.00),
(431, 'Blood Transfusion Unit Unit', 'Hematology', 320.00),
(432, 'Wound Dressing Complex', 'Nursing Care', 110.00),
(433, 'Chemotherapy Administration', 'Oncology', 2100.00),
(434, 'Radiation Therapy Session', 'Oncology', 1350.00),
(435, 'Pediatric Wellness Exam', 'Pediatrics', 130.00);

SET IDENTITY_INSERT Clinical.MedicalServices OFF;
GO

SELECT * FROM Clinical.MedicalServices;

SET IDENTITY_INSERT Clinical.Inventory ON;

INSERT INTO Clinical.Inventory (ItemID, ItemName, StockQuantity, ReorderLevel, UnitPrice)
VALUES
(800, 'Acetaminophen 500mg Tablets', 1500, 300, 0.15),
(801, 'Ibuprofen 400mg Tablets', 2000, 400, 0.20),
(802, 'Amoxicillin 500mg Capsules', 850, 200, 0.75),
(803, 'Cephalexin 250mg Capsules', 600, 150, 0.90),
(804, 'Azithromycin 250mg Tablets', 450, 100, 2.50),
(805, 'Ciprofloxacin 500mg Tablets', 380, 100, 1.85),
(806, 'Metformin 500mg Tablets', 1200, 250, 0.30),
(807, 'Lisinopril 10mg Tablets', 950, 200, 0.40),
(808, 'Atorvastatin 20mg Tablets', 1100, 250, 0.65),
(809, 'Metoprolol Succinate 50mg', 700, 150, 0.80),
(810, 'Amlodipine 5mg Tablets', 850, 200, 0.35),
(811, 'Levothyroxine 50mcg Tablets', 1300, 300, 0.25),
(812, 'Omeprazole 20mg Capsules', 900, 200, 0.50),
(813, 'Albuterol Inhaler 90mcg', 180, 50, 28.50),
(814, 'Insulin Glargine 100u/ml Pen', 120, 30, 45.00),
(815, 'Insulin Lispro 100u/ml Vial', 95, 25, 38.00),
(816, 'Heparin 5000 units/ml Vial', 140, 40, 12.50),
(817, 'Enoxaparin 40mg/0.4ml Syringe', 210, 50, 18.00),
(818, 'Warfarin 5mg Tablets', 500, 100, 0.45),
(819, 'Morphine Sulfate 10mg/ml Ampule', 85, 30, 8.50),
(820, 'Fentanyl Transdermal 25mcg/h', 60, 20, 15.00),
(821, 'Oxycodone 10mg Tablets', 320, 80, 1.20),
(822, 'Propofol 10mg/ml 20ml Vial', 150, 40, 22.00),
(823, 'Midazolam 5mg/5ml Vial', 190, 50, 6.50),
(824, 'Ondansetron 4mg/2ml Ampule', 400, 100, 3.75),
(825, 'Furosemide 40mg Tablets', 750, 150, 0.30),
(826, 'Hydrochlorothiazide 25mg', 800, 200, 0.25),
(827, 'Prednisone 20mg Tablets', 620, 120, 0.55),
(828, 'Methylprednisolone 125mg Vial', 110, 30, 14.20),
(829, 'Vancomycin 1g IV Vial', 90, 25, 32.00),
(830, 'Piperacillin/Tazobactam 3.375g', 130, 35, 26.50),
(831, 'Meropenem 1g IV Vial', 75, 20, 42.00),
(832, 'Normal Saline 0.9% 1000ml Bag', 2500, 500, 4.50),
(833, 'Lactated Ringer 1000ml Bag', 1800, 400, 5.00),
(834, 'Dextrose 5% in Water 500ml', 950, 200, 4.25),
(835, 'Sterile IV Tubing Sets', 1200, 300, 2.75),
(836, 'IV Catheter 18 Gauge', 1500, 300, 1.50),
(837, 'IV Catheter 20 Gauge', 2200, 400, 1.50),
(838, 'IV Catheter 22 Gauge', 1800, 350, 1.50),
(839, 'Surgical Gloves Size 7.5 Box', 450, 100, 18.50),
(840, 'Surgical Gloves Size 8.0 Box', 420, 100, 18.50),
(841, 'N95 Respirator Masks Box', 300, 80, 24.00),
(842, 'Surgical Face Masks Box', 850, 200, 12.00),
(843, 'Sterile Gauze Pads 4x4 Box', 600, 150, 8.50),
(844, 'Abdominal Surgical Pads', 350, 80, 14.00),
(845, 'Medical Adhesive Tape Roll', 900, 200, 2.10),
(846, 'Chlorhexidine Skin Prep 26ml', 500, 120, 6.80),
(847, 'Povidone-Iodine Swabsticks', 750, 150, 3.50),
(848, 'Sutures Vicryl 3-0 Pack', 280, 60, 11.20),
(849, 'Sutures Prolene 4-0 Pack', 240, 50, 12.50),
(850, 'Sutures Silk 2-0 Pack', 190, 40, 9.80),
(851, 'Surgical Scalpel Blades #10', 800, 150, 0.85),
(852, 'Surgical Scalpel Blades #11', 650, 150, 0.85),
(853, 'Surgical Scalpel Blades #15', 720, 150, 0.85),
(854, 'Suction Catheter 14 Fr', 400, 100, 3.20),
(855, 'Endotracheal Tube 7.5mm', 140, 35, 8.75),
(856, 'Endotracheal Tube 8.0mm', 150, 35, 8.75),
(857, 'Foley Catheter 16 Fr Kit', 220, 50, 16.50),
(858, 'Urinary Drainage Bag 2000ml', 310, 75, 5.40),
(859, 'Chest Tube Drainage Unit', 65, 20, 48.00),
(860, 'Syringe 3ml with Needle 22G', 3000, 600, 0.35),
(861, 'Syringe 10ml Luer Lock', 2500, 500, 0.45),
(862, 'Syringe 50ml Feeding/Irrigation', 450, 100, 1.80),
(863, 'ECG Monitoring Electrodes Pack', 600, 150, 14.50),
(864, 'Pulse Oximeter Finger Sensor', 85, 25, 35.00),
(865, 'Blood Glucose Test Strips Box', 380, 80, 28.00),
(866, 'Lancets 28 Gauge Box', 500, 100, 7.50),
(867, 'Blood Collection Tubes EDTA', 1800, 400, 0.65),
(868, 'Blood Collection Tubes Serum', 2100, 400, 0.65),
(869, 'Urine Specimen Containers', 1200, 250, 0.50),
(870, 'Nasal Cannula Oxygen Adult', 850, 200, 1.90),
(871, 'Non-Rebreather Mask Adult', 320, 80, 4.25),
(872, 'Nebulizer Setup Kit', 240, 60, 6.75),
(873, 'Sharps Disposal Container 5qt', 180, 40, 9.50),
(874, 'Biohazard Waste Bags Roll', 350, 80, 15.00),
(875, 'Disposable Bed Underpads Box', 400, 100, 22.00),
(876, 'Patient Gowns Universal', 650, 150, 8.00),
(877, 'Thermal Blanket Hospital Grade', 290, 60, 18.00),
(878, 'Elastic Bandage 4 Inch Roll', 550, 120, 2.40),
(879, 'Cervical Collar Adult Medium', 45, 15, 24.50),
(880, 'Arm Sling Universal Size', 110, 30, 9.75),
(881, 'Crutches Aluminum Pair', 55, 15, 28.00),
(882, 'Walker Folding Standard', 35, 10, 45.00),
(883, 'Wheelchair Standard Adult', 18, 5, 210.00),
(884, 'Digital Thermometer Covers Box', 750, 150, 11.00),
(885, 'Blood Pressure Cuff Adult', 60, 15, 32.00),
(886, 'Stethoscope Single Head', 40, 10, 26.00),
(887, 'Tracheostomy Care Kit', 85, 25, 19.50),
(888, 'Central Venous Catheter Kit', 45, 15, 85.00),
(889, 'Arterial Line Insertion Kit', 50, 15, 62.00),
(890, 'Epidural Tray Complete', 35, 10, 95.00),
(891, 'Spinal Anesthesia Kit 22G', 40, 10, 42.00),
(892, 'Defibrillator Pads Adult', 30, 10, 68.00),
(893, 'Suction Canister 1500ml', 420, 100, 4.80),
(894, 'Enteral Feeding Bag 1000ml', 160, 40, 7.20),
(895, 'Potassium Chloride 20mEq IV', 220, 50, 5.80),
(896, 'Sodium Bicarbonate 8.4% Amp', 130, 30, 9.10),
(897, 'Epinephrine 1mg/10ml Syringe', 95, 25, 16.50),
(898, 'Atropine 1mg/10ml Syringe', 85, 20, 14.00),
(899, 'Amiodarone 150mg/3ml Vial', 60, 15, 21.00);

SET IDENTITY_INSERT Clinical.Inventory OFF;
GO

SELECT * FROM Clinical.Inventory;

SET IDENTITY_INSERT Clinical.Encounters ON;

INSERT INTO Clinical.Encounters (EncounterID, PatientID, PhysicianID, RoomID, EncounterType, AdmitDateTime, DischargeDateTime, Status)
VALUES
(10000, 5000, 3000, 200, 'Emergency', '2023-10-01 08:15:00', '2023-10-03 14:00:00', 'Discharged'),
(10001, 5001, 3002, 223, 'Inpatient', '2023-10-01 10:30:00', '2023-10-05 11:45:00', 'Discharged'),
(10002, 5002, 3004, 207, 'Inpatient', '2023-10-02 09:00:00', '2023-10-08 16:30:00', 'Discharged'),
(10003, 5003, 3005, 233, 'Inpatient', '2023-10-02 14:20:00', '2023-10-04 10:15:00', 'Discharged'),
(10004, 5004, 3008, 213, 'Inpatient', '2023-10-03 07:45:00', '2023-10-10 12:00:00', 'Discharged'),
(10005, 5005, 3000, 202, 'Emergency', '2023-10-03 18:10:00', '2023-10-04 06:30:00', 'Discharged'),
(10006, 5006, 3003, 231, 'Inpatient', '2023-10-04 11:00:00', '2023-10-14 15:00:00', 'Discharged'),
(10007, 5007, 3008, NULL, 'Outpatient', '2023-10-05 09:30:00', '2023-10-05 10:30:00', 'Discharged'),
(10008, 5008, 3006, 245, 'Inpatient', '2023-10-05 13:15:00', '2023-10-12 11:00:00', 'Discharged'),
(10009, 5009, 3005, NULL, 'Outpatient', '2023-10-06 10:00:00', '2023-10-06 11:15:00', 'Discharged'),
(10010, 5010, 3002, 225, 'Inpatient', '2023-10-06 15:45:00', '2023-10-11 09:30:00', 'Discharged'),
(10011, 5011, 3008, 215, 'Inpatient', '2023-10-07 08:00:00', '2023-10-09 14:00:00', 'Discharged'),
(10012, 5012, 3025, 251, 'Emergency', '2023-10-07 22:30:00', '2023-10-08 10:00:00', 'Discharged'),
(10013, 5013, 3004, 208, 'Inpatient', '2023-10-08 09:15:00', '2023-10-15 13:30:00', 'Discharged'),
(10014, 5014, 3001, 238, 'Inpatient', '2023-10-09 06:45:00', '2023-10-12 16:00:00', 'Discharged'),
(10015, 5015, 3008, NULL, 'Outpatient', '2023-10-09 14:00:00', '2023-10-09 15:00:00', 'Discharged'),
(10016, 5016, 3002, 226, 'Inpatient', '2023-10-10 10:20:00', '2023-10-16 11:00:00', 'Discharged'),
(10017, 5017, 3005, 235, 'Inpatient', '2023-10-11 08:30:00', '2023-10-13 12:30:00', 'Discharged'),
(10018, 5018, 3003, 228, 'Inpatient', '2023-10-11 16:00:00', '2023-10-18 10:00:00', 'Discharged'),
(10019, 5019, 3006, 247, 'Inpatient', '2023-10-12 09:45:00', '2023-10-20 14:15:00', 'Discharged'),
(10020, 5020, 3008, NULL, 'Outpatient', '2023-10-13 11:30:00', '2023-10-13 12:30:00', 'Discharged'),
(10021, 5021, 3000, 200, 'Emergency', '2023-10-13 20:15:00', '2023-10-15 09:00:00', 'Discharged'),
(10022, 5022, 3004, 210, 'Inpatient', '2023-10-14 07:30:00', '2023-10-19 15:30:00', 'Discharged'),
(10023, 5023, 3005, NULL, 'Outpatient', '2023-10-15 08:45:00', '2023-10-15 09:45:00', 'Discharged'),
(10024, 5024, 3008, 256, 'Inpatient', '2023-10-15 13:00:00', '2023-10-22 11:00:00', 'Discharged'),
(10025, 5025, 3001, 240, 'Inpatient', '2023-10-16 06:30:00', '2023-10-18 17:00:00', 'Discharged'),
(10026, 5026, 3005, 237, 'Inpatient', '2023-10-17 10:15:00', '2023-10-20 10:00:00', 'Discharged'),
(10027, 5027, 3006, 248, 'Inpatient', '2023-10-18 09:00:00', '2023-10-25 12:30:00', 'Discharged'),
(10028, 5028, 3002, 223, 'Inpatient', '2023-10-19 14:40:00', '2023-10-24 16:15:00', 'Discharged'),
(10029, 5029, 3008, NULL, 'Outpatient', '2023-10-20 09:00:00', '2023-10-20 10:00:00', 'Discharged'),
(10030, 5030, 3004, 254, 'Inpatient', '2023-10-21 08:20:00', '2023-10-27 13:00:00', 'Discharged'),
(10031, 5031, 3025, 202, 'Emergency', '2023-10-21 19:50:00', '2023-10-22 08:30:00', 'Discharged'),
(10032, 5032, 3003, 230, 'Inpatient', '2023-10-22 11:10:00', '2023-10-28 10:45:00', 'Discharged'),
(10033, 5033, 3008, 216, 'Inpatient', '2023-10-23 07:00:00', '2023-10-26 14:00:00', 'Discharged'),
(10034, 5034, 3000, 294, 'Emergency', '2023-10-24 01:15:00', '2023-10-25 18:00:00', 'Discharged'),
(10035, 5035, 3006, 270, 'Inpatient', '2023-10-24 10:30:00', '2023-11-02 11:30:00', 'Discharged'),
(10036, 5036, 3004, 212, 'Inpatient', '2023-10-25 15:00:00', '2023-10-30 09:15:00', 'Discharged'),
(10037, 5037, 3005, NULL, 'Outpatient', '2023-10-26 13:00:00', '2023-10-26 14:00:00', 'Discharged'),
(10038, 5038, 3002, 262, 'Inpatient', '2023-10-27 08:45:00', '2023-11-01 15:00:00', 'Discharged'),
(10039, 5039, 3003, 264, 'Inpatient', '2023-10-28 12:15:00', '2023-11-04 10:30:00', 'Discharged'),
(10040, 5040, 3008, 277, 'Inpatient', '2023-10-29 09:30:00', '2023-11-03 12:00:00', 'Discharged'),
(10041, 5041, 3005, 266, 'Inpatient', '2023-10-30 07:15:00', '2023-11-02 16:45:00', 'Discharged'),
(10042, 5042, 3022, 200, 'Emergency', '2023-10-30 21:00:00', '2023-11-01 08:00:00', 'Discharged'),
(10043, 5043, 3001, 269, 'Inpatient', '2023-10-31 06:00:00', '2023-11-05 14:15:00', 'Discharged'),
(10044, 5044, 3008, NULL, 'Outpatient', '2023-11-01 10:00:00', '2023-11-01 11:00:00', 'Discharged'),
(10045, 5045, 3005, NULL, 'Outpatient', '2023-11-01 14:30:00', '2023-11-01 15:30:00', 'Discharged'),
(10046, 5046, 3002, 225, 'Inpatient', '2023-11-02 08:00:00', '2023-11-07 11:00:00', 'Discharged'),
(10047, 5047, 3006, 284, 'Inpatient', '2023-11-03 11:20:00', '2023-11-10 13:30:00', 'Discharged'),
(10048, 5048, 3004, 275, 'Inpatient', '2023-11-04 09:10:00', '2023-11-11 10:00:00', 'Discharged'),
(10049, 5049, 3008, NULL, 'Outpatient', '2023-11-05 08:30:00', '2023-11-05 09:30:00', 'Discharged'),
(10050, 5050, 3000, 251, 'Emergency', '2023-11-05 17:45:00', '2023-11-07 09:00:00', 'Discharged'),
(10051, 5051, 3003, 230, 'Inpatient', '2023-11-06 10:00:00', '2023-11-12 15:00:00', 'Discharged'),
(10052, 5052, 3008, 287, 'Inpatient', '2023-11-07 13:15:00', '2023-11-10 12:00:00', 'Discharged'),
(10053, 5053, 3008, 213, 'Inpatient', '2023-11-08 07:30:00', '2023-11-15 14:30:00', 'Discharged'),
(10054, 5054, 3001, 242, 'Inpatient', '2023-11-09 06:15:00', '2023-11-12 11:15:00', 'Discharged'),
(10055, 5055, 3008, NULL, 'Outpatient', '2023-11-09 15:00:00', '2023-11-09 16:00:00', 'Discharged'),
(10056, 5056, 3004, 295, 'Inpatient', '2023-11-10 09:00:00', '2023-11-18 10:00:00', 'Discharged'),
(10057, 5057, 3005, 233, 'Inpatient', '2023-11-11 11:30:00', '2023-11-14 13:00:00', 'Discharged'),
(10058, 5058, 3002, 223, 'Inpatient', '2023-11-12 08:45:00', '2023-11-17 16:00:00', 'Discharged'),
(10059, 5059, 3006, 245, 'Inpatient', '2023-11-13 14:00:00', '2023-11-20 10:30:00', 'Discharged'),
(10060, 5060, 3004, 207, 'Inpatient', '2023-11-14 10:15:00', '2023-11-19 12:00:00', 'Discharged'),
(10061, 5061, 3008, NULL, 'Outpatient', '2023-11-15 09:00:00', '2023-11-15 10:00:00', 'Discharged'),
(10062, 5062, 3005, NULL, 'Outpatient', '2023-11-15 11:30:00', '2023-11-15 12:30:00', 'Discharged'),
(10063, 5063, 3003, 228, 'Inpatient', '2023-11-16 13:45:00', '2023-11-22 15:00:00', 'Discharged'),
(10064, 5064, 3000, 202, 'Emergency', '2023-11-17 02:30:00', '2023-11-18 11:00:00', 'Discharged'),
(10065, 5065, 3005, 235, 'Inpatient', '2023-11-17 10:00:00', '2023-11-20 09:30:00', 'Discharged'),
(10066, 5066, 3008, 215, 'Inpatient', '2023-11-18 08:15:00', '2023-11-24 14:00:00', 'Discharged'),
(10067, 5067, 3008, NULL, 'Outpatient', '2023-11-19 14:00:00', '2023-11-19 15:00:00', 'Discharged'),
(10068, 5068, 3001, 244, 'Inpatient', '2023-11-20 06:45:00', '2023-11-23 16:30:00', 'Discharged'),
(10069, 5069, 3008, 256, 'Inpatient', '2023-11-21 09:30:00', '2023-11-29 11:00:00', 'Discharged'),
(10070, 5070, 3004, 210, 'Inpatient', '2023-11-22 11:00:00', '2023-11-27 10:00:00', 'Discharged'),
(10071, 5071, 3008, NULL, 'Outpatient', '2023-11-23 10:30:00', '2023-11-23 11:30:00', 'Discharged'),
(10072, 5072, 3003, 231, 'Inpatient', '2023-11-24 07:00:00', '2023-12-02 12:00:00', 'Discharged'),
(10073, 5073, 3005, 237, 'Inpatient', '2023-11-25 12:00:00', '2023-11-28 15:30:00', 'Discharged'),
(10074, 5074, 3002, 226, 'Inpatient', '2023-11-26 08:30:00', '2023-12-01 10:00:00', 'Discharged'),
(10075, 5075, 3008, NULL, 'Outpatient', '2023-11-27 09:15:00', '2023-11-27 10:15:00', 'Discharged'),
(10076, 5076, 3006, 247, 'Inpatient', '2023-11-28 10:00:00', '2023-12-05 14:00:00', 'Discharged'),
(10077, 5077, 3005, NULL, 'Outpatient', '2023-11-29 13:30:00', '2023-11-29 14:30:00', 'Discharged'),
(10078, 5078, 3004, 254, 'Inpatient', '2023-11-30 08:00:00', '2023-12-06 11:30:00', 'Discharged'),
(10079, 5079, 3008, 208, 'Inpatient', '2023-12-01 09:30:00', '2023-12-07 13:00:00', 'Discharged'),
(10080, 5080, 3000, 200, 'Emergency', '2023-12-02 01:10:00', NULL, 'Admitted'),
(10081, 5081, 3002, 223, 'Inpatient', '2023-12-02 08:00:00', NULL, 'Admitted'),
(10082, 5082, 3004, 207, 'Inpatient', '2023-12-02 10:15:00', NULL, 'Admitted'),
(10083, 5083, 3005, 233, 'Inpatient', '2023-12-02 11:30:00', NULL, 'Admitted'),
(10084, 5084, 3008, 213, 'Inpatient', '2023-12-02 14:00:00', NULL, 'Admitted'),
(10085, 5085, 3001, 238, 'Inpatient', '2023-12-03 06:30:00', NULL, 'Admitted'),
(10086, 5086, 3003, 228, 'Inpatient', '2023-12-03 09:00:00', NULL, 'Admitted'),
(10087, 5087, 3006, 245, 'Inpatient', '2023-12-03 10:45:00', NULL, 'Admitted'),
(10088, 5088, 3002, 225, 'Inpatient', '2023-12-03 13:20:00', NULL, 'Admitted'),
(10089, 5089, 3008, 215, 'Inpatient', '2023-12-03 15:10:00', NULL, 'Admitted'),
(10090, 5090, 3000, 251, 'Emergency', '2023-12-04 02:00:00', NULL, 'Admitted'),
(10091, 5091, 3004, 210, 'Inpatient', '2023-12-04 08:30:00', NULL, 'Admitted'),
(10092, 5092, 3003, 230, 'Inpatient', '2023-12-04 10:00:00', NULL, 'Admitted'),
(10093, 5093, 3008, 256, 'Inpatient', '2023-12-04 11:45:00', NULL, 'Admitted'),
(10094, 5094, 3001, 240, 'Inpatient', '2023-12-04 14:15:00', NULL, 'Admitted'),
(10095, 5095, 3005, 235, 'Inpatient', '2023-12-05 07:30:00', NULL, 'Admitted'),
(10096, 5096, 3006, 247, 'Inpatient', '2023-12-05 09:15:00', NULL, 'Admitted'),
(10097, 5097, 3002, 226, 'Inpatient', '2023-12-05 11:00:00', NULL, 'Admitted'),
(10098, 5098, 3003, 231, 'Inpatient', '2023-12-05 13:30:00', NULL, 'Admitted'),
(10099, 5099, 3008, 216, 'Inpatient', '2023-12-05 16:00:00', NULL, 'Admitted');

SET IDENTITY_INSERT Clinical.Encounters OFF;
GO

SELECT * FROM Clinical.Encounters;

SET IDENTITY_INSERT Clinical.EncounterServices ON;

INSERT INTO Clinical.EncounterServices (EncounterServiceID, EncounterID, ServiceID, ServiceDateTime, Quantity, BilledCost)
VALUES
(50000, 10000, 402, '2023-10-01 08:30:00', 1, 450.00),
(50001, 10000, 408, '2023-10-01 09:15:00', 1, 120.00),
(50002, 10000, 404, '2023-10-01 09:30:00', 1, 45.00),
(50003, 10001, 400, '2023-10-01 10:45:00', 1, 150.00),
(50004, 10001, 415, '2023-10-01 14:00:00', 1, 750.00),
(50005, 10001, 416, '2023-10-01 14:30:00', 1, 125.00),
(50006, 10002, 400, '2023-10-02 09:30:00', 1, 150.00),
(50007, 10002, 421, '2023-10-03 08:00:00', 1, 14200.00),
(50008, 10002, 424, '2023-10-03 08:00:00', 3, 1350.00),
(50009, 10002, 426, '2023-10-05 10:00:00', 2, 280.00),
(50010, 10003, 435, '2023-10-02 15:00:00', 1, 130.00),
(50011, 10003, 404, '2023-10-02 15:30:00', 1, 45.00),
(50012, 10004, 400, '2023-10-03 08:15:00', 1, 150.00),
(50013, 10004, 403, '2023-10-03 09:00:00', 2, 170.00),
(50014, 10004, 411, '2023-10-04 11:00:00', 1, 1450.00),
(50015, 10005, 402, '2023-10-03 18:30:00', 1, 450.00),
(50016, 10005, 409, '2023-10-03 19:15:00', 1, 180.00),
(50017, 10006, 400, '2023-10-04 11:30:00', 1, 150.00),
(50018, 10006, 412, '2023-10-05 10:00:00', 1, 1850.00),
(50019, 10006, 423, '2023-10-07 07:30:00', 1, 24500.00),
(50020, 10006, 424, '2023-10-07 07:30:00', 5, 2250.00),
(50021, 10007, 401, '2023-10-05 09:45:00', 1, 200.00),
(50022, 10007, 405, '2023-10-05 10:00:00', 1, 60.00),
(50023, 10008, 400, '2023-10-05 13:45:00', 1, 150.00),
(50024, 10008, 433, '2023-10-06 09:00:00', 1, 2100.00),
(50025, 10008, 404, '2023-10-06 09:30:00', 2, 90.00),
(50026, 10009, 435, '2023-10-06 10:15:00', 1, 130.00),
(50027, 10010, 400, '2023-10-06 16:15:00', 1, 150.00),
(50028, 10010, 417, '2023-10-07 08:30:00', 1, 4200.00),
(50029, 10010, 416, '2023-10-07 09:00:00', 2, 250.00),
(50030, 10011, 400, '2023-10-07 08:30:00', 1, 150.00),
(50031, 10011, 403, '2023-10-07 09:00:00', 1, 85.00),
(50032, 10012, 402, '2023-10-07 22:45:00', 1, 450.00),
(50033, 10012, 432, '2023-10-07 23:30:00', 1, 110.00),
(50034, 10013, 400, '2023-10-08 09:45:00', 1, 150.00),
(50035, 10013, 422, '2023-10-09 08:00:00', 1, 15800.00),
(50036, 10013, 424, '2023-10-09 08:00:00', 4, 1800.00),
(50037, 10014, 400, '2023-10-09 07:15:00', 1, 150.00),
(50038, 10014, 420, '2023-10-09 09:00:00', 1, 5800.00),
(50039, 10014, 424, '2023-10-09 09:00:00', 2, 900.00),
(50040, 10015, 401, '2023-10-09 14:15:00', 1, 200.00),
(50041, 10016, 400, '2023-10-10 10:45:00', 1, 150.00),
(50042, 10016, 418, '2023-10-11 07:00:00', 1, 18500.00),
(50043, 10016, 424, '2023-10-11 07:00:00', 6, 2700.00),
(50044, 10017, 435, '2023-10-11 09:00:00', 1, 130.00),
(50045, 10018, 400, '2023-10-11 16:30:00', 1, 150.00),
(50046, 10018, 410, '2023-10-12 10:00:00', 1, 1100.00),
(50047, 10019, 400, '2023-10-12 10:15:00', 1, 150.00),
(50048, 10019, 434, '2023-10-13 11:00:00', 3, 4050.00),
(50049, 10020, 401, '2023-10-13 11:45:00', 1, 200.00),
(50050, 10020, 406, '2023-10-13 12:00:00', 1, 55.00),
(50051, 10021, 402, '2023-10-13 20:30:00', 1, 450.00),
(50052, 10022, 400, '2023-10-14 08:00:00', 1, 150.00),
(50053, 10022, 426, '2023-10-15 09:00:00', 3, 420.00),
(50054, 10023, 435, '2023-10-15 09:00:00', 1, 130.00),
(50055, 10024, 400, '2023-10-15 13:30:00', 1, 150.00),
(50056, 10024, 403, '2023-10-16 08:30:00', 2, 170.00),
(50057, 10025, 400, '2023-10-16 07:00:00', 1, 150.00),
(50058, 10025, 419, '2023-10-16 08:30:00', 1, 6500.00),
(50059, 10026, 435, '2023-10-17 10:45:00', 1, 130.00),
(50060, 10027, 400, '2023-10-18 09:30:00', 1, 150.00),
(50061, 10027, 433, '2023-10-19 10:00:00', 1, 2100.00),
(50062, 10028, 400, '2023-10-19 15:00:00', 1, 150.00),
(50063, 10028, 415, '2023-10-20 11:00:00', 1, 750.00),
(50064, 10029, 401, '2023-10-20 09:15:00', 1, 200.00),
(50065, 10030, 400, '2023-10-21 08:45:00', 1, 150.00),
(50066, 10030, 413, '2023-10-22 14:00:00', 1, 1950.00),
(50067, 10031, 402, '2023-10-21 20:15:00', 1, 450.00),
(50068, 10032, 400, '2023-10-22 11:30:00', 1, 150.00),
(50069, 10032, 410, '2023-10-23 09:00:00', 1, 1100.00),
(50070, 10033, 400, '2023-10-23 07:30:00', 1, 150.00),
(50071, 10034, 402, '2023-10-24 01:45:00', 1, 450.00),
(50072, 10035, 400, '2023-10-24 11:00:00', 1, 150.00),
(50073, 10035, 434, '2023-10-25 10:00:00', 2, 2700.00),
(50074, 10036, 400, '2023-10-25 15:30:00', 1, 150.00),
(50075, 10036, 421, '2023-10-26 08:00:00', 1, 14200.00),
(50076, 10037, 435, '2023-10-26 13:15:00', 1, 130.00),
(50077, 10038, 400, '2023-10-27 09:15:00', 1, 150.00),
(50078, 10038, 417, '2023-10-28 08:30:00', 1, 4200.00),
(50079, 10039, 400, '2023-10-28 12:45:00', 1, 150.00),
(50080, 10040, 400, '2023-10-29 10:00:00', 1, 150.00),
(50081, 10041, 435, '2023-10-30 07:45:00', 1, 130.00),
(50082, 10042, 402, '2023-10-30 21:30:00', 1, 450.00),
(50083, 10043, 400, '2023-10-31 06:30:00', 1, 150.00),
(50084, 10043, 420, '2023-10-31 08:00:00', 1, 5800.00),
(50085, 10044, 401, '2023-11-01 10:15:00', 1, 200.00),
(50086, 10045, 435, '2023-11-01 14:45:00', 1, 130.00),
(50087, 10046, 400, '2023-11-02 08:30:00', 1, 150.00),
(50088, 10046, 415, '2023-11-03 10:00:00', 1, 750.00),
(50089, 10047, 400, '2023-11-03 11:45:00', 1, 150.00),
(50090, 10048, 400, '2023-11-04 09:30:00', 1, 150.00),
(50091, 10048, 422, '2023-11-05 08:00:00', 1, 15800.00),
(50092, 10049, 401, '2023-11-05 08:45:00', 1, 200.00),
(50093, 10050, 402, '2023-11-05 18:00:00', 1, 450.00),
(50094, 10051, 400, '2023-11-06 10:30:00', 1, 150.00),
(50095, 10052, 400, '2023-11-07 13:45:00', 1, 150.00),
(50096, 10053, 400, '2023-11-08 08:00:00', 1, 150.00),
(50097, 10054, 400, '2023-11-09 06:45:00', 1, 150.00),
(50098, 10054, 419, '2023-11-09 08:15:00', 1, 6500.00),
(50099, 10055, 401, '2023-11-09 15:15:00', 1, 200.00);

SET IDENTITY_INSERT Clinical.EncounterServices OFF;
GO

SELECT * FROM Clinical.EncounterServices;

SET IDENTITY_INSERT Admin.Billing ON;

INSERT INTO Admin.Billing (BillID, EncounterID, TotalAmount, InsuranceCoverage, PaymentStatus, BillDate)
VALUES
(7000, 10000, 615.00, 500.00, 'Paid', '2023-10-03'),
(7001, 10001, 1025.00, 800.00, 'Paid', '2023-10-05'),
(7002, 10002, 15830.00, 12000.00, 'Partial', '2023-10-08'),
(7003, 10003, 175.00, 0.00, 'Paid', '2023-10-04'),
(7004, 10004, 1770.00, 1400.00, 'Paid', '2023-10-10'),
(7005, 10005, 630.00, 500.00, 'Paid', '2023-10-04'),
(7006, 10006, 28750.00, 25000.00, 'Paid', '2023-10-14'),
(7007, 10007, 260.00, 200.00, 'Paid', '2023-10-05'),
(7008, 10008, 2340.00, 1800.00, 'Partial', '2023-10-12'),
(7009, 10009, 130.00, 100.00, 'Paid', '2023-10-06'),
(7010, 10010, 4600.00, 3500.00, 'Paid', '2023-10-11'),
(7011, 10011, 235.00, 0.00, 'Paid', '2023-10-09'),
(7012, 10012, 560.00, 400.00, 'Paid', '2023-10-08'),
(7013, 10013, 17750.00, 15000.00, 'Paid', '2023-10-15'),
(7014, 10014, 6850.00, 5000.00, 'Partial', '2023-10-12'),
(7015, 10015, 200.00, 150.00, 'Paid', '2023-10-09'),
(7016, 10016, 21350.00, 18000.00, 'Paid', '2023-10-16'),
(7017, 10017, 130.00, 100.00, 'Paid', '2023-10-13'),
(7018, 10018, 1250.00, 1000.00, 'Pending', '2023-10-18'),
(7019, 10019, 4200.00, 3200.00, 'Paid', '2023-10-20'),
(7020, 10020, 255.00, 200.00, 'Paid', '2023-10-13'),
(7021, 10021, 450.00, 0.00, 'Paid', '2023-10-15'),
(7022, 10022, 570.00, 400.00, 'Paid', '2023-10-19'),
(7023, 10023, 130.00, 100.00, 'Paid', '2023-10-15'),
(7024, 10024, 320.00, 250.00, 'Paid', '2023-10-22'),
(7025, 10025, 6650.00, 5000.00, 'Paid', '2023-10-18'),
(7026, 10026, 130.00, 0.00, 'Paid', '2023-10-20'),
(7027, 10027, 2250.00, 1800.00, 'Partial', '2023-10-25'),
(7028, 10028, 900.00, 700.00, 'Paid', '2023-10-24'),
(7029, 10029, 200.00, 150.00, 'Paid', '2023-10-20'),
(7030, 10030, 2100.00, 1600.00, 'Pending', '2023-10-27'),
(7031, 10031, 450.00, 300.00, 'Paid', '2023-10-22'),
(7032, 10032, 1250.00, 1000.00, 'Paid', '2023-10-28'),
(7033, 10033, 150.00, 100.00, 'Paid', '2023-10-26'),
(7034, 10034, 450.00, 0.00, 'Written-Off', '2023-10-25'),
(7035, 10035, 2850.00, 2000.00, 'Paid', '2023-11-02'),
(7036, 10036, 14350.00, 11000.00, 'Partial', '2023-10-30'),
(7037, 10037, 130.00, 100.00, 'Paid', '2023-10-26'),
(7038, 10038, 4350.00, 3500.00, 'Paid', '2023-11-01'),
(7039, 10039, 150.00, 100.00, 'Paid', '2023-11-04'),
(7040, 10040, 150.00, 0.00, 'Paid', '2023-11-03'),
(7041, 10041, 130.00, 100.00, 'Paid', '2023-11-02'),
(7042, 10042, 450.00, 350.00, 'Paid', '2023-11-01'),
(7043, 10043, 5950.00, 4500.00, 'Paid', '2023-11-05'),
(7044, 10044, 200.00, 150.00, 'Paid', '2023-11-01'),
(7045, 10045, 130.00, 100.00, 'Paid', '2023-11-01'),
(7046, 10046, 900.00, 700.00, 'Paid', '2023-11-07'),
(7047, 10047, 150.00, 100.00, 'Pending', '2023-11-10'),
(7048, 10048, 15950.00, 12000.00, 'Partial', '2023-11-11'),
(7049, 10049, 200.00, 150.00, 'Paid', '2023-11-05'),
(7050, 10050, 450.00, 300.00, 'Paid', '2023-11-07'),
(7051, 10051, 150.00, 100.00, 'Paid', '2023-11-12'),
(7052, 10052, 150.00, 0.00, 'Paid', '2023-11-10'),
(7053, 10053, 150.00, 100.00, 'Paid', '2023-11-15'),
(7054, 10054, 6650.00, 5000.00, 'Paid', '2023-11-12'),
(7055, 10055, 200.00, 150.00, 'Paid', '2023-11-09'),
(7056, 10056, 150.00, 100.00, 'Pending', '2023-11-18'),
(7057, 10057, 130.00, 100.00, 'Paid', '2023-11-14'),
(7058, 10058, 150.00, 100.00, 'Paid', '2023-11-17'),
(7059, 10059, 150.00, 100.00, 'Paid', '2023-11-20'),
(7060, 10060, 150.00, 100.00, 'Paid', '2023-11-19'),
(7061, 10061, 200.00, 150.00, 'Paid', '2023-11-15'),
(7062, 10062, 130.00, 100.00, 'Paid', '2023-11-15'),
(7063, 10063, 150.00, 100.00, 'Pending', '2023-11-22'),
(7064, 10064, 450.00, 300.00, 'Paid', '2023-11-18'),
(7065, 10065, 130.00, 100.00, 'Paid', '2023-11-20'),
(7066, 10066, 150.00, 100.00, 'Paid', '2023-11-24'),
(7067, 10067, 200.00, 150.00, 'Paid', '2023-11-19'),
(7068, 10068, 150.00, 100.00, 'Paid', '2023-11-23'),
(7069, 10069, 150.00, 100.00, 'Paid', '2023-11-29'),
(7070, 10070, 150.00, 100.00, 'Paid', '2023-11-27'),
(7071, 10071, 200.00, 150.00, 'Paid', '2023-11-23'),
(7072, 10072, 150.00, 100.00, 'Pending', '2023-12-02'),
(7073, 10073, 130.00, 100.00, 'Paid', '2023-11-28'),
(7074, 10074, 150.00, 100.00, 'Paid', '2023-12-01'),
(7075, 10075, 200.00, 150.00, 'Paid', '2023-11-27'),
(7076, 10076, 150.00, 100.00, 'Paid', '2023-12-05'),
(7077, 10077, 130.00, 100.00, 'Paid', '2023-11-29'),
(7078, 10078, 150.00, 100.00, 'Pending', '2023-12-06'),
(7079, 10079, 150.00, 100.00, 'Paid', '2023-12-07'),
(7080, 10080, 450.00, 0.00, 'Pending', '2023-12-02'),
(7081, 10081, 1200.00, 800.00, 'Pending', '2023-12-02'),
(7082, 10082, 950.00, 500.00, 'Pending', '2023-12-02'),
(7083, 10083, 650.00, 400.00, 'Pending', '2023-12-02'),
(7084, 10084, 800.00, 600.00, 'Pending', '2023-12-02'),
(7085, 10085, 2500.00, 1800.00, 'Pending', '2023-12-03'),
(7086, 10086, 1100.00, 750.00, 'Pending', '2023-12-03'),
(7087, 10087, 1850.00, 1200.00, 'Pending', '2023-12-03'),
(7088, 10088, 1400.00, 900.00, 'Pending', '2023-12-03'),
(7089, 10089, 900.00, 600.00, 'Pending', '2023-12-03'),
(7090, 10090, 450.00, 0.00, 'Pending', '2023-12-04'),
(7091, 10091, 1000.00, 700.00, 'Pending', '2023-12-04'),
(7092, 10092, 1300.00, 900.00, 'Pending', '2023-12-04'),
(7093, 10093, 1100.00, 800.00, 'Pending', '2023-12-04'),
(7094, 10094, 2800.00, 2000.00, 'Pending', '2023-12-04'),
(7095, 10095, 750.00, 500.00, 'Pending', '2023-12-05'),
(7096, 10096, 1600.00, 1100.00, 'Pending', '2023-12-05'),
(7097, 10097, 1250.00, 850.00, 'Pending', '2023-12-05'),
(7098, 10098, 1900.00, 1300.00, 'Pending', '2023-12-05'),
(7099, 10099, 1050.00, 700.00, 'Pending', '2023-12-05');

SET IDENTITY_INSERT Admin.Billing OFF;
GO

SELECT * FROM Admin.Billing;

SET IDENTITY_INSERT Audit.SystemLogs ON;

INSERT INTO Audit.SystemLogs (LogID, TableName, OperationType, ExecutionTime, ExecutedBy, Details)
VALUES
(1, 'Patients', 'INSERT', '2023-10-01 08:30:00', 'dbo', 'New patient record created: PatientID 5000'),
(2, 'Encounters', 'INSERT', '2023-10-01 08:32:00', 'dbo', 'Emergency encounter opened: EncounterID 10000'),
(3, 'EncounterServices', 'INSERT', '2023-10-01 08:35:00', 'dbo', 'Added ServiceID 402 to EncounterID 10000'),
(4, 'Inventory', 'UPDATE', '2023-10-01 09:00:00', 'dbo', 'Stock deducted for ItemID 800 (Qty: -10)'),
(5, 'Patients', 'INSERT', '2023-10-01 10:15:00', 'dbo', 'New patient record created: PatientID 5001'),
(6, 'Encounters', 'INSERT', '2023-10-01 10:30:00', 'dbo', 'Inpatient encounter opened: EncounterID 10001'),
(7, 'Rooms', 'UPDATE', '2023-10-01 10:35:00', 'dbo', 'RoomID 223 marked as occupied (IsOccupied = 1)'),
(8, 'Patients', 'INSERT', '2023-10-02 08:45:00', 'dbo', 'New patient record created: PatientID 5002'),
(9, 'Encounters', 'INSERT', '2023-10-02 09:00:00', 'dbo', 'Inpatient encounter opened: EncounterID 10002'),
(10, 'Billing', 'INSERT', '2023-10-03 14:00:00', 'dbo', 'Bill generated: BillID 7000 for EncounterID 10000'),
(11, 'Encounters', 'UPDATE', '2023-10-03 14:00:00', 'dbo', 'EncounterID 10000 status changed to Discharged'),
(12, 'Rooms', 'UPDATE', '2023-10-03 14:05:00', 'dbo', 'RoomID 200 marked as vacant (IsOccupied = 0)'),
(13, 'Staff', 'UPDATE', '2023-10-04 09:00:00', 'dbo', 'Updated salary for StaffID 1030'),
(14, 'Inventory', 'UPDATE', '2023-10-04 11:30:00', 'dbo', 'Stock replenished for ItemID 832 (Qty: +500)'),
(15, 'Billing', 'UPDATE', '2023-10-05 11:45:00', 'dbo', 'Payment status updated to Paid for BillID 7001'),
(16, 'Patients', 'UPDATE', '2023-10-05 13:00:00', 'dbo', 'Updated phone number for PatientID 5003'),
(17, 'Encounters', 'INSERT', '2023-10-05 13:15:00', 'dbo', 'Inpatient encounter opened: EncounterID 10008'),
(18, 'MedicalServices', 'INSERT', '2023-10-06 08:00:00', 'dbo', 'New medical service added: ServiceID 435'),
(19, 'Physicians', 'UPDATE', '2023-10-06 09:30:00', 'dbo', 'Consultation fee updated for PhysicianID 3000'),
(20, 'SystemLogs', 'TRUNCATE', '2023-10-06 23:59:59', 'sysadmin', 'Archived historical audit entries'),
(21, 'Patients', 'INSERT', '2023-10-07 08:00:00', 'dbo', 'New patient record created: PatientID 5011'),
(22, 'Encounters', 'INSERT', '2023-10-07 08:00:00', 'dbo', 'Inpatient encounter opened: EncounterID 10011'),
(23, 'Inventory', 'UPDATE', '2023-10-07 14:20:00', 'dbo', 'Reorder trigger warning hit for ItemID 820'),
(24, 'Rooms', 'UPDATE', '2023-10-08 10:00:00', 'dbo', 'RoomID 251 status changed to IsOccupied = 0'),
(25, 'Billing', 'INSERT', '2023-10-08 10:05:00', 'dbo', 'Bill generated: BillID 7012 for EncounterID 10012'),
(26, 'Encounters', 'INSERT', '2023-10-08 09:15:00', 'dbo', 'Inpatient encounter opened: EncounterID 10013'),
(27, 'EncounterServices', 'INSERT', '2023-10-09 08:00:00', 'dbo', 'Added ServiceID 422 to EncounterID 10013'),
(28, 'Staff', 'INSERT', '2023-10-09 09:00:00', 'dbo', 'New employee onboarded: StaffID 1099'),
(29, 'Patients', 'INSERT', '2023-10-10 10:20:00', 'dbo', 'New patient record created: PatientID 5016'),
(30, 'Billing', 'UPDATE', '2023-10-11 09:30:00', 'dbo', 'Payment received for BillID 7010'),
(31, 'Encounters', 'UPDATE', '2023-10-12 11:00:00', 'dbo', 'EncounterID 10008 status changed to Discharged'),
(32, 'Inventory', 'UPDATE', '2023-10-12 15:00:00', 'dbo', 'Stock deducted for ItemID 841 (Qty: -50)'),
(33, 'Patients', 'UPDATE', '2023-10-13 10:00:00', 'dbo', 'Updated emergency contact for PatientID 5020'),
(34, 'Encounters', 'INSERT', '2023-10-13 20:15:00', 'dbo', 'Emergency encounter opened: EncounterID 10021'),
(35, 'Billing', 'INSERT', '2023-10-14 15:00:00', 'dbo', 'Bill generated: BillID 7006 for EncounterID 10006'),
(36, 'Departments', 'UPDATE', '2023-10-15 08:00:00', 'dbo', 'Annual budget updated for DepartmentID 104'),
(37, 'Encounters', 'INSERT', '2023-10-15 13:00:00', 'dbo', 'Inpatient encounter opened: EncounterID 10024'),
(38, 'Rooms', 'UPDATE', '2023-10-15 13:05:00', 'dbo', 'RoomID 256 marked as occupied (IsOccupied = 1)'),
(39, 'Billing', 'UPDATE', '2023-10-16 11:00:00', 'dbo', 'Insurance payment applied to BillID 7016'),
(40, 'Patients', 'INSERT', '2023-10-17 10:15:00', 'dbo', 'New patient record created: PatientID 5026'),
(41, 'Encounters', 'INSERT', '2023-10-18 09:00:00', 'dbo', 'Inpatient encounter opened: EncounterID 10027'),
(42, 'EncounterServices', 'INSERT', '2023-10-19 10:00:00', 'dbo', 'Added ServiceID 433 to EncounterID 10027'),
(43, 'Inventory', 'UPDATE', '2023-10-20 08:30:00', 'dbo', 'Stock replenished for ItemID 813 (Qty: +100)'),
(44, 'Encounters', 'UPDATE', '2023-10-20 10:00:00', 'dbo', 'EncounterID 10026 status changed to Discharged'),
(45, 'Billing', 'INSERT', '2023-10-20 10:05:00', 'dbo', 'Bill generated: BillID 7026 for EncounterID 10026'),
(46, 'Patients', 'INSERT', '2023-10-21 08:20:00', 'dbo', 'New patient record created: PatientID 5030'),
(47, 'Rooms', 'UPDATE', '2023-10-21 08:25:00', 'dbo', 'RoomID 254 marked as occupied (IsOccupied = 1)'),
(48, 'Encounters', 'INSERT', '2023-10-22 11:10:00', 'dbo', 'Inpatient encounter opened: EncounterID 10032'),
(49, 'Billing', 'UPDATE', '2023-10-23 16:00:00', 'dbo', 'Payment received for BillID 7028'),
(50, 'Encounters', 'UPDATE', '2023-10-24 16:15:00', 'dbo', 'EncounterID 10028 status changed to Discharged'),
(51, 'Billing', 'UPDATE', '2023-10-25 09:00:00', 'dbo', 'BillID 7034 status changed to Written-Off'),
(52, 'Staff', 'UPDATE', '2023-10-25 14:00:00', 'dbo', 'Changed Role for StaffID 1044 to Charge Nurse'),
(53, 'Patients', 'INSERT', '2023-10-26 13:00:00', 'dbo', 'New patient record created: PatientID 5037'),
(54, 'Encounters', 'INSERT', '2023-10-27 08:45:00', 'dbo', 'Inpatient encounter opened: EncounterID 10038'),
(55, 'EncounterServices', 'INSERT', '2023-10-28 08:30:00', 'dbo', 'Added ServiceID 417 to EncounterID 10038'),
(56, 'Rooms', 'UPDATE', '2023-10-28 10:45:00', 'dbo', 'RoomID 230 status changed to IsOccupied = 0'),
(57, 'Inventory', 'UPDATE', '2023-10-29 11:00:00', 'dbo', 'Stock deducted for ItemID 860 (Qty: -200)'),
(58, 'Patients', 'INSERT', '2023-10-30 07:15:00', 'dbo', 'New patient record created: PatientID 5041'),
(59, 'Encounters', 'INSERT', '2023-10-30 21:00:00', 'dbo', 'Emergency encounter opened: EncounterID 10042'),
(60, 'Billing', 'INSERT', '2023-10-31 10:00:00', 'dbo', 'Bill generated: BillID 7036 for EncounterID 10036'),
(61, 'Encounters', 'UPDATE', '2023-11-01 08:00:00', 'dbo', 'EncounterID 10042 status changed to Discharged'),
(62, 'Billing', 'UPDATE', '2023-11-01 09:00:00', 'dbo', 'Payment received for BillID 7042'),
(63, 'Patients', 'INSERT', '2023-11-02 08:00:00', 'dbo', 'New patient record created: PatientID 5046'),
(64, 'Encounters', 'INSERT', '2023-11-02 08:00:00', 'dbo', 'Inpatient encounter opened: EncounterID 10046'),
(65, 'Rooms', 'UPDATE', '2023-11-02 08:05:00', 'dbo', 'RoomID 225 marked as occupied (IsOccupied = 1)'),
(66, 'Encounters', 'UPDATE', '2023-11-03 12:00:00', 'dbo', 'EncounterID 10040 status changed to Discharged'),
(67, 'Billing', 'INSERT', '2023-11-03 12:05:00', 'dbo', 'Bill generated: BillID 7040 for EncounterID 10040'),
(68, 'Inventory', 'UPDATE', '2023-11-04 10:00:00', 'dbo', 'Stock replenished for ItemID 814 (Qty: +50)'),
(69, 'Patients', 'INSERT', '2023-11-05 08:30:00', 'dbo', 'New patient record created: PatientID 5049'),
(70, 'Encounters', 'INSERT', '2023-11-06 10:00:00', 'dbo', 'Inpatient encounter opened: EncounterID 10051'),
(71, 'EncounterServices', 'INSERT', '2023-11-06 10:30:00', 'dbo', 'Added ServiceID 400 to EncounterID 10051'),
(72, 'Billing', 'UPDATE', '2023-11-07 11:00:00', 'dbo', 'Payment received for BillID 7046'),
(73, 'Encounters', 'UPDATE', '2023-11-07 11:00:00', 'dbo', 'EncounterID 10046 status changed to Discharged'),
(74, 'Rooms', 'UPDATE', '2023-11-07 11:05:00', 'dbo', 'RoomID 225 marked as vacant (IsOccupied = 0)'),
(75, 'Patients', 'INSERT', '2023-11-08 07:30:00', 'dbo', 'New patient record created: PatientID 5053'),
(76, 'Encounters', 'INSERT', '2023-11-09 06:15:00', 'dbo', 'Inpatient encounter opened: EncounterID 10054'),
(77, 'EncounterServices', 'INSERT', '2023-11-09 08:15:00', 'dbo', 'Added ServiceID 419 to EncounterID 10054'),
(78, 'Billing', 'UPDATE', '2023-11-10 13:30:00', 'dbo', 'Insurance claim submitted for BillID 7047'),
(79, 'Encounters', 'UPDATE', '2023-11-10 12:00:00', 'dbo', 'EncounterID 10052 status changed to Discharged'),
(80, 'Inventory', 'UPDATE', '2023-11-11 14:00:00', 'dbo', 'Stock deducted for ItemID 836 (Qty: -100)'),
(81, 'Patients', 'INSERT', '2023-11-12 08:45:00', 'dbo', 'New patient record created: PatientID 5058'),
(82, 'Encounters', 'INSERT', '2023-11-13 14:00:00', 'dbo', 'Inpatient encounter opened: EncounterID 10059'),
(83, 'Rooms', 'UPDATE', '2023-11-13 14:05:00', 'dbo', 'RoomID 245 marked as occupied (IsOccupied = 1)'),
(84, 'Billing', 'INSERT', '2023-11-14 13:00:00', 'dbo', 'Bill generated: BillID 7057 for EncounterID 10057'),
(85, 'Encounters', 'UPDATE', '2023-11-15 14:30:00', 'dbo', 'EncounterID 10053 status changed to Discharged'),
(86, 'Staff', 'UPDATE', '2023-11-16 09:00:00', 'dbo', 'Deactivated StaffID 1094 (IsActive = 0)'),
(87, 'Patients', 'INSERT', '2023-11-17 02:30:00', 'dbo', 'New patient record created: PatientID 5064'),
(88, 'Encounters', 'INSERT', '2023-11-18 08:15:00', 'dbo', 'Inpatient encounter opened: EncounterID 10066'),
(89, 'Billing', 'UPDATE', '2023-11-19 12:00:00', 'dbo', 'Payment received for BillID 7060'),
(90, 'Encounters', 'UPDATE', '2023-11-20 10:30:00', 'dbo', 'EncounterID 10059 status changed to Discharged'),
(91, 'Rooms', 'UPDATE', '2023-11-20 10:35:00', 'dbo', 'RoomID 245 marked as vacant (IsOccupied = 0)'),
(92, 'Inventory', 'UPDATE', '2023-11-21 16:00:00', 'dbo', 'Stock audit performed on Category: Surgery'),
(93, 'Patients', 'INSERT', '2023-11-22 11:00:00', 'dbo', 'New patient record created: PatientID 5070'),
(94, 'Encounters', 'INSERT', '2023-11-24 07:00:00', 'dbo', 'Inpatient encounter opened: EncounterID 10072'),
(95, 'EncounterServices', 'INSERT', '2023-11-25 10:00:00', 'dbo', 'Added ServiceID 400 to EncounterID 10073'),
(96, 'Billing', 'UPDATE', '2023-11-27 10:00:00', 'dbo', 'Payment received for BillID 7070'),
(97, 'Encounters', 'UPDATE', '2023-11-29 11:00:00', 'dbo', 'EncounterID 10069 status changed to Discharged'),
(98, 'Rooms', 'UPDATE', '2023-11-29 11:05:00', 'dbo', 'RoomID 256 marked as vacant (IsOccupied = 0)'),
(99, 'Patients', 'INSERT', '2023-12-01 09:30:00', 'dbo', 'New patient record created: PatientID 5079'),
(100, 'SystemLogs', 'INSERT', '2023-12-05 16:00:00', 'dbo', 'Section 2 Ingestion Complete: All 11 HIMS tables populated');

SET IDENTITY_INSERT Audit.SystemLogs OFF;
GO

SELECT * FROM Audit.SystemLogs;


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
WHERE s.name = 'Admin'
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
WHERE s.name = 'Clinical'
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
