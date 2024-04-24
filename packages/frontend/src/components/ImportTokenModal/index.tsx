import { zodResolver } from '@hookform/resolvers/zod'
import { Loader2Icon } from 'lucide-react'
import { useCallback, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate } from 'react-router-dom'
import useChainId from 'src/hooks/useChainId'
import useDebounce from 'src/hooks/useDebounce'
import { useDeploymentStore } from 'src/hooks/useDeployment'
import useMemecoin from 'src/hooks/useMemecoin'
import { useCloseModal, useImportTokenModal } from 'src/hooks/useModal'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { isValidL2Address } from 'src/utils/address'
import { address } from 'src/utils/zod'
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
  const [, pushDeployedTokenContracts] = useDeploymentStore()

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
    [navigate, close],
  )

  // starknet
  const chainId = useChainId()

  // form
  const {
    register,
    formState: { errors },
    watch,
    setError,
  } = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
  })

  const tokenAddress = watch('tokenAddress')

  const debouncedTokenAddress = useDebounce(tokenAddress)

  // token check
  const tokenAddressToUse = isValidL2Address(debouncedTokenAddress) ? debouncedTokenAddress : undefined
  const { data: memecoin, isLoading, ruggable } = useMemecoin(tokenAddressToUse)

  useEffect(() => {
    if (memecoin && isOpen && chainId) {
      // save token if needed
      if (save) {
        pushDeployedTokenContracts({
          address: memecoin.address,
          name: memecoin.name,
          symbol: memecoin.symbol,
          totalSupply: memecoin.totalSupply.toString(),
        })
      }

      openTokenPage(memecoin.address)
      return
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [memecoin?.address, save, isOpen, chainId])

  // handle error
  useEffect(() => {
    if (ruggable) {
      setError('tokenAddress', { message: 'This token is not unruggable' })
    }
  }, [setError, ruggable])

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

          {isLoading && <Loader2Icon className={styles.loader} />}
        </Column>
      </Content>

      <Overlay onClick={close} />
    </Portal>
  )
}
