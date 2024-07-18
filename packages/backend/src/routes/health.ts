import express from 'express'

import { HTTPStatus } from '../utils/http'

const Router = express.Router()

Router.get('/', async (req, res) => {
  res.status(HTTPStatus.OK).send()
})

export default Router
