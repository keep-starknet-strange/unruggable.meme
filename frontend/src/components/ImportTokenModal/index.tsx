import { zodResolver } from '@hookform/resolvers/zod'
import { starknetChainId, useNetwork, useProvider } from '@starknet-react/core'
import { useCallback, useEffect, useMemo } from 'react'
import { useForm } from 'react-hook-form'
import { FACTORY_ADDRESSES, MULTICALL_ADDRESS } from 'src/constants/contracts'
import { Selector } from 'src/constants/misc'
import useDebounce from 'src/hooks/useDebounce'
import { useDeploymentStore } from 'src/hooks/useDeployment'
import { useCloseModal, useImportTokenModal } from 'src/hooks/useModal'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { address } from 'src/utils/zod'
import { CallData, getChecksumAddress, hash, shortString, uint256 } from 'starknet'
import { z } from 'zod'

import Portal from '../common/Portal'
import Input from '../Input'
import Content from '../Modal/Content'
import Overlay from '../Modal/Overlay'
import * as styles from './style.css'

// zod schemes

const schema = z.object({
  tokenAddress: address,
})

export function ImportTokenModal() {
  const { deployedTokenContracts, pushDeployedTokenContracts } = useDeploymentStore()

  // modal
  const [isOpen] = useImportTokenModal()
  const close = useCloseModal()

  // starknet
  const { chain } = useNetwork()
  const { provider } = useProvider()
  const chainId = useMemo(() => (chain.id ? starknetChainId(chain.id) : undefined), [chain.id])

  // form
  const {
    register,
    formState: { errors },
    handleSubmit,
    formState,
    watch,
    setError,
  } = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
  })

  const tokenAddress = watch('tokenAddress')

  const debouncedTokenAddress = useDebounce(tokenAddress)

  // token check
  const importToken = useCallback(
    async (data: z.infer<typeof schema>) => {
      if (!chainId) return

      const { tokenAddress } = data

      for (const deployedTokenContract of deployedTokenContracts) {
        if (getChecksumAddress(deployedTokenContract.address) === getChecksumAddress(tokenAddress)) {
          // TODO: close modal and navigate to token page
          return
        }
      }

      const isMemecoinCalldata = CallData.compile({
        to: FACTORY_ADDRESSES[chainId],
        selector: hash.getSelector(Selector.IS_MEMECOIN),
        calldata: [tokenAddress],
      })

      const nameCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.NAME),
        calldata: [],
      })

      const symbolCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.SYMBOL),
        calldata: [],
      })

      const launchedCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.LAUNCHED),
        calldata: [],
      })

      const totalSupplyCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.TOTAL_SUPPLY),
        calldata: [],
      })

      const teamAllocationCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.GET_TEAM_ALLOCATION),
        calldata: [],
      })

      try {
        const res = await provider?.callContract({
          contractAddress: MULTICALL_ADDRESS,
          entrypoint: Selector.AGGREGATE,
          calldata: [
            6,
            ...isMemecoinCalldata,
            ...nameCalldata,
            ...symbolCalldata,
            ...launchedCalldata,
            ...totalSupplyCalldata,
            ...teamAllocationCalldata,
          ],
        })

        const isUnruggable = !!+res.result[3]

        if (isUnruggable) {
          const name = shortString.decodeShortString(res.result[5])
          const symbol = shortString.decodeShortString(res.result[7])
          const launched = !!+res.result[9]
          const maxSupply = uint256.uint256ToBN({ low: res.result[11], high: res.result[12] }).toString()
          const teamAllocation = uint256.uint256ToBN({ low: res.result[14], high: res.result[15] }).toString()

          pushDeployedTokenContracts({
            address: tokenAddress,
            name,
            symbol,
            maxSupply,
            teamAllocation,
            launched,
          })

          // TODO: close modal and navigate to token page
        } else {
          setError('tokenAddress', { message: 'Token is not unruggable' })
        }
      } catch (err) {
        setError('tokenAddress', { message: 'Token not found' })
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [chainId, provider, pushDeployedTokenContracts, setError, deployedTokenContracts.length]
  )

  useEffect(() => {
    if (formState.isValid) {
      handleSubmit(importToken)()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [debouncedTokenAddress])

  if (!isOpen) return null

  return (
    <Portal>
      <Content title="Import token" close={close}>
        <Column gap="8">
          <Text.Body className={styles.inputLabel}>Token Address</Text.Body>

          <Input placeholder="0x000000000000000000" {...register('tokenAddress')} />

          <Box className={styles.errorContainer}>
            {errors.tokenAddress?.message ? <Text.Error>{errors.tokenAddress.message}</Text.Error> : null}
          </Box>
        </Column>
      </Content>

      <Overlay onClick={close} />
    </Portal>
  )
}
