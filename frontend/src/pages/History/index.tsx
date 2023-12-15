import 'src/theme/css/global.css'
import './tailwind.css'

import { useNavigate } from 'react-router-dom'
import { columns } from 'src/components/Table/columns'
import { DataTable } from 'src/components/Table/data-table'
import { Card, CardContent } from 'src/pages/History/registry/card'

import contracts from './data/history.json'
import { Button } from './registry/button'
// import { contractSchema } from './data/schema'

// Simulate an onchain read for deployed contracts. Can use: https://starkscan.readme.io/reference/contract-object

// const options = {
//   method: 'GET',
//   headers: {accept: 'application/json', 'x-api-key': 'docs-starkscan-co-api-3'}
// };

// async function getContracts() {
//   const data = fetch(
//     'https://api.starkscan.co/api/v0/contract/0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7',
//     options
//   )
//     .then((response) => response.json())
//     .then((response) => console.log(response))
//     .catch((err) => console.error(err))

//   const contracts = JSON.parse(data.toString())

//   return z.array(contractSchema).parse(contracts)
// }

export default function HistoryPage() {
  const navigate = useNavigate()
  return (
    <div className="dark !important">
      <div className="md:hidden h-screen w-full flex flex-col items-center justify-center">
        <Card className="max-w-md mx-auto text-center p-6 shadow-lg rounded-xl">
          <CardContent className="space-y-4">
            <h2 className="text-2xl font-bold">Attention</h2>
            <p className="text-gray-400">
              To view contracts deployed using Unruggable meme, please use a laptop or tablet.
            </p>
            <Button
              className="w-full py-2 border-blue-500 text-blue-500 hover:bg-blue-500 hover:text-white"
              variant="outline"
              onClick={() => {
                navigate({ pathname: '/' })
              }}
            >
              Take me to home page
            </Button>
          </CardContent>
        </Card>
      </div>
      <div className="hidden h-full flex-1 flex-col space-y-8 p-8 md:flex">
        <div className="flex items-center justify-between space-y-2">
          <div>
            <h2 className="text-2xl text-white font-bold tracking-tight">Welcome back!</h2>
            <p className="text-muted-foreground text-white">
              Here&apos;s a list of the contracts that were previously deployed with Unruggable Meme!
            </p>
          </div>
        </div>
        <DataTable data={contracts} columns={columns} />
      </div>
    </div>
  )
}
