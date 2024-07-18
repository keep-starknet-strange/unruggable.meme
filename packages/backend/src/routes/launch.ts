import { eq } from 'drizzle-orm'
import express from 'express'

import { db, launch } from '../services/db'
import { ErrorCode } from '../utils/error'
import { isValidStarknetAddress } from '../utils/helpers'
import { HTTPStatus } from '../utils/http'

const Router = express.Router()

Router.get('/', async (req, res) => {
  try {
    const launches = await db.select().from(launch)

    res.status(HTTPStatus.OK).send(launches)
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

    const launches = await db.select().from(launch).where(eq(launch.token, token)).limit(1)

    if (!launches[0]) {
      res.status(HTTPStatus.NotFound).send({ code: ErrorCode.TOKEN_NOT_FOUND, message: 'Token not found' })
      return
    }

    res.status(HTTPStatus.OK).send(launches[0])
  } catch (error) {
    res.status(HTTPStatus.InternalServerError).send(error)
  }
})

export default Router
