/*

This script creates a new database named 'data_warehouse' after checking its existence. 
If the database exists, it is dropped and recreated. Moreover, the script sets up three schemas 
within the database, which are 'bronze', 'silver' and 'gold'.
	
Running this script drops the entire 'data_warehouse' database if it exists. 
Data in the database will be permanently deleted. Proceed with caution 
and ensure you have proper backups before running this script.

*/

USE master; 

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'data_warehouse')
BEGIN
	ALTER DATABASE data_warehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE data_warehouse;
END;
GO

CREATE DATABASE data_warehouse; 

USE data_warehouse;

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver; 
GO

CREATE SCHEMA gold;
GO
