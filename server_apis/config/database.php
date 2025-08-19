<?php
// Database configuration for client's server
$host = 'localhost';  // Or client's MySQL server IP
$dbname = 'vmurugan_gold_trading';
$username = 'vmurugan_user';  // Database username
$password = 'SecurePassword123!';  // Strong password for production

// PDO options for better error handling and security
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
];

// DSN (Data Source Name)
$dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";

// Test database connection function
function testDatabaseConnection() {
    global $dsn, $username, $password, $options;
    
    try {
        $pdo = new PDO($dsn, $username, $password, $options);
        return ['success' => true, 'message' => 'Database connection successful'];
    } catch (PDOException $e) {
        error_log("Database connection failed: " . $e->getMessage());
        return ['success' => false, 'message' => 'Database connection failed: ' . $e->getMessage()];
    }
}

// Omniware configuration for client's server
$omniware_config = [
    'merchant_id' => 'CLIENT_OMNIWARE_MERCHANT_ID',  // Client's actual merchant ID
    'secret_key' => 'CLIENT_OMNIWARE_SECRET_KEY',    // Client's actual secret key
    'base_url' => 'https://api.omniware.in',         // Omniware API base URL
    'callback_url' => 'https://client-domain.com/vmurugan-api/payment_callback.php',  // Client's domain
    'success_url' => 'https://client-domain.com/payment/success',
    'failure_url' => 'https://client-domain.com/payment/failure',
    'cancel_url' => 'https://client-domain.com/payment/cancel'
];

// Application configuration
$app_config = [
    'app_name' => 'V Murugan Gold Trading',
    'app_version' => '1.0.0',
    'timezone' => 'Asia/Kolkata',
    'currency' => 'INR',
    'max_transaction_amount' => 100000.00,  // ₹1,00,000
    'min_transaction_amount' => 100.00,     // ₹100
    'transaction_fee_percentage' => 0.0,    // 0% transaction fee
    'gst_percentage' => 18.0                // 18% GST
];

// Set timezone
date_default_timezone_set($app_config['timezone']);

// Security headers function
function setSecurityHeaders() {
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');
    header('X-XSS-Protection: 1; mode=block');
    header('Referrer-Policy: strict-origin-when-cross-origin');
}

// Validate required environment variables
function validateEnvironment() {
    global $omniware_config;
    
    $errors = [];
    
    if ($omniware_config['merchant_id'] === 'YOUR_OMNIWARE_MERCHANT_ID') {
        $errors[] = 'Omniware merchant ID not configured';
    }
    
    if ($omniware_config['secret_key'] === 'YOUR_OMNIWARE_SECRET_KEY') {
        $errors[] = 'Omniware secret key not configured';
    }
    
    if (strpos($omniware_config['callback_url'], 'yourdomain.com') !== false) {
        $errors[] = 'Callback URL not configured with actual domain';
    }
    
    return $errors;
}

// Generate secure hash for Omniware
function generateOmniwareHash($data, $secret_key) {
    ksort($data);
    $hash_string = '';
    
    foreach ($data as $key => $value) {
        if ($key !== 'hash') {
            $hash_string .= $key . '=' . $value . '&';
        }
    }
    
    $hash_string = rtrim($hash_string, '&');
    return hash('sha256', $hash_string . $secret_key);
}

// Verify Omniware hash
function verifyOmniwareHash($data, $received_hash, $secret_key) {
    $calculated_hash = generateOmniwareHash($data, $secret_key);
    return hash_equals($calculated_hash, $received_hash);
}

// Log function for debugging
function logMessage($message, $level = 'INFO') {
    $timestamp = date('Y-m-d H:i:s');
    $log_entry = "[$timestamp] [$level] $message" . PHP_EOL;
    error_log($log_entry, 3, __DIR__ . '/../logs/app.log');
}

// Create logs directory if it doesn't exist
$logs_dir = __DIR__ . '/../logs';
if (!is_dir($logs_dir)) {
    mkdir($logs_dir, 0755, true);
}

// Initialize error logging
ini_set('log_errors', 1);
ini_set('error_log', $logs_dir . '/php_errors.log');
?>
