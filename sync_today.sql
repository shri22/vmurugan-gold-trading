
-- sync_today.sql

-- 1. Sync Customers
IF NOT EXISTS (SELECT 1 FROM customers WHERE phone = '7603861139') 
INSERT INTO customers (customer_id, name, phone, email, address, pan_card, mpin, is_active, created_at) 
VALUES ('VM97', N'Rupa', '7603861139', 'rupajaya45@gmal.com', N'Chinna noolahalli', 'KADPD5170B', '73ea20db003a66add4bb622c26175fc7a42b5e0ad8386c7ac8a68991ac3d2c06', 1, '2026-01-09 16:57:16.749');

IF NOT EXISTS (SELECT 1 FROM customers WHERE phone = '9952649996') 
INSERT INTO customers (customer_id, name, phone, email, address, pan_card, mpin, is_active, created_at) 
VALUES ('VM98', N'muniraj', '9952649996', 'rmuni3194@gmail.com', N'thldlappavu muthali street ANNASAGARAM dharmapuri', 'DIYPM0323K', '013fa583d221782bb8436193785ec6d30e3e9cbda7a13031f9cc3faa1aff113a', 1, '2026-01-09 18:28:26.819');

-- 2. Sync Schemes
IF NOT EXISTS (SELECT 1 FROM schemes WHERE scheme_id = 'GF_P22')
INSERT INTO schemes (scheme_id, customer_phone, scheme_type, metal_type, monthly_amount, total_invested, total_amount_paid, total_metal_accumulated, completed_installments, duration_months, start_date, status, created_at)
VALUES ('GF_P22', '7094967284', 'GOLDFLEXI', 'GOLD', 500.00, 500.00, 500.00, 0.039, 1, 12, '2026-01-09 09:38:25.814', 'ACTIVE', '2026-01-09 09:38:25.814');

IF NOT EXISTS (SELECT 1 FROM schemes WHERE scheme_id = 'SP_P6')
INSERT INTO schemes (scheme_id, customer_phone, scheme_type, metal_type, monthly_amount, total_invested, total_amount_paid, total_metal_accumulated, completed_installments, duration_months, start_date, end_date, status, created_at)
VALUES ('SP_P6', '7603861139', 'SILVERPLUS', 'SILVER', 100.00, 100.00, 100.00, 0.373, 1, 12, '2026-01-09 17:07:39.437', '2027-01-04 17:07:39.433', 'ACTIVE', '2026-01-09 17:07:39.437');

-- 3. Sync Transactions
IF NOT EXISTS (SELECT 1 FROM transactions WHERE transaction_id = 'ORD_1767931650400_G_285')
INSERT INTO transactions (transaction_id, customer_phone, customer_name, type, amount, metal_type, gold_grams, gold_price_per_gram, silver_grams, payment_method, status, gateway_transaction_id, scheme_id, installment_number, created_at)
VALUES ('ORD_1767931650400_G_285', '7094967284', 'J.Dhanasekar', 'BUY', 500.00, 'GOLD', 0.039, 12800.00, 0.000, 'Omniware UPI', 'SUCCESS', 'FEUPII3C1D7447029', 'GF_P22', 1, '2026-01-09 09:38:25.236');

IF NOT EXISTS (SELECT 1 FROM transactions WHERE transaction_id = 'ORD_1767945306591_G_285')
INSERT INTO transactions (transaction_id, customer_phone, customer_name, type, amount, metal_type, gold_grams, gold_price_per_gram, silver_grams, payment_method, status, gateway_transaction_id, scheme_id, installment_number, created_at)
VALUES ('ORD_1767945306591_G_285', '9585007471', 'rajeswari', 'BUY', 700.00, 'GOLD', 0.055, 12800.00, 0.000, 'Omniware UPI', 'SUCCESS', 'FEUPIID73229C8835', 'GF_P6', 1, '2026-01-09 13:25:49.678');

IF NOT EXISTS (SELECT 1 FROM transactions WHERE transaction_id = 'ORD_1767958499211_S_295')
INSERT INTO transactions (transaction_id, customer_phone, customer_name, type, amount, metal_type, gold_grams, silver_grams, silver_price_per_gram, payment_method, status, gateway_transaction_id, scheme_id, installment_number, created_at)
VALUES ('ORD_1767958499211_S_295', '7603861139', 'Rupa', 'BUY', 100.00, 'SILVER', 0.000, 0.373, 268.00, 'Omniware UPI', 'SUCCESS', 'FEUPII91C3E31F8C8', 'SP_P6', 1, '2026-01-09 17:07:39.035');
