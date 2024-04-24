import { EKUBO_TICK_SIZE, EKUBO_TICK_SIZE_LOG, EKUBO_TICK_SPACING } from 'core/constants'

export const getInitialPrice = (startingTick: number) => EKUBO_TICK_SIZE ** startingTick

export const getStartingTick = (initialPrice: number) =>
  Math.floor(Math.log(initialPrice) / EKUBO_TICK_SIZE_LOG / EKUBO_TICK_SPACING) * EKUBO_TICK_SPACING
