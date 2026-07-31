const EMPTY = '—'

export function formatDateTime(value, options = {}) {
  if (value === null || value === undefined || value === '') return EMPTY
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return EMPTY
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
    ...options,
  }).format(date)
}
