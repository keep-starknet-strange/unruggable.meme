import { zodResolver } from '@hookform/resolvers/zod'
import { useAccount } from '@starknet-react/core'
import { Wallet, X } from 'lucide-react'
import { useCallback } from 'react'
import { useFieldArray, useForm } from 'react-hook-form'
import { IconButton, PrimaryButton, SecondaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { z } from 'zod'

import * as styles from './style.css'

const MAX_HOLDERS = 10

const address = z.string().refine(
  (addr) => {
    return addr.startsWith('0x') && addr.length === 66
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
  holders: z.array(holder),
})

export default function LaunchPage() {
  const { account, address } = useAccount()

  const {
    control,
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<z.infer<typeof schema>>({ resolver: zodResolver(schema) })

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'holders',
  })

  const deployToken = useCallback(
    (data: z.infer<typeof schema>) => {
      console.log('deploy token form account', account?.address, data)
      // data contains data to be used for deploying.
      // use `account.execute` to deploy the token.
      // TODO: wait for Starknet React to support overriding call arguments so it
      // plays nicely with react-hook-form.
    },
    [account]
  )

  return (
    <Row className={styles.wrapper}>
      <Box as="span" className={`${styles.backgroundContainer} ${styles.background}`} />
      <Box className={styles.container}>
        <Box as="form" onSubmit={handleSubmit(deployToken)}>
          <Column gap="20">
            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Name</Text.Body>
              <Input placeholder="Dogecoin" {...register('name')} />
              <Box className={styles.errorContainer}>
                {errors.name?.message ? <Text.Error>{errors.name.message}</Text.Error> : null}
              </Box>
            </Column>

            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Symbol</Text.Body>
              <Input placeholder="DOGE" {...register('symbol')} />
              <Box className={styles.errorContainer}>
                {errors.symbol?.message ? <Text.Error>{errors.symbol.message}</Text.Error> : null}
              </Box>
            </Column>

            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Initial Recipient Address</Text.Body>
              <Input
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
                addon={
                  <IconButton disabled={!address} onClick={() => (address ? setValue('ownerAddress', address) : null)}>
                    <Wallet />
                  </IconButton>
                }
                {...register('ownerAddress')}
              />
              <Box className={styles.errorContainer}>
                {errors.ownerAddress?.message ? <Text.Error>{errors.ownerAddress.message}</Text.Error> : null}
              </Box>
            </Column>

            {fields.map((field, index) => (
              <Column gap="4" key={field.id}>
                <Text.Body className={styles.inputLabel}>Holder {index + 1}</Text.Body>
                <Column gap="2" flexDirection="row">
                  <Input placeholder="Holder address" {...register(`holders.${index}.address`)} />
                  <Input placeholder="Tokens" {...register(`holders.${index}.amount`, { valueAsNumber: true })} />
                  <IconButton onClick={() => remove(index)}>
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

            <PrimaryButton disabled={!account} className={styles.deployButton}>
              {account ? 'DEPLOY' : 'CONNECT WALLET'}
            </PrimaryButton>
          </Column>
        </Box>
      </Box>
    </Row>
  )
}
