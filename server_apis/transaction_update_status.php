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
    if (empty($input['transaction_id']) || empty($input['payment_status'])) {
        throw new Exception('Transaction ID and payment status are required');
    }
    
    $transaction_id = trim($input['transaction_id']);
    $payment_status = strtoupper(trim($input['payment_status']));
    $gateway_transaction_id = trim($input['gateway_transaction_id'] ?? '');
    $callback_data = $input['callback_data'] ?? null;
    
    // Validate payment status
    if (!in_array($payment_status, ['PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'])) {
        throw new Exception('Invalid payment status');
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Begin transaction
    $pdo->beginTransaction();
    
    try {
        // Get current transaction details
        $stmt = $pdo->prepare("
            SELECT id, user_id, type, metal_type, quantity, total_amount, payment_status
            FROM transactions 
            WHERE transaction_id = ?
        ");
        $stmt->execute([$transaction_id]);
        $transaction = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$transaction) {
            throw new Exception('Transaction not found');
        }
        
        $old_status = $transaction['payment_status'];
        
        // Update transaction status
        $stmt = $pdo->prepare("
            UPDATE transactions 
            SET payment_status = ?, 
                gateway_transaction_id = ?, 
                callback_data = ?,
                updated_at = NOW()
            WHERE transaction_id = ?
        ");
        
        $stmt->execute([
            $payment_status,
            $gateway_transaction_id,
            $callback_data ? json_encode($callback_data) : null,
            $transaction_id
        ]);
        
        // If status changed from non-SUCCESS to SUCCESS and it's a BUY transaction, update portfolio
        if ($old_status !== 'SUCCESS' && $payment_status === 'SUCCESS' && $transaction['type'] === 'BUY') {
            $user_id = $transaction['user_id'];
            $metal_type = $transaction['metal_type'];
            $quantity = floatval($transaction['quantity']);
            $total_amount = floatval($transaction['total_amount']);
            
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
            
            error_log("Portfolio updated for successful transaction: User=$user_id, Metal=$metal_type, Quantity=$quantity");
        }
        
        // If status changed from SUCCESS to FAILED/CANCELLED and it's a BUY transaction, reverse portfolio update
        if ($old_status === 'SUCCESS' && in_array($payment_status, ['FAILED', 'CANCELLED']) && $transaction['type'] === 'BUY') {
            $user_id = $transaction['user_id'];
            $metal_type = $transaction['metal_type'];
            $quantity = floatval($transaction['quantity']);
            $total_amount = floatval($transaction['total_amount']);
            
            if ($metal_type === 'GOLD') {
                $stmt = $pdo->prepare("
                    UPDATE portfolio 
                    SET total_gold_grams = GREATEST(0, total_gold_grams - ?), 
                        total_invested = GREATEST(0, total_invested - ?),
                        last_updated = NOW()
                    WHERE user_id = ?
                ");
            } else {
                $stmt = $pdo->prepare("
                    UPDATE portfolio 
                    SET total_silver_grams = GREATEST(0, total_silver_grams - ?), 
                        total_invested = GREATEST(0, total_invested - ?),
                        last_updated = NOW()
                    WHERE user_id = ?
                ");
            }
            
            $stmt->execute([$quantity, $total_amount, $user_id]);
            
            error_log("Portfolio reversed for failed transaction: User=$user_id, Metal=$metal_type, Quantity=$quantity");
        }
        
        // Commit transaction
        $pdo->commit();
        
        // Log successful update
        error_log("Transaction status updated: ID=$transaction_id, Status=$payment_status, Gateway=$gateway_transaction_id");
        
        echo json_encode([
            'success' => true,
            'message' => 'Transaction status updated successfully',
            'transaction_id' => $transaction_id,
            'old_status' => $old_status,
            'new_status' => $payment_status,
            'gateway_transaction_id' => $gateway_transaction_id
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    error_log("Transaction status update error: " . $e->getMessage());
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
