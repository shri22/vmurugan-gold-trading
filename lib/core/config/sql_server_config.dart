// SQL SERVER CONFIGURATION
// Update these values to connect to your local SQL Server (SSMS)

class SqlServerConfig {
  // =============================================================================
  // UPDATE THESE VALUES WITH YOUR SQL SERVER DETAILS
  // =============================================================================
  
  // Your Windows Server public IP address where APIs are deployed
  // ✅ CONFIGURED WITH ACTUAL PUBLIC IP
  static const String serverIP = '103.124.152.220'; // Your actual public IP

  // For development/testing, you can temporarily use:
  // static const String serverIP = '192.168.1.18'; // Local network IP

  // SQL Server port (default is 1433)
  static const int port = 1433;

  // Database name (will be created if doesn't exist)
  static const String databaseName = 'VMuruganGoldTrading';

  // Authentication details
  static const String username = 'DakData'; // Your SQL Server username
  static const String password = 'Test@123'; // Your SQL Server password
  
  // Instance name (if using named instance, e.g., 'SQLEXPRESS')
  static const String instanceName = ''; // Leave empty for default instance
  
  // =============================================================================
  // AUTOMATIC CONFIGURATION
  // =============================================================================
  
  // Connection string
  static String get connectionString {
    String server = instanceName.isNotEmpty ? '$serverIP\\$instanceName' : serverIP;
    return 'Server=$server,$port;Database=$databaseName;User Id=$username;Password=$password;TrustServerCertificate=true;';
  }
  
  // Alternative connection string for Windows Authentication
  static String get windowsAuthConnectionString {
    String server = instanceName.isNotEmpty ? '$serverIP\\$instanceName' : serverIP;
    return 'Server=$server,$port;Database=$databaseName;Trusted_Connection=true;TrustServerCertificate=true;';
  }
  
  // =============================================================================
  // COMMON CONFIGURATIONS
  // =============================================================================
  
  static const Map<String, String> commonConfigs = {
    'local_default': '127.0.0.1,1433',
    'local_sqlexpress': '127.0.0.1\\SQLEXPRESS,1433',
    'network_default': 'YOUR_IP,1433',
    'network_sqlexpress': 'YOUR_IP\\SQLEXPRESS,1433',
  };
  
  // =============================================================================
  // VALIDATION AND STATUS
  // =============================================================================
  
  /// Check if configuration is complete
  static bool get isConfigured {
    return serverIP != 'YOUR_COMPUTER_IP' && 
           username != 'YOUR_SQL_USERNAME' && 
           password != 'YOUR_SQL_PASSWORD' &&
           serverIP.isNotEmpty && 
           username.isNotEmpty;
  }
  
  /// Get configuration status
  static Map<String, dynamic> get status {
    return {
      'configured': isConfigured,
      'server_ip': serverIP,
      'port': port,
      'database': databaseName,
      'username': username,
      'password_set': password.isNotEmpty && password != 'YOUR_SQL_PASSWORD',
      'connection_string': isConfigured ? connectionString : 'Not configured',
    };
  }
  
  /// Get setup instructions
  static List<String> get setupInstructions {
    return [
      '1. Enable SQL Server TCP/IP Protocol:',
      '   - Open SQL Server Configuration Manager',
      '   - Go to SQL Server Network Configuration',
      '   - Enable TCP/IP protocol',
      '   - Set TCP Port to 1433',
      '',
      '2. Enable SQL Server Authentication:',
      '   - Open SSMS (SQL Server Management Studio)',
      '   - Right-click server → Properties → Security',
      '   - Select "SQL Server and Windows Authentication mode"',
      '   - Restart SQL Server service',
      '',
      '3. Create SQL User (if not using Windows Auth):',
      '   - In SSMS: Security → Logins → New Login',
      '   - Create username and password',
      '   - Grant necessary permissions',
      '',
      '4. Configure Windows Firewall:',
      '   - Allow SQL Server through firewall',
      '   - Open port 1433 for inbound connections',
      '',
      '5. Find Your Computer IP:',
      '   - Open Command Prompt',
      '   - Run: ipconfig',
      '   - Look for IPv4 Address (usually 192.168.x.x)',
      '',
      '6. Update Configuration:',
      '   - Edit sql_server_config.dart',
      '   - Set serverIP, username, password',
      '   - Test connection from app',
    ];
  }
  
