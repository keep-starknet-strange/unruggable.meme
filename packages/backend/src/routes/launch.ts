import express from 'express'

import { db, launch } from '../services/db'
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

export default Router
