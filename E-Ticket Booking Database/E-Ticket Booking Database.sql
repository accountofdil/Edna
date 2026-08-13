USE eticket_booking_database;
GO

-- DQL Querying: Joins, Aggregations, Subqueries & Window Functions

-- Extract comprehensive event order ledger with venue and customer details

SELECT 
	b.booking_id,
	CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
	u.email,
	e.event_name,
	v.venue_name,
	t.ticket_id,
	bi.unit_price,
	b.status AS booking_status
FROM Sales.Bookings AS b
INNER JOIN Core.Users AS u 
ON b.user_id = u.user_id
INNER JOIN Sales.BookingItems AS bi
ON b.booking_id = bi.booking_id
INNER JOIN Inventory.Tickets AS t
ON bi.ticket_id = t.ticket_id
INNER JOIN Catalog.Events AS e
ON t.event_id = e.event_id
INNER JOIN Catalog.Venues AS v
ON e.venue_id = v.venue_id
WHERE b.status = 'Confirmed'
UNION ALL
SELECT
	b.booking_id,
	CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
	u.email,
	e.event_name,
	v.venue_name,
	t.ticket_id,
	bi.unit_price,
	'AUDIT_REFUND' AS booking_status
FROM Sales.Bookings AS b
INNER JOIN Core.Users AS u
ON b.user_id = u.user_id
INNER JOIN Sales.BookingItems AS bi
ON b.booking_id = bi.booking_id
INNER JOIN Inventory.Tickets AS t
ON bi.ticket_id = t.ticket_id
INNER JOIN Catalog.Events AS e
ON t.event_id = e.event_id
INNER JOIN Catalog.Venues AS v
ON e.venue_id = v.venue_id
WHERE b.status = 'Refunded';
GO

SELECT 
	t.ticket_id,
	t.event_id,
	t.seat_id,
	s.row_number,
	s.seat_number
FROM Inventory.Tickets AS t
LEFT JOIN Inventory.Seats AS s
ON t.seat_id = s.seat_id
WHERE s.seat_id IS NULL;
GO

-- Aggregate venue sales performance and categorise into performance tiers

SELECT 
	v.venue_name,
	v.city,
	COUNT(DISTINCT e.event_id) AS total_events_hosted,
	COUNT(bi.ticket_id) AS total_tickets_sold,
	ISNULL(SUM(bi.unit_price), 0.00) AS gross_revenue,
	ISNULL(AVG(bi.unit_price), 0.00) AS average_ticket_price,
	CASE
		WHEN ISNULL(SUM(bi.unit_price), 0.00) >= 5000.00 THEN 'Tier 1 - High Yield'
		WHEN ISNULL(SUM(bi.unit_price), 0.00) BETWEEN 2000.00 AND 4999.99 THEN 'Tier 2 - Mid Yield'
		ELSE 'Tier 3 - Emerging'
	END AS venue_performance_category
FROM Catalog.Venues AS v
LEFT JOIN Catalog.Events AS e 
ON v.venue_id = e.venue_id
LEFT JOIN Inventory.Tickets AS t
ON e.event_id = t.event_id
LEFT JOIN Sales.BookingItems AS bi
ON t.ticket_id = bi.ticket_id
GROUP BY 
	v.venue_id, 
	v.venue_name, 
	v.city
HAVING COUNT(bi.ticket_id) > 0
ORDER BY gross_revenue DESC;
GO

SELECT 
	(SELECT SUM(unit_price) FROM Sales.BookingItems) AS item_level_total,
	(SELECT SUM(total_amount) FROM Sales.Bookings WHERE status IN ('Confirmed', 'Refunded')) AS header_level_total,
	CASE
		WHEN (SELECT SUM(unit_price) FROM Sales.BookingItems) = 
			 (SELECT SUM(total_amount) FROM Sales.Bookings WHERE status IN ('Confirmed', 'Refunded'))
		THEN 'Balanced'
		ELSE 'Discrepancy Detected'
	END AS status_check;
GO

-- Calculate user purchase metrics against platform-wide benchmarks

