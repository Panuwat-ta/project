import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import { defineConfig, globalIgnores } from 'eslint/config'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{js,jsx}'],
    extends: [
      js.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      globals: globals.browser,
      parserOptions: { ecmaFeatures: { jsx: true } },
    },
    rules: {
      // Async data fetching in useEffect is standard React pattern, not cascading renders
      'react-hooks/set-state-in-effect': 'off',
      // Catch TDZ/self-reference regressions such as `const value = value?.x`
      'no-use-before-define': ['error', { functions: false, classes: true, variables: true }],
      // Allow non-component exports (e.g. useTheme hook) alongside components
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
    },
  },
])
