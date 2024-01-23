import { Duration } from 'moment'

export function parseMinutesDuration(duration: Duration) {
  const hours = duration.asHours()
  const minutes = duration.minutes()

  return `${Math.floor(hours).toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
}

export function parseMonthsDuration(duration: Duration) {
  const months = duration.asMonths()

  return `${Math.floor(months).toString()} month${months >= 2 ? 's' : ''}`
}
