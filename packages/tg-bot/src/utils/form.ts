import { CallbackQuery, Message } from 'node-telegram-bot-api'
import { ZodSchema } from 'zod'

import { bot } from '../services/bot'
import { validateAndSend } from './validation'

const FORM_CHOICE_PREFIX = 'form_choice'

type Form = ReturnType<typeof createForm<any>>

export const Forms = new (class Forms {
  forms: Record<number, Form> = {}

  getForm(chatId: number): Form {
    return this.forms[chatId]
  }

  resetForm(chatId: number) {
    delete this.forms[chatId]
  }

  setForm(chatId: number, form: any) {
    this.forms[chatId] = form
  }
})()

type TextField<TSchema extends ZodSchema> = {
  type: 'text'
  validation?: TSchema
  handler: (data: { value: TSchema['_output']; msg: Message }) => void
}

type ChoiceField = {
  type: 'choice'
  choices: { key: string; title: string }[]
  handler: (data: { value: string; query: CallbackQuery }) => void
}

type Field<TValue, TSchema extends ZodSchema> = {
  value: TValue
  message?: string | (() => string)
} & (TextField<TSchema> | ChoiceField)

// Does nothing, used for type inference
export function defineField<TValue, TSchema extends ZodSchema>(field: Field<TValue, TSchema>) {
  return field
}

export function createForm<TFields extends Record<string, Field<any, any>>>(chatId: number, fields: TFields) {
  let activeField: keyof TFields | null = null

  const getValues = (): { [K in keyof TFields]: TFields[K]['value'] } => {
    return Object.fromEntries(Object.entries(fields).map(([key, field]) => [key, field.value])) as any
  }

  const setValue = <TKey extends keyof TFields>(field: TKey, value: TFields[TKey]['value']) => {
    fields[field].value = value
  }

  const setActiveField = (field: keyof TFields) => {
    activeField = field

    const fieldData = fields[field]
    const message = fieldData.message
      ? typeof fieldData.message === 'string'
        ? fieldData.message
        : fieldData.message()
      : undefined

    if (fieldData.type === 'text' && message) {
      bot.sendMessage(chatId, message, { parse_mode: 'Markdown' })
      return
    }

    if (fieldData.type === 'choice' && fieldData.choices) {
      const keyboard = [
        fieldData.choices.map(({ key, title }) => ({
          text: title,
          callback_data: `${FORM_CHOICE_PREFIX}_${String(field)}_${key}`,
        })),
      ]

      bot.sendMessage(chatId, message ?? '', {
        reply_markup: {
          inline_keyboard: keyboard,
        },
        parse_mode: 'Markdown',
      })
      return
    }
  }

  const getActiveField = () => {
    return activeField
  }

  return {
    fields,

    getValues,
    setValue,

    getActiveField,
    setActiveField,
  }
}

bot.on('message', (msg) => {
  if (!msg.text || msg.text.startsWith('/')) return

  const form = Forms.getForm(msg.chat.id)
  if (!form) return

  const activeField = form.getActiveField()
  if (!activeField || !form.fields[activeField]) return

  const field = form.fields[activeField] as Field<any, any>
  if (field.type !== 'text') return

  let value: string | false = msg.text
  if (field.validation) {
    value = validateAndSend(msg.chat.id, msg.text, field.validation)
    if (value === false) return
  }

  field.handler({
    msg,
    value,
  })
})

bot.on('callback_query', (query) => {
  if (!query.data || !query.message || !query.data.startsWith(FORM_CHOICE_PREFIX)) return
  const chatId = query.message.chat.id

  const form = Forms.getForm(chatId)
  if (!form) return

  const activeField = form.getActiveField()
  if (!activeField || !form.fields[activeField]) return

  const field = form.fields[activeField] as Field<any, any>
  if (field.type !== 'choice' || !query.data.startsWith(`${FORM_CHOICE_PREFIX}_${String(activeField)}_`)) return

  field.handler({
    query,
    value: query.data.replace(`${FORM_CHOICE_PREFIX}_${String(activeField)}_`, ''),
  })
})
