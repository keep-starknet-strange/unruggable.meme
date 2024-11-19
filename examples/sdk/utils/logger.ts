function getTimestamp(): string {
  return new Date().toISOString()
}

export const logger = {
  info: (...args: any[]) => {
    console.log(`${getTimestamp()} [INFO]:`, ...args)
  },
  error: (...args: any[]) => {
    console.error(`${getTimestamp()} [ERROR]:`, ...args)
  },
  warn: (...args: any[]) => {
    console.warn(`${getTimestamp()} [WARN]:`, ...args)
  },
}
