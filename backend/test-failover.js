#!/usr/bin/env node

const https = require('https');
const http = require('http');

// Backend URLs
const backends = {
  render: 'https://bitcoincloudmining.onrender.com',
  railway: 'https://bitcoincloudmining-production.up.railway.app'
};

// Health endpoints to test
const healthEndpoints = ['/health', '/api/health', '/status', '/ping'];

// Test function
async function testEndpoint(url, timeout = 5000) {
  return new Promise((resolve) => {
    const start = Date.now();
    const request = https.get(url, (res) => {
      const duration = Date.now() - start;
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({
            success: true,
            status: res.statusCode,
            duration,
            data: json
          });
        } catch (e) {
          resolve({
            success: true,
            status: res.statusCode,
            duration,
            data: data.substring(0, 100) // First 100 chars if not JSON
          });
        }
      });
    });
    
    request.on('error', (error) => {
      const duration = Date.now() - start;
      resolve({
        success: false,
        error: error.message,
        duration
      });
    });
    
    request.setTimeout(timeout, () => {
      request.destroy();
      const duration = Date.now() - start;
      resolve({
        success: false,
        error: 'Timeout',
        duration
      });
    });
  });
}

// Test all health endpoints
async function testHealthEndpoints() {
  console.log('\n🏥 Testing Health Endpoints');
  console.log('=' .repeat(50));
  
  for (const [name, baseUrl] of Object.entries(backends)) {
    console.log(`\n🔍 Testing ${name.toUpperCase()} backend: ${baseUrl}`);
    console.log('-'.repeat(40));
    
    for (const endpoint of healthEndpoints) {
      const url = baseUrl + endpoint;
      const result = await testEndpoint(url);
      
      const status = result.success ? '✅' : '❌';
      const statusCode = result.status ? `(${result.status})` : '';
      const duration = `${result.duration}ms`;
      
      console.log(`${status} ${endpoint.padEnd(12)} ${statusCode.padEnd(6)} ${duration.padStart(8)}`);
      
      if (!result.success) {
        console.log(`   Error: ${result.error}`);
      }
    }
  }
}

// Test backend identification
async function testBackendIdentification() {
  console.log('\n🆔 Testing Backend Identification');
  console.log('=' .repeat(50));
  
  for (const [name, baseUrl] of Object.entries(backends)) {
    const url = `${baseUrl}/api/failover-test?action=identify`;
    const result = await testEndpoint(url);
    
    if (result.success && result.data) {
      const data = result.data;
      console.log(`\n🏷️  ${name.toUpperCase()} Backend:`);
      console.log(`   Backend Type: ${data.backend || 'Unknown'}`);
      console.log(`   Message: ${data.message || 'No message'}`);
      console.log(`   Hostname: ${data.hostname || 'Unknown'}`);
      console.log(`   Environment: ${data.environment || 'Unknown'}`);
      console.log(`   Response Time: ${result.duration}ms`);
    } else {
      console.log(`\n❌ ${name.toUpperCase()} Backend: Failed to identify`);
      console.log(`   Error: ${result.error || 'Unknown error'}`);
    }
  }
}

// Test failover scenarios
async function testFailoverScenarios() {
  console.log('\n🔄 Testing Failover Scenarios');
  console.log('=' .repeat(50));
  
  const scenarios = [
    { action: 'delay', params: 'ms=5000', description: 'Slow response (5s delay)' },
    { action: 'error', params: '', description: 'Server error simulation' }
  ];
  
  for (const scenario of scenarios) {
    console.log(`\n🧪 Testing: ${scenario.description}`);
    console.log('-'.repeat(30));
    
    for (const [name, baseUrl] of Object.entries(backends)) {
      const params = scenario.params ? `&${scenario.params}` : '';
      const url = `${baseUrl}/api/failover-test?action=${scenario.action}${params}`;
      
      console.log(`   Testing ${name}...`);
      const result = await testEndpoint(url, 10000); // 10s timeout for delay test
      
      if (result.success) {
        console.log(`   ✅ ${name}: ${result.status} (${result.duration}ms)`);
      } else {
        console.log(`   ❌ ${name}: ${result.error} (${result.duration}ms)`);
      }
    }
  }
}

// Test connection speed comparison
async function testConnectionSpeed() {
  console.log('\n⚡ Connection Speed Comparison');
  console.log('=' .repeat(50));
  
  const results = {};
  
  for (const [name, baseUrl] of Object.entries(backends)) {
    const tests = [];
    
    // Run 3 tests for each backend
    for (let i = 0; i < 3; i++) {
      const result = await testEndpoint(`${baseUrl}/ping`);
      if (result.success) {
        tests.push(result.duration);
      }
    }
    
    if (tests.length > 0) {
      const avg = Math.round(tests.reduce((a, b) => a + b, 0) / tests.length);
      const min = Math.min(...tests);
      const max = Math.max(...tests);
      
      results[name] = { avg, min, max, tests };
      console.log(`📊 ${name.toUpperCase()}: Avg ${avg}ms, Min ${min}ms, Max ${max}ms`);
    } else {
      console.log(`❌ ${name.toUpperCase()}: No successful connections`);
    }
  }
  
  // Determine faster backend
  if (results.render && results.railway) {
    const faster = results.render.avg < results.railway.avg ? 'render' : 'railway';
    const difference = Math.abs(results.render.avg - results.railway.avg);
    console.log(`\n🏆 Faster Backend: ${faster.toUpperCase()} (${difference}ms faster on average)`);
  }
}

// Main function
async function main() {
  console.log('🚀 Backend Failover System Test');
  console.log('Testing backends for Bitcoin Cloud Mining app');
  console.log('Time:', new Date().toISOString());
  
  try {
    await testHealthEndpoints();
    await testBackendIdentification();
    await testConnectionSpeed();
    await testFailoverScenarios();
    
    console.log('\n✅ All tests completed!');
    console.log('\n💡 Tips:');
    console.log('   - Use the faster backend as primary in your Flutter app');
    console.log('   - Monitor health endpoints regularly');
    console.log('   - Test failover scenarios before production deployment');
    
  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    process.exit(1);
  }
}

// Handle command line arguments
const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) {
  console.log(`
Usage: node test-failover.js [options]

Options:
  --help, -h     Show this help message
  --health       Test only health endpoints
  --identify     Test only backend identification
  --speed        Test only connection speed
  --scenarios    Test only failover scenarios

Examples:
  node test-failover.js           # Run all tests
  node test-failover.js --health  # Test only health endpoints
  node test-failover.js --speed   # Test only connection speed
`);
  process.exit(0);
}

// Run specific tests based on arguments
if (args.includes('--health')) {
  testHealthEndpoints().then(() => process.exit(0));
} else if (args.includes('--identify')) {
  testBackendIdentification().then(() => process.exit(0));
} else if (args.includes('--speed')) {
  testConnectionSpeed().then(() => process.exit(0));
} else if (args.includes('--scenarios')) {
  testFailoverScenarios().then(() => process.exit(0));
} else {
  // Run all tests
  main();
}