const mockDb = require('../config/mock-db');

// Função que simula um repositório de pedidos usando o mock-db
const pedidosRepository = {
  async criar(pedido) {
    const result = await mockDb.query(
      'INSERT INTO pedidos (nome, cpf_cnpj, placa, renavam, chassi, status) VALUES (?, ?, ?, ?, ?, ?)',
      [pedido.nome, pedido.cpf_cnpj, pedido.placa, pedido.renavam, pedido.chassi, pedido.status || 'pendente']
    );
    return { id: result.insertId, ...pedido };
  },
  
  async buscarPorId(id) {
    const [pedido] = await mockDb.query('SELECT * FROM pedidos WHERE id = ?', [id]);
    return pedido;
  },
  
  async listarTodos() {
    return await mockDb.query('SELECT * FROM pedidos ORDER BY criado_em DESC');
  },
  
  async atualizar(id, dados) {
    const fieldsToUpdate = Object.keys(dados)
      .filter(key => key !== 'id')
      .map(key => `${key} = ?`);
      
    const values = Object.values(dados).filter(val => typeof val !== 'undefined');
    values.push(id);
    
    const query = `UPDATE pedidos SET ${fieldsToUpdate.join(', ')} WHERE id = ?`;
    const result = await mockDb.query(query, values);
    
    return result.affectedRows > 0;
  },
  
  async excluir(id) {
    const result = await mockDb.query('DELETE FROM pedidos WHERE id = ?', [id]);
    return result.affectedRows > 0;
  },
  
  async buscarPorFiltros(filtros) {
    let query = 'SELECT * FROM pedidos WHERE 1=1';
    const params = [];
    
    if (filtros.nome) {
      query += ' AND nome LIKE ?';
      params.push(`%${filtros.nome}%`);
    }
    
    if (filtros.cpf_cnpj) {
      query += ' AND cpf_cnpj = ?';
      params.push(filtros.cpf_cnpj);
    }
    
    if (filtros.placa) {
      query += ' AND placa = ?';
      params.push(filtros.placa);
    }
    
    if (filtros.status) {
      query += ' AND status = ?';
      params.push(filtros.status);
    }
    
    return await mockDb.query(query, params);
  }
};

