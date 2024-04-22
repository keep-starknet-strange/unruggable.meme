/* eslint-disable import/no-unused-modules */
import { defineConfig, Options } from 'tsup'

const commonConfig: Options = {
  entry: ['src/index.ts'],
  sourcemap: true,
  clean: true,
  globalName: 'sdk.core',
}

export default defineConfig([
  {
    ...commonConfig,
    format: ['cjs', 'esm'],
    platform: 'node',
    dts: true,
  },
  {
    ...commonConfig,
    format: ['iife'],
    platform: 'browser',
  },
])
