-- Rollback: Remove driver-auth linking

-- Drop foreign key constraints
ALTER TABLE appeal_record DROP FOREIGN KEY fk_appeal_driver;
ALTER TABLE payment_record DROP FOREIGN KEY fk_payment_driver;
ALTER TABLE fine_record DROP FOREIGN KEY fk_fine_driver;
ALTER TABLE vehicle_information DROP FOREIGN KEY fk_vehicle_driver;

-- Drop indexes
DROP INDEX idx_appeal_driver_id ON appeal_record;
DROP INDEX idx_payment_driver_id ON payment_record;
DROP INDEX idx_fine_driver_id ON fine_record;
DROP INDEX idx_vehicle_driver_id ON vehicle_information;

-- Drop driver_id columns from business tables
ALTER TABLE appeal_record DROP COLUMN driver_id;
ALTER TABLE payment_record DROP COLUMN driver_id;
ALTER TABLE fine_record DROP COLUMN driver_id;
ALTER TABLE vehicle_information DROP COLUMN driver_id;

-- Drop constraints and column from driver_information
ALTER TABLE driver_information DROP FOREIGN KEY fk_driver_auth_user;
ALTER TABLE driver_information DROP INDEX uk_driver_information_auth_user;
ALTER TABLE driver_information DROP COLUMN auth_user_id;
