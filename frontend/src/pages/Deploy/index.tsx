import { zodResolver } from '@hookform/resolvers/zod'
import { useAccount, useContractWrite } from '@starknet-react/core'
import { Wallet, X } from 'lucide-react'
import { useCallback } from 'react'
import { useFieldArray, useForm } from 'react-hook-form'
import { IconButton, PrimaryButton, SecondaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import NumericalInput from 'src/components/Input/NumericalInput'
import Section from 'src/components/Section'
import { TOKEN_CLASS_HASH, UDC } from 'src/constants/contracts'
import { DECIMALS, MAX_HOLDERS_PER_DEPLOYMENT } from 'src/constants/misc'
import { useDeploymentStore } from 'src/hooks/useDeployment'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { isValidL2Address } from 'src/utils/address'
import { parseFormatedAmount } from 'src/utils/amount'
import { CallData, hash, stark, uint256 } from 'starknet'
import { z } from 'zod'

import * as styles from './style.css'

// zod schemes

const address = z.string().refine((address) => isValidL2Address(address), { message: 'Invalid Starknet address' })

const currencyInput = z.string().refine((input) => +parseFormatedAmount(input) > 0, { message: 'Invalid amount' })

const holder = z.object({
  address,
  amount: currencyInput,
})

const schema = z.object({
  name: z.string().min(1),
  symbol: z.string().min(1),
  initialRecipientAddress: address,
  ownerAddress: address,
  initialSupply: currencyInput,
  holders: z.array(holder),
})

/**
 * DeployPage component
 */

export default function DeployPage() {
  const { pushDeployedTokenContracts } = useDeploymentStore()

  const { account, address } = useAccount()
  const { writeAsync, isPending } = useContractWrite({})

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
      if (!account?.address) return

      const salt = stark.randomAddress()
      const unique = 0

      const parsedInitialSupply = parseFormatedAmount(data.initialSupply)

      const totalTeamAllocation = data.holders
        .reduce((acc, { amount }) => BigInt(parseFormatedAmount(amount)) + acc, BigInt(0))
        .toString()

      const constructorCalldata = CallData.compile([
        data.ownerAddress, // owner
        data.initialRecipientAddress, // initial_recipient
        data.name, // name
        data.symbol, // symbol
        uint256.bnToUint256(BigInt(parsedInitialSupply) * BigInt(DECIMALS)), // initial_supply
        data.holders.map(({ address }) => address), // initial_holders
        data.holders.map(({ amount }) => uint256.bnToUint256(BigInt(parseFormatedAmount(amount)) * BigInt(DECIMALS))), // initial_holders_amounts
      ])

      // Token address. Used to transfer tokens to initial holders.
      const tokenAddress = hash.calculateContractAddressFromHash(salt, TOKEN_CLASS_HASH, constructorCalldata, unique)

      const deploy = {
        contractAddress: UDC.ADDRESS,
        entrypoint: UDC.ENTRYPOINT,
        calldata: [TOKEN_CLASS_HASH, salt, unique, constructorCalldata.length, ...constructorCalldata],
      }

      try {
        await writeAsync({ calls: [deploy] })

        pushDeployedTokenContracts({
          address: tokenAddress,
          name: data.name,
          symbol: data.symbol,
          maxSupply: parsedInitialSupply,
          teamAllocation: totalTeamAllocation,
          launched: false,
        })
      } catch (err) {
        console.error(err)
      }
    },
    [account, writeAsync, pushDeployedTokenContracts]
  )

  return (
    <Section>
      <Box className={styles.container}>
        <Box as="form" onSubmit={handleSubmit(deployToken)}>
          <Column gap="20">
            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Name</Text.Body>

              <Input placeholder="Unruggable" {...register('name')} />

              <Box className={styles.errorContainer}>
                {errors.name?.message ? <Text.Error>{errors.name.message}</Text.Error> : null}
              </Box>
            </Column>

            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Symbol</Text.Body>

              <Input placeholder="MEME" {...register('symbol')} />

              <Box className={styles.errorContainer}>
                {errors.symbol?.message ? <Text.Error>{errors.symbol.message}</Text.Error> : null}
              </Box>
            </Column>

            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Initial Recipient Address</Text.Body>

              <Input
                placeholder="0x000000000000000000"
                addon={
                  <IconButton
                    type="button"
                    disabled={!address}
                    onClick={() =>
                      address ? setValue('initialRecipientAddress', address, { shouldValidate: true }) : null
                    }
                  >
                    <Wallet />
                  </IconButton>
                }
                {...register('initialRecipientAddress')}
              />

              <Box className={styles.errorContainer}>
                {errors.initialRecipientAddress?.message ? (
                  <Text.Error>{errors.initialRecipientAddress.message}</Text.Error>
                ) : null}
              </Box>
            </Column>

            <Column gap="4">
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

            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Initial Supply</Text.Body>

              <NumericalInput placeholder="10,000,000,000.00" {...register('initialSupply')} />

              <Box className={styles.errorContainer}>
                {errors.initialSupply?.message ? <Text.Error>{errors.initialSupply.message}</Text.Error> : null}
              </Box>
            </Column>

            {fields.map((field, index) => (
              <Column gap="4" key={field.id}>
                <Text.Body className={styles.inputLabel}>Holder {index + 1}</Text.Body>

                <Column gap="2" flexDirection="row">
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

            <PrimaryButton type="submit" disabled={!account || isPending} className={styles.deployButton} major>
              {account ? (isPending ? 'Waiting for signature' : 'Deploy') : 'Connect wallet'}
            </PrimaryButton>
          </Column>
        </Box>
      </Box>
    </Section>
  )
}
