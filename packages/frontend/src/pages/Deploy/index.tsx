import { zodResolver } from '@hookform/resolvers/zod'
import { useAccount } from '@starknet-react/core'
import { useFactory } from 'hooks'
import { Wallet } from 'lucide-react'
import { useCallback } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate } from 'react-router-dom'
import { IconButton, PrimaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import NumericalInput from 'src/components/Input/NumericalInput'
import Section from 'src/components/Section'
import useChainId from 'src/hooks/useChainId'
import { useDeploymentStore } from 'src/hooks/useDeployment'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseFormatedAmount } from 'src/utils/amount'
import { address, currencyInput } from 'src/utils/zod'
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
  const [, pushDeployedTokenContract] = useDeploymentStore()

  // navigation
  const navigate = useNavigate()

  // starknet
  const { account, address } = useAccount()
  const chainId = useChainId()

  // sdk factory
  const sdkFactory = useFactory()

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

      const parsedInitialSupply = parseFormatedAmount(data.initialSupply)

      const { tokenAddress, calls } = sdkFactory.getDeployCalldata({
        owner: data.ownerAddress,
        name: data.name,
        symbol: data.symbol,
        initialSupply: parsedInitialSupply,
      })

      executeTransaction({
        calls,
        action: 'Deploy memecoin',
        onSuccess: () => {
          pushDeployedTokenContract({
            address: tokenAddress,
            name: data.name,
            symbol: data.symbol,
            totalSupply: parsedInitialSupply,
          })

          navigate(`/token/${tokenAddress}`)
        },
      })
    },
    [account?.address, chainId, executeTransaction, navigate, pushDeployedTokenContract, sdkFactory],
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
