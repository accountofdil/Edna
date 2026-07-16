-- Database Creation

CREATE DATABASE phishing_detection_dbms;
USE phishing_detection_dbms;

DROP TABLE IF EXISTS Users;
CREATE TABLE Users(
				user_id INT NOT NULL AUTO_INCREMENT,
                name VARCHAR(100) NOT NULL, 
                email VARCHAR(150) NOT NULL, 
                role ENUM('Administrator', 'Analyst', 'Reporter') NOT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT pk_user_id PRIMARY KEY (user_id),
                CONSTRAINT uq_email UNIQUE (email));

DROP TABLE IF EXISTS Domains;
CREATE TABLE Domains(
					domain_id INT NOT NULL AUTO_INCREMENT,
                    domain_name VARCHAR(255) NOT NULL,
                    is_blacklisted CHAR(1) NOT NULL DEFAULT 'N',
                    risk_score DECIMAL(5, 2) DEFAULT 0.00,
                    first_detected DATE,
                    last_updated DATE,
                    CONSTRAINT pk_domain_id PRIMARY KEY (domain_id),
                    CONSTRAINT uq_domain_name UNIQUE (domain_name),
                    CONSTRAINT ch_domains_isblacklisted CHECK (is_blacklisted IN ('Y', 'N')),
                    CONSTRAINT ch_domains_risk CHECK (risk_score BETWEEN 0 AND 100));
                        
DROP TABLE IF EXISTS IP_Addresses;
CREATE TABLE IP_Addresses(
						ip_id INT NOT NULL AUTO_INCREMENT,
                        ip_address VARCHAR(45) NOT NULL,
                        country VARCHAR(100),
                        is_malicious CHAR(1) NOT NULL DEFAULT 'N',
                        risk_score DECIMAL(5, 2) DEFAULT 0.00,
                        last_checked DATE,
                        CONSTRAINT pk_ip_id PRIMARY KEY (ip_id),
                        CONSTRAINT uq_ip_address UNIQUE (ip_address),
                        CONSTRAINT ch_ipaddresses_ismalicious CHECK (is_malicious IN ('Y', 'N')),
                        CONSTRAINT ch_ipaddresses_risk CHECK (risk_score BETWEEN 0 AND 100)); 

DROP TABLE IF EXISTS Feature_Types;
CREATE TABLE Feature_Types(
						feature_type_id INT NOT NULL AUTO_INCREMENT, 
                        feature_name VARCHAR(100) NOT NULL,
                        description VARCHAR(500),
                        CONSTRAINT pk_feature_type_id PRIMARY KEY (feature_type_id),
                        CONSTRAINT uq_feature_name UNIQUE (feature_name));

DROP TABLE IF EXISTS Detection_Models;
CREATE TABLE Detection_Models(
							model_id INT NOT NULL AUTO_INCREMENT,
                            model_name VARCHAR(150) NOT NULL,
                            version VARCHAR(50) NOT NULL,
                            accuracy_score DECIMAL(5, 4),
                            precision_score DECIMAL(5, 4),
                            recall_score DECIMAL(5, 4),
                            deployment_date DATE,
                            CONSTRAINT pk_model_id PRIMARY KEY (model_id),
                            CONSTRAINT uq_model_version UNIQUE (model_name, version));

DROP TABLE IF EXISTS Emails;
CREATE TABLE Emails(
				email_id INT NOT NULL AUTO_INCREMENT,
                sender_email VARCHAR(200) NOT NULL,
                receiver_email VARCHAR(200) NOT NULL,
                subject VARCHAR(500),
                body_text TEXT,
                received_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                domain_id INT,
                ip_id INT,
                CONSTRAINT pk_email_id PRIMARY KEY (email_id),
                CONSTRAINT fk_emails_domains FOREIGN KEY (domain_id) REFERENCES Domains(domain_id) ON DELETE SET NULL,
                CONSTRAINT fk_emails_ipaddresses FOREIGN KEY (ip_id) REFERENCES IP_Addresses(ip_id) ON DELETE SET NULL);

DROP TABLE IF EXISTS Email_Features;
CREATE TABLE Email_Features(
						email_id INT NOT NULL,
                        feature_type_id INT NOT NULL,
                        feature_value VARCHAR(200) NOT NULL,
                        CONSTRAINT pk_emails_features PRIMARY KEY (email_id, feature_type_id),
                        CONSTRAINT fk_emailfeatures_emails FOREIGN KEY (email_id) REFERENCES Emails(email_id) ON DELETE CASCADE,
                        CONSTRAINT fk_emailfeatures_featuretypes FOREIGN KEY (feature_type_id) REFERENCES Feature_Types(feature_type_id) ON DELETE RESTRICT);

DROP TABLE IF EXISTS Labels;
CREATE TABLE Labels(
				label_id INT NOT NULL AUTO_INCREMENT,
                email_id INT NOT NULL,
                classification ENUM('Phishing', 'Legitimate') NOT NULL,
                risk_score DECIMAL(5, 2) DEFAULT 0.00,
                labeled_by INT NOT NULL,
                labeled_date DATE NOT NULL DEFAULT (CURRENT_DATE),
                CONSTRAINT pk_label_id PRIMARY KEY (label_id),
                CONSTRAINT fk_labels_emails FOREIGN KEY (email_id) REFERENCES Emails(email_id) ON DELETE CASCADE,
                CONSTRAINT fk_labels_users FOREIGN KEY (labeled_by) REFERENCES Users(user_id) ON DELETE RESTRICT,
                CONSTRAINT ch_labels_risk CHECK (risk_score BETWEEN 0 AND 100));

DROP TABLE IF EXISTS User_Reports;
CREATE TABLE User_Reports(
						report_id INT NOT NULL AUTO_INCREMENT,
                        email_id INT NOT NULL,
                        user_id INT NOT NULL,
                        report_reason VARCHAR(500) NOT NULL,
                        report_date DATE NOT NULL DEFAULT (CURRENT_DATE),
                        status ENUM('Pending', 'Reviewed', 'Dismissed') NOT NULL DEFAULT 'Pending',
                        CONSTRAINT pk_report_id PRIMARY KEY (report_id),
                        CONSTRAINT fk_reports_emails FOREIGN KEY (email_id) REFERENCES Emails(email_id) ON DELETE CASCADE,
                        CONSTRAINT fk_reports_users FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE RESTRICT);

DROP TABLE IF EXISTS Model_Predictions;
CREATE TABLE Model_Predictions(
							prediction_id INT NOT NULL AUTO_INCREMENT,
                            email_id INT NOT NULL,
                            model_id INT NOT NULL,
                            predicted_label ENUM('Phishing', 'Legitimate') NOT NULL,
                            predicted_score DECIMAL(5, 4),
                            actual_label ENUM('Phishing', 'Legitimate'),
                            actual_score DECIMAL(5, 4),
                            prediction_date DATE NOT NULL DEFAULT (CURRENT_DATE),
                            CONSTRAINT pk_prediction_id PRIMARY KEY (prediction_id),
                            CONSTRAINT fk_modelpredictions_emails FOREIGN KEY (email_id) REFERENCES Emails(email_id) ON DELETE CASCADE,
                            CONSTRAINT fk_modelpredictions_detectionmodels FOREIGN KEY (model_id) REFERENCES Detection_Models(model_id) ON DELETE RESTRICT);

DROP TABLE IF EXISTS Blacklist;
CREATE TABLE Blacklist(
					blacklist_id INT NOT NULL AUTO_INCREMENT,
                    entity_type ENUM('Domain', 'IP', 'Email') NOT NULL,
                    entity_value VARCHAR(255) NOT NULL,
                    added_date DATE NOT NULL DEFAULT (CURRENT_DATE),
                    reason VARCHAR(500),
                    added_by INT NOT NULL,
                    active_flag CHAR(1) NOT NULL DEFAULT 'Y',
                    CONSTRAINT pk_blacklist_id PRIMARY KEY (blacklist_id),
                    CONSTRAINT fk_blacklist_users FOREIGN KEY (added_by) REFERENCES Users(user_id) ON DELETE RESTRICT,
                    CONSTRAINT ch_active_flag CHECK (active_flag IN ('Y', 'N')));

