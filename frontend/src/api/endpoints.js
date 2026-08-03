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
  workshops: {
    list: (params) => get('/workshops', { params }),
    get: (id) => get(`/workshops/${id}`),
  },
  sessions: {
    list: (params) => get('/sessions', { params }),
    get: (id) => get(`/sessions/${id}`),
    availability: (id) => get(`/sessions/${id}/availability`),
    register: (id, attendee) => post(`/sessions/${id}/registrations`, { attendee }),
  },
  registrations: {
    confirm: (id) => post(`/registrations/${id}/confirm`),
    cancel: (id) => post(`/registrations/${id}/cancel`),
  },
}
