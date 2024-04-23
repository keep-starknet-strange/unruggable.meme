import clsx from 'clsx'

import { Sprinkles, sprinkles } from '../css/sprinkles.css'
import Box, { BoxProps } from './Box'

export interface TextProps extends BoxProps {
  loadingWidth?: Sprinkles['width']
}

const TextWrapper = ({ loadingWidth, loading, className, children, ...props }: TextProps) => {
  if (loading) {
    className = clsx(
      className,
      sprinkles({
        width: loadingWidth,
        borderRadius: 'round',
      }),
    )
    children = <>&nbsp;</>
  }

  return (
    <Box className={className} loading={loading} {...props}>
      {children}
    </Box>
  )
}

export const Custom = TextWrapper

export const Small = ({ className, ...props }: TextProps) => (
  <TextWrapper
    className={clsx(
      className,
      sprinkles({
        fontWeight: 'normal',
        color: 'text1',
        fontSize: '14',
      }),
    )}
    {...props}
  />
)

export const Subtitle = ({ className, ...props }: TextProps) => (
  <TextWrapper
    className={clsx(
      className,
      sprinkles({
        fontWeight: 'normal',
        color: 'text2',
        fontSize: '16',
      }),
    )}
    {...props}
  />
)

export const Body = ({ className, ...props }: TextProps) => (
  <TextWrapper
    className={clsx(
      className,
      sprinkles({
        fontWeight: 'normal',
        color: 'text1',
        fontSize: '16',
      }),
    )}
    {...props}
  />
)

export const Medium = ({ className, ...props }: TextProps) => (
  <TextWrapper
    className={clsx(
      className,
      sprinkles({
        fontWeight: 'medium',
        color: 'text1',
        fontSize: '16',
      }),
    )}
    {...props}
  />
)

export const Link = ({ className, ...props }: TextProps) => (
  <TextWrapper
    className={clsx(
      className,
      sprinkles({
        fontWeight: 'normal',
        color: 'text1',
        fontSize: '16',
        cursor: 'pointer',
        textDecoration: {
          hover: 'underline',
        },
      }),
    )}
    {...props}
  />
)

export const HeadlineSmall = ({ className, ...props }: TextProps) => (
  <TextWrapper
    className={clsx(
      className,
      sprinkles({
        fontWeight: 'medium',
        color: 'text1',
        fontSize: '18',
      }),
    )}
    {...props}
  />
)

export const HeadlineMedium = ({ className, ...props }: TextProps) => (
  <TextWrapper
    className={clsx(
      className,
      sprinkles({
        fontWeight: 'semibold',
        color: 'text1',
        fontSize: '24',
      }),
    )}
    {...props}
  />
)

export const HeadlineLarge = ({ className, ...props }: TextProps) => (
  <TextWrapper
    className={clsx(
      className,
      sprinkles({
        fontWeight: 'semibold',
        color: 'text1',
        fontSize: '32',
      }),
    )}
    {...props}
  />
)

export const Error = ({ className, ...props }: TextProps) => (
  <TextWrapper
    className={clsx(
      className,
      sprinkles({
        fontWeight: 'normal',
        color: 'error',
        fontSize: '14',
      }),
    )}
    {...props}
  />
)
