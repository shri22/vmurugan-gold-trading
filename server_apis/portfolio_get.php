<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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
    // Get user_id from query parameter
    $user_id = $_GET['user_id'] ?? null;
    
    if (!$user_id) {
        throw new Exception('User ID is required');
    }
    
    // Validate user_id is numeric
    if (!is_numeric($user_id)) {
        throw new Exception('Invalid user ID format');
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Get user's portfolio
    $stmt = $pdo->prepare("
        SELECT 
            p.total_gold_grams,
            p.total_silver_grams,
            p.total_invested,
            p.current_value,
            p.last_updated,
            u.name,
            u.phone
        FROM portfolio p
        JOIN users u ON p.user_id = u.id
        WHERE p.user_id = ? AND u.status = 'active'
    ");
    $stmt->execute([$user_id]);
    $portfolio = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$portfolio) {
        // Create portfolio if it doesn't exist
        $stmt = $pdo->prepare("
            INSERT INTO portfolio (user_id, total_gold_grams, total_silver_grams, total_invested, current_value) 
            VALUES (?, 0, 0, 0, 0)
        ");
        $stmt->execute([$user_id]);
        
        $portfolio = [
            'total_gold_grams' => 0,
            'total_silver_grams' => 0,
            'total_invested' => 0,
            'current_value' => 0,
            'last_updated' => date('Y-m-d H:i:s'),
            'name' => '',
            'phone' => ''
        ];
    }
    
    // Get recent transactions
    $stmt = $pdo->prepare("
        SELECT 
            transaction_id,
            type,
            metal_type,
            quantity,
            price_per_gram,
            total_amount,
            payment_status,
            created_at
        FROM transactions 
        WHERE user_id = ? 
        ORDER BY created_at DESC 
        LIMIT 10
    ");
    $stmt->execute([$user_id]);
    $recent_transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Calculate profit/loss
    $current_value = floatval($portfolio['current_value']);
    $total_invested = floatval($portfolio['total_invested']);
    $profit_loss = $current_value - $total_invested;
    $profit_loss_percentage = $total_invested > 0 ? ($profit_loss / $total_invested) * 100 : 0;
    
    echo json_encode([
        'success' => true,
        'portfolio' => [
            'total_gold_grams' => floatval($portfolio['total_gold_grams']),
            'total_silver_grams' => floatval($portfolio['total_silver_grams']),
            'total_invested' => $total_invested,
            'current_value' => $current_value,
            'profit_loss' => $profit_loss,
            'profit_loss_percentage' => round($profit_loss_percentage, 2),
            'last_updated' => $portfolio['last_updated']
        ],
        'user' => [
            'name' => $portfolio['name'],
            'phone' => $portfolio['phone']
        ],
        'recent_transactions' => $recent_transactions
    ]);
    
} catch (Exception $e) {
    error_log("Portfolio get error: " . $e->getMessage());
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
