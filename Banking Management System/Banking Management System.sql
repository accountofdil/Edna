-- Database Creation

CREATE DATABASE banking_management_system;
USE banking_management_system;

DROP TABLE IF EXISTS customers;
CREATE TABLE customers(
					customer_id INT PRIMARY KEY AUTO_INCREMENT,
                    first_name VARCHAR(50) NOT NULL,
                    last_name VARCHAR(50) NOT NULL,
                    gender ENUM('Male', 'Female', 'Other') NOT NULL,
                    date_of_birth DATE NOT NULL,
                    phone VARCHAR(15) UNIQUE,
                    email VARCHAR(100) UNIQUE,
                    address VARCHAR(255) NOT NULL,
                    aadhaar_no VARCHAR(12) UNIQUE,
                    customer_status ENUM('Active', 'Inactive', 'Blocked') DEFAULT 'Active',
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP);

SHOW tables;
DESC customers;
SELECT * FROM customers;

DROP TABLE IF EXISTS branches;
CREATE TABLE branches(
					branch_id INT PRIMARY KEY AUTO_INCREMENT,
                    branch_name VARCHAR(100) NOT NULL,
                    city VARCHAR(50) NOT NULL,
                    state VARCHAR(50) NOT NULL,
                    ifsc_code VARCHAR(20) UNIQUE NOT NULL,
                    phone VARCHAR(15));
                    
SHOW tables;
DESC branches;
SELECT * FROM branches;

DROP TABLE IF EXISTS account_types;
CREATE TABLE account_types(
						account_type_id INT PRIMARY KEY AUTO_INCREMENT,
                        type_name VARCHAR(30) UNIQUE NOT NULL,
                        minimum_balance DECIMAL(12, 2) NOT NULL);

SHOW tables;
DESC account_types;
SELECT * FROM account_types;

DROP TABLE IF EXISTS employees;
CREATE TABLE employees(
					employee_id INT PRIMARY KEY AUTO_INCREMENT,
                    branch_id INT NOT NULL,
                    first_name VARCHAR(50) NOT NULL,
                    last_name VARCHAR(50) NOT NULL,
                    designation VARCHAR(50) NOT NULL,
                    salary DECIMAL(12, 2) NOT NULL,
                    hire_date DATE NOT NULL,
                    phone VARCHAR(15) UNIQUE,
                    FOREIGN KEY (branch_id) REFERENCES branches(branch_id));

SHOW tables;
DESC employees;
SELECT * FROM employees;

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts(
					account_id INT PRIMARY KEY AUTO_INCREMENT,
                    customer_id INT NOT NULL,
                    branch_id INT NOT NULL,
                    account_type_id INT NOT NULL,
                    account_number VARCHAR(20) UNIQUE NOT NULL,
                    balance DECIMAL(15, 2) NOT NULL,
                    open_date DATE NOT NULL,
                    account_status ENUM('Active', 'Dormant', 'Closed') DEFAULT 'Active',
                    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
                    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
                    FOREIGN KEY (account_type_id) REFERENCES account_types(account_type_id));

SHOW tables;
DESC accounts;
SELECT * FROM accounts;

DROP TABLE IF EXISTS beneficiaries;
CREATE TABLE beneficiaries(
						beneficiary_id INT PRIMARY KEY AUTO_INCREMENT,
                        account_id INT NOT NULL,
                        beneficiary_name VARCHAR(100) NOT NULL,
                        beneficiary_account_no VARCHAR(20) NOT NULL,
                        bank_name VARCHAR(100) NOT NULL,
                        ifsc_code VARCHAR(20) NOT NULL,
                        FOREIGN KEY (account_id) REFERENCES accounts(account_id));

SHOW tables;
DESC beneficiaries;
SELECT * FROM beneficiaries;

DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions(
						transaction_id INT PRIMARY KEY AUTO_INCREMENT,
                        account_id INT NOT NULL,
                        beneficiary_id INT,
                        transaction_type ENUM('Deposit', 'Withdrawal', 'Transfer') NOT NULL,
                        amount DECIMAL(15, 2) NOT NULL,
                        transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                        transaction_status ENUM('Success', 'Failed', 'Pending') DEFAULT 'Success',
                        FOREIGN KEY (account_id) REFERENCES accounts(account_id),
                        FOREIGN KEY (beneficiary_id) REFERENCES beneficiaries(beneficiary_id));

SHOW tables;
DESC transactions;
SELECT * FROM transactions;

DROP TABLE IF EXISTS cards;
CREATE TABLE cards(
				card_id INT PRIMARY KEY AUTO_INCREMENT,
                account_id INT NOT NULL,
                card_number VARCHAR(20) UNIQUE NOT NULL,
                card_type ENUM('Debit', 'Credit') NOT NULL,
                issue_date DATE NOT NULL,
                expiry_date DATE NOT NULL,
                card_status ENUM('Active', 'Blocked', 'Expired') DEFAULT 'Active',
                FOREIGN KEY (account_id) REFERENCES accounts(account_id));

SHOW tables;
DESC cards;
SELECT * FROM cards;

DROP TABLE IF EXISTS loans;
CREATE TABLE loans(
				loan_id INT PRIMARY KEY AUTO_INCREMENT,
                customer_id INT NOT NULL,
                loan_type VARCHAR(50) NOT NULL,
                loan_amount DECIMAL(15, 2) NOT NULL,
                interest_rate DECIMAL(5, 2) NOT NULL,
                start_date DATE NOT NULL,
                tenure_months INT NOT NULL,
                loan_status ENUM('Active', 'Closed') DEFAULT 'Active',
                FOREIGN KEY (customer_id) REFERENCES customers(customer_id));

SHOW tables;
DESC loans;
SELECT * FROM loans;

DROP TABLE IF EXISTS emi_payments;
CREATE TABLE emi_payments(
						emi_id INT PRIMARY KEY AUTO_INCREMENT,
                        loan_id INT NOT NULL,
                        emi_amount DECIMAL(15, 2) NOT NULL,
                        payment_date DATE NOT NULL,
                        payment_status ENUM('Paid', 'Pending', 'Missed') DEFAULT 'Pending',
                        FOREIGN KEY (loan_id) REFERENCES loans(loan_id));

SHOW tables;
DESC emi_payments;
SELECT * FROM emi_payments;

DROP TABLE IF EXISTS fraud_alerts;
CREATE TABLE fraud_alerts(
						alert_id INT PRIMARY KEY AUTO_INCREMENT,
                        transaction_id INT NOT NULL,
                        alert_type VARCHAR(100) NOT NULL,
                        risk_level ENUM('Low', 'Medium', 'High') NOT NULL,
                        alert_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                        alert_status ENUM('Open', 'Investigating', 'Resolved') DEFAULT 'Open',
                        FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id));

SHOW tables;
DESC transactions;
SELECT * FROM transactions;

SELECT
	TABLE_NAME, 
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE 
	REFERENCED_TABLE_NAME IS NOT NULL
    AND
    TABLE_SCHEMA = DATABASE();

