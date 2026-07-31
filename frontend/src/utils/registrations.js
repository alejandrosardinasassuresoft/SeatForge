export const REGISTRATION_STATUSES = ['held', 'confirmed', 'waitlisted', 'cancelled', 'expired']

export const REGISTRATION_STATUS_META = {
  held: { label: 'Held', color: 'info', icon: 'mdi-timer-sand' },
  confirmed: { label: 'Confirmed', color: 'success', icon: 'mdi-check-circle-outline' },
  waitlisted: { label: 'Waitlisted', color: 'warning', icon: 'mdi-account-clock-outline' },
  cancelled: { label: 'Cancelled', color: 'error', icon: 'mdi-cancel' },
  expired: { label: 'Expired', color: 'grey', icon: 'mdi-clock-alert-outline' },
}

export const CANCELLABLE_STATUSES = ['held', 'confirmed', 'waitlisted']

export function registrationStatusMeta(status) {
  return (
    REGISTRATION_STATUS_META[status] ?? {
      label: status || 'Unknown',
      color: 'grey',
      icon: 'mdi-help-circle-outline',
    }
  )
}

export function canCancelRegistration(status) {
  return CANCELLABLE_STATUSES.includes(status)
}
