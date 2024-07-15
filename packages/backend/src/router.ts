import express from 'express'

import health from './routes/health'
import launch from './routes/launch'

const Router = express.Router()

Router.use('/health', health)
Router.use('/launch', launch)

export default Router