INSERT INTO customers (first_name, last_name, gender, date_of_birth, phone, email, address, aadhaar_no, customer_status)
VALUES
('Aarav', 'Sharma', 'Male', '1992-05-14', '9876500001', 'aarav.sharma@bankingmanagementsystem.ac.uk', 'Bengaluru, Karnataka', '483920174561', 'Active'),
('Vivaan', 'Patel', 'Male', '1988-09-22', '9876500002', 'vivaan.patel@bankingmanagementsystem.ac.uk', 'Ahmedabad, Gujarat', '521483907126', 'Active'),
('Aditya', 'Verma', 'Male', '1995-11-10', '9876500003', 'aditya.verma@bankingmanagementsystem.ac.uk', 'Jaipur, Rajasthan', '709154382617', 'Active'),
('Vihaan', 'Gupta', 'Male', '1990-07-18', '9876500004', 'vihaan.gupta@bankingmanagementsystem.ac.uk', 'Kolkata, West Bengal', '394726518204', 'Active'),
('Arjun', 'Singh', 'Male', '1986-01-28', '9876500005', 'arjun.singh@bankingmanagementsystem.ac.uk', 'Dehradun, Uttarakhand', '648315729104', 'Active'),
('Sai', 'Reddy', 'Male', '1993-08-05', '9876500006', 'sai.reddy@bankingmanagementsystem.ac.uk', 'Hyderabad, Telangana', '930417526184', 'Active'),
('Krishna', 'Nair', 'Male', '1998-02-13', '9876500007', 'krishna.nair@bankingmanagementsystem.ac.uk', 'Kochi, Kerala', '156742983015', 'Active'),
('Rohan', 'Joshi', 'Male', '1991-04-21', '9876500008', 'rohan.joshi@bankingmanagementsystem.ac.uk', 'Pune, Maharashtra', '480371956281', 'Active'),
('Karan', 'Malhotra', 'Male', '1987-10-09', '9876500009', 'karan.malhotra@bankingmanagementsystem.ac.uk', 'Chandigarh, Chandigarh', '762015438920', 'Active'),
('Rahul', 'Mehta', 'Male', '1994-12-03', '9876500010', 'rahul.mehta@bankingmanagementsystem.ac.uk', 'Ahmedabad, Gujarat', '291540738615', 'Active'),
('Ananya', 'Sharma', 'Female', '1996-06-19', '9876500011', 'ananya.sharma@bankingmanagementsystem.ac.uk', 'Bengaluru, Karnataka', '836271549018', 'Active'),
('Priya', 'Patel', 'Female', '1989-03-27', '9876500012', 'priya.patel@bankingmanagementsystem.ac.uk', 'Ahmedabad, Gujarat', '415972860134', 'Active'),
('Aisha', 'Khan', 'Female', '1997-09-11', '9876500013', 'aisha.khan@bankingmanagementsystem.ac.uk', 'Lucknow, Uttar Pradesh', '692317845016', 'Active'),
('Sneha', 'Iyer', 'Female', '1993-02-25', '9876500014', 'sneha.iyer@bankingmanagementsystem.ac.uk', 'Chennai, Tamil Nadu', '510248697341', 'Active'),
('Pooja', 'Gupta', 'Female', '1985-11-14', '9876500015', 'pooja.gupta@bankingmanagementsystem.ac.uk', 'Vadodara, Gujarat', '874915263108', 'Active'),
('Meera', 'Rao', 'Female', '1992-08-30', '9876500016', 'meera.rao@bankingmanagementsystem.ac.uk', 'Mysuru, Karnataka', '342861759204', 'Active'),
('Kavya', 'Nair', 'Female', '1998-05-09', '9876500017', 'kavya.nair@bankingmanagementsystem.ac.uk', 'Kochi, Kerala', '785493126450', 'Active'),
('Ishita', 'Joshi', 'Female', '1991-01-17', '9876500018', 'ishita.joshi@bankingmanagementsystem.ac.uk', 'Jaipur, Rajasthan', '264180593741', 'Active'),
('Neha', 'Verma', 'Female', '1994-10-28', '9876500019', 'neha.verma@bankingmanagementsystem.ac.uk', 'Lucknow, Uttar Pradesh', '917350482615', 'Active'),
('Riya', 'Saxena', 'Female', '1990-12-06', '9876500020', 'riya.saxena@bankingmanagementsystem.ac.uk', 'Bhubaneswar, Odisha', '658214907381', 'Active'),
('Harsh', 'Agarwal', 'Male', '1988-04-12', '9876500021', 'harsh.agarwal@bankingmanagementsystem.ac.uk', 'Ludhiana, Punjab', '304182759461', 'Active'),
('Manish', 'Bansal', 'Male', '1995-09-29', '9876500022', 'manish.bansal@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '825731604192', 'Active'),
('Deepak', 'Yadav', 'Male', '1987-07-01', '9876500023', 'deepak.yadav@bankingmanagementsystem.ac.uk', 'Ghaziabad, Uttar Pradesh', '197463820541', 'Inactive'),
('Nikhil', 'Chauhan', 'Male', '1993-06-24', '9876500024', 'nikhil.chauhan@bankingmanagementsystem.ac.uk', 'Indore, Madhya Pradesh', '742950381624', 'Active'),
('Varun', 'Kapoor', 'Male', '1991-03-15', '9876500025', 'varun.kapoor@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '681527304918', 'Active'),
('Akash', 'Mishra', 'Male', '1997-11-08', '9876500026', 'akash.mishra@bankingmanagementsystem.ac.uk', 'Kanpur, Uttar Pradesh', '934280175643', 'Active'),
('Siddharth', 'Kulkarni', 'Male', '1989-02-20', '9876500027', 'siddharth.kulkarni@bankingmanagementsystem.ac.uk', 'Pune, Maharashtra', '250814697325', 'Active'),
('Yash', 'Desai', 'Male', '1994-08-17', '9876500028', 'yash.desai@bankingmanagementsystem.ac.uk', 'Surat, Gujarat', '519706428315', 'Blocked'),
('Mohit', 'Arora', 'Male', '1992-10-31', '9876500029', 'mohit.arora@bankingmanagementsystem.ac.uk', 'Amritsar, Punjab', '763182495014', 'Active'),
('Abhishek', 'Pandey', 'Male', '1986-05-23', '9876500030', 'abhishek.pandey@bankingmanagementsystem.ac.uk', 'Prayagraj, Uttar Pradesh', '401695827314', 'Active'),
('Diya', 'Shah', 'Female', '1995-04-18', '9876500031', 'diya.shah@bankingmanagementsystem.ac.uk', 'Ahmedabad, Gujarat', '942751836014', 'Active'),
('Nandini', 'Kulkarni', 'Female', '1990-07-27', '9876500032', 'nandini.kulkarni@bankingmanagementsystem.ac.uk', 'Pune, Maharashtra', '315804926741', 'Active'),
('Simran', 'Kaur', 'Female', '1992-09-14', '9876500033', 'simran.kaur@bankingmanagementsystem.ac.uk', 'Amritsar, Punjab', '681902754381', 'Active'),
('Aditi', 'Mishra', 'Female', '1998-12-22', '9876500034', 'aditi.mishra@bankingmanagementsystem.ac.uk', 'Prayagraj, Uttar Pradesh', '234176985042', 'Active'),
('Shruti', 'Bose', 'Female', '1988-01-09', '9876500035', 'shruti.bose@bankingmanagementsystem.ac.uk', 'Kolkata, West Bengal', '809251476315', 'Inactive'),
('Tanya', 'Kapoor', 'Female', '1996-03-05', '9876500036', 'tanya.kapoor@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '573014926845', 'Active'),
('Radhika', 'Menon', 'Female', '1991-08-16', '9876500037', 'radhika.menon@bankingmanagementsystem.ac.uk', 'Kochi, Kerala', '916357420184', 'Active'),
('Anjali', 'Deshmukh', 'Female', '1987-11-30', '9876500038', 'anjali.deshmukh@bankingmanagementsystem.ac.uk', 'Nagpur, Maharashtra', '280746193514', 'Active'),
('Payal', 'Jain', 'Female', '1994-05-11', '9876500039', 'payal.jain@bankingmanagementsystem.ac.uk', 'Jaipur, Rajasthan', '751903864125', 'Blocked'),
('Komal', 'Chopra', 'Female', '1993-02-02', '9876500040', 'komal.chopra@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '462905713840', 'Active'),
('Ritesh', 'Soni', 'Male', '1985-09-18', '9876500041', 'ritesh.soni@bankingmanagementsystem.ac.uk', 'Bhopal, Madhya Pradesh', '803541927615', 'Active'),
('Gaurav', 'Tripathi', 'Male', '1997-01-26', '9876500042', 'gaurav.tripathi@bankingmanagementsystem.ac.uk', 'Lucknow, Uttar Pradesh', '394862701543', 'Active'),
('Aniket', 'Patil', 'Male', '1992-04-04', '9876500043', 'aniket.patil@bankingmanagementsystem.ac.uk', 'Pune, Maharashtra', '607319845214', 'Active'),
('Rishi', 'Thakur', 'Male', '1990-06-15', '9876500044', 'rishi.thakur@bankingmanagementsystem.ac.uk', 'Shimla, Himachal Pradesh', '281574639105', 'Active'),
('Dev', 'Chatterjee', 'Male', '1996-08-09', '9876500045', 'dev.chatterjee@bankingmanagementsystem.ac.uk', 'Kolkata, West Bengal', '735028164910', 'Active'),
('Tanmay', 'Naidu', 'Male', '1989-10-20', '9876500046', 'tanmay.naidu@bankingmanagementsystem.ac.uk', 'Visakhapatnam, Andhra Pradesh', '164982375041', 'Active'),
('Aman', 'Khanna', 'Male', '1993-03-12', '9876500047', 'aman.khanna@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '591840327614', 'Active'),
('Raghav', 'Gill', 'Male', '1995-12-01', '9876500048', 'raghav.gill@bankingmanagementsystem.ac.uk', 'Jalandhar, Punjab', '847316205491', 'Active'),
('Kunal', 'Srivastava', 'Male', '1991-07-07', '9876500049', 'kunal.srivastava@bankingmanagementsystem.ac.uk', 'Lucknow, Uttar Pradesh', '320758416904', 'Active'),
('Dhruv', 'Bhat', 'Male', '1998-02-28', '9876500050', 'dhruv.bhat@bankingmanagementsystem.ac.uk', 'Mysuru, Karnataka', '918246570314', 'Active'),
('Aryan', 'Kulshrestha', 'Male', '1993-04-16', '9876500051', 'aryan.kulshrestha@bankingmanagementsystem.ac.uk', 'Noida, Uttar Pradesh', '572941836015', 'Active'),
('Vikas', 'Tiwari', 'Male', '1988-11-24', '9876500052', 'vikas.tiwari@bankingmanagementsystem.ac.uk', 'Varanasi, Uttar Pradesh', '834205791643', 'Active'),
('Rohit', 'Shukla', 'Male', '1991-02-13', '9876500053', 'rohit.shukla@bankingmanagementsystem.ac.uk', 'Kanpur, Uttar Pradesh', '149627503814', 'Active'),
('Saurabh', 'Jha', 'Male', '1995-07-08', '9876500054', 'saurabh.jha@bankingmanagementsystem.ac.uk', 'Patna, Bihar', '620485731942', 'Active'),
('Ayush', 'Sinha', 'Male', '1997-09-21', '9876500055', 'ayush.sinha@bankingmanagementsystem.ac.uk', 'Ranchi, Jharkhand', '358721604915', 'Active'),
('Nitin', 'Dubey', 'Male', '1987-01-30', '9876500056', 'nitin.dubey@bankingmanagementsystem.ac.uk', 'Bhopal, Madhya Pradesh', '907315482164', 'Inactive'),
('Shivam', 'Maurya', 'Male', '1998-06-18', '9876500057', 'shivam.maurya@bankingmanagementsystem.ac.uk', 'Lucknow, Uttar Pradesh', '285046719354', 'Active'),
('Uday', 'Pillai', 'Male', '1992-12-02', '9876500058', 'uday.pillai@bankingmanagementsystem.ac.uk', 'Thiruvananthapuram, Kerala', '731895462018', 'Active'),
('Ashwin', 'Menon', 'Male', '1989-05-26', '9876500059', 'ashwin.menon@bankingmanagementsystem.ac.uk', 'Kochi, Kerala', '514203897651', 'Active'),
('Vivek', 'Bhardwaj', 'Male', '1994-10-15', '9876500060', 'vivek.bhardwaj@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '860147352914', 'Blocked'),
('Sakshi', 'Arora', 'Female', '1996-03-29', '9876500061', 'sakshi.arora@bankingmanagementsystem.ac.uk', 'Ludhiana, Punjab', '416837205194', 'Active'),
('Muskan', 'Singhal', 'Female', '1993-08-11', '9876500062', 'muskan.singhal@bankingmanagementsystem.ac.uk', 'Jaipur, Rajasthan', '983517462041', 'Active'),
('Palak', 'Ahuja', 'Female', '1995-11-05', '9876500063', 'palak.ahuja@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '250894617352', 'Active'),
('Bhavna', 'Sethi', 'Female', '1990-04-20', '9876500064', 'bhavna.sethi@bankingmanagementsystem.ac.uk', 'Chandigarh, Chandigarh', '604217835941', 'Active'),
('Nikita', 'Madan', 'Female', '1997-12-09', '9876500065', 'nikita.madan@bankingmanagementsystem.ac.uk', 'Gurugram, Haryana', '795103824615', 'Active'),
('Shreya', 'Roy', 'Female', '1992-06-03', '9876500066', 'shreya.roy@bankingmanagementsystem.ac.uk', 'Kolkata, West Bengal', '312475980614', 'Active'),
('Mansi', 'Das', 'Female', '1988-10-28', '9876500067', 'mansi.das@bankingmanagementsystem.ac.uk', 'Bhubaneswar, Odisha', '871460523918', 'Inactive'),
('Sonal', 'Bajaj', 'Female', '1994-02-14', '9876500068', 'sonal.bajaj@bankingmanagementsystem.ac.uk', 'Indore, Madhya Pradesh', '563918240715', 'Active'),
('Preeti', 'Chawla', 'Female', '1991-09-17', '9876500069', 'preeti.chawla@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '140973682451', 'Blocked'),
('Tanvi', 'Purohit', 'Female', '1998-05-24', '9876500070', 'tanvi.purohit@bankingmanagementsystem.ac.uk', 'Udaipur, Rajasthan', '628594173205', 'Active'),
('Laksh', 'Chawla', 'Male', '1989-07-27', '9876500071', 'laksh.chawla@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '951732864105', 'Active'),
('Pranav', 'Saxena', 'Male', '1993-01-11', '9876500072', 'pranav.saxena@bankingmanagementsystem.ac.uk', 'Lucknow, Uttar Pradesh', '347150982614', 'Active'),
('Ansh', 'Goswami', 'Male', '1996-04-08', '9876500073', 'ansh.goswami@bankingmanagementsystem.ac.uk', 'Haridwar, Uttarakhand', '702841956314', 'Active'),
('Lokesh', 'Rawat', 'Male', '1990-11-23', '9876500074', 'lokesh.rawat@bankingmanagementsystem.ac.uk', 'Dehradun, Uttarakhand', '281593704615', 'Active'),
('Pratik', 'Chaudhary', 'Male', '1992-08-30', '9876500075', 'pratik.chaudhary@bankingmanagementsystem.ac.uk', 'Surat, Gujarat', '639714820531', 'Active'),
('Hemant', 'Tomar', 'Male', '1987-05-12', '9876500076', 'hemant.tomar@bankingmanagementsystem.ac.uk', 'Agra, Uttar Pradesh', '815962470314', 'Active'),
('Mayank', 'Bisht', 'Male', '1995-10-01', '9876500077', 'mayank.bisht@bankingmanagementsystem.ac.uk', 'Nainital, Uttarakhand', '430718259614', 'Active'),
('Akhil', 'Rajput', 'Male', '1991-12-16', '9876500078', 'akhil.rajput@bankingmanagementsystem.ac.uk', 'Gwalior, Madhya Pradesh', '168405972314', 'Active'),
('Naveen', 'Solanki', 'Male', '1994-06-27', '9876500079', 'naveen.solanki@bankingmanagementsystem.ac.uk', 'Jaipur, Rajasthan', '924176503815', 'Active'),
('Parth', 'Vyas', 'Male', '1998-03-04', '9876500080', 'parth.vyas@bankingmanagementsystem.ac.uk', 'Ahmedabad, Gujarat', '570384261914', 'Active'),
('Ira', 'Kapoor', 'Female', '1993-07-13', '9876500081', 'ira.kapoor@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '246931857014', 'Active'),
('Anushka', 'Joshi', 'Female', '1996-09-06', '9876500082', 'anushka.joshi@bankingmanagementsystem.ac.uk', 'Pune, Maharashtra', '805213479614', 'Active'),
('Khushi', 'Bhatia', 'Female', '1997-02-19', '9876500083', 'khushi.bhatia@bankingmanagementsystem.ac.uk', 'Chandigarh, Chandigarh', '314697820541', 'Active'),
('Rupal', 'Parmar', 'Female', '1989-04-28', '9876500084', 'rupal.parmar@bankingmanagementsystem.ac.uk', 'Vadodara, Gujarat', '982457361014', 'Active'),
('Juhi', 'Trivedi', 'Female', '1994-01-09', '9876500085', 'juhi.trivedi@bankingmanagementsystem.ac.uk', 'Rajkot, Gujarat', '461803729154', 'Active'),
('Monika', 'Yadav', 'Female', '1992-08-02', '9876500086', 'monika.yadav@bankingmanagementsystem.ac.uk', 'Noida, Uttar Pradesh', '157924680341', 'Inactive'),
('Ritu', 'Pandit', 'Female', '1991-11-18', '9876500087', 'ritu.pandit@bankingmanagementsystem.ac.uk', 'Jammu, Jammu and Kashmir', '620351947814', 'Active'),
('Shivani', 'Bhatt', 'Female', '1995-05-31', '9876500088', 'shivani.bhatt@bankingmanagementsystem.ac.uk', 'Dehradun, Uttarakhand', '748126395014', 'Active'),
('Pallavi', 'Kohli', 'Female', '1990-12-12', '9876500089', 'pallavi.kohli@bankingmanagementsystem.ac.uk', 'Amritsar, Punjab', '235807146914', 'Blocked'),
('Rashmi', 'Soni', 'Female', '1998-10-07', '9876500090', 'rashmi.soni@bankingmanagementsystem.ac.uk', 'Bhopal, Madhya Pradesh', '890461725314', 'Active'),
('Harshit', 'Malik', 'Male', '1993-05-20', '9876500091', 'harshit.malik@bankingmanagementsystem.ac.uk', 'Rohtak, Haryana', '518247930614', 'Active'),
('Yuvraj', 'Bedi', 'Male', '1988-02-25', '9876500092', 'yuvraj.bedi@bankingmanagementsystem.ac.uk', 'Jalandhar, Punjab', '163805297414', 'Active'),
('Sameer', 'Rastogi', 'Male', '1994-09-03', '9876500093', 'sameer.rastogi@bankingmanagementsystem.ac.uk', 'Bareilly, Uttar Pradesh', '704619358214', 'Active'),
('Rajat', 'Sabharwal', 'Male', '1991-06-11', '9876500094', 'rajat.sabharwal@bankingmanagementsystem.ac.uk', 'Delhi, Delhi', '281637459014', 'Active'),
('Kartik', 'Garg', 'Male', '1996-03-26', '9876500095', 'kartik.garg@bankingmanagementsystem.ac.uk', 'Hisar, Haryana', '936214857104', 'Active'),
('Om', 'Mishra', 'Male', '1998-01-14', '9876500096', 'om.mishra@bankingmanagementsystem.ac.uk', 'Prayagraj, Uttar Pradesh', '452318790614', 'Active'),
('Adarsh', 'Rana', 'Male', '1992-11-09', '9876500097', 'adarsh.rana@bankingmanagementsystem.ac.uk', 'Shimla, Himachal Pradesh', '817340625914', 'Active'),
('Chetan', 'Negi', 'Male', '1989-07-01', '9876500098', 'chetan.negi@bankingmanagementsystem.ac.uk', 'Dehradun, Uttarakhand', '694182573014', 'Active'),
('Keshav', 'Mathur', 'Male', '1995-08-22', '9876500099', 'keshav.mathur@bankingmanagementsystem.ac.uk', 'Jaipur, Rajasthan', '130784962514', 'Active'),
('Tushar', 'Chandra', 'Male', '1997-04-10', '9876500100', 'tushar.chandra@bankingmanagementsystem.ac.uk', 'Patna, Bihar', '573196048214', 'Active');

SELECT COUNT(*) FROM customers;
SELECT * FROM customers;

INSERT INTO branches (branch_name, city, state, ifsc_code, phone)
VALUES
('Bengaluru Main Branch', 'Bengaluru', 'Karnataka', 'BMSB0001001', '08045678001'),
('Mumbai Central Branch', 'Mumbai', 'Maharashtra', 'BMSB0001002', '02245678002'),
('Delhi Connaught Branch', 'New Delhi', 'Delhi', 'BMSB0001003', '01145678003'),
('Chennai City Branch', 'Chennai', 'Tamil Nadu', 'BMSB0001004', '04445678004'),
('Hyderabad Main Branch', 'Hyderabad', 'Telangana', 'BMSB0001005', '04045678005'),
('Kolkata Central Branch', 'Kolkata', 'West Bengal', 'BMSB0001006', '03345678006'),
('Ahmedabad Branch', 'Ahmedabad', 'Gujarat', 'BMSB0001007', '07945678007'),
('Pune Branch', 'Pune', 'Maharashtra', 'BMSB0001008', '02045678008'),
('Jaipur Branch', 'Jaipur', 'Rajasthan', 'BMSB0001009', '014145678009'),
('Lucknow Branch', 'Lucknow', 'Uttar Pradesh', 'BMSB0001010', '052245678010'),
('Kochi Branch', 'Kochi', 'Kerala', 'BMSB0001011', '048445678011'),
('Bhopal Branch', 'Bhopal', 'Madhya Pradesh', 'BMSB0001012', '075545678012');

SELECT COUNT(*) FROM branches;
SELECT * FROM branches;

INSERT INTO account_types (type_name, minimum_balance)
VALUES
('Savings Account', 1000.00),
('Current Account', 10000.00),
('Salary Account', 0.00),
('Fixed Deposit Account', 5000.00),
('Premium Savings Account', 25000.00);

SELECT COUNT(*) FROM account_types;
SELECT * FROM account_types;

INSERT INTO employees (branch_id, first_name, last_name, designation, salary, hire_date, phone)
VALUES
(1, 'Rajesh', 'Kumar', 'Branch Manager', 95000.00, '2016-04-12', '9000000001'),
(1, 'Meena', 'Sharma', 'Assistant Manager', 65000.00, '2018-07-19', '9000000002'),
(1, 'Vikram', 'Rao', 'Loan Officer', 55000.00, '2019-03-25', '9000000003'),
(1, 'Pooja', 'Nair', 'Customer Service Officer', 42000.00, '2020-08-14', '9000000004'),
(1, 'Karthik', 'Iyer', 'Cashier', 35000.00, '2021-11-05', '9000000005'),
(2, 'Amit', 'Desai', 'Branch Manager', 98000.00, '2015-06-18', '9000000006'),
(2, 'Neha', 'Patel', 'Assistant Manager', 68000.00, '2017-09-22', '9000000007'),
(2, 'Rohit', 'Shah', 'Relationship Manager', 60000.00, '2019-01-15', '9000000008'),
(2, 'Snehal', 'Joshi', 'Customer Service Officer', 43000.00, '2021-02-11', '9000000009'),
(2, 'Manoj', 'Pawar', 'Cashier', 36000.00, '2022-05-09', '9000000010'),
(3, 'Sanjay', 'Verma', 'Branch Manager', 97000.00, '2014-11-10', '9000000011'),
(3, 'Ritu', 'Kapoor', 'Assistant Manager', 67000.00, '2017-05-16', '9000000012'),
(3, 'Arvind', 'Singh', 'Loan Officer', 56000.00, '2019-07-08', '9000000013'),
(3, 'Kavita', 'Malhotra', 'Relationship Manager', 61000.00, '2020-01-21', '9000000014'),
(3, 'Deepak', 'Yadav', 'Cashier', 34000.00, '2022-09-12', '9000000015'),
(4, 'Suresh', 'Reddy', 'Branch Manager', 93000.00, '2016-02-14', '9000000016'),
(4, 'Lakshmi', 'Krishnan', 'Assistant Manager', 64000.00, '2018-06-30', '9000000017'),
(4, 'Ajay', 'Menon', 'Loan Officer', 54000.00, '2020-03-17', '9000000018'),
(4, 'Divya', 'Iyer', 'Customer Service Officer', 41000.00, '2021-07-22', '9000000019'),
(4, 'Prakash', 'Nair', 'Cashier', 35000.00, '2023-01-10', '9000000020'),
(5, 'Ramesh', 'Naidu', 'Branch Manager', 94000.00, '2015-08-25', '9000000021'),
(5, 'Anjali', 'Rao', 'Assistant Manager', 66000.00, '2017-12-05', '9000000022'),
(5, 'Harish', 'Reddy', 'Relationship Manager', 59000.00, '2019-04-18', '9000000023'),
(5, 'Swathi', 'Kumar', 'Customer Service Officer', 42000.00, '2021-10-06', '9000000024'),
(5, 'Naveen', 'Sharma', 'Cashier', 35000.00, '2022-12-14', '9000000025'),
(6, 'Debashis', 'Roy', 'Branch Manager', 92000.00, '2016-09-11', '9000000026'),
(6, 'Madhuri', 'Das', 'Assistant Manager', 63000.00, '2018-04-23', '9000000027'),
(6, 'Subhajit', 'Ghosh', 'Loan Officer', 53000.00, '2020-06-19', '9000000028'),
(6, 'Priyanka', 'Bose', 'Customer Service Officer', 41000.00, '2021-08-15', '9000000029'),
(6, 'Anirban', 'Sen', 'Cashier', 35000.00, '2023-02-07', '9000000030'),
(7, 'Harshad', 'Mehta', 'Branch Manager', 96000.00, '2015-03-18', '9000000031'),
(7, 'Nisha', 'Shah', 'Assistant Manager', 65000.00, '2018-01-25', '9000000032'),
(7, 'Dhaval', 'Patel', 'Loan Officer', 54000.00, '2019-09-14', '9000000033'),
(7, 'Rina', 'Joshi', 'Customer Service Officer', 42000.00, '2021-03-08', '9000000034'),
(7, 'Yogesh', 'Trivedi', 'Cashier', 35000.00, '2022-07-16', '9000000035'),
(8, 'Mahesh', 'Kulkarni', 'Branch Manager', 95000.00, '2016-05-20', '9000000036'),
(8, 'Snehal', 'Deshmukh', 'Assistant Manager', 66000.00, '2017-11-12', '9000000037'),
(8, 'Amol', 'Patil', 'Relationship Manager', 59000.00, '2019-06-04', '9000000038'),
(8, 'Priya', 'Jadhav', 'Customer Service Officer', 42000.00, '2020-10-19', '9000000039'),
(8, 'Sachin', 'More', 'Cashier', 36000.00, '2022-03-27', '9000000040'),
(9, 'Rajiv', 'Chauhan', 'Branch Manager', 93000.00, '2016-08-09', '9000000041'),
(9, 'Kiran', 'Sharma', 'Assistant Manager', 64000.00, '2018-03-15', '9000000042'),
(9, 'Manoj', 'Saini', 'Loan Officer', 53000.00, '2020-01-22', '9000000043'),
(9, 'Rashmi', 'Agarwal', 'Relationship Manager', 60000.00, '2021-04-12', '9000000044'),
(9, 'Vishal', 'Meena', 'Cashier', 35000.00, '2022-08-30', '9000000045'),
(10, 'Alok', 'Srivastava', 'Branch Manager', 92000.00, '2015-10-17', '9000000046'),
(10, 'Shalini', 'Mishra', 'Assistant Manager', 63000.00, '2018-05-21', '9000000047'),
(10, 'Pankaj', 'Tiwari', 'Loan Officer', 54000.00, '2019-12-10', '9000000048'),
(10, 'Neelam', 'Verma', 'Customer Service Officer', 41000.00, '2021-06-18', '9000000049'),
(10, 'Rahul', 'Pandey', 'Cashier', 35000.00, '2023-01-05', '9000000050'),
(11, 'Joseph', 'Mathew', 'Branch Manager', 94000.00, '2016-07-14', '9000000051'),
(11, 'Anitha', 'Menon', 'Assistant Manager', 65000.00, '2018-09-06', '9000000052'),
(11, 'Vishnu', 'Pillai', 'Relationship Manager', 59000.00, '2020-02-17', '9000000053'),
(11, 'Reshma', 'Nair', 'Customer Service Officer', 42000.00, '2021-11-23', '9000000054'),
(11, 'Sandeep', 'Kumar', 'Cashier', 35000.00, '2022-06-13', '9000000055'),
(12, 'Ashok', 'Shukla', 'Branch Manager', 91000.00, '2015-12-01', '9000000056'),
(12, 'Kavita', 'Joshi', 'Assistant Manager', 63000.00, '2018-08-18', '9000000057'),
(12, 'Rakesh', 'Mishra', 'Loan Officer', 52000.00, '2019-11-25', '9000000058'),
(12, 'Swati', 'Patel', 'Customer Service Officer', 41000.00, '2021-05-09', '9000000059'),
(12, 'Vijay', 'Soni', 'Cashier', 34000.00, '2022-10-14', '9000000060');

SELECT COUNT(*) FROM employees;
SELECT * FROM employees;

INSERT INTO accounts (customer_id, branch_id, account_type_id, account_number, balance, open_date, account_status)
VALUES
(1, 1, 1, '100000000001', 85000.00, '2020-03-15', 'Active'),
(1, 1, 4, '100000000002', 500000.00, '2022-06-10', 'Active'),
(2, 7, 1, '100000000003', 42000.00, '2019-08-21', 'Active'),
(3, 9, 3, '100000000004', 28000.00, '2021-01-18', 'Active'),
(4, 6, 1, '100000000005', 125000.00, '2018-11-05', 'Active'),
(5, 12, 2, '100000000006', 750000.00, '2020-07-14', 'Active'),
(6, 5, 1, '100000000007', 56000.00, '2022-02-20', 'Active'),
(7, 11, 3, '100000000008', 18000.00, '2023-04-11', 'Active'),
(8, 8, 1, '100000000009', 92000.00, '2019-12-09', 'Active'),
(9, 3, 5, '100000000010', 450000.00, '2021-09-16', 'Active'),
(10, 7, 1, '100000000011', 67000.00, '2020-05-22', 'Active'),
(11, 1, 3, '100000000012', 35000.00, '2022-07-01', 'Active'),
(12, 7, 1, '100000000013', 78000.00, '2019-03-13', 'Active'),
(13, 10, 2, '100000000014', 620000.00, '2021-11-19', 'Active'),
(14, 4, 1, '100000000015', 51000.00, '2020-08-27', 'Active'),
(15, 7, 4, '100000000016', 750000.00, '2023-01-12', 'Active'),
(16, 11, 1, '100000000017', 94000.00, '2018-06-25', 'Active'),
(17, 11, 3, '100000000018', 22000.00, '2022-10-03', 'Active'),
(18, 9, 1, '100000000019', 61000.00, '2019-05-30', 'Active'),
(19, 10, 5, '100000000020', 650000.00, '2021-04-18', 'Active'),
(20, 3, 1, '100000000021', 73000.00, '2020-09-12', 'Active'),
(21, 9, 2, '100000000022', 850000.00, '2018-12-14', 'Active'),
(22, 3, 1, '100000000023', 48000.00, '2022-03-22', 'Active'),
(23, 10, 3, '100000000024', 15000.00, '2023-05-16', 'Active'),
(24, 8, 1, '100000000025', 69000.00, '2020-01-25', 'Active'),
(25, 3, 5, '100000000026', 350000.00, '2021-08-09', 'Active'),
(26, 10, 1, '100000000027', 58000.00, '2019-10-17', 'Active'),
(27, 8, 4, '100000000028', 900000.00, '2022-12-06', 'Active'),
(28, 7, 1, '100000000029', 45000.00, '2021-02-11', 'Active'),
(29, 2, 3, '100000000030', 27000.00, '2023-03-29', 'Active'),
(30, 2, 1, '100000000031', 81000.00, '2019-07-08', 'Active'),
(31, 7, 1, '100000000032', 53000.00, '2020-11-15', 'Active'),
(32, 8, 3, '100000000033', 24000.00, '2022-01-19', 'Active'),
(33, 2, 2, '100000000034', 950000.00, '2018-09-26', 'Active'),
(34, 10, 1, '100000000035', 72000.00, '2021-06-14', 'Active'),
(35, 6, 5, '100000000036', 520000.00, '2020-12-20', 'Active'),
(36, 3, 1, '100000000037', 63000.00, '2019-04-07', 'Active'),
(37, 11, 3, '100000000038', 19000.00, '2023-02-15', 'Active'),
(38, 8, 1, '100000000039', 88000.00, '2020-06-29', 'Active'),
(39, 9, 4, '100000000040', 600000.00, '2022-05-18', 'Active'),
(40, 12, 1, '100000000041', 47000.00, '2021-09-23', 'Active'),
(41, 12, 2, '100000000042', 720000.00, '2019-11-11', 'Active'),
(42, 5, 1, '100000000043', 59000.00, '2020-02-06', 'Active'),
(43, 4, 3, '100000000044', 21000.00, '2022-08-24', 'Active'),
(44, 6, 1, '100000000045', 76000.00, '2018-10-30', 'Active'),
(45, 6, 5, '100000000046', 400000.00, '2021-12-13', 'Active'),
(46, 5, 1, '100000000047', 54000.00, '2020-04-17', 'Active'),
(47, 3, 3, '100000000048', 16000.00, '2023-01-28', 'Active'),
(48, 10, 1, '100000000049', 67000.00, '2019-08-05', 'Active'),
(49, 2, 4, '100000000050', 850000.00, '2022-07-21', 'Active'),
(50, 2, 1, '100000000051', 91000.00, '2020-10-12', 'Active'),
(51, 10, 1, '100000000052', 64000.00, '2021-03-18', 'Active'),
(52, 10, 3, '100000000053', 26000.00, '2022-06-25', 'Active'),
(53, 10, 1, '100000000054', 73000.00, '2019-09-14', 'Active'),
(54, 12, 2, '100000000055', 680000.00, '2020-05-08', 'Active'),
(55, 12, 1, '100000000056', 58000.00, '2021-11-22', 'Active'),
(56, 12, 3, '100000000057', 17000.00, '2023-02-10', 'Active'),
(57, 5, 1, '100000000058', 86000.00, '2018-07-16', 'Active'),
(58, 11, 4, '100000000059', 700000.00, '2022-09-05', 'Active'),
(59, 3, 1, '100000000060', 51000.00, '2020-01-29', 'Active'),
(60, 3, 5, '100000000061', 550000.00, '2021-06-18', 'Active'),
(61, 2, 1, '100000000062', 62000.00, '2019-03-12', 'Active'),
(62, 2, 3, '100000000063', 23000.00, '2022-04-07', 'Active'),
(63, 1, 1, '100000000064', 77000.00, '2020-08-15', 'Active'),
(64, 1, 2, '100000000065', 900000.00, '2018-11-19', 'Active'),
(65, 4, 1, '100000000066', 46000.00, '2021-02-28', 'Active'),
(66, 4, 3, '100000000067', 20000.00, '2023-05-14', 'Active'),
(67, 4, 5, '100000000068', 320000.00, '2020-12-01', 'Active'),
(68, 6, 1, '100000000069', 89000.00, '2019-06-23', 'Active'),
(69, 6, 4, '100000000070', 650000.00, '2022-03-17', 'Active'),
(70, 7, 1, '100000000071', 74000.00, '2020-04-09', 'Active'),
(71, 7, 3, '100000000072', 30000.00, '2021-07-26', 'Active'),
(72, 8, 1, '100000000073', 56000.00, '2018-10-13', 'Active'),
(73, 8, 2, '100000000074', 820000.00, '2019-12-04', 'Active'),
(74, 9, 1, '100000000075', 69000.00, '2020-06-11', 'Active'),
(75, 9, 5, '100000000076', 470000.00, '2021-10-22', 'Active'),
(76, 11, 1, '100000000077', 83000.00, '2019-05-15', 'Active'),
(77, 11, 3, '100000000078', 25000.00, '2023-01-09', 'Active'),
(78, 5, 1, '100000000079', 61000.00, '2020-02-19', 'Active'),
(79, 5, 4, '100000000080', 950000.00, '2022-08-12', 'Active'),
(80, 3, 1, '100000000081', 52000.00, '2018-06-21', 'Active'),
(81, 3, 3, '100000000082', 28000.00, '2021-04-16', 'Active'),
(82, 10, 1, '100000000083', 71000.00, '2019-11-27', 'Active'),
(83, 12, 2, '100000000084', 760000.00, '2020-09-09', 'Active'),
(84, 12, 1, '100000000085', 64000.00, '2021-12-18', 'Active'),
(85, 6, 3, '100000000086', 18000.00, '2023-03-02', 'Active'),
(86, 6, 5, '100000000087', 600000.00, '2019-08-24', 'Active'),
(87, 4, 1, '100000000088', 57000.00, '2020-05-30', 'Active'),
(88, 4, 4, '100000000089', 800000.00, '2022-11-15', 'Active'),
(89, 2, 1, '100000000090', 91000.00, '2018-12-07', 'Active'),
(90, 1, 1, '100000000091', 66000.00, '2019-10-18', 'Active'),
(91, 1, 3, '100000000092', 22000.00, '2022-02-14', 'Active'),
(92, 7, 5, '100000000093', 375000.00, '2021-05-23', 'Active'),
(93, 8, 1, '100000000094', 59000.00, '2020-07-31', 'Active'),
(94, 9, 2, '100000000095', 880000.00, '2018-08-20', 'Active'),
(95, 10, 1, '100000000096', 75000.00, '2021-09-14', 'Active'),
(96, 11, 3, '100000000097', 21000.00, '2023-04-05', 'Active'),
(97, 12, 1, '100000000098', 84000.00, '2019-01-17', 'Active'),
(98, 5, 4, '100000000099', 720000.00, '2022-06-08', 'Active'),
(99, 6, 1, '100000000100', 63000.00, '2020-03-26', 'Active'),
(100, 6, 1, '100000000101', 78000.00, '2021-08-16', 'Active'),
(1, 1, 5, '100000000102', 625000.00, '2023-02-18', 'Active'),
(2, 7, 3, '100000000103', 32000.00, '2022-09-12', 'Active'),
(3, 9, 1, '100000000104', 46000.00, '2021-04-07', 'Active'),
(4, 6, 4, '100000000105', 900000.00, '2020-12-19', 'Active'),
(5, 12, 1, '100000000106', 112000.00, '2022-05-24', 'Active'),
(6, 5, 3, '100000000107', 27000.00, '2023-01-11', 'Active'),
(7, 11, 1, '100000000108', 68000.00, '2020-06-30', 'Active'),
(8, 8, 5, '100000000109', 480000.00, '2021-11-08', 'Active'),
(9, 3, 1, '100000000110', 97000.00, '2019-09-25', 'Active'),
(10, 7, 4, '100000000111', 650000.00, '2022-07-15', 'Active'),
(11, 1, 1, '100000000112', 73000.00, '2020-02-17', 'Active'),
(12, 7, 3, '100000000113', 29000.00, '2021-10-06', 'Active'),
(13, 10, 1, '100000000114', 55000.00, '2019-05-28', 'Active'),
(14, 4, 5, '100000000115', 375000.00, '2023-03-20', 'Active'),
(15, 7, 2, '100000000116', 1100000.00, '2020-11-11', 'Active'),
(16, 11, 1, '100000000117', 82000.00, '2021-01-29', 'Active'),
(17, 11, 3, '100000000118', 26000.00, '2022-12-02', 'Active'),
(18, 9, 4, '100000000119', 550000.00, '2018-07-22', 'Active'),
(19, 10, 1, '100000000120', 64000.00, '2020-10-14', 'Active'),
(20, 3, 5, '100000000121', 720000.00, '2022-04-18', 'Active'),
(21, 9, 1, '100000000122', 59000.00, '2021-06-09', 'Active'),
(22, 3, 3, '100000000123', 24000.00, '2023-05-21', 'Active'),
(23, 10, 1, '100000000124', 87000.00, '2019-08-12', 'Active'),
(24, 8, 4, '100000000125', 820000.00, '2022-01-16', 'Active'),
(25, 3, 1, '100000000126', 76000.00, '2020-04-23', 'Active'),
(26, 10, 5, '100000000127', 430000.00, '2021-09-19', 'Active'),
(27, 8, 3, '100000000128', 31000.00, '2022-03-11', 'Active'),
(28, 7, 1, '100000000129', 49000.00, '2018-10-27', 'Active'),
(29, 2, 4, '100000000130', 700000.00, '2023-01-23', 'Active'),
(30, 2, 1, '100000000131', 93000.00, '2020-08-08', 'Active'),
(31, 7, 3, '100000000132', 19000.00, '2021-12-13', 'Active'),
(32, 8, 5, '100000000133', 390000.00, '2022-06-22', 'Active'),
(33, 2, 1, '100000000134', 68000.00, '2019-04-15', 'Active'),
(34, 10, 4, '100000000135', 950000.00, '2020-11-30', 'Active'),
(35, 6, 1, '100000000136', 54000.00, '2021-03-17', 'Active'),
(36, 3, 3, '100000000137', 22000.00, '2022-08-26', 'Active'),
(37, 11, 5, '100000000138', 500000.00, '2023-02-04', 'Active'),
(38, 8, 1, '100000000139', 85000.00, '2020-07-11', 'Active'),
(39, 9, 4, '100000000140', 620000.00, '2021-10-20', 'Active'),
(40, 12, 1, '100000000141', 58000.00, '2019-02-24', 'Active'),
(41, 12, 5, '100000000142', 680000.00, '2022-05-07', 'Active'),
(42, 5, 3, '100000000143', 25000.00, '2023-03-13', 'Active'),
(43, 4, 1, '100000000144', 71000.00, '2020-09-18', 'Active'),
(44, 6, 4, '100000000145', 780000.00, '2021-12-09', 'Active'),
(45, 6, 1, '100000000146', 66000.00, '2019-07-25', 'Active'),
(46, 5, 5, '100000000147', 520000.00, '2022-02-16', 'Active'),
(47, 3, 3, '100000000148', 18000.00, '2023-04-27', 'Active'),
(48, 10, 1, '100000000149', 79000.00, '2020-05-12', 'Active'),
(49, 2, 4, '100000000150', 875000.00, '2021-11-26', 'Active'),
(50, 2, 1, '100000000151', 87000.00, '2021-03-14', 'Active'),
(51, 10, 4, '100000000152', 750000.00, '2022-08-19', 'Active'),
(52, 10, 1, '100000000153', 52000.00, '2020-06-23', 'Dormant'),
(53, 10, 3, '100000000154', 28000.00, '2023-02-17', 'Active'),
(54, 12, 5, '100000000155', 580000.00, '2021-10-11', 'Active'),
(55, 12, 1, '100000000156', 76000.00, '2019-09-06', 'Closed'),
(56, 12, 2, '100000000157', 950000.00, '2020-12-15', 'Active'),
(57, 5, 1, '100000000158', 63000.00, '2022-04-22', 'Active'),
(58, 11, 3, '100000000159', 21000.00, '2023-05-03', 'Dormant'),
(59, 3, 4, '100000000160', 680000.00, '2021-07-28', 'Active'),
(60, 3, 1, '100000000161', 82000.00, '2020-01-16', 'Active'),
(61, 2, 5, '100000000162', 450000.00, '2022-11-09', 'Active'),
(62, 2, 1, '100000000163', 56000.00, '2019-06-18', 'Dormant'),
(63, 1, 3, '100000000164', 26000.00, '2023-01-24', 'Active'),
(64, 1, 2, '100000000165', 1250000.00, '2020-08-07', 'Active'),
(65, 4, 1, '100000000166', 47000.00, '2021-05-15', 'Closed'),
(66, 4, 3, '100000000167', 17000.00, '2022-10-20', 'Active'),
(67, 4, 4, '100000000168', 850000.00, '2019-12-12', 'Active'),
(68, 6, 1, '100000000169', 91000.00, '2020-04-28', 'Active'),
(69, 6, 5, '100000000170', 520000.00, '2021-09-17', 'Dormant'),
(70, 7, 1, '100000000171', 69000.00, '2018-11-25', 'Active'),
(71, 7, 3, '100000000172', 30000.00, '2022-02-08', 'Active'),
(72, 8, 4, '100000000173', 700000.00, '2020-10-21', 'Closed'),
(73, 8, 1, '100000000174', 85000.00, '2021-06-16', 'Active'),
(74, 9, 5, '100000000175', 610000.00, '2023-03-07', 'Active'),
(75, 9, 1, '100000000176', 62000.00, '2019-08-29', 'Dormant'),
(76, 11, 2, '100000000177', 900000.00, '2020-02-13', 'Active'),
(77, 11, 1, '100000000178', 73000.00, '2022-07-18', 'Active'),
(78, 5, 3, '100000000179', 23000.00, '2023-04-09', 'Active'),
(79, 5, 4, '100000000180', 950000.00, '2021-12-22', 'Active'),
(80, 3, 1, '100000000181', 67000.00, '2020-03-05', 'Dormant'),
(81, 3, 5, '100000000182', 480000.00, '2022-09-14', 'Active'),
(82, 10, 3, '100000000183', 20000.00, '2023-01-30', 'Closed'),
(83, 12, 1, '100000000184', 94000.00, '2019-10-08', 'Active'),
(84, 12, 4, '100000000185', 780000.00, '2021-04-19', 'Active'),
(85, 6, 1, '100000000186', 51000.00, '2020-07-24', 'Dormant'),
(86, 6, 5, '100000000187', 570000.00, '2022-05-11', 'Active'),
(87, 4, 3, '100000000188', 25000.00, '2023-02-21', 'Active'),
(88, 4, 1, '100000000189', 83000.00, '2018-12-17', 'Active'),
(89, 2, 4, '100000000190', 620000.00, '2021-08-06', 'Closed'),
(90, 1, 1, '100000000191', 74000.00, '2020-11-14', 'Active'),
(91, 1, 3, '100000000192', 29000.00, '2022-03-26', 'Dormant'),
(92, 7, 5, '100000000193', 530000.00, '2021-01-18', 'Active'),
(93, 8, 1, '100000000194', 61000.00, '2019-05-20', 'Active'),
(94, 9, 2, '100000000195', 1150000.00, '2020-09-03', 'Active'),
(95, 10, 1, '100000000196', 78000.00, '2021-07-12', 'Closed'),
(96, 11, 3, '100000000197', 22000.00, '2023-03-16', 'Active'),
(97, 12, 4, '100000000198', 720000.00, '2020-05-29', 'Active'),
(98, 5, 1, '100000000199', 88000.00, '2022-01-08', 'Dormant'),
(99, 6, 5, '100000000200', 490000.00, '2021-11-03', 'Active');

SELECT COUNT(*) FROM accounts;
SELECT * FROM accounts;

INSERT INTO beneficiaries (account_id, beneficiary_name, beneficiary_account_no, bank_name, ifsc_code)
VALUES
(1, 'Rohan Sharma', '220000000001', 'National Trust Bank', 'NTBK0001001'),
(1, 'Anita Sharma', '220000000002', 'United Finance Bank', 'UFBK0001002'),
(2, 'Priya Verma', '220000000003', 'City Commercial Bank', 'CCBK0001003'),
(3, 'Rahul Mehta', '220000000004', 'National Trust Bank', 'NTBK0001004'),
(4, 'Sneha Kapoor', '220000000005', 'United Finance Bank', 'UFBK0001005'),
(5, 'Arjun Nair', '220000000006', 'Metro Cooperative Bank', 'MCBK0001006'),
(6, 'Kiran Patel', '220000000007', 'City Commercial Bank', 'CCBK0001007'),
(7, 'Megha Rao', '220000000008', 'National Trust Bank', 'NTBK0001008'),
(8, 'Vivek Joshi', '220000000009', 'United Finance Bank', 'UFBK0001009'),
(9, 'Aakash Singh', '220000000010', 'Metro Cooperative Bank', 'MCBK0001010'),
(10, 'Neha Malhotra', '220000000011', 'City Commercial Bank', 'CCBK0001011'),
(11, 'Ravi Kumar', '220000000012', 'National Trust Bank', 'NTBK0001012'),
(12, 'Pooja Nair', '220000000013', 'United Finance Bank', 'UFBK0001013'),
(13, 'Siddharth Jain', '220000000014', 'Metro Cooperative Bank', 'MCBK0001014'),
(14, 'Komal Arora', '220000000015', 'City Commercial Bank', 'CCBK0001015'),
(15, 'Manish Gupta', '220000000016', 'National Trust Bank', 'NTBK0001016'),
(16, 'Divya Menon', '220000000017', 'United Finance Bank', 'UFBK0001017'),
(17, 'Rakesh Shah', '220000000018', 'Metro Cooperative Bank', 'MCBK0001018'),
(18, 'Anjali Das', '220000000019', 'City Commercial Bank', 'CCBK0001019'),
(19, 'Varun Mehra', '220000000020', 'National Trust Bank', 'NTBK0001020'),
(20, 'Simran Kaur', '220000000021', 'United Finance Bank', 'UFBK0001021'),
(21, 'Aditya Rao', '220000000022', 'Metro Cooperative Bank', 'MCBK0001022'),
(22, 'Nidhi Sharma', '220000000023', 'City Commercial Bank', 'CCBK0001023'),
(23, 'Tarun Bhatia', '220000000024', 'National Trust Bank', 'NTBK0001024'),
(24, 'Ritika Soni', '220000000025', 'United Finance Bank', 'UFBK0001025'),
(25, 'Aman Verma', '220000000026', 'Metro Cooperative Bank', 'MCBK0001026'),
(26, 'Kavya Iyer', '220000000027', 'City Commercial Bank', 'CCBK0001027'),
(27, 'Nitin Yadav', '220000000028', 'National Trust Bank', 'NTBK0001028'),
(28, 'Shreya Kapoor', '220000000029', 'United Finance Bank', 'UFBK0001029'),
(29, 'Mohit Agarwal', '220000000030', 'Metro Cooperative Bank', 'MCBK0001030'),
(30, 'Isha Malhotra', '220000000031', 'City Commercial Bank', 'CCBK0001031'),
(31, 'Rajiv Sinha', '220000000032', 'National Trust Bank', 'NTBK0001032'),
(32, 'Ananya Roy', '220000000033', 'United Finance Bank', 'UFBK0001033'),
(33, 'Kunal Shah', '220000000034', 'Metro Cooperative Bank', 'MCBK0001034'),
(34, 'Priyanka Joshi', '220000000035', 'City Commercial Bank', 'CCBK0001035'),
(35, 'Harsh Vardhan', '220000000036', 'National Trust Bank', 'NTBK0001036'),
(36, 'Sonal Mehta', '220000000037', 'United Finance Bank', 'UFBK0001037'),
(37, 'Deepak Kumar', '220000000038', 'Metro Cooperative Bank', 'MCBK0001038'),
(38, 'Rhea Nair', '220000000039', 'City Commercial Bank', 'CCBK0001039'),
(39, 'Suresh Patel', '220000000040', 'National Trust Bank', 'NTBK0001040'),
(40, 'Meera Shah', '220000000041', 'United Finance Bank', 'UFBK0001041'),
(41, 'Yash Agarwal', '220000000042', 'Metro Cooperative Bank', 'MCBK0001042'),
(42, 'Rohan Verma', '220000000043', 'City Commercial Bank', 'CCBK0001043'),
(43, 'Aditi Sharma', '220000000044', 'National Trust Bank', 'NTBK0001044'),
(44, 'Sanjay Rao', '220000000045', 'United Finance Bank', 'UFBK0001045'),
(45, 'Pallavi Singh', '220000000046', 'Metro Cooperative Bank', 'MCBK0001046'),
(46, 'Abhishek Jain', '220000000047', 'City Commercial Bank', 'CCBK0001047'),
(47, 'Ritu Sharma', '220000000048', 'National Trust Bank', 'NTBK0001048'),
(48, 'Sameer Khan', '220000000049', 'United Finance Bank', 'UFBK0001049'),
(49, 'Monika Patel', '220000000050', 'Metro Cooperative Bank', 'MCBK0001050'),
(50, 'Vikas Kumar', '220000000051', 'City Commercial Bank', 'CCBK0001051'),
(51, 'Tanvi Arora', '220000000052', 'National Trust Bank', 'NTBK0001052'),
(52, 'Rohit Sharma', '220000000053', 'United Finance Bank', 'UFBK0001053'),
(53, 'Kriti Mehra', '220000000054', 'Metro Cooperative Bank', 'MCBK0001054'),
(54, 'Ajay Verma', '220000000055', 'City Commercial Bank', 'CCBK0001055'),
(55, 'Sneha Rao', '220000000056', 'National Trust Bank', 'NTBK0001056'),
(56, 'Arvind Patel', '220000000057', 'United Finance Bank', 'UFBK0001057'),
(57, 'Pooja Shah', '220000000058', 'Metro Cooperative Bank', 'MCBK0001058'),
(58, 'Karan Joshi', '220000000059', 'City Commercial Bank', 'CCBK0001059'),
(59, 'Nisha Kapoor', '220000000060', 'National Trust Bank', 'NTBK0001060'),
(60, 'Rajat Mehta', '220000000061', 'United Finance Bank', 'UFBK0001061'),
(61, 'Alisha Singh', '220000000062', 'Metro Cooperative Bank', 'MCBK0001062'),
(62, 'Vivek Sharma', '220000000063', 'City Commercial Bank', 'CCBK0001063'),
(63, 'Neelam Gupta', '220000000064', 'National Trust Bank', 'NTBK0001064'),
(64, 'Amit Shah', '220000000065', 'United Finance Bank', 'UFBK0001065'),
(65, 'Kavita Rao', '220000000066', 'Metro Cooperative Bank', 'MCBK0001066'),
(66, 'Rahul Jain', '220000000067', 'City Commercial Bank', 'CCBK0001067'),
(67, 'Shivani Mehta', '220000000068', 'National Trust Bank', 'NTBK0001068'),
(68, 'Naveen Verma', '220000000069', 'United Finance Bank', 'UFBK0001069'),
(69, 'Priya Shah', '220000000070', 'Metro Cooperative Bank', 'MCBK0001070'),
(70, 'Ankit Sharma', '220000000071', 'City Commercial Bank', 'CCBK0001071'),
(71, 'Riya Kapoor', '220000000072', 'National Trust Bank', 'NTBK0001072'),
(72, 'Sahil Mehta', '220000000073', 'United Finance Bank', 'UFBK0001073'),
(73, 'Priti Jain', '220000000074', 'Metro Cooperative Bank', 'MCBK0001074'),
(74, 'Gaurav Singh', '220000000075', 'City Commercial Bank', 'CCBK0001075'),
(75, 'Maya Rao', '220000000076', 'National Trust Bank', 'NTBK0001076'),
(76, 'Harish Patel', '220000000077', 'United Finance Bank', 'UFBK0001077'),
(77, 'Divya Shah', '220000000078', 'Metro Cooperative Bank', 'MCBK0001078'),
(78, 'Aman Gupta', '220000000079', 'City Commercial Bank', 'CCBK0001079'),
(79, 'Reena Joshi', '220000000080', 'National Trust Bank', 'NTBK0001080'),
(80, 'Vijay Kumar', '220000000081', 'United Finance Bank', 'UFBK0001081'),
(81, 'Anjali Verma', '220000000082', 'Metro Cooperative Bank', 'MCBK0001082'),
(82, 'Saurabh Mehta', '220000000083', 'City Commercial Bank', 'CCBK0001083'),
(83, 'Preeti Shah', '220000000084', 'National Trust Bank', 'NTBK0001084'),
(84, 'Manoj Rao', '220000000085', 'United Finance Bank', 'UFBK0001085'),
(85, 'Simran Gupta', '220000000086', 'Metro Cooperative Bank', 'MCBK0001086'),
(86, 'Rakesh Sharma', '220000000087', 'City Commercial Bank', 'CCBK0001087'),
(87, 'Nandini Patel', '220000000088', 'National Trust Bank', 'NTBK0001088'),
(88, 'Kishore Mehta', '220000000089', 'United Finance Bank', 'UFBK0001089'),
(89, 'Pooja Verma', '220000000090', 'Metro Cooperative Bank', 'MCBK0001090'),
(90, 'Raj Malhotra', '220000000091', 'City Commercial Bank', 'CCBK0001091'),
(91, 'Kiran Sharma', '220000000092', 'National Trust Bank', 'NTBK0001092'),
(92, 'Deepa Rao', '220000000093', 'United Finance Bank', 'UFBK0001093'),
(93, 'Yuvraj Singh', '220000000094', 'Metro Cooperative Bank', 'MCBK0001094'),
(94, 'Sakshi Mehta', '220000000095', 'City Commercial Bank', 'CCBK0001095'),
(95, 'Varun Patel', '220000000096', 'National Trust Bank', 'NTBK0001096'),
(96, 'Neha Shah', '220000000097', 'United Finance Bank', 'UFBK0001097'),
(97, 'Akash Kumar', '220000000098', 'Metro Cooperative Bank', 'MCBK0001098'),
(98, 'Riya Verma', '220000000099', 'City Commercial Bank', 'CCBK0001099'),
(99, 'Aditya Mehta', '220000000100', 'National Trust Bank', 'NTBK0001100'),
(100, 'Ananya Sharma', '220000000101', 'United Finance Bank', 'UFBK0001101'),
(101, 'Rohit Kapoor', '220000000102', 'Metro Cooperative Bank', 'MCBK0001102'),
(102, 'Neha Verma', '220000000103', 'City Commercial Bank', 'CCBK0001103'),
(103, 'Aarav Mehta', '220000000104', 'National Trust Bank', 'NTBK0001104'),
(104, 'Simran Patel', '220000000105', 'United Finance Bank', 'UFBK0001105'),
(105, 'Karan Sharma', '220000000106', 'Metro Cooperative Bank', 'MCBK0001106'),
(106, 'Riya Nair', '220000000107', 'City Commercial Bank', 'CCBK0001107'),
(107, 'Mohit Singh', '220000000108', 'National Trust Bank', 'NTBK0001108'),
(108, 'Pallavi Rao', '220000000109', 'United Finance Bank', 'UFBK0001109'),
(109, 'Sanjay Patel', '220000000110', 'Metro Cooperative Bank', 'MCBK0001110'),
(110, 'Ishita Kapoor', '220000000111', 'City Commercial Bank', 'CCBK0001111'),
(111, 'Vishal Sharma', '220000000112', 'National Trust Bank', 'NTBK0001112'),
(112, 'Meera Verma', '220000000113', 'United Finance Bank', 'UFBK0001113'),
(113, 'Rohan Gupta', '220000000114', 'Metro Cooperative Bank', 'MCBK0001114'),
(114, 'Nisha Patel', '220000000115', 'City Commercial Bank', 'CCBK0001115'),
(115, 'Arjun Singh', '220000000116', 'National Trust Bank', 'NTBK0001116'),
(116, 'Kavya Rao', '220000000117', 'United Finance Bank', 'UFBK0001117'),
(117, 'Amit Sharma', '220000000118', 'Metro Cooperative Bank', 'MCBK0001118'),
(118, 'Divya Kapoor', '220000000119', 'City Commercial Bank', 'CCBK0001119'),
(119, 'Rahul Verma', '220000000120', 'National Trust Bank', 'NTBK0001120'),
(120, 'Sneha Patel', '220000000121', 'United Finance Bank', 'UFBK0001121'),
(121, 'Yash Sharma', '220000000122', 'Metro Cooperative Bank', 'MCBK0001122'),
(122, 'Pooja Mehta', '220000000123', 'City Commercial Bank', 'CCBK0001123'),
(123, 'Harsh Singh', '220000000124', 'National Trust Bank', 'NTBK0001124'),
(124, 'Ritu Kapoor', '220000000125', 'United Finance Bank', 'UFBK0001125'),
(125, 'Kunal Verma', '220000000126', 'Metro Cooperative Bank', 'MCBK0001126'),
(126, 'Anjali Sharma', '220000000127', 'City Commercial Bank', 'CCBK0001127'),
(127, 'Siddharth Patel', '220000000128', 'National Trust Bank', 'NTBK0001128'),
(128, 'Mansi Rao', '220000000129', 'United Finance Bank', 'UFBK0001129'),
(129, 'Vivek Gupta', '220000000130', 'Metro Cooperative Bank', 'MCBK0001130'),
(130, 'Shreya Singh', '220000000131', 'City Commercial Bank', 'CCBK0001131'),
(131, 'Manish Kapoor', '220000000132', 'National Trust Bank', 'NTBK0001132'),
(132, 'Tanvi Sharma', '220000000133', 'United Finance Bank', 'UFBK0001133'),
(133, 'Rakesh Verma', '220000000134', 'Metro Cooperative Bank', 'MCBK0001134'),
(134, 'Komal Patel', '220000000135', 'City Commercial Bank', 'CCBK0001135'),
(135, 'Aman Singh', '220000000136', 'National Trust Bank', 'NTBK0001136'),
(136, 'Priya Rao', '220000000137', 'United Finance Bank', 'UFBK0001137'),
(137, 'Nitin Sharma', '220000000138', 'Metro Cooperative Bank', 'MCBK0001138'),
(138, 'Rhea Kapoor', '220000000139', 'City Commercial Bank', 'CCBK0001139'),
(139, 'Ajay Verma', '220000000140', 'National Trust Bank', 'NTBK0001140'),
(140, 'Kriti Patel', '220000000141', 'United Finance Bank', 'UFBK0001141'),
(141, 'Vikas Sharma', '220000000142', 'Metro Cooperative Bank', 'MCBK0001142'),
(142, 'Nandini Mehta', '220000000143', 'City Commercial Bank', 'CCBK0001143'),
(143, 'Tarun Singh', '220000000144', 'National Trust Bank', 'NTBK0001144'),
(144, 'Aditi Kapoor', '220000000145', 'United Finance Bank', 'UFBK0001145'),
(145, 'Saurabh Verma', '220000000146', 'Metro Cooperative Bank', 'MCBK0001146'),
(146, 'Rashmi Sharma', '220000000147', 'City Commercial Bank', 'CCBK0001147'),
(147, 'Keshav Patel', '220000000148', 'National Trust Bank', 'NTBK0001148'),
(148, 'Anusha Rao', '220000000149', 'United Finance Bank', 'UFBK0001149'),
(149, 'Gaurav Singh', '220000000150', 'Metro Cooperative Bank', 'MCBK0001150'),
(150, 'Ira Sharma', '220000000151', 'City Commercial Bank', 'CCBK0001151'),
(151, 'Sameer Kapoor', '220000000152', 'National Trust Bank', 'NTBK0001152'),
(152, 'Bhavna Verma', '220000000153', 'United Finance Bank', 'UFBK0001153'),
(153, 'Lokesh Patel', '220000000154', 'Metro Cooperative Bank', 'MCBK0001154'),
(154, 'Rupal Sharma', '220000000155', 'City Commercial Bank', 'CCBK0001155'),
(155, 'Mayank Singh', '220000000156', 'National Trust Bank', 'NTBK0001156'),
(156, 'Juhi Rao', '220000000157', 'United Finance Bank', 'UFBK0001157'),
(157, 'Chetan Gupta', '220000000158', 'Metro Cooperative Bank', 'MCBK0001158'),
(158, 'Priti Kapoor', '220000000159', 'City Commercial Bank', 'CCBK0001159'),
(159, 'Harshit Sharma', '220000000160', 'National Trust Bank', 'NTBK0001160'),
(160, 'Monika Verma', '220000000161', 'United Finance Bank', 'UFBK0001161'),
(161, 'Yuvraj Patel', '220000000162', 'Metro Cooperative Bank', 'MCBK0001162'),
(162, 'Shivani Rao', '220000000163', 'City Commercial Bank', 'CCBK0001163'),
(163, 'Adarsh Singh', '220000000164', 'National Trust Bank', 'NTBK0001164'),
(164, 'Preeti Kapoor', '220000000165', 'United Finance Bank', 'UFBK0001165'),
(165, 'Om Sharma', '220000000166', 'Metro Cooperative Bank', 'MCBK0001166'),
(166, 'Rashmi Verma', '220000000167', 'City Commercial Bank', 'CCBK0001167'),
(167, 'Parth Patel', '220000000168', 'National Trust Bank', 'NTBK0001168'),
(168, 'Isha Rao', '220000000169', 'United Finance Bank', 'UFBK0001169'),
(169, 'Laksh Singh', '220000000170', 'Metro Cooperative Bank', 'MCBK0001170'),
(170, 'Sakshi Sharma', '220000000171', 'City Commercial Bank', 'CCBK0001171'),
(171, 'Pranav Kapoor', '220000000172', 'National Trust Bank', 'NTBK0001172'),
(172, 'Muskan Verma', '220000000173', 'United Finance Bank', 'UFBK0001173'),
(173, 'Ashwin Patel', '220000000174', 'Metro Cooperative Bank', 'MCBK0001174'),
(174, 'Tanvi Rao', '220000000175', 'City Commercial Bank', 'CCBK0001175'),
(175, 'Ayush Singh', '220000000176', 'National Trust Bank', 'NTBK0001176'),
(176, 'Ritu Sharma', '220000000177', 'United Finance Bank', 'UFBK0001177'),
(177, 'Kartik Verma', '220000000178', 'Metro Cooperative Bank', 'MCBK0001178'),
(178, 'Anushka Patel', '220000000179', 'City Commercial Bank', 'CCBK0001179'),
(179, 'Sameer Rao', '220000000180', 'National Trust Bank', 'NTBK0001180'),
(180, 'Nikita Sharma', '220000000181', 'United Finance Bank', 'UFBK0001181'),
(181, 'Vivek Kapoor', '220000000182', 'Metro Cooperative Bank', 'MCBK0001182'),
(182, 'Riya Verma', '220000000183', 'City Commercial Bank', 'CCBK0001183'),
(183, 'Kartik Patel', '220000000184', 'National Trust Bank', 'NTBK0001184'),
(184, 'Anjali Rao', '220000000185', 'United Finance Bank', 'UFBK0001185'),
(185, 'Rohan Singh', '220000000186', 'Metro Cooperative Bank', 'MCBK0001186'),
(186, 'Megha Sharma', '220000000187', 'City Commercial Bank', 'CCBK0001187'),
(187, 'Arnav Verma', '220000000188', 'National Trust Bank', 'NTBK0001188'),
(188, 'Pallavi Patel', '220000000189', 'United Finance Bank', 'UFBK0001189'),
(189, 'Rahul Rao', '220000000190', 'Metro Cooperative Bank', 'MCBK0001190'),
(190, 'Naina Sharma', '220000000191', 'City Commercial Bank', 'CCBK0001191'),
(191, 'Dhruv Kapoor', '220000000192', 'National Trust Bank', 'NTBK0001192'),
(192, 'Kajal Verma', '220000000193', 'United Finance Bank', 'UFBK0001193'),
(193, 'Aarav Patel', '220000000194', 'Metro Cooperative Bank', 'MCBK0001194'),
(194, 'Sonia Rao', '220000000195', 'City Commercial Bank', 'CCBK0001195'),
(195, 'Nikhil Singh', '220000000196', 'National Trust Bank', 'NTBK0001196'),
(196, 'Deepa Sharma', '220000000197', 'United Finance Bank', 'UFBK0001197'),
(197, 'Kunal Verma', '220000000198', 'Metro Cooperative Bank', 'MCBK0001198'),
(198, 'Rhea Patel', '220000000199', 'City Commercial Bank', 'CCBK0001199'),
(199, 'Aditya Rao', '220000000200', 'National Trust Bank', 'NTBK0001200'),
(200, 'Aarav Sharma', '220000000201', 'United Finance Bank', 'UFBK0001201'),
(1, 'Rohan Mehta', '220000000202', 'Metro Cooperative Bank', 'MCBK0001202'),
(2, 'Ishita Verma', '220000000203', 'City Commercial Bank', 'CCBK0001203'),
(3, 'Vikram Patel', '220000000204', 'National Trust Bank', 'NTBK0001204'),
(4, 'Ananya Rao', '220000000205', 'United Finance Bank', 'UFBK0001205'),
(5, 'Kunal Sharma', '220000000206', 'Metro Cooperative Bank', 'MCBK0001206'),
(6, 'Riya Kapoor', '220000000207', 'City Commercial Bank', 'CCBK0001207'),
(7, 'Arjun Verma', '220000000208', 'National Trust Bank', 'NTBK0001208'),
(8, 'Neha Patel', '220000000209', 'United Finance Bank', 'UFBK0001209'),
(9, 'Sahil Rao', '220000000210', 'Metro Cooperative Bank', 'MCBK0001210'),
(10, 'Pooja Sharma', '220000000211', 'City Commercial Bank', 'CCBK0001211'),
(11, 'Yash Mehta', '220000000212', 'National Trust Bank', 'NTBK0001212'),
(12, 'Kavya Verma', '220000000213', 'United Finance Bank', 'UFBK0001213'),
(13, 'Rakesh Patel', '220000000214', 'Metro Cooperative Bank', 'MCBK0001214'),
(14, 'Simran Rao', '220000000215', 'City Commercial Bank', 'CCBK0001215'),
(15, 'Amit Kapoor', '220000000216', 'National Trust Bank', 'NTBK0001216'),
(16, 'Divya Sharma', '220000000217', 'United Finance Bank', 'UFBK0001217'),
(17, 'Manav Verma', '220000000218', 'Metro Cooperative Bank', 'MCBK0001218'),
(18, 'Sneha Patel', '220000000219', 'City Commercial Bank', 'CCBK0001219'),
(19, 'Tarun Rao', '220000000220', 'National Trust Bank', 'NTBK0001220'),
(20, 'Meera Sharma', '220000000221', 'United Finance Bank', 'UFBK0001221'),
(21, 'Rahul Kapoor', '220000000222', 'Metro Cooperative Bank', 'MCBK0001222'),
(22, 'Nidhi Verma', '220000000223', 'City Commercial Bank', 'CCBK0001223'),
(23, 'Vishal Patel', '220000000224', 'National Trust Bank', 'NTBK0001224'),
(24, 'Aditi Rao', '220000000225', 'United Finance Bank', 'UFBK0001225'),
(25, 'Sanjay Sharma', '220000000226', 'Metro Cooperative Bank', 'MCBK0001226'),
(26, 'Priya Kapoor', '220000000227', 'City Commercial Bank', 'CCBK0001227'),
(27, 'Harish Verma', '220000000228', 'National Trust Bank', 'NTBK0001228'),
(28, 'Ritu Patel', '220000000229', 'United Finance Bank', 'UFBK0001229'),
(29, 'Akash Rao', '220000000230', 'Metro Cooperative Bank', 'MCBK0001230'),
(30, 'Komal Sharma', '220000000231', 'City Commercial Bank', 'CCBK0001231'),
(31, 'Suresh Mehta', '220000000232', 'National Trust Bank', 'NTBK0001232'),
(32, 'Pallavi Verma', '220000000233', 'United Finance Bank', 'UFBK0001233'),
(33, 'Ravi Patel', '220000000234', 'Metro Cooperative Bank', 'MCBK0001234'),
(34, 'Shreya Rao', '220000000235', 'City Commercial Bank', 'CCBK0001235'),
(35, 'Nitin Sharma', '220000000236', 'National Trust Bank', 'NTBK0001236'),
(36, 'Rashmi Kapoor', '220000000237', 'United Finance Bank', 'UFBK0001237'),
(37, 'Gaurav Verma', '220000000238', 'Metro Cooperative Bank', 'MCBK0001238'),
(38, 'Anjali Patel', '220000000239', 'City Commercial Bank', 'CCBK0001239'),
(39, 'Deepak Rao', '220000000240', 'National Trust Bank', 'NTBK0001240'),
(40, 'Ira Sharma', '220000000241', 'United Finance Bank', 'UFBK0001241'),
(41, 'Mohit Kapoor', '220000000242', 'Metro Cooperative Bank', 'MCBK0001242'),
(42, 'Bhavna Verma', '220000000243', 'City Commercial Bank', 'CCBK0001243'),
(43, 'Karan Patel', '220000000244', 'National Trust Bank', 'NTBK0001244'),
(44, 'Nisha Rao', '220000000245', 'United Finance Bank', 'UFBK0001245'),
(45, 'Vikas Sharma', '220000000246', 'Metro Cooperative Bank', 'MCBK0001246'),
(46, 'Maya Kapoor', '220000000247', 'City Commercial Bank', 'CCBK0001247'),
(47, 'Aman Verma', '220000000248', 'National Trust Bank', 'NTBK0001248'),
(48, 'Kriti Patel', '220000000249', 'United Finance Bank', 'UFBK0001249'),
(49, 'Rohan Rao', '220000000250', 'Metro Cooperative Bank', 'MCBK0001250'),
(50, 'Tanvi Sharma', '220000000251', 'City Commercial Bank', 'CCBK0001251'),
(51, 'Aditya Kapoor', '220000000252', 'National Trust Bank', 'NTBK0001252'),
(52, 'Sakshi Verma', '220000000253', 'United Finance Bank', 'UFBK0001253'),
(53, 'Raj Patel', '220000000254', 'Metro Cooperative Bank', 'MCBK0001254'),
(54, 'Preeti Rao', '220000000255', 'City Commercial Bank', 'CCBK0001255'),
(55, 'Kishore Sharma', '220000000256', 'National Trust Bank', 'NTBK0001256'),
(56, 'Riya Kapoor', '220000000257', 'United Finance Bank', 'UFBK0001257'),
(57, 'Siddhant Verma', '220000000258', 'Metro Cooperative Bank', 'MCBK0001258'),
(58, 'Neelam Patel', '220000000259', 'City Commercial Bank', 'CCBK0001259'),
(59, 'Varun Rao', '220000000260', 'National Trust Bank', 'NTBK0001260'),
(60, 'Anushka Sharma', '220000000261', 'United Finance Bank', 'UFBK0001261'),
(61, 'Harsh Kapoor', '220000000262', 'Metro Cooperative Bank', 'MCBK0001262'),
(62, 'Monika Verma', '220000000263', 'City Commercial Bank', 'CCBK0001263'),
(63, 'Yuvraj Patel', '220000000264', 'National Trust Bank', 'NTBK0001264'),
(64, 'Priti Rao', '220000000265', 'United Finance Bank', 'UFBK0001265'),
(65, 'Sameer Sharma', '220000000266', 'Metro Cooperative Bank', 'MCBK0001266'),
(66, 'Alisha Kapoor', '220000000267', 'City Commercial Bank', 'CCBK0001267'),
(67, 'Chetan Verma', '220000000268', 'National Trust Bank', 'NTBK0001268'),
(68, 'Sonia Patel', '220000000269', 'United Finance Bank', 'UFBK0001269'),
(69, 'Naveen Rao', '220000000270', 'Metro Cooperative Bank', 'MCBK0001270'),
(70, 'Kajal Sharma', '220000000271', 'City Commercial Bank', 'CCBK0001271'),
(71, 'Dhruv Kapoor', '220000000272', 'National Trust Bank', 'NTBK0001272'),
(72, 'Muskan Verma', '220000000273', 'United Finance Bank', 'UFBK0001273'),
(73, 'Ashish Patel', '220000000274', 'Metro Cooperative Bank', 'MCBK0001274'),
(74, 'Nandini Rao', '220000000275', 'City Commercial Bank', 'CCBK0001275'),
(75, 'Ayush Sharma', '220000000276', 'National Trust Bank', 'NTBK0001276'),
(76, 'Rashmi Kapoor', '220000000277', 'United Finance Bank', 'UFBK0001277'),
(77, 'Kartik Verma', '220000000278', 'Metro Cooperative Bank', 'MCBK0001278'),
(78, 'Anusha Patel', '220000000279', 'City Commercial Bank', 'CCBK0001279'),
(79, 'Sameer Rao', '220000000280', 'National Trust Bank', 'NTBK0001280'),
(80, 'Nikita Sharma', '220000000281', 'United Finance Bank', 'UFBK0001281'),
(81, 'Vivek Kapoor', '220000000282', 'Metro Cooperative Bank', 'MCBK0001282'),
(82, 'Riya Verma', '220000000283', 'City Commercial Bank', 'CCBK0001283'),
(83, 'Kartik Patel', '220000000284', 'National Trust Bank', 'NTBK0001284'),
(84, 'Anjali Rao', '220000000285', 'United Finance Bank', 'UFBK0001285'),
(85, 'Rohan Singh', '220000000286', 'Metro Cooperative Bank', 'MCBK0001286'),
(86, 'Megha Sharma', '220000000287', 'City Commercial Bank', 'CCBK0001287'),
(87, 'Arnav Verma', '220000000288', 'National Trust Bank', 'NTBK0001288'),
(88, 'Pallavi Patel', '220000000289', 'United Finance Bank', 'UFBK0001289'),
(89, 'Rahul Rao', '220000000290', 'Metro Cooperative Bank', 'MCBK0001290'),
(90, 'Naina Sharma', '220000000291', 'City Commercial Bank', 'CCBK0001291'),
(91, 'Dhruv Kapoor', '220000000292', 'National Trust Bank', 'NTBK0001292'),
(92, 'Kajal Verma', '220000000293', 'United Finance Bank', 'UFBK0001293'),
(93, 'Aarav Patel', '220000000294', 'Metro Cooperative Bank', 'MCBK0001294'),
(94, 'Sonia Rao', '220000000295', 'City Commercial Bank', 'CCBK0001295'),
(95, 'Nikhil Singh', '220000000296', 'National Trust Bank', 'NTBK0001296'),
(96, 'Deepa Sharma', '220000000297', 'United Finance Bank', 'UFBK0001297'),
(97, 'Kunal Verma', '220000000298', 'Metro Cooperative Bank', 'MCBK0001298'),
(98, 'Rhea Patel', '220000000299', 'City Commercial Bank', 'CCBK0001299'),
(99, 'Aditya Rao', '220000000300', 'National Trust Bank', 'NTBK0001300');

SELECT COUNT(*) FROM beneficiaries; 
SELECT * FROM beneficiaries;

INSERT INTO transactions (account_id, beneficiary_id, transaction_type, amount, transaction_date, transaction_status)
VALUES
(1, NULL, 'Deposit', 45000.00, '2023-01-05 09:15:00', 'Success'),
(2, NULL, 'Withdrawal', 5000.00, '2023-01-06 14:20:00', 'Success'),
(3, 3, 'Transfer', 12000.00, '2023-01-08 11:30:00', 'Success'),
(4, NULL, 'Deposit', 75000.00, '2023-01-10 10:00:00', 'Success'),
(5, NULL, 'Withdrawal', 8000.00, '2023-01-12 16:45:00', 'Success'),
(6, 6, 'Transfer', 15000.00, '2023-01-15 13:10:00', 'Pending'),
(7, NULL, 'Deposit', 32000.00, '2023-01-18 09:25:00', 'Success'),
(8, NULL, 'Withdrawal', 3500.00, '2023-01-20 17:15:00', 'Success'),
(9, 9, 'Transfer', 22000.00, '2023-01-22 12:40:00', 'Success'),
(10, NULL, 'Deposit', 60000.00, '2023-01-25 08:50:00', 'Success'),
(11, NULL, 'Withdrawal', 7000.00, '2023-02-01 15:20:00', 'Success'),
(12, 12, 'Transfer', 18000.00, '2023-02-03 11:15:00', 'Success'),
(13, NULL, 'Deposit', 52000.00, '2023-02-06 10:35:00', 'Success'),
(14, NULL, 'Withdrawal', 4500.00, '2023-02-09 18:10:00', 'Failed'),
(15, 15, 'Transfer', 30000.00, '2023-02-11 14:00:00', 'Success'),
(16, NULL, 'Deposit', 85000.00, '2023-02-14 09:45:00', 'Success'),
(17, NULL, 'Withdrawal', 9000.00, '2023-02-17 16:25:00', 'Success'),
(18, 18, 'Transfer', 25000.00, '2023-02-20 13:50:00', 'Success'),
(19, NULL, 'Deposit', 40000.00, '2023-02-23 10:20:00', 'Success'),
(20, NULL, 'Withdrawal', 6500.00, '2023-02-25 19:00:00', 'Pending'),
(21, NULL, 'Deposit', 55000.00, '2023-03-02 09:30:00', 'Success'),
(22, 22, 'Transfer', 14000.00, '2023-03-04 12:15:00', 'Success'),
(23, NULL, 'Withdrawal', 3000.00, '2023-03-06 15:45:00', 'Success'),
(24, NULL, 'Deposit', 90000.00, '2023-03-09 08:40:00', 'Success'),
(25, 25, 'Transfer', 35000.00, '2023-03-12 17:20:00', 'Success'),
(26, NULL, 'Withdrawal', 12000.00, '2023-03-15 14:30:00', 'Success'),
(27, NULL, 'Deposit', 48000.00, '2023-03-18 11:00:00', 'Success'),
(28, 28, 'Transfer', 16000.00, '2023-03-21 13:25:00', 'Failed'),
(29, NULL, 'Withdrawal', 5500.00, '2023-03-24 18:30:00', 'Success'),
(30, NULL, 'Deposit', 67000.00, '2023-03-28 09:10:00', 'Success'),
(31, 31, 'Transfer', 20000.00, '2023-04-02 12:45:00', 'Success'),
(32, NULL, 'Withdrawal', 4000.00, '2023-04-05 16:10:00', 'Success'),
(33, NULL, 'Deposit', 73000.00, '2023-04-08 10:25:00', 'Success'),
(34, 34, 'Transfer', 28000.00, '2023-04-11 14:40:00', 'Success'),
(35, NULL, 'Withdrawal', 9500.00, '2023-04-14 17:55:00', 'Success'),
(36, NULL, 'Deposit', 56000.00, '2023-04-17 08:30:00', 'Success'),
(37, 37, 'Transfer', 11000.00, '2023-04-20 13:15:00', 'Pending'),
(38, NULL, 'Withdrawal', 6000.00, '2023-04-23 19:10:00', 'Success'),
(39, NULL, 'Deposit', 82000.00, '2023-04-26 09:55:00', 'Success'),
(40, 40, 'Transfer', 19000.00, '2023-04-29 15:35:00', 'Success'),
(41, NULL, 'Deposit', 62000.00, '2023-05-02 09:20:00', 'Success'),
(42, NULL, 'Withdrawal', 7500.00, '2023-05-05 14:35:00', 'Success'),
(43, 43, 'Transfer', 17000.00, '2023-05-08 11:45:00', 'Success'),
(44, NULL, 'Deposit', 95000.00, '2023-05-11 10:15:00', 'Success'),
(45, NULL, 'Withdrawal', 6500.00, '2023-05-14 18:20:00', 'Success'),
(46, 46, 'Transfer', 24000.00, '2023-05-17 13:05:00', 'Success'),
(47, NULL, 'Deposit', 43000.00, '2023-05-20 08:55:00', 'Success'),
(48, NULL, 'Withdrawal', 5000.00, '2023-05-23 16:40:00', 'Failed'),
(49, 49, 'Transfer', 32000.00, '2023-05-26 12:10:00', 'Success'),
(50, NULL, 'Deposit', 78000.00, '2023-05-29 09:35:00', 'Success'),
(51, NULL, 'Withdrawal', 8500.00, '2023-06-02 15:25:00', 'Success'),
(52, 52, 'Transfer', 21000.00, '2023-06-05 11:50:00', 'Success'),
(53, NULL, 'Deposit', 68000.00, '2023-06-08 10:30:00', 'Success'),
(54, NULL, 'Withdrawal', 4500.00, '2023-06-11 17:45:00', 'Pending'),
(55, 55, 'Transfer', 27000.00, '2023-06-14 14:15:00', 'Success'),
(56, NULL, 'Deposit', 89000.00, '2023-06-17 09:05:00', 'Success'),
(57, NULL, 'Withdrawal', 7000.00, '2023-06-20 18:35:00', 'Success'),
(58, 58, 'Transfer', 13000.00, '2023-06-23 12:25:00', 'Success'),
(59, NULL, 'Deposit', 51000.00, '2023-06-26 08:45:00', 'Success'),
(60, NULL, 'Withdrawal', 10000.00, '2023-06-29 16:55:00', 'Success'),
(61, 61, 'Transfer', 16000.00, '2023-07-03 13:20:00', 'Success'),
(62, NULL, 'Deposit', 72000.00, '2023-07-06 09:40:00', 'Success'),
(63, NULL, 'Withdrawal', 6000.00, '2023-07-09 15:15:00', 'Success'),
(64, 64, 'Transfer', 29000.00, '2023-07-12 11:35:00', 'Success'),
(65, NULL, 'Deposit', 84000.00, '2023-07-15 10:10:00', 'Success'),
(66, NULL, 'Withdrawal', 5500.00, '2023-07-18 17:30:00', 'Failed'),
(67, 67, 'Transfer', 22000.00, '2023-07-21 14:25:00', 'Success'),
(68, NULL, 'Deposit', 47000.00, '2023-07-24 08:50:00', 'Success'),
(69, NULL, 'Withdrawal', 9000.00, '2023-07-27 19:05:00', 'Success'),
(70, 70, 'Transfer', 35000.00, '2023-07-30 12:55:00', 'Success'),
(71, NULL, 'Deposit', 60000.00, '2023-08-03 09:25:00', 'Success'),
(72, NULL, 'Withdrawal', 4000.00, '2023-08-06 16:15:00', 'Success'),
(73, 73, 'Transfer', 26000.00, '2023-08-09 13:45:00', 'Pending'),
(74, NULL, 'Deposit', 91000.00, '2023-08-12 10:05:00', 'Success'),
(75, NULL, 'Withdrawal', 12000.00, '2023-08-15 18:40:00', 'Success'),
(76, 76, 'Transfer', 18000.00, '2023-08-18 11:20:00', 'Success'),
(77, NULL, 'Deposit', 53000.00, '2023-08-21 09:00:00', 'Success'),
(78, NULL, 'Withdrawal', 6500.00, '2023-08-24 15:50:00', 'Success'),
(79, 79, 'Transfer', 31000.00, '2023-08-27 14:10:00', 'Success'),
(80, NULL, 'Deposit', 76000.00, '2023-08-30 08:35:00', 'Success'),
(81, NULL, 'Withdrawal', 8000.00, '2023-09-03 17:25:00', 'Success'),
(82, 82, 'Transfer', 23000.00, '2023-09-06 12:40:00', 'Success'),
(83, NULL, 'Deposit', 66000.00, '2023-09-09 10:20:00', 'Success'),
(84, NULL, 'Withdrawal', 3500.00, '2023-09-12 16:35:00', 'Success'),
(85, 85, 'Transfer', 15000.00, '2023-09-15 13:30:00', 'Failed'),
(86, NULL, 'Deposit', 98000.00, '2023-09-18 09:15:00', 'Success'),
(87, NULL, 'Withdrawal', 7000.00, '2023-09-21 18:25:00', 'Success'),
(88, 88, 'Transfer', 34000.00, '2023-09-24 11:55:00', 'Success'),
(89, NULL, 'Deposit', 58000.00, '2023-09-27 08:40:00', 'Success'),
(90, NULL, 'Withdrawal', 9500.00, '2023-09-30 15:05:00', 'Pending'),
(91, 91, 'Transfer', 20000.00, '2023-10-04 12:20:00', 'Success'),
(92, NULL, 'Deposit', 74000.00, '2023-10-07 09:45:00', 'Success'),
(93, NULL, 'Withdrawal', 5000.00, '2023-10-10 17:15:00', 'Success'),
(94, 94, 'Transfer', 28000.00, '2023-10-13 13:35:00', 'Success'),
(95, NULL, 'Deposit', 86000.00, '2023-10-16 10:30:00', 'Success'),
(96, NULL, 'Withdrawal', 6000.00, '2023-10-19 16:50:00', 'Success'),
(97, 97, 'Transfer', 19000.00, '2023-10-22 14:05:00', 'Success'),
(98, NULL, 'Deposit', 55000.00, '2023-10-25 08:25:00', 'Success'),
(99, NULL, 'Withdrawal', 7500.00, '2023-10-28 18:00:00', 'Failed'),
(100, 100, 'Transfer', 36000.00, '2023-10-31 11:40:00', 'Success'),
(101, NULL, 'Deposit', 67000.00, '2023-11-03 09:10:00', 'Success'),
(102, NULL, 'Withdrawal', 8500.00, '2023-11-06 15:30:00', 'Success'),
(103, 103, 'Transfer', 21000.00, '2023-11-09 12:25:00', 'Success'),
(104, NULL, 'Deposit', 92000.00, '2023-11-12 10:45:00', 'Success'),
(105, NULL, 'Withdrawal', 6000.00, '2023-11-15 17:20:00', 'Success'),
(106, 106, 'Transfer', 17500.00, '2023-11-18 13:15:00', 'Pending'),
(107, NULL, 'Deposit', 48000.00, '2023-11-21 08:50:00', 'Success'),
(108, NULL, 'Withdrawal', 4500.00, '2023-11-24 16:10:00', 'Success'),
(109, 109, 'Transfer', 26000.00, '2023-11-27 11:35:00', 'Success'),
(110, NULL, 'Deposit', 78000.00, '2023-11-30 09:00:00', 'Success'),
(111, NULL, 'Withdrawal', 7000.00, '2023-12-03 14:45:00', 'Success'),
(112, 112, 'Transfer', 22000.00, '2023-12-06 12:10:00', 'Success'),
(113, NULL, 'Deposit', 59000.00, '2023-12-09 10:25:00', 'Success'),
(114, NULL, 'Withdrawal', 3500.00, '2023-12-12 18:05:00', 'Failed'),
(115, 115, 'Transfer', 31000.00, '2023-12-15 13:40:00', 'Success'),
(116, NULL, 'Deposit', 88000.00, '2023-12-18 09:35:00', 'Success'),
(117, NULL, 'Withdrawal', 9500.00, '2023-12-21 16:25:00', 'Success'),
(118, 118, 'Transfer', 14000.00, '2023-12-24 11:50:00', 'Success'),
(119, NULL, 'Deposit', 62000.00, '2023-12-27 08:45:00', 'Success'),
(120, NULL, 'Withdrawal', 5000.00, '2023-12-30 17:10:00', 'Pending'),
(121, 121, 'Transfer', 19000.00, '2024-01-03 12:35:00', 'Success'),
(122, NULL, 'Deposit', 73000.00, '2024-01-06 09:20:00', 'Success'),
(123, NULL, 'Withdrawal', 6500.00, '2024-01-09 15:45:00', 'Success'),
(124, 124, 'Transfer', 27000.00, '2024-01-12 13:25:00', 'Success'),
(125, NULL, 'Deposit', 96000.00, '2024-01-15 10:10:00', 'Success'),
(126, NULL, 'Withdrawal', 8000.00, '2024-01-18 18:30:00', 'Success'),
(127, 127, 'Transfer', 16000.00, '2024-01-21 11:15:00', 'Failed'),
(128, NULL, 'Deposit', 54000.00, '2024-01-24 08:40:00', 'Success'),
(129, NULL, 'Withdrawal', 4000.00, '2024-01-27 16:55:00', 'Success'),
(130, 130, 'Transfer', 33000.00, '2024-01-30 14:20:00', 'Success'),
(131, NULL, 'Deposit', 69000.00, '2024-02-03 09:05:00', 'Success'),
(132, NULL, 'Withdrawal', 5500.00, '2024-02-06 17:25:00', 'Success'),
(133, 133, 'Transfer', 24000.00, '2024-02-09 12:40:00', 'Success'),
(134, NULL, 'Deposit', 83000.00, '2024-02-12 10:30:00', 'Success'),
(135, NULL, 'Withdrawal', 9000.00, '2024-02-15 15:50:00', 'Success'),
(136, 136, 'Transfer', 29000.00, '2024-02-18 13:05:00', 'Success'),
(137, NULL, 'Deposit', 47000.00, '2024-02-21 08:55:00', 'Success'),
(138, NULL, 'Withdrawal', 7500.00, '2024-02-24 18:15:00', 'Pending'),
(139, 139, 'Transfer', 12000.00, '2024-02-27 11:45:00', 'Success'),
(140, NULL, 'Deposit', 91000.00, '2024-03-01 09:30:00', 'Success'),
(141, NULL, 'Withdrawal', 6500.00, '2024-03-04 16:20:00', 'Success'),
(142, 142, 'Transfer', 18000.00, '2024-03-07 12:55:00', 'Success'),
(143, NULL, 'Deposit', 76000.00, '2024-03-10 10:15:00', 'Success'),
(144, NULL, 'Withdrawal', 3500.00, '2024-03-13 17:40:00', 'Success'),
(145, 145, 'Transfer', 37000.00, '2024-03-16 14:10:00', 'Success'),
(146, NULL, 'Deposit', 64000.00, '2024-03-19 09:25:00', 'Success'),
(147, NULL, 'Withdrawal', 6000.00, '2024-03-22 15:35:00', 'Failed'),
(148, 148, 'Transfer', 23000.00, '2024-03-25 13:50:00', 'Success'),
(149, NULL, 'Deposit', 52000.00, '2024-03-28 08:35:00', 'Success'),
(150, NULL, 'Withdrawal', 8500.00, '2024-03-31 18:05:00', 'Success'),
(151, 151, 'Transfer', 20000.00, '2024-04-04 11:20:00', 'Success'),
(152, NULL, 'Deposit', 87000.00, '2024-04-07 09:15:00', 'Success'),
(153, NULL, 'Withdrawal', 5000.00, '2024-04-10 16:45:00', 'Success'),
(154, 154, 'Transfer', 28000.00, '2024-04-13 12:30:00', 'Success'),
(155, NULL, 'Deposit', 99000.00, '2024-04-16 10:05:00', 'Success'),
(156, NULL, 'Withdrawal', 7000.00, '2024-04-19 17:35:00', 'Pending'),
(157, 157, 'Transfer', 15000.00, '2024-04-22 13:20:00', 'Success'),
(158, NULL, 'Deposit', 58000.00, '2024-04-25 08:50:00', 'Success'),
(159, NULL, 'Withdrawal', 4500.00, '2024-04-28 15:55:00', 'Success'),
(160, 160, 'Transfer', 32000.00, '2024-05-01 11:40:00', 'Success'),
(161, NULL, 'Deposit', 71000.00, '2024-05-04 09:25:00', 'Success'),
(162, NULL, 'Withdrawal', 9000.00, '2024-05-07 18:10:00', 'Success'),
(163, 163, 'Transfer', 26000.00, '2024-05-10 12:15:00', 'Success'),
(164, NULL, 'Deposit', 93000.00, '2024-05-13 10:45:00', 'Success'),
(165, NULL, 'Withdrawal', 5500.00, '2024-05-16 16:30:00', 'Success'),
(166, 166, 'Transfer', 21000.00, '2024-05-19 14:00:00', 'Failed'),
(167, NULL, 'Deposit', 68000.00, '2024-05-22 08:40:00', 'Success'),
(168, NULL, 'Withdrawal', 7500.00, '2024-05-25 17:15:00', 'Success'),
(169, 169, 'Transfer', 30000.00, '2024-05-28 13:35:00', 'Success'),
(170, NULL, 'Deposit', 81000.00, '2024-05-31 09:50:00', 'Success'),
(171, NULL, 'Withdrawal', 6000.00, '2024-06-03 15:25:00', 'Success'),
(172, 172, 'Transfer', 18000.00, '2024-06-06 12:40:00', 'Success'),
(173, NULL, 'Deposit', 75000.00, '2024-06-09 09:15:00', 'Success'),
(174, NULL, 'Withdrawal', 4000.00, '2024-06-12 17:35:00', 'Success'),
(175, 175, 'Transfer', 27000.00, '2024-06-15 13:20:00', 'Success'),
(176, NULL, 'Deposit', 88000.00, '2024-06-18 10:05:00', 'Success'),
(177, NULL, 'Withdrawal', 8500.00, '2024-06-21 16:45:00', 'Pending'),
(178, 178, 'Transfer', 22000.00, '2024-06-24 11:30:00', 'Success'),
(179, NULL, 'Deposit', 56000.00, '2024-06-27 08:55:00', 'Success'),
(180, NULL, 'Withdrawal', 7000.00, '2024-06-30 18:20:00', 'Success'),
(181, 181, 'Transfer', 35000.00, '2024-07-04 12:10:00', 'Success'),
(182, NULL, 'Deposit', 63000.00, '2024-07-07 09:40:00', 'Success'),
(183, NULL, 'Withdrawal', 5000.00, '2024-07-10 15:55:00', 'Success'),
(184, 184, 'Transfer', 16000.00, '2024-07-13 13:25:00', 'Success'),
(185, NULL, 'Deposit', 97000.00, '2024-07-16 10:20:00', 'Success'),
(186, NULL, 'Withdrawal', 6500.00, '2024-07-19 17:10:00', 'Failed'),
(187, 187, 'Transfer', 24000.00, '2024-07-22 11:45:00', 'Success'),
(188, NULL, 'Deposit', 59000.00, '2024-07-25 08:30:00', 'Success'),
(189, NULL, 'Withdrawal', 3000.00, '2024-07-28 16:40:00', 'Success'),
(190, 190, 'Transfer', 29000.00, '2024-07-31 14:15:00', 'Success'),
(191, NULL, 'Deposit', 82000.00, '2024-08-04 09:05:00', 'Success'),
(192, NULL, 'Withdrawal', 9000.00, '2024-08-07 18:25:00', 'Success'),
(193, 193, 'Transfer', 20000.00, '2024-08-10 12:35:00', 'Pending'),
(194, NULL, 'Deposit', 67000.00, '2024-08-13 10:10:00', 'Success'),
(195, NULL, 'Withdrawal', 4500.00, '2024-08-16 15:45:00', 'Success'),
(196, 196, 'Transfer', 31000.00, '2024-08-19 13:05:00', 'Success'),
(197, NULL, 'Deposit', 54000.00, '2024-08-22 08:50:00', 'Success'),
(198, NULL, 'Withdrawal', 7500.00, '2024-08-25 17:55:00', 'Success'),
(199, 199, 'Transfer', 14000.00, '2024-08-28 11:20:00', 'Success'),
(200, NULL, 'Deposit', 90000.00, '2024-08-31 09:35:00', 'Success'),
(1, NULL, 'Withdrawal', 6000.00, '2024-09-04 16:15:00', 'Success'),
(2, 2, 'Transfer', 25000.00, '2024-09-07 12:25:00', 'Success'),
(3, NULL, 'Deposit', 72000.00, '2024-09-10 10:00:00', 'Success'),
(4, NULL, 'Withdrawal', 8000.00, '2024-09-13 18:10:00', 'Success'),
(5, 5, 'Transfer', 19000.00, '2024-09-16 14:30:00', 'Success'),
(6, NULL, 'Deposit', 85000.00, '2024-09-19 09:20:00', 'Success'),
(7, NULL, 'Withdrawal', 3500.00, '2024-09-22 15:40:00', 'Failed'),
(8, 8, 'Transfer', 28000.00, '2024-09-25 11:55:00', 'Success'),
(9, NULL, 'Deposit', 61000.00, '2024-09-28 08:45:00', 'Success'),
(10, NULL, 'Withdrawal', 9500.00, '2024-10-01 17:30:00', 'Success'),
(11, 11, 'Transfer', 23000.00, '2024-10-05 13:15:00', 'Success'),
(12, NULL, 'Deposit', 79000.00, '2024-10-08 09:25:00', 'Success'),
(13, NULL, 'Withdrawal', 5000.00, '2024-10-11 16:50:00', 'Success'),
(14, 14, 'Transfer', 17000.00, '2024-10-14 12:20:00', 'Success'),
(15, NULL, 'Deposit', 94000.00, '2024-10-17 10:35:00', 'Success'),
(16, NULL, 'Withdrawal', 6500.00, '2024-10-20 18:05:00', 'Pending'),
(17, 17, 'Transfer', 33000.00, '2024-10-23 14:10:00', 'Success'),
(18, NULL, 'Deposit', 57000.00, '2024-10-26 08:35:00', 'Success'),
(19, NULL, 'Withdrawal', 4000.00, '2024-10-29 15:25:00', 'Success'),
(20, 20, 'Transfer', 26000.00, '2024-11-01 11:50:00', 'Success'),
(21, NULL, 'Deposit', 76000.00, '2024-11-05 09:15:00', 'Success'),
(22, NULL, 'Withdrawal', 8500.00, '2024-11-08 17:20:00', 'Success'),
(23, 23, 'Transfer', 15000.00, '2024-11-11 13:40:00', 'Success'),
(24, NULL, 'Deposit', 89000.00, '2024-11-14 10:25:00', 'Success'),
(25, NULL, 'Withdrawal', 7000.00, '2024-11-17 16:35:00', 'Success'),
(26, 26, 'Transfer', 30000.00, '2024-11-20 12:05:00', 'Success'),
(27, NULL, 'Deposit', 65000.00, '2024-11-23 08:55:00', 'Success'),
(28, NULL, 'Withdrawal', 5500.00, '2024-11-26 18:15:00', 'Failed'),
(29, 29, 'Transfer', 21000.00, '2024-11-29 14:45:00', 'Success'),
(30, NULL, 'Deposit', 93000.00, '2024-12-02 09:30:00', 'Success'),
(31, NULL, 'Withdrawal', 6000.00, '2024-12-06 15:10:00', 'Success'),
(32, 32, 'Transfer', 18000.00, '2024-12-09 12:35:00', 'Success'),
(33, NULL, 'Deposit', 70000.00, '2024-12-12 10:15:00', 'Success'),
(34, NULL, 'Withdrawal', 4500.00, '2024-12-15 17:45:00', 'Success'),
(35, 35, 'Transfer', 27000.00, '2024-12-18 13:25:00', 'Success'),
(36, NULL, 'Deposit', 86000.00, '2024-12-21 09:05:00', 'Success'),
(37, NULL, 'Withdrawal', 7500.00, '2024-12-24 16:20:00', 'Pending'),
(38, 38, 'Transfer', 32000.00, '2024-12-27 11:40:00', 'Success'),
(39, NULL, 'Deposit', 53000.00, '2024-12-30 08:50:00', 'Success'),
(40, NULL, 'Withdrawal', 9000.00, '2025-01-03 18:00:00', 'Success'),
(41, NULL, 'Deposit', 68000.00, '2025-01-06 09:15:00', 'Success'),
(42, NULL, 'Withdrawal', 7000.00, '2025-01-09 16:20:00', 'Success'),
(43, 43, 'Transfer', 22000.00, '2025-01-12 12:40:00', 'Success'),
(44, NULL, 'Deposit', 95000.00, '2025-01-15 10:05:00', 'Success'),
(45, NULL, 'Withdrawal', 4500.00, '2025-01-18 17:30:00', 'Success'),
(46, 46, 'Transfer', 31000.00, '2025-01-21 13:15:00', 'Pending'),
(47, NULL, 'Deposit', 52000.00, '2025-01-24 08:45:00', 'Success'),
(48, NULL, 'Withdrawal', 8500.00, '2025-01-27 18:10:00', 'Success'),
(49, 49, 'Transfer', 16000.00, '2025-01-30 11:25:00', 'Success'),
(50, NULL, 'Deposit', 78000.00, '2025-02-02 09:35:00', 'Success'),
(51, NULL, 'Withdrawal', 6000.00, '2025-02-05 15:50:00', 'Failed'),
(52, 52, 'Transfer', 25000.00, '2025-02-08 12:15:00', 'Success'),
(53, NULL, 'Deposit', 64000.00, '2025-02-11 10:30:00', 'Success'),
(54, NULL, 'Withdrawal', 9000.00, '2025-02-14 17:05:00', 'Success'),
(55, 55, 'Transfer', 28000.00, '2025-02-17 13:45:00', 'Success'),
(56, NULL, 'Deposit', 87000.00, '2025-02-20 09:20:00', 'Success'),
(57, NULL, 'Withdrawal', 5500.00, '2025-02-23 16:35:00', 'Success'),
(58, 58, 'Transfer', 19000.00, '2025-02-26 11:55:00', 'Success'),
(59, NULL, 'Deposit', 46000.00, '2025-03-01 08:40:00', 'Success'),
(60, NULL, 'Withdrawal', 7500.00, '2025-03-04 18:15:00', 'Pending'),
(61, 61, 'Transfer', 34000.00, '2025-03-07 12:30:00', 'Success'),
(62, NULL, 'Deposit', 72000.00, '2025-03-10 09:50:00', 'Success'),
(63, NULL, 'Withdrawal', 5000.00, '2025-03-13 15:25:00', 'Success'),
(64, 64, 'Transfer', 21000.00, '2025-03-16 13:10:00', 'Success'),
(65, NULL, 'Deposit', 91000.00, '2025-03-19 10:15:00', 'Success'),
(66, NULL, 'Withdrawal', 6500.00, '2025-03-22 17:40:00', 'Success'),
(67, 67, 'Transfer', 27000.00, '2025-03-25 11:20:00', 'Failed'),
(68, NULL, 'Deposit', 58000.00, '2025-03-28 08:55:00', 'Success'),
(69, NULL, 'Withdrawal', 4000.00, '2025-03-31 16:30:00', 'Success'),
(70, 70, 'Transfer', 30000.00, '2025-04-03 14:05:00', 'Success'),
(71, NULL, 'Deposit', 76000.00, '2025-04-06 09:25:00', 'Success'),
(72, NULL, 'Withdrawal', 8500.00, '2025-04-09 18:20:00', 'Success'),
(73, 73, 'Transfer', 17000.00, '2025-04-12 12:45:00', 'Success'),
(74, NULL, 'Deposit', 99000.00, '2025-04-15 10:10:00', 'Success'),
(75, NULL, 'Withdrawal', 7000.00, '2025-04-18 16:55:00', 'Success'),
(76, 76, 'Transfer', 24000.00, '2025-04-21 13:30:00', 'Success'),
(77, NULL, 'Deposit', 61000.00, '2025-04-24 08:35:00', 'Success'),
(78, NULL, 'Withdrawal', 3500.00, '2025-04-27 17:15:00', 'Failed'),
(79, 79, 'Transfer', 36000.00, '2025-04-30 11:40:00', 'Success'),
(80, NULL, 'Deposit', 83000.00, '2025-05-03 09:05:00', 'Success'),
(81, NULL, 'Withdrawal', 6000.00, '2025-05-06 15:20:00', 'Success'),
(82, 82, 'Transfer', 20000.00, '2025-05-09 12:35:00', 'Success'),
(83, NULL, 'Deposit', 74000.00, '2025-05-12 10:25:00', 'Success'),
(84, NULL, 'Withdrawal', 9500.00, '2025-05-15 18:05:00', 'Pending'),
(85, 85, 'Transfer', 29000.00, '2025-05-18 13:50:00', 'Success'),
(86, NULL, 'Deposit', 88000.00, '2025-05-21 09:30:00', 'Success'),
(87, NULL, 'Withdrawal', 5000.00, '2025-05-24 16:45:00', 'Success'),
(88, 88, 'Transfer', 14000.00, '2025-05-27 11:15:00', 'Success'),
(89, NULL, 'Deposit', 56000.00, '2025-05-30 08:50:00', 'Success'),
(90, NULL, 'Withdrawal', 8000.00, '2025-06-02 17:25:00', 'Success'),
(91, 91, 'Transfer', 26000.00, '2025-06-05 12:20:00', 'Success'),
(92, NULL, 'Deposit', 69000.00, '2025-06-08 09:45:00', 'Success'),
(93, NULL, 'Withdrawal', 5500.00, '2025-06-11 16:15:00', 'Success'),
(94, 94, 'Transfer', 18000.00, '2025-06-14 13:40:00', 'Success'),
(95, NULL, 'Deposit', 93000.00, '2025-06-17 10:20:00', 'Success'),
(96, NULL, 'Withdrawal', 7500.00, '2025-06-20 17:50:00', 'Success'),
(97, 97, 'Transfer', 32000.00, '2025-06-23 11:35:00', 'Pending'),
(98, NULL, 'Deposit', 57000.00, '2025-06-26 08:30:00', 'Success'),
(99, NULL, 'Withdrawal', 4000.00, '2025-06-29 15:45:00', 'Success'),
(100, 100, 'Transfer', 23000.00, '2025-07-02 12:05:00', 'Success'),
(101, NULL, 'Deposit', 81000.00, '2025-07-05 09:25:00', 'Success'),
(102, NULL, 'Withdrawal', 6500.00, '2025-07-08 16:40:00', 'Success'),
(103, 103, 'Transfer', 27000.00, '2025-07-11 13:15:00', 'Success'),
(104, NULL, 'Deposit', 97000.00, '2025-07-14 10:50:00', 'Success'),
(105, NULL, 'Withdrawal', 8500.00, '2025-07-17 18:25:00', 'Failed'),
(106, 106, 'Transfer', 15000.00, '2025-07-20 11:45:00', 'Success'),
(107, NULL, 'Deposit', 62000.00, '2025-07-23 08:55:00', 'Success'),
(108, NULL, 'Withdrawal', 5000.00, '2025-07-26 17:10:00', 'Success'),
(109, 109, 'Transfer', 35000.00, '2025-07-29 12:30:00', 'Success'),
(110, NULL, 'Deposit', 86000.00, '2025-08-01 09:15:00', 'Success'),
(111, NULL, 'Withdrawal', 7000.00, '2025-08-04 16:25:00', 'Success'),
(112, 112, 'Transfer', 21000.00, '2025-08-07 13:50:00', 'Success'),
(113, NULL, 'Deposit', 54000.00, '2025-08-10 10:35:00', 'Success'),
(114, NULL, 'Withdrawal', 4500.00, '2025-08-13 18:00:00', 'Pending'),
(115, 115, 'Transfer', 29000.00, '2025-08-16 12:15:00', 'Success'),
(116, NULL, 'Deposit', 92000.00, '2025-08-19 09:40:00', 'Success'),
(117, NULL, 'Withdrawal', 6000.00, '2025-08-22 15:55:00', 'Success'),
(118, 118, 'Transfer', 17000.00, '2025-08-25 11:25:00', 'Success'),
(119, NULL, 'Deposit', 73000.00, '2025-08-28 08:45:00', 'Success'),
(120, NULL, 'Withdrawal', 9000.00, '2025-08-31 17:30:00', 'Success'),
(121, 121, 'Transfer', 24000.00, '2025-09-03 12:10:00', 'Success'),
(122, NULL, 'Deposit', 67000.00, '2025-09-06 09:20:00', 'Success'),
(123, NULL, 'Withdrawal', 5500.00, '2025-09-09 16:35:00', 'Success'),
(124, 124, 'Transfer', 31000.00, '2025-09-12 13:25:00', 'Success'),
(125, NULL, 'Deposit', 84000.00, '2025-09-15 10:15:00', 'Success'),
(126, NULL, 'Withdrawal', 7000.00, '2025-09-18 18:10:00', 'Failed'),
(127, 127, 'Transfer', 22000.00, '2025-09-21 11:40:00', 'Success'),
(128, NULL, 'Deposit', 59000.00, '2025-09-24 08:50:00', 'Success'),
(129, NULL, 'Withdrawal', 3500.00, '2025-09-27 15:30:00', 'Success'),
(130, 130, 'Transfer', 28000.00, '2025-09-30 12:45:00', 'Success'),
(131, NULL, 'Deposit', 76000.00, '2025-10-03 09:05:00', 'Success'),
(132, NULL, 'Withdrawal', 8000.00, '2025-10-06 17:20:00', 'Success'),
(133, 133, 'Transfer', 19000.00, '2025-10-09 13:35:00', 'Success'),
(134, NULL, 'Deposit', 98000.00, '2025-10-12 10:25:00', 'Success'),
(135, NULL, 'Withdrawal', 6500.00, '2025-10-15 16:50:00', 'Success'),
(136, 136, 'Transfer', 33000.00, '2025-10-18 12:30:00', 'Success'),
(137, NULL, 'Deposit', 51000.00, '2025-10-21 08:40:00', 'Success'),
(138, NULL, 'Withdrawal', 4500.00, '2025-10-24 18:15:00', 'Pending'),
(139, 139, 'Transfer', 16000.00, '2025-10-27 11:55:00', 'Success'),
(140, NULL, 'Deposit', 89000.00, '2025-10-30 09:30:00', 'Success'),
(141, NULL, 'Withdrawal', 6000.00, '2025-11-02 16:10:00', 'Success'),
(142, 142, 'Transfer', 25000.00, '2025-11-05 12:25:00', 'Success'),
(143, NULL, 'Deposit', 71000.00, '2025-11-08 09:35:00', 'Success'),
(144, NULL, 'Withdrawal', 5000.00, '2025-11-11 17:45:00', 'Success'),
(145, 145, 'Transfer', 34000.00, '2025-11-14 13:20:00', 'Success'),
(146, NULL, 'Deposit', 85000.00, '2025-11-17 10:05:00', 'Success'),
(147, NULL, 'Withdrawal', 7500.00, '2025-11-20 18:30:00', 'Failed'),
(148, 148, 'Transfer', 18000.00, '2025-11-23 11:50:00', 'Success'),
(149, NULL, 'Deposit', 63000.00, '2025-11-26 08:45:00', 'Success'),
(150, NULL, 'Withdrawal', 4000.00, '2025-11-29 15:15:00', 'Success'),
(151, 151, 'Transfer', 27000.00, '2025-12-02 12:40:00', 'Success'),
(152, NULL, 'Deposit', 94000.00, '2025-12-05 09:25:00', 'Success'),
(153, NULL, 'Withdrawal', 6500.00, '2025-12-08 16:55:00', 'Success'),
(154, 154, 'Transfer', 22000.00, '2025-12-11 13:35:00', 'Pending'),
(155, NULL, 'Deposit', 78000.00, '2025-12-14 10:15:00', 'Success'),
(156, NULL, 'Withdrawal', 8500.00, '2025-12-17 18:05:00', 'Success'),
(157, 157, 'Transfer', 30000.00, '2025-12-20 11:30:00', 'Success'),
(158, NULL, 'Deposit', 56000.00, '2025-12-23 08:55:00', 'Success'),
(159, NULL, 'Withdrawal', 3500.00, '2025-12-26 15:40:00', 'Success'),
(160, 160, 'Transfer', 26000.00, '2025-12-29 12:15:00', 'Success'),
(161, NULL, 'Deposit', 82000.00, '2026-01-02 09:20:00', 'Success'),
(162, NULL, 'Withdrawal', 7000.00, '2026-01-05 16:35:00', 'Success'),
(163, 163, 'Transfer', 15000.00, '2026-01-08 13:10:00', 'Success'),
(164, NULL, 'Deposit', 96000.00, '2026-01-11 10:45:00', 'Success'),
(165, NULL, 'Withdrawal', 6000.00, '2026-01-14 17:25:00', 'Success'),
(166, 166, 'Transfer', 29000.00, '2026-01-17 12:50:00', 'Failed'),
(167, NULL, 'Deposit', 68000.00, '2026-01-20 08:40:00', 'Success'),
(168, NULL, 'Withdrawal', 4500.00, '2026-01-23 15:55:00', 'Success'),
(169, 169, 'Transfer', 20000.00, '2026-01-26 11:35:00', 'Success'),
(170, NULL, 'Deposit', 90000.00, '2026-01-29 09:10:00', 'Success'),
(171, NULL, 'Withdrawal', 5500.00, '2026-02-01 18:15:00', 'Success'),
(172, 172, 'Transfer', 24000.00, '2026-02-04 12:30:00', 'Success'),
(173, NULL, 'Deposit', 74000.00, '2026-02-07 09:50:00', 'Success'),
(174, NULL, 'Withdrawal', 8000.00, '2026-02-10 16:20:00', 'Success'),
(175, 175, 'Transfer', 32000.00, '2026-02-13 13:45:00', 'Success'),
(176, NULL, 'Deposit', 87000.00, '2026-02-16 10:25:00', 'Success'),
(177, NULL, 'Withdrawal', 6500.00, '2026-02-19 17:40:00', 'Pending'),
(178, 178, 'Transfer', 17000.00, '2026-02-22 11:15:00', 'Success'),
(179, NULL, 'Deposit', 52000.00, '2026-02-25 08:35:00', 'Success'),
(180, NULL, 'Withdrawal', 9500.00, '2026-02-28 18:00:00', 'Success'),
(181, 181, 'Transfer', 28000.00, '2026-03-03 12:20:00', 'Success'),
(182, NULL, 'Deposit', 79000.00, '2026-03-06 09:40:00', 'Success'),
(183, NULL, 'Withdrawal', 5000.00, '2026-03-09 16:30:00', 'Success'),
(184, 184, 'Transfer', 23000.00, '2026-03-12 13:05:00', 'Success'),
(185, NULL, 'Deposit', 92000.00, '2026-03-15 10:10:00', 'Success'),
(186, NULL, 'Withdrawal', 7000.00, '2026-03-18 17:55:00', 'Failed'),
(187, 187, 'Transfer', 35000.00, '2026-03-21 11:45:00', 'Success'),
(188, NULL, 'Deposit', 61000.00, '2026-03-24 08:50:00', 'Success'),
(189, NULL, 'Withdrawal', 4000.00, '2026-03-27 15:25:00', 'Success'),
(190, 190, 'Transfer', 19000.00, '2026-03-30 12:35:00', 'Success'),
(191, NULL, 'Deposit', 76000.00, '2026-04-02 09:15:00', 'Success'),
(192, NULL, 'Withdrawal', 6000.00, '2026-04-05 16:40:00', 'Success'),
(193, 193, 'Transfer', 21000.00, '2026-04-08 12:25:00', 'Success'),
(194, NULL, 'Deposit', 88000.00, '2026-04-11 10:05:00', 'Success'),
(195, NULL, 'Withdrawal', 7500.00, '2026-04-14 17:30:00', 'Pending'),
(196, 196, 'Transfer', 29000.00, '2026-04-17 13:45:00', 'Success'),
(197, NULL, 'Deposit', 54000.00, '2026-04-20 08:50:00', 'Success'),
(198, NULL, 'Withdrawal', 4500.00, '2026-04-23 15:20:00', 'Success'),
(199, 199, 'Transfer', 18000.00, '2026-04-26 11:35:00', 'Success'),
(200, NULL, 'Deposit', 93000.00, '2026-04-29 09:40:00', 'Success'),
(1, NULL, 'Withdrawal', 8500.00, '2026-05-02 18:15:00', 'Success'),
(2, 2, 'Transfer', 26000.00, '2026-05-05 12:30:00', 'Success'),
(3, NULL, 'Deposit', 67000.00, '2026-05-08 09:25:00', 'Success'),
(4, NULL, 'Withdrawal', 5000.00, '2026-05-11 16:55:00', 'Failed'),
(5, 5, 'Transfer', 32000.00, '2026-05-14 13:10:00', 'Success'),
(6, NULL, 'Deposit', 84000.00, '2026-05-17 10:20:00', 'Success'),
(7, NULL, 'Withdrawal', 7000.00, '2026-05-20 17:40:00', 'Success'),
(8, 8, 'Transfer', 15000.00, '2026-05-23 11:50:00', 'Success'),
(9, NULL, 'Deposit', 58000.00, '2026-05-26 08:45:00', 'Success'),
(10, NULL, 'Withdrawal', 4000.00, '2026-05-29 15:35:00', 'Success'),
(11, 11, 'Transfer', 24000.00, '2026-06-01 12:15:00', 'Success'),
(12, NULL, 'Deposit', 91000.00, '2026-06-04 09:30:00', 'Success'),
(13, NULL, 'Withdrawal', 6500.00, '2026-06-07 16:25:00', 'Success'),
(14, 14, 'Transfer', 27000.00, '2026-06-10 13:40:00', 'Success'),
(15, NULL, 'Deposit', 73000.00, '2026-06-13 10:10:00', 'Success'),
(16, NULL, 'Withdrawal', 9000.00, '2026-06-16 18:05:00', 'Success'),
(17, 17, 'Transfer', 19000.00, '2026-06-19 11:25:00', 'Pending'),
(18, NULL, 'Deposit', 62000.00, '2026-06-22 08:55:00', 'Success'),
(19, NULL, 'Withdrawal', 5500.00, '2026-06-25 15:45:00', 'Success'),
(20, 20, 'Transfer', 35000.00, '2026-06-28 12:35:00', 'Success'),
(21, NULL, 'Deposit', 82000.00, '2026-07-01 09:20:00', 'Success'),
(22, NULL, 'Withdrawal', 7000.00, '2026-07-04 16:35:00', 'Success'),
(23, 23, 'Transfer', 23000.00, '2026-07-07 12:10:00', 'Success'),
(24, NULL, 'Deposit', 96000.00, '2026-07-10 10:25:00', 'Success'),
(25, NULL, 'Withdrawal', 5000.00, '2026-07-13 17:45:00', 'Success'),
(26, 26, 'Transfer', 28000.00, '2026-07-16 13:30:00', 'Success'),
(27, NULL, 'Deposit', 59000.00, '2026-07-19 08:40:00', 'Success'),
(28, NULL, 'Withdrawal', 8500.00, '2026-07-22 15:55:00', 'Failed'),
(29, 29, 'Transfer', 17000.00, '2026-07-25 11:20:00', 'Success'),
(30, NULL, 'Deposit', 87000.00, '2026-07-28 09:35:00', 'Success'),
(31, NULL, 'Withdrawal', 6500.00, '2026-07-31 18:10:00', 'Success'),
(32, 32, 'Transfer', 31000.00, '2026-08-03 12:45:00', 'Success'),
(33, NULL, 'Deposit', 64000.00, '2026-08-06 09:15:00', 'Success'),
(34, NULL, 'Withdrawal', 4000.00, '2026-08-09 16:30:00', 'Success'),
(35, 35, 'Transfer', 22000.00, '2026-08-12 13:25:00', 'Success'),
(36, NULL, 'Deposit', 99000.00, '2026-08-15 10:40:00', 'Success'),
(37, NULL, 'Withdrawal', 7500.00, '2026-08-18 17:20:00', 'Pending'),
(38, 38, 'Transfer', 26000.00, '2026-08-21 11:50:00', 'Success'),
(39, NULL, 'Deposit', 51000.00, '2026-08-24 08:35:00', 'Success'),
(40, NULL, 'Withdrawal', 6000.00, '2026-08-27 15:25:00', 'Success'),
(41, 41, 'Transfer', 34000.00, '2026-08-30 12:05:00', 'Success'),
(42, NULL, 'Deposit', 76000.00, '2026-09-02 09:30:00', 'Success'),
(43, NULL, 'Withdrawal', 5500.00, '2026-09-05 16:20:00', 'Success'),
(44, 44, 'Transfer', 20000.00, '2026-09-08 13:15:00', 'Success'),
(45, NULL, 'Deposit', 91000.00, '2026-09-11 10:35:00', 'Success'),
(46, NULL, 'Withdrawal', 8000.00, '2026-09-14 18:25:00', 'Success'),
(47, 47, 'Transfer', 15000.00, '2026-09-17 11:45:00', 'Success'),
(48, NULL, 'Deposit', 68000.00, '2026-09-20 08:50:00', 'Success'),
(49, NULL, 'Withdrawal', 4500.00, '2026-09-23 15:40:00', 'Failed'),
(50, 50, 'Transfer', 29000.00, '2026-09-26 12:30:00', 'Success'),
(51, NULL, 'Deposit', 85000.00, '2026-09-29 09:10:00', 'Success'),
(52, NULL, 'Withdrawal', 7000.00, '2026-10-02 17:55:00', 'Success'),
(53, 53, 'Transfer', 18000.00, '2026-10-05 13:40:00', 'Success'),
(54, NULL, 'Deposit', 63000.00, '2026-10-08 10:20:00', 'Success'),
(55, NULL, 'Withdrawal', 5000.00, '2026-10-11 16:45:00', 'Success'),
(56, 56, 'Transfer', 36000.00, '2026-10-14 12:15:00', 'Success'),
(57, NULL, 'Deposit', 57000.00, '2026-10-17 09:25:00', 'Success'),
(58, NULL, 'Withdrawal', 9000.00, '2026-10-20 18:05:00', 'Pending'),
(59, 59, 'Transfer', 21000.00, '2026-10-23 11:30:00', 'Success'),
(60, NULL, 'Deposit', 94000.00, '2026-10-26 08:45:00', 'Success'),
(61, NULL, 'Withdrawal', 6500.00, '2026-10-29 16:10:00', 'Success'),
(62, 62, 'Transfer', 27000.00, '2026-11-01 12:35:00', 'Success'),
(63, NULL, 'Deposit', 78000.00, '2026-11-04 09:20:00', 'Success'),
(64, NULL, 'Withdrawal', 5500.00, '2026-11-07 17:30:00', 'Success'),
(65, 65, 'Transfer', 32000.00, '2026-11-10 13:45:00', 'Success'),
(66, NULL, 'Deposit', 89000.00, '2026-11-13 10:15:00', 'Success'),
(67, NULL, 'Withdrawal', 7000.00, '2026-11-16 18:20:00', 'Success'),
(68, 68, 'Transfer', 16000.00, '2026-11-19 11:40:00', 'Pending'),
(69, NULL, 'Deposit', 61000.00, '2026-11-22 08:50:00', 'Success'),
(70, NULL, 'Withdrawal', 4000.00, '2026-11-25 15:25:00', 'Success'),
(71, 71, 'Transfer', 25000.00, '2026-11-28 12:05:00', 'Success'),
(72, NULL, 'Deposit', 73000.00, '2026-12-01 09:30:00', 'Success'),
(73, NULL, 'Withdrawal', 8500.00, '2026-12-04 16:45:00', 'Failed'),
(74, 74, 'Transfer', 19000.00, '2026-12-07 13:10:00', 'Success'),
(75, NULL, 'Deposit', 95000.00, '2026-12-10 10:25:00', 'Success'),
(76, NULL, 'Withdrawal', 6000.00, '2026-12-13 17:35:00', 'Success'),
(77, 77, 'Transfer', 28000.00, '2026-12-16 11:55:00', 'Success'),
(78, NULL, 'Deposit', 56000.00, '2026-12-19 08:40:00', 'Success'),
(79, NULL, 'Withdrawal', 4500.00, '2026-12-22 15:15:00', 'Success'),
(80, 80, 'Transfer', 33000.00, '2026-12-25 12:25:00', 'Success'),
(81, NULL, 'Deposit', 81000.00, '2026-12-28 09:15:00', 'Success'),
(82, NULL, 'Withdrawal', 7500.00, '2026-12-31 18:00:00', 'Success'),
(83, 83, 'Transfer', 22000.00, '2027-01-03 13:35:00', 'Success'),
(84, NULL, 'Deposit', 67000.00, '2027-01-06 10:20:00', 'Success'),
(85, NULL, 'Withdrawal', 5000.00, '2027-01-09 16:30:00', 'Pending'),
(86, 86, 'Transfer', 30000.00, '2027-01-12 12:15:00', 'Success'),
(87, NULL, 'Deposit', 88000.00, '2027-01-15 09:40:00', 'Success'),
(88, NULL, 'Withdrawal', 6500.00, '2027-01-18 17:25:00', 'Success'),
(89, 89, 'Transfer', 14000.00, '2027-01-21 11:50:00', 'Success'),
(90, NULL, 'Deposit', 92000.00, '2027-01-24 08:35:00', 'Success'),
(91, NULL, 'Withdrawal', 8000.00, '2027-01-27 15:55:00', 'Success'),
(92, 92, 'Transfer', 26000.00, '2027-01-30 12:40:00', 'Success'),
(93, NULL, 'Deposit', 75000.00, '2027-02-02 09:25:00', 'Success'),
(94, NULL, 'Withdrawal', 5500.00, '2027-02-05 16:20:00', 'Success'),
(95, 95, 'Transfer', 17000.00, '2027-02-08 13:05:00', 'Success'),
(96, NULL, 'Deposit', 98000.00, '2027-02-11 10:30:00', 'Success'),
(97, NULL, 'Withdrawal', 7000.00, '2027-02-14 18:15:00', 'Failed'),
(98, 98, 'Transfer', 24000.00, '2027-02-17 11:35:00', 'Success'),
(99, NULL, 'Deposit', 53000.00, '2027-02-20 08:50:00', 'Success'),
(100, NULL, 'Withdrawal', 9000.00, '2027-02-23 15:40:00', 'Success'),
(101, NULL, 'Deposit', 86000.00, '2027-02-26 09:15:00', 'Success'),
(102, NULL, 'Withdrawal', 6000.00, '2027-03-01 16:25:00', 'Success'),
(103, 103, 'Transfer', 28000.00, '2027-03-04 12:45:00', 'Success'),
(104, NULL, 'Deposit', 94000.00, '2027-03-07 10:20:00', 'Success'),
(105, NULL, 'Withdrawal', 7500.00, '2027-03-10 17:35:00', 'Success'),
(106, 106, 'Transfer', 19000.00, '2027-03-13 13:15:00', 'Pending'),
(107, NULL, 'Deposit', 62000.00, '2027-03-16 08:50:00', 'Success'),
(108, NULL, 'Withdrawal', 4500.00, '2027-03-19 15:40:00', 'Success'),
(109, 109, 'Transfer', 35000.00, '2027-03-22 11:30:00', 'Success'),
(110, NULL, 'Deposit', 79000.00, '2027-03-25 09:05:00', 'Success'),
(111, NULL, 'Withdrawal', 8500.00, '2027-03-28 18:10:00', 'Failed'),
(112, 112, 'Transfer', 23000.00, '2027-03-31 12:25:00', 'Success'),
(113, NULL, 'Deposit', 57000.00, '2027-04-03 10:00:00', 'Success'),
(114, NULL, 'Withdrawal', 5000.00, '2027-04-06 16:35:00', 'Success'),
(115, 115, 'Transfer', 31000.00, '2027-04-09 13:20:00', 'Success'),
(116, NULL, 'Deposit', 91000.00, '2027-04-12 09:45:00', 'Success'),
(117, NULL, 'Withdrawal', 6500.00, '2027-04-15 17:25:00', 'Success'),
(118, 118, 'Transfer', 18000.00, '2027-04-18 11:55:00', 'Success'),
(119, NULL, 'Deposit', 68000.00, '2027-04-21 08:35:00', 'Success'),
(120, NULL, 'Withdrawal', 7000.00, '2027-04-24 15:15:00', 'Success'),
(121, 121, 'Transfer', 26000.00, '2027-04-27 12:30:00', 'Success'),
(122, NULL, 'Deposit', 83000.00, '2027-04-30 09:20:00', 'Success'),
(123, NULL, 'Withdrawal', 5500.00, '2027-05-03 16:45:00', 'Success'),
(124, 124, 'Transfer', 22000.00, '2027-05-06 13:10:00', 'Success'),
(125, NULL, 'Deposit', 97000.00, '2027-05-09 10:30:00', 'Success'),
(126, NULL, 'Withdrawal', 4000.00, '2027-05-12 18:05:00', 'Success'),
(127, 127, 'Transfer', 29000.00, '2027-05-15 11:40:00', 'Success'),
(128, NULL, 'Deposit', 55000.00, '2027-05-18 08:55:00', 'Success'),
(129, NULL, 'Withdrawal', 9000.00, '2027-05-21 15:30:00', 'Pending'),
(130, 130, 'Transfer', 16000.00, '2027-05-24 12:20:00', 'Success'),
(131, NULL, 'Deposit', 76000.00, '2027-05-27 09:10:00', 'Success'),
(132, NULL, 'Withdrawal', 6000.00, '2027-05-30 17:20:00', 'Success'),
(133, 133, 'Transfer', 34000.00, '2027-06-02 13:40:00', 'Success'),
(134, NULL, 'Deposit', 89000.00, '2027-06-05 10:15:00', 'Success'),
(135, NULL, 'Withdrawal', 7500.00, '2027-06-08 16:50:00', 'Failed'),
(136, 136, 'Transfer', 21000.00, '2027-06-11 12:35:00', 'Success'),
(137, NULL, 'Deposit', 63000.00, '2027-06-14 09:25:00', 'Success'),
(138, NULL, 'Withdrawal', 5000.00, '2027-06-17 18:15:00', 'Success'),
(139, 139, 'Transfer', 27000.00, '2027-06-20 11:45:00', 'Success'),
(140, NULL, 'Deposit', 93000.00, '2027-06-23 08:40:00', 'Success'),
(141, NULL, 'Withdrawal', 8500.00, '2027-06-26 15:35:00', 'Success'),
(142, 142, 'Transfer', 20000.00, '2027-06-29 12:10:00', 'Success'),
(143, NULL, 'Deposit', 72000.00, '2027-07-02 09:30:00', 'Success'),
(144, NULL, 'Withdrawal', 6500.00, '2027-07-05 17:45:00', 'Success'),
(145, 145, 'Transfer', 30000.00, '2027-07-08 13:25:00', 'Success'),
(146, NULL, 'Deposit', 85000.00, '2027-07-11 10:05:00', 'Success'),
(147, NULL, 'Withdrawal', 4500.00, '2027-07-14 16:30:00', 'Success'),
(148, 148, 'Transfer', 24000.00, '2027-07-17 12:50:00', 'Success'),
(149, NULL, 'Deposit', 60000.00, '2027-07-20 08:45:00', 'Success'),
(150, NULL, 'Withdrawal', 8000.00, '2027-07-23 15:25:00', 'Success'),
(151, 151, 'Transfer', 26000.00, '2027-07-26 12:15:00', 'Success'),
(152, NULL, 'Deposit', 78000.00, '2027-07-29 09:35:00', 'Success'),
(153, NULL, 'Withdrawal', 5500.00, '2027-08-01 16:20:00', 'Success'),
(154, 154, 'Transfer', 32000.00, '2027-08-04 13:40:00', 'Success'),
(155, NULL, 'Deposit', 92000.00, '2027-08-07 10:25:00', 'Success'),
(156, NULL, 'Withdrawal', 7000.00, '2027-08-10 17:30:00', 'Pending'),
(157, 157, 'Transfer', 18000.00, '2027-08-13 11:50:00', 'Success'),
(158, NULL, 'Deposit', 57000.00, '2027-08-16 08:40:00', 'Success'),
(159, NULL, 'Withdrawal', 4500.00, '2027-08-19 15:35:00', 'Success'),
(160, 160, 'Transfer', 29000.00, '2027-08-22 12:25:00', 'Success'),
(161, NULL, 'Deposit', 83000.00, '2027-08-25 09:10:00', 'Success'),
(162, NULL, 'Withdrawal', 6000.00, '2027-08-28 18:05:00', 'Success'),
(163, 163, 'Transfer', 21000.00, '2027-08-31 13:15:00', 'Success'),
(164, NULL, 'Deposit', 96000.00, '2027-09-03 10:35:00', 'Success'),
(165, NULL, 'Withdrawal', 8500.00, '2027-09-06 16:45:00', 'Failed'),
(166, 166, 'Transfer', 27000.00, '2027-09-09 12:20:00', 'Success'),
(167, NULL, 'Deposit', 65000.00, '2027-09-12 09:30:00', 'Success'),
(168, NULL, 'Withdrawal', 5000.00, '2027-09-15 17:15:00', 'Success'),
(169, 169, 'Transfer', 34000.00, '2027-09-18 11:40:00', 'Success'),
(170, NULL, 'Deposit', 88000.00, '2027-09-21 08:50:00', 'Success'),
(171, NULL, 'Withdrawal', 7500.00, '2027-09-24 15:25:00', 'Success'),
(172, 172, 'Transfer', 22000.00, '2027-09-27 12:35:00', 'Success'),
(173, NULL, 'Deposit', 71000.00, '2027-09-30 09:20:00', 'Success'),
(174, NULL, 'Withdrawal', 4000.00, '2027-10-03 16:40:00', 'Success'),
(175, 175, 'Transfer', 30000.00, '2027-10-06 13:05:00', 'Success'),
(176, NULL, 'Deposit', 99000.00, '2027-10-09 10:15:00', 'Success'),
(177, NULL, 'Withdrawal', 6500.00, '2027-10-12 17:45:00', 'Pending'),
(178, 178, 'Transfer', 16000.00, '2027-10-15 11:30:00', 'Success'),
(179, NULL, 'Deposit', 54000.00, '2027-10-18 08:55:00', 'Success'),
(180, NULL, 'Withdrawal', 9000.00, '2027-10-21 15:50:00', 'Success'),
(181, 181, 'Transfer', 25000.00, '2027-10-24 12:10:00', 'Success'),
(182, NULL, 'Deposit', 86000.00, '2027-10-27 09:25:00', 'Success'),
(183, NULL, 'Withdrawal', 5500.00, '2027-10-30 16:35:00', 'Success'),
(184, 184, 'Transfer', 19000.00, '2027-11-02 13:20:00', 'Success'),
(185, NULL, 'Deposit', 74000.00, '2027-11-05 10:10:00', 'Success'),
(186, NULL, 'Withdrawal', 7000.00, '2027-11-08 18:20:00', 'Success'),
(187, 187, 'Transfer', 28000.00, '2027-11-11 11:45:00', 'Success'),
(188, NULL, 'Deposit', 61000.00, '2027-11-14 08:40:00', 'Success'),
(189, NULL, 'Withdrawal', 3500.00, '2027-11-17 15:15:00', 'Success'),
(190, 190, 'Transfer', 33000.00, '2027-11-20 12:25:00', 'Success'),
(191, NULL, 'Deposit', 90000.00, '2027-11-23 09:35:00', 'Success'),
(192, NULL, 'Withdrawal', 8000.00, '2027-11-26 17:05:00', 'Failed'),
(193, 193, 'Transfer', 24000.00, '2027-11-29 13:45:00', 'Success'),
(194, NULL, 'Deposit', 67000.00, '2027-12-02 10:20:00', 'Success'),
(195, NULL, 'Withdrawal', 6000.00, '2027-12-05 16:55:00', 'Success'),
(196, 196, 'Transfer', 31000.00, '2027-12-08 12:30:00', 'Success'),
(197, NULL, 'Deposit', 58000.00, '2027-12-11 09:15:00', 'Success'),
(198, NULL, 'Withdrawal', 4500.00, '2027-12-14 18:10:00', 'Success'),
(199, 199, 'Transfer', 20000.00, '2027-12-17 11:35:00', 'Success'),
(200, NULL, 'Deposit', 95000.00, '2027-12-20 08:45:00', 'Success'),
(1, NULL, 'Deposit', 72000.00, '2027-12-23 09:20:00', 'Success'),
(2, NULL, 'Withdrawal', 6500.00, '2027-12-26 16:35:00', 'Success'),
(3, 3, 'Transfer', 28000.00, '2027-12-29 12:15:00', 'Success'),
(4, NULL, 'Deposit', 89000.00, '2028-01-02 10:05:00', 'Success'),
(5, NULL, 'Withdrawal', 4500.00, '2028-01-05 17:25:00', 'Success'),
(6, 6, 'Transfer', 23000.00, '2028-01-08 13:40:00', 'Pending'),
(7, NULL, 'Deposit', 61000.00, '2028-01-11 08:50:00', 'Success'),
(8, NULL, 'Withdrawal', 7000.00, '2028-01-14 15:30:00', 'Success'),
(9, 9, 'Transfer', 35000.00, '2028-01-17 11:45:00', 'Success'),
(10, NULL, 'Deposit', 94000.00, '2028-01-20 09:25:00', 'Success'),
(11, NULL, 'Withdrawal', 5500.00, '2028-01-23 16:40:00', 'Failed'),
(12, 12, 'Transfer', 19000.00, '2028-01-26 12:20:00', 'Success'),
(13, NULL, 'Deposit', 76000.00, '2028-01-29 10:15:00', 'Success'),
(14, NULL, 'Withdrawal', 8000.00, '2028-02-01 18:05:00', 'Success'),
(15, 15, 'Transfer', 27000.00, '2028-02-04 13:25:00', 'Success'),
(16, NULL, 'Deposit', 85000.00, '2028-02-07 09:40:00', 'Success'),
(17, NULL, 'Withdrawal', 6000.00, '2028-02-10 17:15:00', 'Success'),
(18, 18, 'Transfer', 16000.00, '2028-02-13 11:30:00', 'Success'),
(19, NULL, 'Deposit', 53000.00, '2028-02-16 08:45:00', 'Success'),
(20, NULL, 'Withdrawal', 9000.00, '2028-02-19 15:55:00', 'Success'),
(21, 21, 'Transfer', 32000.00, '2028-02-22 12:35:00', 'Success'),
(22, NULL, 'Deposit', 68000.00, '2028-02-25 09:10:00', 'Success'),
(23, NULL, 'Withdrawal', 5000.00, '2028-02-28 16:25:00', 'Success'),
(24, 24, 'Transfer', 21000.00, '2028-03-02 13:15:00', 'Success'),
(25, NULL, 'Deposit', 97000.00, '2028-03-05 10:20:00', 'Success'),
(26, NULL, 'Withdrawal', 7500.00, '2028-03-08 18:10:00', 'Pending'),
(27, 27, 'Transfer', 29000.00, '2028-03-11 11:50:00', 'Success'),
(28, NULL, 'Deposit', 59000.00, '2028-03-14 08:35:00', 'Success'),
(29, NULL, 'Withdrawal', 4000.00, '2028-03-17 15:40:00', 'Success'),
(30, 30, 'Transfer', 24000.00, '2028-03-20 12:25:00', 'Success'),
(31, NULL, 'Deposit', 82000.00, '2028-03-23 09:30:00', 'Success'),
(32, NULL, 'Withdrawal', 6500.00, '2028-03-26 17:20:00', 'Success'),
(33, 33, 'Transfer', 18000.00, '2028-03-29 13:35:00', 'Success'),
(34, NULL, 'Deposit', 91000.00, '2028-04-01 10:10:00', 'Success'),
(35, NULL, 'Withdrawal', 5500.00, '2028-04-04 16:45:00', 'Success'),
(36, 36, 'Transfer', 33000.00, '2028-04-07 12:05:00', 'Success'),
(37, NULL, 'Deposit', 64000.00, '2028-04-10 09:20:00', 'Success'),
(38, NULL, 'Withdrawal', 8500.00, '2028-04-13 18:00:00', 'Failed'),
(39, 39, 'Transfer', 20000.00, '2028-04-16 11:25:00', 'Success'),
(40, NULL, 'Deposit', 88000.00, '2028-04-19 08:50:00', 'Success');

SELECT DISTINCT(transaction_type) FROM transactions;
SELECT COUNT(*) FROM transactions;
SELECT * FROM transactions;

INSERT INTO cards (account_id, card_number, card_type, issue_date, expiry_date, card_status)
VALUES
(1, '4539126789012345', 'Debit', '2022-01-15', '2027-01-31', 'Active'),
(2, '4539126789012346', 'Debit', '2022-02-10', '2027-02-28', 'Active'),
(3, '4539126789012347', 'Credit', '2021-03-05', '2026-03-31', 'Expired'),
(4, '4539126789012348', 'Debit', '2023-04-12', '2028-04-30', 'Active'),
(5, '4539126789012349', 'Credit', '2022-05-18', '2027-05-31', 'Blocked'),
(6, '4539126789012350', 'Debit', '2023-06-20', '2028-06-30', 'Active'),
(7, '4539126789012351', 'Debit', '2022-07-25', '2027-07-31', 'Active'),
(8, '4539126789012352', 'Credit', '2021-08-14', '2026-08-31', 'Expired'),
(9, '4539126789012353', 'Debit', '2023-09-09', '2028-09-30', 'Active'),
(10, '4539126789012354', 'Credit', '2022-10-22', '2027-10-31', 'Active'),
(11, '4539126789012355', 'Debit', '2023-01-11', '2028-01-31', 'Active'),
(12, '4539126789012356', 'Debit', '2022-02-16', '2027-02-28', 'Blocked'),
(13, '4539126789012357', 'Credit', '2021-03-21', '2026-03-31', 'Expired'),
(14, '4539126789012358', 'Debit', '2023-04-17', '2028-04-30', 'Active'),
(15, '4539126789012359', 'Credit', '2022-05-27', '2027-05-31', 'Active'),
(16, '4539126789012360', 'Debit', '2023-06-08', '2028-06-30', 'Active'),
(17, '4539126789012361', 'Debit', '2022-07-19', '2027-07-31', 'Active'),
(18, '4539126789012362', 'Credit', '2021-08-25', '2026-08-31', 'Expired'),
(19, '4539126789012363', 'Debit', '2023-09-13', '2028-09-30', 'Active'),
(20, '4539126789012364', 'Credit', '2022-10-30', '2027-10-31', 'Blocked'),
(21, '4539126789012365', 'Debit', '2023-01-19', '2028-01-31', 'Active'),
(22, '4539126789012366', 'Debit', '2022-02-24', '2027-02-28', 'Active'),
(23, '4539126789012367', 'Credit', '2021-03-18', '2026-03-31', 'Expired'),
(24, '4539126789012368', 'Debit', '2023-04-22', '2028-04-30', 'Active'),
(25, '4539126789012369', 'Credit', '2022-05-14', '2027-05-31', 'Active'),
(26, '4539126789012370', 'Debit', '2023-06-11', '2028-06-30', 'Active'),
(27, '4539126789012371', 'Debit', '2022-07-28', '2027-07-31', 'Blocked'),
(28, '4539126789012372', 'Credit', '2021-08-09', '2026-08-31', 'Expired'),
(29, '4539126789012373', 'Debit', '2023-09-16', '2028-09-30', 'Active'),
(30, '4539126789012374', 'Credit', '2022-10-12', '2027-10-31', 'Active'),
(31, '4539126789012375', 'Debit', '2023-02-14', '2028-02-29', 'Active'),
(32, '4539126789012376', 'Credit', '2022-03-20', '2027-03-31', 'Active'),
(33, '4539126789012377', 'Debit', '2021-04-25', '2026-04-30', 'Expired'),
(34, '4539126789012378', 'Debit', '2023-05-11', '2028-05-31', 'Active'),
(35, '4539126789012379', 'Credit', '2022-06-16', '2027-06-30', 'Blocked'),
(36, '4539126789012380', 'Debit', '2023-07-22', '2028-07-31', 'Active'),
(37, '4539126789012381', 'Debit', '2022-08-18', '2027-08-31', 'Active'),
(38, '4539126789012382', 'Credit', '2021-09-12', '2026-09-30', 'Expired'),
(39, '4539126789012383', 'Debit', '2023-10-05', '2028-10-31', 'Active'),
(40, '4539126789012384', 'Credit', '2022-11-14', '2027-11-30', 'Active'),
(41, '4539126789012385', 'Debit', '2023-01-25', '2028-01-31', 'Active'),
(42, '4539126789012386', 'Debit', '2022-02-12', '2027-02-28', 'Blocked'),
(43, '4539126789012387', 'Credit', '2021-03-27', '2026-03-31', 'Expired'),
(44, '4539126789012388', 'Debit', '2023-04-19', '2028-04-30', 'Active'),
(45, '4539126789012389', 'Credit', '2022-05-23', '2027-05-31', 'Active'),
(46, '4539126789012390', 'Debit', '2023-06-15', '2028-06-30', 'Active'),
(47, '4539126789012391', 'Debit', '2022-07-09', '2027-07-31', 'Active'),
(48, '4539126789012392', 'Credit', '2021-08-22', '2026-08-31', 'Expired'),
(49, '4539126789012393', 'Debit', '2023-09-14', '2028-09-30', 'Active'),
(50, '4539126789012394', 'Credit', '2022-10-18', '2027-10-31', 'Blocked'),
(51, '4539126789012395', 'Debit', '2023-02-08', '2028-02-29', 'Active'),
(52, '4539126789012396', 'Debit', '2022-03-15', '2027-03-31', 'Active'),
(53, '4539126789012397', 'Credit', '2021-04-11', '2026-04-30', 'Expired'),
(54, '4539126789012398', 'Debit', '2023-05-20', '2028-05-31', 'Active'),
(55, '4539126789012399', 'Credit', '2022-06-25', '2027-06-30', 'Active'),
(56, '4539126789012400', 'Debit', '2023-07-13', '2028-07-31', 'Active'),
(57, '4539126789012401', 'Debit', '2022-08-28', '2027-08-31', 'Blocked'),
(58, '4539126789012402', 'Credit', '2021-09-19', '2026-09-30', 'Expired'),
(59, '4539126789012403', 'Debit', '2023-10-22', '2028-10-31', 'Active'),
(60, '4539126789012404', 'Credit', '2022-11-08', '2027-11-30', 'Active'),
(61, '4539126789012405', 'Debit', '2023-01-18', '2028-01-31', 'Active'),
(62, '4539126789012406', 'Credit', '2022-02-22', '2027-02-28', 'Active'),
(63, '4539126789012407', 'Debit', '2021-03-16', '2026-03-31', 'Expired'),
(64, '4539126789012408', 'Debit', '2023-04-09', '2028-04-30', 'Active'),
(65, '4539126789012409', 'Credit', '2022-05-19', '2027-05-31', 'Blocked'),
(66, '4539126789012410', 'Debit', '2023-06-24', '2028-06-30', 'Active'),
(67, '4539126789012411', 'Debit', '2022-07-17', '2027-07-31', 'Active'),
(68, '4539126789012412', 'Credit', '2021-08-11', '2026-08-31', 'Expired'),
(69, '4539126789012413', 'Debit', '2023-09-26', '2028-09-30', 'Active'),
(70, '4539126789012414', 'Credit', '2022-10-21', '2027-10-31', 'Active'),
(71, '4539126789012415', 'Debit', '2023-01-07', '2028-01-31', 'Active'),
(72, '4539126789012416', 'Debit', '2022-02-15', '2027-02-28', 'Blocked'),
(73, '4539126789012417', 'Credit', '2021-03-29', '2026-03-31', 'Expired'),
(74, '4539126789012418', 'Debit', '2023-04-21', '2028-04-30', 'Active'),
(75, '4539126789012419', 'Credit', '2022-05-26', '2027-05-31', 'Active'),
(76, '4539126789012420', 'Debit', '2023-06-12', '2028-06-30', 'Active'),
(77, '4539126789012421', 'Debit', '2022-07-23', '2027-07-31', 'Active'),
(78, '4539126789012422', 'Credit', '2021-08-30', '2026-08-31', 'Expired'),
(79, '4539126789012423', 'Debit', '2023-09-18', '2028-09-30', 'Active'),
(80, '4539126789012424', 'Credit', '2022-10-09', '2027-10-31', 'Blocked'),
(81, '4539126789012425', 'Debit', '2023-02-11', '2028-02-29', 'Active'),
(82, '4539126789012426', 'Debit', '2022-03-24', '2027-03-31', 'Active'),
(83, '4539126789012427', 'Credit', '2021-04-18', '2026-04-30', 'Expired'),
(84, '4539126789012428', 'Debit', '2023-05-15', '2028-05-31', 'Active'),
(85, '4539126789012429', 'Credit', '2022-06-28', '2027-06-30', 'Active'),
(86, '4539126789012430', 'Debit', '2023-07-19', '2028-07-31', 'Active'),
(87, '4539126789012431', 'Debit', '2022-08-05', '2027-08-31', 'Blocked'),
(88, '4539126789012432', 'Credit', '2021-09-15', '2026-09-30', 'Expired'),
(89, '4539126789012433', 'Debit', '2023-10-12', '2028-10-31', 'Active'),
(90, '4539126789012434', 'Credit', '2022-11-25', '2027-11-30', 'Active'),
(91, '4539126789012435', 'Debit', '2023-01-14', '2028-01-31', 'Active'),
(92, '4539126789012436', 'Debit', '2022-02-28', '2027-02-28', 'Active'),
(93, '4539126789012437', 'Credit', '2021-03-22', '2026-03-31', 'Expired'),
(94, '4539126789012438', 'Debit', '2023-04-26', '2028-04-30', 'Active'),
(95, '4539126789012439', 'Credit', '2022-05-11', '2027-05-31', 'Blocked'),
(96, '4539126789012440', 'Debit', '2023-06-18', '2028-06-30', 'Active'),
(97, '4539126789012441', 'Debit', '2022-07-31', '2027-07-31', 'Active'),
(98, '4539126789012442', 'Credit', '2021-08-16', '2026-08-31', 'Expired'),
(99, '4539126789012443', 'Debit', '2023-09-24', '2028-09-30', 'Active'),
(100, '4539126789012444', 'Credit', '2022-10-27', '2027-10-31', 'Active'),
(101, '4539126789012445', 'Debit', '2023-02-06', '2028-02-29', 'Active'),
(102, '4539126789012446', 'Credit', '2022-03-18', '2027-03-31', 'Active'),
(103, '4539126789012447', 'Debit', '2021-04-23', '2026-04-30', 'Expired'),
(104, '4539126789012448', 'Debit', '2023-05-09', '2028-05-31', 'Active'),
(105, '4539126789012449', 'Credit', '2022-06-21', '2027-06-30', 'Blocked'),
(106, '4539126789012450', 'Debit', '2023-07-16', '2028-07-31', 'Active'),
(107, '4539126789012451', 'Debit', '2022-08-12', '2027-08-31', 'Active'),
(108, '4539126789012452', 'Credit', '2021-09-28', '2026-09-30', 'Expired'),
(109, '4539126789012453', 'Debit', '2023-10-18', '2028-10-31', 'Active'),
(110, '4539126789012454', 'Credit', '2022-11-13', '2027-11-30', 'Active'),
(111, '4539126789012455', 'Debit', '2023-01-21', '2028-01-31', 'Active'),
(112, '4539126789012456', 'Debit', '2022-02-09', '2027-02-28', 'Blocked'),
(113, '4539126789012457', 'Credit', '2021-03-14', '2026-03-31', 'Expired'),
(114, '4539126789012458', 'Debit', '2023-04-28', '2028-04-30', 'Active'),
(115, '4539126789012459', 'Credit', '2022-05-30', '2027-05-31', 'Active'),
(116, '4539126789012460', 'Debit', '2023-06-14', '2028-06-30', 'Active'),
(117, '4539126789012461', 'Debit', '2022-07-26', '2027-07-31', 'Active'),
(118, '4539126789012462', 'Credit', '2021-08-20', '2026-08-31', 'Expired'),
(119, '4539126789012463', 'Debit', '2023-09-07', '2028-09-30', 'Active'),
(120, '4539126789012464', 'Credit', '2022-10-16', '2027-10-31', 'Blocked'),
(121, '4539126789012465', 'Debit', '2023-02-19', '2028-02-29', 'Active'),
(122, '4539126789012466', 'Debit', '2022-03-27', '2027-03-31', 'Active'),
(123, '4539126789012467', 'Credit', '2021-04-08', '2026-04-30', 'Expired'),
(124, '4539126789012468', 'Debit', '2023-05-17', '2028-05-31', 'Active'),
(125, '4539126789012469', 'Credit', '2022-06-09', '2027-06-30', 'Active'),
(126, '4539126789012470', 'Debit', '2023-07-28', '2028-07-31', 'Active'),
(127, '4539126789012471', 'Debit', '2022-08-24', '2027-08-31', 'Blocked'),
(128, '4539126789012472', 'Credit', '2021-09-05', '2026-09-30', 'Expired'),
(129, '4539126789012473', 'Debit', '2023-10-29', '2028-10-31', 'Active'),
(130, '4539126789012474', 'Credit', '2022-11-21', '2027-11-30', 'Active'),
(131, '4539126789012475', 'Debit', '2023-01-12', '2028-01-31', 'Active'),
(132, '4539126789012476', 'Debit', '2022-02-19', '2027-02-28', 'Active'),
(133, '4539126789012477', 'Credit', '2021-03-31', '2026-03-31', 'Expired'),
(134, '4539126789012478', 'Debit', '2023-04-14', '2028-04-30', 'Active'),
(135, '4539126789012479', 'Credit', '2022-05-25', '2027-05-31', 'Blocked'),
(136, '4539126789012480', 'Debit', '2023-06-30', '2028-06-30', 'Active'),
(137, '4539126789012481', 'Debit', '2022-07-14', '2027-07-31', 'Active'),
(138, '4539126789012482', 'Credit', '2021-08-27', '2026-08-31', 'Expired'),
(139, '4539126789012483', 'Debit', '2023-09-20', '2028-09-30', 'Active'),
(140, '4539126789012484', 'Credit', '2022-10-06', '2027-10-31', 'Active'),
(141, '4539126789012485', 'Debit', '2023-02-04', '2028-02-29', 'Active'),
(142, '4539126789012486', 'Debit', '2022-03-11', '2027-03-31', 'Blocked'),
(143, '4539126789012487', 'Credit', '2021-04-16', '2026-04-30', 'Expired'),
(144, '4539126789012488', 'Debit', '2023-05-22', '2028-05-31', 'Active'),
(145, '4539126789012489', 'Credit', '2022-06-26', '2027-06-30', 'Active'),
(146, '4539126789012490', 'Debit', '2023-07-10', '2028-07-31', 'Active'),
(147, '4539126789012491', 'Debit', '2022-08-29', '2027-08-31', 'Blocked'),
(148, '4539126789012492', 'Credit', '2021-09-17', '2026-09-30', 'Expired'),
(149, '4539126789012493', 'Debit', '2023-10-24', '2028-10-31', 'Active'),
(150, '4539126789012494', 'Credit', '2022-11-29', '2027-11-30', 'Active');

SELECT DISTINCT(card_status) FROM cards;
SELECT DISTINCT(card_type) FROM cards;
SELECT COUNT(*) FROM cards;
SELECT * FROM cards;

SELECT 
	card_status,
    COUNT(*) AS count_of_card_status
FROM cards
GROUP BY card_status
ORDER BY 2 DESC;

SELECT 
	card_type,
    COUNT(*) AS count_of_card_type
FROM cards
GROUP BY card_type
ORDER BY 2 DESC;

INSERT INTO loans (customer_id, loan_type, loan_amount, interest_rate, start_date, tenure_months, loan_status)
VALUES
(1, 'Home Loan', 4500000.00, 7.50, '2021-01-15', 240, 'Active'),
(2, 'Personal Loan', 350000.00, 11.25, '2022-03-10', 60, 'Active'),
(3, 'Vehicle Loan', 850000.00, 8.75, '2020-06-20', 84, 'Closed'),
(4, 'Education Loan', 1200000.00, 6.90, '2023-01-12', 120, 'Active'),
(5, 'Business Loan', 2500000.00, 10.50, '2021-08-05', 180, 'Active'),
(6, 'Home Loan', 5200000.00, 7.25, '2022-04-18', 240, 'Active'),
(7, 'Personal Loan', 275000.00, 12.00, '2023-02-14', 48, 'Active'),
(8, 'Vehicle Loan', 950000.00, 8.60, '2021-11-09', 72, 'Closed'),
(9, 'Education Loan', 1500000.00, 7.10, '2022-07-25', 120, 'Active'),
(10, 'Business Loan', 3200000.00, 10.25, '2020-09-30', 180, 'Closed'),
(11, 'Home Loan', 6000000.00, 7.40, '2023-03-15', 240, 'Active'),
(12, 'Personal Loan', 450000.00, 11.75, '2022-05-21', 60, 'Active'),
(13, 'Vehicle Loan', 780000.00, 8.90, '2021-12-12', 84, 'Closed'),
(14, 'Education Loan', 900000.00, 6.75, '2023-06-10', 96, 'Active'),
(15, 'Business Loan', 4100000.00, 10.80, '2022-10-05', 180, 'Active'),
(16, 'Home Loan', 3800000.00, 7.65, '2021-02-22', 180, 'Closed'),
(17, 'Personal Loan', 600000.00, 12.25, '2023-04-19', 72, 'Active'),
(18, 'Vehicle Loan', 1100000.00, 8.50, '2022-09-08', 84, 'Active'),
(19, 'Education Loan', 1300000.00, 7.00, '2021-07-14', 120, 'Closed'),
(20, 'Business Loan', 2800000.00, 10.40, '2023-01-30', 180, 'Active'),
(21, 'Home Loan', 7000000.00, 7.35, '2022-02-17', 240, 'Active'),
(22, 'Personal Loan', 500000.00, 11.90, '2021-05-11', 60, 'Closed'),
(23, 'Vehicle Loan', 900000.00, 8.65, '2023-03-22', 72, 'Active'),
(24, 'Education Loan', 1800000.00, 6.85, '2022-08-15', 120, 'Active'),
(25, 'Business Loan', 3600000.00, 10.60, '2021-10-19', 180, 'Closed'),
(26, 'Home Loan', 5500000.00, 7.55, '2023-05-13', 240, 'Active'),
(27, 'Personal Loan', 300000.00, 12.10, '2022-11-25', 48, 'Active'),
(28, 'Vehicle Loan', 1250000.00, 8.45, '2021-09-17', 84, 'Closed'),
(29, 'Education Loan', 1000000.00, 7.20, '2023-02-08', 96, 'Active'),
(30, 'Business Loan', 4500000.00, 10.30, '2022-06-29', 180, 'Active'),
(31, 'Home Loan', 4800000.00, 7.45, '2021-03-12', 240, 'Active'),
(32, 'Personal Loan', 400000.00, 11.50, '2022-04-26', 60, 'Active'),
(33, 'Vehicle Loan', 750000.00, 8.80, '2020-08-19', 84, 'Closed'),
(34, 'Education Loan', 1400000.00, 6.95, '2023-02-05', 120, 'Active'),
(35, 'Business Loan', 2900000.00, 10.70, '2021-11-23', 180, 'Active'),
(36, 'Home Loan', 6200000.00, 7.30, '2022-07-14', 240, 'Active'),
(37, 'Personal Loan', 550000.00, 11.85, '2023-03-18', 72, 'Closed'),
(38, 'Vehicle Loan', 980000.00, 8.55, '2021-10-09', 84, 'Active'),
(39, 'Education Loan', 1600000.00, 7.05, '2022-12-11', 120, 'Active'),
(40, 'Business Loan', 3700000.00, 10.45, '2020-05-30', 180, 'Closed'),
(41, 'Home Loan', 7500000.00, 7.20, '2023-04-22', 240, 'Active'),
(42, 'Personal Loan', 325000.00, 12.15, '2022-09-16', 60, 'Active'),
(43, 'Vehicle Loan', 880000.00, 8.70, '2021-06-27', 72, 'Closed'),
(44, 'Education Loan', 1150000.00, 6.80, '2023-01-19', 96, 'Active'),
(45, 'Business Loan', 4200000.00, 10.55, '2022-03-28', 180, 'Active'),
(46, 'Home Loan', 3900000.00, 7.60, '2021-12-05', 180, 'Closed'),
(47, 'Personal Loan', 700000.00, 12.05, '2023-05-14', 72, 'Active'),
(48, 'Vehicle Loan', 1050000.00, 8.40, '2022-08-20', 84, 'Active'),
(49, 'Education Loan', 1350000.00, 7.15, '2021-04-18', 120, 'Closed'),
(50, 'Business Loan', 3100000.00, 10.35, '2023-02-25', 180, 'Active'),
(51, 'Home Loan', 6800000.00, 7.35, '2022-01-13', 240, 'Active'),
(52, 'Personal Loan', 425000.00, 11.70, '2021-07-22', 60, 'Closed'),
(53, 'Vehicle Loan', 820000.00, 8.95, '2023-06-08', 72, 'Active'),
(54, 'Education Loan', 1750000.00, 6.85, '2022-11-19', 120, 'Active'),
(55, 'Business Loan', 3900000.00, 10.65, '2021-09-15', 180, 'Closed'),
(56, 'Home Loan', 5800000.00, 7.50, '2023-03-11', 240, 'Active'),
(57, 'Personal Loan', 375000.00, 12.20, '2022-05-30', 48, 'Active'),
(58, 'Vehicle Loan', 1150000.00, 8.35, '2021-08-25', 84, 'Closed'),
(59, 'Education Loan', 1250000.00, 7.25, '2023-01-07', 96, 'Active'),
(60, 'Business Loan', 4700000.00, 10.20, '2022-10-14', 180, 'Active'),
(61, 'Home Loan', 7200000.00, 7.15, '2021-05-20', 240, 'Active'),
(62, 'Personal Loan', 600000.00, 11.95, '2022-12-02', 72, 'Closed'),
(63, 'Vehicle Loan', 950000.00, 8.75, '2023-04-17', 84, 'Active'),
(64, 'Education Loan', 1450000.00, 6.90, '2021-10-28', 120, 'Active'),
(65, 'Business Loan', 3400000.00, 10.75, '2022-06-12', 180, 'Closed'),
(66, 'Home Loan', 5100000.00, 7.55, '2023-02-20', 240, 'Active'),
(67, 'Personal Loan', 475000.00, 12.10, '2021-11-15', 60, 'Active'),
(68, 'Vehicle Loan', 870000.00, 8.60, '2022-08-07', 72, 'Closed'),
(69, 'Education Loan', 1900000.00, 7.00, '2023-05-26', 120, 'Active'),
(70, 'Business Loan', 3600000.00, 10.50, '2021-03-29', 180, 'Active'),
(71, 'Home Loan', 4600000.00, 7.65, '2022-02-11', 180, 'Active'),
(72, 'Personal Loan', 350000.00, 11.80, '2023-06-15', 60, 'Active'),
(73, 'Vehicle Loan', 780000.00, 8.85, '2021-09-21', 84, 'Closed'),
(74, 'Education Loan', 1500000.00, 6.75, '2022-05-18', 120, 'Active'),
(75, 'Business Loan', 2800000.00, 10.60, '2023-01-24', 180, 'Active'),
(76, 'Home Loan', 6300000.00, 7.25, '2021-07-30', 240, 'Closed'),
(77, 'Personal Loan', 525000.00, 12.00, '2022-11-06', 72, 'Active'),
(78, 'Vehicle Loan', 1020000.00, 8.55, '2023-03-09', 84, 'Active'),
(79, 'Education Loan', 1700000.00, 7.10, '2021-12-18', 120, 'Closed'),
(80, 'Business Loan', 4000000.00, 10.40, '2022-08-26', 180, 'Active'),
(81, 'Home Loan', 5600000.00, 7.45, '2023-04-12', 240, 'Active'),
(82, 'Personal Loan', 450000.00, 11.65, '2021-06-22', 60, 'Closed'),
(83, 'Vehicle Loan', 920000.00, 8.70, '2022-10-10', 72, 'Active'),
(84, 'Education Loan', 1350000.00, 6.95, '2023-02-16', 96, 'Active'),
(85, 'Business Loan', 3300000.00, 10.55, '2021-11-28', 180, 'Closed'),
(86, 'Home Loan', 6900000.00, 7.30, '2022-04-05', 240, 'Active'),
(87, 'Personal Loan', 375000.00, 12.25, '2023-05-21', 48, 'Active'),
(88, 'Vehicle Loan', 1250000.00, 8.45, '2021-08-13', 84, 'Closed'),
(89, 'Education Loan', 1100000.00, 7.20, '2022-12-20', 96, 'Active'),
(90, 'Business Loan', 4500000.00, 10.30, '2023-03-27', 180, 'Active'),
(91, 'Home Loan', 7600000.00, 7.15, '2021-05-14', 240, 'Active'),
(92, 'Personal Loan', 650000.00, 11.90, '2022-09-03', 72, 'Closed'),
(93, 'Vehicle Loan', 840000.00, 8.80, '2023-07-11', 84, 'Active'),
(94, 'Education Loan', 1600000.00, 6.85, '2021-10-06', 120, 'Active'),
(95, 'Business Loan', 3700000.00, 10.70, '2022-06-24', 180, 'Closed'),
(96, 'Home Loan', 5400000.00, 7.55, '2023-01-18', 240, 'Active'),
(97, 'Personal Loan', 500000.00, 12.05, '2021-12-29', 60, 'Active'),
(98, 'Vehicle Loan', 980000.00, 8.50, '2022-07-17', 72, 'Closed'),
(99, 'Education Loan', 1450000.00, 7.05, '2023-04-28', 120, 'Active'),
(100, 'Business Loan', 5200000.00, 10.25, '2022-11-12', 180, 'Active');

SELECT DISTINCT(loan_status) FROM loans;
SELECT DISTINCT(loan_type) FROM loans;
SELECT COUNT(*) FROM loans;
SELECT * FROM loans;

SELECT 
	loan_status,
    COUNT(*) AS count_of_loan_status
FROM loans
GROUP BY loan_status
ORDER BY 2 DESC;

SELECT
	loan_type,
    COUNT(*) AS count_of_loan_type
FROM loans
GROUP BY loan_type
ORDER BY 2 DESC;

TRUNCATE TABLE emi_payments;

INSERT INTO emi_payments (loan_id, emi_amount, payment_date, payment_status)
VALUES
(1, 36300.00, '2022-02-15', 'Paid'),
(1, 36300.00, '2022-03-15', 'Paid'),
(1, 36300.00, '2022-04-15', 'Paid'),
(2, 7600.00, '2022-05-10', 'Paid'),
(2, 7600.00, '2022-06-10', 'Paid'),
(2, 7600.00, '2022-07-10', 'Pending'),
(3, 13500.00, '2020-09-20', 'Paid'),
(3, 13500.00, '2020-10-20', 'Paid'),
(3, 13500.00, '2020-11-20', 'Missed'),
(4, 13900.00, '2023-05-12', 'Paid'),
(4, 13900.00, '2023-06-12', 'Paid'),
(4, 13900.00, '2023-07-12', 'Pending'),
(5, 33700.00, '2022-02-05', 'Paid'),
(5, 33700.00, '2022-03-05', 'Paid'),
(5, 33700.00, '2022-04-05', 'Paid'),
(6, 40300.00, '2022-07-18', 'Paid'),
(6, 40300.00, '2022-08-18', 'Paid'),
(6, 40300.00, '2022-09-18', 'Pending'),
(7, 7200.00, '2023-06-14', 'Paid'),
(7, 7200.00, '2023-07-14', 'Missed'),
(7, 7200.00, '2023-08-14', 'Paid'),
(8, 14500.00, '2021-09-09', 'Paid'),
(8, 14500.00, '2021-10-09', 'Paid'),
(8, 14500.00, '2021-11-09', 'Missed'),
(9, 17400.00, '2022-11-25', 'Paid'),
(9, 17400.00, '2022-12-25', 'Paid'),
(9, 17400.00, '2023-01-25', 'Pending'),
(10, 48000.00, '2021-01-30', 'Paid'),
(10, 48000.00, '2021-02-28', 'Paid'),
(10, 48000.00, '2021-03-30', 'Missed'),
(11, 48300.00, '2023-07-15', 'Paid'),
(11, 48300.00, '2023-08-15', 'Paid'),
(11, 48300.00, '2023-09-15', 'Pending'),
(12, 9700.00, '2022-08-21', 'Paid'),
(12, 9700.00, '2022-09-21', 'Paid'),
(12, 9700.00, '2022-10-21', 'Paid'),
(13, 12500.00, '2022-03-12', 'Paid'),
(13, 12500.00, '2022-04-12', 'Missed'),
(13, 12500.00, '2022-05-12', 'Paid'),
(14, 13200.00, '2023-09-10', 'Paid'),
(14, 13200.00, '2023-10-10', 'Paid'),
(14, 13200.00, '2023-11-10', 'Pending'),
(15, 43800.00, '2023-01-05', 'Paid'),
(15, 43800.00, '2023-02-05', 'Paid'),
(15, 43800.00, '2023-03-05', 'Paid'),
(16, 35400.00, '2021-08-22', 'Paid'),
(16, 35400.00, '2021-09-22', 'Paid'),
(16, 35400.00, '2021-10-22', 'Missed'),
(17, 11800.00, '2023-10-19', 'Paid'),
(17, 11800.00, '2023-11-19', 'Pending'),
(17, 11800.00, '2023-12-19', 'Paid'),
(18, 17400.00, '2022-12-08', 'Paid'),
(18, 17400.00, '2023-01-08', 'Paid'),
(18, 17400.00, '2023-02-08', 'Pending'),
(19, 15100.00, '2021-11-14', 'Paid'),
(19, 15100.00, '2021-12-14', 'Paid'),
(19, 15100.00, '2022-01-14', 'Missed'),
(20, 36400.00, '2023-04-30', 'Paid'),
(20, 36400.00, '2023-05-30', 'Paid'),
(20, 36400.00, '2023-06-30', 'Pending'),
(21, 56300.00, '2022-08-17', 'Paid'),
(21, 56300.00, '2022-09-17', 'Paid'),
(21, 56300.00, '2022-10-17', 'Paid'),
(22, 11000.00, '2021-08-11', 'Paid'),
(22, 11000.00, '2021-09-11', 'Missed'),
(22, 11000.00, '2021-10-11', 'Paid'),
(23, 13700.00, '2023-09-22', 'Paid'),
(23, 13700.00, '2023-10-22', 'Pending'),
(23, 13700.00, '2023-11-22', 'Paid'),
(24, 20800.00, '2023-08-15', 'Paid'),
(24, 20800.00, '2023-09-15', 'Paid'),
(24, 20800.00, '2023-10-15', 'Pending'),
(25, 42100.00, '2022-04-19', 'Paid'),
(25, 42100.00, '2022-05-19', 'Paid'),
(25, 42100.00, '2022-06-19', 'Missed'),
(26, 42600.00, '2023-08-13', 'Paid'),
(26, 42600.00, '2023-09-13', 'Paid'),
(26, 42600.00, '2023-10-13', 'Pending'),
(27, 8200.00, '2022-11-25', 'Paid'),
(27, 8200.00, '2022-12-25', 'Paid'),
(27, 8200.00, '2023-01-25', 'Missed'),
(28, 18800.00, '2022-01-17', 'Paid'),
(28, 18800.00, '2022-02-17', 'Paid'),
(28, 18800.00, '2022-03-17', 'Pending'),
(29, 12400.00, '2023-05-08', 'Paid'),
(29, 12400.00, '2023-06-08', 'Paid'),
(29, 12400.00, '2023-07-08', 'Pending'),
(30, 51000.00, '2022-09-29', 'Paid'),
(30, 51000.00, '2022-10-29', 'Paid'),
(30, 51000.00, '2022-11-29', 'Missed'),
(31, 38800.00, '2022-05-12', 'Paid'),
(31, 38800.00, '2022-06-12', 'Paid'),
(31, 38800.00, '2022-07-12', 'Pending'),
(32, 8600.00, '2022-09-26', 'Paid'),
(32, 8600.00, '2022-10-26', 'Paid'),
(32, 8600.00, '2022-11-26', 'Missed'),
(33, 11900.00, '2020-11-19', 'Paid'),
(33, 11900.00, '2020-12-19', 'Paid'),
(33, 11900.00, '2021-01-19', 'Pending'),
(34, 16200.00, '2023-06-05', 'Paid'),
(34, 16200.00, '2023-07-05', 'Paid'),
(34, 16200.00, '2023-08-05', 'Paid'),
(35, 39000.00, '2022-02-23', 'Paid'),
(35, 39000.00, '2022-03-23', 'Pending'),
(35, 39000.00, '2022-04-23', 'Paid'),
(36, 48200.00, '2022-11-14', 'Paid'),
(36, 48200.00, '2022-12-14', 'Paid'),
(36, 48200.00, '2023-01-14', 'Missed'),
(37, 10200.00, '2023-06-18', 'Paid'),
(37, 10200.00, '2023-07-18', 'Paid'),
(37, 10200.00, '2023-08-18', 'Pending'),
(38, 15300.00, '2022-01-09', 'Paid'),
(38, 15300.00, '2022-02-09', 'Paid'),
(38, 15300.00, '2022-03-09', 'Missed'),
(39, 18600.00, '2023-01-11', 'Paid'),
(39, 18600.00, '2023-02-11', 'Paid'),
(39, 18600.00, '2023-03-11', 'Pending'),
(40, 53000.00, '2020-11-30', 'Paid'),
(40, 53000.00, '2020-12-30', 'Paid'),
(40, 53000.00, '2021-01-30', 'Missed'),
(41, 57600.00, '2023-08-22', 'Paid'),
(41, 57600.00, '2023-09-22', 'Paid'),
(41, 57600.00, '2023-10-22', 'Pending'),
(42, 7400.00, '2022-10-16', 'Paid'),
(42, 7400.00, '2022-11-16', 'Paid'),
(42, 7400.00, '2022-12-16', 'Missed'),
(43, 13600.00, '2022-02-27', 'Paid'),
(43, 13600.00, '2022-03-27', 'Pending'),
(43, 13600.00, '2022-04-27', 'Paid'),
(44, 12600.00, '2023-05-19', 'Paid'),
(44, 12600.00, '2023-06-19', 'Paid'),
(44, 12600.00, '2023-07-19', 'Pending'),
(45, 45400.00, '2022-09-28', 'Paid'),
(45, 45400.00, '2022-10-28', 'Paid'),
(45, 45400.00, '2022-11-28', 'Missed'),
(46, 36500.00, '2022-03-05', 'Paid'),
(46, 36500.00, '2022-04-05', 'Paid'),
(46, 36500.00, '2022-05-05', 'Pending'),
(47, 13800.00, '2023-08-14', 'Paid'),
(47, 13800.00, '2023-09-14', 'Paid'),
(47, 13800.00, '2023-10-14', 'Missed'),
(48, 19500.00, '2023-02-20', 'Paid'),
(48, 19500.00, '2023-03-20', 'Pending'),
(48, 19500.00, '2023-04-20', 'Paid'),
(49, 15300.00, '2022-02-18', 'Paid'),
(49, 15300.00, '2022-03-18', 'Paid'),
(49, 15300.00, '2022-04-18', 'Missed'),
(50, 40400.00, '2023-05-25', 'Paid'),
(50, 40400.00, '2023-06-25', 'Paid'),
(50, 40400.00, '2023-07-25', 'Pending'),
(51, 52000.00, '2022-07-13', 'Paid'),
(51, 52000.00, '2022-08-13', 'Paid'),
(51, 52000.00, '2022-09-13', 'Missed'),
(52, 11700.00, '2021-12-22', 'Paid'),
(52, 11700.00, '2022-01-22', 'Pending'),
(52, 11700.00, '2022-02-22', 'Paid'),
(53, 12900.00, '2023-09-08', 'Paid'),
(53, 12900.00, '2023-10-08', 'Paid'),
(53, 12900.00, '2023-11-08', 'Missed'),
(54, 20300.00, '2023-04-19', 'Paid'),
(54, 20300.00, '2023-05-19', 'Pending'),
(54, 20300.00, '2023-06-19', 'Paid'),
(55, 44500.00, '2022-12-15', 'Paid'),
(55, 44500.00, '2023-01-15', 'Paid'),
(55, 44500.00, '2023-02-15', 'Missed'),
(56, 45100.00, '2023-06-11', 'Paid'),
(56, 45100.00, '2023-07-11', 'Paid'),
(56, 45100.00, '2023-08-11', 'Pending'),
(57, 9700.00, '2022-08-30', 'Paid'),
(57, 9700.00, '2022-09-30', 'Paid'),
(57, 9700.00, '2022-10-30', 'Missed'),
(58, 21100.00, '2021-11-25', 'Paid'),
(58, 21100.00, '2021-12-25', 'Pending'),
(58, 21100.00, '2022-01-25', 'Paid'),
(59, 14100.00, '2023-05-07', 'Paid'),
(59, 14100.00, '2023-06-07', 'Paid'),
(59, 14100.00, '2023-07-07', 'Pending'),
(60, 52600.00, '2023-01-14', 'Paid'),
(60, 52600.00, '2023-02-14', 'Paid'),
(60, 52600.00, '2023-03-14', 'Missed'),
(61, 54500.00, '2021-08-20', 'Paid'),
(61, 54500.00, '2021-09-20', 'Pending'),
(61, 54500.00, '2021-10-20', 'Paid'),
(62, 12500.00, '2023-02-02', 'Paid'),
(62, 12500.00, '2023-03-02', 'Paid'),
(62, 12500.00, '2023-04-02', 'Missed'),
(63, 13200.00, '2023-10-11', 'Paid'),
(63, 13200.00, '2023-11-11', 'Pending'),
(63, 13200.00, '2023-12-11', 'Paid'),
(64, 15800.00, '2022-08-06', 'Paid'),
(64, 15800.00, '2022-09-06', 'Paid'),
(64, 15800.00, '2022-10-06', 'Missed'),
(65, 46200.00, '2022-01-24', 'Paid'),
(65, 46200.00, '2022-02-24', 'Pending'),
(65, 46200.00, '2022-03-24', 'Paid'),
(66, 39200.00, '2023-07-20', 'Paid'),
(66, 39200.00, '2023-08-20', 'Paid'),
(66, 39200.00, '2023-09-20', 'Pending'),
(67, 11300.00, '2022-11-15', 'Paid'),
(67, 11300.00, '2022-12-15', 'Missed'),
(67, 11300.00, '2023-01-15', 'Paid'),
(68, 16200.00, '2022-02-07', 'Paid'),
(68, 16200.00, '2022-03-07', 'Pending'),
(68, 16200.00, '2022-04-07', 'Paid'),
(69, 22000.00, '2023-09-26', 'Paid'),
(69, 22000.00, '2023-10-26', 'Paid'),
(69, 22000.00, '2023-11-26', 'Missed'),
(70, 47400.00, '2021-09-29', 'Paid'),
(70, 47400.00, '2021-10-29', 'Pending'),
(70, 47400.00, '2021-11-29', 'Paid'),
(71, 36600.00, '2022-08-11', 'Paid'),
(71, 36600.00, '2022-09-11', 'Paid'),
(71, 36600.00, '2022-10-11', 'Pending'),
(72, 7800.00, '2023-08-15', 'Paid'),
(72, 7800.00, '2023-09-15', 'Missed'),
(72, 7800.00, '2023-10-15', 'Paid'),
(73, 12300.00, '2022-03-21', 'Paid'),
(73, 12300.00, '2022-04-21', 'Pending'),
(73, 12300.00, '2022-05-21', 'Paid'),
(74, 16900.00, '2023-05-18', 'Paid'),
(74, 16900.00, '2023-06-18', 'Paid'),
(74, 16900.00, '2023-07-18', 'Missed'),
(75, 38000.00, '2023-04-24', 'Paid'),
(75, 38000.00, '2023-05-24', 'Pending'),
(75, 38000.00, '2023-06-24', 'Paid'),
(76, 46800.00, '2022-04-30', 'Paid'),
(76, 46800.00, '2022-05-30', 'Paid'),
(76, 46800.00, '2022-06-30', 'Missed'),
(77, 11000.00, '2023-05-06', 'Paid'),
(77, 11000.00, '2023-06-06', 'Pending'),
(77, 11000.00, '2023-07-06', 'Paid'),
(78, 18600.00, '2023-06-09', 'Paid'),
(78, 18600.00, '2023-07-09', 'Paid'),
(78, 18600.00, '2023-08-09', 'Missed'),
(79, 15900.00, '2022-03-18', 'Paid'),
(79, 15900.00, '2022-04-18', 'Pending'),
(79, 15900.00, '2022-05-18', 'Paid'),
(80, 51500.00, '2023-02-26', 'Paid'),
(80, 51500.00, '2023-03-26', 'Paid'),
(80, 51500.00, '2023-04-26', 'Pending'),
(81, 43000.00, '2023-07-12', 'Paid'),
(81, 43000.00, '2023-08-12', 'Missed'),
(81, 43000.00, '2023-09-12', 'Paid'),
(82, 10800.00, '2022-05-03', 'Paid'),
(82, 10800.00, '2022-06-03', 'Pending'),
(82, 10800.00, '2022-07-03', 'Paid'),
(83, 14200.00, '2023-01-10', 'Paid'),
(83, 14200.00, '2023-02-10', 'Paid'),
(83, 14200.00, '2023-03-10', 'Missed'),
(84, 15400.00, '2023-08-16', 'Paid'),
(84, 15400.00, '2023-09-16', 'Pending'),
(84, 15400.00, '2023-10-16', 'Paid'),
(85, 42600.00, '2022-02-28', 'Paid'),
(85, 42600.00, '2022-03-28', 'Missed'),
(85, 42600.00, '2022-04-28', 'Paid'),
(86, 40100.00, '2022-10-05', 'Paid'),
(86, 40100.00, '2022-11-05', 'Pending'),
(86, 40100.00, '2022-12-05', 'Paid'),
(87, 9200.00, '2023-09-21', 'Paid'),
(87, 9200.00, '2023-10-21', 'Missed'),
(87, 9200.00, '2023-11-21', 'Paid'),
(88, 23200.00, '2022-05-13', 'Paid'),
(88, 23200.00, '2022-06-13', 'Pending'),
(88, 23200.00, '2022-07-13', 'Paid'),
(89, 12900.00, '2023-06-20', 'Paid'),
(89, 12900.00, '2023-07-20', 'Paid'),
(89, 12900.00, '2023-08-20', 'Missed'),
(90, 55200.00, '2023-06-27', 'Paid'),
(90, 55200.00, '2023-07-27', 'Pending'),
(90, 55200.00, '2023-08-27', 'Paid'),
(91, 59000.00, '2021-08-14', 'Paid'),
(91, 59000.00, '2021-09-14', 'Missed'),
(91, 59000.00, '2021-10-14', 'Paid'),
(92, 13200.00, '2023-03-03', 'Paid'),
(92, 13200.00, '2023-04-03', 'Pending'),
(92, 13200.00, '2023-05-03', 'Paid'),
(93, 12500.00, '2023-10-11', 'Paid'),
(93, 12500.00, '2023-11-11', 'Missed'),
(93, 12500.00, '2023-12-11', 'Paid'),
(94, 14800.00, '2022-08-06', 'Paid'),
(94, 14800.00, '2022-09-06', 'Pending'),
(94, 14800.00, '2022-10-06', 'Paid'),
(95, 43800.00, '2022-09-24', 'Paid'),
(95, 43800.00, '2022-10-24', 'Missed'),
(95, 43800.00, '2022-11-24', 'Paid'),
(96, 41800.00, '2023-07-18', 'Paid'),
(96, 41800.00, '2023-08-18', 'Pending'),
(96, 41800.00, '2023-09-18', 'Paid'),
(97, 11600.00, '2022-05-29', 'Paid'),
(97, 11600.00, '2022-06-29', 'Missed'),
(97, 11600.00, '2022-07-29', 'Paid'),
(98, 17500.00, '2022-10-17', 'Paid'),
(98, 17500.00, '2022-11-17', 'Pending'),
(98, 17500.00, '2022-12-17', 'Paid'),
(99, 14300.00, '2023-07-28', 'Paid'),
(99, 14300.00, '2023-08-28', 'Missed'),
(99, 14300.00, '2023-09-28', 'Paid'),
(100, 58500.00, '2023-02-12', 'Paid'),
(100, 58500.00, '2023-03-12', 'Pending'),
(100, 58500.00, '2023-04-12', 'Paid');

SELECT DISTINCT(payment_status) FROM emi_payments;
SELECT COUNT(*) FROM emi_payments;
SELECT * FROM emi_payments;

SELECT
	payment_status,
    COUNT(*) AS count_of_payment_status
FROM emi_payments
GROUP BY payment_status
ORDER BY 2 DESC;

TRUNCATE TABLE fraud_alerts;

INSERT INTO fraud_alerts (transaction_id, alert_type, risk_level, alert_date, alert_status)
VALUES
(11, 'Multiple Failed Transactions', 'Medium', '2027-01-18 10:30:00', 'Investigating'),
(18, 'Unusual Withdrawal Amount', 'Low', '2027-01-21 15:45:00', 'Resolved'),
(27, 'Suspicious Transfer Activity', 'High', '2027-01-25 12:20:00', 'Open'),
(35, 'Large Transaction Detected', 'Medium', '2027-02-02 09:15:00', 'Resolved'),
(42, 'Multiple Transactions In Short Time', 'High', '2027-02-05 18:10:00', 'Investigating'),
(56, 'Unusual Account Behaviour', 'Medium', '2027-02-09 11:35:00', 'Open'),
(63, 'High Value Transfer', 'High', '2027-02-13 14:25:00', 'Investigating'),
(74, 'Repeated Withdrawal Pattern', 'Low', '2027-02-17 16:40:00', 'Resolved'),
(89, 'Suspicious Login Activity', 'Medium', '2027-02-22 10:50:00', 'Open'),
(96, 'Large Cash Withdrawal', 'High', '2027-02-26 17:15:00', 'Investigating'),
(105, 'Unusual Transaction Location', 'Medium', '2027-03-01 13:30:00', 'Resolved'),
(118, 'Multiple Transfer Attempts', 'High', '2027-03-06 09:45:00', 'Open'),
(126, 'Abnormal Spending Pattern', 'Low', '2027-03-10 15:20:00', 'Resolved'),
(137, 'Suspicious Beneficiary Activity', 'High', '2027-03-15 12:55:00', 'Investigating'),
(149, 'Large Transaction Detected', 'Medium', '2027-03-19 11:10:00', 'Open'),
(158, 'Multiple Failed Transactions', 'Medium', '2027-03-23 18:25:00', 'Resolved'),
(172, 'Unusual Withdrawal Amount', 'Low', '2027-03-27 14:40:00', 'Resolved'),
(183, 'Suspicious Transfer Activity', 'High', '2027-04-02 10:15:00', 'Investigating'),
(195, 'High Value Transfer', 'High', '2027-04-07 16:50:00', 'Open'),
(207, 'Unusual Account Behaviour', 'Medium', '2027-04-11 09:35:00', 'Resolved'),
(218, 'Multiple Transactions In Short Time', 'High', '2027-04-15 13:20:00', 'Investigating'),
(229, 'Large Cash Withdrawal', 'Medium', '2027-04-19 17:45:00', 'Open'),
(241, 'Suspicious Login Activity', 'Low', '2027-04-24 10:25:00', 'Resolved'),
(255, 'Suspicious Beneficiary Activity', 'High', '2027-04-29 12:40:00', 'Investigating'),
(266, 'Unusual Transaction Location', 'Medium', '2027-05-03 15:10:00', 'Resolved'),
(279, 'Multiple Failed Transactions', 'High', '2027-05-08 18:30:00', 'Open'),
(290, 'Large Transaction Detected', 'Medium', '2027-05-12 09:20:00', 'Resolved'),
(304, 'Repeated Withdrawal Pattern', 'Low', '2027-05-17 14:35:00', 'Resolved'),
(316, 'Suspicious Transfer Activity', 'High', '2027-05-21 11:50:00', 'Investigating'),
(329, 'High Value Transfer', 'High', '2027-05-26 16:15:00', 'Open'),
(340, 'Unusual Account Behaviour', 'Medium', '2027-05-30 10:40:00', 'Resolved'),
(352, 'Multiple Transactions In Short Time', 'Medium', '2027-06-04 13:25:00', 'Investigating'),
(365, 'Suspicious Beneficiary Activity', 'High', '2027-06-09 17:05:00', 'Open'),
(377, 'Large Cash Withdrawal', 'Medium', '2027-06-13 12:15:00', 'Resolved'),
(389, 'Multiple Failed Transactions', 'Low', '2027-06-18 09:30:00', 'Resolved'),
(402, 'Unusual Transaction Location', 'High', '2027-06-22 15:45:00', 'Investigating'),
(414, 'Suspicious Transfer Activity', 'Medium', '2027-06-27 11:20:00', 'Open'),
(426, 'High Value Transfer', 'High', '2027-07-01 16:35:00', 'Investigating'),
(438, 'Unusual Withdrawal Amount', 'Medium', '2027-07-06 10:10:00', 'Resolved'),
(450, 'Suspicious Login Activity', 'Low', '2027-07-10 14:50:00', 'Resolved'),
(463, 'Large Transaction Detected', 'Medium', '2027-07-15 18:20:00', 'Open'),
(475, 'Multiple Transactions In Short Time', 'High', '2027-07-19 12:30:00', 'Investigating'),
(487, 'Suspicious Beneficiary Activity', 'Medium', '2027-07-24 09:55:00', 'Resolved'),
(499, 'Repeated Withdrawal Pattern', 'Low', '2027-07-28 15:25:00', 'Resolved'),
(512, 'High Value Transfer', 'High', '2027-08-02 11:40:00', 'Open'),
(524, 'Unusual Account Behaviour', 'Medium', '2027-08-06 16:10:00', 'Investigating'),
(536, 'Multiple Failed Transactions', 'High', '2027-08-11 10:35:00', 'Open'),
(548, 'Suspicious Transfer Activity', 'Medium', '2027-08-15 13:50:00', 'Resolved'),
(560, 'Large Cash Withdrawal', 'High', '2027-08-20 17:25:00', 'Investigating'),
(573, 'Unusual Transaction Location', 'Medium', '2027-08-24 09:40:00', 'Resolved'),
(585, 'Multiple Failed Transactions', 'High', '2027-08-29 14:15:00', 'Open'),
(597, 'Suspicious Beneficiary Activity', 'Medium', '2027-09-02 18:35:00', 'Investigating'),
(610, 'Large Transaction Detected', 'Low', '2027-09-07 11:25:00', 'Resolved'),
(622, 'High Value Transfer', 'High', '2027-09-11 16:45:00', 'Open'),
(634, 'Unusual Withdrawal Amount', 'Medium', '2027-09-16 10:20:00', 'Investigating'),
(45, 'Multiple Transactions In Short Time', 'High', '2027-09-20 13:55:00', 'Resolved'),
(78, 'Suspicious Login Activity', 'Low', '2027-09-25 17:30:00', 'Resolved'),
(112, 'Suspicious Transfer Activity', 'High', '2027-09-29 09:15:00', 'Investigating'),
(146, 'Repeated Withdrawal Pattern', 'Medium', '2027-10-04 14:40:00', 'Open'),
(169, 'Unusual Account Behaviour', 'Medium', '2027-10-08 18:05:00', 'Resolved'),
(214, 'Large Cash Withdrawal', 'High', '2027-10-13 12:35:00', 'Investigating'),
(251, 'Multiple Failed Transactions', 'Medium', '2027-10-17 16:20:00', 'Open'),
(288, 'High Value Transfer', 'High', '2027-10-22 10:45:00', 'Investigating'),
(321, 'Suspicious Beneficiary Activity', 'Medium', '2027-10-26 15:30:00', 'Resolved'),
(356, 'Unusual Transaction Location', 'Low', '2027-11-01 09:50:00', 'Resolved'),
(391, 'Large Transaction Detected', 'Medium', '2027-11-05 13:25:00', 'Open'),
(427, 'Multiple Transactions In Short Time', 'High', '2027-11-10 17:10:00', 'Investigating'),
(463, 'Suspicious Transfer Activity', 'Medium', '2027-11-14 11:40:00', 'Resolved'),
(498, 'High Value Transfer', 'High', '2027-11-19 15:55:00', 'Open'),
(533, 'Unusual Withdrawal Amount', 'Medium', '2027-11-23 10:30:00', 'Resolved'),
(568, 'Suspicious Login Activity', 'Low', '2027-11-28 14:45:00', 'Resolved'),
(603, 'Large Cash Withdrawal', 'High', '2027-12-02 18:15:00', 'Investigating'),
(29, 'Multiple Failed Transactions', 'Medium', '2027-12-07 12:20:00', 'Open'),
(64, 'Suspicious Beneficiary Activity', 'High', '2027-12-11 16:35:00', 'Investigating'),
(99, 'Unusual Account Behaviour', 'Medium', '2027-12-16 09:25:00', 'Resolved'),
(134, 'High Value Transfer', 'High', '2027-12-20 13:50:00', 'Open'),
(169, 'Unusual Transaction Location', 'Low', '2027-12-25 17:05:00', 'Resolved'),
(204, 'Multiple Transactions In Short Time', 'Medium', '2027-12-29 11:15:00', 'Investigating'),
(239, 'Large Transaction Detected', 'High', '2028-01-03 15:40:00', 'Open'),
(274, 'Suspicious Transfer Activity', 'Medium', '2028-01-07 10:10:00', 'Resolved'),
(309, 'Repeated Withdrawal Pattern', 'Low', '2028-01-12 14:30:00', 'Resolved'),
(344, 'Multiple Failed Transactions', 'High', '2028-01-16 18:25:00', 'Investigating'),
(379, 'Suspicious Beneficiary Activity', 'Medium', '2028-01-21 12:45:00', 'Open'),
(414, 'High Value Transfer', 'High', '2028-01-25 16:55:00', 'Investigating'),
(449, 'Unusual Withdrawal Amount', 'Medium', '2028-01-30 09:35:00', 'Resolved'),
(484, 'Suspicious Login Activity', 'Low', '2028-02-03 13:15:00', 'Resolved'),
(519, 'Large Cash Withdrawal', 'Medium', '2028-02-08 17:40:00', 'Open'),
(554, 'Multiple Failed Transactions', 'High', '2028-02-12 11:05:00', 'Investigating'),
(589, 'Unusual Account Behaviour', 'Medium', '2028-02-17 15:25:00', 'Resolved'),
(624, 'Suspicious Transfer Activity', 'High', '2028-02-21 10:50:00', 'Open'),
(57, 'High Value Transfer', 'Medium', '2028-02-26 14:10:00', 'Resolved'),
(93, 'Unusual Transaction Location', 'Low', '2028-03-01 18:30:00', 'Resolved'),
(128, 'Large Transaction Detected', 'Medium', '2028-03-06 12:00:00', 'Investigating'),
(163, 'Multiple Transactions In Short Time', 'High', '2028-03-10 16:20:00', 'Open'),
(198, 'Suspicious Beneficiary Activity', 'Medium', '2028-03-15 09:45:00', 'Resolved'),
(233, 'Repeated Withdrawal Pattern', 'Low', '2028-03-19 13:35:00', 'Resolved'),
(268, 'Multiple Failed Transactions', 'High', '2028-03-24 17:50:00', 'Investigating'),
(303, 'Suspicious Transfer Activity', 'Medium', '2028-03-28 11:30:00', 'Open'),
(338, 'High Value Transfer', 'High', '2028-04-02 15:15:00', 'Investigating');

SELECT DISTINCT(alert_status) FROM fraud_alerts;
SELECT DISTINCT(alert_type) FROM fraud_alerts;
SELECT DISTINCT(risk_level) FROM fraud_alerts;
SELECT COUNT(*) FROM fraud_alerts;
SELECT * FROM fraud_alerts;

SELECT 
	alert_status,
    COUNT(*) AS count_of_alert_status
FROM fraud_alerts
GROUP BY alert_status
ORDER BY 2 DESC;

SELECT 
	alert_type,
    COUNT(*) AS count_of_alert_type
FROM fraud_alerts
GROUP BY alert_type
ORDER BY 2 DESC;

SELECT 
	risk_level,
    COUNT(*) AS count_of_risk_level
FROM fraud_alerts
GROUP BY risk_level
ORDER BY 2 DESC;

SELECT * FROM account_types;
SELECT * FROM accounts;
SELECT * FROM beneficiaries;
SELECT * FROM branches;
SELECT * FROM cards;
SELECT * FROM customers;
SELECT * FROM emi_payments;
SELECT * FROM employees;
SELECT * FROM fraud_alerts;
SELECT * FROM loans;
SELECT * FROM transactions;


-- Data Analysis

-- Display all active, inactive and blocked customers

SELECT * FROM customers
WHERE customer_status = 'Active';

SELECT * FROM customers
WHERE customer_status = 'Inactive';

SELECT * FROM customers
WHERE customer_status = 'Blocked';

-- Display all customers from Delhi

SELECT * FROM customers
WHERE address = 'Delhi, Delhi';

-- Display accounts with balance between 20,000 and 50,000

SELECT * FROM accounts
WHERE balance BETWEEN 20000 AND 50000;

-- Display the latest 10 transactions

SELECT * FROM transactions
ORDER BY transaction_date 
LIMIT 10;

-- Display all credit and debit cards

SELECT * FROM cards
WHERE card_type = 'Credit';

SELECT * FROM cards
WHERE card_type = 'Debit';

-- Display all missed and pending Equated Monthly Installment (EMI) payments

SELECT * FROM emi_payments
WHERE payment_status = 'Missed';

SELECT * FROM emi_payments
WHERE payment_status = 'Pending';

-- Count the total number of customers in each address

SELECT
	address,
    COUNT(*) AS total_customers
FROM customers
GROUP BY address;

-- Find the total balance maintained in the bank

SELECT
	SUM(balance) AS total_balance
FROM accounts;

-- Find the highest and lowest account balance in the bank

SELECT
	MAX(balance) AS highest_account_balance,
    MIN(balance) AS lowest_account_balance
FROM accounts;

-- Find the average account balance across the bank

SELECT
	AVG(balance) AS average_balance
FROM accounts;

-- Find the total loan amount issued

SELECT 
	SUM(loan_amount) AS total_loan_amount_issued
FROM loans;

-- Count the number of employees in each branch

SELECT
	branch_id,
    COUNT(*) AS total_employees
FROM employees
GROUP BY branch_id;

-- Count the number of customers in each city

SELECT
	address,
    COUNT(*)
FROM customers
GROUP BY address;

-- Count the number of transactions per transaction type

SELECT 
	transaction_type, 
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY transaction_type;

-- Display branches that have more than 10 accounts

SELECT
	branch_id,
	COUNT(*) AS total_accounts
FROM accounts
GROUP BY branch_id
HAVING total_accounts > 10;

-- Display customers that have more than 1 account

SELECT 
	customer_id,
    COUNT(*) AS total_accounts
FROM accounts
GROUP BY customer_id
HAVING total_accounts > 1;

-- Display customer information alongside account details 

SELECT
	c.customer_id,
    c.first_name,
    c.last_name,
    a.account_id,
    a.balance
FROM customers AS c
JOIN accounts AS a
ON c.customer_id = a.customer_id;

-- Display customer information alongside branch details

SELECT
	c.customer_id,
    c.first_name,
    c.last_name,
    b.branch_name
FROM customers AS c
JOIN accounts AS a
ON c.customer_id = a.customer_id
JOIN branches AS b
ON a.branch_id = b.branch_id;

-- Display fraud alert information alongside transaction details

SELECT
	fa.alert_id,
    fa.alert_type,
    t.transaction_id,
    t.amount
FROM fraud_alerts AS fa
JOIN transactions AS t
ON fa.transaction_id = t.transaction_id;

-- Generate a complete customer profile report

SELECT 
	c.customer_id,
    c.first_name,
    c.last_name,
    a.account_id,
    a.balance,
    b.branch_name,
    cd.card_type,
    l.loan_amount
FROM customers AS c
LEFT JOIN accounts AS a 
ON c.customer_id = a.customer_id
LEFT JOIN branches AS b
ON a.branch_id = b.branch_id
LEFT JOIN cards AS cd
ON a.account_id = cd.account_id
LEFT JOIN loans AS l
ON c.customer_id = l.customer_id;

-- Display all customers and their total account balance

SELECT
	c.customer_id,
    c.first_name,
    SUM(a.balance) AS total_balance
FROM customers AS c
JOIN accounts AS a
ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.first_name;

-- Find the customers that don't have loans

SELECT
	c.customer_id,
    c.first_name
FROM customers AS c
LEFT JOIN loans AS l
ON c.customer_id = l.customer_id
WHERE l.loan_id IS NULL;

-- Display customer information alongside fraud alert details

SELECT 
	c.first_name,
    t.transaction_id,
    fa.alert_type
FROM customers AS c
JOIN accounts AS a 
ON c.customer_id = a.customer_id
JOIN transactions AS t
ON a.account_id = t.account_id
JOIN fraud_alerts AS fa
ON t.transaction_id = fa.transaction_id;

-- Find accounts that have a balance above the average

SELECT
	account_id,
    balance
FROM accounts
WHERE balance > (SELECT AVG(balance) FROM accounts);

-- Find accounts that have no transactions

SELECT account_id FROM accounts 
WHERE account_id NOT IN (SELECT account_id FROM transactions);

-- Find the second highest account balance

SELECT
	MAX(balance)
FROM accounts
WHERE balance < (SELECT MAX(balance) FROM accounts);

-- Find accounts that have a balance greater than the average of their branch

SELECT
	a.account_id,
    a.branch_id,
    a.balance
FROM accounts AS a
WHERE a.balance > (SELECT AVG(balance)
					FROM accounts 
                    WHERE branch_id = a.branch_id);

-- Find customers that have both a loan and a credit card

SELECT
	c.customer_id,
    c.first_name,
    c.last_name
FROM customers AS c
WHERE 
	c.customer_id IN (SELECT customer_id FROM loans)
    AND 
    c.customer_id IN (SELECT a.customer_id
						FROM accounts AS a
						JOIN cards AS cd
                        ON a.account_id = cd.account_id
                        WHERE cd.card_type = 'Credit');
                        
-- Categorise accounts as low, medium and high balance

SELECT 
	account_id,
    balance,
    CASE 
		WHEN balance < 25000 THEN 'Low Balance'
        WHEN balance BETWEEN 25000 AND 75000 THEN 'Medium Balance'
        ELSE 'High Balance'
	END AS balance_category
FROM accounts;

-- Categorise loans as small, medium or large sized

SELECT
	loan_id,
    loan_amount,
    CASE 
		WHEN loan_amount < 100000 THEN 'Small Loan'
        WHEN loan_amount BETWEEN 100000 AND 500000 THEN 'Medium Loan'
        ELSE 'Large Loan'
	END AS loan_category
FROM loans;

-- Categorise EMI payments based on pending, overdue or on-time status

SELECT
	emi_id,
    payment_date,
    CASE
		WHEN 
			payment_date < CURDATE() 
			AND
            payment_status = 'Pending'
            THEN 'Overdue'
		ELSE 'On-Time'
	END AS emi_status
FROM emi_payments;


-- Common Table Expressions Implementation

-- Rank of customers by total account balance

WITH customer_balance 
AS
	(SELECT 	
		c.customer_id,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		SUM(a.balance) AS total_balance
	FROM customers AS c
	JOIN accounts AS a
	ON c.customer_id = a.customer_id
	GROUP BY c.customer_id, c.first_name, c.last_name)
SELECT 
	customer_id,
    customer_name, 
    total_balance,
    RANK() OVER(ORDER BY total_balance DESC) AS customer_rank
FROM customer_balance;

-- Highest balance account per branch

WITH ranked_accounts
AS
	(SELECT 
		a.account_id,
		a.branch_id,
		a.account_number,
		a.balance,
		ROW_NUMBER() OVER(PARTITION BY a.branch_id ORDER BY a.balance DESC) AS account_rank
	FROM accounts AS a)
SELECT * 
FROM ranked_accounts
WHERE account_rank = 1;

-- Transactions per month

WITH monthly_transactions 
AS
	(SELECT
		YEAR(transaction_date) AS transaction_year,
		MONTH(transaction_date) AS transaction_month,
		COUNT(transaction_id) AS total_transactions,
		SUM(amount) AS total_amount
	FROM transactions
	GROUP BY YEAR(transaction_date), MONTH(transaction_date))
SELECT *
FROM monthly_transactions
ORDER BY transaction_year, transaction_month;

-- Customer loan exposure analysis

WITH customer_loans
AS
	(SELECT 
		c.customer_id,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		COUNT(l.loan_id) AS total_loans,
		SUM(l.loan_amount) AS total_loan_amount
	FROM customers AS c
	JOIN loans AS l
	ON c.customer_id - l.customer_id
	GROUP BY c.customer_id, c.first_name, c.last_name)
SELECT
	customer_name,
    total_loans,
    total_loan_amount,
    CASE
		WHEN total_loan_amount > 5000000 THEN 'High Exposure'
        WHEN total_loan_amount > 1000000 THEN 'Medium Exposure'
        ELSE 'Low Exposure'
	END AS risk_category
FROM customer_loans;

-- Fraud risk transaction analysis

WITH fraud_analysis 
AS
	(SELECT 	
		t.account_id,
		COUNT(fa.alert_id) AS fraud_alert_count,
		MAX(fa.risk_level) AS highest_risk
	FROM transactions AS t
	LEFT JOIN fraud_alerts AS fa
	ON t.transaction_id = fa.transaction_id
	GROUP BY t.account_id)
SELECT 
	account_id,
    fraud_alert_count,
    CASE
		WHEN fraud_alert_count >= 3 THEN 'High Risk'
        WHEN fraud_alert_count >= 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
	END AS risk_status
FROM fraud_analysis;


-- View Implementation

-- Active Customers

DROP VIEW IF EXISTS vw_active_customers;
CREATE VIEW vw_active_customers
AS
	(SELECT 
		customer_id,
		CONCAT(first_name, ' ', last_name) AS customer_name,
		phone, 
		email,
		created_at
	FROM customers
	WHERE customer_status = 'Active');
    
SELECT * FROM vw_active_customers;

-- Branch Performance

DROP VIEW IF EXISTS vw_branch_performance;
CREATE VIEW vw_branch_performance
AS
	(SELECT 
		b.branch_id,
		b.branch_name,
		COUNT(a.account_id) AS total_accounts,
		SUM(a.balance) AS total_deposit,
		AVG(a.balance) AS average_balance
	FROM branches AS b
	LEFT JOIN accounts AS a
	ON b.branch_id = a.branch_id
	GROUP BY b.branch_id, b.branch_name);
    
SELECT * FROM vw_branch_performance;

-- Customer Account Summary

DROP VIEW IF EXISTS vw_customer_account_summary;
CREATE VIEW vw_customer_account_summary
AS
	(SELECT 
		c.customer_id,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		COUNT(a.account_id) AS total_accounts,
		SUM(a.balance) AS total_balance,
		COUNT(t.transaction_id) AS total_transactions
	FROM customers AS c
	LEFT JOIN accounts AS a
	ON c.customer_id = a.customer_id
	LEFT JOIN transactions AS t
	ON a.account_id = t.account_id
	GROUP BY c.customer_id, c.first_name, c.last_name);

SELECT * FROM vw_customer_account_summary;

-- EMI Defaulters 

DROP VIEW IF EXISTS vw_emi_defaulters;
CREATE VIEW vw_emi_defaulters
AS
	(SELECT 
		c.customer_id,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		l.loan_id,
		l.loan_type,
		ep.emi_amount,
		ep.payment_date,
		ep.payment_status
	FROM customers AS c
	JOIN loans AS l
	ON c.customer_id = l.customer_id
	JOIN emi_payments AS ep
	ON l.loan_id = ep.loan_id
	WHERE ep.payment_status = 'Pending');

SELECT * FROM vw_emi_defaulters;

-- Transaction Dashboard

DROP TABLE IF EXISTS vw_transaction_dashboard;
CREATE VIEW vw_transaction_dashboard
AS
	(SELECT 
		t.transaction_id,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		a.account_number,
		t.transaction_type,
		t.amount,
		t.transaction_date,
		t.transaction_status,
		COALESCE(fa.risk_level, 'No Alert') AS fraud_status
	FROM transactions AS t
	JOIN accounts AS a
	ON t.account_id = a.account_id
	JOIN customers AS c
	ON a.customer_id = c.customer_id
	LEFT JOIN fraud_alerts AS fa
	ON t.transaction_id = fa.transaction_id);

SELECT * FROM vw_transaction_dashboard;


-- Function Implementation

-- Customer Age

DROP FUNCTION IF EXISTS fn_calculate_customer_age;
DELIMITER $$
CREATE FUNCTION fn_calculate_customer_age (p_date_of_birth DATE)
RETURNS INT
DETERMINISTIC 
BEGIN
	DECLARE customer_age INT;
    
    SET customer_age = TIMESTAMPDIFF(YEAR, p_date_of_birth, CURDATE());
    
    RETURN customer_age;
END $$
DELIMITER ; 

SELECT
	first_name,
    last_name,
    fn_calculate_customer_age(date_of_birth) AS age
FROM customers;

-- Account Duration

DROP FUNCTION IF EXISTS fn_calculate_account_duration;
DELIMITER $$
CREATE FUNCTION fn_calculate_account_duration (p_open_date DATE)
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE years_open INT;
    
    SET years_open = TIMESTAMPDIFF(YEAR, p_open_date, CURDATE());
    
    RETURN years_open;
END $$
DELIMITER ;

SELECT 
	account_number,
    fn_calculate_account_duration(open_date) AS account_duration_in_years
FROM accounts;

-- Loan Interest Amount

DROP FUNCTION IF EXISTS fn_calculate_loan_interest;
DELIMITER $$
CREATE FUNCTION fn_calculate_loan_interest (p_amount DECIMAL(15, 2),
											p_rate DECIMAL(5, 2),
											p_years INT)
RETURNS DECIMAL(15, 2)
DETERMINISTIC 
BEGIN
	DECLARE interest DECIMAL(15, 2);
    
    SET interest = (p_amount * p_rate * p_years) / 100;
    
    RETURN interest;
END $$
DELIMITER ; 

SELECT
	loan_id,
    loan_amount,
    fn_calculate_loan_interest(loan_amount, interest_rate, 5) AS estimated_interest
FROM loans;

-- Account Balance Categorisation

DROP FUNCTION IF EXISTS fn_balance_category;
DELIMITER $$
CREATE FUNCTION fn_balance_category (p_balance DECIMAL(15, 2))
RETURNS VARCHAR(20)
DETERMINISTIC 
BEGIN
	DECLARE category VARCHAR(20);
    
    IF p_balance >= 1000000 THEN 
		SET category = 'Premium';
	
    ELSEIF p_balance >= 500000 THEN 
		SET category = 'High Value';
	
    ELSEIF p_balance >= 100000 THEN
		SET category = 'Standard';
	
    ELSE 
		SET category = 'Basic';
	
    END IF;
    
    RETURN category;
END $$
DELIMITER ; 

SELECT
	account_id,
    balance,
    fn_balance_category(balance) AS balance_category
FROM accounts;

-- Customer Risk Score

DROP FUNCTION IF EXISTS fn_customer_risk_score;
DELIMITER $$
CREATE FUNCTION fn_customer_risk_score (p_customer_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC 
BEGIN
	DECLARE risk VARCHAR(20);
    DECLARE loan_count INT;
    DECLARE fraud_count INT;
    
    SELECT COUNT(*) INTO loan_count
    FROM loans
    WHERE customer_id = p_customer_id;
    
    SELECT COUNT(*) INTO fraud_count 
    FROM accounts AS a 
    JOIN transactions AS t
    ON a.account_id = t.account_id
    JOIN fraud_alerts AS fa
    ON t.transaction_id = fa.transaction_id
    WHERE a.customer_id = p_customer_id;
    
    IF fraud_count > 2 THEN
		SET risk = 'High';
	
    ELSEIF loan_count > 2 THEN
		SET risk = 'Medium';
        
	ELSE 
		SET risk = 'Low';
	
    END IF; 
    
    RETURN risk;
END $$
DELIMITER ; 

SELECT
	customer_id,
    fn_customer_risk_score(customer_id) AS customer_risk_score
FROM customers; 


-- Trigger Implementation

CREATE TABLE transaction_audit(
							audit_id INT PRIMARY KEY AUTO_INCREMENT,
                            transaction_id INT,
                            account_id INT,
                            amount DECIMAL(15, 2),
                            action_type VARCHAR(50),
                            action_date DATETIME DEFAULT CURRENT_TIMESTAMP);

-- Prevent Negative Balance

DROP TRIGGER IF EXISTS trg_prevent_negative_balance;
DELIMITER $$
CREATE TRIGGER trg_prevent_negative_balance
BEFORE UPDATE ON accounts
FOR EACH ROW
BEGIN
	IF NEW.balance < 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient account balance';
	END IF;
END $$
DELIMITER ; 

SELECT 
	account_id, 
    balance
FROM accounts
LIMIT 5;

UPDATE accounts
SET balance = 90000.00
WHERE account_id = 1;

UPDATE accounts
SET balance = -9000.00
WHERE account_id = 1;

SELECT 
	balance
FROM accounts
WHERE account_id = 1;

-- Record Transactions

DROP TRIGGER IF EXISTS trg_transactions_audit_log;
DELIMITER $$
CREATE TRIGGER trg_transactions_audit_log
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
	INSERT INTO transaction_audit (transaction_id, account_id, amount, action_type)
    VALUES (NEW.transaction_id, NEW.account_id, NEW.amount, 'Transaction Created');
END $$
DELIMITER ;

DESCRIBE transaction_audit;

SELECT account_id
FROM accounts
LIMIT 5;

INSERT INTO transactions (account_id, amount)
VALUES (1, 50.00);

SELECT *
FROM transaction_audit
ORDER BY transaction_id DESC
LIMIT 5;

START TRANSACTION;
INSERT INTO transactions (account_id, amount)
VALUES (1, 25.00);
SELECT *
FROM transaction_audit
ORDER BY transaction_id DESC
LIMIT 1;
ROLLBACK;

INSERT INTO transactions (account_id, amount)
VALUES (1, 100.00), (1, 200.00), (1, 300.00);

SELECT * 
FROM transaction_audit
ORDER BY transaction_id DESC
LIMIT 3;

-- Prevent Negative Transaction Amounts

DROP TRIGGER IF EXISTS trg_prevent_negative_transaction_amount;
DELIMITER $$
CREATE TRIGGER trg_prevent_negative_transaction_amount
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
	IF NEW.amount <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction amount must be positive';
	END IF;
END $$
DELIMITER ; 

SHOW TRIGGERS;

SHOW TRIGGERS
WHERE `Trigger` = 'trg_prevent_negative_transaction_amount';

SELECT account_id
FROM accounts
LIMIT 5;

INSERT INTO transactions (account_id, amount)
VALUES (2, 100.00);

SELECT *
FROM transactions
ORDER BY transaction_id DESC
LIMIT 5;

INSERT INTO transactions (account_id, amount)
VALUES (1, 0);

INSERT INTO transactions (account_id, amount)
VALUES (1, -50.00);

-- Fraud Alert for Large Transactions

DROP TRIGGER IF EXISTS trg_large_transaction_fraud_check;
DELIMITER $$
CREATE TRIGGER trg_large_transaction_fraud_check
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
	IF NEW.amount > 500000 THEN
		INSERT INTO fraud_alerts (transaction_id, alert_type, risk_level)
        VALUES (NEW.transaction_id, 'Large Transaction Detected', 'High');
	END IF;
END $$
DELIMITER ; 

INSERT INTO transactions (account_id, amount)
VALUES (1, 1000.00);

SELECT *
FROM fraud_alerts
ORDER BY transaction_id DESC
LIMIT 5;

INSERT INTO transactions (account_id, amount)
VALUES (1, 600000.00);

SELECT *
FROM fraud_alerts
ORDER BY transaction_id DESC
LIMIT 5;

SELECT *
FROM transactions
WHERE amount > 500000
ORDER BY transaction_id DESC;

SELECT *
FROM fraud_alerts
WHERE alert_type = 'Large Transaction Detected';

-- Prevent Closure of Account with Balance

DROP TRIGGER IF EXISTS trg_prevent_closing_positive_balance;
DELIMITER $$
CREATE TRIGGER trg_prevent_closing_positive_balance
BEFORE UPDATE ON accounts
FOR EACH ROW
BEGIN
	IF NEW.account_status = 'Closed' AND NEW.balance > 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account cannot be closed with a remaining balance';
	END IF;
END $$
DELIMITER ; 

SHOW TRIGGERS;

SHOW TRIGGERS 
WHERE `Trigger` = 'trg_prevent_closing_positive_balance';

SELECT 
	account_id, 
	account_status, 
	balance
FROM accounts
LIMIT 10;

UPDATE accounts
SET account_status = 'Closed' 
WHERE account_id = 5;

SELECT
	account_status,
    balance
FROM accounts
WHERE account_id = 5;

UPDATE accounts
SET balance = 0
WHERE account_id = 5;

UPDATE accounts
SET account_status = 'Closed'
WHERE account_id = 5;


-- Stored Procedure Implementation

-- Customer Banking Profile

DROP PROCEDURE IF EXISTS sp_customer_banking_profile
DELIMITER $$ 
CREATE PROCEDURE sp_customer_banking_profile (IN p_customer_id INT)
BEGIN
    SELECT
		c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        a.account_number,
        a.balance,
        b.branch_name,
        at.type_name
    FROM customers AS c
    JOIN accounts AS a
    ON c.customer_id = a.customer_id
    JOIN branches AS b
    ON a.branch_id = b.branch_id
    JOIN account_types AS at
    ON a.account_type_id = at.account_type_id
    WHERE c.customer_id = p_customer_id;
END $$
DELIMITER ;

SHOW PROCEDURE STATUS
WHERE Db = DATABASE();

SELECT * 
FROM customers;

CALL sp_customer_banking_profile(1);

SELECT
	c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    a.account_number,
    a.balance,
    b.branch_name,
    at.type_name
FROM customers AS c
JOIN accounts AS a
ON c.customer_id = a.customer_id
JOIN branches AS b
ON a.branch_id = b.branch_id
JOIN account_types AS at
ON a.account_type_id = at.account_type_id
WHERE c.customer_id = 1;

-- Deposit Money

DROP PROCEDURE IF EXISTS sp_deposit_money;
DELIMITER $$
CREATE PROCEDURE sp_deposit_money (IN p_account_id INT, IN p_amount DECIMAL(15, 2))
BEGIN
	DECLARE v_account_count INT DEFAULT 0;
    
    IF p_amount <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deposit amount must be greater than zero';
	END IF;
    
    SELECT COUNT(*)
    INTO v_account_count
    FROM accounts
    WHERE account_id = p_account_id;
    
    IF v_account_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account does not exist';
	END IF;
        
	START TRANSACTION;
    
	UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;
    
    INSERT INTO transactions (account_id, transaction_type, amount)
    VALUES (p_account_id, 'Deposit', p_amount);
    
    COMMIT;
END $$
DELIMITER ; 

SHOW PROCEDURE STATUS
WHERE Db = DATABASE();  

SELECT 
	account_id,
    balance
FROM accounts
WHERE account_id = 1;

CALL sp_deposit_money(1, 250.00);
    
SELECT 
	account_id,
    balance
FROM accounts
WHERE account_id = 1;

SELECT *
FROM transactions
WHERE account_id = 1
ORDER BY transaction_id DESC;					

CALL sp_deposit_money(1, 0);
CALL sp_deposit_money(1, -50000);
CALL sp_deposit_money(9999, 100);

-- Withdraw Money

DROP PROCEDURE IF EXISTS sp_withdraw_money;
DELIMITER $$
CREATE PROCEDURE sp_withdraw_money (IN p_account_id INT, IN p_amount DECIMAL(15, 2))
BEGIN
	DECLARE v_balance DECIMAL(15, 2);
    DECLARE v_account_count INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        RESIGNAL;
	END;
    
    IF p_amount <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Withdrawal amount must be greater than zero';
	END IF;
    
    SELECT COUNT(*)
    INTO v_account_count
    FROM accounts
    WHERE account_id = p_account_id;
    
    IF v_account_count = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account does not exist';
	END IF;
    
    SELECT balance 
    INTO v_balance
    FROM accounts
    WHERE account_id = p_account_id;
    
    IF v_balance < p_amount THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Unable to withdraw due to insufficient funds';
	END IF;
    
    START TRANSACTION; 
    
    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_account_id;
    
    INSERT INTO transactions (account_id, transaction_type, amount)
    VALUES (p_account_id, 'Withdrawal', p_amount);
    
    COMMIT;
END $$
DELIMITER ;

SHOW PROCEDURE STATUS
WHERE Db = DATABASE();

SELECT 
	account_id, 
    balance
FROM accounts
WHERE account_id = 1;

CALL sp_withdraw_money(1, 250.00);

SELECT 
	account_id, 
    balance
FROM accounts
WHERE account_id = 1;

SELECT *
FROM transactions
WHERE account_id = 1
ORDER BY transaction_id DESC
LIMIT 5;

CALL sp_withdraw_money(1, 0);
CALL sp_withdraw_money(1, -100);
CALL sp_withdraw_money(1, 100000);
CALL sp_withdraw_money(9999, 100.00);

-- Transfer Money

DROP PROCEDURE IF EXISTS sp_transfer_money;
DELIMITER $$
CREATE PROCEDURE sp_transfer_money (IN p_sender INT, IN p_receiver INT, IN p_amount DECIMAL(15, 2))
BEGIN
	DECLARE v_sender_balance DECIMAL(15, 2);
    DECLARE v_sender_exists INT DEFAULT 0;
    DECLARE v_receiver_exists INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        RESIGNAL;
	END;
    
    IF p_amount <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transfer amount must be greater than zero';
	END IF;
    
    IF p_sender = p_receiver THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sender and receiver must be different';
	END IF;
    
    SELECT COUNT(*) 
    INTO v_sender_exists 
    FROM accounts
    WHERE account_id = p_sender;
    
    IF v_sender_exists = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sender account does not exist';
	END IF;
    
    SELECT COUNT(*)
    INTO v_receiver_exists
    FROM accounts
    WHERE account_id = p_receiver;
    
    IF v_receiver_exists = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Receiver account does not exist';
	END IF;
    
    START TRANSACTION;
    
    SELECT balance 
    INTO v_sender_balance 
    FROM accounts
    WHERE account_id = p_sender
    FOR UPDATE;
    
    SELECT account_id
    FROM accounts
    WHERE account_id = p_receiver
    FOR UPDATE;
    
    IF v_sender_balance < p_amount THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient funds';
	END IF;
    
    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_sender;
    
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_receiver;
    
    INSERT INTO transactions (account_id, transaction_type, amount)
    VALUES (p_sender, 'Transfer', p_amount);
    
    INSERT INTO transactions (account_id, transaction_type, amount)
    VALUES (p_receiver, 'Transfer', p_amount);
    
    COMMIT;
END $$
DELIMITER ;

SELECT 
	account_id,
    balance
FROM accounts
WHERE account_id IN (1, 2);

CALL sp_transfer_money(1, 2, 200.00);

SELECT 
	account_id,
    balance
FROM accounts
WHERE account_id IN (1, 2);

SELECT *
FROM transactions
WHERE account_id IN (1, 2)
ORDER BY transaction_id DESC
LIMIT 10;

CALL sp_transfer_money(1, 2, 0);
CALL sp_transfer_money(1, 2, 10000000.00);
CALL sp_transfer_money(1, 2, -500.00);
CALL sp_transfer_money(1, 1, 1000.00);
CALL sp_transfer_money(9999, 2, 100.00);
CALL sp_transfer_money(1, 9999, 100.00);

SELECT 
	account_id,
    balance
FROM accounts
WHERE account_id IN (1, 2);

SELECT *
FROM transactions
WHERE account_id IN (1, 2)
ORDER BY transaction_id DESC
LIMIT 10;

-- Customer Statement 

DROP PROCEDURE IF EXISTS sp_customer_statement;
DELIMITER $$
CREATE PROCEDURE sp_customer_statement (IN p_customer_id INT, IN p_start DATE, IN p_end DATE)
BEGIN
	DECLARE v_customer_exists INT DEFAULT 0;
    
    SELECT COUNT(*)
    INTO v_customer_exists
    FROM customers
    WHERE customer_id = p_customer_id;
    
    IF v_customer_exists = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer does not exist';
	END IF;
    
    IF p_start > p_end THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Start date cannot be after end date';
	END IF;
    
    SELECT
		c.customer_id,
        c.first_name,
        c.last_name,
        a.account_number,
        t.transaction_id,
        t.transaction_type,
        t.amount,
        t.transaction_date,
        t.transaction_status
    FROM customers AS c
    JOIN accounts AS a
    ON c.customer_id = a.customer_id
    JOIN transactions AS t
    ON a.account_id = t.account_id
    WHERE 
		c.customer_id = p_customer_id
        AND 
        DATE(t.transaction_date) BETWEEN p_start AND p_end
	ORDER BY t.transaction_date ASC; 
END $$
DELIMITER ; 
    
SELECT *
FROM customers
WHERE customer_id = 1;    

SELECT *
FROM transactions
ORDER BY transaction_date DESC;

CALL sp_customer_statement(1, '2025-01-01', '2025-12-31');
CALL sp_customer_statement(9999, '2025-01-01', '2025-12-31');
CALL sp_customer_statement(1, '2025-12-31', '2025-01-01');
CALL sp_customer_statement(1, '2030-01-01', '2030-12-31');   


-- Performance Optimisation

ANALYZE TABLE customers;
ANALYZE TABLE transactions;
ANALYZE TABLE accounts;

EXPLAIN ANALYZE
SELECT
    c.first_name,
    c.last_name,
    t.transaction_id,
    t.transaction_type,
    t.amount,
    t.transaction_date
FROM customers c
JOIN accounts a
ON c.customer_id = a.customer_id
JOIN transactions t
ON a.account_id = t.account_id

CREATE INDEX idx_accounts_customer
ON accounts(customer_id);

CREATE INDEX idx_accounts_branch
ON accounts(branch_id);

CREATE INDEX idx_accounts_type
ON accounts(account_type_id);

CREATE INDEX idx_transactions_account
ON transactions(account_id);

CREATE INDEX idx_transactions_account_date
ON transactions(account_id, transaction_date);

CREATE INDEX idx_transactions_date
ON transactions(transaction_date);

EXPLAIN ANALYZE
SELECT
    c.first_name,
    c.last_name,
    t.transaction_id,
    t.transaction_type,
    t.amount,
    t.transaction_date
FROM customers c
JOIN accounts a
ON c.customer_id = a.customer_id
JOIN transactions t
ON a.account_id = t.account_id
