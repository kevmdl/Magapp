// Script para testar a funcionalidade dos novos status 3 e 4
const http = require('http');

function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 8080,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json; charset=utf-8'
      }
    };

    const req = http.request(options, (res) => {
      let responseData = '';
      res.setEncoding('utf8');
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData);
          resolve({ status: res.statusCode, data: parsed, headers: res.headers });
        } catch (e) {
          resolve({ status: res.statusCode, data: responseData, headers: res.headers });
        }
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function testNewStatusFunctionality() {
  console.log('=== TESTE DA FUNCIONALIDADE DE NOVOS STATUS ===\n');

  try {
    // 1. Buscar todos os pedidos
    console.log('1. Buscando todos os pedidos...');
    const pedidosResponse = await makeRequest('GET', '/api/pedidos');
    console.log(`Status: ${pedidosResponse.status}`);
    console.log(`Total de pedidos: ${pedidosResponse.data.data?.length || 0}`);
    
    if (!pedidosResponse.data.data || pedidosResponse.data.data.length === 0) {
      console.log('❌ Nenhum pedido encontrado para testar');
      return;
    }

    // Encontrar um pedido com status 1 (aprovado) para testar
    const pedidoAprovado = pedidosResponse.data.data.find(p => p.concluido === 1);
    
    if (!pedidoAprovado) {
      console.log('❌ Nenhum pedido com status 1 (aprovado) encontrado para testar');
      console.log('Pedidos disponíveis:', pedidosResponse.data.data.map(p => ({ id: p.idpedidos, status: p.concluido })));
      return;
    }

    console.log(`✅ Pedido encontrado para teste: ID ${pedidoAprovado.idpedidos} (Status: ${pedidoAprovado.concluido})`);
    console.log(`   Cliente: ${pedidoAprovado.nome_cliente}, Modelo: ${pedidoAprovado.modelo}\n`);

    // 2. Testar mudança para status 3 (pronto para retirada)
    console.log('2. Testando mudança para status 3 (pronto para retirada)...');
    const status3Response = await makeRequest('PUT', `/api/pedidos/${pedidoAprovado.idpedidos}/status`, {
      concluido: 3
    });
    
    console.log(`Status: ${status3Response.status}`);
    console.log(`Resposta: ${status3Response.data.message}`);
    console.log(`Sucesso: ${status3Response.data.success}`);

    if (status3Response.data.success) {
      console.log('✅ Status 3 aplicado com sucesso!\n');
      
      // 3. Testar mudança para status 4 (retirado)
      console.log('3. Testando mudança para status 4 (retirado)...');
      const status4Response = await makeRequest('PUT', `/api/pedidos/${pedidoAprovado.idpedidos}/status`, {
        concluido: 4
      });
      
      console.log(`Status: ${status4Response.status}`);
      console.log(`Resposta: ${status4Response.data.message}`);
      console.log(`Sucesso: ${status4Response.data.success}`);
      
      if (status4Response.data.success) {
        console.log('✅ Status 4 aplicado com sucesso!\n');
      } else {
        console.log('❌ Falha ao aplicar status 4\n');
      }
    } else {
      console.log('❌ Falha ao aplicar status 3\n');
    }

    // 4. Verificar o pedido após as mudanças
    console.log('4. Verificando estado final do pedido...');
    const finalResponse = await makeRequest('GET', '/api/pedidos');
    const pedidoFinal = finalResponse.data.data.find(p => p.idpedidos === pedidoAprovado.idpedidos);
    
    if (pedidoFinal) {
      console.log(`Estado final do pedido ${pedidoFinal.idpedidos}:`);
      console.log(`   Status (concluido): ${pedidoFinal.concluido}`);
      console.log(`   Data conclusão: ${pedidoFinal.data_conclusao}`);
      console.log(`   Mensagem rejeição: ${pedidoFinal.mensagem_rejeicao || 'N/A'}`);
      
      // Mapear status para texto
      const statusTexts = {
        0: 'Pendente',
        1: 'Aprovado',
        2: 'Rejeitado',
        3: 'Aprovado - Pronto para Retirada',
        4: 'Aprovado e Retirado'
      };
      
      console.log(`   Status em texto: ${statusTexts[pedidoFinal.concluido] || 'Desconhecido'}`);
      console.log('\n✅ TESTE CONCLUÍDO COM SUCESSO!');
    } else {
      console.log('❌ Pedido não encontrado após as mudanças');
    }

  } catch (error) {
    console.error('❌ Erro durante o teste:', error.message);
  }
}

testNewStatusFunctionality();
