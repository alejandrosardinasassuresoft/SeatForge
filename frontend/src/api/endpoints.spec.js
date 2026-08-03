import { beforeEach, describe, expect, it, vi } from 'vitest'

const client = vi.hoisted(() => ({
  get: vi.fn(),
  post: vi.fn(),
}))

vi.mock('./client', () => client)

import { api } from './endpoints'

describe('SeatForge API endpoint map', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('keeps confirmation and cancellation as distinct registration operations', () => {
    api.registrations.confirm(12)
    api.registrations.cancel(12)

    expect(client.post).toHaveBeenNthCalledWith(1, '/registrations/12/confirm')
    expect(client.post).toHaveBeenNthCalledWith(2, '/registrations/12/cancel')
  })

  it('requests authoritative availability separately from session detail', () => {
    api.sessions.get(7)
    api.sessions.availability(7)

    expect(client.get).toHaveBeenNthCalledWith(1, '/sessions/7')
    expect(client.get).toHaveBeenNthCalledWith(2, '/sessions/7/availability')
  })

  it('sends the attendee payload only to the registration-create endpoint', () => {
    const attendee = { name: 'Alejandro', email: 'alejandro@example.com' }

    api.sessions.register(7, attendee)

    expect(client.post).toHaveBeenCalledWith('/sessions/7/registrations', { attendee })
  })
})
