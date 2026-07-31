module.exports = {
  root: true,
  env: {
    browser: true,
    es2022: true,
    node: true,
  },
  extends: ['eslint:recommended', 'plugin:vue/vue3-essential'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  ignorePatterns: ['dist/**', 'node_modules/**'],
  rules: {
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'vue/valid-v-slot': 'off',
  },
}
