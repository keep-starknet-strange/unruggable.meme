module.exports = {
  root: true,
  // Add common rules

  overrides: [
    {
      files: ['*.ts', '*.tsx', '*.js', '*.jsx'],
      rules: {
        'prettier/prettier': 'error'
      },
    },
  ],
}
