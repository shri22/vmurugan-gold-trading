<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

require_once 'config/database.php';

try {
    // Get parameters
    $user_id = $_GET['user_id'] ?? null;
    $limit = intval($_GET['limit'] ?? 50);
    $offset = intval($_GET['offset'] ?? 0);
    $metal_type = strtoupper(trim($_GET['metal_type'] ?? ''));
    $transaction_type = strtoupper(trim($_GET['type'] ?? ''));
    $status = strtoupper(trim($_GET['status'] ?? ''));
    
    if (!$user_id) {
        throw new Exception('User ID is required');
    }
    
    // Validate user_id is numeric
    if (!is_numeric($user_id)) {
        throw new Exception('Invalid user ID format');
    }
    
    // Validate limit and offset
    if ($limit < 1 || $limit > 100) {
        $limit = 50;
    }
    
    if ($offset < 0) {
        $offset = 0;
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Build query with filters
    $where_conditions = ['user_id = ?'];
    $params = [$user_id];
    
    if (!empty($metal_type) && in_array($metal_type, ['GOLD', 'SILVER'])) {
        $where_conditions[] = 'metal_type = ?';
        $params[] = $metal_type;
    }
    
    if (!empty($transaction_type) && in_array($transaction_type, ['BUY', 'SELL'])) {
        $where_conditions[] = 'type = ?';
        $params[] = $transaction_type;
    }
    
    if (!empty($status) && in_array($status, ['PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'])) {
        $where_conditions[] = 'payment_status = ?';
        $params[] = $status;
    }
    
    $where_clause = implode(' AND ', $where_conditions);
    
    // Get total count
    $count_stmt = $pdo->prepare("
        SELECT COUNT(*) as total
        FROM transactions 
        WHERE $where_clause
    ");
    $count_stmt->execute($params);
    $total_count = $count_stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Get transactions with pagination
    $stmt = $pdo->prepare("
        SELECT 
            id,
            transaction_id,
            type,
            metal_type,
            quantity,
            price_per_gram,
            total_amount,
            payment_method,
            payment_status,
            gateway_transaction_id,
            created_at,
            updated_at
        FROM transactions 
        WHERE $where_clause
        ORDER BY created_at DESC 
        LIMIT ? OFFSET ?
    ");
    
    // Add limit and offset to params
    $params[] = $limit;
    $params[] = $offset;
    
    $stmt->execute($params);
    $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format transactions
    $formatted_transactions = array_map(function($transaction) {
        return [
            'id' => intval($transaction['id']),
            'transaction_id' => $transaction['transaction_id'],
            'type' => $transaction['type'],
            'metal_type' => $transaction['metal_type'],
            'quantity' => floatval($transaction['quantity']),
            'price_per_gram' => floatval($transaction['price_per_gram']),
            'total_amount' => floatval($transaction['total_amount']),
            'payment_method' => $transaction['payment_method'],
            'payment_status' => $transaction['payment_status'],
            'gateway_transaction_id' => $transaction['gateway_transaction_id'],
            'created_at' => $transaction['created_at'],
            'updated_at' => $transaction['updated_at'],
            'status_display' => ucfirst(strtolower($transaction['payment_status'])),
            'formatted_amount' => '₹' . number_format($transaction['total_amount'], 2),
            'formatted_quantity' => number_format($transaction['quantity'], 4) . 'g'
        ];
    }, $transactions);
    
    // Calculate summary statistics
    $summary_stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_transactions,
            SUM(CASE WHEN type = 'BUY' AND payment_status = 'SUCCESS' THEN total_amount ELSE 0 END) as total_invested,
            SUM(CASE WHEN type = 'BUY' AND payment_status = 'SUCCESS' AND metal_type = 'GOLD' THEN quantity ELSE 0 END) as total_gold_bought,
            SUM(CASE WHEN type = 'BUY' AND payment_status = 'SUCCESS' AND metal_type = 'SILVER' THEN quantity ELSE 0 END) as total_silver_bought,
            COUNT(CASE WHEN payment_status = 'SUCCESS' THEN 1 END) as successful_transactions,
            COUNT(CASE WHEN payment_status = 'PENDING' THEN 1 END) as pending_transactions,
            COUNT(CASE WHEN payment_status = 'FAILED' THEN 1 END) as failed_transactions
        FROM transactions 
        WHERE user_id = ?
    ");
    $summary_stmt->execute([$user_id]);
    $summary = $summary_stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'transactions' => $formatted_transactions,
        'pagination' => [
            'total' => intval($total_count),
            'limit' => $limit,
            'offset' => $offset,
            'has_more' => ($offset + $limit) < $total_count
        ],
        'summary' => [
            'total_transactions' => intval($summary['total_transactions']),
            'total_invested' => floatval($summary['total_invested']),
            'total_gold_bought' => floatval($summary['total_gold_bought']),
            'total_silver_bought' => floatval($summary['total_silver_bought']),
            'successful_transactions' => intval($summary['successful_transactions']),
            'pending_transactions' => intval($summary['pending_transactions']),
            'failed_transactions' => intval($summary['failed_transactions'])
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Transaction history error: " . $e->getMessage());
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
