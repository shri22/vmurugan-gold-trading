<?php
/**
 * Payment Initiation API for Omniware Gateway
 * URL: https://yourdomain.com/api/payment/initiate
 * Method: POST
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$host = 'localhost';
$dbname = 'gold_trading';
$username = 'your_db_user';
$password = 'your_db_password';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database connection failed']);
    exit();
}

// Get input data
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON input']);
    exit();
}

// Validate required fields
$requiredFields = ['amount', 'userId', 'goldQuantity', 'goldPrice'];
foreach ($requiredFields as $field) {
    if (!isset($input[$field]) || empty($input[$field])) {
        http_response_code(400);
        echo json_encode(['error' => "Missing required field: $field"]);
        exit();
    }
}

// Omniware configuration (use environment variables in production)
$merchantId = getenv('OMNIWARE_MERCHANT_ID') ?: 'TEST_MERCHANT_ID';
$secretKey = getenv('OMNIWARE_SECRET_KEY') ?: 'TEST_SECRET_KEY';
$environment = getenv('OMNIWARE_ENVIRONMENT') ?: 'test';

// Payment details
$amount = number_format((float)$input['amount'], 2, '.', '');
$userId = $input['userId'];
$goldQuantity = $input['goldQuantity'];
$goldPrice = $input['goldPrice'];
$orderId = 'GOLD_' . time() . '_' . $userId;

// Generate transaction record
try {
    $stmt = $pdo->prepare("
        INSERT INTO transactions (
            order_id, user_id, amount, gold_quantity, gold_price, 
            status, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, 'PENDING', NOW(), NOW())
    ");
    
    $stmt->execute([
        $orderId, $userId, $amount, $goldQuantity, $goldPrice
    ]);
    
    $transactionId = $pdo->lastInsertId();
    
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to create transaction record']);
    exit();
}

// Generate hash for Omniware
$hashString = $merchantId . '|' . $orderId . '|' . $amount . '|' . $secretKey;
$hash = hash('sha256', $hashString);

// Prepare URLs
$baseUrl = 'https://' . $_SERVER['HTTP_HOST'];
$successUrl = $baseUrl . '/payment/success';
$failureUrl = $baseUrl . '/payment/failure';
$callbackUrl = $baseUrl . '/api/payment/callback';

// Determine payment gateway URL
$paymentUrl = $environment === 'live' 
    ? 'https://api.omniware.in/payment/initiate'
    : 'https://sandbox.omniware.in/payment/initiate';

// Prepare response
$response = [
    'status' => 'success',
    'transactionId' => $transactionId,
    'orderId' => $orderId,
    'merchantId' => $merchantId,
    'amount' => $amount,
    'hash' => $hash,
    'paymentUrl' => $paymentUrl,
    'successUrl' => $successUrl,
    'failureUrl' => $failureUrl,
    'callbackUrl' => $callbackUrl,
    'environment' => $environment,
    'timestamp' => date('Y-m-d H:i:s')
];

// Log the payment initiation
error_log("Payment initiated: OrderID=$orderId, Amount=$amount, UserID=$userId");

echo json_encode($response);
?>
