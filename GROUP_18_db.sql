DROP TABLE IF EXISTS service_detail;
DROP TABLE IF EXISTS service;
DROP TABLE IF EXISTS receipt;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS booking;
DROP TABLE IF EXISTS vehicle;
DROP TABLE IF EXISTS vehicle_type;
DROP TABLE IF EXISTS membership;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS role;
DROP TABLE IF EXISTS branch;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS service_type;

USE washflow; 

CREATE TABLE branch (
    branch_ID INT PRIMARY KEY AUTO_INCREMENT,
    branch_name VARCHAR(100) NOT NULL,
    branch_address VARCHAR(255) NOT NULL  
);

CREATE TABLE customer (
    cust_ID INT PRIMARY KEY AUTO_INCREMENT,
    cust_fname VARCHAR(100) NOT NULL,
    cust_lname VARCHAR(100) NOT NULL,
    cust_tel VARCHAR(20) NOT NULL, 
    cust_address VARCHAR(255),
    cust_username VARCHAR(50) NOT NULL UNIQUE,
    cust_password VARCHAR(255) NOT NULL
);

CREATE TABLE role (
    role_ID INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(100) NOT NULL UNIQUE,
    role_salary DECIMAL(10,2) NOT NULL  
);

CREATE TABLE employee (
    emp_ID INT PRIMARY KEY AUTO_INCREMENT,
    emp_fname VARCHAR(100) NOT NULL,
    emp_lname VARCHAR(100) NOT NULL,
    emp_address VARCHAR(255),
    emp_username VARCHAR(50) NOT NULL UNIQUE,
    emp_password VARCHAR(255) NOT NULL,
    branch_ID INT NOT NULL,
    role_ID INT NOT NULL,

    FOREIGN KEY (branch_ID) REFERENCES branch(branch_ID),
    FOREIGN KEY (role_ID) REFERENCES role(role_ID)
);

CREATE TABLE vehicle_type (
    vehicletype_ID INT PRIMARY KEY AUTO_INCREMENT,
    vehicletype_name VARCHAR(50) NOT NULL,
    vehicletype_multiplier DECIMAL(3,2) NOT NULL 
);

CREATE TABLE service_type (
    serviceType_ID INT PRIMARY KEY AUTO_INCREMENT,
    serviceType_Name VARCHAR(100) NOT NULL,
    serviceType_BasePrice DECIMAL(10,2) NOT NULL
);

CREATE TABLE membership (
    membership_ID INT PRIMARY KEY AUTO_INCREMENT,
    membership_name VARCHAR(100) NOT NULL,
    membership_description TEXT,
    membership_point INT DEFAULT 0 NOT NULL, 
    cust_ID INT NOT NULL UNIQUE,

    FOREIGN KEY (cust_ID) REFERENCES customer(cust_ID)
);

CREATE TABLE vehicle (
    vehicle_ID INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_plate VARCHAR(20) NOT NULL UNIQUE, 
    vehicle_color VARCHAR(50),
    cust_ID INT NOT NULL,
    vehicletype_ID INT NOT NULL,

    FOREIGN KEY (cust_ID) REFERENCES customer(cust_ID),
    FOREIGN KEY (vehicletype_ID) REFERENCES vehicle_type(vehicletype_ID)
);

CREATE TABLE booking (
    booking_ID INT PRIMARY KEY AUTO_INCREMENT,
    booking_date DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL, 
    booking_status VARCHAR(50) DEFAULT 'pending' NOT NULL, 
    cust_ID INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (cust_ID) REFERENCES customer(cust_ID)
);

CREATE TABLE payment (
    payment_ID INT PRIMARY KEY AUTO_INCREMENT,
    payment_amount DECIMAL(10,2) NOT NULL, 
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,  
    payment_method VARCHAR(50) NOT NULL,
    booking_ID INT NOT NULL UNIQUE,

    FOREIGN KEY (booking_ID) REFERENCES booking(booking_ID)
);

CREATE TABLE service (
    service_ID INT PRIMARY KEY AUTO_INCREMENT,
    service_status VARCHAR(50) DEFAULT 'in_progress' NOT NULL, 
    service_startdate DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,  
    service_finishdate DATETIME,
    booking_ID INT NOT NULL,
    vehicle_ID INT NOT NULL,

    FOREIGN KEY (booking_ID) REFERENCES booking(booking_ID),
    FOREIGN KEY (vehicle_ID) REFERENCES vehicle(vehicle_ID)
);

CREATE TABLE receipt (
    receipt_ID INT PRIMARY KEY AUTO_INCREMENT,
    receipt_number VARCHAR(20) NOT NULL UNIQUE,  
    receipt_date DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL, 
    receipt_description TEXT,
    payment_ID INT NOT NULL UNIQUE,

    FOREIGN KEY (payment_ID) REFERENCES payment(payment_ID)
);

