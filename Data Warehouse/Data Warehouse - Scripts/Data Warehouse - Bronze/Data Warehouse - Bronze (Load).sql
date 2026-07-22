/*

This stored procedure loads data into the 'bronze' schema from external CSV files. 
It truncates the bronze tables before loading data and uses the `BULK INSERT` command 
to load data from csv files to bronze tables. This stored procedure does not accept 
any parameters or return any values.

*/

-- Testing

SELECT * FROM bronze.crm_cust_info;
SELECT COUNT(*) FROM bronze.crm_cust_info;

SELECT * FROM bronze.crm_prd_info;
SELECT COUNT(*) FROM bronze.crm_prd_info;

SELECT * FROM bronze.crm_sales_details;
SELECT COUNT(*) FROM bronze.crm_sales_details;

SELECT * FROM bronze.erp_cust_az12;
SELECT COUNT(*) FROM bronze.erp_cust_az12;

SELECT * FROM bronze.erp_loc_a101;
SELECT COUNT(*) FROM bronze.erp_loc_a101;

SELECT * FROM bronze.erp_px_cat_g1v2;
SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2;

SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	NUMERIC_PRECISION,
	NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_NAME = 'crm_cust_info'
	AND
	TABLE_SCHEMA = 'bronze';

SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	NUMERIC_PRECISION,
	NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_NAME = 'crm_prd_info'
	AND
	TABLE_SCHEMA = 'bronze';

SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	NUMERIC_PRECISION,
	NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_NAME = 'crm_sales_details'
	AND
	TABLE_SCHEMA = 'bronze';

SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	NUMERIC_PRECISION,
	NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_NAME = 'erp_cust_az12'
	AND
	TABLE_SCHEMA = 'bronze';

SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	NUMERIC_PRECISION,
	NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_NAME = 'erp_loc_a101'
	AND
	TABLE_SCHEMA = 'bronze';

SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	NUMERIC_PRECISION,
	NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_NAME = 'erp_px_cat_g1v2'
	AND
	TABLE_SCHEMA = 'bronze';


-- Stored Procedure Implementation

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '============================';
		PRINT 'Loading Bronze Layer';
		PRINT '============================';

		PRINT '----------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '----------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT '>> Inserting Data Into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'G:\My Drive\Vocation\Projects & Practicals\Edna\Data Warehouse\Data Warehouse - Data\Data Warehouse - Data (CRM)\Data Warehouse - CRM (Customers).csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '----------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT '>> Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'G:\My Drive\Vocation\Projects & Practicals\Edna\Data Warehouse\Data Warehouse - Data\Data Warehouse - Data (CRM)\Data Warehouse - CRM (Products).csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '----------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '>> Inserting Data Into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'G:\My Drive\Vocation\Projects & Practicals\Edna\Data Warehouse\Data Warehouse - Data\Data Warehouse - Data (CRM)\Data Warehouse - CRM (Sales Details).csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '----------------------------';

		PRINT '----------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '----------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'G:\My Drive\Vocation\Projects & Practicals\Edna\Data Warehouse\Data Warehouse - Data\Data Warehouse - Data (ERP)\Data Warehouse - ERP (Customers).csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '----------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'G:\My Drive\Vocation\Projects & Practicals\Edna\Data Warehouse\Data Warehouse - Data\Data Warehouse - Data (ERP)\Data Warehouse - ERP (Locations).csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '----------------------------';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'G:\My Drive\Vocation\Projects & Practicals\Edna\Data Warehouse\Data Warehouse - Data\Data Warehouse - Data (ERP)\Data Warehouse - ERP (Categories).csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '----------------------------';

		SET @batch_end_time = GETDATE();
		PRINT '=================================================';
		PRINT 'Loading Bronze Layer is Completed';
		PRINT '	- Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds'
		PRINT '=================================================';

	END TRY
	BEGIN CATCH
		PRINT '=================================================';
		PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '=================================================';
	END CATCH
END

EXEC bronze.load_bronze;
	