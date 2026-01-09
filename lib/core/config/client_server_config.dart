import 'api_config.dart';

// CLIENT'S SERVER CONFIGURATION
// Configuration for deploying APIs on client's own server

class ClientServerConfig {
  // =============================================================================
  // CLIENT'S SERVER DETAILS - USES ApiConfig AS MASTER
  // =============================================================================
  
  // PRODUCTION DEPLOYMENT ON WINDOWS SERVER
  static const String serverDomain = ApiConfig.domain;

  // API port (linked to ApiConfig)
  static int get serverPort => int.tryParse(ApiConfig.port) ?? 443;

  // Protocol (ALWAYS HTTPS)
  static String get protocol => 'https';

  // =============================================================================
  // AUTOMATIC API ENDPOINT GENERATION
  // =============================================================================

  // Base URL for all APIs (your Node.js server) - Dynamic based on mode
  static String get baseUrl => ApiConfig.baseUrl;

  // User Management APIs (your Node.js endpoints)
  static String get userRegisterEndpoint => '$baseUrl/customers';
  static String get userLoginEndpoint => '$baseUrl/login';
  static String get sendOtpEndpoint => '$baseUrl/auth/send-otp';
  static String get verifyOtpEndpoint => '$baseUrl/auth/verify-otp';

  // Transaction Management APIs (your Node.js endpoints)
  static String get transactionCreateEndpoint => '$baseUrl/transactions';
  static String get transactionUpdateEndpoint => '$baseUrl/transaction-status';
  static String get transactionHistoryEndpoint => '$baseUrl/transaction-history';

  // Portfolio Management APIs (your Node.js endpoints)
  static String get portfolioGetEndpoint => '$baseUrl/portfolio';
  static String get portfolioUpdateEndpoint => '$baseUrl/portfolio-update';

  // Scheme Management APIs (your Node.js endpoints) - NEW
  static String get schemeCreateEndpoint => '$baseUrl/schemes';
  static String get schemeGetEndpoint => '$baseUrl/schemes'; // GET /schemes/:phone
  static String get schemeUpdateEndpoint => '$baseUrl/schemes'; // PUT /schemes/:scheme_id
  static String get schemeInvestEndpoint => '$baseUrl/schemes'; // POST /schemes/:scheme_id/invest
  static String get schemeDetailsEndpoint => '$baseUrl/schemes/details'; // GET /schemes/details/:scheme_id

  // Admin APIs (your Node.js endpoints)
  static String get adminCustomersEndpoint => '$baseUrl/admin/customers';
  static String get adminTransactionsEndpoint => '$baseUrl/admin/transactions';
  static String get adminStatsEndpoint => '$baseUrl/admin/stats';

  // Health check (your Node.js endpoint)
  static String get healthCheckEndpoint => '${ApiConfig.rawBaseUrl}/health';
  
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
