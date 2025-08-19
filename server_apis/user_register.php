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
    $required_fields = ['phone', 'name', 'email', 'encrypted_mpin'];
    foreach ($required_fields as $field) {
        if (empty($input[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $phone = trim($input['phone']);
    $name = trim($input['name']);
    $email = trim($input['email']);
    $encrypted_mpin = $input['encrypted_mpin'];
    $address = trim($input['address'] ?? '');
    $pan_card = trim($input['pan_card'] ?? '');
    $device_id = trim($input['device_id'] ?? '');
    
    // Validate phone number format
    if (!preg_match('/^[6-9]\d{9}$/', $phone)) {
        throw new Exception('Invalid phone number format');
    }
    
    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception('Invalid email format');
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Check if user already exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ? OR email = ?");
    $stmt->execute([$phone, $email]);
    
    if ($stmt->fetch()) {
        throw new Exception('User already exists with this phone number or email');
    }
    
    // Begin transaction
    $pdo->beginTransaction();
    
    try {
        // Insert user
        $stmt = $pdo->prepare("
            INSERT INTO users (phone, name, email, encrypted_mpin, address, pan_card, device_id, created_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        ");
        
        $stmt->execute([$phone, $name, $email, $encrypted_mpin, $address, $pan_card, $device_id]);
        $user_id = $pdo->lastInsertId();
        
        // Create initial portfolio for user
        $stmt = $pdo->prepare("
            INSERT INTO portfolio (user_id, total_gold_grams, total_silver_grams, total_invested, current_value) 
            VALUES (?, 0, 0, 0, 0)
        ");
        $stmt->execute([$user_id]);
        
        // Commit transaction
        $pdo->commit();
        
        // Log successful registration
        error_log("User registered successfully: Phone=$phone, ID=$user_id");
        
        echo json_encode([
            'success' => true,
            'message' => 'User registered successfully',
            'user' => [
                'id' => $user_id,
                'phone' => $phone,
                'name' => $name,
                'email' => $email
            ]
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }
    
} catch (Exception $e) {
    error_log("Registration error: " . $e->getMessage());
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
