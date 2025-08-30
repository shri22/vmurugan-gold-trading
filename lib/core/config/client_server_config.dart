// CLIENT'S SERVER CONFIGURATION
// Configuration for deploying APIs on client's own server

class ClientServerConfig {
  // =============================================================================
  // CLIENT'S SERVER DETAILS - UPDATE THESE VALUES
  // =============================================================================
  
  // PRODUCTION DEPLOYMENT ON WINDOWS SERVER
  // ✅ CONFIGURED WITH ACTUAL DOMAIN
  static const String serverDomain = 'api.vmuruganjewellery.co.in'; // Your actual domain

  // For local testing, you can temporarily use:
  // static const String serverDomain = 'localhost'; // Local testing

  // API port (HTTPS server runs on port 3001 for secure API endpoints)
  static const int serverPort = 3001;

  // Protocol (HTTPS ONLY for secure production)
  static const String protocol = 'https';

  // =============================================================================
  // AUTOMATIC API ENDPOINT GENERATION
  // =============================================================================

  // Base URL for all APIs (your Node.js server) - HTTPS ONLY
  static const String baseUrl = '$protocol://$serverDomain:$serverPort/api';

  // User Management APIs (your Node.js endpoints)
  static const String userRegisterEndpoint = '$baseUrl/customers';
  static const String userLoginEndpoint = '$baseUrl/login';
  static const String sendOtpEndpoint = '$baseUrl/auth/send-otp';
  static const String verifyOtpEndpoint = '$baseUrl/auth/verify-otp';

  // Transaction Management APIs (your Node.js endpoints)
  static const String transactionCreateEndpoint = '$baseUrl/transactions';
  static const String transactionUpdateEndpoint = '$baseUrl/transaction-status';
  static const String transactionHistoryEndpoint = '$baseUrl/transaction-history';

  // Portfolio Management APIs (your Node.js endpoints)
  static const String portfolioGetEndpoint = '$baseUrl/portfolio';
  static const String portfolioUpdateEndpoint = '$baseUrl/portfolio-update';

  // Admin APIs (your Node.js endpoints)
  static const String adminCustomersEndpoint = '$baseUrl/admin/customers';
  static const String adminTransactionsEndpoint = '$baseUrl/admin/transactions';
  static const String adminStatsEndpoint = '$baseUrl/admin/stats';

  // Health check (your Node.js endpoint)
  static const String healthCheckEndpoint = '$protocol://$serverDomain:$serverPort/health';
  
  // =============================================================================
  // CONFIGURATION VALIDATION
  // =============================================================================
  
  /// Check if configuration is complete
  static bool get isConfigured {
    return serverDomain != 'client-domain.com' && 
           serverDomain.isNotEmpty &&
           !serverDomain.contains('example') &&
           !serverDomain.contains('localhost');
  }
  
  /// Get configuration status
  static Map<String, dynamic> get status {
    return {
      'configured': isConfigured,
      'server_domain': serverDomain,
      'server_port': serverPort,
      'protocol': protocol,
      'base_url': baseUrl,
      'ssl_enabled': true, // HTTPS ONLY
      'https_only': true,
    };
  }
  
  // =============================================================================
  // DEPLOYMENT INSTRUCTIONS
  // =============================================================================
  
  /// Get deployment instructions for client's server
  static List<String> get deploymentInstructions {
    return [
      '1. Server Requirements:',
      '   - PHP 7.4+ with MySQL extension',
      '   - MySQL 5.7+ or MariaDB 10.3+',
      '   - Apache/Nginx web server',
      '   - SSL certificate (Let\'s Encrypt recommended)',
      '',
      '2. Upload Files:',
      '   - Upload Node.js server files to server',
      '   - Install dependencies: npm install',
      '   - Set proper permissions',
      '',
      '3. Database Setup:',
      '   - Create database: vmurugan_gold_trading',
      '   - Import database_schema.sql',
      '   - Create database user with full privileges',
      '',
      '4. Configuration:',
      '   - Update config/database.php with credentials',
      '   - Configure Omniware settings',
      '   - Test API endpoints',
      '',
      '5. SSL Setup:',
      '   - Install SSL certificate',
      '   - Force HTTPS redirects',
      '   - Test secure connections',
      '',
      '6. App Configuration:',
      '   - Update serverDomain in this file',
      '   - Rebuild APK with new configuration',
      '   - Test app connectivity',
    ];
  }
  
  // =============================================================================
  // API TESTING URLS
  // =============================================================================
  
  /// Get test URLs for API endpoints
  static Map<String, String> get testUrls {
    return {
      'User Registration': '$userRegisterEndpoint',
      'User Login': '$userLoginEndpoint',
      'Portfolio Get': '$portfolioGetEndpoint?user_id=1',
      'Transaction History': '$transactionHistoryEndpoint?phone=9876543210',
      'Health Check': '$healthCheckEndpoint',
    };
  }
  
  // =============================================================================
  // COMMON SERVER CONFIGURATIONS
  // =============================================================================
  
  static const Map<String, String> commonConfigs = {
    'production': 'https://yourdomain.com/vmurugan-api',
    'staging': 'https://staging.yourdomain.com/vmurugan-api',
    'development': 'https://dev.yourdomain.com/vmurugan-api',
    'local_testing': 'http://localhost/vmurugan-api',
  };
  
  // =============================================================================
  // SECURITY HEADERS
  // =============================================================================
  
  /// Required security headers for production
  static const Map<String, String> securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}
