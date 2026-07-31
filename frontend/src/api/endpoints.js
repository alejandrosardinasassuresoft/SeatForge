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
  workshops: {
    list: (params) => get('/workshops', { params }),
    get: (id) => get(`/workshops/${id}`),
  },
  sessions: {
    list: (params) => get('/sessions', { params }),
    get: (id) => get(`/sessions/${id}`),
  },
}
