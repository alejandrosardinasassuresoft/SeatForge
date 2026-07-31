import { get, post, put, patch, del } from './client'

export const api = {
  health: {
    check: () => get('/health'),
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
