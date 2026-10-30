-- Run once in MySQL Workbench as a privileged user (e.g. root).
-- Schema v2: 10 tables, 80 columns, 1,500 sample sales over the last 12 months.
CREATE DATABASE IF NOT EXISTS bi_demo;
USE bi_demo;

SET SESSION cte_max_recursion_depth = 5000;   -- the seed data below is generated with recursive CTEs
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS customer_feedback, sale_returns, sales, sales_targets, marketing_campaigns,
                     employees, customers, products, suppliers, regions;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------- reference tables
CREATE TABLE regions (
    region_id         INT PRIMARY KEY,
    name              VARCHAR(50)  NOT NULL,
    country           VARCHAR(50)  NOT NULL,
    headquarters_city VARCHAR(60)  NOT NULL,
    opened_on         DATE         NOT NULL
);

CREATE TABLE suppliers (
    supplier_id    INT PRIMARY KEY,
    name           VARCHAR(80)  NOT NULL,
    country        VARCHAR(50)  NOT NULL,
    contact_email  VARCHAR(100) NOT NULL,
    rating         DECIMAL(2,1) NOT NULL,          -- 1.0 to 5.0
    lead_time_days INT          NOT NULL,
    contract_start DATE         NOT NULL
);

CREATE TABLE products (
    product_id     INT PRIMARY KEY,
    sku            VARCHAR(20)   NOT NULL,
    name           VARCHAR(80)   NOT NULL,
    category       VARCHAR(50)   NOT NULL,
    brand          VARCHAR(50)   NOT NULL,
    supplier_id    INT           NOT NULL,
    price          DECIMAL(10,2) NOT NULL,
    cost_price     DECIMAL(10,2) NOT NULL,
    stock_quantity INT           NOT NULL,
    reorder_level  INT           NOT NULL,
    launch_date    DATE          NOT NULL,
    is_active      TINYINT(1)    NOT NULL DEFAULT 1,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

CREATE TABLE customers (
    customer_id  INT PRIMARY KEY,
    name         VARCHAR(80)  NOT NULL,
    email        VARCHAR(100) NOT NULL,
    phone        VARCHAR(20)  NOT NULL,
    city         VARCHAR(60)  NOT NULL,
    region_id    INT          NOT NULL,
    segment      VARCHAR(30)  NOT NULL,             -- Consumer / Corporate / Small Business
    loyalty_tier VARCHAR(20)  NOT NULL,             -- Bronze / Silver / Gold / Platinum
    signup_date  DATE         NOT NULL,
    is_active    TINYINT(1)   NOT NULL DEFAULT 1,
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

CREATE TABLE employees (
    employee_id     INT PRIMARY KEY,
    name            VARCHAR(80)  NOT NULL,
    email           VARCHAR(100) NOT NULL,
    role            VARCHAR(40)  NOT NULL,          -- Regional Manager / Sales Rep
    region_id       INT          NOT NULL,
    manager_id      INT          NULL,
    hire_date       DATE         NOT NULL,
    commission_rate DECIMAL(4,2) NOT NULL,          -- percent of sale amount
    FOREIGN KEY (region_id)  REFERENCES regions(region_id),
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

CREATE TABLE marketing_campaigns (
    campaign_id INT PRIMARY KEY,
    name        VARCHAR(80)   NOT NULL,
    channel     VARCHAR(40)   NOT NULL,             -- Email / Social Media / Search Ads / TV / Influencer
    region_id   INT           NULL,                 -- NULL = all regions
    start_date  DATE          NOT NULL,
    end_date    DATE          NOT NULL,
    budget      DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- ---------------------------------------------------------------- transaction tables
CREATE TABLE sales (
    sale_id          INT AUTO_INCREMENT PRIMARY KEY,
    order_ref        VARCHAR(20)   NOT NULL,
    product_id       INT           NOT NULL,
    customer_id      INT           NOT NULL,
    employee_id      INT           NOT NULL,
    region_id        INT           NOT NULL,
    campaign_id      INT           NULL,            -- NULL = not linked to a campaign
    quantity         INT           NOT NULL,
    unit_price       DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2)  NOT NULL DEFAULT 0,
    amount           DECIMAL(12,2) NOT NULL,        -- quantity * unit_price after discount
    payment_method   VARCHAR(30)   NOT NULL,        -- Card / UPI / Net Banking / Cash
    channel          VARCHAR(30)   NOT NULL,        -- Online / Retail Store / Distributor
    status           VARCHAR(20)   NOT NULL,        -- Completed / Pending / Returned / Cancelled
    sale_date        DATE          NOT NULL,
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (region_id)   REFERENCES regions(region_id),
    FOREIGN KEY (campaign_id) REFERENCES marketing_campaigns(campaign_id),
    INDEX idx_sale_date (sale_date),
    INDEX idx_sale_status (status)
);

CREATE TABLE sale_returns (
    return_id     INT AUTO_INCREMENT PRIMARY KEY,
    sale_id       INT           NOT NULL,
    return_date   DATE          NOT NULL,
    reason        VARCHAR(60)   NOT NULL,
    refund_amount DECIMAL(12,2) NOT NULL,
    restocked     TINYINT(1)    NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
);

CREATE TABLE customer_feedback (
    feedback_id   INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT          NOT NULL,
    product_id    INT          NOT NULL,
    rating        TINYINT      NOT NULL,            -- 1 (worst) to 5 (best)
    comment       VARCHAR(200) NOT NULL,
    feedback_date DATE         NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)  REFERENCES products(product_id)
);

CREATE TABLE sales_targets (
    target_id     INT AUTO_INCREMENT PRIMARY KEY,
    region_id     INT           NOT NULL,
    target_month  DATE          NOT NULL,           -- first day of the month
    target_amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (region_id) REFERENCES regions(region_id),
    UNIQUE KEY uq_region_month (region_id, target_month)
);

-- ---------------------------------------------------------------- seed data
INSERT INTO regions VALUES
 (1,'North',  'India','Delhi',    '2018-04-01'),
 (2,'South',  'India','Bengaluru','2017-06-15'),
 (3,'East',   'India','Kolkata',  '2019-01-10'),
 (4,'West',   'India','Mumbai',   '2016-09-01'),
 (5,'Central','India','Nagpur',   '2020-02-20');

INSERT INTO suppliers VALUES
 (1,'TechSource Ltd',      'China',  'sales@techsource.example',   4.5, 14,'2021-03-01'),
 (2,'PeripheralWorks',     'Taiwan', 'orders@periphworks.example', 4.2, 10,'2020-07-15'),
 (3,'OfficeCraft Furniture','India', 'hello@officecraft.example',  4.0,  7,'2019-11-01'),
 (4,'SoundWave Audio',     'Japan',  'b2b@soundwave.example',      4.8, 21,'2022-01-10'),
 (5,'NetLink Systems',     'USA',    'trade@netlink.example',      3.9, 18,'2021-09-01'),
 (6,'PaperTrail Supplies', 'India',  'bulk@papertrail.example',    3.7,  5,'2018-05-20');

INSERT INTO products VALUES
 ( 1,'ACC-001','Wireless Mouse',            'Accessories', 'ClickPro',  2,  19.99,  8.50, 240, 60,'2022-02-01',1),
 ( 2,'ACC-002','Mechanical Keyboard',       'Accessories', 'KeyForge',  2,  69.00, 32.00, 120, 40,'2022-05-10',1),
 ( 3,'ACC-003','USB-C Hub',                 'Accessories', 'PortMax',   1,  34.50, 15.00, 180, 50,'2022-08-20',1),
 ( 4,'ELE-001','Webcam HD',                 'Electronics', 'VisionCam', 1,  49.90, 22.00,  90, 30,'2021-11-05',1),
 ( 5,'FUR-001','Laptop Stand',              'Furniture',   'ErgoRise',  3,  27.00, 11.00, 150, 40,'2021-06-18',1),
 ( 6,'ELE-002','Monitor 24"',               'Electronics', 'ViewEdge',  1, 139.00, 92.00,  45, 20,'2021-04-02',1),
 ( 7,'FUR-002','Desk Lamp',                 'Furniture',   'LumiDesk',  3,  22.50,  9.00, 200, 50,'2020-10-12',1),
 ( 8,'ELE-003','Noise-Cancelling Headset',  'Electronics', 'SoundWave', 4,  89.00, 45.00,  70, 25,'2022-03-30',1),
 ( 9,'ACC-004','Bluetooth Speaker',         'Electronics', 'SoundWave', 4,  59.00, 28.00, 110, 30,'2023-01-15',1),
 (10,'NET-001','WiFi 6 Router',             'Networking',  'NetLink',   5,  79.00, 41.00,  60, 20,'2023-03-01',1),
 (11,'NET-002','Ethernet Switch 8-Port',    'Networking',  'NetLink',   5,  45.00, 24.00,  85, 25,'2022-12-05',1),
 (12,'OFF-001','Ergonomic Office Chair',    'Furniture',   'ErgoRise',  3, 189.00,105.00,  25, 10,'2022-09-09',1),
 (13,'OFF-002','Notebook Pack (5)',         'Office Supplies','PaperTrail',6,  12.00,  4.50, 500,120,'2020-02-14',1),
 (14,'OFF-003','Whiteboard 90x60',          'Office Supplies','PaperTrail',6,  64.00, 31.00,  40, 15,'2021-08-23',1),
 (15,'ACC-005','Laptop Backpack',           'Accessories', 'CarryOn',   2,  39.00, 17.00, 130, 35,'2023-05-02',1),
 (16,'ELE-004','Portable SSD 1TB',          'Electronics', 'DataVault', 1, 109.00, 66.00,  55, 20,'2023-06-12',0);

INSERT INTO employees VALUES
 ( 1,'Anita Rao',     'anita.rao@example.com',     'Regional Manager',1,NULL,'2017-05-01',2.00),
 ( 2,'Vikram Shetty', 'vikram.shetty@example.com', 'Regional Manager',2,NULL,'2016-08-15',2.00),
 ( 3,'Sourav Banerjee','sourav.b@example.com',     'Regional Manager',3,NULL,'2018-02-01',2.00),
 ( 4,'Meera Kulkarni','meera.k@example.com',       'Regional Manager',4,NULL,'2015-11-10',2.00),
 ( 5,'Rohit Deshmukh','rohit.d@example.com',       'Regional Manager',5,NULL,'2019-06-01',2.00),
 ( 6,'Karan Malhotra','karan.m@example.com',       'Sales Rep',1,1,'2020-01-13',3.50),
 ( 7,'Divya Nair',    'divya.n@example.com',       'Sales Rep',2,2,'2020-03-02',3.50),
 ( 8,'Arjun Sen',     'arjun.s@example.com',       'Sales Rep',3,3,'2021-07-19',3.00),
 ( 9,'Pooja Patil',   'pooja.p@example.com',       'Sales Rep',4,4,'2019-09-23',4.00),
 (10,'Sanjay Joshi',  'sanjay.j@example.com',      'Sales Rep',5,5,'2022-02-07',3.00),
 (11,'Neha Kapoor',   'neha.k@example.com',        'Sales Rep',1,1,'2021-04-12',3.50),
 (12,'Suresh Iyer',   'suresh.i@example.com',      'Sales Rep',2,2,'2022-10-03',3.00),
 (13,'Ishita Das',    'ishita.d@example.com',      'Sales Rep',3,3,'2022-05-16',3.00),
 (14,'Rahul Mehta',   'rahul.m@example.com',       'Sales Rep',4,4,'2023-01-09',3.50),
 (15,'Lata Bhosle',   'lata.b@example.com',        'Sales Rep',5,5,'2023-04-24',3.00);

INSERT INTO marketing_campaigns VALUES
 (1,'New Year Tech Sale',        'Email',        NULL, CURDATE() - INTERVAL 300 DAY, CURDATE() - INTERVAL 285 DAY,  8000.00),
 (2,'Work From Home Essentials', 'Social Media', NULL, CURDATE() - INTERVAL 250 DAY, CURDATE() - INTERVAL 220 DAY, 15000.00),
 (3,'Southern Festive Offer',    'TV',           2,    CURDATE() - INTERVAL 200 DAY, CURDATE() - INTERVAL 170 DAY, 22000.00),
 (4,'Monsoon Clearance',         'Search Ads',   4,    CURDATE() - INTERVAL 160 DAY, CURDATE() - INTERVAL 140 DAY,  9500.00),
 (5,'Back To Office',            'Email',        NULL, CURDATE() - INTERVAL 120 DAY, CURDATE() - INTERVAL 100 DAY,  7000.00),
 (6,'Influencer Gadget Week',    'Influencer',   1,    CURDATE() - INTERVAL  90 DAY, CURDATE() - INTERVAL  75 DAY, 12000.00),
 (7,'Festive Mega Sale',         'Social Media', NULL, CURDATE() - INTERVAL  60 DAY, CURDATE() - INTERVAL  30 DAY, 30000.00),
 (8,'Central India Roadshow',    'TV',           5,    CURDATE() - INTERVAL  40 DAY, CURDATE() - INTERVAL  20 DAY, 11000.00);

-- 60 customers spread over the 5 regions
INSERT INTO customers
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i+1 FROM n WHERE i < 60)
SELECT i,
       CONCAT('Customer ', i),
       CONCAT('customer', i, '@example.com'),
       CONCAT('+91-98', LPAD((i * 7919) % 100000000, 8, '0')),
       ELT(1 + (i-1) % 5, 'Delhi','Bengaluru','Kolkata','Mumbai','Nagpur'),
       1 + (i-1) % 5,
       ELT(1 + i % 3, 'Consumer','Corporate','Small Business'),
       ELT(1 + i % 4, 'Bronze','Silver','Gold','Platinum'),
       CURDATE() - INTERVAL (370 + (i * 13) % 500) DAY,
       (i % 11 <> 0)
FROM n;

-- 1,500 sample sales spread over the last 12 months
INSERT INTO sales (order_ref, product_id, customer_id, employee_id, region_id, campaign_id,
                   quantity, unit_price, discount_percent, amount, payment_method, channel, status, sale_date)
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i+1 FROM n WHERE i < 1500)
SELECT CONCAT('ORD-', LPAD(n.i, 5, '0')),
       p.product_id, c.customer_id,
       6 + (c.region_id - 1) + 5 * (n.i % 2),                          -- a sales rep from the customer's region
       c.region_id,
       CASE WHEN n.i % 4 = 0 THEN 1 + (n.i DIV 4) % 8 END,             -- ~25% of sales tied to a campaign
       1 + (n.i * 13 % 9),
       p.price,
       (n.i % 4 = 2) * 5 + (n.i % 4 = 3) * 10,                         -- 0, 0, 5 or 10 percent discount
       ROUND((1 + (n.i * 13 % 9)) * p.price * (1 - ((n.i % 4 = 2) * 5 + (n.i % 4 = 3) * 10) / 100), 2),
       ELT(1 + (n.i * 3) % 4, 'Card','UPI','Net Banking','Cash'),
       ELT(1 + (n.i * 5) % 3, 'Online','Retail Store','Distributor'),
       CASE WHEN n.i % 23 = 0 THEN 'Cancelled'
            WHEN n.i % 17 = 0 THEN 'Returned'
            WHEN n.i % 31 = 0 THEN 'Pending'
            ELSE 'Completed' END,
       CURDATE() - INTERVAL (n.i * 7 % 365) DAY
