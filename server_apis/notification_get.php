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
    $limit = intval($_GET['limit'] ?? 20);
    $offset = intval($_GET['offset'] ?? 0);
    $unread_only = filter_var($_GET['unread_only'] ?? false, FILTER_VALIDATE_BOOLEAN);
    
    if (!$user_id) {
        throw new Exception('User ID is required');
    }
    
    // Validate user_id is numeric
    if (!is_numeric($user_id)) {
        throw new Exception('Invalid user ID format');
    }
    
    // Validate limit and offset
    if ($limit < 1 || $limit > 100) {
        $limit = 20;
    }
    
    if ($offset < 0) {
        $offset = 0;
    }
    
    // Connect to database
    $pdo = new PDO($dsn, $username, $password, $options);
    
    // Build query
    $where_clause = 'user_id = ?';
    $params = [$user_id];
    
    if ($unread_only) {
        $where_clause .= ' AND is_read = FALSE';
    }
    
    // Get total count
    $count_stmt = $pdo->prepare("
        SELECT COUNT(*) as total
        FROM notifications 
        WHERE $where_clause
    ");
    $count_stmt->execute($params);
    $total_count = $count_stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Get notifications with pagination
    $stmt = $pdo->prepare("
        SELECT 
            id,
            title,
            message,
            type,
            is_read,
            data,
            created_at,
            read_at
        FROM notifications 
        WHERE $where_clause
        ORDER BY created_at DESC 
        LIMIT ? OFFSET ?
    ");
    
    // Add limit and offset to params
    $params[] = $limit;
    $params[] = $offset;
    
    $stmt->execute($params);
    $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format notifications
    $formatted_notifications = array_map(function($notification) {
        return [
            'id' => intval($notification['id']),
            'title' => $notification['title'],
            'message' => $notification['message'],
            'type' => $notification['type'],
            'is_read' => (bool)$notification['is_read'],
            'data' => $notification['data'] ? json_decode($notification['data'], true) : null,
            'created_at' => $notification['created_at'],
            'read_at' => $notification['read_at'],
            'time_ago' => timeAgo($notification['created_at'])
        ];
    }, $notifications);
    
    // Get unread count
    $unread_stmt = $pdo->prepare("
        SELECT COUNT(*) as unread_count
        FROM notifications 
        WHERE user_id = ? AND is_read = FALSE
    ");
    $unread_stmt->execute([$user_id]);
    $unread_count = $unread_stmt->fetch(PDO::FETCH_ASSOC)['unread_count'];
    
    echo json_encode([
        'success' => true,
        'notifications' => $formatted_notifications,
        'pagination' => [
            'total' => intval($total_count),
            'limit' => $limit,
            'offset' => $offset,
            'has_more' => ($offset + $limit) < $total_count
        ],
        'unread_count' => intval($unread_count)
    ]);
    
} catch (Exception $e) {
    error_log("Notification get error: " . $e->getMessage());
    
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

// Helper function to calculate time ago
function timeAgo($datetime) {
    $time = time() - strtotime($datetime);
    
    if ($time < 60) {
        return 'Just now';
    } elseif ($time < 3600) {
        return floor($time / 60) . ' minutes ago';
    } elseif ($time < 86400) {
        return floor($time / 3600) . ' hours ago';
    } elseif ($time < 2592000) {
        return floor($time / 86400) . ' days ago';
    } else {
        return date('M j, Y', strtotime($datetime));
    }
}
?>
