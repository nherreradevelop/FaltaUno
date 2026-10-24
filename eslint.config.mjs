// Configuración única de ESLint para todo el repositorio (api, web y mobile).
// Se ejecuta desde la raíz: npm run lint
import js from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';
import reactHooks from 'eslint-plugin-react-hooks';

export default tseslint.config(
  // Carpetas que no se revisan
  {
    ignores: [
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/coverage/**',
      '**/.expo/**',
      'mobile/android/**',
      'mobile/ios/**',
      'n8n/**',
    ],
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

  // API (Node.js)
  {
    files: ['api/**/*.{ts,js,mjs,cjs}'],
    languageOptions: { globals: { ...globals.node } },
  },

  // Web (React en el navegador)
  {
    files: ['web/**/*.{ts,tsx,js,jsx}'],
    languageOptions: { globals: { ...globals.browser } },
    plugins: { 'react-hooks': reactHooks },
    rules: { ...reactHooks.configs.recommended.rules },
  },

  // App móvil (React Native con Expo)
  {
    files: ['mobile/**/*.{ts,tsx,js,jsx}'],
    languageOptions: { globals: { ...globals.browser, __DEV__: 'readonly' } },
    plugins: { 'react-hooks': reactHooks },
    rules: { ...reactHooks.configs.recommended.rules },
  },

  // Archivos de configuración (babel.config.js, metro.config.js, etc.)
  {
    files: ['**/*.config.{js,cjs,mjs}', '**/*.cjs'],
    languageOptions: { globals: { ...globals.node } },
    rules: { '@typescript-eslint/no-require-imports': 'off' },
  },
);