// Testes de integração usando o mock-db
describe('Testes de integração com mock do banco de dados', () => {
  // Inicializar o banco de teste antes de todos os testes
  beforeAll(async () => {
    console.log('Iniciando banco de dados mock para testes...');
    await mockDb.initTestDatabase();
  });

  // Limpar os dados entre cada teste
  beforeEach(async () => {
    await mockDb.clearTestDatabase();
  });

  // Fechar a conexão após todos os testes
  afterAll(async () => {
    await mockDb.closeDatabase();
  });

  // Testes do repositório de pedidos
  describe('Repositório de Pedidos', () => {
    test('Deve criar um novo pedido', async () => {
      const novoPedido = {
        nome: 'João da Silva',
        cpf_cnpj: '123.456.789-00',
        placa: 'ABC1234',
        renavam: '12345678901',
        chassi: '9BWZZZ377VT004251',
        status: 'pendente'
      };
      
      const pedidoCriado = await pedidosRepository.criar(novoPedido);
      expect(pedidoCriado.id).toBeDefined();
      expect(pedidoCriado.nome).toBe(novoPedido.nome);
      expect(pedidoCriado.cpf_cnpj).toBe(novoPedido.cpf_cnpj);
      
      // Verificar se o pedido foi realmente inserido no banco
      const pedidoInserido = await pedidosRepository.buscarPorId(pedidoCriado.id);
      expect(pedidoInserido).toBeDefined();
      expect(pedidoInserido.nome).toBe(novoPedido.nome);
    });
    
    test('Deve listar todos os pedidos', async () => {
      // Inserir alguns pedidos de teste
      await pedidosRepository.criar({
        nome: 'Cliente 1',
        cpf_cnpj: '111.111.111-11',
        placa: 'AAA1111',
        status: 'pendente'
      });
      
      await pedidosRepository.criar({
        nome: 'Cliente 2',
        cpf_cnpj: '222.222.222-22',
        placa: 'BBB2222',
        status: 'aprovado'
      });
      
      await pedidosRepository.criar({
        nome: 'Cliente 3',
        cpf_cnpj: '333.333.333-33',
        placa: 'CCC3333',
        status: 'concluído'
      });
      
      const pedidos = await pedidosRepository.listarTodos();
      expect(pedidos).toHaveLength(3);
      
      // Verificar se os pedidos foram retornados na ordem correta (mais recentes primeiro)
      expect(pedidos[0].nome).toBe('Cliente 3');
      expect(pedidos[1].nome).toBe('Cliente 2');
      expect(pedidos[2].nome).toBe('Cliente 1');
    });
    
    test('Deve atualizar um pedido existente', async () => {
      // Criar um pedido
      const pedido = await pedidosRepository.criar({
        nome: 'Maria Oliveira',
        cpf_cnpj: '444.444.444-44',
        placa: 'DDD4444',
        status: 'pendente'
      });
      
      // Atualizar o pedido
      const atualizacao = {
        status: 'aprovado',
        placa: 'DDD4455'
      };
      
      const sucesso = await pedidosRepository.atualizar(pedido.id, atualizacao);
      expect(sucesso).toBe(true);
      
      // Verificar se o pedido foi atualizado
      const pedidoAtualizado = await pedidosRepository.buscarPorId(pedido.id);
      expect(pedidoAtualizado.status).toBe('aprovado');
      expect(pedidoAtualizado.placa).toBe('DDD4455');
      // O nome não deve ter sido alterado
      expect(pedidoAtualizado.nome).toBe('Maria Oliveira');
    });
    
    test('Deve excluir um pedido existente', async () => {
      // Criar um pedido
      const pedido = await pedidosRepository.criar({
        nome: 'Pedro Santos',
        cpf_cnpj: '555.555.555-55',
        placa: 'EEE5555',
        status: 'pendente'
      });
      
      // Verificar se o pedido foi criado
      const pedidoCriado = await pedidosRepository.buscarPorId(pedido.id);
      expect(pedidoCriado).toBeDefined();
      
      // Excluir o pedido
      const sucesso = await pedidosRepository.excluir(pedido.id);
      expect(sucesso).toBe(true);
      
      // Verificar se o pedido foi excluído
      const pedidoExcluido = await pedidosRepository.buscarPorId(pedido.id);
      expect(pedidoExcluido).toBeUndefined();
    });
    
    test('Deve buscar pedidos por filtros', async () => {
      // Criar vários pedidos para teste
      await pedidosRepository.criar({
        nome: 'Ana Silva',
        cpf_cnpj: '666.666.666-66',
        placa: 'FFF6666',
        status: 'pendente'
      });
      
      await pedidosRepository.criar({
        nome: 'Ana Oliveira',
        cpf_cnpj: '777.777.777-77',
        placa: 'GGG7777',
        status: 'aprovado'
      });
      
      await pedidosRepository.criar({
        nome: 'Carlos Silva',
        cpf_cnpj: '888.888.888-88',
        placa: 'HHH8888',
        status: 'pendente'
      });
      
      // Buscar por nome
      const pedidosAna = await pedidosRepository.buscarPorFiltros({ nome: 'Ana' });
      expect(pedidosAna).toHaveLength(2);
      
      // Buscar por nome e status
      const anasPendentes = await pedidosRepository.buscarPorFiltros({ 
        nome: 'Ana',
        status: 'pendente'
      });
      expect(anasPendentes).toHaveLength(1);
      expect(anasPendentes[0].nome).toBe('Ana Silva');
      
      // Buscar por placa exata
      const pedidoPorPlaca = await pedidosRepository.buscarPorFiltros({ placa: 'GGG7777' });
      expect(pedidoPorPlaca).toHaveLength(1);
      expect(pedidoPorPlaca[0].nome).toBe('Ana Oliveira');
      
      // Buscar por status
      const pedidosPendentes = await pedidosRepository.buscarPorFiltros({ status: 'pendente' });
      expect(pedidosPendentes).toHaveLength(2);
    });
  });
  
  // Teste de cenário de erro
  describe('Tratamento de Erros', () => {
    test('Deve lidar com erros de consulta SQL', async () => {
      try {
        // Tentar executar uma query inválida
        await mockDb.query('SELECT * FROM tabela_inexistente');
        fail('A consulta deveria ter falhado');
      } catch (error) {
        expect(error).toBeDefined();
        // Verifica se a mensagem de erro contém informações sobre a tabela inexistente
        expect(error.message).toContain("tabela_inexistente");
      }
    });
  });
});