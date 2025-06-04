-- Create the reservation database and grant ownership to amcloud_admin
CREATE DATABASE amcloud_reservation_db OWNER amcloud_admin;

-- Create the billing database and grant ownership to amcloud_admin
CREATE DATABASE amcloud_billing_db OWNER amcloud_admin;

-- Grant all privileges on the reservation database to amcloud_admin
GRANT ALL PRIVILEGES ON DATABASE amcloud_reservation_db TO amcloud_admin;

-- Grant all privileges on the billing database to amcloud_admin
GRANT ALL PRIVILEGES ON DATABASE amcloud_billing_db TO amcloud_admin;
