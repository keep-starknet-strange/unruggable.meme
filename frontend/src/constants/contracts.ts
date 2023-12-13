import { constants } from 'starknet'

export const UDC = constants.UDC

export const TOKEN_CLASS_HASH = process.env.REACT_APP_TOKEN_CLASS_HASH ?? ''
if (TOKEN_CLASS_HASH === '') {
  throw new Error(`REACT_APP_TOKEN_CLASS_HASH must be a defined environment variable`)
}
