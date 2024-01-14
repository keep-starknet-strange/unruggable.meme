import { zodResolver } from '@hookform/resolvers/zod'
import { Loader2Icon } from 'lucide-react'
import { useCallback, useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate } from 'react-router-dom'
import useDebounce from 'src/hooks/useDebounce'
import { useDeploymentStore } from 'src/hooks/useDeployment'
import { useMemecoinInfos } from 'src/hooks/useMemecoin'
import { useCloseModal, useImportTokenModal } from 'src/hooks/useModal'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { isValidL2Address } from 'src/utils/address'
import { address } from 'src/utils/zod'
import { getChecksumAddress } from 'starknet'
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

interface ImportTokenModalProps {
  save?: boolean
}

export function ImportTokenModal({ save = false }: ImportTokenModalProps) {
  const [loading, setLoading] = useState(false)

  const { deployedTokenContracts, pushDeployedTokenContracts } = useDeploymentStore()

  // modal
  const [isOpen] = useImportTokenModal()
  const close = useCloseModal()

  // navigation
  const navigate = useNavigate()
  const openTokenPage = useCallback(
    (tokenAddress: string) => {
      navigate(`/token/${tokenAddress}`)
      close()
    },
    [navigate, close]
  )

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

  // loading
  const shouldLoad = useCallback((event: React.FormEvent<HTMLInputElement>) => {
    const value = (event.target as HTMLInputElement).value

    setLoading(isValidL2Address(value))
  }, [])

  // token check
  const [{ error }, getMemecoinInfos] = useMemecoinInfos()

  const importToken = useCallback(
    async (data: z.infer<typeof schema>) => {
      const { tokenAddress } = data

      for (const deployedTokenContract of deployedTokenContracts) {
        if (getChecksumAddress(deployedTokenContract.address) === getChecksumAddress(tokenAddress)) {
          openTokenPage(tokenAddress)
          return
        }
      }

      const memecoinInfos = await getMemecoinInfos(tokenAddress)

      if (memecoinInfos) {
        // save token if needed
        if (save) {
          pushDeployedTokenContracts(memecoinInfos)
        }

        openTokenPage(tokenAddress)
        return
      }

      setLoading(false)
    },
    [getMemecoinInfos, deployedTokenContracts, openTokenPage, pushDeployedTokenContracts, save]
  )

  // handle error
  useEffect(() => {
    setError('tokenAddress', { message: error })
  }, [error, setError])

  // handle submit
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

          <Input placeholder="0x000000000000000000" {...register('tokenAddress', { onChange: shouldLoad })} />

          <Box className={styles.errorContainer}>
            {errors.tokenAddress?.message ? <Text.Error>{errors.tokenAddress.message}</Text.Error> : null}
          </Box>

          {loading && <Loader2Icon className={styles.loader} />}
        </Column>
      </Content>

      <Overlay onClick={close} />
    </Portal>
  )
}
