import clsx from 'clsx'
import Box, { BoxProps } from 'src/theme/components/Box'

import * as styles from './style.css'

type ButtonProps = Omit<BoxProps, 'as'>

export const PrimaryButton = ({ className, ...props }: ButtonProps) => (
  <Box as="button" className={clsx(className, styles.primaryButton)} {...props} />
)

interface SecondaryButtonProps extends ButtonProps {
  withIcon?: boolean
}

export const SecondaryButton = ({ className, withIcon, ...props }: SecondaryButtonProps) => (
  <Box as="button" className={clsx(className, styles.secondaryButton({ withIcon }))} {...props} />
)

export const IconButton = ({ className, ...props }: ButtonProps) => (
  <Box as="button" className={clsx(className, styles.iconButton)} {...props} />
)
