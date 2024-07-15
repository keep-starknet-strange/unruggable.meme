import express from 'express'

import health from './routes/health'

const Router = express.Router()

Router.use('/health', health)

export default Router
