import { ColumnDef } from '@tanstack/react-table'
import { Contract } from 'src/pages/History/data/schema'

import { statuses, types } from '../../pages/History/data/data'
import { DataTableColumnHeader } from './data-table-column-header'

export const columns: ColumnDef<Contract>[] = [
  {
    accessorKey: 'deployed_at_timestamp',
    header: ({ column }) => <DataTableColumnHeader column={column} title="Deployed At" />,
    cell: ({ row }) => {
      const timestamp: number = row.getValue('deployed_at_timestamp')
      const date = new Date(timestamp * 1000).toLocaleString()
      return <div className="w-[100px]">{date}</div>
    },
    enableSorting: false,
    enableHiding: false,
  },
  {
    accessorKey: 'contract',
    header: ({ column }) => <DataTableColumnHeader column={column} title="Contract Address" />,
    cell: ({ row }) => {
      return (
        <div className="flex space-x-2">
          <span className="max-w-[600px] truncate font-medium">{row.getValue('contract')}</span>
        </div>
      )
    },
  },
  {
    accessorKey: 'status',
    header: ({ column }) => <DataTableColumnHeader column={column} title="Status" />,
    cell: ({ row }) => {
      const status = statuses.find((status) => status.value === row.getValue('status'))

      if (!status) {
        return null
      }

      return (
        <div className="flex w-[100px] items-center">
          {status.icon && <status.icon className="mr-2 h-4 w-4 text-muted-foreground" />}
          <span>{status.label}</span>
        </div>
      )
    },
    filterFn: (row, id, value) => {
      return value.includes(row.getValue(id))
    },
  },
  {
    accessorKey: 'type',
    header: ({ column }) => <DataTableColumnHeader column={column} title="Type" />,
    cell: ({ row }) => {
      const type = types.find((type) => type.value === row.getValue('type'))

      if (!type) {
        return null
      }

      return (
        <div className="flex items-center">
          <span>{type.label}</span>
        </div>
      )
    },
    filterFn: (row, id, value) => {
      return value.includes(row.getValue(id))
    },
  },
]