INSERT INTO Users (name, email, role) 
VALUES
('Aarav Sharma', 'aarav.sharma@phishingdbms.ac.uk', 'Administrator'),
('Ishita Gupta', 'ishita.gupta@phishingdbms.ac.uk', 'Administrator'),
('Rohan Mehta', 'rohan.mehta@phishingdbms.ac.uk', 'Analyst'),
('Sneha Kapoor', 'sneha.kapoor@phishingdbms.ac.uk', 'Analyst'),
('Aditya Malhotra', 'aditya.malhotra@phishingdbms.ac.uk', 'Analyst'),
('Neha Bansal', 'neha.bansal@phishingdbms.ac.uk', 'Analyst'),
('Karan Verma', 'karan.verma@phishingdbms.ac.uk', 'Analyst'),
('Simran Kaur', 'simran.kaur@phishingdbms.ac.uk', 'Analyst'),
('Vivek Arora', 'vivek.arora@phishingdbms.ac.uk', 'Analyst'),
('Mehak Jain', 'mehak.jain@phishingdbms.ac.uk', 'Analyst'),
('Ananya Singh', 'ananya.singh@phishingdbms.ac.uk', 'Reporter'),
('Harsh Gupta', 'harsh.gupta@phishingdbms.ac.uk', 'Reporter'),
('Priyanshu Saini', 'priyanshu.saini@phishingdbms.ac.uk', 'Reporter'),
('Ritika Malhotra', 'ritika.malhotra@phishingdbms.ac.uk', 'Reporter'),
('Ayush Goel', 'ayush.goel@phishingdbms.ac.uk', 'Reporter'),
('Muskan Arora', 'muskan.arora@phishingdbms.ac.uk', 'Reporter'),
('Shubham Garg', 'shubham.garg@phishingdbms.ac.uk', 'Reporter'),
('Nikita Sharma', 'nikita.sharma@phishingdbms.ac.uk', 'Reporter'),
('Yash Aggarwal', 'yash.aggarwal@phishingdbms.ac.uk', 'Reporter'),
('Khushi Batra', 'khushi.batra@phishingdbms.ac.uk', 'Reporter'),
('Arjun Bedi', 'arjun.bedi@phishingdbms.ac.uk', 'Reporter'),
('Diya Khanna', 'diya.khanna@phishingdbms.ac.uk', 'Reporter'),
('Sarthak Jain', 'sarthak.jain@phishingdbms.ac.uk', 'Reporter'),
('Riya Chawla', 'riya.chawla@phishingdbms.ac.uk', 'Reporter'),
('Devansh Gupta', 'devansh.gupta@phishingdbms.ac.uk', 'Reporter');

SELECT * FROM Users;

INSERT INTO Domains (domain_name, is_blacklisted, risk_score, first_detected, last_updated) 
VALUES
('secure-bank-verification.com', 'Y', 96.50, '2024-01-12', '2026-01-05'),
('account-security-check.net', 'Y', 91.80, '2024-02-20', '2026-02-10'),
('paypal-login-support.com', 'Y', 94.20, '2023-11-15', '2025-12-18'),
('microsoft365-authentication.com', 'Y', 89.70, '2024-04-03', '2026-01-22'),
('google-security-alerts.net', 'Y', 93.40, '2024-05-14', '2025-11-30'),
('amazon-payment-confirmation.com', 'Y', 87.90, '2024-06-09', '2026-02-01'),
('netflix-account-recovery.org', 'Y', 85.60, '2023-09-25', '2025-10-11'),
('office365-password-reset.com', 'Y', 92.30, '2024-07-18', '2026-03-03'),
('bank-login-verification.co', 'Y', 97.20, '2024-08-05', '2026-01-15'),
('crypto-wallet-security.net', 'Y', 90.40, '2024-03-30', '2025-12-25'),
('free-cloud-storage-access.com', 'Y', 72.50, '2023-06-21', '2025-09-12'),
('document-share-request.net', 'Y', 68.80, '2024-09-10', '2026-02-08'),
('urgent-payment-update.org', 'Y', 79.60, '2024-10-01', '2026-01-28'),
('verify-identity-portal.com', 'Y', 81.30, '2025-01-11', '2026-02-15'),
('secure-message-center.net', 'Y', 75.90, '2024-11-22', '2026-03-01'),
('gmail.com', 'N', 2.00, '2004-04-01', '2026-01-01'),
('outlook.com', 'N', 2.50, '2012-07-31', '2026-01-01'),
('microsoft.com', 'N', 1.20, '1991-05-02', '2026-01-10'),
('google.com', 'N', 1.00, '1997-09-15', '2026-01-10'),
('amazon.com', 'N', 1.80, '1995-07-05', '2026-01-08'),
('paypal.com', 'N', 2.20, '1999-12-01', '2026-01-12'),
('tiet.ac.in', 'N', 1.50, '2019-01-01', '2026-01-05'),
('gov.uk', 'N', 1.00, '1996-01-01', '2026-01-15'),
('github.com', 'N', 1.30, '2008-02-08', '2026-01-20'),
('stackoverflow.com', 'N', 1.40, '2008-04-01', '2026-01-20'),
('phishingdbms.ac.uk', 'N', 1.00, '2025-01-01', '2026-01-01'),
('research-security.ac.uk', 'N', 3.50, '2023-02-15', '2025-12-20'),
('cybersecurity-lab.edu', 'N', 4.00, '2022-08-10', '2025-11-18'),
('login-validation-service.com', 'Y', 86.70, '2025-02-05', '2026-03-10'),
('account-warning-alert.net', 'Y', 83.90, '2025-03-12', '2026-03-12'),
('secure-invoice-download.org', 'Y', 77.40, '2025-04-01', '2026-02-25'),
('employee-verification-mail.com', 'Y', 80.60, '2025-05-17', '2026-03-05'),
('cloud-document-review.net', 'Y', 74.30, '2025-06-20', '2026-03-08');	
				
SELECT * FROM Domains;
                                
INSERT INTO IP_Addresses (ip_address, country, is_malicious, risk_score, last_checked) 
VALUES
('185.220.101.45', 'Russia', 'Y', 96.50, '2026-02-01'),
('45.155.205.78', 'China', 'Y', 91.20, '2026-01-28'),
('103.87.214.66', 'India', 'Y', 84.70, '2026-02-05'),
('198.98.57.142', 'United States', 'Y', 88.90, '2026-01-20'),
('176.119.29.11', 'Germany', 'Y', 86.40, '2026-02-12'),
('91.240.118.33', 'Netherlands', 'Y', 90.10, '2026-01-25'),
('162.243.155.89', 'United States', 'Y', 82.60, '2026-02-15'),
('5.188.86.24', 'Russia', 'Y', 94.30, '2026-03-01'),
('45.76.134.90', 'Singapore', 'Y', 79.80, '2026-02-18'),
('154.16.105.72', 'Brazil', 'Y', 81.50, '2026-01-30'),
('89.187.164.55', 'Romania', 'Y', 76.20, '2025-12-20'),
('185.234.219.10', 'Ukraine', 'Y', 73.40, '2026-02-03'),
('141.98.10.24', 'France', 'Y', 70.90, '2026-01-17'),
('104.248.12.65', 'Canada', 'Y', 68.50, '2026-02-10'),
('51.83.77.190', 'Poland', 'Y', 71.30, '2026-02-22'),
('203.0.113.45', 'United Kingdom', 'N', 3.00, '2026-01-15'),
('198.51.100.22', 'United States', 'N', 4.50, '2026-01-18'),
('192.0.2.15', 'United Kingdom', 'N', 2.50, '2026-01-20'),
('172.217.14.206', 'United States', 'N', 1.50, '2026-02-01'),
('142.250.183.14', 'United States', 'N', 1.20, '2026-02-03'),
('13.107.42.14', 'United States', 'N', 1.80, '2026-02-04'),
('40.90.189.152', 'United States', 'N', 2.10, '2026-02-06'),
('52.96.72.50', 'Ireland', 'N', 2.40, '2026-02-08'),
('52.85.61.23', 'United States', 'N', 2.00, '2026-02-12'),
('185.199.108.153', 'United States', 'N', 1.70, '2026-02-15'),
('146.75.30.133', 'United Kingdom', 'N', 3.20, '2026-02-17'),
('193.62.83.30', 'United Kingdom', 'N', 2.80, '2026-02-20'),
('144.76.32.22', 'Germany', 'N', 4.00, '2026-02-22'),
('34.107.221.82', 'United States', 'N', 1.90, '2026-02-25'),
('35.190.27.44', 'United States', 'N', 2.30, '2026-02-28'),
('77.91.124.88', 'Turkey', 'Y', 83.70, '2026-03-02'),
('89.248.165.12', 'Netherlands', 'Y', 78.90, '2026-03-03'),
('185.61.149.33', 'Lithuania', 'Y', 85.10, '2026-03-05'),
('193.56.29.77', 'France', 'Y', 80.40, '2026-03-06'),
('109.206.242.18', 'Russia', 'Y', 89.60, '2026-03-08'),
('8.8.8.8', 'United States', 'N', 0.50, '2026-03-10'),
('1.1.1.1', 'United States', 'N', 0.50, '2026-03-10'),
('185.199.109.153', 'United States', 'N', 1.60, '2026-03-11'),
('151.101.1.69', 'United States', 'N', 1.40, '2026-03-12'),
('104.18.32.47', 'United States', 'N', 1.70, '2026-03-12');
        
