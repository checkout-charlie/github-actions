module.exports = {
    root: true,
    env: {
        browser: true,
        node: true,
    },
    parserOptions: {
        parser: 'babel-eslint'
    },
    extends: [
    ],
    plugins: ['prettier'],
    rules: {
        'unicorn/prefer-text-content': 'off',
        yoda: [1, 'always', { onlyEquality: true }]
    }
}