CREATE TABLE service_detail (
    sdetail_ID INT PRIMARY KEY AUTO_INCREMENT,
    sdetail_quantity INT DEFAULT 1 NOT NULL, 
    sdetail_price DECIMAL(10,2) NOT NULL,  

    service_ID INT NOT NULL,
    serviceType_ID INT NOT NULL,
    emp_ID INT NOT NULL,

    FOREIGN KEY (service_ID) REFERENCES service(service_ID),
    FOREIGN KEY (serviceType_ID) REFERENCES service_type(serviceType_ID),
    FOREIGN KEY (emp_ID) REFERENCES employee(emp_ID)
);

DROP VIEW IF EXISTS service_detail_summary_view;
DROP VIEW IF EXISTS service_progress_view;
DROP VIEW IF EXISTS payment_receipt_view;
DROP VIEW IF EXISTS active_services_view;
DROP VIEW IF EXISTS booking_summary_view;
DROP VIEW IF EXISTS employee_branch_role_view;
DROP VIEW IF EXISTS customer_vehicles_view;
DROP VIEW IF EXISTS customer_membership_view;
DROP VIEW IF EXISTS branch_booking_count_view;
DROP VIEW IF EXISTS service_type_pricing_view;

USE washflow; 

-- 1. Customer Membership View
CREATE VIEW customer_membership_view AS
SELECT 
    c.cust_ID,
    CONCAT(c.cust_fname, ' ', c.cust_lname) AS customer_name,
    c.cust_tel,
    c.cust_address,
    c.cust_username,
    m.membership_ID,
    m.membership_name,
    m.membership_point,
    m.membership_description
FROM customer c
LEFT JOIN membership m ON c.cust_ID = m.cust_ID;

-- 2. Customer Vehicles View
CREATE VIEW customer_vehicles_view AS
SELECT 
    c.cust_ID,
    CONCAT(c.cust_fname, ' ', c.cust_lname) AS customer_name,
    c.cust_tel,
    v.vehicle_ID,
    v.vehicle_plate,
    v.vehicle_color,
    vt.vehicletype_name,
    vt.vehicletype_multiplier
FROM customer c
JOIN vehicle v ON c.cust_ID = v.cust_ID
JOIN vehicle_type vt ON v.vehicletype_ID = vt.vehicletype_ID;

-- 3. Employee Branch Role View
CREATE VIEW employee_branch_role_view AS
SELECT 
    e.emp_ID,
    CONCAT(e.emp_fname, ' ', e.emp_lname) AS employee_name,
    e.emp_address,
    e.emp_username,
    r.role_name,
    r.role_salary,
    b.branch_name,
    b.branch_address,
    b.branch_ID,
    r.role_ID
FROM employee e
JOIN branch b ON e.branch_ID = b.branch_ID
JOIN role r ON e.role_ID = r.role_ID;

-- 4. Booking Summary View
CREATE VIEW booking_summary_view AS
SELECT DISTINCT
    b.booking_ID,
    b.booking_date,
    b.booking_status,
    b.created_at,
    b.updated_at,
    CONCAT(c.cust_fname, ' ', c.cust_lname) AS customer_name,
    c.cust_tel,
    c.cust_ID,
    br.branch_name,
    br.branch_address,
    br.branch_ID
FROM booking b
JOIN customer c ON b.cust_ID = c.cust_ID
LEFT JOIN service s ON b.booking_ID = s.booking_ID
LEFT JOIN service_detail sd ON s.service_ID = sd.service_ID
LEFT JOIN employee e ON sd.emp_ID = e.emp_ID
LEFT JOIN branch br ON e.branch_ID = br.branch_ID;

-- 5. Service Progress View
CREATE VIEW service_progress_view AS
SELECT DISTINCT
    s.service_ID,
    s.service_status,
    s.service_startdate,
    s.service_finishdate,
    v.vehicle_plate,
    v.vehicle_color,
    vt.vehicletype_name,
    b.booking_ID,
    CONCAT(c.cust_fname, ' ', c.cust_lname) AS customer_name,
    c.cust_tel,
    br.branch_name,
    br.branch_ID
FROM service s
JOIN vehicle v ON s.vehicle_ID = v.vehicle_ID
JOIN vehicle_type vt ON v.vehicletype_ID = vt.vehicletype_ID
JOIN booking b ON s.booking_ID = b.booking_ID
JOIN customer c ON b.cust_ID = c.cust_ID
LEFT JOIN service_detail sd ON s.service_ID = sd.service_ID
LEFT JOIN employee e ON sd.emp_ID = e.emp_ID
LEFT JOIN branch br ON e.branch_ID = br.branch_ID;

