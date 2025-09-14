-- Create database
CREATE DATABASE IF NOT EXISTS moffatbay
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE moffatbay;


-- Table: customers
CREATE TABLE IF NOT EXISTS customers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name  VARCHAR(100) NOT NULL,
  phone VARCHAR(30),
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- Table: room_types
CREATE TABLE IF NOT EXISTS room_types (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,                
  name VARCHAR(150) NOT NULL,                      
  nightly_rate DECIMAL(10,2) NOT NULL,
  capacity INT NOT NULL,                           
  inventory_count INT NOT NULL,                    
  description TEXT
) ENGINE=InnoDB;


-- Table: reservations
CREATE TABLE IF NOT EXISTS reservations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT UNSIGNED NOT NULL,
  room_type_id BIGINT UNSIGNED NOT NULL,
  check_in DATE NOT NULL,
  check_out DATE NOT NULL,
  guests INT NOT NULL,
  status ENUM('PENDING','CONFIRMED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  rate_at_booking DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_res_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT fk_res_roomtype
    FOREIGN KEY (room_type_id) REFERENCES room_types(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,

  CONSTRAINT chk_dates CHECK (check_in < check_out),
  CONSTRAINT chk_guests CHECK (guests > 0)
) ENGINE=InnoDB;

-- Helpful indexes for lookups & availability checks
CREATE INDEX idx_res_customer ON reservations (customer_id, created_at);
CREATE INDEX idx_res_avail    ON reservations (room_type_id, check_in, check_out);

-- Create dedicated user for moffatbay DB
-- (Run as root or admin account)
CREATE USER IF NOT EXISTS 'moffatbay'@'localhost' IDENTIFIED BY 'moffatbay';

GRANT ALL PRIVILEGES ON moffatbay.* TO 'moffatbay'@'localhost';

FLUSH PRIVILEGES;

-- Insert Customers
INSERT INTO customers (email, first_name, last_name, phone, password_hash)
VALUES
  ('anton@example.com',   'Anton',   'Smith',   '555-1010', 'hashAnton123'),
  ('brian@example.com',   'Brian',   'Johnson', '555-2020', 'hashBrian123'),
  ('colton@example.com',  'Colton',  'Miller',  '555-3030', 'hashColton123'),
  ('brett@example.com',   'Brett',   'Davis',   '555-4040', 'hashBrett123');


-- Insert Room Types
INSERT INTO room_types (code, name, nightly_rate, capacity, inventory_count, description)
VALUES
  ('STD-QN', 'Standard Queen',   99.99, 2, 10, 'Basic queen room, simple comfort'),
  ('DLX-KG', 'Deluxe King',     149.99, 2, 5,  'Spacious king room with view'),
  ('FAM-SU', 'Family Suite',    199.99, 4, 3,  'Two-room suite with living space'),
  ('LUX-PH', 'Luxury Penthouse',399.99, 6, 1,  'Top floor, premium amenities');


-- test Reservations

-- Anton books a Standard Queen
INSERT INTO reservations (customer_id, room_type_id, check_in, check_out, guests, status, rate_at_booking, total_price)
VALUES
  (1, 1, '2025-09-01', '2025-09-05', 2, 'CONFIRMED', 99.99, 99.99*4);

-- Brian books a Deluxe King
INSERT INTO reservations (customer_id, room_type_id, check_in, check_out, guests, status, rate_at_booking, total_price)
VALUES
  (2, 2, '2025-09-10', '2025-09-12', 2, 'PENDING', 149.99, 149.99*2);

-- Colton books the Family Suite
INSERT INTO reservations (customer_id, room_type_id, check_in, check_out, guests, status, rate_at_booking, total_price)
VALUES
  (3, 3, '2025-09-15', '2025-09-20', 4, 'CONFIRMED', 199.99, 199.99*5);

-- Brett books the Penthouse
INSERT INTO reservations (customer_id, room_type_id, check_in, check_out, guests, status, rate_at_booking, total_price)
VALUES
  (4, 4, '2025-09-25', '2025-09-28', 2, 'CANCELLED', 399.99, 399.99*3);