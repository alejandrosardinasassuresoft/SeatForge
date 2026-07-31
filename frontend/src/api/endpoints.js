import { get, post } from './client'

export const api = {
  health: {
    check: () => get('/health'),
  },
  attendees: {
    registrations: (attendeeId) => get(`/attendees/${attendeeId}/registrations`),
  },
  dashboard: {
    show: () => get('/dashboard'),
  },
  registrations: {
    cancel: (registrationId) => post(`/registrations/${registrationId}/cancel`),
  },
}
