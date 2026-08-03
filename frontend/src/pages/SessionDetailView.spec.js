// @vitest-environment jsdom
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, shallowMount } from '@vue/test-utils'

const api = vi.hoisted(() => ({
  sessions: { get: vi.fn(), register: vi.fn() },
  registrations: { confirm: vi.fn() },
}))

vi.mock('vue-router', () => ({ useRoute: () => ({ params: { id: '42' } }) }))
vi.mock('@/api', () => ({ api }))

import SessionDetailView from './SessionDetailView.vue'

const scheduledSession = {
  id: 42,
  status: 'scheduled',
  starts_at: '2026-08-01T10:00:00Z',
  ends_at: '2026-08-01T12:00:00Z',
  capacity: 2,
  workshop: { title: 'Vue integration', topic: 'vue', description: 'Testing' },
  availability: { capacity: 2, available_seats: 1, confirmed_count: 1, held_count: 0, waitlist_count: 0 },
}

function mountView() {
  return shallowMount(SessionDetailView, {
    global: {
      stubs: {
        VForm: { template: '<form><slot /></form>' },
      },
    },
  })
}

describe('SessionDetailView registration outcomes', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    api.sessions.get.mockResolvedValue(scheduledSession)
  })

  it('preserves a held result and backend-provided expiration', async () => {
    api.sessions.register.mockResolvedValue({ id: 9, status: 'held', hold_expires_at: '2026-08-01T10:10:00Z' })
    const wrapper = mountView()
    await flushPromises()

    wrapper.vm.registrationForm.name = 'Alejandro'
    wrapper.vm.registrationForm.email = 'alejandro@example.com'
    await wrapper.vm.submitRegistration()

    expect(api.sessions.register).toHaveBeenCalledWith('42', { name: 'Alejandro', email: 'alejandro@example.com' })
    expect(wrapper.vm.registration.status).toBe('held')
    expect(wrapper.text()).toContain('Your seat is temporarily held')
  })

  it('keeps waitlisted outcome visibly distinct from a hold', async () => {
    api.sessions.register.mockResolvedValue({ id: 10, status: 'waitlisted', hold_expires_at: null })
    const wrapper = mountView()
    await flushPromises()

    wrapper.vm.registrationForm.name = 'Alejandro'
    wrapper.vm.registrationForm.email = 'alejandro@example.com'
    await wrapper.vm.submitRegistration()

    expect(wrapper.vm.registration.status).toBe('waitlisted')
    expect(wrapper.text()).toContain('You are on the waitlist')
    expect(wrapper.text()).not.toContain('Confirm my seat')
  })

  it('preserves a backend conflict and refreshes detail after confirmation', async () => {
    api.sessions.register.mockResolvedValue({ id: 11, status: 'held', hold_expires_at: '2026-08-01T10:10:00Z' })
    api.registrations.confirm.mockResolvedValue({ id: 11, status: 'confirmed' })
    const wrapper = mountView()
    await flushPromises()

    wrapper.vm.registrationForm.name = 'Alejandro'
    wrapper.vm.registrationForm.email = 'alejandro@example.com'
    await wrapper.vm.submitRegistration()
    await wrapper.vm.confirmRegistration()

    expect(api.registrations.confirm).toHaveBeenCalledWith(11)
    expect(api.sessions.get).toHaveBeenCalledTimes(3)
    expect(wrapper.vm.registration.status).toBe('confirmed')
  })

  it('renders the backend validation or conflict message unchanged', async () => {
    api.sessions.register.mockRejectedValue({ code: 'duplicate_registration', message: 'Attendee already has an active registration', details: ['Only one active registration is allowed'] })
    const wrapper = mountView()
    await flushPromises()

    wrapper.vm.registrationForm.name = 'Alejandro'
    wrapper.vm.registrationForm.email = 'alejandro@example.com'
    await wrapper.vm.submitRegistration()

    expect(wrapper.vm.operationError.message).toBe('Attendee already has an active registration')
    expect(wrapper.text()).toContain('Attendee already has an active registration')
  })

  it('does not render registration controls for cancelled sessions', async () => {
    api.sessions.get.mockResolvedValue({
      ...scheduledSession,
      status: 'cancelled',
      cancellation_reason: 'Instructor unavailable',
      cancelled_at: '2026-07-31T10:00:00Z',
    })
    const wrapper = mountView()
    await flushPromises()

    expect(wrapper.text()).toContain('Instructor unavailable')
    expect(wrapper.text()).toContain('Registration is unavailable')
    expect(wrapper.find('form').exists()).toBe(false)
  })
})
