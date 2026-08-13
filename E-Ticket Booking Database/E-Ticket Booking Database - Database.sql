-- Database Creation

USE master;
GO

ALTER DATABASE eticket_booking_database
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE IF EXISTS eticket_booking_database;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'eticket_booking_database')
BEGIN
	CREATE DATABASE eticket_booking_database;
END;
GO

USE eticket_booking_database;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Core')
	EXEC('CREATE SCHEMA Core;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Catalog')
	EXEC('CREATE SCHEMA Catalog;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Inventory')
	EXEC('CREATE SCHEMA Inventory;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Sales')
	EXEC('CREATE SCHEMA Sales;');
GO

DROP TABLE IF EXISTS Core.Users;
CREATE TABLE Core.Users(
					user_id INT IDENTITY(1, 1) PRIMARY KEY,
					email VARCHAR(100) NOT NULL UNIQUE,
					first_name VARCHAR(50) NOT NULL,
					last_name VARCHAR(50) NOT NULL,
					phone VARCHAR(20) NULL,
					created_at DATETIME2 NOT NULL DEFAULT GETDATE());
GO

DROP TABLE IF EXISTS Catalog.Categories;
CREATE TABLE Catalog.Categories(
							category_id INT IDENTITY(1, 1) PRIMARY KEY,
							category_name VARCHAR(50) NOT NULL UNIQUE,
							description VARCHAR(255) NULL);
GO

DROP TABLE IF EXISTS Catalog.Venues;
CREATE TABLE Catalog.Venues(
						venue_id INT IDENTITY(1, 1) PRIMARY KEY,
						venue_name VARCHAR(100) NOT NULL,
						city VARCHAR(50) NOT NULL,
						state VARCHAR(50) NULL,
						postal_code VARCHAR(20) NULL,
						total_capacity INT NOT NULL CHECK (total_capacity > 0));
GO

DROP TABLE IF EXISTS Catalog.Performers;
CREATE TABLE Catalog.Performers(
							performer_id INT IDENTITY(1, 1) PRIMARY KEY,
							name VARCHAR(100) NOT NULL,
							genre_or_type VARCHAR(50) NULL);
GO

DROP TABLE IF EXISTS Catalog.Events;
CREATE TABLE Catalog.Events(
						event_id INT IDENTITY(1, 1) PRIMARY KEY,
						venue_id INT NOT NULL FOREIGN KEY REFERENCES Catalog.Venues(venue_id),
						category_id INT NOT NULL FOREIGN KEY REFERENCES Catalog.Categories(category_id),
						event_name VARCHAR(150) NOT NULL,
						start_time DATETIME2 NOT NULL,
						end_time DATETIME2 NOT NULL,
						status VARCHAR(20) NOT NULL DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'Postponed')),
						CONSTRAINT CK_event_times CHECK (end_time > start_time));
GO

DROP TABLE IF EXISTS Catalog.EventPerformers;
CREATE TABLE Catalog.EventPerformers(
									event_id INT NOT NULL FOREIGN KEY REFERENCES Catalog.Events(event_id),
									performer_id INT NOT NULL FOREIGN KEY REFERENCES Catalog.Performers(performer_id),
									performance_order INT DEFAULT 1 CHECK (performance_order > 0),
									PRIMARY KEY (event_id, performer_id));
GO

DROP TABLE IF EXISTS Inventory.SeatSections;
CREATE TABLE Inventory.SeatSections(
								section_id INT IDENTITY(1, 1) PRIMARY KEY,
								venue_id INT NOT NULL FOREIGN KEY REFERENCES Catalog.Venues(venue_id),
								section_name VARCHAR(50) NOT NULL,
								base_price_tier DECIMAL(10, 2) NOT NULL CHECK (base_price_tier >= 0));
GO

DROP TABLE IF EXISTS Inventory.Seats;
CREATE TABLE Inventory.Seats(
							seat_id INT IDENTITY(1, 1) PRIMARY KEY,
							section_id INT NOT NULL FOREIGN KEY REFERENCES Inventory.SeatSections(section_id),
							row_number VARCHAR(10) NOT NULL,
							seat_number INT NOT NULL CHECK (seat_number > 0),
							CONSTRAINT UQ_seat_location UNIQUE (section_id, row_number, seat_number));
GO

DROP TABLE IF EXISTS Inventory.Tickets;
CREATE TABLE Inventory.Tickets(
							ticket_id INT IDENTITY(1, 1) PRIMARY KEY,
							event_id INT NOT NULL FOREIGN KEY REFERENCES Catalog.Events(event_id),
							seat_id INT NOT NULL FOREIGN KEY REFERENCES Inventory.Seats(seat_id),
							price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
							status VARCHAR(20) NOT NULL DEFAULT 'Available' CHECK (status IN ('Available', 'Reserved', 'Sold')),
							CONSTRAINT UQ_event_seat UNIQUE (event_id, seat_id));
GO

