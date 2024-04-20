import { useCallback, useState } from 'react'
import { AddTeamAllocationHolderModal } from 'src/components/AddTeamAllocationHolderModal'
import { MAX_TEAM_ALLOCATION_HOLDERS_COUNT } from 'src/constants/misc'
import { useTeamAllocation, useTeamAllocationTotalPercentage } from 'src/hooks/useLaunchForm'
import useMemecoin from 'src/hooks/useMemecoin'
import { useAddTeamAllocationHolderModal } from 'src/hooks/useModal'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { formatPercentage } from 'src/utils/amount'

import { FormPageProps, Submit } from '../common'
import HolderSlot from './HolderSlot'
import * as styles from './style.css'

const slots = Array(MAX_TEAM_ALLOCATION_HOLDERS_COUNT).fill(0)

export default function TeamAllocationForm({ previous, next }: FormPageProps) {
  const [selectedHolderIndex, setSelectedHolderIndex] = useState(0)

  // memecoin
  const { data: memecoin } = useMemecoin()

  // team allocation state
  const { teamAllocation } = useTeamAllocation()

  // modal
  const [, addTeamAllocationHolderModal] = useAddTeamAllocationHolderModal()

  // open slot
  const openSlot = useCallback(
    (index: number) => {
      setSelectedHolderIndex(index)
      addTeamAllocationHolderModal()
    },
    [addTeamAllocationHolderModal]
  )

  // total team allocation
  const teamAllocationTotalPercentage = useTeamAllocationTotalPercentage(memecoin?.totalSupply)

  if (!teamAllocationTotalPercentage || !memecoin) return null

  return (
    <>
      <Column gap="42">
        <Text.Custom color="text2" fontWeight="normal" fontSize="24">
          Team allocation
        </Text.Custom>

        <Column gap="24">
          <Box className={styles.slotsContainer}>
            {slots.map((_, index) => (
              <HolderSlot
                key={index}
                open={() => openSlot(index)}
                holder={teamAllocation[index]}
                totalSupply={memecoin.totalSupply}
              />
            ))}
          </Box>

          <Row gap="16">
            <Text.HeadlineLarge>
              Total{' '}
              <Box as="span" color="accent">
                {formatPercentage(teamAllocationTotalPercentage)}
              </Box>
            </Text.HeadlineLarge>
          </Row>
        </Column>

        <Column as="form" onSubmit={next}>
          <Submit previous={previous} />
        </Column>
      </Column>

      <AddTeamAllocationHolderModal index={selectedHolderIndex} totalSupply={memecoin.totalSupply} />
    </>
  )
}