SELECT * FROM IP_Addresses;                   
                                
INSERT INTO Emails (sender_email, receiver_email, subject, body_text, received_timestamp, domain_id, ip_id) 
VALUES
('support@secure-bank-verification.com', 'ananya.singh@phishingdbms.ac.uk',
 'Urgent: Verify Your Bank Account',
 'Your account has been suspended. Click the link immediately to confirm your banking details.',
 '2026-01-05 08:15:00', 1, 1),
('security@account-security-check.net', 'rohan.mehta@phishingdbms.ac.uk',
 'Security Alert: Login Required',
 'We detected unusual activity. Verify your account using the attached secure link.',
 '2026-01-07 10:25:00', 2, 2),
('service@paypal-login-support.com', 'sneha.kapoor@phishingdbms.ac.uk',
 'PayPal Account Limited',
 'Your PayPal account requires verification to prevent permanent closure.',
 '2026-01-09 12:40:00', 3, 4),
('admin@microsoft365-authentication.com', 'aditya.malhotra@phishingdbms.ac.uk',
 'Microsoft 365 Password Expiry Notice',
 'Your password expires today. Login now to avoid losing access.',
 '2026-01-12 09:10:00', 4, 6),
('alert@google-security-alerts.net', 'neha.bansal@phishingdbms.ac.uk',
 'Google Account Warning',
 'Suspicious login detected. Confirm your identity immediately.',
 '2026-01-14 15:30:00', 5, 8),
('billing@amazon-payment-confirmation.com', 'karan.verma@phishingdbms.ac.uk',
 'Payment Verification Required',
 'Your recent payment failed. Update your card details.',
 '2026-01-16 11:20:00', 6, 9),
('support@netflix-account-recovery.org', 'simran.kaur@phishingdbms.ac.uk',
 'Netflix Subscription Suspended',
 'Renew your subscription by entering your payment information.',
 '2026-01-18 13:45:00', 7, 10),
('office@office365-password-reset.com', 'vivek.arora@phishingdbms.ac.uk',
 'Password Reset Request',
 'Follow this link to reset your organisation password.',
 '2026-01-20 07:55:00', 8, 5),
('verify@bank-login-verification.co', 'mehak.jain@phishingdbms.ac.uk',
 'Bank Login Verification Needed',
 'Confirm your account details to avoid restrictions.',
 '2026-01-22 14:15:00', 9, 7),
('wallet@crypto-wallet-security.net', 'ananya.singh@phishingdbms.ac.uk',
 'Crypto Wallet Security Update',
 'Your wallet requires immediate verification.',
 '2026-01-24 16:00:00', 10, 35),
('storage@free-cloud-storage-access.com', 'harsh.gupta@phishingdbms.ac.uk',
 'Free Cloud Storage Upgrade',
 'Claim additional storage by signing into your account.',
 '2026-01-26 09:30:00', 11, 11),
('documents@document-share-request.net', 'priyanshu.saini@phishingdbms.ac.uk',
 'Shared Document Waiting',
 'A document has been shared with you. Open the attachment.',
 '2026-01-28 10:45:00', 12, 12),
('payments@urgent-payment-update.org', 'ritika.malhotra@phishingdbms.ac.uk',
 'Urgent Payment Update',
 'Your payment information needs verification.',
 '2026-02-01 08:20:00', 13, 13),
('identity@verify-identity-portal.com', 'ayush.goel@phishingdbms.ac.uk',
 'Identity Confirmation Required',
 'Confirm your identity before account access expires.',
 '2026-02-03 12:00:00', 14, 14),
('message@secure-message-center.net', 'muskan.arora@phishingdbms.ac.uk',
 'Secure Message Notification',
 'Open the secure message using the provided link.',
 '2026-02-05 14:25:00', 15, 15),
('newsletter@gmail.com', 'aarav.sharma@phishingdbms.ac.uk',
 'Monthly Security Newsletter',
 'Latest cybersecurity updates and industry news.',
 '2026-02-07 09:00:00', 16, 17),
('hr@microsoft.com', 'ishita.gupta@phishingdbms.ac.uk',
 'Microsoft Security Update',
 'Important security updates are available.',
 '2026-02-09 11:30:00', 18, 21),
('support@google.com', 'rohan.mehta@phishingdbms.ac.uk',
 'Google Service Notification',
 'Information regarding your Google services.',
 '2026-02-11 15:10:00', 19, 20),
('orders@amazon.com', 'sneha.kapoor@phishingdbms.ac.uk',
 'Order Confirmation',
 'Your order has been successfully processed.',
 '2026-02-13 16:45:00', 20, 24),
('service@paypal.com', 'aditya.malhotra@phishingdbms.ac.uk',
 'Payment Receipt',
 'Your payment receipt is attached.',
 '2026-02-15 10:15:00', 21, 22),
('admin@tiet.ac.in', 'neha.bansal@phishingdbms.ac.uk',
 'Exam Schedule Released',
 'The latest examination schedule is available.',
 '2026-02-17 12:30:00', 22, 26),
('security@github.com', 'karan.verma@phishingdbms.ac.uk',
 'Repository Security Alert',
 'A security scan has completed successfully.',
 '2026-02-19 13:00:00', 24, 25),
('notification@gov.uk', 'simran.kaur@phishingdbms.ac.uk',
 'Government Service Update',
 'Important information regarding your account.',
 '2026-02-21 09:45:00', 23, 27),
('research@research-security.ac.uk', 'vivek.arora@phishingdbms.ac.uk',
 'Cybersecurity Research Report',
 'New findings from security research.',
 '2026-02-23 14:20:00', 26, 28),
('lab@cybersecurity-lab.edu', 'mehak.jain@phishingdbms.ac.uk',
 'Security Lab Announcement',
 'Upcoming cybersecurity workshop details.',
 '2026-02-25 17:00:00', 27, 29);

SELECT * FROM Emails;

INSERT INTO Feature_Types (feature_name, description)
VALUES
('URL Count', 'Total number of URLs found in the email body'),
('Has Attachment', 'Whether the email contains an attachment (1 = Yes, 0 = No)'),
('SPF Fail', 'Whether the sender domain failed SPF validation (1 = Yes, 0 = No)'),
('Link Mismatch', 'Whether displayed link text differs from the actual URL destination'),
('Suspicious Words', 'Count of suspicious keywords such as urgent, verify, click, reset'),
('Sender Reputation Score', 'Reputation score of the sender domain based on previous activity'),
('Domain Age', 'Age of sender domain in days since registration'),
('External Link Count', 'Number of external links present in the email'),
('Urgency Indicator', 'Presence of urgent language requesting immediate action'),
('Credential Request', 'Whether the email requests usernames, passwords, or sensitive information'),
('Email Header Anomaly', 'Whether abnormal email header patterns were detected'),
('Attachment Risk Score', 'Risk score assigned to email attachments based on file analysis');  

SELECT * FROM Feature_Types;     

