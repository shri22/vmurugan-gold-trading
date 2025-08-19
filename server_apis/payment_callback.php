<?php
/**
 * Payment Callback/Webhook API for Omniware Gateway
 * URL: https://yourdomain.com/api/payment/callback
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

// Get callback data
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    // Try to get data from POST parameters
    $input = $_POST;
}

if (empty($input)) {
    http_response_code(400);
    echo json_encode(['error' => 'No callback data received']);
    exit();
}

// Log the callback for debugging
error_log("Payment callback received: " . json_encode($input));

// Extract callback data
$orderId = $input['orderId'] ?? $input['order_id'] ?? '';
$status = $input['status'] ?? '';
$transactionId = $input['transactionId'] ?? $input['transaction_id'] ?? '';
$amount = $input['amount'] ?? '';
$receivedHash = $input['hash'] ?? '';
$gatewayTransactionId = $input['gatewayTransactionId'] ?? $input['gateway_transaction_id'] ?? '';

// Validate required fields
if (empty($orderId) || empty($status)) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required callback data']);
    exit();
}

// Get secret key
$secretKey = getenv('OMNIWARE_SECRET_KEY') ?: 'TEST_SECRET_KEY';

// Verify hash if provided
if (!empty($receivedHash)) {
    $calculatedHash = hash('sha256', $orderId . '|' . $status . '|' . $amount . '|' . $secretKey);
    
    if ($receivedHash !== $calculatedHash) {
        error_log("Hash verification failed for order: $orderId");
        http_response_code(400);
        echo json_encode(['error' => 'Invalid hash verification']);
        exit();
    }
}

// Get existing transaction
try {
    $stmt = $pdo->prepare("SELECT * FROM transactions WHERE order_id = ?");
    $stmt->execute([$orderId]);
    $transaction = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$transaction) {
        http_response_code(404);
        echo json_encode(['error' => 'Transaction not found']);
        exit();
    }
    
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Database query failed']);
    exit();
}

// Map status
$statusMap = [
    'SUCCESS' => 'COMPLETED',
    'FAILED' => 'FAILED',
    'PENDING' => 'PENDING',
    'CANCELLED' => 'CANCELLED'
];

$newStatus = $statusMap[strtoupper($status)] ?? 'FAILED';

// Update transaction
try {
    $stmt = $pdo->prepare("
        UPDATE transactions 
        SET status = ?, 
            gateway_transaction_id = ?, 
            callback_data = ?,
            updated_at = NOW()
        WHERE order_id = ?
    ");
    
    $stmt->execute([
        $newStatus,
        $gatewayTransactionId,
        json_encode($input),
        $orderId
    ]);
    
    // If payment successful, update user's gold balance
    if ($newStatus === 'COMPLETED') {
        $stmt = $pdo->prepare("
            UPDATE users 
            SET gold_balance = gold_balance + ?,
                total_investment = total_investment + ?
            WHERE id = ?
        ");
        
        $stmt->execute([
            $transaction['gold_quantity'],
            $transaction['amount'],
            $transaction['user_id']
        ]);
        
        // Create portfolio entry
        $stmt = $pdo->prepare("
            INSERT INTO portfolio (
                user_id, transaction_id, gold_quantity, 
                purchase_price, purchase_date
            ) VALUES (?, ?, ?, ?, NOW())
        ");
        
        $stmt->execute([
            $transaction['user_id'],
            $transaction['id'],
            $transaction['gold_quantity'],
            $transaction['gold_price']
        ]);
    }
    
} catch(PDOException $e) {
    error_log("Database update failed: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Failed to update transaction']);
    exit();
}

// Send notification (implement your notification logic)
sendPaymentNotification($transaction['user_id'], $orderId, $newStatus, $transaction['amount']);

// Log the successful callback processing
error_log("Payment callback processed: OrderID=$orderId, Status=$newStatus, Amount={$transaction['amount']}");

// Respond to gateway
echo json_encode([
    'status' => 'success',
    'message' => 'Callback processed successfully',
    'orderId' => $orderId,
    'transactionStatus' => $newStatus
]);

/**
 * Send payment notification to user
 */
function sendPaymentNotification($userId, $orderId, $status, $amount) {
    // Implement your notification logic here
    // This could be:
    // - Push notification via Firebase
    // - SMS notification
    // - Email notification
    
    $message = '';
    switch ($status) {
        case 'COMPLETED':
            $message = "Payment successful! ₹$amount gold purchase completed. Order: $orderId";
            break;
        case 'FAILED':
            $message = "Payment failed for order: $orderId. Please try again.";
            break;
        case 'PENDING':
            $message = "Payment pending for order: $orderId. We'll update you soon.";
            break;
    }
    
    // Log notification (implement actual notification sending)
    error_log("Notification sent to user $userId: $message");
}
?>