  // =============================================================================
  // TABLE CREATION SCRIPTS
  // =============================================================================
  
  /// SQL script to create database and tables
  static String get createDatabaseScript {
    return '''
-- Create database if not exists
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '$databaseName')
BEGIN
    CREATE DATABASE [$databaseName]
END

USE [$databaseName]

-- Create Customers table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='customers' AND xtype='U')
BEGIN
    CREATE TABLE customers (
        id INT IDENTITY(1,1) PRIMARY KEY,
        phone NVARCHAR(15) UNIQUE NOT NULL,
        name NVARCHAR(100) NOT NULL,
        email NVARCHAR(100),
        address NVARCHAR(MAX),
        pan_card NVARCHAR(10),
        device_id NVARCHAR(100),
        registration_date DATETIME2 DEFAULT GETDATE(),
        business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
        total_invested DECIMAL(12,2) DEFAULT 0.00,
        total_gold DECIMAL(10,4) DEFAULT 0.0000,
        transaction_count INT DEFAULT 0,
        last_transaction DATETIME2 NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE()
    )
    
    CREATE INDEX IX_customers_phone ON customers (phone)
    CREATE INDEX IX_customers_business ON customers (business_id)
END

-- Create Transactions table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='transactions' AND xtype='U')
BEGIN
    CREATE TABLE transactions (
        id INT IDENTITY(1,1) PRIMARY KEY,
        transaction_id NVARCHAR(100) UNIQUE NOT NULL,
        customer_phone NVARCHAR(15),
        customer_name NVARCHAR(100),
        type NVARCHAR(10) NOT NULL CHECK (type IN ('BUY', 'SELL')),
        amount DECIMAL(12,2) NOT NULL,
        gold_grams DECIMAL(10,4) NOT NULL,
        gold_price_per_gram DECIMAL(10,2) NOT NULL,
        payment_method NVARCHAR(50) NOT NULL,
        status NVARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED')),
        gateway_transaction_id NVARCHAR(100),
        device_info NVARCHAR(MAX),
        location NVARCHAR(MAX),
        business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
        timestamp DATETIME2 DEFAULT GETDATE(),
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (customer_phone) REFERENCES customers(phone)
    )
    
    CREATE INDEX IX_transactions_customer ON transactions (customer_phone)
    CREATE INDEX IX_transactions_status ON transactions (status)
    CREATE INDEX IX_transactions_timestamp ON transactions (timestamp)
END

-- Create Schemes table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='schemes' AND xtype='U')
BEGIN
    CREATE TABLE schemes (
        id INT IDENTITY(1,1) PRIMARY KEY,
        scheme_id NVARCHAR(100) UNIQUE NOT NULL,
        customer_id NVARCHAR(100),
        customer_phone NVARCHAR(15),
        customer_name NVARCHAR(100),
        monthly_amount DECIMAL(12,2) NOT NULL,
        duration_months INT NOT NULL,
        scheme_type NVARCHAR(50) NOT NULL,
        status NVARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED')),
        start_date DATETIME2 DEFAULT GETDATE(),
        end_date DATETIME2,
        total_amount DECIMAL(12,2),
        total_gold DECIMAL(10,4) DEFAULT 0.0000,
        business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (customer_phone) REFERENCES customers(phone)
    )
    
    CREATE INDEX IX_schemes_customer ON schemes (customer_phone)
END

-- Create Analytics table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='analytics' AND xtype='U')
BEGIN
    CREATE TABLE analytics (
        id INT IDENTITY(1,1) PRIMARY KEY,
        event NVARCHAR(100) NOT NULL,
        data NVARCHAR(MAX),
        business_id NVARCHAR(50) DEFAULT 'VMURUGAN_001',
        timestamp DATETIME2 DEFAULT GETDATE(),
        created_at DATETIME2 DEFAULT GETDATE()
    )
    
    CREATE INDEX IX_analytics_event ON analytics (event)
    CREATE INDEX IX_analytics_timestamp ON analytics (timestamp)
END

-- Insert sample data
IF NOT EXISTS (SELECT * FROM customers WHERE phone = '9999999999')
BEGIN
    INSERT INTO customers (phone, name, email, address, pan_card, device_id)
    VALUES ('9999999999', 'Test Customer', 'test@vmurugan.com', 'Test Address, Chennai', 'ABCDE1234F', 'test_device_001')
END

PRINT 'Database and tables created successfully!'
''';
  }
}
