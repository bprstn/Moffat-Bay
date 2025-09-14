USE moffatbay;

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