INSERT INTO Email_Features (email_id, feature_type_id, feature_value)
VALUES                 
(1, 1, '6'),
(1, 2, '1'),
(1, 3, '1'),
(1, 4, '1'),
(1, 5, '7'),
(1, 6, '12'),
(1, 7, '45'),
(1, 8, '5'),
(1, 9, '1'),
(1, 10, '1'),
(1, 11, '1'),
(1, 12, '85'),
(2, 1, '4'),
(2, 2, '1'),
(2, 3, '1'),
(2, 4, '1'),
(2, 5, '6'),
(2, 6, '18'),
(2, 7, '60'),
(2, 8, '4'),
(2, 9, '1'),
(2, 10, '1'),
(2, 11, '1'),
(2, 12, '78'),
(3, 1, '5'),
(3, 2, '0'),
(3, 3, '1'),
(3, 4, '1'),
(3, 5, '5'),
(3, 6, '15'),
(3, 7, '90'),
(3, 8, '3'),
(3, 9, '1'),
(3, 10, '1'),
(3, 11, '1'),
(3, 12, '65'),
(4, 1, '7'),
(4, 2, '1'),
(4, 3, '1'),
(4, 4, '1'),
(4, 5, '8'),
(4, 6, '10'),
(4, 7, '35'),
(4, 8, '6'),
(4, 9, '1'),
(4, 10, '1'),
(4, 11, '1'),
(4, 12, '92'),
(5, 1, '5'),
(5, 2, '1'),
(5, 3, '1'),
(5, 4, '1'),
(5, 5, '6'),
(5, 6, '14'),
(5, 7, '70'),
(5, 8, '4'),
(5, 9, '1'),
(5, 10, '1'),
(5, 11, '1'),
(5, 12, '75');

SELECT * FROM Email_Features;

INSERT INTO Detection_Models (model_name, version, accuracy_score, precision_score, recall_score, deployment_date)
VALUES
('Random Forest', 'v2.0', 0.9380, 0.9310, 0.9250, '2025-02-15'),
('Random Forest', 'v3.1', 0.9520, 0.9480, 0.9400, '2026-01-10'),
('Deep Neural Network', 'v1.0', 0.9610, 0.9550, 0.9580, '2025-04-20'),
('Deep Neural Network', 'v2.2', 0.9730, 0.9680, 0.9700, '2026-02-01'),
('Naive Bayes', 'v1.5', 0.8420, 0.8300, 0.8500, '2024-05-15'),
('Gradient Boosting', 'v1.0', 0.9450, 0.9390, 0.9470, '2025-06-10'),
('Gradient Boosting', 'v2.0', 0.9580, 0.9540, 0.9600, '2026-01-25'),
('XGBoost Classifier', 'v1.0', 0.9650, 0.9620, 0.9640, '2025-08-05'),
('XGBoost Classifier', 'v2.1', 0.9780, 0.9740, 0.9760, '2026-03-01'),
('Support Vector Machine', 'v2.0', 0.9180, 0.9120, 0.9200, '2025-09-12'),
('Transformer Email Model', 'v1.0', 0.9810, 0.9790, 0.9800, '2026-03-05'),
('Hybrid Ensemble Model', 'v1.0', 0.9850, 0.9830, 0.9840, '2026-03-15'),
('Random Forest', 'v4.0', 0.9640, 0.9610, 0.9630, '2026-04-05'),
('Logistic Regression', 'v3.0', 0.8920, 0.8850, 0.8890, '2025-01-18'),
('Logistic Regression', 'v4.1', 0.9140, 0.9080, 0.9120, '2026-02-12'),
('SVM Classifier', 'v2.5', 0.9310, 0.9270, 0.9340, '2025-03-25'),
('SVM Classifier', 'v3.0', 0.9440, 0.9410, 0.9460, '2026-01-30'),
('Decision Tree', 'v1.0', 0.8510, 0.8460, 0.8540, '2024-08-10'),
('Decision Tree', 'v2.0', 0.8840, 0.8790, 0.8870, '2025-11-15'),
('AdaBoost Classifier', 'v1.0', 0.9320, 0.9280, 0.9350, '2025-05-21'),
('AdaBoost Classifier', 'v2.0', 0.9510, 0.9490, 0.9520, '2026-02-20'),
('LightGBM Phishing Detector', 'v1.0', 0.9690, 0.9650, 0.9700, '2026-01-05'),
('LightGBM Phishing Detector', 'v2.0', 0.9770, 0.9750, 0.9780, '2026-03-18'),
('CNN Email Content Analyzer', 'v1.0', 0.9580, 0.9530, 0.9600, '2025-10-01'),
('CNN Email Content Analyzer', 'v2.0', 0.9720, 0.9690, 0.9710, '2026-03-22'),
('LSTM Sequence Detector', 'v1.0', 0.9660, 0.9620, 0.9670, '2025-12-10'),
('LSTM Sequence Detector', 'v2.0', 0.9790, 0.9760, 0.9800, '2026-04-01'),
('BERT Email Security Model', 'v1.0', 0.9840, 0.9810, 0.9850, '2026-04-10'),
('BERT Email Security Model', 'v2.0', 0.9880, 0.9860, 0.9890, '2026-05-01'),
('Ensemble Risk Classifier', 'v2.0', 0.9910, 0.9890, 0.9900, '2026-05-15'),
('Threat Intelligence Model', 'v1.0', 0.9560, 0.9520, 0.9570, '2025-07-14'),
('Threat Intelligence Model', 'v2.0', 0.9710, 0.9680, 0.9720, '2026-04-20');

SELECT * FROM Detection_Models;

INSERT INTO Labels (email_id, classification, risk_score, labeled_by, labeled_date)
VALUES                                
(2, 'Phishing', 89.20, 4, '2024-12-07'),
(3, 'Legitimate', 4.50, 5, '2024-12-08'),
(4, 'Phishing', 95.20, 6, '2024-12-09'),
(5, 'Legitimate', 3.80, 7, '2024-12-10'),
(6, 'Phishing', 91.60, 8, '2024-12-11'),
(7, 'Phishing', 93.40, 9, '2024-12-12'),
(8, 'Phishing', 96.10, 10, '2024-12-13'),
(9, 'Phishing', 92.70, 11, '2024-12-14'),
(10, 'Phishing', 87.90, 12, '2024-12-15'),
(11, 'Legitimate', 8.20, 13, '2024-12-16'),
(12, 'Legitimate', 14.50, 14, '2024-12-17'),
(13, 'Phishing', 81.30, 15, '2024-12-18'),
(14, 'Phishing', 85.70, 16, '2024-12-19'),
(15, 'Phishing', 79.80, 17, '2024-12-20'),
(16, 'Legitimate', 2.50, 18, '2024-12-21'),
(17, 'Legitimate', 5.40, 19, '2024-12-22'),
(18, 'Legitimate', 3.90, 20, '2024-12-23'),
(19, 'Legitimate', 2.80, 21, '2024-12-24'),
(20, 'Legitimate', 4.10, 22, '2024-12-25'),
(21, 'Legitimate', 1.90, 23, '2024-12-26'),
(22, 'Legitimate', 6.20, 24, '2024-12-27'),
(23, 'Legitimate', 3.50, 25, '2024-12-28'),
(24, 'Legitimate', 5.80, 3, '2024-12-29'),
(25, 'Legitimate', 7.10, 4, '2024-12-30'),
(1, 'Phishing', 93.50, 5, '2025-01-02'),
(2, 'Phishing', 86.90, 6, '2025-01-03'),
(4, 'Phishing', 97.10, 7, '2025-01-04'),
(6, 'Phishing', 90.40, 8, '2025-01-05'),
(7, 'Phishing', 92.80, 9, '2025-01-06'),
(8, 'Phishing', 95.60, 10, '2025-01-07'),
(10, 'Phishing', 86.40, 11, '2025-01-08'),
(13, 'Phishing', 76.90, 12, '2025-01-09'),
(14, 'Phishing', 83.20, 13, '2025-01-10'),
(15, 'Phishing', 78.40, 14, '2025-01-11'),
(16, 'Legitimate', 4.00, 15, '2025-01-12'),
(18, 'Legitimate', 5.10, 16, '2025-01-13'),
(20, 'Legitimate', 3.20, 17, '2025-01-14'),
(22, 'Legitimate', 6.70, 18, '2025-01-15'),
(25, 'Legitimate', 5.50, 19, '2025-01-16');

