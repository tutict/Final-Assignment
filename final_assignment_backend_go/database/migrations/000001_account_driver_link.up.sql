-- Migration: Link driver_information to auth user
-- Purpose: Connect drivers with authentication system

-- Add auth_user_id to driver_information
ALTER TABLE driver_information
ADD COLUMN auth_user_id BIGINT DEFAULT NULL COMMENT 'Link to sys_user for authentication';

-- Create unique constraint on auth_user_id
ALTER TABLE driver_information
ADD UNIQUE KEY uk_driver_information_auth_user (auth_user_id);

-- Create foreign key constraint
ALTER TABLE driver_information
ADD CONSTRAINT fk_driver_auth_user
    FOREIGN KEY (auth_user_id) REFERENCES sys_user(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- Add driver_id to business tables for direct driver reference
ALTER TABLE vehicle_information
ADD COLUMN driver_id BIGINT DEFAULT NULL COMMENT 'Driver ID reference';

ALTER TABLE fine_record
ADD COLUMN driver_id BIGINT DEFAULT NULL COMMENT 'Driver ID reference';

ALTER TABLE payment_record
ADD COLUMN driver_id BIGINT DEFAULT NULL COMMENT 'Driver ID reference';

ALTER TABLE appeal_record
ADD COLUMN driver_id BIGINT DEFAULT NULL COMMENT 'Driver ID reference';

-- Create indexes for performance
CREATE INDEX idx_vehicle_driver_id ON vehicle_information(driver_id);
CREATE INDEX idx_fine_driver_id ON fine_record(driver_id);
CREATE INDEX idx_payment_driver_id ON payment_record(driver_id);
CREATE INDEX idx_appeal_driver_id ON appeal_record(driver_id);

-- Add foreign key constraints
ALTER TABLE vehicle_information
ADD CONSTRAINT fk_vehicle_driver
    FOREIGN KEY (driver_id) REFERENCES driver_information(driver_id)
    ON DELETE SET NULL;

ALTER TABLE fine_record
ADD CONSTRAINT fk_fine_driver
    FOREIGN KEY (driver_id) REFERENCES driver_information(driver_id)
    ON DELETE SET NULL;

ALTER TABLE payment_record
ADD CONSTRAINT fk_payment_driver
    FOREIGN KEY (driver_id) REFERENCES driver_information(driver_id)
    ON DELETE SET NULL;

ALTER TABLE appeal_record
ADD CONSTRAINT fk_appeal_driver
    FOREIGN KEY (driver_id) REFERENCES driver_information(driver_id)
    ON DELETE SET NULL;
