import express from 'express'

import deploy from './routes/deploy'
import health from './routes/health'
import launch from './routes/launch'

const Router = express.Router()

Router.use('/health', health)

Router.use('/deploy', deploy)
Router.use('/launch', launch)

export default Router
