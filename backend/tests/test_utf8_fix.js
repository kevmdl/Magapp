// Script para testar a correção UTF-8
const http = require('http');

function testUTF8() {  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/pedidos',
    method: 'GET',
    headers: {
      'Accept': 'application/json; charset=utf-8'
    }
  };

  const req = http.request(options, (res) => {
    console.log(`Status: ${res.statusCode}`);
    console.log(`Headers:`, res.headers);
    
    let data = '';
    res.setEncoding('utf8');
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      try {
        const parsed = JSON.parse(data);
        console.log('\n=== TESTE UTF-8 PEDIDOS ===');
        console.log('Success:', parsed.success);
        console.log('Total pedidos:', parsed.data?.length || 0);
        
        if (parsed.data && parsed.data.length > 0) {
          console.log('\n=== PRIMEIRO PEDIDO ===');
          const primeiro = parsed.data[0];
          console.log('Nome cliente:', primeiro.nome_cliente);
          console.log('Modelo:', primeiro.modelo);
          console.log('Cor:', primeiro.cor);
          console.log('Status (concluido):', primeiro.concluido);
          
          // Verificar se há caracteres especiais corretamente decodificados
          const temAcentos = /[áéíóúàèìòùãõâêîôûç]/i.test(JSON.stringify(primeiro));
          console.log('Tem acentos corretamente decodificados:', temAcentos);
        }
      } catch (e) {
        console.error('Erro ao parsear JSON:', e);
        console.log('Raw data:', data);
      }
    });
  });

  req.on('error', (e) => {
    console.error(`Erro na requisição: ${e.message}`);
  });

  req.end();
}

console.log('Testando correção UTF-8...');
testUTF8();
