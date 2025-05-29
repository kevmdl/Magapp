// Script de teste para verificar os novos status de pedidos
const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function testNewStatus() {
  try {
    console.log('🧪 Testando funcionalidade de novos status...\n');

    // Primeiro, vamos buscar todos os pedidos para ver se há algum disponível
    console.log('📋 Buscando pedidos existentes...');
    const pedidosResponse = await axios.get(`${BASE_URL}/pedidos`);
    
    if (pedidosResponse.data.success && pedidosResponse.data.data.length > 0) {
      const pedidos = pedidosResponse.data.data;
      console.log(`✅ Encontrados ${pedidos.length} pedidos`);
      
      // Encontrar um pedido pendente ou aprovado para testar
      const pedidoPendente = pedidos.find(p => p.concluido === 0);
      const pedidoAprovado = pedidos.find(p => p.concluido === 1);
      
      if (pedidoPendente) {
        console.log(`\n🔄 Testando aprovação do pedido #${pedidoPendente.idpedidos}...`);
        const approveResponse = await axios.put(
          `${BASE_URL}/pedidos/${pedidoPendente.idpedidos}/status`,
          { concluido: 1 }
        );
        console.log('✅ Resposta da aprovação:', approveResponse.data.message);
        
        // Agora testar status 3 (pronto para retirada)
        console.log(`\n📦 Testando status "pronto para retirada"...`);
        const readyResponse = await axios.put(
          `${BASE_URL}/pedidos/${pedidoPendente.idpedidos}/status`,
          { concluido: 3 }
        );
        console.log('✅ Resposta do status 3:', readyResponse.data.message);
        
        // Agora testar status 4 (retirado)
        console.log(`\n✅ Testando status "retirado"...`);
        const pickedResponse = await axios.put(
          `${BASE_URL}/pedidos/${pedidoPendente.idpedidos}/status`,
          { concluido: 4 }
        );
        console.log('✅ Resposta do status 4:', pickedResponse.data.message);
        
      } else if (pedidoAprovado) {
        // Se já temos um pedido aprovado, teste direto os status 3 e 4
        console.log(`\n📦 Testando status "pronto para retirada" em pedido já aprovado #${pedidoAprovado.idpedidos}...`);
        const readyResponse = await axios.put(
          `${BASE_URL}/pedidos/${pedidoAprovado.idpedidos}/status`,
          { concluido: 3 }
        );
        console.log('✅ Resposta do status 3:', readyResponse.data.message);
        
      } else {
        console.log('⚠️ Nenhum pedido pendente ou aprovado encontrado para teste');
      }
      
    } else {
      console.log('⚠️ Nenhum pedido encontrado. Criando um pedido de teste...');
      
      // Criar um pedido de teste
      const novoPedido = {
        nome_cliente: 'Teste Status',
        cpf: '123.456.789-00',
        placa: 'TST1234',
        renavam: '12345678901',
        chassi: '9BWTEST123456789',
        modelo: 'Teste',
        cor: 'Azul',
        usuario_id: 1
      };
      
      const createResponse = await axios.post(`${BASE_URL}/pedidos`, novoPedido);
      if (createResponse.data.success) {
        const novoPedidoId = createResponse.data.pedidoId;
        console.log(`✅ Pedido de teste criado com ID: ${novoPedidoId}`);
        
        // Testar todos os status
        for (let status = 1; status <= 4; status++) {
          console.log(`\n🔄 Testando status ${status}...`);
          const response = await axios.put(
            `${BASE_URL}/pedidos/${novoPedidoId}/status`,
            { concluido: status }
          );
          console.log(`✅ Status ${status}:`, response.data.message);
        }
      }
    }
    
    console.log('\n🎉 Teste concluído com sucesso!');
    
  } catch (error) {
    console.error('❌ Erro durante o teste:', error.response?.data || error.message);
  }
}

testNewStatus();
