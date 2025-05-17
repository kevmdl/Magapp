module.exports = {
  // Diretório raiz onde o Jest procurará arquivos
  rootDir: '.',

  // Ambiente de teste - Node.js
  testEnvironment: 'node',

  // Padrões de arquivos que são considerados testes
  testMatch: [
    '**/tests/**/*.[jt]s?(x)',
    '**/?(*.)+(spec|test).[jt]s?(x)'
  ],

  // Diretórios que o Jest deve ignorar
  testPathIgnorePatterns: [
    '/node_modules/'
  ],

  // Timeout para cada teste (em milissegundos)
  testTimeout: 10000,

  // Relatórios verbosos
  verbose: true,

  // Configuração da cobertura de código
  collectCoverage: true,
  coverageDirectory: 'coverage',
  collectCoverageFrom: ['**/*.{js,jsx}', '!**/node_modules/**', '!**/coverage/**'],

  // Permitir chamadas de mocks
  clearMocks: true
};