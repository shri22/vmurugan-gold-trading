<?php
// LOCAL TESTING CONFIGURATION FOR XAMPP
// Use this configuration for local testing with XAMPP

// Database configuration for XAMPP
$host = 'localhost';
$dbname = 'vmurugan_gold_trading';
$username = 'root';      // Default XAMPP MySQL username
$password = '';          // Default XAMPP MySQL password (empty)

// PDO options for better error handling and security
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
];

// DSN (Data Source Name)
$dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";

// Test Omniware configuration (for local testing - won't actually work)
$omniware_config = [
    'merchant_id' => 'TEST_MERCHANT_ID',
    'secret_key' => 'TEST_SECRET_KEY',
    'base_url' => 'https://api.omniware.in',
    'callback_url' => 'http://localhost/vmurugan-api/payment_callback.php',
    'success_url' => 'http://localhost/payment/success',
    'failure_url' => 'http://localhost/payment/failure',
    'cancel_url' => 'http://localhost/payment/cancel'
];

// Application configuration
$app_config = [
    'app_name' => 'V Murugan Gold Trading - LOCAL TESTING',
    'app_version' => '1.0.0',
    'timezone' => 'Asia/Kolkata',
    'currency' => 'INR',
    'max_transaction_amount' => 100000.00,
    'min_transaction_amount' => 100.00,
    'transaction_fee_percentage' => 0.0,
    'gst_percentage' => 18.0,
    'environment' => 'LOCAL_TESTING'
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

// Test database connection function
function testDatabaseConnection() {
    global $dsn, $username, $password, $options;
    
    try {
        $pdo = new PDO($dsn, $username, $password, $options);
        return ['success' => true, 'message' => 'Local database connection successful'];
    } catch (PDOException $e) {
        error_log("Local database connection failed: " . $e->getMessage());
        return ['success' => false, 'message' => 'Local database connection failed: ' . $e->getMessage()];
    }
}

// Generate secure hash for Omniware (test version)
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

// Verify Omniware hash (test version)
function verifyOmniwareHash($data, $received_hash, $secret_key) {
    $calculated_hash = generateOmniwareHash($data, $secret_key);
    return hash_equals($calculated_hash, $received_hash);
}

// Log function for debugging
function logMessage($message, $level = 'INFO') {
    $timestamp = date('Y-m-d H:i:s');
    $log_entry = "[$timestamp] [$level] [LOCAL] $message" . PHP_EOL;
    error_log($log_entry, 3, __DIR__ . '/../logs/local_testing.log');
}

// Create logs directory if it doesn't exist
$logs_dir = __DIR__ . '/../logs';
if (!is_dir($logs_dir)) {
    mkdir($logs_dir, 0755, true);
}

// Initialize error logging for local testing
ini_set('log_errors', 1);
ini_set('error_log', $logs_dir . '/local_php_errors.log');
ini_set('display_errors', 1); // Show errors for local testing

// Local testing banner
echo "<!-- V Murugan Gold Trading - LOCAL TESTING MODE -->\n";
echo "<!-- Database: $dbname | Host: $host | Environment: LOCAL -->\n";
?>