SELECT * FROM Labels;

INSERT INTO User_Reports (email_id, user_id, report_reason, report_date, status)
VALUES
(2, 13, 'Password reset email received without requesting a password change.', '2025-01-04', 'Reviewed'),
(2, 14, 'Sender domain appears similar to a trusted service but is not authentic.', '2025-01-05', 'Pending'),
(3, 15, 'Checked email and confirmed sender appears legitimate.', '2025-01-06', 'Dismissed'),
(4, 16, 'Urgent password expiry warning contains suspicious external links.', '2025-01-07', 'Reviewed'),
(4, 17, 'Possible credential harvesting attempt detected.', '2025-01-08', 'Reviewed'),
(1, 11, 'Received a bank verification request containing a suspicious login link.', '2025-01-02', 'Reviewed'),
(1, 12, 'Message impersonates a financial institution and requests account information.', '2025-01-03', 'Reviewed'),
(5, 18, 'Email requests identity confirmation through unknown website.', '2025-01-09', 'Reviewed'),
(6, 19, 'Payment verification message requests sensitive banking details.', '2025-01-10', 'Reviewed'),
(6, 20, 'Suspicious attachment included in payment-related email.', '2025-01-11', 'Pending'),
(7, 21, 'Subscription renewal email contains possible phishing indicators.', '2025-01-12', 'Reviewed'),
(8, 22, 'Password reset link redirects to unknown domain.', '2025-01-13', 'Reviewed'),
(9, 23, 'Bank login verification email appears fraudulent.', '2025-01-14', 'Reviewed'),
(10, 24, 'Cryptocurrency wallet update requests account credentials.', '2025-01-15', 'Pending'),
(11, 25, 'Cloud storage upgrade notification appears suspicious.', '2025-01-16', 'Reviewed'),
(12, 11, 'Unexpected document sharing request from unknown sender.', '2025-01-17', 'Reviewed'),
(13, 12, 'Payment update request uses urgent language and suspicious wording.', '2025-01-18', 'Reviewed'),
(14, 13, 'Identity verification email requests personal information.', '2025-01-19', 'Pending'),
(15, 14, 'Secure message notification contains suspicious URL patterns.', '2025-01-20', 'Reviewed'),
(16, 15, 'Security newsletter verified as legitimate communication.', '2025-01-21', 'Dismissed'),
(17, 16, 'Microsoft security update appears to originate from valid domain.', '2025-01-22', 'Dismissed'),
(20, 19, 'Payment receipt verified as legitimate transaction.', '2025-01-25', 'Dismissed'),
(18, 17, 'Google notification checked and confirmed authentic.', '2025-01-23', 'Dismissed'),
(19, 18, 'Amazon order confirmation matches previous activity.', '2025-01-24', 'Dismissed'),
(21, 20, 'University communication verified by sender domain.', '2025-01-26', 'Dismissed'),
(22, 21, 'GitHub security notification appears authentic.', '2025-01-27', 'Dismissed'),
(23, 22, 'Government service notification confirmed genuine.', '2025-01-28', 'Dismissed'),
(24, 23, 'Research report email checked and approved.', '2025-01-29', 'Dismissed'),
(25, 24, 'Cybersecurity workshop announcement verified.', '2025-01-30', 'Dismissed'),
(1, 25, 'Multiple users received identical fraudulent banking messages.', '2025-02-01', 'Reviewed'),
(2, 11, 'Suspicious sender address resembles a known phishing campaign.', '2025-02-02', 'Reviewed'),
(4, 12, 'Detected fake Microsoft login page reference.', '2025-02-03', 'Reviewed'),
(5, 13, 'Possible account takeover attempt detected.', '2025-02-04', 'Pending'),
(7, 14, 'Fake subscription renewal message requesting payment details.', '2025-02-05', 'Reviewed'),
(8, 15, 'Password reset URL does not match official service domain.', '2025-02-06', 'Reviewed'),
(9, 16, 'Banking credentials requested through external webpage.', '2025-02-07', 'Reviewed'),
(10, 17, 'Crypto-related email associated with malicious infrastructure.', '2025-02-08', 'Reviewed'),
(13, 18, 'Urgent payment request appears to be social engineering.', '2025-02-09', 'Pending'),
(14, 19, 'Identity theft attempt suspected from email content.', '2025-02-10', 'Reviewed'),
(15, 20, 'Suspicious message centre notification flagged.', '2025-02-11', 'Reviewed');

SELECT * FROM User_Reports;

INSERT INTO Model_Predictions (email_id, model_id, predicted_label, predicted_score, actual_label, actual_score, prediction_date)
VALUES
(1, 4, 'Phishing', 0.9520, 'Phishing', 0.9200, '2025-01-02'),
(1, 5, 'Phishing', 0.9670, 'Phishing', 0.9200, '2025-01-02'),
(1, 6, 'Phishing', 0.9010, 'Phishing', 0.9200, '2025-01-02'),
(1, 7, 'Phishing', 0.9750, 'Phishing', 0.9200, '2025-01-02'),
(1, 8, 'Phishing', 0.9410, 'Phishing', 0.9200, '2025-01-02'),
(2, 3, 'Phishing', 0.8840, 'Phishing', 0.8750, '2025-01-03'),
(2, 4, 'Phishing', 0.9230, 'Phishing', 0.8750, '2025-01-03'),
(2, 9, 'Phishing', 0.9560, 'Phishing', 0.8750, '2025-01-03'),
(2, 10, 'Phishing', 0.9720, 'Phishing', 0.8750, '2025-01-03'),
(2, 11, 'Phishing', 0.9810, 'Phishing', 0.8750, '2025-01-03'),
(3, 4, 'Legitimate', 0.9480, 'Legitimate', 0.9700, '2025-01-04'),
(3, 5, 'Legitimate', 0.9620, 'Legitimate', 0.9700, '2025-01-04'),
(3, 8, 'Legitimate', 0.9330, 'Legitimate', 0.9700, '2025-01-04'),
(3, 12, 'Legitimate', 0.9750, 'Legitimate', 0.9700, '2025-01-04'),
(4, 4, 'Phishing', 0.9640, 'Phishing', 0.9600, '2025-01-05'),
(4, 7, 'Phishing', 0.9810, 'Phishing', 0.9600, '2025-01-05'),
(4, 9, 'Phishing', 0.9460, 'Phishing', 0.9600, '2025-01-05'),
(4, 11, 'Phishing', 0.9890, 'Phishing', 0.9600, '2025-01-05'),
(5, 4, 'Legitimate', 0.8910, 'Legitimate', 0.9800, '2025-01-06'),
(5, 6, 'Legitimate', 0.9240, 'Legitimate', 0.9800, '2025-01-06'),
(5, 10, 'Legitimate', 0.9530, 'Legitimate', 0.9800, '2025-01-06'),
(5, 15, 'Legitimate', 0.9760, 'Legitimate', 0.9800, '2025-01-06'),
(6, 4, 'Phishing', 0.9450, 'Phishing', 0.9100, '2025-01-07'),
(6, 8, 'Phishing', 0.9630, 'Phishing', 0.9100, '2025-01-07'),
(6, 11, 'Phishing', 0.9870, 'Phishing', 0.9100, '2025-01-07'),
(7, 5, 'Phishing', 0.9320, 'Phishing', 0.9300, '2025-01-08'),
(7, 9, 'Phishing', 0.9610, 'Phishing', 0.9300, '2025-01-08'),
(7, 12, 'Phishing', 0.9790, 'Phishing', 0.9300, '2025-01-08'),
(8, 7, 'Phishing', 0.9710, 'Phishing', 0.9600, '2025-01-09'),
(8, 10, 'Phishing', 0.9830, 'Phishing', 0.9600, '2025-01-09'),
(8, 16, 'Phishing', 0.9910, 'Phishing', 0.9600, '2025-01-09'),
(9, 4, 'Phishing', 0.9560, 'Phishing', 0.9200, '2025-01-10'),
(9, 11, 'Phishing', 0.9840, 'Phishing', 0.9200, '2025-01-10'),
(9, 17, 'Phishing', 0.9920, 'Phishing', 0.9200, '2025-01-10'),
(10, 5, 'Phishing', 0.9120, 'Phishing', 0.8870, '2025-01-11'),
(10, 8, 'Phishing', 0.9540, 'Phishing', 0.8870, '2025-01-11'),
(10, 18, 'Phishing', 0.9810, 'Phishing', 0.8870, '2025-01-11');

