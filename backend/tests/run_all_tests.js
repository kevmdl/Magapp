#!/usr/bin/env node

/**
 * Script para executar todos os testes principais do MagApp
 * Execute: node backend/tests/run_all_tests.js
 */

const { spawn } = require('child_process');
const path = require('path');

// Lista dos testes principais
const tests = [
  {
    name: 'Teste de Correção UTF-8',
    file: 'test_utf8_fix.js',
    description: 'Verifica decodificação de caracteres especiais'
  },
  {
    name: 'Teste de Transição de Status',
    file: 'test_status_transition.js', 
    description: 'Testa transições 1 → 3 → 4'
  },
  {
    name: 'Teste de Integração - Pedidos',
    file: 'pedidos-integration.js',
    description: 'Testa operações CRUD de pedidos'
  },
  {
    name: 'Teste de Integração - Banco de Dados',
    file: 'db-integration.js',
    description: 'Testa conexão com MySQL'
  }
];

async function runTest(testFile, testName) {
  return new Promise((resolve, reject) => {
    console.log(`\n🧪 Executando: ${testName}`);
    console.log('='.repeat(60));
    
    const testPath = path.join(__dirname, testFile);
    const child = spawn('node', [testPath], { 
      stdio: 'inherit',
      shell: true 
    });
    
    child.on('close', (code) => {
      if (code === 0) {
        console.log(`✅ ${testName} - SUCESSO`);
        resolve();
      } else {
        console.log(`❌ ${testName} - FALHOU (código: ${code})`);
        reject(new Error(`Teste falhou: ${testName}`));
      }
    });
    
    child.on('error', (err) => {
      console.log(`❌ ${testName} - ERRO: ${err.message}`);
      reject(err);
    });
  });
}

async function runAllTests() {
  console.log('🚀 MagApp - Executando Todos os Testes');
  console.log('='.repeat(60));
  console.log(`📅 ${new Date().toLocaleString()}`);
  console.log(`📁 Pasta: ${__dirname}`);
  console.log(`📊 Total de testes: ${tests.length}\n`);
  
  let passed = 0;
  let failed = 0;
  const results = [];
  
  for (const test of tests) {
    try {
      await runTest(test.file, test.name);
      passed++;
      results.push({ name: test.name, status: 'PASSOU', error: null });
    } catch (error) {
      failed++;
      results.push({ name: test.name, status: 'FALHOU', error: error.message });
    }
    
    // Pausa entre testes
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  // Relatório final
  console.log('\n' + '='.repeat(60));
  console.log('📊 RELATÓRIO FINAL DOS TESTES');
  console.log('='.repeat(60));
  
  results.forEach(result => {
    const status = result.status === 'PASSOU' ? '✅' : '❌';
    console.log(`${status} ${result.name}`);
    if (result.error) {
      console.log(`   └─ Erro: ${result.error}`);
    }
  });
  
  console.log(`\n📈 Resumo: ${passed} passou(ram), ${failed} falhou(falharam)`);
  console.log(`🎯 Taxa de sucesso: ${Math.round((passed / tests.length) * 100)}%`);
  
  if (failed === 0) {
    console.log('\n🎉 TODOS OS TESTES PASSARAM!');
    process.exit(0);
  } else {
    console.log('\n⚠️  ALGUNS TESTES FALHARAM');
    process.exit(1);
  }
}

// Verificar se o servidor está rodando
console.log('🔍 Verificando se o servidor está rodando na porta 3000...');

const http = require('http');
const checkServer = http.request({
  hostname: 'localhost',
  port: 3000,
  path: '/api/pedidos',
  method: 'GET',
  timeout: 3000
}, (res) => {
  console.log('✅ Servidor está rodando!\n');
  runAllTests();
});

checkServer.on('error', (err) => {
  console.log('❌ Servidor não está rodando na porta 3000!');
  console.log('💡 Execute: node backend/app.js');
  console.log(`🔧 Erro: ${err.message}\n`);
  process.exit(1);
});

checkServer.on('timeout', () => {
  console.log('⏰ Timeout ao conectar com o servidor');
  console.log('💡 Verifique se o servidor está rodando: node backend/app.js\n');
  process.exit(1);
});

checkServer.end();