WITH UserSpendSummary AS (
	SELECT 
		u.user_id,
		CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
		u.email,
		COUNT(b.booking_id) AS total_orders,
		SUM(b.total_amount) AS total_lifetime_spend
	FROM Core.Users AS u
	INNER JOIN Sales.Bookings AS b
	ON u.user_id = b.user_id
	WHERE b.status = 'Confirmed'
	GROUP BY
		u.user_id,
		u.first_name,
		u.last_name,
		u.email
),
PlatformBenchmark AS (
	SELECT
		AVG(total_lifetime_spend) AS average_customer_spend
	FROM UserSpendSummary
)
SELECT
	us.user_id,
	us.customer_name,
	us.email,
	us.total_orders,
	us.total_lifetime_spend,
	pb.average_customer_spend,
	ROUND(us.total_lifetime_spend - pb.average_customer_spend, 2) AS spend_above_average
FROM UserSpendSummary AS us
CROSS JOIN PlatformBenchmark AS pb
WHERE us.total_lifetime_spend > pb.average_customer_spend
ORDER BY us.total_lifetime_spend DESC;
GO

SELECT COUNT(*) AS high_value_user_count
FROM Core.Users AS u
WHERE EXISTS (
	SELECT 1
	FROM Sales.Bookings AS b
	WHERE b.user_id = u.user_id
	GROUP BY b.user_id
	HAVING SUM(b.total_amount) > 
		   (SELECT AVG(user_total) FROM 
		   (SELECT SUM(total_amount) AS user_total
		    FROM Sales.Bookings
			WHERE status = 'Confirmed'
			GROUP BY user_id) AS sub)
			);
GO

-- Evaluate user purchase velocity and running totals

