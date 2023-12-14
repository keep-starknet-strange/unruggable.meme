import { columns } from 'src/components/Table/columns'
import { DataTable } from 'src/components/Table/data-table'
import { UserNav } from 'src/components/Table/user-nav'

import tasks from './data/history.json'

// Simulate an onchain read for deployed contracts.
// async function getContracts() {
//   const data = await

//   const contracts = JSON.parse(data.toString())

// return z.array(taskSchema).parse(tasks)
// }

export default function LeaderboardPage() {
  return (
    <div className="hidden h-full flex-1 flex-col space-y-8 p-8 md:flex bg-red-500">
      <div className="flex items-center justify-between space-y-2">
        <div>
          <h2 className="text-4xl font-bold tracking-tight">Welcome back!</h2>
          <p className="text-muted-foreground text-white">Here&apos;s a list of your tasks for this month!</p>
        </div>
        <div className="flex items-center space-x-2">
          <UserNav />
        </div>
      </div>
      <DataTable data={tasks} columns={columns} />
    </div>
  )
}
