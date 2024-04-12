import clsx from 'clsx'
import Box, { BoxProps } from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './style.css'

type ButtonProps = Omit<BoxProps, 'as'>

interface EnlargeableButtonProps extends ButtonProps {
  large?: boolean
}

export const PrimaryButton = ({ className, children, disabled, large = false, ...props }: EnlargeableButtonProps) => (
  <Box as="button" className={clsx(className, styles.primaryButton({ large, disabled }))} {...props}>
    <Box zIndex="1" position="relative">
      {children}
    </Box>
  </Box>
)

interface SecondaryButtonProps extends EnlargeableButtonProps {
  withIcon?: boolean
}

export const SecondaryButton = ({ className, withIcon, large = false, ...props }: SecondaryButtonProps) => (
  <Box as="button" className={clsx(className, styles.secondaryButton({ withIcon, large }))} {...props} />
)

export const IconButton = ({ className, large = false, ...props }: EnlargeableButtonProps) => (
  <Box as="button" className={clsx(className, styles.iconButton({ large }))} {...props} />
)

// Card button

interface CardButtonProps extends BoxProps {
  title: string
  subtitle: string
  icon: () => JSX.Element
}

export const CardButton = ({ className, title, subtitle, icon, ...props }: CardButtonProps) => {
  return (
    <Box as="button" className={clsx(className, styles.cardButton)} {...props}>
      <Row gap="12" alignItems="flex-start">
        <Box className={styles.cardButtonIconContainer}>{icon()}</Box>

        <Column gap="4">
          <Text.Body>{title}</Text.Body>

          <Text.Custom fontWeight="normal" fontSize="14" color="text2">
            {subtitle}
          </Text.Custom>
        </Column>
      </Row>
    </Box>
  )
}