FROM n
JOIN products  p ON p.product_id  = 1 + ((n.i * 7 + n.i DIV 3) % 16)
JOIN customers c ON c.customer_id = 1 + (n.i * 11 % 60);

INSERT INTO sale_returns (sale_id, return_date, reason, refund_amount, restocked)
SELECT sale_id,
       LEAST(CURDATE(), sale_date + INTERVAL (3 + sale_id % 10) DAY),
       ELT(1 + sale_id % 4, 'Defective','Wrong item delivered','Not as described','Changed mind'),
       amount,
       (sale_id % 3 <> 0)
FROM sales
WHERE status = 'Returned';

-- 400 feedback rows
INSERT INTO customer_feedback (customer_id, product_id, rating, comment, feedback_date)
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i+1 FROM n WHERE i < 400),
     f AS (SELECT i, 1 + (i * 7 + i DIV 5) % 5 AS rating FROM n)
SELECT 1 + (i * 17 % 60),
       1 + (i * 5 % 16),
       rating,
       ELT(rating, 'Poor quality, would not buy again','Below expectations','Average, does the job',
                   'Good value for the price','Excellent product, highly recommended'),
       CURDATE() - INTERVAL (i * 9 % 360) DAY
FROM f;

-- monthly revenue targets per region for the last 12 months
INSERT INTO sales_targets (region_id, target_month, target_amount)
WITH RECURSIVE m AS (SELECT 0 AS k UNION ALL SELECT k+1 FROM m WHERE k < 11)
SELECT r.region_id,
       DATE_FORMAT(CURDATE() - INTERVAL m.k MONTH, '%Y-%m-01'),
       5000 + r.region_id * 150 + (m.k % 3) * 400
FROM m CROSS JOIN regions r;

-- Read-only account used by the Spring Boot app (SELECT only)
CREATE USER IF NOT EXISTS 'bi_readonly'@'localhost' IDENTIFIED BY 'ReadOnly_2026';
GRANT SELECT ON bi_demo.* TO 'bi_readonly'@'localhost';
FLUSH PRIVILEGES;
