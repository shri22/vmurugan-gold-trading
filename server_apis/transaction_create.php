<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

require_once 'config/database.php';

try {
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Invalid JSON input');
    }
    
    // Validate required fields
    $required_fields = ['user_id', 'transaction_id', 'type', 'metal_type', 'quantity', 'price_per_gram', 'total_amount', 'payment_method'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $user_id = intval($input['user_id']);
    $transaction_id = trim($input['transaction_id']);
    $type = strtoupper(trim($input['type'])); // BUY or SELL
    $metal_type = strtoupper(trim($input['metal_type'])); // GOLD or SILVER
    $quantity = floatval($input['quantity']);
    $price_per_gram = floatval($input['price_per_gram']);
    $total_amount = floatval($input['total_amount']);
    $payment_method = trim($input['payment_method']);
    $payment_status = strtoupper(trim($input['payment_status'] ?? 'PENDING'));
    $gateway_transaction_id = trim($input['gateway_transaction_id'] ?? '');
    
    // Validate inputs
    if (!in_array($type, ['BUY', 'SELL'])) {
        throw new Exception('Invalid transaction type. Must be BUY or SELL');
    }
    
    if (!in_array($metal_type, ['GOLD', 'SILVER'])) {
        throw new Exception('Invalid metal type. Must be GOLD or SILVER');
    }
    
    if (!in_array($payment_status, ['PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'])) {
        throw new Exception('Invalid payment status');
    }
    
    if ($quantity <= 0 || $price_per_gram <= 0 || $total_amount <= 0) {
        throw new Exception('Quantity, price per gram, and total amount must be positive numbers');
    }
    
    if (empty($transaction_id)) {
        throw new Exception('Transaction ID cannot be empty');
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Check if transaction ID already exists
    $stmt = $pdo->prepare("SELECT id FROM transactions WHERE transaction_id = ?");
    $stmt->execute([$transaction_id]);
    
    if ($stmt->fetch()) {
        throw new Exception('Transaction ID already exists');
    }
    
    // Verify user exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? AND status = 'active'");
    $stmt->execute([$user_id]);
    
    if (!$stmt->fetch()) {
        throw new Exception('User not found or inactive');
    }
    
    // Begin transaction
    $pdo->beginTransaction();
    
    try {
        // Insert transaction
        $stmt = $pdo->prepare("
            INSERT INTO transactions (
                user_id, transaction_id, type, metal_type, quantity, 
                price_per_gram, total_amount, payment_method, payment_status, 
                gateway_transaction_id, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ");
        
        $stmt->execute([
            $user_id,
            $transaction_id,
            $type,
            $metal_type,
            $quantity,
            $price_per_gram,
            $total_amount,
            $payment_method,
            $payment_status,
            $gateway_transaction_id
        ]);
        
        $db_transaction_id = $pdo->lastInsertId();
        
        // If transaction is successful and it's a purchase, update portfolio
        if ($payment_status === 'SUCCESS' && $type === 'BUY') {
            // Update portfolio
            if ($metal_type === 'GOLD') {
                $stmt = $pdo->prepare("
                    UPDATE portfolio 
                    SET total_gold_grams = total_gold_grams + ?, 
                        total_invested = total_invested + ?,
                        last_updated = NOW()
                    WHERE user_id = ?
                ");
            } else {
                $stmt = $pdo->prepare("
                    UPDATE portfolio 
                    SET total_silver_grams = total_silver_grams + ?, 
                        total_invested = total_invested + ?,
                        last_updated = NOW()
                    WHERE user_id = ?
                ");
            }
            
            $stmt->execute([$quantity, $total_amount, $user_id]);
        }
        
        // Commit transaction
        $pdo->commit();
        
        // Log successful creation
        error_log("Transaction created: ID=$transaction_id, User=$user_id, Type=$type, Metal=$metal_type, Amount=$total_amount");
        
        echo json_encode([
            'success' => true,
            'message' => 'Transaction created successfully',
            'transaction' => [
                'id' => $db_transaction_id,
                'transaction_id' => $transaction_id,
                'user_id' => $user_id,
                'type' => $type,
                'metal_type' => $metal_type,
                'quantity' => $quantity,
                'price_per_gram' => $price_per_gram,
                'total_amount' => $total_amount,
                'payment_method' => $payment_method,
                'payment_status' => $payment_status,
                'gateway_transaction_id' => $gateway_transaction_id,
                'created_at' => date('Y-m-d H:i:s')
            ]
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    error_log("Transaction creation error: " . $e->getMessage());
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
