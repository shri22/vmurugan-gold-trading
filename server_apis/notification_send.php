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
    $required_fields = ['user_id', 'title', 'message'];
    foreach ($required_fields as $field) {
        if (empty($input[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $user_id = intval($input['user_id']);
    $title = trim($input['title']);
    $message = trim($input['message']);
    $type = strtoupper(trim($input['type'] ?? 'SYSTEM'));
    $data = $input['data'] ?? null;
    
    // Validate notification type
    if (!in_array($type, ['TRANSACTION', 'PRICE_ALERT', 'SYSTEM', 'PROMOTION'])) {
        $type = 'SYSTEM';
    }
    
    // Validate user exists
    if ($user_id <= 0) {
        throw new Exception('Invalid user ID');
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Verify user exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? AND status = 'active'");
    $stmt->execute([$user_id]);
    
    if (!$stmt->fetch()) {
        throw new Exception('User not found or inactive');
    }
    
    // Insert notification
    $stmt = $pdo->prepare("
        INSERT INTO notifications (user_id, title, message, type, data, created_at) 
        VALUES (?, ?, ?, ?, ?, NOW())
    ");
    
    $stmt->execute([
        $user_id,
        $title,
        $message,
        $type,
        $data ? json_encode($data) : null
    ]);
    
    $notification_id = $pdo->lastInsertId();
    
    // Log successful notification
    error_log("Notification sent: ID=$notification_id, User=$user_id, Type=$type, Title=$title");
    
    echo json_encode([
        'success' => true,
        'message' => 'Notification sent successfully',
        'notification' => [
            'id' => $notification_id,
            'user_id' => $user_id,
            'title' => $title,
            'message' => $message,
            'type' => $type,
            'data' => $data,
            'created_at' => date('Y-m-d H:i:s')
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Notification send error: " . $e->getMessage());
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
