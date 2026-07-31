export function errorMessage(error, fallback = 'Something went wrong. Please try again.') {
  return error?.message || fallback
}

export function errorDetails(error) {
  if (Array.isArray(error?.details) && error.details.length) {
    return error.details.join(' ')
  }
  return ''
}
