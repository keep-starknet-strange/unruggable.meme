import { zodResolver } from '@hookform/resolvers/zod'
import { useAccount, useContractWrite, useExplorer } from '@starknet-react/core'
import { Wallet, X } from 'lucide-react'
import { useCallback, useState } from 'react'
import { useFieldArray, useForm } from 'react-hook-form'
import { IconButton, PrimaryButton, SecondaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import { TOKEN_CLASS_HASH, UDC } from 'src/constants/contracts'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { CallData, hash, stark, uint256 } from 'starknet'
import { z } from 'zod'

import * as styles from './style.css'

const MAX_HOLDERS = 10

const address = z.string().refine(
  (addr) => {
    // Wallets like to omit leading zeroes, so we cannot check for a fixed length.
    // On the other hand, we don't want users to mistakenly enter an Ethereum address.
    return /^0x[0-9a-fA-F]{50,64}$/.test(addr)
  },
  { message: 'Invalid Starknet address' }
)

const holder = z.object({
  address,
  amount: z.number().min(0),
})

const schema = z.object({
  name: z.string().min(1),
  symbol: z.string().min(1),
  initialRecipientAddress: address,
  ownerAddress: address,
  initialSupply: z.number().min(0),
  holders: z.array(holder),
})

export default function LaunchPage() {
  const [deployedToken, setDeployedToken] = useState<{ address: string; tx: string } | undefined>(undefined)

  const explorer = useExplorer()
  const { account, address } = useAccount()
  const { writeAsync, isPending, reset: resetWrite } = useContractWrite({})

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
    reset: resetForm,
  } = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: { initialSupply: 10_000_000_000 },
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

      const ctorCalldata = CallData.compile([
        data.ownerAddress,
        data.initialRecipientAddress,
        data.name,
        data.symbol,
        uint256.bnToUint256(BigInt(data.initialSupply)),
      ])

      // Token address. Used to transfer tokens to initial holders.
      const tokenAddress = hash.calculateContractAddressFromHash(salt, TOKEN_CLASS_HASH, ctorCalldata, unique)

      const deploy = {
        contractAddress: UDC.ADDRESS,
        entrypoint: UDC.ENTRYPOINT,
        calldata: [TOKEN_CLASS_HASH, salt, unique, ctorCalldata.length, ...ctorCalldata],
      }

      const transfers = data.holders.map(({ address, amount }) => ({
        contractAddress: tokenAddress,
        entrypoint: 'transfer',
        calldata: CallData.compile([address, uint256.bnToUint256(BigInt(amount))]),
      }))

      try {
        const response = await writeAsync({
          calls: [deploy, ...transfers],
        })

        setDeployedToken({ address: tokenAddress, tx: response.transaction_hash })
      } catch (err) {
        console.error(err)
      }
    },
    [account, writeAsync]
  )

  const restart = useCallback(() => {
    resetWrite()
    resetForm()
    setDeployedToken(undefined)
  }, [resetForm, resetWrite, setDeployedToken])

  return (
    <Row className={styles.wrapper}>
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
                    disabled={!address}
                    onClick={() => (address ? setValue('initialRecipientAddress', address) : null)}
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
                    onClick={() => (address ? setValue('ownerAddress', address) : null)}
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
              <Input {...register('initialSupply', { valueAsNumber: true })} />
              <Box className={styles.errorContainer}>
                {errors.initialSupply?.message ? <Text.Error>{errors.initialSupply.message}</Text.Error> : null}
              </Box>
            </Column>

            {fields.map((field, index) => (
              <Column gap="4" key={field.id}>
                <Text.Body className={styles.inputLabel}>Holder {index + 1}</Text.Body>
                <Column gap="2" flexDirection="row">
                  <Input placeholder="Holder address" {...register(`holders.${index}.address`)} />
                  <Input placeholder="Tokens" {...register(`holders.${index}.amount`, { valueAsNumber: true })} />
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

            <SecondaryButton disabled={fields.length >= MAX_HOLDERS} onClick={() => append({ address: '', amount: 0 })}>
              Add holder
            </SecondaryButton>

            <div />

            {deployedToken ? (
              <Column gap="4">
                <Text.HeadlineMedium textAlign="center">Token deployed!</Text.HeadlineMedium>
                <Column gap="2">
                  <Text.Body className={styles.inputLabel}>Token address</Text.Body>
                  <Text.Body className={styles.deployedAddress}>
                    <a href={explorer.contract(deployedToken.address)}>{deployedToken.address}</a>.
                  </Text.Body>
                </Column>
                <Column gap="2">
                  <Text.Body className={styles.inputLabel}>Transaction</Text.Body>
                  <Text.Body className={styles.deployedAddress}>
                    <a href={explorer.transaction(deployedToken.tx)}>{deployedToken.tx}</a>.
                  </Text.Body>
                </Column>
                <PrimaryButton onClick={restart} type="button" className={styles.deployButton}>
                  Start over
                </PrimaryButton>
              </Column>
            ) : (
              <PrimaryButton disabled={!account || isPending} className={styles.deployButton}>
                {account ? (isPending ? 'WAITING FOR SIGNATURE' : 'DEPLOY') : 'CONNECT WALLET'}
              </PrimaryButton>
            )}
          </Column>
        </Box>
      </Box>
    </Row>
  )
}
