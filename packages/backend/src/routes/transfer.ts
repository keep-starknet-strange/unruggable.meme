import { eq } from 'drizzle-orm'
import express from 'express'

import { db, transfer } from '../services/db'
import { ErrorCode } from '../utils/error'
import { isValidStarknetAddress } from '../utils/helpers'
import { HTTPStatus } from '../utils/http'

const Router = express.Router()

Router.get('/', async (req, res) => {
  try {
    const transfers = await db.select().from(transfer)

    res.status(HTTPStatus.OK).send(transfers)
  } catch (error) {
    res.status(HTTPStatus.InternalServerError).send(error)
  }
})

Router.get('/:token', async (req, res) => {
  try {
    const { token } = req.params

    if (!isValidStarknetAddress(token)) {
      res.status(HTTPStatus.BadRequest).send({ code: ErrorCode.BAD_REQUEST, message: 'Invalid token address' })
      return
    }

    const transfers = await db.select().from(transfer).where(eq(transfer.token, token))

    res.status(HTTPStatus.OK).send(transfers)
  } catch (error) {
    res.status(HTTPStatus.InternalServerError).send(error)
  }
})

export default Router
