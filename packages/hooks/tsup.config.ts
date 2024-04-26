/* eslint-disable import/no-unused-modules */
import { defineConfig } from 'tsup'

export default defineConfig([
  {
    entry: ['src/index.ts'],
    sourcemap: true,
    clean: true,
    globalName: 'sdk.hooks',
    format: ['cjs', 'esm', 'iife'],
    platform: 'browser',
    dts: true,
  },
])
