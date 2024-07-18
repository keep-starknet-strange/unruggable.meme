import 'dotenv/config'

import cors from 'cors'
import express from 'express'
import helmet from 'helmet'

import router from './router'

const app = express()

app.use(cors())
app.use(helmet())
app.use(express.urlencoded({ extended: false }))
app.use(express.json())

app.use('/', router)

const PORT = Number(process.env.PORT) || 3001

app.listen(PORT, () => {
  console.info(`Express server started listening on port ${PORT}`)
})
