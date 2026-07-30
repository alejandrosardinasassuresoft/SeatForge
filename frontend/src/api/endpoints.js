import { get, post, put, patch, del } from './client'

export const api = {
  health: {
    check: () => get('/health'),
  },
}
