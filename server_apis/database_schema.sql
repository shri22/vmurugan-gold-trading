-- V Murugan Gold Trading Database Schema
-- Created for production deployment with Omniware payment gateway
-- Updated with complete portfolio and transaction management

-- Create database
CREATE DATABASE IF NOT EXISTS vmurugan_gold_trading;
USE vmurugan_gold_trading;

-- Users table - Complete user management
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    phone VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    encrypted_mpin VARCHAR(255) NOT NULL,
    address TEXT,
    pan_card VARCHAR(20),
    device_id VARCHAR(100),
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_phone (phone),
    INDEX idx_email (email),
    INDEX idx_status (status)
);

-- Portfolio table - User holdings
CREATE TABLE portfolio (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE NOT NULL,
    total_gold_grams DECIMAL(10,4) DEFAULT 0,
    total_silver_grams DECIMAL(10,4) DEFAULT 0,
    total_invested DECIMAL(12,2) DEFAULT 0,
    current_value DECIMAL(12,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);

-- Transactions table - Complete transaction tracking
CREATE TABLE transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    transaction_id VARCHAR(50) UNIQUE NOT NULL,
    type ENUM('BUY', 'SELL') NOT NULL,
    metal_type ENUM('GOLD', 'SILVER') NOT NULL,
    quantity DECIMAL(10,4) NOT NULL,
    price_per_gram DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50),
    payment_status ENUM('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED') DEFAULT 'PENDING',
    gateway_transaction_id VARCHAR(100),
    callback_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_user_id (user_id),
    INDEX idx_payment_status (payment_status),
    INDEX idx_metal_type (metal_type),
    INDEX idx_created_at (created_at)
);

-- Notifications table - User notifications
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('TRANSACTION', 'PRICE_ALERT', 'SYSTEM', 'PROMOTION') DEFAULT 'SYSTEM',
    is_read BOOLEAN DEFAULT FALSE,
    data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- Price history table - Track price changes
CREATE TABLE price_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    metal_type ENUM('GOLD', 'SILVER') NOT NULL,
    price_per_gram DECIMAL(10,2) NOT NULL,
    source VARCHAR(50) DEFAULT 'MJDTA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_metal_type (metal_type),
    INDEX idx_created_at (created_at)
);

-- Sample data for testing
INSERT INTO users (phone, name, email, encrypted_mpin) VALUES
('9876543210', 'Test User', 'test@example.com', 'encrypted_test_mpin_1234');

INSERT INTO portfolio (user_id, total_gold_grams, total_silver_grams, total_invested, current_value) VALUES
(1, 0, 0, 0, 0);

-- Portfolio table
CREATE TABLE portfolio (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    transaction_id INT NOT NULL,
    gold_quantity DECIMAL(10,4) NOT NULL,
    purchase_price DECIMAL(10,2) NOT NULL,
    current_price DECIMAL(10,2),
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('ACTIVE', 'SOLD') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);

-- Gold prices table
CREATE TABLE gold_prices (
    id INT PRIMARY KEY AUTO_INCREMENT,
    price_per_gram DECIMAL(10,2) NOT NULL,
    price_source VARCHAR(50) DEFAULT 'MJDTA',
    location VARCHAR(50) DEFAULT 'Chennai',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created_at (created_at)
);

-- Notifications table
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('PAYMENT', 'PRICE_ALERT', 'GENERAL') DEFAULT 'GENERAL',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- Payment gateway logs table
CREATE TABLE payment_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id VARCHAR(50) NOT NULL,
    request_data JSON,
    response_data JSON,
    callback_data JSON,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order_id (order_id),
    INDEX idx_created_at (created_at)
);

-- App configuration table
CREATE TABLE app_config (
    id INT PRIMARY KEY AUTO_INCREMENT,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_config_key (config_key)
);

-- Insert default configuration
INSERT INTO app_config (config_key, config_value, description) VALUES
('omniware_merchant_id', 'TEST_MERCHANT_ID', 'Omniware Merchant ID'),
('omniware_environment', 'test', 'Payment gateway environment (test/live)'),
('gold_price_source', 'MJDTA', 'Gold price data source'),
('min_investment_amount', '100', 'Minimum investment amount in INR'),
('max_investment_amount', '100000', 'Maximum investment amount in INR'),
('app_version', '1.0.0', 'Current app version'),
('maintenance_mode', 'false', 'App maintenance mode flag');

-- Insert sample gold price
INSERT INTO gold_prices (price_per_gram, price_source, location) VALUES
(6500.00, 'MJDTA', 'Chennai');

-- Create indexes for better performance
CREATE INDEX idx_transactions_user_status ON transactions(user_id, status);
CREATE INDEX idx_portfolio_user_status ON portfolio(user_id, status);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);

-- Create views for common queries
CREATE VIEW user_portfolio_summary AS
SELECT 
    u.id as user_id,
    u.name,
    u.phone,
    u.gold_balance,
    u.total_investment,
    COUNT(p.id) as total_purchases,
    SUM(p.gold_quantity) as total_gold_quantity,
    AVG(p.purchase_price) as avg_purchase_price
FROM users u
LEFT JOIN portfolio p ON u.id = p.user_id AND p.status = 'ACTIVE'
GROUP BY u.id;

CREATE VIEW transaction_summary AS
SELECT 
    DATE(created_at) as transaction_date,
    COUNT(*) as total_transactions,
    SUM(CASE WHEN status = 'COMPLETED' THEN amount ELSE 0 END) as completed_amount,
    SUM(CASE WHEN status = 'PENDING' THEN amount ELSE 0 END) as pending_amount,
    SUM(CASE WHEN status = 'FAILED' THEN amount ELSE 0 END) as failed_amount
FROM transactions
GROUP BY DATE(created_at)
ORDER BY transaction_date DESC;

-- Sample data for testing
INSERT INTO users (phone, mpin, name, email) VALUES
('9876543210', '$2y$10$example_hashed_mpin', 'Test User', 'test@example.com');

-- Grant permissions (adjust username/password as needed)
-- GRANT ALL PRIVILEGES ON gold_trading.* TO 'gold_user'@'localhost' IDENTIFIED BY 'secure_password';
-- FLUSH PRIVILEGES;
