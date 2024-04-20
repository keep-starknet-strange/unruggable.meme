/* eslint-disable import/no-unused-modules */
import { defineConfig } from 'tsup'

export default defineConfig({
  entry: ['src/index.ts'],
  sourcemap: true,
  clean: true,
  format: ['cjs'],
  globalName: 'sdk.core',
})
