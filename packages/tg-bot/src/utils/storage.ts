import { BaseAdapter } from '../adapters/BaseAdapter'

export const adapterStorage = new (class AdapterStorage {
  public adapters: Record<number, BaseAdapter> = {}

  public addAdapter = (chatId: number, adapter: BaseAdapter): void => {
    this.adapters[chatId] = adapter
  }

  public removeAdapter = (chatId: number): void => {
    delete this.adapters[chatId]
  }

  public getAdapter = (chatId: number): BaseAdapter | undefined => {
    return this.adapters[chatId]
  }
})()
