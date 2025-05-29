const http = require('http');

// Configuração
const baseUrl = 'http://localhost:3000';

// Função helper para fazer requisições
function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const jsonResponse = JSON.parse(body);
          resolve({ status: res.statusCode, data: jsonResponse });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

// Função para testar transição de status
async function testStatusTransition() {
  console.log('🧪 Testando transição de status 3 → 4\n');

  try {
    // 1. Buscar todos os pedidos
    console.log('1. Buscando pedidos...');
    const getPedidos = await makeRequest({
      hostname: 'localhost',
      port: 3000,
      path: '/api/pedidos',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    if (getPedidos.status !== 200) {
      throw new Error(`Erro ao buscar pedidos: ${getPedidos.status}`);
    }

    const pedidos = getPedidos.data.data;
    console.log(`✅ Encontrados ${pedidos.length} pedidos`);

    // 2. Encontrar um pedido aprovado (status 1) para testar
    let testPedido = pedidos.find(p => p.concluido === 1);
    
    if (!testPedido) {
      // Se não há pedido com status 1, vamos procurar um com status 0 e aprovar primeiro
      testPedido = pedidos.find(p => p.concluido === 0);
      
      if (!testPedido) {
        console.log('❌ Nenhum pedido disponível para teste');
        return;
      }

      console.log(`2. Aprovando pedido ${testPedido.idpedidos} primeiro...`);
      const aproveResult = await makeRequest({
        hostname: 'localhost',
        port: 3000,
        path: `/api/pedidos/${testPedido.idpedidos}/status`,
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        }
      }, { concluido: 1 });

      if (aproveResult.status !== 200) {
        throw new Error(`Erro ao aprovar pedido: ${aproveResult.status}`);
      }
      
      testPedido.concluido = 1;
      console.log('✅ Pedido aprovado com sucesso');
    }

    // 3. Alterar para status 3 (Pronto para Retirada)
    console.log(`3. Alterando pedido ${testPedido.idpedidos} para status 3 (Pronto para Retirada)...`);
    const status3Result = await makeRequest({
      hostname: 'localhost',
      port: 3000,
      path: `/api/pedidos/${testPedido.idpedidos}/status`,
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      }
    }, { concluido: 3 });

    if (status3Result.status !== 200) {
      throw new Error(`Erro ao alterar para status 3: ${status3Result.status}`);
    }

    console.log('✅ Status alterado para 3:', status3Result.data.message);

    // 4. Alterar para status 4 (Retirado)
    console.log(`4. Alterando pedido ${testPedido.idpedidos} para status 4 (Retirado)...`);
    const status4Result = await makeRequest({
      hostname: 'localhost',
      port: 3000,
      path: `/api/pedidos/${testPedido.idpedidos}/status`,
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      }
    }, { concluido: 4 });

    if (status4Result.status !== 200) {
      throw new Error(`Erro ao alterar para status 4: ${status4Result.status}`);
    }

    console.log('✅ Status alterado para 4:', status4Result.data.message);

    // 5. Verificar o status final
    console.log('5. Verificando status final...');
    const finalCheck = await makeRequest({
      hostname: 'localhost',
      port: 3000,
      path: '/api/pedidos',
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const updatedPedido = finalCheck.data.data.find(p => p.idpedidos === testPedido.idpedidos);
    
    console.log('\n📊 RESULTADO DO TESTE:');
    console.log(`Pedido ID: ${testPedido.idpedidos}`);
    console.log(`Status final: ${updatedPedido.concluido}`);
    console.log(`Placa: ${updatedPedido.placa}`);
    
    if (updatedPedido.concluido === 4) {
      console.log('🎉 SUCESSO! Transição 1 → 3 → 4 funcionou perfeitamente!');
    } else {
      console.log('❌ ERRO! Status final não é 4');
    }

  } catch (error) {
    console.error('❌ Erro durante o teste:', error.message);
  }
}

// Executar o teste
testStatusTransition();
