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
    if (empty($input['user_id'])) {
        throw new Exception('User ID is required');
    }
    
    $user_id = intval($input['user_id']);
    $notification_id = isset($input['notification_id']) ? intval($input['notification_id']) : null;
    $mark_all = filter_var($input['mark_all'] ?? false, FILTER_VALIDATE_BOOLEAN);
    
    if (!$mark_all && !$notification_id) {
        throw new Exception('Either notification_id or mark_all must be provided');
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Verify user exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? AND status = 'active'");
    $stmt->execute([$user_id]);
    
    if (!$stmt->fetch()) {
        throw new Exception('User not found or inactive');
    }
    
    if ($mark_all) {
        // Mark all notifications as read for the user
        $stmt = $pdo->prepare("
            UPDATE notifications 
            SET is_read = TRUE, read_at = NOW() 
            WHERE user_id = ? AND is_read = FALSE
        ");
        $stmt->execute([$user_id]);
        $affected_rows = $stmt->rowCount();
        
        error_log("Marked all notifications as read: User=$user_id, Count=$affected_rows");
        
        echo json_encode([
            'success' => true,
            'message' => 'All notifications marked as read',
            'marked_count' => $affected_rows
        ]);
        
    } else {
        // Mark specific notification as read
        $stmt = $pdo->prepare("
            UPDATE notifications 
            SET is_read = TRUE, read_at = NOW() 
            WHERE id = ? AND user_id = ? AND is_read = FALSE
        ");
        $stmt->execute([$notification_id, $user_id]);
        $affected_rows = $stmt->rowCount();
        
        if ($affected_rows === 0) {
            throw new Exception('Notification not found or already read');
        }
        
        error_log("Marked notification as read: ID=$notification_id, User=$user_id");
        
        echo json_encode([
            'success' => true,
            'message' => 'Notification marked as read',
            'notification_id' => $notification_id
        ]);
    }
    
} catch (Exception $e) {
    error_log("Notification mark read error: " . $e->getMessage());
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
