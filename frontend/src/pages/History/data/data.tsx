import { CheckCircledIcon, CrossCircledIcon } from '@radix-ui/react-icons'

// See Contract Object: https://starkscan.readme.io/reference/contract-object

// is_verified
export const statuses = [
  {
    value: 'TRUE',
    label: 'True',
    icon: CheckCircledIcon,
  },
  {
    value: 'FALSE',
    label: 'False',
    icon: CrossCircledIcon,
  },
]

// implementation_type
export const types = [
  {
    label: 'ERC20',
    value: 'ERC20',
  },
  {
    label: 'ERC721',
    value: 'ERC721',
  },
  {
    label: 'ERC1155',
    value: 'ERC1155',
  },
  {
    label: 'ACCOUNT',
    value: 'ACCOUNT',
  },
  {
    label: 'UNKNOWN',
    value: 'UNKNOWN',
  },
]
