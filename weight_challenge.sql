CREATE DATABASE IF NOT EXISTS weight_challenge;
USE weight_challenge;

DROP TABLE IF EXISTS weight_measure;
DROP TABLE IF EXISTS bets;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
  customerId   INT PRIMARY KEY AUTO_INCREMENT,
  personalId   INT,
  customerName VARCHAR(100) NOT NULL,
  phoneNumber  VARCHAR(15)  NOT NULL
);

CREATE TABLE bets (
  betID        INT PRIMARY KEY AUTO_INCREMENT,
  customerID   INT NOT NULL,
  targetWeight INT NOT NULL,
  betAmount    DECIMAL(10,2) NOT NULL,
  startDate    DATE NOT NULL,
  endDate      DATE NOT NULL,
  CONSTRAINT fk_bets_customer
    FOREIGN KEY (customerID) REFERENCES customers(customerId)
);

CREATE TABLE weight_measure (
  measureId   INT PRIMARY KEY AUTO_INCREMENT,
  customerId  INT NOT NULL,
  betID       INT NOT NULL,
  measureDate DATE NOT NULL,          
  weight      INT NOT NULL,
  CONSTRAINT fk_weight_measure_customer
    FOREIGN KEY (customerId) REFERENCES customers(customerId),
  CONSTRAINT fk_weight_measure_bet
    FOREIGN KEY (betID) REFERENCES bets(betID)
);

INSERT INTO customers (personalId, customerName, phoneNumber) VALUES
(453525325, 'LOL KEK', '111-3234'),
(525233333, 'teest TEST', '222-5373');

INSERT INTO bets (targetWeight, customerID, betAmount, startDate, endDate) VALUES
(222, 1, 100.00, '2007-01-01', '2007-06-01'),
(333, 2, 300.00, '2007-02-01', '2007-07-01');

INSERT INTO weight_measure (customerId, betID, measureDate, weight) VALUES
(1, 1, '2007-01-01', 170),
(1, 1, '2007-02-02', 160),
(2, 2, '2007-03-03', 200),
(2, 2, '2007-04-04', 185);

SELECT * FROM customers;
SELECT * FROM bets;
SELECT * FROM weight_measure;

SELECT *
FROM customers
LEFT JOIN bets ON customers.customerId = bets.customerID;

SELECT c.customerName, b.betID, w.measureDate, w.weight
FROM customers c
JOIN bets b ON c.customerId = b.customerID
JOIN weight_measure w ON w.betID = b.betID
ORDER BY c.customerId, w.measureDate;
