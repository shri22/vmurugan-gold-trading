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
    $required_fields = ['user_id', 'metal_type', 'quantity', 'amount', 'operation'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $user_id = intval($input['user_id']);
    $metal_type = strtoupper(trim($input['metal_type'])); // GOLD or SILVER
    $quantity = floatval($input['quantity']);
    $amount = floatval($input['amount']);
    $operation = strtoupper(trim($input['operation'])); // ADD or SUBTRACT
    $current_price = floatval($input['current_price'] ?? 0);
    
    // Validate inputs
    if (!in_array($metal_type, ['GOLD', 'SILVER'])) {
        throw new Exception('Invalid metal type. Must be GOLD or SILVER');
    }
    
    if (!in_array($operation, ['ADD', 'SUBTRACT'])) {
        throw new Exception('Invalid operation. Must be ADD or SUBTRACT');
    }
    
    if ($quantity <= 0 || $amount <= 0) {
        throw new Exception('Quantity and amount must be positive numbers');
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Begin transaction
    $pdo->beginTransaction();
    
    try {
        // Get current portfolio
        $stmt = $pdo->prepare("
            SELECT total_gold_grams, total_silver_grams, total_invested, current_value
            FROM portfolio 
            WHERE user_id = ?
        ");
        $stmt->execute([$user_id]);
        $portfolio = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$portfolio) {
            throw new Exception('Portfolio not found for user');
        }
        
        // Calculate new values
        $new_gold_grams = floatval($portfolio['total_gold_grams']);
        $new_silver_grams = floatval($portfolio['total_silver_grams']);
        $new_total_invested = floatval($portfolio['total_invested']);
        
        if ($metal_type === 'GOLD') {
            if ($operation === 'ADD') {
                $new_gold_grams += $quantity;
                $new_total_invested += $amount;
            } else {
                $new_gold_grams = max(0, $new_gold_grams - $quantity);
                $new_total_invested = max(0, $new_total_invested - $amount);
            }
        } else { // SILVER
            if ($operation === 'ADD') {
                $new_silver_grams += $quantity;
                $new_total_invested += $amount;
            } else {
                $new_silver_grams = max(0, $new_silver_grams - $quantity);
                $new_total_invested = max(0, $new_total_invested - $amount);
            }
        }
        
        // Calculate current value if price provided
        $new_current_value = 0;
        if ($current_price > 0) {
            if ($metal_type === 'GOLD') {
                $new_current_value = $new_gold_grams * $current_price;
            } else {
                $new_current_value = $new_silver_grams * $current_price;
            }
        } else {
            $new_current_value = floatval($portfolio['current_value']);
        }
        
        // Update portfolio
        $stmt = $pdo->prepare("
            UPDATE portfolio 
            SET total_gold_grams = ?, 
                total_silver_grams = ?, 
                total_invested = ?, 
                current_value = ?,
                last_updated = NOW()
            WHERE user_id = ?
        ");
        
        $stmt->execute([
            $new_gold_grams,
            $new_silver_grams,
            $new_total_invested,
            $new_current_value,
            $user_id
        ]);
        
        // Commit transaction
        $pdo->commit();
        
        // Log successful update
        error_log("Portfolio updated: User=$user_id, Metal=$metal_type, Operation=$operation, Quantity=$quantity");
        
        echo json_encode([
            'success' => true,
            'message' => 'Portfolio updated successfully',
            'portfolio' => [
                'total_gold_grams' => $new_gold_grams,
                'total_silver_grams' => $new_silver_grams,
                'total_invested' => $new_total_invested,
                'current_value' => $new_current_value,
                'profit_loss' => $new_current_value - $new_total_invested,
                'last_updated' => date('Y-m-d H:i:s')
            ]
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    error_log("Portfolio update error: " . $e->getMessage());
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
