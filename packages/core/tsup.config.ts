/* eslint-disable import/no-unused-modules */
import { defineConfig, Options } from 'tsup'

const getConfig = (config: Options): Options[] => {
  return [
    {
      ...config,
      format: ['cjs', 'esm'],
      platform: 'node',
      dts: true,
    },
    {
      ...config,
      format: ['iife'],
      platform: 'browser',
    },
  ]
}

export default defineConfig([
  // Default entrypoint
  ...getConfig({
    entry: ['src/index.ts'],
    outDir: 'dist',
    sourcemap: true,
    clean: false,
    globalName: 'sdk.core',
  }),

  ...getConfig({
    entry: ['src/constants/index.ts'],
    outDir: 'dist/constants',
    sourcemap: true,
    clean: false,
    globalName: 'sdk.core.constants',
  }),
])