SELECT * FROM Model_Predictions;

INSERT INTO Blacklist (entity_type, entity_value, added_date, reason, added_by, active_flag) 
VALUES
('Domain', 'secure-account-update-login.com', '2025-01-02',
 'Credential phishing campaign targeting banking users', 1, 'Y'),
('Domain', 'microsoft365-security-check.net', '2025-01-04',
 'Fake Microsoft authentication portal', 2, 'Y'),
('Domain', 'paypal-verification-center.org', '2025-01-06',
 'Fraudulent PayPal login page', 3, 'Y'),
('Domain', 'google-account-recovery-help.com', '2025-01-08',
 'Impersonation domain used for account theft', 4, 'Y'),
('Domain', 'amazon-payment-alerts.net', '2025-01-10',
 'Fake payment verification website', 5, 'Y'),
('Domain', 'netflix-billing-support.org', '2025-01-12',
 'Subscription renewal phishing campaign', 6, 'Y'),
('Domain', 'office365-login-security.com', '2025-01-14',
 'Credential harvesting website', 7, 'Y'),
('Domain', 'crypto-wallet-confirmation.net', '2025-01-16',
 'Cryptocurrency phishing infrastructure', 8, 'Y'),
('Domain', 'identity-check-service.org', '2025-01-18',
 'Fake identity verification portal', 9, 'Y'),
('Domain', 'document-access-confirmation.com', '2025-01-20',
 'Malicious document sharing domain', 10, 'Y'),
('Domain', 'secure-invoice-payment.net', '2025-01-22',
 'Business email compromise campaign', 11, 'Y'),
('Domain', 'employee-login-verification.org', '2025-01-25',
 'Fake employee authentication service', 12, 'Y'),
('Domain', 'account-warning-message.com', '2025-01-28',
 'Phishing emails impersonating account alerts', 13, 'Y'),
('Domain', 'cloud-storage-security-check.net', '2025-02-01',
 'Fake cloud storage login page', 14, 'Y'),
('Domain', 'bank-confirmation-service.org', '2025-02-05',
 'Banking credential theft operation', 15, 'Y'),
('IP', '185.234.72.19', '2025-01-03',
 'Command and control server linked to phishing activity', 1, 'Y'),
('IP', '91.219.236.55', '2025-01-05',
 'Hosting server for malicious login pages', 2, 'Y'),
('IP', '45.142.214.88', '2025-01-07',
 'Suspicious mail relay infrastructure', 3, 'Y'),
('IP', '103.112.44.91', '2025-01-09',
 'Detected sending high volume phishing emails', 4, 'Y'),
('IP', '176.111.174.20', '2025-01-11',
 'Associated with credential harvesting attacks', 5, 'Y'),
('IP', '193.56.29.88', '2025-01-13',
 'Malicious email distribution server', 6, 'Y'),
('IP', '154.213.18.77', '2025-01-15',
 'Known phishing campaign infrastructure', 7, 'Y'),
('IP', '89.34.96.120', '2025-01-17',
 'Suspicious hosting provider address', 8, 'Y'),
('IP', '212.102.40.51', '2025-01-19',
 'Threat intelligence match detected', 9, 'Y'),
('IP', '37.120.222.44', '2025-01-21',
 'Malware distribution server', 10, 'Y'),
('Email', 'security-alert@fakebank-support.com', '2025-02-10',
 'Sender used in banking phishing campaign', 11, 'Y'),
('Email', 'admin@account-reset-help.net', '2025-02-12',
 'Credential harvesting sender address', 12, 'Y'),
('Email', 'support@payment-validation.org', '2025-02-14',
 'Fake payment verification emails', 13, 'Y'),
('Email', 'service@cloud-storage-access.com', '2025-02-16',
 'Malicious cloud account takeover attempt', 14, 'Y'),
('Email', 'verify@secure-login-check.net', '2025-02-18',
 'Phishing sender requesting credentials', 15, 'Y'),
('Domain', 'old-phishing-campaign.com', '2023-06-15',
 'Previous phishing campaign no longer active', 1, 'N'),
('Domain', 'expired-login-alert.net', '2023-08-22',
 'Domain removed after investigation', 2, 'N'),
('IP', '192.0.2.200', '2023-09-10',
 'Historical malicious infrastructure', 3, 'N'),
('IP', '198.51.100.75', '2023-11-05',
 'Previously associated with spam activity', 4, 'N'),
('Email', 'old-alert@phish-example.com', '2024-01-15',
 'Inactive phishing sender account', 5, 'N');

SELECT * FROM Blacklist;       
                        

-- View Implementation   

DROP VIEW IF EXISTS vw_phishing_summary;
CREATE OR REPLACE VIEW vw_phishing_summary 
AS
	(SELECT 	
		e.email_id,
		e.sender_email,
		e.received_timestamp,
		d.domain_name,
		d.risk_score AS domain_risk_score,
		ip.ip_address,
		ip.country,
		ip.is_malicious,
		l.classification,
		l.risk_score AS label_risk_score,
		u.name AS labeled_by_name
	FROM Emails AS e
	JOIN Domains AS d 
	ON e.domain_id = d.domain_id
	JOIN IP_Addresses AS ip
	ON e.ip_id = ip.ip_id
	JOIN Labels AS l
	ON e.email_id = l.email_id
	JOIN Users AS u
	ON l.labeled_by = u.user_id
	WHERE l.classification = 'Phishing');

SELECT * FROM vw_phishing_summary;

DROP VIEW IF EXISTS vw_model_performance;
CREATE OR REPLACE VIEW vw_model_performance
AS
	(SELECT 
		dm.model_name,
		dm.version,
		COUNT(mp.prediction_id) AS total_predictions,
		SUM(mp.predicted_label = mp.actual_label) AS correct_predictions,
		ROUND(SUM(mp.predicted_label = mp.actual_label) / COUNT(mp.prediction_id) * 100, 2) AS live_accuracy_percentage,
		SUM(mp.predicted_label = 'Legitimate' AND mp.actual_label = 'Phishing') AS false_positives
	FROM Detection_Models AS dm
	JOIN Model_Predictions AS mp
	ON dm.model_id = mp.model_id
    GROUP BY dm.model_id, dm.model_name, dm.version);

SELECT * FROM vw_model_performance;

DROP VIEW IF EXISTS vw_active_blacklist;
CREATE OR REPLACE VIEW vw_active_blacklist
AS
	(SELECT 
		b.blacklist_id,
		b.entity_type,
		b.entity_value,
		b.added_date,
		b.reason,
		u.name AS added_by_name
	FROM Blacklist AS b
	JOIN Users AS u
	ON b.added_by = u.user_id
	WHERE b.active_flag = 'Y'
	ORDER BY b.added_date DESC);

SELECT * FROM vw_active_blacklist;

DROP VIEW IF EXISTS vw_pending_reports;
CREATE OR REPLACE VIEW vw_pending_reports
AS
	(SELECT 
		ur.report_id,
		u.name AS reported_by,
		e.sender_email,
		e.subject,
		ur.report_reason,
		ur.report_date
	FROM User_Reports AS ur
	JOIN Users AS u
	ON ur.user_id = u.user_id
	JOIN Emails AS e
	ON ur.email_id = e.email_id
	WHERE ur.status = 'Pending'
	ORDER BY ur.report_date ASC);

SELECT * FROM vw_pending_reports;


-- Function Implementation

