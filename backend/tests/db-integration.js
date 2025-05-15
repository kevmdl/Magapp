const db = require('../config/mock-db');

// Configuração dos testes de integração com banco de dados
describe('Testes de Integração com Banco de Dados', () => {
  // Inicializar o banco de teste antes de todos os testes
  beforeAll(async () => {
    console.log('Iniciando banco de dados de teste...');
    await db.initTestDatabase();
  });

  // Limpar os dados entre cada teste
  beforeEach(async () => {
    await db.clearTestDatabase();
  });

  // Fechar a conexão após todos os testes
  afterAll(async () => {
    await db.closeDatabase();
  });

  // Teste de inserção de dados na tabela usuário
  test('Deve inserir um usuário no banco de dados', async () => {
    // Dados para o teste
    const usuario = {
      nome: 'Usuário Teste',
      email: 'teste@exemplo.com',
      senha: 'senha123',
      avatar: 'default.jpg',
      is_online: true
    };

    // Executar a query de inserção
    const result = await db.query(
      'INSERT INTO usuario (nome, email, senha, avatar, is_online) VALUES (?, ?, ?, ?, ?)',
      [usuario.nome, usuario.email, usuario.senha, usuario.avatar, usuario.is_online]
    );

    // Verificar se um registro foi inserido
    expect(result.affectedRows).toBe(1);
    expect(result.insertId).toBeGreaterThan(0);

    // Confirmar se os dados foram inseridos corretamente
    const [insertedUser] = await db.query('SELECT * FROM usuario WHERE id = ?', [result.insertId]);
    expect(insertedUser).toBeDefined();
    expect(insertedUser.nome).toBe(usuario.nome);
    expect(insertedUser.email).toBe(usuario.email);
  });

  // Teste de atualização de dados
  test('Deve atualizar os dados de um usuário', async () => {
    // Inserir um usuário primeiro
    const result = await db.query(
      'INSERT INTO usuario (nome, email, senha, avatar, is_online) VALUES (?, ?, ?, ?, ?)',
      ['João Silva', 'joao@exemplo.com', 'senha123', 'avatar.jpg', true]
    );
    const userId = result.insertId;

    // Atualizar os dados
    const updateResult = await db.query(
      'UPDATE usuario SET nome = ?, avatar = ? WHERE id = ?',
      ['João Silva Atualizado', 'novo_avatar.jpg', userId]
    );

    expect(updateResult.affectedRows).toBe(1);

    // Verificar se os dados foram atualizados
    const [updatedUser] = await db.query('SELECT * FROM usuario WHERE id = ?', [userId]);
    expect(updatedUser.nome).toBe('João Silva Atualizado');
    expect(updatedUser.avatar).toBe('novo_avatar.jpg');
    // O email não deve ter sido alterado
    expect(updatedUser.email).toBe('joao@exemplo.com');
  });

  // Teste de exclusão de registros
  test('Deve excluir um usuário do banco de dados', async () => {
    // Inserir um usuário primeiro
    const result = await db.query(
      'INSERT INTO usuario (nome, email, senha) VALUES (?, ?, ?)',
      ['Maria Santos', 'maria@exemplo.com', 'senha456']
    );
    const userId = result.insertId;

    // Confirmar que o usuário foi inserido
    let [user] = await db.query('SELECT * FROM usuario WHERE id = ?', [userId]);
    expect(user).toBeDefined();

    // Excluir o usuário
    const deleteResult = await db.query('DELETE FROM usuario WHERE id = ?', [userId]);
    expect(deleteResult.affectedRows).toBe(1);

    // Verificar se o usuário foi excluído
    const [deletedUser] = await db.query('SELECT * FROM usuario WHERE id = ?', [userId]);
    expect(deletedUser).toBeUndefined();
  });

  // Teste de consulta com filtros
  test('Deve buscar usuários por filtros', async () => {
    // Inserir vários usuários
    await db.query(
      'INSERT INTO usuario (nome, email, senha, is_online) VALUES (?, ?, ?, ?)',
      ['Carlos Silva', 'carlos@exemplo.com', 'senha123', true]
    );
    await db.query(
      'INSERT INTO usuario (nome, email, senha, is_online) VALUES (?, ?, ?, ?)',
      ['Ana Silva', 'ana@exemplo.com', 'senha456', true]
    );
    await db.query(
      'INSERT INTO usuario (nome, email, senha, is_online) VALUES (?, ?, ?, ?)',
      ['Pedro Santos', 'pedro@exemplo.com', 'senha789', false]
    );

    // Buscar usuários com nome contendo "Silva"
    const usersWithSilva = await db.query("SELECT * FROM usuario WHERE nome LIKE ?", ['%Silva%']);
    expect(usersWithSilva.length).toBe(2);

    // Buscar usuários online
    const onlineUsers = await db.query("SELECT * FROM usuario WHERE is_online = ?", [true]);
    expect(onlineUsers.length).toBe(2);

    // Buscar usuário específico por email
    const [specificUser] = await db.query("SELECT * FROM usuario WHERE email = ?", ['pedro@exemplo.com']);
    expect(specificUser).toBeDefined();
    expect(specificUser.nome).toBe('Pedro Santos');
    expect(specificUser.is_online).toBe(0); // false em MySQL é representado como 0
  });

  // Teste de inserção na tabela de pedidos
  test('Deve inserir e recuperar um pedido', async () => {
    // Dados do pedido
    const pedido = {
      nome: 'Cliente Teste',
      cpf_cnpj: '123.456.789-00',
      placa: 'ABC1234',
      renavam: '12345678901',
      chassi: '9BWZZZ377VT004251',
      status: 'pendente'
    };

    // Inserir pedido
    const result = await db.query(
      'INSERT INTO pedidos (nome, cpf_cnpj, placa, renavam, chassi, status) VALUES (?, ?, ?, ?, ?, ?)',
      [pedido.nome, pedido.cpf_cnpj, pedido.placa, pedido.renavam, pedido.chassi, pedido.status]
    );

    expect(result.affectedRows).toBe(1);
    
    // Recuperar o pedido inserido
    const [insertedOrder] = await db.query('SELECT * FROM pedidos WHERE id = ?', [result.insertId]);
    expect(insertedOrder).toBeDefined();
    expect(insertedOrder.nome).toBe(pedido.nome);
    expect(insertedOrder.cpf_cnpj).toBe(pedido.cpf_cnpj);
    expect(insertedOrder.placa).toBe(pedido.placa);
    expect(insertedOrder.status).toBe('pendente');
  });

  // Teste de atualização de status de pedido
  test('Deve atualizar o status de um pedido', async () => {
    // Inserir um pedido
    const result = await db.query(
      'INSERT INTO pedidos (nome, cpf_cnpj, placa) VALUES (?, ?, ?)',
      ['Maria Oliveira', '987.654.321-00', 'XYZ5678']
    );
    const pedidoId = result.insertId;

    // Atualizar o status
    const updateResult = await db.query(
      'UPDATE pedidos SET status = ? WHERE id = ?',
      ['aprovado', pedidoId]
    );

    expect(updateResult.affectedRows).toBe(1);

    // Verificar se o status foi atualizado
    const [updatedOrder] = await db.query('SELECT * FROM pedidos WHERE id = ?', [pedidoId]);
    expect(updatedOrder.status).toBe('aprovado');
  });

  // Teste de transações (garantir atomicidade)
  test('Deve garantir atomicidade em operações com transação', async () => {
    // Iniciar uma transação
    const connection = await db.pool.getConnection();
    try {
      await connection.beginTransaction();

      // Inserir um pedido na transação
      await connection.query(
        'INSERT INTO pedidos (nome, cpf_cnpj, placa) VALUES (?, ?, ?)',
        ['Transação Teste', '111.222.333-44', 'TRA1234']
      );

      // Propositalmente causar um erro (chave duplicada)
      // Isso deve fazer com que toda a transação seja revertida
      await connection.query(
        'INSERT INTO usuario (nome, email, senha) VALUES (?, ?, ?)',
        ['Usuário Teste', 'teste@exemplo.com', 'senha123']
      );

      // Esta linha não deve ser executada, pois a instrução anterior deve falhar
      await connection.query(
        'INSERT INTO usuario (nome, email, senha) VALUES (?, ?, ?)',
        ['Usuário Dois', 'usuario2@exemplo.com', 'senha456']
      );

      await connection.commit();
    } catch (error) {
      // Se ocorrer erro, reverter a transação
      await connection.rollback();
    } finally {
      connection.release();
    }

    // Verificar se nenhum pedido foi inserido após o rollback
    const pedidos = await db.query('SELECT * FROM pedidos WHERE nome = ?', ['Transação Teste']);
    expect(pedidos.length).toBe(0);
  });
});