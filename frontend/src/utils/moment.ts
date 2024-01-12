import { Duration } from 'moment'

export function parseDuration(duration: Duration) {
  const hours = duration.asHours()
  const minutes = duration.minutes()

  return `${Math.floor(hours).toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
}
