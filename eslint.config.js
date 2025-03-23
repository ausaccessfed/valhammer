/* eslint-disable no-undef */
const eslintPluginPrettierRecommended = require('eslint-plugin-prettier/recommended')
const eslintPluginYml = require('eslint-plugin-yml')
const eslint = require('@eslint/js')
const globals = require('globals')

const common = [
  eslintPluginPrettierRecommended,
  eslint.configs.recommended,
  ...eslintPluginYml.configs['flat/recommended'],
  {
    languageOptions: {
      parserOptions: {
        sourceType: 'module'
      },
      globals: {
        ...globals.browser,
        ...globals.node
      }
    },
    rules: {
      'class-methods-use-this': 'warn',
      'no-param-reassign': [
        'error',
        {
          props: false
        }
      ],
      'no-tabs': 'error',
      'no-plusplus': 'off',
      'no-underscore-dangle': 'off',
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      'import/extensions': 'off',
      'import/first': 'off',
      'import/no-unresolved': 'off',
      'prettier/prettier': 'error',
      'yml/plain-scalar': 'off',
      'yml/quotes': [
        'error',
        {
          prefer: 'single'
        }
      ],
      'yml/indent': 'off',
      'yml/sort-keys': 'off',
      'yml/no-empty-mapping-value': 'off',
      'yml/no-multiple-empty-lines': [
        'error',
        {
          max: 1
        }
      ],
      'yml/no-empty-document': 'off'
    },
    settings: {}
  },
  {
    ignores: [
      '.DS_Store',
      'node_modules/',
      'tmp/',
      'coverage/',
      '.vscode/',
      'yarn.lock',
      'Gemfile.lock',
      '.env*',
      '!.env*.dist',
      'coverage/',
      'public/assets/',
      '**/.terraform/',
      'tmp/*',
      '.idea/*',
      'dump.rdb',
      '*.iml',
      '**/kustomization.yaml',
      '**/templates/',
      '**/values.yaml',
      '**/templates/',
      '.github/',
      '.torba/'
    ]
  }
]

//EOF_DISTRIBUTION