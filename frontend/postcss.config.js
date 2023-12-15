module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
    // Add other paths here if necessary
  ],
  plugins: {
    'postcss-import': {},
    'tailwindcss/nesting': 'postcss-nesting',
    tailwindcss: {},
    autoprefixer: {},
  }
}
