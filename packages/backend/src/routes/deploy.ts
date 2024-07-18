import { eq } from 'drizzle-orm'
import express from 'express'

import { db, deploy } from '../services/db'
import { ErrorCode } from '../utils/error'
import { isValidStarknetAddress } from '../utils/helpers'
import { HTTPStatus } from '../utils/http'

const Router = express.Router()

Router.get('/', async (req, res) => {
  try {
    const deploys = await db.select().from(deploy)

    res.status(HTTPStatus.OK).send(deploys)
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

    const deploys = await db.select().from(deploy).where(eq(deploy.token, token)).limit(1)

    if (!deploys[0]) {
      res.status(HTTPStatus.NotFound).send({ code: ErrorCode.TOKEN_NOT_FOUND, message: 'Token not found' })
      return
    }

    res.status(HTTPStatus.OK).send(deploys[0])
  } catch (error) {
    res.status(HTTPStatus.InternalServerError).send(error)
  }
})

Router.get('/owner/:owner', async (req, res) => {
  try {
    const { owner } = req.params

    if (!isValidStarknetAddress(owner)) {
      res.status(HTTPStatus.BadRequest).send({ code: ErrorCode.BAD_REQUEST, message: 'Invalid owner address' })
      return
    }

    const deploys = await db.select().from(deploy).where(eq(deploy.owner, owner))

    res.status(HTTPStatus.OK).send(deploys)
  } catch (error) {
    res.status(HTTPStatus.InternalServerError).send(error)
  }
})

export default Router
