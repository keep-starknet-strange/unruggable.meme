import { zodResolver } from '@hookform/resolvers/zod'
import { useAccount, useContractWrite } from '@starknet-react/core'
import { Wallet, X } from 'lucide-react'
import { useCallback } from 'react'
import { useFieldArray, useForm } from 'react-hook-form'
import { useNavigate } from 'react-router-dom'
import { IconButton, PrimaryButton, SecondaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import NumericalInput from 'src/components/Input/NumericalInput'
import Section from 'src/components/Section'
import { FACTORY_ADDRESSES, TOKEN_CLASS_HASH } from 'src/constants/contracts'
import { DECIMALS, MAX_HOLDERS_PER_DEPLOYMENT, Selector } from 'src/constants/misc'
import useChainId from 'src/hooks/useChainId'
import { useDeploymentStore } from 'src/hooks/useDeployment'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseFormatedAmount } from 'src/utils/amount'
import { decimalsScale } from 'src/utils/decimals'
import { address, currencyInput, holder } from 'src/utils/zod'
import { CallData, hash, stark, uint256 } from 'starknet'
import { z } from 'zod'

import * as styles from './style.css'

// zod schemes

const schema = z.object({
  name: z.string().min(1),
  symbol: z.string().min(1),
  ownerAddress: address,
  initialSupply: currencyInput,
  holders: z.array(holder),
})

/**
 * DeployPage component
 */

export default function DeployPage() {
  const { pushDeployedTokenContracts } = useDeploymentStore()

  // navigation
  const navigate = useNavigate()

  const { account, address } = useAccount()
  const { writeAsync, isPending } = useContractWrite({})

  const chainId = useChainId()

  // If you need the transaction status, you can use this hook.
  // Notice that RPC providers will take some time to receive the transaction,
  // so you will get a "transaction not found" for a few sounds after deployment.
  // const {} = useWaitForTransaction({ hash: deployedToken?.address })

  const {
    control,
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
  })

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'holders',
  })

  const deployToken = useCallback(
    async (data: z.infer<typeof schema>) => {
      if (!account?.address || !chainId) return

      const salt = stark.randomAddress()

      const parsedInitialSupply = parseFormatedAmount(data.initialSupply)

      const totalTeamAllocation = data.holders
        .reduce((acc, { amount }) => BigInt(parseFormatedAmount(amount)) + acc, BigInt(0))
        .toString()

      const constructorCalldata = CallData.compile([
        data.ownerAddress, // owner
        data.name, // name
        data.symbol, // symbol
        uint256.bnToUint256(BigInt(parsedInitialSupply) * BigInt(decimalsScale(DECIMALS))), // initial_supply
        data.holders.map(({ address }) => address), // initial_holders
        data.holders.map(({ amount }) =>
          uint256.bnToUint256(BigInt(parseFormatedAmount(amount)) * BigInt(decimalsScale(DECIMALS)))
        ), // initial_holders_amounts
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

      try {
        await writeAsync({ calls: [createMemecoin] })

        pushDeployedTokenContracts({
          address: tokenAddress,
          name: data.name,
          symbol: data.symbol,
          maxSupply: parsedInitialSupply,
          teamAllocation: totalTeamAllocation,
        })

        navigate(`/token/${tokenAddress}`)
      } catch (err) {
        console.error(err)
      }
    },
    [account, writeAsync, pushDeployedTokenContracts, chainId, navigate]
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

            {fields.map((field, index) => (
              <Column gap="8" key={field.id}>
                <Text.Body className={styles.inputLabel}>Holder {index + 1}</Text.Body>

                <Column gap="8" flexDirection="row">
                  <Input placeholder="Holder address" {...register(`holders.${index}.address`)} />

                  <NumericalInput placeholder="Tokens" {...register(`holders.${index}.amount`)} />

                  <IconButton type="button" onClick={() => remove(index)}>
                    <X />
                  </IconButton>
                </Column>

                <Box className={styles.errorContainer}>
                  {errors.holders?.[index]?.address?.message ? (
                    <Text.Error>{errors.holders?.[index]?.address?.message}</Text.Error>
                  ) : null}

                  {errors.holders?.[index]?.amount?.message ? (
                    <Text.Error>{errors.holders?.[index]?.amount?.message}</Text.Error>
                  ) : null}
                </Box>
              </Column>
            ))}

            {fields.length < MAX_HOLDERS_PER_DEPLOYMENT && (
              <SecondaryButton
                type="button"
                onClick={() => append({ address: '', amount: '' }, { shouldFocus: false })}
              >
                Add holder
              </SecondaryButton>
            )}

            <div />

            <PrimaryButton type="submit" disabled={!account || isPending} large>
              {account ? (isPending ? 'Waiting for signature' : 'Deploy') : 'Connect wallet'}
            </PrimaryButton>
          </Column>
        </Box>
      </Box>
    </Section>
  )
}