SELECT 
	b.user_id,
	b.booking_id,
	b.booking_date,
	b.total_amount,
	ROW_NUMBER() OVER(PARTITION BY b.user_id ORDER BY b.booking_date ASC) AS user_order_sequence,
	DENSE_RANK() OVER(ORDER BY b.total_amount DESC) AS global_amount_rank,
	LAG(b.total_amount, 1, 0.00) OVER(PARTITION BY b.user_id ORDER BY b.booking_date ASC) AS previous_booking_amount,
	LEAD(b.total_amount, 1, 0.00) OVER(PARTITION BY b.user_id ORDER BY b.booking_date ASC) AS next_booking_amount,
	SUM(b.total_amount) OVER(PARTITION BY b.user_id ORDER BY b.booking_date ASC 
							 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_user_spend
FROM Sales.Bookings AS b
WHERE b.status = 'Confirmed'
ORDER BY 
	b.user_id,
	user_order_sequence;
GO

WITH WindowTest AS (
	SELECT
		user_id,
		total_amount,
		SUM(total_amount) OVER(PARTITION BY user_id ORDER BY booking_date ASC
							   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
		ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY booking_date DESC) AS rn
	FROM Sales.Bookings
	WHERE status = 'Confirmed'
)
SELECT
	wt.user_id,
	wt.running_total AS final_window_running_total,
	s.actual_total,
	CASE
		WHEN wt.running_total = s.actual_total THEN 'Passed'
		ELSE 'Failed'
	END AS test_result
FROM WindowTest AS wt
INNER JOIN (
	SELECT 
		user_id, 
		SUM(total_amount) AS actual_total
	FROM Sales.Bookings
	WHERE status = 'Confirmed'
	GROUP BY user_id) AS s
ON wt.user_id = s.user_id
WHERE wt.rn = 1;
GO


-- Database Programmability & Storage Objects

-- Create or alter view for real-time event sales and inventory tracking

CREATE OR ALTER VIEW Catalog.vw_EventSalesSummary
AS
SELECT 
	e.event_id,
	e.event_name,
	c.category_name,
	v.venue_name,
	v.city,
	e.start_time,
	e.status AS event_status,
	COUNT(t.ticket_id) AS total_inventory_tickets,
	SUM(CASE WHEN t.status = 'Sold' THEN 1 ELSE 0 END) AS tickets_sold,
	SUM(CASE WHEN t.status = 'Reserved' THEN 1 ELSE 0 END) AS tickets_reserved,
	SUM(CASE WHEN t.status = 'Available' THEN 1 ELSE 0 END) AS tickets_available,
	ISNULL(SUM(CASE WHEN t.status = 'Sold' THEN t.price ELSE 0 END), 0.00) AS gross_revenue_collected,
	ROUND(CASE
			WHEN COUNT(t.ticket_id) > 0
			THEN (CAST(SUM(CASE WHEN t.status = 'Sold' THEN 1 ELSE 0 END) AS DECIMAL(10, 2)) / COUNT(t.ticket_id)) * 100
			ELSE 0
		  END, 2) AS occupancy_percentage  
FROM Catalog.Events AS e
INNER JOIN Catalog.Categories AS c
ON e.category_id = c.category_id
INNER JOIN Catalog.Venues AS v
ON e.venue_id = v.venue_id
LEFT JOIN Inventory.Tickets AS t
ON e.event_id = t.event_id
GROUP BY
	e.event_id,
	e.event_name,
	c.category_name,
	v.venue_name,
	v.city,
	e.start_time,
	e.status;
GO

SELECT * 
FROM Catalog.vw_EventSalesSummary
ORDER BY gross_revenue_collected DESC;
GO

-- Filter index on event venue and schedule
-- Non-clustered index on customer order dates and user ID
-- Covered index for ticket status and event lookups

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Events_Venue_Start')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Events_Venue_Start
	ON Catalog.Events (venue_id, start_time)
	INCLUDE (event_name, status);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Bookings_User_Status')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Bookings_User_Status
	ON Sales.Bookings (user_id, status)
	INCLUDE (total_amount, booking_date);
END;
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Tickets_Event_Status')
BEGIN
	CREATE NONCLUSTERED INDEX IX_Tickets_Event_Status
	ON Inventory.Tickets (event_id, status)
	INCLUDE (price, seat_id);
END;
GO

SELECT 
	s.name AS schema_name,
	t.name AS table_name,
	i.name AS index_name,
	i.type_desc AS index_type,
	i.is_unique
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
ON i.object_id = t.object_id
INNER JOIN sys.schemas AS s
ON t.schema_id = s.schema_id
WHERE i.name LIKE 'IX_%'
ORDER BY 
	s.name, 
	t.name;
GO

-- Scalar User-Defined Function (UDF)
-- Return total count of unsold available tickets for a specific event

DROP FUNCTION IF EXISTS Inventory.fn_GetEventAvailableSeatCount;
GO
CREATE OR ALTER FUNCTION Inventory.fn_GetEventAvailableSeatCount (@event_id INT)
RETURNS INT
AS 
BEGIN
	DECLARE @available_count INT;
	SELECT @available_count = COUNT(*)
	FROM Inventory.Tickets
	WHERE 
		event_id = @event_id
		AND
		status = 'Available';
	RETURN ISNULL(@available_count, 0);
END;
GO

SELECT
	event_id,
	event_name,
	Inventory.fn_GetEventAvailableSeatCount(event_id) AS total_available_seats
FROM Catalog.Events

-- Inline Table-Valued Function (ITVF)
-- Return detailed booking history for a specific customer

DROP FUNCTION IF EXISTS Sales.fn_GetUserBookingHistory;
GO
CREATE OR ALTER FUNCTION Sales.fn_GetUserBookingHistory (@user_id INT)
RETURNS TABLE
AS 
RETURN
	(SELECT 
		b.booking_id,
		b.booking_date,
		b.status AS booking_status,
		b.total_amount,
		COUNT(bi.ticket_id) AS ticket_count,
		p.payment_method,
		p.status AS payment_status
	 FROM Sales.Bookings AS b
	 LEFT JOIN Sales.BookingItems AS bi
	 ON b.booking_id = bi.booking_id
	 LEFT JOIN Sales.Payments AS p
	 ON b.booking_id = p.booking_id
	 WHERE b.user_id = @user_id
	 GROUP BY
		b.booking_id,
		b.booking_date,
		b.status,
		b.total_amount,
		p.payment_method,
		p.status);
GO

SELECT * 
FROM Sales.fn_GetUserBookingHistory(1);
GO

-- Transactional Stored Procedure
-- Create and process a new ticket booking

DROP PROCEDURE IF EXISTS Sales.sp_CreateBooking;
GO
CREATE OR ALTER PROCEDURE Sales.sp_CreateBooking (@user_id INT,
												  @ticket_id INT,
												  @payment_method VARCHAR(30),
												  @new_booking_id INT OUTPUT)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ticket_status VARCHAR(20);
	DECLARE @ticket_price DECIMAL(10, 2);

	SELECT
		@ticket_status = status,
		@ticket_price = price
	FROM Inventory.Tickets
	WHERE ticket_id = @ticket_id

	IF @ticket_status IS NULL
	BEGIN
		RAISERROR('Error: Selected ticket is no longer available for purchase', 16, 1);
		RETURN;
	END;

	BEGIN TRANSACTION;

	BEGIN TRY
		
		INSERT INTO Sales.Bookings (user_id, booking_date, total_amount, status)
		VALUES (@user_id, GETDATE(), @ticket_price, 'Confirmed');

		SET @new_booking_id = SCOPE_IDENTITY();

		INSERT INTO Sales.BookingItems (booking_id, ticket_id, unit_price)
		VALUES (@new_booking_id, @ticket_id, @ticket_price);

		INSERT INTO Sales.Payments (booking_id, amount, payment_method, payment_date, status)
		VALUES (@new_booking_id, @ticket_price, @payment_method, GETDATE(), 'Completed')

		UPDATE Inventory.Tickets
		SET status = 'Sold'
		WHERE ticket_id = @ticket_id;

		COMMIT TRANSACTION;
		PRINT 'Booking successfully completed. Booking ID: ' + CAST(@new_booking_id AS VARCHAR(10));

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		RAISERROR(@ErrorMessage, 16, 1);

	END CATCH;
END;
GO

INSERT INTO Inventory.Tickets (event_id, seat_id, price, status) 
VALUES
(1, 21, 250.00, 'Available'),
(1, 22, 250.00, 'Available'),
(1, 23, 250.00, 'Available'),
(1, 24, 250.00, 'Available'),
(1, 25, 250.00, 'Available'),
(1, 26, 250.00, 'Available'),
(1, 27, 250.00, 'Available'),
(1, 28, 250.00, 'Available'),
(1, 29, 250.00, 'Available'),
(1, 30, 250.00, 'Available');
GO

SELECT TOP 1
	t.ticket_id,
	t.event_id,
	t.price,
	t.status
FROM Inventory.Tickets AS t
LEFT JOIN Sales.BookingItems AS bi
ON t.ticket_id = bi.ticket_id
WHERE 
	t.status = 'Available'
	AND 
	bi.ticket_id IS NULL;
GO

DECLARE @created_id INT;

EXEC Sales.sp_CreateBooking
	@user_id = 5,
	@ticket_id = 101,
	@payment_method = 'Credit Card',
	@new_booking_id = @created_id OUTPUT;

DECLARE @created_id INT;
SELECT * FROM Sales.Bookings 
WHERE booking_id = @created_id;

DECLARE @created_id INT;
SELECT * FROM Sales.BookingItems 
WHERE booking_id = @created_id;

DECLARE @created_id INT;
SELECT * FROM Sales.Payments
WHERE booking_id = @created_id;

SELECT * FROM Inventory.Tickets
WHERE ticket_id = 101;

-- Trigger
-- Handle order status and inventory release upon payment refund

DROP TRIGGER IF EXISTS Sales.trg_Payments_AfterUpdate;
GO
CREATE OR ALTER TRIGGER Sales.trg_Payments_AfterUpdate
ON Sales.Payments
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF UPDATE(status)
	BEGIN
		UPDATE b
		SET b.status = 'Refunded'
		FROM Sales.Bookings AS b
		INNER JOIN inserted AS i
		ON b.booking_id = i.booking_id
		WHERE i.status = 'Refunded';

		UPDATE t
		SET t.status = 'Available'
		FROM Inventory.Tickets AS t
		INNER JOIN Sales.BookingItems AS bi
		ON t.ticket_id = bi.ticket_id
		INNER JOIN inserted AS i
		ON bi.booking_id = i.booking_id
		WHERE i.status = 'Refunded';
	END;
END;
GO

UPDATE Sales.Payments
SET status = 'Refunded'
WHERE booking_id = 1;
GO

SELECT
	booking_id,
	status
FROM Sales.Bookings
WHERE booking_id = 1;
GO

SELECT 
	t.ticket_id,
	t.status
FROM Inventory.Tickets AS t
INNER JOIN Sales.BookingItems AS bi
ON t.ticket_id = bi.ticket_id
WHERE bi.booking_id = 1;
GO


-- Transactions, Concurrency, Security & Query Optimisation

-- Transaction involving savepoints for conditional partial rollback

BEGIN TRANSACTION MultiItemBooking;

BEGIN TRY
	
	INSERT INTO Sales.Bookings (user_id, booking_date, total_amount, status)
	VALUES (10, GETDATE(), 250.00, 'Confirmed');

	DECLARE @new_booking_id INT = SCOPE_IDENTITY();

	SAVE TRANSACTION AddOnSavepoint;

	INSERT INTO Sales.BookingItems (booking_id, ticket_id, unit_price)
	VALUES (@new_booking_id, 102, 250.00);

	IF EXISTS (SELECT 1 FROM Sales.BookingItems WHERE ticket_id = 102 AND booking_id <> @new_booking_id)
	BEGIN
		PRINT 'Add-on ticket unavailable. Rolling back add-on item only';
		ROLLBACK TRANSACTION AddOnSavepoint;
	END;

	UPDATE Inventory.Tickets 
	SET status = 'Sold'
	WHERE ticket_id = 102;

	COMMIT TRANSACTION MultiItemBooking;
	PRINT 'Transaction committed successfully';

END TRY

BEGIN CATCH

	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION MultiItemBooking;

	DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
	RAISERROR(@ErrorMessage, 16, 1);

END CATCH;
GO

SELECT TOP 1
	booking_id,
	user_id,
	booking_date,
	total_amount,
	status
FROM Sales.Bookings
ORDER BY booking_id DESC;
GO

-- Transaction isolation levels and locking to control concurrency

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
GO

BEGIN TRANSACTION InventoryCheckout;

SELECT 
	ticket_id,
	event_id,
	price,
	status
FROM Inventory.Tickets WITH (UPDLOCK, ROWLOCK)
WHERE 
	ticket_id = 103
	AND 
	status = 'Available';

UPDATE Inventory.Tickets
SET status = 'Reserved'
WHERE ticket_id = 103;

COMMIT TRANSACTION InventoryCheckout;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

SELECT
	session_id,
	CASE transaction_isolation_level
		WHEN 0 THEN 'Unspecified'
		WHEN 1 THEN 'ReadUncommitted'
		WHEN 2 THEN 'ReadCommitted'
		WHEN 3 THEN 'RepeatableRead'
		WHEN 4 THEN 'Serialisable'
		WHEN 5 THEN 'Snapshot'
	END AS current_isolation_level
FROM sys.dm_exec_sessions 
WHERE session_id = @@SPID;
GO

-- Role-based access control for isolating permissions across schemas 

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_analyst_role')
	CREATE ROLE db_analyst_role;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_agent_role')
	CREATE ROLE db_agent_role;
GO

GRANT SELECT ON SCHEMA::Sales TO db_analyst_role;
GRANT SELECT ON SCHEMA::Catalog TO db_analyst_role;
GRANT EXECUTE ON OBJECT::Sales.sp_CreateBooking TO db_agent_role;
GRANT SELECT, UPDATE ON Inventory.Tickets TO db_agent_role;
REVOKE DELETE ON SCHEMA::Sales FROM db_agent_role;
GO

SELECT
	dp.name AS role_name,
	pe.permission_name,
	pe.state_desc AS permission_state,
	pe.class_desc AS object_class,
	OBJECT_NAME(pe.major_id) AS object_name
FROM sys.database_permissions AS pe
INNER JOIN sys.database_principals AS dp
ON pe.grantee_principal_id = dp.principal_id
WHERE dp.name IN ('db_analyst_role', 'db_agent_role')
ORDER BY dp.name;
GO

-- Performance impact of Search Argument Able (SARGable) predicate design

SELECT 
	booking_id,
	user_id,
	total_amount,
	booking_date
FROM Sales.Bookings
WHERE 
	booking_date >= '2026-01-01 00:00:00'
	AND 
	booking_date < '2027-01-01 00:00:00';
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
	booking_id,
	total_amount
FROM Sales.Bookings
WHERE
	booking_date >= '2026-05-01'
	AND 
	booking_date < '2026-06-01';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
