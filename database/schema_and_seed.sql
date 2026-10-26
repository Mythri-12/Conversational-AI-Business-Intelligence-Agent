-- Run once in MySQL Workbench as a privileged user (e.g. root).
CREATE DATABASE IF NOT EXISTS bi_demo;
USE bi_demo;
DROP TABLE IF EXISTS sales, customers, products, regions;

CREATE TABLE regions   (region_id INT PRIMARY KEY, name VARCHAR(50) NOT NULL);
CREATE TABLE products  (product_id INT PRIMARY KEY, name VARCHAR(80) NOT NULL, category VARCHAR(50) NOT NULL, price DECIMAL(10,2) NOT NULL);
CREATE TABLE customers (customer_id INT PRIMARY KEY, name VARCHAR(80) NOT NULL, region_id INT NOT NULL,
                        FOREIGN KEY (region_id) REFERENCES regions(region_id));
CREATE TABLE sales     (sale_id INT AUTO_INCREMENT PRIMARY KEY, product_id INT NOT NULL, customer_id INT NOT NULL,
                        region_id INT NOT NULL, quantity INT NOT NULL, amount DECIMAL(12,2) NOT NULL, sale_date DATE NOT NULL,
                        FOREIGN KEY (product_id)  REFERENCES products(product_id),
                        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
                        FOREIGN KEY (region_id)   REFERENCES regions(region_id),
                        INDEX idx_sale_date (sale_date));

INSERT INTO regions VALUES (1,'North'),(2,'South'),(3,'East'),(4,'West'),(5,'Central');
INSERT INTO products VALUES
 (1,'Wireless Mouse','Accessories',19.99),(2,'Mechanical Keyboard','Accessories',69.00),
 (3,'USB-C Hub','Accessories',34.50),(4,'Webcam HD','Electronics',49.90),
 (5,'Laptop Stand','Furniture',27.00),(6,'Monitor 24"','Electronics',139.00),
 (7,'Desk Lamp','Furniture',22.50),(8,'Noise-Cancelling Headset','Electronics',89.00);

INSERT INTO customers
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i+1 FROM n WHERE i < 20)
SELECT i, CONCAT('Customer ', i), 1 + (i-1) % 5 FROM n;

-- 900 sample sales spread over the last 12 months
INSERT INTO sales (product_id, customer_id, region_id, quantity, amount, sale_date)
WITH RECURSIVE n AS (SELECT 1 AS i UNION ALL SELECT i+1 FROM n WHERE i < 900)
SELECT p.product_id, c.customer_id, c.region_id,
       1 + (n.i*13 % 9), (1 + (n.i*13 % 9)) * p.price, CURDATE() - INTERVAL (n.i*7 % 365) DAY
FROM n
JOIN products  p ON p.product_id  = 1 + ((n.i*7 + n.i DIV 3) % 8)
JOIN customers c ON c.customer_id = 1 + (n.i*11 % 20);

-- Read-only account used by the Spring Boot app (SELECT only)
CREATE USER IF NOT EXISTS 'bi_readonly'@'localhost' IDENTIFIED BY 'ReadOnly_2026';
GRANT SELECT ON bi_demo.* TO 'bi_readonly'@'localhost';
FLUSH PRIVILEGES;