DROP FUNCTION IF EXISTS fn_composite_risk;
DELIMITER $$
CREATE FUNCTION fn_composite_risk (p_email_id INT)
RETURNS DECIMAL(5, 2)
READS SQL DATA
DETERMINISTIC 
BEGIN
	DECLARE v_domain_risk DECIMAL(5, 2) DEFAULT 0;
    DECLARE v_ip_risk DECIMAL(5, 2) DEFAULT 0;
    DECLARE v_url_count INT DEFAULT 0;
    DECLARE v_spf_fail INT DEFAULT 0;
    DECLARE v_composite DECIMAL(5, 2);
    
    SELECT 
		COALESCE(d.risk_score, 0) INTO v_domain_risk
    FROM Emails AS e
    LEFT JOIN Domains AS d
    ON e.domain_id = d.domain_id
    WHERE e.email_id = p_email_id;
    
    SELECT
		COALESCE(ip.risk_score, 0) INTO v_ip_risk
    FROM Emails AS e
    LEFT JOIN IP_Addresses AS ip
    ON e.ip_id = ip.ip_id
    WHERE e.email_id = p_email_id;
    
    SELECT
		COALESCE(CAST(feature_value AS UNSIGNED), 0) INTO v_url_count
    FROM Email_Features
    WHERE 
		email_id = p_email_id 
        AND 
        feature_type_id = 1;
    
    SELECT
		COALESCE(CAST(feature_value AS UNSIGNED), 0) INTO v_spf_fail
	FROM Email_Features
    WHERE 
		email_id = p_email_id 
        AND 
        feature_type_id = 3;
    
    SET v_composite = (v_domain_risk * 0.50) + (v_ip_risk * 0.30) + (v_url_count * 1.50) + (v_spf_fail * 5.00);
    
    RETURN LEAST(v_composite, 100.00);
END $$
DELIMITER ; 

SHOW FUNCTION STATUS
WHERE Name = 'fn_composite_risk';

SELECT * FROM Emails;

SELECT fn_composite_risk(9) AS composite_risk;

SELECT 
	e.email_id, 
    COALESCE(d.risk_score, 0) AS domain_risk,
    COALESCE(ip.risk_score, 0) AS ip_risk, 
    fn_composite_risk(9) AS composite_risk
FROM Emails AS e
LEFT JOIN Domains AS d
ON e.domain_id = d.domain_id
LEFT JOIN IP_Addresses AS ip
ON e.ip_id = ip.ip_id
WHERE e.email_id = 9;

SELECT 
	email_id,
    sender_email,
    fn_composite_risk(email_id) AS composite_risk_score
FROM Emails
ORDER BY composite_risk_score DESC;

DROP FUNCTION IF EXISTS fn_is_sender_blacklisted;
DELIMITER $$ 
CREATE FUNCTION fn_is_sender_blacklisted (p_email_id INT)
RETURNS VARCHAR(3)
READS SQL DATA
DETERMINISTIC 
BEGIN
	DECLARE v_flag CHAR(1) DEFAULT 'N';
    
    SELECT 
		d.is_blacklisted INTO v_flag
	FROM Emails AS e
    JOIN Domains AS d
    ON e.domain_id = d.domain_id
    WHERE e.email_id = p_email_id;
    
    IF v_flag = 'Y' THEN
		RETURN 'Yes';
	ELSE
		RETURN 'No';
	END IF;
END $$ 
DELIMITER ; 

SELECT email_id, domain_id
FROM Emails;

SELECT fn_is_sender_blacklisted(4) AS is_blacklisted;
SELECT fn_is_sender_blacklisted(5) AS is_blacklisted;

SELECT 
	e.email_id,
    d.is_blacklisted
FROM Emails AS e
JOIN Domains AS d
ON e.domain_id = d.domain_id
WHERE e.email_id = 4;

SELECT 
	e.email_id,
    d.is_blacklisted
FROM Emails AS e
JOIN Domains AS d
ON e.domain_id = d.domain_id
WHERE e.email_id = 5;

SELECT 
	email_id,
    sender_email,
    fn_is_sender_blacklisted(email_id) AS sender_blacklisted
FROM Emails;


-- Trigger Implementation

DROP TRIGGER IF EXISTS trg_auto_blacklist_domain;
DELIMITER $$
CREATE TRIGGER trg_auto_blacklist_domain
AFTER INSERT ON Labels
FOR EACH ROW
BEGIN
	DECLARE v_domain_id INT;
    
    IF NEW.risk_score >= 90 THEN
		SELECT domain_id INTO v_domain_id
        FROM Emails 
        WHERE email_id = NEW.email_id;
	
    UPDATE DOMAINS
	SET
		is_blacklisted = 'Y',
        last_updated = CURRENT_DATE()
	WHERE 
		domain_id = v_domain_id
        AND
        is_blacklisted = 'N';
	END IF;
END $$
DELIMITER ; 

SHOW TRIGGERS LIKE 'Labels';

SELECT
	e.email_id,
    d.domain_id,
    d.is_blacklisted
FROM Emails AS e
JOIN Domains AS d
ON e.domain_id = d.domain_id
WHERE d.is_blacklisted = 'N';

SELECT *
FROM Domains
WHERE domain_id = 16;

SELECT user_id
FROM Users;

INSERT INTO Labels (email_id, classification, risk_score, labeled_by)
VALUES (16, 'Phishing', 95, 5);

SELECT domain_id
FROM Emails
WHERE email_id = 16;

SELECT 
	domain_id,
    is_blacklisted,
    last_updated
FROM Domains
WHERE domain_id = (SELECT domain_id FROM Emails WHERE email_id = 16);

DROP TRIGGER IF EXISTS trg_log_blacklisted_domain;
DELIMITER $$
CREATE TRIGGER trg_log_blacklisted_domain
AFTER UPDATE ON Domains
FOR EACH ROW
BEGIN
	IF OLD.is_blacklisted = 'N' AND NEW.is_blacklisted = 'Y' THEN
		INSERT INTO Blacklist (entity_type, entity_value, added_date, reason, added_by, active_flag)
        VALUES ('Domain', NEW.domain_name, CURRENT_DATE(), 'Auto-blacklisted due to high risk score and threshold breach', 1, 'Y');
	END IF; 
END $$ 
DELIMITER ; 

SELECT 
	domain_id, 
    domain_name,
    is_blacklisted
FROM Domains
WHERE is_blacklisted = 'N';

SELECT *
FROM Blacklist
WHERE entity_value = 'microsoft.com';

UPDATE Domains
SET is_blacklisted = 'Y'
WHERE domain_id = 18;

SELECT *
FROM Blacklist
WHERE entity_value = 'microsoft.com';

DROP TRIGGER IF EXISTS trg_prevent_active_blacklist_delete;
DELIMITER $$ 
CREATE TRIGGER trg_prevent_active_blacklist_delete
BEFORE DELETE ON Blacklist
FOR EACH ROW
BEGIN
	IF OLD.active_flag = 'Y' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Cannot delete an active blacklist entry. Set active_flag to N first.';
    END IF;
END $$ 
DELIMITER ;

SELECT 
	blacklist_id,
    entity_value, 
    active_flag
FROM Blacklist
WHERE active_flag = 'Y';

DELETE FROM Blacklist 
WHERE blacklist_id = 1;

UPDATE Blacklist
SET active_flag = 'N'
WHERE blacklist_id = 1;

DELETE FROM Blacklist 
WHERE blacklist_id = 1;

SELECT 
	blacklist_id,
    entity_value, 
    active_flag
FROM Blacklist
WHERE active_flag = 'Y';

DROP TRIGGER IF EXISTS trg_validate_classification;
DELIMITER $$
CREATE TRIGGER trg_validate_classification
BEFORE INSERT ON Labels
FOR EACH ROW
BEGIN
	IF NEW.classification NOT IN ('Phishing', 'Legitimate') THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Invalid classification. Entries should be Phishing or Legitimate.';
	END IF;
END $$
DELIMITER ; 

INSERT INTO Labels (email_id, classification, risk_score, labeled_by)
VALUES (5, 'Phishing', 92.50, 1);

SELECT *
FROM Labels
WHERE email_id = 5;

INSERT INTO Labels (email_id, classification, risk_score, labeled_by)
VALUES (6, 'Spam', 80.00, 2);


-- Stored Procedure Implementation

DROP PROCEDURE IF EXISTS sp_add_email_with_features;
DELIMITER $$
CREATE PROCEDURE sp_add_email_with_features(
										IN p_sender VARCHAR(200),
                                        IN p_receiver VARCHAR(200),
                                        IN p_subject VARCHAR(500),
                                        IN p_body TEXT,
                                        IN p_domain_id INT,
                                        IN p_ip_id INT,
                                        IN p_url_count VARCHAR(10),
                                        IN p_has_attach VARCHAR(5),
                                        IN p_spf_fail VARCHAR(5),
                                        OUT p_new_email_id INT)
