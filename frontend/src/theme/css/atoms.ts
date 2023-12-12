import clsx from 'clsx'

import * as resetStyles from './reset.css'
import { Sprinkles, sprinkles } from './sprinkles.css'

interface Atoms extends Sprinkles {
  reset?: string
}

export const atoms = ({ reset, ...rest }: Atoms) => {
  if (!reset) return sprinkles(rest)

  const elementReset = resetStyles.element[reset as keyof typeof resetStyles.element]

  const sprinklesClasses = sprinkles(rest)

  return clsx(elementReset, sprinklesClasses)
}
