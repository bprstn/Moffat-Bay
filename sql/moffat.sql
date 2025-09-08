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
