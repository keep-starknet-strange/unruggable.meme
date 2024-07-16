import express from 'express'

import deploy from './routes/deploy'
import health from './routes/health'
import launch from './routes/launch'
import transfer from './routes/transfer'

const Router = express.Router()

Router.use('/health', health)

Router.use('/deploy', deploy)
Router.use('/launch', launch)
Router.use('/transfer', transfer)

export default Router
