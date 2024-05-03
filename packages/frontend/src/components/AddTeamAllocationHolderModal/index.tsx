import { zodResolver } from '@hookform/resolvers/zod'
import { useAccount } from '@starknet-react/core'
import { Fraction, Percent } from '@uniswap/sdk-core'
import { DECIMALS, MAX_TEAM_ALLOCATION_TOTAL_SUPPLY_PERCENTAGE } from 'core/constants'
import { Wallet } from 'lucide-react'
import { useCallback, useEffect, useMemo } from 'react'
import { useForm } from 'react-hook-form'
import { useTeamAllocation } from 'src/hooks/useLaunchForm'
import { useAddTeamAllocationHolderModal, useCloseModal } from 'src/hooks/useModal'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { formatPercentage, parseFormatedAmount } from 'src/utils/amount'
import { decimalsScale } from 'src/utils/decimalScale'
import { address, currencyInput } from 'src/utils/zod'
import { getChecksumAddress } from 'starknet'
import { z } from 'zod'

import { IconButton, PrimaryButton, SecondaryButton } from '../Button'
import Portal from '../common/Portal'
import Input from '../Input'
import NumericalInput from '../Input/NumericalInput'
import Content from '../Modal/Content'
import Overlay from '../Modal/Overlay'
import * as styles from './style.css'

// zod schemes

const schema = z.object({
  holderAddress: address,
  amount: currencyInput,
})
interface AddTeamAllocationHolderModalProps {
  index: number
  totalSupply: string
}

const PERCENTAGE_SUGGESTIONS = [
  new Percent(5, 1000), // 0.5%
  new Percent(1, 100), // 1%
  new Percent(2, 100), // 2%
  new Percent(5, 100), // 5%
]

export function AddTeamAllocationHolderModal({ index, totalSupply }: AddTeamAllocationHolderModalProps) {
  // state
  const { teamAllocation, setTeamAllocationHolder, removeTeamAllocationHolder } = useTeamAllocation()

  // starknet
  const { address } = useAccount()

  // modal
  const [isOpen] = useAddTeamAllocationHolderModal()
  const close = useCloseModal()

  // form
  const {
    register,
    handleSubmit,
    setValue,
    setError,
    reset,
    formState: { errors },
  } = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
  })

  // max team allocation
  const remainingTeamAllocation = useMemo(() => {
    const maxTeamAllocation = new Fraction(totalSupply)
      .multiply(MAX_TEAM_ALLOCATION_TOTAL_SUPPLY_PERCENTAGE)
      .divide(decimalsScale(DECIMALS))

    const alreadyAllocatedAmount = Object.keys(teamAllocation)
      .map(Number)
      .reduce(
        (acc, holderIndex) =>
          holderIndex === index ? acc : acc.add(parseFormatedAmount(teamAllocation[holderIndex]?.amount ?? '0')),
        new Fraction(0),
      )

    return maxTeamAllocation.subtract(alreadyAllocatedAmount)
  }, [index, teamAllocation, totalSupply])

  // add holder
  const addHolder = useCallback(
    async (data: z.infer<typeof schema>) => {
      let hasError = false

      // check for duplicated holder
      for (const holderIndex in teamAllocation) {
        if (
          +holderIndex !== index &&
          getChecksumAddress(teamAllocation[+holderIndex].address) === getChecksumAddress(data.holderAddress)
        ) {
          setError('holderAddress', { message: 'This holder already has a team allocation' })
          hasError = true
        }
      }

      // check for max team allocation
      if (new Fraction(parseFormatedAmount(data.amount)).greaterThan(remainingTeamAllocation)) {
        setError('amount', {
          message: `Total team allocation cannot exceed ${+MAX_TEAM_ALLOCATION_TOTAL_SUPPLY_PERCENTAGE.toFixed(2)}%`,
        })
        hasError = true
      }

      // reject form submission if an error has been detected
      if (hasError) {
        return
      }

      setTeamAllocationHolder(
        {
          address: data.holderAddress,
          amount: data.amount,
        },
        index,
      )
      close()
    },
    [close, index, remainingTeamAllocation, setError, setTeamAllocationHolder, teamAllocation],
  )

  // remove holder
  const removeHolder = useCallback(() => {
    removeTeamAllocationHolder(index)
    close()
  }, [close, index, removeTeamAllocationHolder])

  useEffect(() => {
    if (!isOpen) return

    reset()
    setValue('holderAddress', teamAllocation[index]?.address ?? '')
    setValue('amount', teamAllocation[index]?.amount ?? '')
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [index, isOpen, setValue, reset, teamAllocation[index]?.address, teamAllocation[index]?.amount])

  // set percentage suggestion
  const setPercentageSuggestion = useCallback(
    (percentage: Percent) => {
      setValue('amount', new Fraction(totalSupply, decimalsScale(DECIMALS)).multiply(percentage).quotient.toString())
    },
    [setValue, totalSupply],
  )

  if (!isOpen) return null

  return (
    <Portal>
      <Content title="Add holder" close={close}>
        <Column as="form" gap="32" onSubmit={handleSubmit(addHolder)}>
          <Column gap="16">
            <Column gap="8">
              <Text.Body className={styles.inputLabel}>Holder Address</Text.Body>

              <Input
                placeholder="0x000000000000000000"
                addon={
                  <IconButton
                    type="button"
                    disabled={!address}
                    onClick={() => (address ? setValue('holderAddress', address) : null)}
                  >
                    <Wallet />
                  </IconButton>
                }
                {...register('holderAddress')}
              />

              <Box className={styles.errorContainer}>
                {errors.holderAddress?.message ? <Text.Error>{errors.holderAddress.message}</Text.Error> : null}
              </Box>
            </Column>

            <Column gap="8">
              <Text.Body className={styles.inputLabel}>Amount</Text.Body>

              <NumericalInput placeholder="21,000,000" {...register('amount')} />

              <Row gap="8">
                {PERCENTAGE_SUGGESTIONS.map((percentage, index) => (
                  <Box
                    key={`percentage-suggestion-${index}`}
                    className={styles.percentageSelection}
                    onClick={() => setPercentageSuggestion(percentage)}
                  >
                    <Text.Body color="accent">{formatPercentage(percentage)}</Text.Body>
                  </Box>
                ))}
              </Row>

              <Box className={styles.errorContainer}>
                {errors.amount?.message ? <Text.Error>{errors.amount.message}</Text.Error> : null}
              </Box>
            </Column>
          </Column>

          <Column gap="16">
            <PrimaryButton type="submit">Save</PrimaryButton>
            <SecondaryButton type="button" onClick={removeHolder}>
              Remove
            </SecondaryButton>
          </Column>
        </Column>
      </Content>

      <Overlay onClick={close} />
    </Portal>
  )
}