DROP TABLE IF EXISTS Sales.Bookings;
CREATE TABLE Sales.Bookings(
						booking_id INT IDENTITY(1, 1) PRIMARY KEY,
						user_id INT NOT NULL FOREIGN KEY REFERENCES Core.Users(user_id),
						booking_date DATETIME2 NOT NULL DEFAULT GETDATE(),
						total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
						status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Confirmed', 'Cancelled', 'Refunded')));
GO

DROP TABLE IF EXISTS Sales.BookingItems;
CREATE TABLE Sales.BookingItems(
							booking_id INT NOT NULL FOREIGN KEY REFERENCES Sales.Bookings(booking_id),
							ticket_id INT NOT NULL UNIQUE FOREIGN KEY REFERENCES Inventory.Tickets(ticket_id),
							unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
							PRIMARY KEY (booking_id, ticket_id));
GO

DROP TABLE IF EXISTS Sales.Payments;
CREATE TABLE Sales.Payments(
						payment_id INT IDENTITY(1, 1) PRIMARY KEY,
						booking_id INT NOT NULL FOREIGN KEY REFERENCES Sales.Bookings(booking_id),
						amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
						payment_method VARCHAR(30) NOT NULL CHECK (payment_method IN ('Credit Card', 'Debit Card', 'PayPal', 'Gift Card')),
						payment_date DATETIME2 NOT NULL DEFAULT GETDATE(),
						status VARCHAR(20) NOT NULL DEFAULT 'Completed' CHECK (status IN ('Pending', 'Completed', 'Failed', 'Refunded')));
GO


-- Data Loading & Integration

INSERT INTO Catalog.Categories (category_name, description) 
VALUES
('Concert', 'Live music performances, music festivals, and arena tours'),
('Sports', 'Professional athletic competitions, leagues, and tournaments'),
('Theater', 'Broadways, stage plays, musicals, and dramatic performances'),
('Comedy', 'Stand-up comedy tours, improv shows, and special tapings'),
('Conference', 'Industry conventions, tech summits, and corporate keynotes'),
('Exhibition', 'Art museum galleries, cultural exhibits, and expos'),
('Family & Kids', 'Children theater, magic shows, and family entertainment'),
('E-Sports', 'Competitive video gaming leagues and global championships'),
('Opera & Ballet', 'Classical opera performances and ballet productions'),
('Festival', 'Multi-day outdoor arts, culture, and food festivals'),
('Motorsports', 'Formula racing, rally events, and motor shows'),
('Combat Sports', 'Mixed martial arts, boxing matches, and wrestling');
GO

SELECT * FROM Catalog.Categories;

INSERT INTO Catalog.Venues (venue_name, city, state, postal_code, total_capacity) 
VALUES
('Madison Square Garden', 'New York', 'NY', '10001', 20000),
('Red Rocks Amphitheatre', 'Morrison', 'CO', '80465', 9525),
('The O2 Arena', 'London', NULL, 'SE10 0DX', 20000),
('Crypto.com Arena', 'Los Angeles', 'CA', '90015', 19067),
('Radio City Music Hall', 'New York', 'NY', '10020', 6015),
('TD Garden', 'Boston', 'MA', '02114', 19580),
('United Center', 'Chicago', 'IL', '60612', 23500),
('Wembley Stadium', 'London', NULL, 'HA9 0WS', 90000),
('Sydney Opera House', 'Sydney', NULL, 'NSW 2000', 5738),
('Spherical Arena', 'Las Vegas', 'NV', '89109', 18600),
('Accor Arena', 'Paris', NULL, '75012', 20300),
('Mercedes-Benz Stadium', 'Atlanta', 'GA', '30313', 71000),
('Red Bull Arena', 'Harrison', 'NJ', '07029', 25000),
('Ryman Auditorium', 'Nashville', 'TN', '37219', 2362),
('Hollywood Bowl', 'Los Angeles', 'CA', '90068', 17500);
GO

SELECT * FROM Catalog.Venues;

INSERT INTO Catalog.Performers (name, genre_or_type) 
VALUES
('The Cosmic Echoes', 'Rock'),
('Sarah Jenkins', 'Stand-Up Comedy'),
('Metropolitan Symphony', 'Classical Orchestra'),
('Apex Predators', 'Esports Team'),
('Elena Rostova', 'Ballet'),
('Quantum Bytes', 'Tech Keynote'),
('The Beat Collective', 'Hip Hop'),
('Urban Groove', 'Jazz'),
('Neon Horizon', 'Synthwave'),
('The Royal Shakespeare Co.', 'Theater'),
('New York Strikers', 'Soccer'),
('Chicago Hoops', 'Basketball'),
('David Vance', 'Illusionist'),
('Luna & The Waves', 'Indie Pop'),
('Thunderbolts MMA', 'Combat Sports'),
('Dr. Aris Thorne', 'AI & Science Keynote'),
('Velocity Racing Team', 'Motorsports'),
('Opera National Ensemble', 'Opera'),
('Marcus ' + CHAR(39) + 'The Titan' + CHAR(39) + ' Stone', 'Boxing'),
('Acoustic Sunset', 'Folk'),
('The Laugh Factory Troupe', 'Improv Comedy'),
('London Symphony Chorus', 'Choral Classical'),
('Starlight Circus', 'Family Entertainment'),
('Cyber Warriors', 'Esports Team'),
('Symphonic Metalheads', 'Heavy Metal'),
('Broadway Revival Cast', 'Musical Theater'),
('DJ Pulse', 'Electronic Dance'),
('Global Economic Forum Speaker', 'Conference Keynote'),
('Rhythm Tap Company', 'Dance'),
('Pacific Coast Big Band', 'Swing & Jazz');
GO

SELECT * FROM Catalog.Performers;

INSERT INTO Core.Users (email, first_name, last_name, phone, created_at) 
VALUES
('alice.smith@example.com', 'Alice', 'Smith', '555-0101', '2025-01-15 08:30:00'),
('bob.jones@example.com', 'Bob', 'Jones', '555-0102', '2025-01-18 11:45:00'),
('charlie.brown@example.com', 'Charlie', 'Brown', '555-0103', '2025-02-01 14:15:00'),
('diana.prince@example.com', 'Diana', 'Prince', '555-0104', '2025-02-10 09:20:00'),
('evan.wright@example.com', 'Evan', 'Wright', '555-0105', '2025-02-22 16:50:00'),
('fiona.gallagher@example.com', 'Fiona', 'Gallagher', '555-0106', '2025-03-01 10:05:00'),
('george.miller@example.com', 'George', 'Miller', '555-0107', '2025-03-05 13:40:00'),
('hannah.abbott@example.com', 'Hannah', 'Abbott', '555-0108', '2025-03-12 17:15:00'),
('ian.malcolm@example.com', 'Ian', 'Malcolm', '555-0109', '2025-03-20 12:00:00'),
('julia.roberts@example.com', 'Julia', 'Roberts', '555-0110', '2025-03-25 15:30:00'),
('kevin.bacon@example.com', 'Kevin', 'Bacon', '555-0111', '2025-04-02 08:10:00'),
('laura.croft@example.com', 'Laura', 'Croft', '555-0112', '2025-04-05 19:25:00'),
('michael.scott@example.com', 'Michael', 'Scott', '555-0113', '2025-04-12 10:40:00'),
('nina.williams@example.com', 'Nina', 'Williams', '555-0114', '2025-04-18 14:00:00'),
('oscar.martinez@example.com', 'Oscar', 'Martinez', '555-0115', '2025-04-22 11:15:00'),
('peter.parker@example.com', 'Peter', 'Parker', '555-0116', '2025-05-01 16:20:00'),
('quinn.fabray@example.com', 'Quinn', 'Fabray', '555-0117', '2025-05-04 09:05:00'),
('rachel.green@example.com', 'Rachel', 'Green', '555-0118', '2025-05-11 13:50:00'),
('sam.winchester@example.com', 'Sam', 'Winchester', '555-0119', '2025-05-15 20:30:00'),
('tina.fey@example.com', 'Tina', 'Fey', '555-0120', '2025-05-20 07:45:00'),
('uma.thurman@example.com', 'Uma', 'Thurman', '555-0121', '2025-06-01 12:10:00'),
('victor.vance@example.com', 'Victor', 'Vance', '555-0122', '2025-06-05 15:00:00'),
('wendy.testaburger@example.com', 'Wendy', 'Testaburger', '555-0123', '2025-06-10 18:20:00'),
('xavier.woods@example.com', 'Xavier', 'Woods', '555-0124', '2025-06-18 10:05:00'),
('yara.shahidi@example.com', 'Yara', 'Shahidi', '555-0125', '2025-06-25 14:40:00'),
('zack.morris@example.com', 'Zack', 'Morris', '555-0126', '2025-07-02 09:30:00'),
('aaron.paul@example.com', 'Aaron', 'Paul', '555-0127', '2025-07-08 11:15:00'),
('beth.phoenix@example.com', 'Beth', 'Phoenix', '555-0128', '2025-07-12 17:00:00'),
('carl.grimes@example.com', 'Carl', 'Grimes', '555-0129', '2025-07-19 13:25:00'),
('david.beckham@example.com', 'David', 'Beckham', '555-0130', '2025-07-28 08:50:00'),
('emma.watson@example.com', 'Emma', 'Watson', '555-0131', '2025-08-01 10:10:00'),
('frank.castle@example.com', 'Frank', 'Castle', '555-0132', '2025-08-05 16:40:00'),
('grace.hopper@example.com', 'Grace', 'Hopper', '555-0133', '2025-08-11 12:00:00'),
('harry.potter@example.com', 'Harry', 'Potter', '555-0134', '2025-08-15 19:15:00'),
('iris.west@example.com', 'Iris', 'West', '555-0135', '2025-08-22 09:00:00'),
('jack.sparrow@example.com', 'Jack', 'Sparrow', '555-0136', '2025-09-01 14:30:00'),
('katie.holmes@example.com', 'Katie', 'Holmes', '555-0137', '2025-09-04 11:20:00'),
('luke.skywalker@example.com', 'Luke', 'Skywalker', '555-0138', '2025-09-10 15:45:00'),
('mia.thermapolis@example.com', 'Mia', 'Thermapolis', '555-0139', '2025-09-18 08:05:00'),
('neil.armstrong@example.com', 'Neil', 'Armstrong', '555-0140', '2025-09-25 18:10:00'),
('olivia.pope@example.com', 'Olivia', 'Pope', '555-0141', '2025-10-02 10:25:00'),
('paul.rudd@example.com', 'Paul', 'Rudd', '555-0142', '2025-10-08 13:00:00'),
('queen.latifah@example.com', 'Queen', 'Latifah', '555-0143', '2025-10-14 16:15:00'),
('ron.weasley@example.com', 'Ron', 'Weasley', '555-0144', '2025-10-20 09:40:00'),
('sarah.connor@example.com', 'Sarah', 'Connor', '555-0145', '2025-10-28 12:50:00'),
('tony.stark@example.com', 'Tony', 'Stark', '555-0146', '2025-11-03 11:00:00'),
('ursula.buffay@example.com', 'Ursula', 'Buffay', '555-0147', '2025-11-09 15:35:00'),
('vince.mcmahon@example.com', 'Vince', 'McMahon', '555-0148', '2025-11-15 17:20:00'),
('wanda.maximoff@example.com', 'Wanda', 'Maximoff', '555-0149', '2025-11-22 08:30:00'),
('xena.warrior@example.com', 'Xena', 'Warrior', '555-0150', '2025-11-29 14:10:00'),
('yena.lee@example.com', 'Yena', 'Lee', '555-0151', '2025-12-02 10:00:00'),
('zane.truesdale@example.com', 'Zane', 'Truesdale', '555-0152', '2025-12-08 16:45:00'),
('amber.heard@example.com', 'Amber', 'Heard', '555-0153', '2025-12-12 11:30:00'),
('bruce.wayne@example.com', 'Bruce', 'Wayne', '555-0154', '2025-12-18 19:00:00'),
('clark.kent@example.com', 'Clark', 'Kent', '555-0155', '2025-12-23 09:15:00'),
('diana.ross@example.com', 'Diana', 'Ross', '555-0156', '2025-12-28 13:40:00'),
('edward.elric@example.com', 'Edward', 'Elric', '555-0157', '2026-01-02 15:20:00'),
('felicity.smoak@example.com', 'Felicity', 'Smoak', '555-0158', '2026-01-07 08:45:00'),
('gordon.ramsay@example.com', 'Gordon', 'Ramsay', '555-0159', '2026-01-12 12:10:00'),
('holly.willoughby@example.com', 'Holly', 'Willoughby', '555-0160', '2026-01-18 17:50:00'),
('isacc.newton@example.com', 'Isaac', 'Newton', '555-0161', '2026-01-24 10:30:00'),
('john.wick@example.com', 'John', 'Wick', '555-0162', '2026-01-29 14:05:00'),
('katniss.everdeen@example.com', 'Katniss', 'Everdeen', '555-0163', '2026-02-03 09:25:00'),
('logan.howlett@example.com', 'Logan', 'Howlett', '555-0164', '2026-02-08 16:00:00'),
('mary.jane@example.com', 'Mary', 'Jane', '555-0165', '2026-02-14 11:15:00'),
('norman.osborn@example.com', 'Norman', 'Osborn', '555-0166', '2026-02-19 13:50:00'),
('oliver.queen@example.com', 'Oliver', 'Queen', '555-0167', '2026-02-25 18:30:00'),
('pam.beesly@example.com', 'Pam', 'Beesly', '555-0168', '2026-03-01 10:10:00'),
('quentin.tarantino@example.com', 'Quentin', 'Tarantino', '555-0169', '2026-03-05 15:40:00'),
('riley.reid@example.com', 'Riley', 'Reid', '555-0170', '2026-03-10 12:20:00'),
('steve.rogers@example.com', 'Steve', 'Rogers', '555-0171', '2026-03-15 08:00:00'),
('todd.howard@example.com', 'Todd', 'Howard', '555-0172', '2026-03-20 17:15:00'),
('ulysse.grant@example.com', 'Ulysses', 'Grant', '555-0173', '2026-03-25 11:05:00'),
('violet.parr@example.com', 'Violet', 'Parr', '555-0174', '2026-03-30 14:30:00'),
('walter.white@example.com', 'Walter', 'White', '555-0175', '2026-04-03 09:50:00'),
('xander.cage@example.com', 'Xander', 'Cage', '555-0176', '2026-04-08 16:10:00'),
('yennifer.vengerberg@example.com', 'Yennefer', 'Vengerberg', '555-0177', '2026-04-12 13:25:00'),
('zelda.hyrule@example.com', 'Zelda', 'Hyrule', '555-0178', '2026-04-17 10:40:00'),
('arthur.pendragon@example.com', 'Arthur', 'Pendragon', '555-0179', '2026-04-22 15:00:00'),
('bilbo.baggins@example.com', 'Bilbo', 'Baggins', '555-0180', '2026-04-26 12:35:00'),
('catelyn.stark@example.com', 'Catelyn', 'Stark', '555-0181', '2026-05-01 08:15:00'),
('daenerys.targaryen@example.com', 'Daenerys', 'Targaryen', '555-0182', '2026-05-05 17:45:00'),
('eowyn.rohan@example.com', 'Eowyn', 'Rohan', '555-0183', '2026-05-09 11:20:00'),
('frodo.baggins@example.com', 'Frodo', 'Baggins', '555-0184', '2026-05-13 14:50:00'),
('gandalf.grey@example.com', 'Gandalf', 'Grey', '555-0185', '2026-05-18 10:05:00'),
('hermione.granger@example.com', 'Hermione', 'Granger', '555-0186', '2026-05-22 16:30:00'),
('inigo.montoya@example.com', 'Inigo', 'Montoya', '555-0187', '2026-05-26 13:10:00'),
('jon.snow@example.com', 'Jon', 'Snow', '555-0188', '2026-05-30 09:40:00'),
('khal.drogo@example.com', 'Khal', 'Drogo', '555-0189', '2026-06-03 15:15:00'),
('legolas.greenleaf@example.com', 'Legolas', 'Greenleaf', '555-0190', '2026-06-07 11:50:00'),
('michael.corleone@example.com', 'Michael', 'Corleone', '555-0191', '2026-06-11 18:00:00'),
('ned.stark@example.com', 'Ned', 'Stark', '555-0192', '2026-06-15 10:20:00'),
('oberyn.martell@example.com', 'Oberyn', 'Martell', '555-0193', '2026-06-20 14:10:00'),
('padme.amidala@example.com', 'Padme', 'Amidala', '555-0194', '2026-06-24 08:35:00'),
('quigon.jinn@example.com', 'QuiGon', 'Jinn', '555-0195', '2026-06-28 12:45:00'),
('rhaegar.targaryen@example.com', 'Rhaegar', 'Targaryen', '555-0196', '2026-07-02 16:00:00'),
('sans.skeleton@example.com', 'Sans', 'Skeleton', '555-0197', '2026-07-06 09:10:00'),
('tyrion.lannister@example.com', 'Tyrion', 'Lannister', '555-0198', '2026-07-10 13:25:00'),
('uther.pendragon@example.com', 'Uther', 'Pendragon', '555-0199', '2026-07-15 17:05:00'),
('vito.corleone@example.com', 'Vito', 'Corleone', '555-0200', '2026-07-20 11:30:00');
GO

SELECT * FROM Core.Users;

INSERT INTO Catalog.Events (venue_id, category_id, event_name, start_time, end_time, status) 
VALUES
(1, 1, 'Cosmic Echoes World Tour', '2026-09-15 19:30:00', '2026-09-15 22:30:00', 'Scheduled'),
(2, 1, 'Red Rocks Summer Night Live', '2026-09-20 20:00:00', '2026-09-20 23:00:00', 'Scheduled'),
(3, 9, 'Swan Lake Gala Night', '2026-10-05 18:00:00', '2026-10-05 21:00:00', 'Scheduled'),
(4, 8, 'Global Esports Championship Finals', '2026-10-12 12:00:00', '2026-10-12 20:00:00', 'Scheduled'),
(5, 4, 'Sarah Jenkins Comedy Special', '2026-11-01 20:00:00', '2026-11-01 22:00:00', 'Scheduled'),
(1, 5, 'Tech Vision Summit 2026', '2026-11-15 09:00:00', '2026-11-15 17:00:00', 'Scheduled'),
(6, 2, 'Boston Hoops vs Chicago Showdown', '2026-08-10 19:00:00', '2026-08-10 21:30:00', 'Completed'),
(7, 2, 'Midwest Basketball Classic', '2026-08-18 18:30:00', '2026-08-18 21:00:00', 'Completed'),
(8, 2, 'London Derby Football Clash', '2026-09-01 15:00:00', '2026-09-01 17:00:00', 'Scheduled'),
(9, 3, 'Shakespeare In The Harbor', '2026-09-08 19:00:00', '2026-09-08 21:30:00', 'Scheduled'),
(10, 1, 'Neon Horizon Laser Concert', '2026-09-25 21:00:00', '2026-09-26 00:00:00', 'Scheduled'),
(11, 9, 'Paris Grand Opera Night', '2026-10-01 19:30:00', '2026-10-01 22:30:00', 'Scheduled'),
(12, 11, 'Atlanta Grand Prix Qualifying', '2026-10-18 13:00:00', '2026-10-18 16:00:00', 'Scheduled'),
(13, 2, 'International Cup Qualifier', '2026-10-22 20:00:00', '2026-10-22 22:00:00', 'Scheduled'),
(14, 1, 'Acoustic Legends Live', '2026-11-05 19:00:00', '2026-11-05 21:30:00', 'Scheduled'),
(15, 1, 'Hollywood Bowl Sunset Symphony', '2026-08-25 18:30:00', '2026-08-25 21:00:00', 'Completed'),
(1, 12, 'World Heavyweight Championship', '2026-11-20 21:00:00', '2026-11-21 00:30:00', 'Scheduled'),
(2, 10, 'Morrison Mountain Folk Fest Day 1', '2026-09-28 11:00:00', '2026-09-28 23:00:00', 'Scheduled'),
(3, 4, 'London Laughs All-Star Night', '2026-10-10 20:00:00', '2026-10-10 22:30:00', 'Scheduled'),
(4, 1, 'Hip Hop Heritage Showcase', '2026-10-28 19:30:00', '2026-10-28 23:00:00', 'Scheduled'),
(5, 7, 'Holiday Magic & Illusion Spectacular', '2026-12-01 14:00:00', '2026-12-01 16:00:00', 'Scheduled'),
(6, 5, 'AI & Robotics Developer Summit', '2026-12-05 08:30:00', '2026-12-05 17:30:00', 'Scheduled'),
(7, 3, 'Broadway National Tour - Les Mis', '2026-12-10 19:00:00', '2026-12-10 22:00:00', 'Postponed'),
(8, 11, 'Wembley Monster Truck Rally', '2026-07-20 14:00:00', '2026-07-20 17:00:00', 'Completed'),
(10, 1, 'Sphere Immersive EDM Experience', '2026-12-31 22:00:00', '2027-01-01 03:00:00', 'Scheduled');
GO

SELECT * FROM Catalog.Events;

INSERT INTO Catalog.EventPerformers (event_id, performer_id, performance_order) 
VALUES
(1, 1, 1), 
(1, 7, 2), 
(1, 9, 3),
(2, 1, 1), 
(2, 20, 2),
(3, 5, 1), 
(3, 3, 2), 
(3, 18, 3),
(4, 4, 1), 
(4, 24, 2),
(5, 2, 1), 
(5, 21, 2),
(6, 6, 1), 
(6, 16, 2), 
(6, 28, 3),
(7, 12, 1), 
(7, 11, 2),
(8, 12, 1),
(9, 11, 1),
(10, 10, 1),
(11, 9, 1), 
(11, 27, 2),
(12, 18, 1), 
(12, 22, 2),
(13, 17, 1),
(14, 11, 1),
(15, 20, 1),
(16, 3, 1), 
(16, 30, 2),
(17, 19, 1), 
(17, 15, 2),
(18, 20, 1), 
(18, 1, 2), 
(18, 8, 3),
(19, 2, 1), 
(19, 21, 2),
(20, 7, 1), 
(20, 27, 2),
(21, 13, 1), 
(21, 23, 2),
(22, 16, 1), 
(22, 6, 2),
(23, 26, 1),
(24, 17, 1),
(25, 27, 1), 
(25, 9, 2);
GO

SELECT * FROM Catalog.EventPerformers;

INSERT INTO Inventory.SeatSections (venue_id, section_name, base_price_tier) 
VALUES
(1, 'VIP Floor', 250.00),
(1, 'Lower Bowl', 125.00),
(1, 'Upper Deck', 65.00),
(2, 'Reserved Front', 185.00),
(2, 'General Admission', 75.00),
(3, 'VIP Club', 220.00),
(3, 'Lower Tier', 110.00),
(3, 'Upper Tier', 55.00),
(4, 'Courtside VIP', 300.00),
(4, 'Concourse Premier', 140.00),
(4, 'Upper Balcony', 60.00),
(5, 'Orchestra Front', 175.00),
(5, 'First Mezzanine', 100.00),
(5, 'Second Mezzanine', 70.00),
(6, 'Loge Level', 130.00),
(6, 'Balcony Level', 60.00),
(7, '100 Level VIP', 210.00),
(7, '200 Level Club', 135.00),
(7, '300 Level', 55.00),
(8, 'Pitch Standing', 95.00),
(8, 'Level 1 Seating', 150.00),
(8, 'Level 3 Upper', 70.00),
(9, 'Concert Hall Stalls', 190.00),
(9, 'Circle', 120.00),
(10, 'Immersive Floor', 275.00),
(10, 'Director Suite', 350.00),
(10, 'General Tier', 90.00),
(11, 'Fosse Gold', 160.00),
(11, 'Gradins', 80.00),
(12, 'Field Club', 230.00),
(12, 'Lower Bowl', 115.00),
(13, 'Supporters Section', 45.00),
(13, 'Main Stand', 85.00),
(14, 'Ryman Floor', 105.00),
(14, 'Balcony', 75.00),
(15, 'Pool Circle', 200.00),
(15, 'Terrace Boxes', 140.00);
GO

SELECT * FROM Inventory.SeatSections;

INSERT INTO Inventory.Seats (section_id, row_number, seat_number) 
VALUES
(1, 'A', 1),
(1, 'A', 2),
(1, 'A', 3),
(1, 'A', 4),
(1, 'A', 5),
(1, 'A', 6),
(1, 'A', 7),
(1, 'A', 8),
(1, 'A', 9),
(1, 'A', 10),
(1, 'B', 1),
(1, 'B', 2),
(1, 'B', 3),
(1, 'B', 4),
(1, 'B', 5),
(1, 'B', 6),
(1, 'B', 7),
(1, 'B', 8),
(1, 'B', 9),
(1, 'B', 10),
(1, 'C', 1),
(1, 'C', 2),
(1, 'C', 3),
(1, 'C', 4),
(1, 'C', 5),
(1, 'C', 6),
(1, 'C', 7),
(1, 'C', 8),
(1, 'C', 9),
(1, 'C', 10),
(2, 'A', 1),
(2, 'A', 2),
(2, 'A', 3),
(2, 'A', 4),
(2, 'A', 5),
(2, 'A', 6),
(2, 'A', 7),
(2, 'A', 8),
(2, 'A', 9),
(2, 'A', 10),
(2, 'B', 1),
(2, 'B', 2),
(2, 'B', 3),
(2, 'B', 4),
(2, 'B', 5),
(2, 'B', 6),
(2, 'B', 7),
(2, 'B', 8),
(2, 'B', 9),
(2, 'B', 10),
(2, 'C', 1),
(2, 'C', 2),
(2, 'C', 3),
(2, 'C', 4),
(2, 'C', 5),
(2, 'C', 6),
(2, 'C', 7),
(2, 'C', 8),
(2, 'C', 9),
(2, 'C', 10),
(3, 'A', 1),
(3, 'A', 2),
(3, 'A', 3),
(3, 'A', 4),
(3, 'A', 5),
(3, 'A', 6),
(3, 'A', 7),
(3, 'A', 8),
(3, 'A', 9),
(3, 'A', 10),
(3, 'B', 1),
(3, 'B', 2),
(3, 'B', 3),
(3, 'B', 4),
(3, 'B', 5),
(3, 'B', 6),
(3, 'B', 7),
(3, 'B', 8),
(3, 'B', 9),
(3, 'B', 10),
(3, 'C', 1),
(3, 'C', 2),
(3, 'C', 3),
(3, 'C', 4),
(3, 'C', 5),
(3, 'C', 6),
(3, 'C', 7),
(3, 'C', 8),
(3, 'C', 9),
(3, 'C', 10),
(4, 'A', 1),
(4, 'A', 2),
(4, 'A', 3),
(4, 'A', 4),
(4, 'A', 5),
(4, 'A', 6),
(4, 'A', 7),
(4, 'A', 8),
(4, 'A', 9),
(4, 'A', 10);
GO

SELECT * FROM Inventory.Seats;

INSERT INTO Inventory.Tickets (event_id, seat_id, price, status) 
VALUES
(1, 1, 250.00, 'Sold'),
(1, 2, 250.00, 'Sold'),
(1, 3, 250.00, 'Sold'),
(1, 4, 250.00, 'Sold'),
(1, 5, 250.00, 'Sold'),
(1, 6, 250.00, 'Sold'),
(1, 7, 250.00, 'Sold'),
(1, 8, 250.00, 'Sold'),
(1, 9, 250.00, 'Sold'),
(1, 10, 250.00, 'Sold'),
(1, 11, 250.00, 'Reserved'),
(1, 12, 250.00, 'Reserved'),
(1, 13, 250.00, 'Available'),
(1, 14, 250.00, 'Available'),
(1, 15, 250.00, 'Available'),
(1, 16, 250.00, 'Available'),
(1, 17, 250.00, 'Available'),
(1, 18, 250.00, 'Available'),
(1, 19, 250.00, 'Available'),
(1, 20, 250.00, 'Available'),
(1, 31, 125.00, 'Sold'),
(1, 32, 125.00, 'Sold'),
(1, 33, 125.00, 'Sold'),
(1, 34, 125.00, 'Sold'),
(1, 35, 125.00, 'Sold'),
(1, 36, 125.00, 'Available'),
(1, 37, 125.00, 'Available'),
(1, 38, 125.00, 'Available'),
(1, 39, 125.00, 'Available'),
(1, 40, 125.00, 'Available'),
(2, 91, 185.00, 'Sold'),
(2, 92, 185.00, 'Sold'),
(2, 93, 185.00, 'Sold'),
(2, 94, 185.00, 'Sold'),
(2, 95, 185.00, 'Sold'),
(2, 96, 185.00, 'Sold'),
(2, 97, 185.00, 'Sold'),
(2, 98, 185.00, 'Sold'),
(2, 99, 185.00, 'Reserved'),
(2, 100, 185.00, 'Available'),
(3, 1, 220.00, 'Sold'),
(3, 2, 220.00, 'Sold'),
(3, 3, 220.00, 'Sold'),
(3, 4, 220.00, 'Sold'),
(3, 5, 220.00, 'Sold'),
(3, 6, 220.00, 'Reserved'),
(3, 7, 220.00, 'Available'),
(3, 8, 220.00, 'Available'),
(3, 9, 220.00, 'Available'),
(3, 10, 220.00, 'Available'),
(4, 31, 140.00, 'Sold'),
(4, 32, 140.00, 'Sold'),
(4, 33, 140.00, 'Sold'),
(4, 34, 140.00, 'Sold'),
(4, 35, 140.00, 'Sold'),
(4, 36, 140.00, 'Sold'),
(4, 37, 140.00, 'Sold'),
(4, 38, 140.00, 'Sold'),
(4, 39, 140.00, 'Reserved'),
(4, 40, 140.00, 'Available'),
(5, 61, 100.00, 'Sold'),
(5, 62, 100.00, 'Sold'),
(5, 63, 100.00, 'Sold'),
(5, 64, 100.00, 'Sold'),
(5, 65, 100.00, 'Sold'),
(5, 66, 100.00, 'Available'),
(5, 67, 100.00, 'Available'),
(5, 68, 100.00, 'Available'),
(5, 69, 100.00, 'Available'),
(5, 70, 100.00, 'Available'),
(6, 1, 300.00, 'Sold'),
(6, 2, 300.00, 'Sold'),
(6, 3, 300.00, 'Sold'),
(6, 4, 300.00, 'Sold'),
(6, 5, 300.00, 'Sold'),
(6, 6, 300.00, 'Sold'),
(6, 7, 300.00, 'Sold'),
(6, 8, 300.00, 'Sold'),
(6, 9, 300.00, 'Sold'),
(6, 10, 300.00, 'Sold'),
(7, 31, 130.00, 'Sold'),
(7, 32, 130.00, 'Sold'),
(7, 33, 130.00, 'Sold'),
(7, 34, 130.00, 'Sold'),
(7, 35, 130.00, 'Sold'),
(7, 36, 130.00, 'Sold'),
(7, 37, 130.00, 'Sold'),
(7, 38, 130.00, 'Sold'),
(7, 39, 130.00, 'Sold'),
(7, 40, 130.00, 'Sold'),
(8, 61, 135.00, 'Sold'),
(8, 62, 135.00, 'Sold'),
(8, 63, 135.00, 'Sold'),
(8, 64, 135.00, 'Sold'),
(8, 65, 135.00, 'Sold'),
(8, 66, 135.00, 'Sold'),
(8, 67, 135.00, 'Sold'),
(8, 68, 135.00, 'Sold'),
(8, 69, 135.00, 'Sold'),
(8, 70, 135.00, 'Sold');
GO

SELECT * FROM Inventory.Tickets;

INSERT INTO Sales.Bookings (user_id, booking_date, total_amount, status) 
VALUES
(1, '2026-05-01 10:15:00', 500.00, 'Confirmed'),
(2, '2026-05-02 11:20:00', 250.00, 'Confirmed'),
(3, '2026-05-02 14:05:00', 250.00, 'Confirmed'),
(4, '2026-05-03 09:30:00', 500.00, 'Confirmed'),
(5, '2026-05-03 16:45:00', 250.00, 'Confirmed'),
(6, '2026-05-04 12:10:00', 500.00, 'Confirmed'),
(7, '2026-05-05 08:50:00', 250.00, 'Refunded'),
(8, '2026-05-05 15:25:00', 500.00, 'Pending'),
(9, '2026-05-06 10:00:00', 250.00, 'Confirmed'),
(10, '2026-05-06 18:15:00', 250.00, 'Cancelled'),
(11, '2026-05-07 11:40:00', 250.00, 'Confirmed'),
(12, '2026-05-07 13:05:00', 250.00, 'Confirmed'),
(13, '2026-05-08 09:15:00', 250.00, 'Confirmed'),
(14, '2026-05-08 17:30:00', 250.00, 'Confirmed'),
(15, '2026-05-09 10:20:00', 250.00, 'Confirmed'),
(16, '2026-05-09 14:50:00', 250.00, 'Confirmed'),
(17, '2026-05-10 11:10:00', 250.00, 'Confirmed'),
(18, '2026-05-10 16:00:00', 250.00, 'Confirmed'),
(19, '2026-05-11 08:40:00', 250.00, 'Confirmed'),
(20, '2026-05-11 19:25:00', 250.00, 'Confirmed'),
(21, '2026-05-12 10:05:00', 125.00, 'Confirmed'),
(22, '2026-05-12 12:30:00', 125.00, 'Confirmed'),
(23, '2026-05-13 09:00:00', 125.00, 'Confirmed'),
(24, '2026-05-13 15:15:00', 125.00, 'Confirmed'),
(25, '2026-05-14 11:50:00', 125.00, 'Confirmed'),
(26, '2026-05-14 18:00:00', 185.00, 'Confirmed'),
(27, '2026-05-15 08:30:00', 185.00, 'Confirmed'),
(28, '2026-05-15 13:45:00', 185.00, 'Confirmed'),
(29, '2026-05-16 10:15:00', 185.00, 'Confirmed'),
(30, '2026-05-16 16:20:00', 185.00, 'Confirmed'),
(31, '2026-05-17 09:40:00', 185.00, 'Confirmed'),
(32, '2026-05-17 14:10:00', 185.00, 'Confirmed'),
(33, '2026-05-18 11:00:00', 185.00, 'Confirmed'),
(34, '2026-05-18 17:35:00', 185.00, 'Confirmed'),
(35, '2026-05-19 12:15:00', 185.00, 'Confirmed'),
(36, '2026-05-19 19:00:00', 220.00, 'Confirmed'),
(37, '2026-05-20 08:50:00', 220.00, 'Confirmed'),
(38, '2026-05-20 13:25:00', 220.00, 'Confirmed'),
(39, '2026-05-21 10:40:00', 220.00, 'Confirmed'),
(40, '2026-05-21 15:50:00', 220.00, 'Confirmed'),
(41, '2026-05-22 09:10:00', 140.00, 'Confirmed'),
(42, '2026-05-22 14:30:00', 140.00, 'Confirmed'),
(43, '2026-05-23 11:20:00', 140.00, 'Confirmed'),
(44, '2026-05-23 16:45:00', 140.00, 'Confirmed'),
(45, '2026-05-24 10:05:00', 140.00, 'Confirmed'),
(46, '2026-05-24 18:10:00', 140.00, 'Confirmed'),
(47, '2026-05-25 08:25:00', 140.00, 'Confirmed'),
(48, '2026-05-25 13:00:00', 140.00, 'Confirmed'),
(49, '2026-05-26 12:40:00', 100.00, 'Confirmed'),
(50, '2026-05-26 17:15:00', 100.00, 'Confirmed'),
(51, '2026-05-27 09:30:00', 100.00, 'Confirmed'),
(52, '2026-05-27 14:50:00', 100.00, 'Confirmed'),
(53, '2026-05-28 11:15:00', 100.00, 'Confirmed'),
(54, '2026-05-28 16:25:00', 300.00, 'Confirmed'),
(55, '2026-05-29 10:10:00', 300.00, 'Confirmed'),
(56, '2026-05-29 15:00:00', 300.00, 'Confirmed'),
(57, '2026-05-30 08:45:00', 300.00, 'Confirmed'),
(58, '2026-05-30 13:30:00', 300.00, 'Confirmed'),
(59, '2026-05-31 11:55:00', 300.00, 'Confirmed'),
(60, '2026-05-31 17:40:00', 300.00, 'Confirmed'),
(61, '2026-06-01 09:20:00', 300.00, 'Confirmed'),
(62, '2026-06-01 14:15:00', 300.00, 'Confirmed'),
(63, '2026-06-02 10:50:00', 300.00, 'Confirmed'),
(64, '2026-06-02 16:05:00', 130.00, 'Confirmed'),
(65, '2026-06-03 08:35:00', 130.00, 'Confirmed'),
(66, '2026-06-03 12:50:00', 130.00, 'Confirmed'),
(67, '2026-06-04 11:10:00', 130.00, 'Confirmed'),
(68, '2026-06-04 15:30:00', 130.00, 'Confirmed'),
(69, '2026-06-05 09:45:00', 130.00, 'Confirmed'),
(70, '2026-06-05 14:00:00', 130.00, 'Confirmed'),
(71, '2026-06-06 10:25:00', 130.00, 'Confirmed'),
(72, '2026-06-06 17:10:00', 130.00, 'Confirmed'),
(73, '2026-06-07 08:15:00', 130.00, 'Confirmed'),
(74, '2026-06-07 13:40:00', 135.00, 'Confirmed'),
(75, '2026-06-08 11:30:00', 135.00, 'Confirmed'),
(76, '2026-06-08 16:50:00', 135.00, 'Confirmed'),
(77, '2026-06-09 09:05:00', 135.00, 'Confirmed'),
(78, '2026-06-09 14:20:00', 135.00, 'Confirmed'),
(79, '2026-06-10 10:45:00', 135.00, 'Confirmed'),
(80, '2026-06-10 15:15:00', 135.00, 'Confirmed'),
(81, '2026-06-11 08:50:00', 135.00, 'Confirmed'),
(82, '2026-06-11 12:35:00', 135.00, 'Confirmed'),
(83, '2026-06-12 11:00:00', 135.00, 'Confirmed'),
(84, '2026-06-12 16:40:00', 250.00, 'Confirmed'),
(85, '2026-06-13 09:15:00', 250.00, 'Confirmed'),
(86, '2026-06-13 13:50:00', 250.00, 'Confirmed'),
(87, '2026-06-14 10:30:00', 250.00, 'Confirmed'),
(88, '2026-06-14 15:05:00', 185.00, 'Confirmed'),
(89, '2026-06-15 08:40:00', 185.00, 'Confirmed'),
(90, '2026-06-15 12:10:00', 185.00, 'Confirmed'),
(91, '2026-06-16 11:25:00', 220.00, 'Confirmed'),
(92, '2026-06-16 16:30:00', 220.00, 'Confirmed'),
(93, '2026-06-17 09:55:00', 140.00, 'Confirmed'),
(94, '2026-06-17 14:15:00', 140.00, 'Confirmed'),
(95, '2026-06-18 10:20:00', 100.00, 'Confirmed'),
(96, '2026-06-18 15:45:00', 100.00, 'Confirmed'),
(97, '2026-06-19 08:30:00', 300.00, 'Confirmed'),
(98, '2026-06-19 13:00:00', 300.00, 'Confirmed'),
(99, '2026-06-20 11:10:00', 130.00, 'Confirmed'),
(100, '2026-06-20 16:20:00', 135.00, 'Confirmed');
GO

SELECT * FROM Sales.Bookings;

INSERT INTO Sales.BookingItems (booking_id, ticket_id, unit_price) 
VALUES
(1, 1, 250.00),
(1, 2, 250.00),
(2, 3, 250.00),
(3, 4, 250.00),
(4, 5, 250.00),
(4, 6, 250.00),
(5, 7, 250.00),
(6, 8, 250.00),
(6, 9, 250.00),
(7, 10, 250.00),
(8, 11, 250.00),
(8, 12, 250.00),
(9, 13, 250.00),
(10, 14, 250.00),
(11, 15, 250.00),
(12, 16, 250.00),
(13, 17, 250.00),
(14, 18, 250.00),
(15, 19, 250.00),
(16, 20, 250.00),
(17, 21, 125.00),
(18, 22, 125.00),
(19, 23, 125.00),
(20, 24, 125.00),
(21, 25, 125.00),
(22, 26, 125.00),
(23, 27, 125.00),
(24, 28, 125.00),
(25, 29, 125.00),
(25, 30, 125.00),
(26, 31, 185.00),
(27, 32, 185.00),
(28, 33, 185.00),
(29, 34, 185.00),
(30, 35, 185.00),
(31, 36, 185.00),
(32, 37, 185.00),
(33, 38, 185.00),
(34, 39, 185.00),
(35, 40, 185.00),
(36, 41, 220.00),
(37, 42, 220.00),
(38, 43, 220.00),
(39, 44, 220.00),
(40, 45, 220.00),
(41, 46, 140.00),
(42, 47, 140.00),
(43, 48, 140.00),
(44, 49, 140.00),
(45, 50, 140.00),
(46, 51, 140.00),
(47, 52, 140.00),
(48, 53, 140.00),
(49, 54, 100.00),
(50, 55, 100.00),
(51, 56, 100.00),
(52, 57, 100.00),
(53, 58, 100.00),
(54, 59, 300.00),
(55, 60, 300.00),
(56, 61, 300.00),
(57, 62, 300.00),
(58, 63, 300.00),
(59, 64, 300.00),
(60, 65, 300.00),
(61, 66, 300.00),
(62, 67, 300.00),
(63, 68, 300.00),
(64, 69, 130.00),
(65, 70, 130.00),
(66, 71, 130.00),
(67, 72, 130.00),
(68, 73, 130.00),
(69, 74, 130.00),
(70, 75, 130.00),
(71, 76, 130.00),
(72, 77, 130.00),
(73, 78, 130.00),
(74, 79, 135.00),
(75, 80, 135.00),
(76, 81, 135.00),
(77, 82, 135.00),
(78, 83, 135.00),
(79, 84, 135.00),
(80, 85, 135.00),
(81, 86, 135.00),
(82, 87, 135.00),
(83, 88, 135.00),
(84, 89, 250.00),
(85, 90, 250.00),
(86, 91, 185.00),
(87, 92, 185.00),
(88, 93, 185.00),
(89, 94, 185.00),
(90, 95, 185.00),
(91, 96, 220.00),
(92, 97, 220.00),
(93, 98, 140.00),
(94, 99, 140.00),
(95, 100, 100.00);
GO

SELECT * FROM Sales.BookingItems;

INSERT INTO Sales.Payments (booking_id, amount, payment_method, payment_date, status) 
VALUES
(1, 500.00, 'Credit Card', '2026-05-01 10:16:00', 'Completed'),
(2, 250.00, 'PayPal', '2026-05-02 11:21:00', 'Completed'),
(3, 250.00, 'Debit Card', '2026-05-02 14:06:00', 'Completed'),
(4, 500.00, 'Credit Card', '2026-05-03 09:31:00', 'Completed'),
(5, 250.00, 'Credit Card', '2026-05-03 16:46:00', 'Completed'),
(6, 500.00, 'Gift Card', '2026-05-04 12:11:00', 'Completed'),
(7, 250.00, 'Credit Card', '2026-05-05 08:51:00', 'Refunded'),
(8, 500.00, 'PayPal', '2026-05-05 15:26:00', 'Pending'),
(9, 250.00, 'Debit Card', '2026-05-06 10:01:00', 'Completed'),
(10, 250.00, 'Credit Card', '2026-05-06 18:16:00', 'Failed'),
(11, 250.00, 'Credit Card', '2026-05-07 11:41:00', 'Completed'),
(12, 250.00, 'PayPal', '2026-05-07 13:06:00', 'Completed'),
(13, 250.00, 'Debit Card', '2026-05-08 09:16:00', 'Completed'),
(14, 250.00, 'Credit Card', '2026-05-08 17:31:00', 'Completed'),
(15, 250.00, 'Credit Card', '2026-05-09 10:21:00', 'Completed'),
(16, 250.00, 'Gift Card', '2026-05-09 14:51:00', 'Completed'),
(17, 250.00, 'Credit Card', '2026-05-10 11:11:00', 'Completed'),
(18, 250.00, 'PayPal', '2026-05-10 16:01:00', 'Completed'),
(19, 250.00, 'Debit Card', '2026-05-11 08:41:00', 'Completed'),
(20, 250.00, 'Credit Card', '2026-05-11 19:26:00', 'Completed'),
(21, 125.00, 'Credit Card', '2026-05-12 10:06:00', 'Completed'),
(22, 125.00, 'PayPal', '2026-05-12 12:31:00', 'Completed'),
(23, 125.00, 'Debit Card', '2026-05-13 09:01:00', 'Completed'),
(24, 125.00, 'Credit Card', '2026-05-13 15:16:00', 'Completed'),
(25, 125.00, 'Credit Card', '2026-05-14 11:51:00', 'Completed'),
(26, 185.00, 'Gift Card', '2026-05-14 18:01:00', 'Completed'),
(27, 185.00, 'Credit Card', '2026-05-15 08:31:00', 'Completed'),
(28, 185.00, 'PayPal', '2026-05-15 13:46:00', 'Completed'),
(29, 185.00, 'Debit Card', '2026-05-16 10:16:00', 'Completed'),
(30, 185.00, 'Credit Card', '2026-05-16 16:21:00', 'Completed'),
(31, 185.00, 'Credit Card', '2026-05-17 09:41:00', 'Completed'),
(32, 185.00, 'PayPal', '2026-05-17 14:11:00', 'Completed'),
(33, 185.00, 'Debit Card', '2026-05-18 11:01:00', 'Completed'),
(34, 185.00, 'Credit Card', '2026-05-18 17:36:00', 'Completed'),
(35, 185.00, 'Credit Card', '2026-05-19 12:16:00', 'Completed'),
(36, 220.00, 'Gift Card', '2026-05-19 19:01:00', 'Completed'),
(37, 220.00, 'Credit Card', '2026-05-20 08:51:00', 'Completed'),
(38, 220.00, 'PayPal', '2026-05-20 13:26:00', 'Completed'),
(39, 220.00, 'Debit Card', '2026-05-21 10:41:00', 'Completed'),
(40, 220.00, 'Credit Card', '2026-05-21 15:51:00', 'Completed'),
(41, 140.00, 'Credit Card', '2026-05-22 09:11:00', 'Completed'),
(42, 140.00, 'PayPal', '2026-05-22 14:31:00', 'Completed'),
(43, 140.00, 'Debit Card', '2026-05-23 11:21:00', 'Completed'),
(44, 140.00, 'Credit Card', '2026-05-23 16:46:00', 'Completed'),
(45, 140.00, 'Credit Card', '2026-05-24 10:06:00', 'Completed'),
(46, 140.00, 'Gift Card', '2026-05-24 18:11:00', 'Completed'),
(47, 140.00, 'Credit Card', '2026-05-25 08:26:00', 'Completed'),
(48, 140.00, 'PayPal', '2026-05-25 13:01:00', 'Completed'),
(49, 100.00, 'Debit Card', '2026-05-26 12:41:00', 'Completed'),
(50, 100.00, 'Credit Card', '2026-05-26 17:16:00', 'Completed'),
(51, 100.00, 'Credit Card', '2026-05-27 09:31:00', 'Completed'),
(52, 100.00, 'PayPal', '2026-05-27 14:51:00', 'Completed'),
(53, 100.00, 'Debit Card', '2026-05-28 11:16:00', 'Completed'),
(54, 300.00, 'Credit Card', '2026-05-28 16:26:00', 'Completed'),
(55, 300.00, 'Credit Card', '2026-05-29 10:11:00', 'Completed'),
(56, 300.00, 'Gift Card', '2026-05-29 15:01:00', 'Completed'),
(57, 300.00, 'Credit Card', '2026-05-30 08:46:00', 'Completed'),
(58, 300.00, 'PayPal', '2026-05-30 13:31:00', 'Completed'),
(59, 300.00, 'Debit Card', '2026-05-31 11:56:00', 'Completed'),
(60, 300.00, 'Credit Card', '2026-05-31 17:41:00', 'Completed'),
(61, 300.00, 'Credit Card', '2026-06-01 09:21:00', 'Completed'),
(62, 300.00, 'PayPal', '2026-06-01 14:16:00', 'Completed'),
(63, 300.00, 'Debit Card', '2026-06-02 10:51:00', 'Completed'),
(64, 130.00, 'Credit Card', '2026-06-02 16:06:00', 'Completed'),
(65, 130.00, 'Credit Card', '2026-06-03 08:36:00', 'Completed'),
(66, 130.00, 'Gift Card', '2026-06-03 12:51:00', 'Completed'),
(67, 130.00, 'Credit Card', '2026-06-04 11:11:00', 'Completed'),
(68, 130.00, 'PayPal', '2026-06-04 15:31:00', 'Completed'),
(69, 130.00, 'Debit Card', '2026-06-05 09:46:00', 'Completed'),
(70, 130.00, 'Credit Card', '2026-06-05 14:01:00', 'Completed'),
(71, 130.00, 'Credit Card', '2026-06-06 10:26:00', 'Completed'),
(72, 130.00, 'PayPal', '2026-06-06 17:11:00', 'Completed'),
(73, 130.00, 'Debit Card', '2026-06-07 08:16:00', 'Completed'),
(74, 135.00, 'Credit Card', '2026-06-07 13:41:00', 'Completed'),
(75, 135.00, 'Credit Card', '2026-06-08 11:31:00', 'Completed'),
(76, 135.00, 'Gift Card', '2026-06-08 16:51:00', 'Completed'),
(77, 135.00, 'Credit Card', '2026-06-09 09:06:00', 'Completed'),
(78, 135.00, 'PayPal', '2026-06-09 14:21:00', 'Completed'),
(79, 135.00, 'Debit Card', '2026-06-10 10:46:00', 'Completed'),
(80, 135.00, 'Credit Card', '2026-06-10 15:16:00', 'Completed'),
(81, 135.00, 'Credit Card', '2026-06-11 08:51:00', 'Completed'),
(82, 135.00, 'PayPal', '2026-06-11 12:36:00', 'Completed'),
(83, 135.00, 'Debit Card', '2026-06-12 11:01:00', 'Completed'),
(84, 250.00, 'Credit Card', '2026-06-12 16:41:00', 'Completed'),
(85, 250.00, 'Credit Card', '2026-06-13 09:16:00', 'Completed'),
(86, 250.00, 'Gift Card', '2026-06-13 13:51:00', 'Completed'),
(87, 250.00, 'Credit Card', '2026-06-14 10:31:00', 'Completed'),
(88, 185.00, 'PayPal', '2026-06-14 15:06:00', 'Completed'),
(89, 185.00, 'Debit Card', '2026-06-15 08:41:00', 'Completed'),
(90, 185.00, 'Credit Card', '2026-06-15 12:11:00', 'Completed'),
(91, 220.00, 'Credit Card', '2026-06-16 11:26:00', 'Completed'),
(92, 220.00, 'PayPal', '2026-06-16 16:31:00', 'Completed'),
(93, 140.00, 'Debit Card', '2026-06-17 09:56:00', 'Completed'),
(94, 140.00, 'Credit Card', '2026-06-17 14:16:00', 'Completed'),
(95, 100.00, 'Credit Card', '2026-06-18 10:21:00', 'Completed'),
(96, 100.00, 'Gift Card', '2026-06-18 15:46:00', 'Completed'),
(97, 300.00, 'Credit Card', '2026-06-19 08:31:00', 'Completed'),
(98, 300.00, 'PayPal', '2026-06-19 13:01:00', 'Completed'),
(99, 130.00, 'Debit Card', '2026-06-20 11:11:00', 'Completed'),
(100, 135.00, 'Credit Card', '2026-06-20 16:21:00', 'Completed');
GO

SELECT * FROM Sales.Payments;


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
WHERE s.name = 'Core'
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
WHERE s.name = 'Catalog'
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
WHERE s.name = 'Inventory'
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
WHERE s.name = 'Sales'
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
WHERE s.name = 'Core'
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
WHERE s.name = 'Catalog'
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
WHERE s.name = 'Inventory'
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
WHERE s.name = 'Sales'
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
WHERE s_parent.name = 'Core'
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
WHERE s_parent.name = 'Catalog'
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
WHERE s_parent.name = 'Inventory'
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
WHERE s_parent.name = 'Sales'
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
WHERE s.name = 'Core'
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
WHERE s.name = 'Catalog'
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
WHERE s.name = 'Inventory'
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
WHERE s.name = 'Sales'
ORDER BY t.name, cc.name;
GO