BEGIN
DECLARE
	EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        RESIGNAL;
	END;
    START TRANSACTION;
    
    INSERT INTO Emails (sender_email, receiver_email, subject, body_text, received_timestamp, domain_id, ip_id)
    VALUES (p_sender, p_receiver, p_subject, p_body, NOW(), p_domain_id, p_ip_id);
    
    SET p_new_email_id = LAST_INSERT_ID();
    
    INSERT INTO Email_Features(email_id, feature_type_id, feature_value) -- Feature Type ID: 1
    VALUES (p_new_email_id, 1, p_url_count);
    
    INSERT INTO Email_Features(email_id, feature_type_id, feature_value) -- Feature Type ID: 2
    VALUES (p_new_email_id, 2, p_has_attach);
    
    INSERT INTO Email_Features(email_id, feature_type_id, feature_value) -- Feature Type ID: 3
    VALUES (p_new_email_id, 3, p_spf_fail);
    
    COMMIT;
END$$
DELIMITER ;

CALL sp_add_email_with_features(
							'attacker@phish-credentials.org', 'victim@phishingdbms.ac.uk', 'Confirm Your Identity',
                            'Click the link to verify', 4, 1, '6', '1', '1', @new_id);
SELECT @new_id AS new_email_id;

DROP PROCEDURE IF EXISTS sp_submit_report;
DELIMITER $$
CREATE PROCEDURE sp_submit_report(
								IN p_email_id INT,
                                IN p_user_id INT,
                                IN p_reason VARCHAR(500))
BEGIN
	DECLARE v_domain_id INT;
    DECLARE v_report_count INT;
    
    INSERT INTO User_Reports(email_id, user_id, report_reason, report_date, status)
    VALUES (p_email_id, p_user_id, p_reason, CURRENT_DATE(), 'Pending');
    
    SELECT 
		e.domain_id INTO v_domain_id
    FROM Emails AS e 
    WHERE e.email_id = p_email_id;
    
    SELECT
		COUNT(*) INTO v_report_count
	FROM User_Reports AS ur
    JOIN Emails AS e
    ON ur.email_id = e.email_id
    WHERE e.domain_id = v_domain_id;
    
    IF v_report_count >= 3 THEN
		UPDATE Domains
        SET
			is_blacklisted = 'Y',
            risk_score = LEAST(risk_score + 5.00, 100.00),
            last_updated = CURRENT_DATE()
		WHERE domain_id = v_domain_id;
	END IF;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_update_model_accuracy;
DELIMITER $$
CREATE PROCEDURE sp_update_model_accuracy (IN p_model_id INT)
BEGIN
	DECLARE v_total INT;
    DECLARE v_correct INT;
    DECLARE v_accuracy DECIMAL(5, 4);
    
    SELECT 
		COUNT(*),
        SUM(predicted_label = actual_label)
	INTO v_total, v_correct
	FROM Model_Predictions
    WHERE model_id = p_model_id;
    
    IF v_total > 0 THEN
		SET v_accuracy = v_correct / v_total;
        UPDATE Detection_Models
			SET accuracy_score = v_accuracy
		WHERE model_id = p_model_id;
        SELECT CONCAT('Updated accuracy for model ', p_model_id, ' to ', ROUND(v_accuracy * 100, 2), '%') AS result;
	ELSE
		SELECT 'No predictions found for this model' AS result;
	END IF;
END $$
DELIMITER ;

SELECT * FROM Model_Predictions;

CALL sp_update_model_accuracy(1);
CALL sp_update_model_accuracy(2);

CALL sp_update_model_accuracy(4);

SELECT * FROM Detection_Models
WHERE model_id = 4;

SELECT
	COUNT(*) AS total,
    SUM(predicted_label = actual_label) AS correct_predictions,
    SUM(predicted_label = actual_label) / COUNT(*) AS accuracy
FROM Model_Predictions
WHERE model_id = 4;

DROP PROCEDURE IF EXISTS sp_process_pending_reports;
DELIMITER $$
CREATE PROCEDURE sp_process_pending_reports()
BEGIN
	DECLARE v_done INT DEFAULT 0;
    DECLARE v_report_id INT;
    DECLARE v_email_id INT;
    DECLARE v_domain_id INT;
    DECLARE v_processed INT DEFAULT 0;
    
    DECLARE cur_reports CURSOR FOR
		SELECT 
			report_id,
            email_id
		FROM User_Reports
        WHERE status = 'Pending';
        
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
	
    OPEN cur_reports;
    
    read_loop: LOOP
    
		FETCH cur_reports INTO v_report_id, v_email_id;
        IF v_done = 1 THEN
			LEAVE read_loop;
		END IF;
        
        SELECT domain_id INTO v_domain_id
        FROM Emails
        WHERE email_id = v_email_id;
        
        UPDATE Domains
		SET 
			risk_score = LEAST(risk_score + 2.00, 100.00),
			last_updated = CURRENT_DATE()
		WHERE domain_id = v_domain_id;
        
        UPDATE User_Reports
		SET	
			status = 'Reviewed'
		WHERE report_id = v_report_id;
        
        SET v_processed = v_processed + 1;
	
    END LOOP;
    
    CLOSE cur_reports;
    
    SELECT CONCAT(v_processed, ' pending reports processed.') AS processing_summary;
END $$
DELIMITER ;

SELECT * 
FROM User_Reports
WHERE status = 'Pending'

SELECT 
	e.email_id,
    d.domain_id,
    d.domain_name,
    d.risk_score
FROM Emails AS e
JOIN Domains AS d
ON e.domain_id = d.domain_id
WHERE e.email_id IN (SELECT email_id FROM User_Reports WHERE status = 'Pending');

CALL sp_process_pending_reports();

SELECT 
	report_id,
    email_id,
    status
FROM User_Reports;

SELECT
	e.email_id,
    d.domain_name,
    d.risk_score,
    d.last_updated
FROM Emails AS e
JOIN Domains AS d
ON e.domain_id = d.domain_id
WHERE 
	e.email_id IN (SELECT email_id FROM User_Reports)
    AND
    e.email_id = '10'

SELECT *
FROM User_Reports
WHERE status = 'Pending';

DROP PROCEDURE IF EXISTS sp_domain_risk_report;
DELIMITER $$
CREATE PROCEDURE sp_domain_risk_report()
BEGIN
	DECLARE v_done INT DEFAULT 0;
    DECLARE v_domain_id INT;
    DECLARE v_domain_name VARCHAR(255);
    DECLARE v_risk_score DECIMAL(5, 2);
    DECLARE v_email_count INT;
    
    DECLARE cur_domains CURSOR FOR
		SELECT 
			domain_id, 
            domain_name, 
            risk_score
		FROM Domains
        ORDER BY risk_score DESC;
	
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS tmp_domain_report(
														domain_name VARCHAR(255),
                                                        risk_score DECIMAL(5, 2),
                                                        email_count INT,
                                                        risk_category VARCHAR(20));
	TRUNCATE TABLE tmp_domain_report;
    
    OPEN cur_domains;
    
    domain_loop: LOOP
    
		FETCH cur_domains INTO v_domain_id, v_domain_name, v_risk_score;
        IF v_done = 1 THEN
			LEAVE domain_loop;
		END IF;
        
        SELECT COUNT(*) INTO v_email_count
        FROM Emails
        WHERE domain_id = v_domain_id;
        
        INSERT INTO tmp_domain_report
        VALUES (v_domain_name,
				v_risk_score,
                v_email_count,
                CASE
					WHEN v_risk_score >= 80 THEN 'High'
                    WHEN v_risk_score >= 40 THEN 'Medium'
                    ELSE 'Low'
				END);
	
    END LOOP; 
    
    CLOSE cur_domains;
    
    SELECT * FROM tmp_domain_report;
END $$
DELIMITER ; 

SELECT * 
FROM Domains;

SELECT
	e.email_id,
    e.domain_id,
    d.domain_name
FROM Emails AS e
JOIN Domains AS d
ON e.domain_id = d.domain_id;

CALL sp_domain_risk_report();
