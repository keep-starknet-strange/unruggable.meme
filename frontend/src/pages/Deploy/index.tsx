import { zodResolver } from '@hookform/resolvers/zod'
import { useAccount } from '@starknet-react/core'
import { Wallet } from 'lucide-react'
import { useCallback } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate } from 'react-router-dom'
import { IconButton, PrimaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import NumericalInput from 'src/components/Input/NumericalInput'
import Section from 'src/components/Section'
import { FACTORY_ADDRESSES, TOKEN_CLASS_HASH } from 'src/constants/contracts'
import { DECIMALS, Selector } from 'src/constants/misc'
import useChainId from 'src/hooks/useChainId'
import { useDeploymentStore } from 'src/hooks/useDeployment'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseFormatedAmount } from 'src/utils/amount'
import { decimalsScale } from 'src/utils/decimals'
import { address, currencyInput } from 'src/utils/zod'
import { CallData, hash, stark, uint256 } from 'starknet'
import { z } from 'zod'

import * as styles from './style.css'

// zod schemes

const schema = z.object({
  name: z.string().min(1),
  symbol: z.string().min(1),
  ownerAddress: address,
  initialSupply: currencyInput,
})

/**
 * DeployPage component
 */

export default function DeployPage() {
  const [, pushDeployedTokenContracts] = useDeploymentStore()

  // navigation
  const navigate = useNavigate()

  // starknet
  const { account, address } = useAccount()
  const chainId = useChainId()

  // transaction
  const executeTransaction = useExecuteTransaction()

  // If you need the transaction status, you can use this hook.
  // Notice that RPC providers will take some time to receive the transaction,
  // so you will get a "transaction not found" for a few sounds after deployment.
  // const {} = useWaitForTransaction({ hash: deployedToken?.address })

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
  })

  const deployToken = useCallback(
    async (data: z.infer<typeof schema>) => {
      if (!account?.address || !chainId) return

      const salt = stark.randomAddress()

      const parsedInitialSupply = parseFormatedAmount(data.initialSupply)

      const constructorCalldata = CallData.compile([
        data.ownerAddress, // owner
        data.name, // name
        data.symbol, // symbol
        uint256.bnToUint256(BigInt(parsedInitialSupply) * BigInt(decimalsScale(DECIMALS))), // initial_supply
        salt, // contract salt
      ])

      // Token address. Used to transfer tokens to initial holders.
      const createMemecoin = {
        contractAddress: FACTORY_ADDRESSES[chainId],
        entrypoint: Selector.CREATE_MEMECOIN,
        calldata: constructorCalldata,
      }

      const tokenAddress = hash.calculateContractAddressFromHash(
        salt,
        TOKEN_CLASS_HASH,
        constructorCalldata.slice(0, -1),
        FACTORY_ADDRESSES[chainId]
      )

      executeTransaction({
        calls: [createMemecoin],
        action: 'Deploy memecoin',
        onSuccess: () => {
          console.log('hey')
          pushDeployedTokenContracts({
            address: tokenAddress,
            name: data.name,
            symbol: data.symbol,
            totalSupply: parsedInitialSupply,
          })

          navigate(`/token/${tokenAddress}`)
        },
      })
    },
    [account?.address, chainId, executeTransaction, navigate, pushDeployedTokenContracts]
  )

  return (
    <Section>
      <Box className={styles.container}>
        <Box as="form" onSubmit={handleSubmit(deployToken)}>
          <Column gap="20">
            <Column gap="8">
              <Text.Body className={styles.inputLabel}>Name</Text.Body>

              <Input placeholder="Unruggable" {...register('name')} />

              <Box className={styles.errorContainer}>
                {errors.name?.message ? <Text.Error>{errors.name.message}</Text.Error> : null}
              </Box>
            </Column>

            <Column gap="8">
              <Text.Body className={styles.inputLabel}>Symbol</Text.Body>

              <Input placeholder="MEME" {...register('symbol')} />

              <Box className={styles.errorContainer}>
                {errors.symbol?.message ? <Text.Error>{errors.symbol.message}</Text.Error> : null}
              </Box>
            </Column>

            <Column gap="8">
              <Text.Body className={styles.inputLabel}>Owner Address</Text.Body>

              <Input
                placeholder="0x000000000000000000"
                addon={
                  <IconButton
                    type="button"
                    disabled={!address}
                    onClick={() => (address ? setValue('ownerAddress', address, { shouldValidate: true }) : null)}
                  >
                    <Wallet />
                  </IconButton>
                }
                {...register('ownerAddress')}
              />

              <Box className={styles.errorContainer}>
                {errors.ownerAddress?.message ? <Text.Error>{errors.ownerAddress.message}</Text.Error> : null}
              </Box>
            </Column>

            <Column gap="8">
              <Text.Body className={styles.inputLabel}>Initial Supply</Text.Body>

              <NumericalInput placeholder="10,000,000,000.00" {...register('initialSupply')} />

              <Box className={styles.errorContainer}>
                {errors.initialSupply?.message ? <Text.Error>{errors.initialSupply.message}</Text.Error> : null}
              </Box>
            </Column>

            <div />

            <PrimaryButton type="submit" disabled={!account} large>
              {account ? 'Deploy' : 'Connect wallet'}
            </PrimaryButton>
          </Column>
        </Box>
      </Box>
    </Section>
  )
}