-- 6. Payment Receipt View
CREATE VIEW payment_receipt_view AS
SELECT DISTINCT
    p.payment_ID,
    p.payment_amount,
    p.payment_date,
    p.payment_method,
    p.booking_ID,
    r.receipt_ID,
    r.receipt_number,
    r.receipt_date,
    r.receipt_description,
    br.branch_name,
    br.branch_ID,
    CONCAT(c.cust_fname, ' ', c.cust_lname) AS customer_name
FROM payment p
LEFT JOIN receipt r ON p.payment_ID = r.payment_ID
JOIN booking b ON p.booking_ID = b.booking_ID
JOIN customer c ON b.cust_ID = c.cust_ID
LEFT JOIN service s ON b.booking_ID = s.booking_ID
LEFT JOIN service_detail sd ON s.service_ID = sd.service_ID
LEFT JOIN employee e ON sd.emp_ID = e.emp_ID
LEFT JOIN branch br ON e.branch_ID = br.branch_ID;

-- 7. Service Detail Summary View
CREATE VIEW service_detail_summary_view AS
SELECT 
    sd.sdetail_ID,
    s.service_ID,
    st.serviceType_Name,
    st.serviceType_BasePrice,
    sd.sdetail_quantity,
    sd.sdetail_price,
    CONCAT(e.emp_fname, ' ', e.emp_lname) AS employee_name,
    e.emp_ID,
    v.vehicle_plate,
    v.vehicle_color,
    vt.vehicletype_name,
    br.branch_name,
    br.branch_ID,
    CONCAT(c.cust_fname, ' ', c.cust_lname) AS customer_name,
    c.cust_ID
FROM service_detail sd
JOIN service_type st ON sd.serviceType_ID = st.serviceType_ID
JOIN employee e ON sd.emp_ID = e.emp_ID
JOIN branch br ON e.branch_ID = br.branch_ID
JOIN service s ON sd.service_ID = s.service_ID
JOIN vehicle v ON s.vehicle_ID = v.vehicle_ID
JOIN vehicle_type vt ON v.vehicletype_ID = vt.vehicletype_ID
JOIN booking b ON s.booking_ID = b.booking_ID
JOIN customer c ON b.cust_ID = c.cust_ID;

-- 8. Branch Booking Count View
CREATE VIEW branch_booking_count_view AS
SELECT 
    b.branch_ID,
    b.branch_name,
    b.branch_address,
    COUNT(DISTINCT bk.booking_ID) AS total_bookings,
    SUM(CASE WHEN bk.booking_status = 'completed' THEN 1 ELSE 0 END) AS completed_bookings,
    SUM(CASE WHEN bk.booking_status = 'pending' THEN 1 ELSE 0 END) AS pending_bookings,
    SUM(CASE WHEN bk.booking_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_bookings
FROM branch b
LEFT JOIN employee e ON b.branch_ID = e.branch_ID
LEFT JOIN service_detail sd ON e.emp_ID = sd.emp_ID
LEFT JOIN service s ON sd.service_ID = s.service_ID
LEFT JOIN booking bk ON s.booking_ID = bk.booking_ID
GROUP BY b.branch_ID, b.branch_name, b.branch_address;

-- 9. Service Type Pricing View
CREATE VIEW service_type_pricing_view AS
SELECT 
    st.serviceType_ID,
    st.serviceType_Name,
    st.serviceType_BasePrice,
    vt.vehicletype_ID,
    vt.vehicletype_name,
    vt.vehicletype_multiplier,
    ROUND(st.serviceType_BasePrice * vt.vehicletype_multiplier, 2) AS calculated_price
FROM service_type st
CROSS JOIN vehicle_type vt
ORDER BY st.serviceType_Name, vt.vehicletype_name;

-- 10. Active Services View
CREATE VIEW active_services_view AS
SELECT DISTINCT
    s.service_ID,
    CONCAT(c.cust_fname, ' ', c.cust_lname) AS customer_name,
    c.cust_tel,
    v.vehicle_plate,
    v.vehicle_color,
    vt.vehicletype_name,
    s.service_status,
    s.service_startdate,
    br.branch_name,
    br.branch_ID
FROM service s
JOIN vehicle v ON s.vehicle_ID = v.vehicle_ID
JOIN vehicle_type vt ON v.vehicletype_ID = vt.vehicletype_ID
JOIN booking b ON s.booking_ID = b.booking_ID
JOIN customer c ON b.cust_ID = c.cust_ID
LEFT JOIN service_detail sd ON s.service_ID = sd.service_ID
LEFT JOIN employee e ON sd.emp_ID = e.emp_ID
LEFT JOIN branch br ON e.branch_ID = br.branch_ID
WHERE s.service_status = 'in_progress';