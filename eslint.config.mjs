// Configuración de ESLint del repositorio de la API.
// Se ejecuta desde la raíz: npm run lint
import js from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  // Carpetas que no se revisan
  {
    ignores: ['**/node_modules/**', '**/dist/**', '**/build/**', '**/coverage/**', 'n8n/**'],
  },

  // Reglas base para todo el código JavaScript y TypeScript
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
    },
  },

  // Todo el repositorio corre en Node.js
  {
    files: ['**/*.{ts,js,mjs,cjs}'],
    languageOptions: { globals: { ...globals.node } },
  },

  // Archivos de configuración en CommonJS
  {
    files: ['**/*.config.{js,cjs,mjs}', '**/*.cjs'],
    rules: { '@typescript-eslint/no-require-imports': 'off' },
  },
);
