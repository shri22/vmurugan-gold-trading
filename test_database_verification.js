// Database Verification Script for Testing
// Run this after testing to verify data is saved correctly

const sql = require('mssql');

const config = {
  user: process.env.SQL_USER || 'sa',
  password: process.env.SQL_PASSWORD || 'YourPassword123',
  server: process.env.SQL_SERVER || '192.168.31.129',
  database: process.env.SQL_DATABASE || 'VMuruganGoldTrading',
  options: {
    encrypt: false,
    trustServerCertificate: true,
    enableArithAbort: true,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};

async function verifyTestData() {
  try {
    console.log('🔍 Connecting to database...');
    await sql.connect(config);
    console.log('✅ Connected to SQL Server');

    // Test 1: Check customers
    console.log('\n📋 TEST 1: Checking Customers');
    const customers = await sql.query('SELECT * FROM customers ORDER BY registration_date DESC');
    console.log(`Found ${customers.recordset.length} customers:`);
    customers.recordset.forEach(customer => {
      console.log(`  📱 ${customer.phone} - ${customer.name} (${customer.registration_date})`);
    });

    // Test 2: Check schemes
    console.log('\n📋 TEST 2: Checking Schemes');
    const schemes = await sql.query(`
      SELECT scheme_id, customer_phone, scheme_type, metal_type, 
             monthly_amount, completed_installments, status, start_date
      FROM schemes 
      ORDER BY start_date DESC
    `);
    console.log(`Found ${schemes.recordset.length} schemes:`);
    schemes.recordset.forEach(scheme => {
      console.log(`  🏆 ${scheme.scheme_id}`);
      console.log(`     📱 Phone: ${scheme.customer_phone}`);
      console.log(`     🥇 Type: ${scheme.scheme_type} (${scheme.metal_type})`);
      console.log(`     💰 Monthly: ₹${scheme.monthly_amount}`);
      console.log(`     📊 Progress: ${scheme.completed_installments}/15 installments`);
      console.log(`     📅 Started: ${scheme.start_date}`);
      console.log('');
    });

    // Test 3: Check installments
    console.log('\n📋 TEST 3: Checking Installments');
    const installments = await sql.query(`
      SELECT i.*, s.scheme_type, s.metal_type
      FROM scheme_installments i
      JOIN schemes s ON i.scheme_id = s.scheme_id
      ORDER BY i.scheme_id, i.installment_number
    `);
    console.log(`Found ${installments.recordset.length} installments:`);
    
    const groupedInstallments = {};
    installments.recordset.forEach(inst => {
      if (!groupedInstallments[inst.scheme_id]) {
        groupedInstallments[inst.scheme_id] = [];
      }
      groupedInstallments[inst.scheme_id].push(inst);
    });

    Object.keys(groupedInstallments).forEach(schemeId => {
      const insts = groupedInstallments[schemeId];
      const firstInst = insts[0];
      console.log(`  📋 Scheme: ${schemeId} (${firstInst.scheme_type} - ${firstInst.metal_type})`);
      
      const paidCount = insts.filter(i => i.status === 'PAID').length;
      const pendingCount = insts.filter(i => i.status === 'PENDING').length;
      
      console.log(`     ✅ Paid: ${paidCount}, ⏳ Pending: ${pendingCount}`);
      
      // Show first few installments
      insts.slice(0, 5).forEach(inst => {
        const status = inst.status === 'PAID' ? '✅' : '⏳';
        const paidDate = inst.paid_date ? ` (${inst.paid_date.toISOString().split('T')[0]})` : '';
        console.log(`     ${status} Installment ${inst.installment_number}: ₹${inst.amount}${paidDate}`);
      });
      console.log('');
    });

    // Test 4: Check transactions
    console.log('\n📋 TEST 4: Checking Transactions');
    const transactions = await sql.query(`
      SELECT transaction_id, customer_phone, type, amount, 
             metal_grams, metal_type, payment_method, status, timestamp
      FROM transactions 
      ORDER BY timestamp DESC
    `);
    console.log(`Found ${transactions.recordset.length} transactions:`);
    transactions.recordset.forEach(txn => {
      console.log(`  💳 ${txn.transaction_id}`);
      console.log(`     📱 Phone: ${txn.customer_phone}`);
      console.log(`     🔄 Type: ${txn.type} ${txn.metal_type}`);
      console.log(`     💰 Amount: ₹${txn.amount} for ${txn.metal_grams}g`);
      console.log(`     💳 Method: ${txn.payment_method}`);
      console.log(`     📊 Status: ${txn.status}`);
      console.log(`     📅 Date: ${txn.timestamp}`);
      console.log('');
    });

    // Test 5: Summary Statistics
    console.log('\n📊 SUMMARY STATISTICS');
    const stats = await sql.query(`
      SELECT 
        COUNT(DISTINCT customer_phone) as total_customers,
        COUNT(DISTINCT CASE WHEN metal_type = 'GOLD' THEN scheme_id END) as gold_schemes,
        COUNT(DISTINCT CASE WHEN metal_type = 'SILVER' THEN scheme_id END) as silver_schemes,
        SUM(CASE WHEN metal_type = 'GOLD' THEN completed_installments ELSE 0 END) as total_gold_installments,
        SUM(CASE WHEN metal_type = 'SILVER' THEN completed_installments ELSE 0 END) as total_silver_installments
      FROM schemes
    `);
    
    const stat = stats.recordset[0];
    console.log(`👥 Total Customers: ${stat.total_customers}`);
    console.log(`🥇 Gold Schemes: ${stat.gold_schemes}`);
    console.log(`🥈 Silver Schemes: ${stat.silver_schemes}`);
    console.log(`📊 Gold Installments Paid: ${stat.total_gold_installments}`);
    console.log(`📊 Silver Installments Paid: ${stat.total_silver_installments}`);

    console.log('\n✅ Database verification complete!');

  } catch (error) {
    console.error('❌ Database verification failed:', error);
  } finally {
    await sql.close();
  }
}

// Run verification
verifyTestData();
