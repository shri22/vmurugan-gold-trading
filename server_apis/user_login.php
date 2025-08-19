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
    if (empty($input['phone']) || empty($input['encrypted_mpin'])) {
        throw new Exception('Phone number and MPIN are required');
    }
    
    $phone = trim($input['phone']);
    $encrypted_mpin = $input['encrypted_mpin'];
    
    // Validate phone number format
    if (!preg_match('/^[6-9]\d{9}$/', $phone)) {
        throw new Exception('Invalid phone number format');
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Find user and verify MPIN
    $stmt = $pdo->prepare("
        SELECT id, phone, name, email, encrypted_mpin, created_at, last_login
        FROM users 
        WHERE phone = ? AND status = 'active'
    ");
    $stmt->execute([$phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$user) {
        throw new Exception('User not found or account inactive');
    }
    
    // Verify encrypted MPIN
    if ($user['encrypted_mpin'] !== $encrypted_mpin) {
        // Log failed login attempt
        error_log("Failed login attempt for phone: $phone");
        throw new Exception('Invalid MPIN');
    }
    
    // Update last login time
    $stmt = $pdo->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
    $stmt->execute([$user['id']]);
    
    // Get user's portfolio
    $stmt = $pdo->prepare("
        SELECT total_gold_grams, total_silver_grams, total_invested, current_value, last_updated
        FROM portfolio 
        WHERE user_id = ?
    ");
    $stmt->execute([$user['id']]);
    $portfolio = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Log successful login
    error_log("User logged in successfully: Phone=$phone, ID={$user['id']}");
    
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'user' => [
            'id' => $user['id'],
            'phone' => $user['phone'],
            'name' => $user['name'],
            'email' => $user['email'],
            'created_at' => $user['created_at'],
            'last_login' => $user['last_login']
        ],
        'portfolio' => $portfolio ?: [
            'total_gold_grams' => 0,
            'total_silver_grams' => 0,
            'total_invested' => 0,
            'current_value' => 0,
            'last_updated' => null
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Login error: " . $e->getMessage());
    
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
