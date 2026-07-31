<template>
  <div>
    <div class="mb-4">
      <VBtn to="/workshops" variant="text" prepend-icon="mdi-arrow-left" class="px-0">
        Back to Workshop Catalog
      </VBtn>
    </div>

    <div v-if="loading" class="my-8"><BaseSkeletonLoader /></div>
    <div v-else-if="error" class="my-8"><BaseError :errors="error.errors" :text="error.message" @action="fetchSessionDetail" /></div>

    <div v-else-if="session">
      <VAlert v-if="session.status === 'cancelled'" type="error" variant="tonal" prominent class="mb-6" icon="mdi-cancel">
        <VAlertTitle class="font-weight-bold">Session Cancelled</VAlertTitle>
        <div><strong>Reason:</strong> {{ session.cancellation_reason || 'Cancelled by organizer' }}</div>
        <div v-if="session.cancelled_at" class="text-caption mt-1">Cancelled on: {{ formatDateTime(session.cancelled_at) }}</div>
      </VAlert>

      <VCard class="pa-6" variant="outlined">
        <div class="d-flex align-center justify-space-between mb-4 flex-wrap ga-2">
          <VChip color="primary" variant="tonal" size="large" class="font-weight-bold text-uppercase">{{ session.workshop?.topic || 'General' }}</VChip>
          <VChip :color="getStatusColor(session)" size="large" variant="flat" class="font-weight-bold">{{ getStatusLabel(session) }}</VChip>
        </div>

        <h1 class="text-h3 font-weight-bold mb-3">{{ session.workshop?.title }}</h1>
        <p class="text-body-1 text-medium-emphasis mb-6">{{ session.workshop?.description || 'No detailed description provided for this workshop.' }}</p>

        <VDivider class="my-6" />
        <h2 class="text-h6 font-weight-bold mb-4">Schedule</h2>
        <VRow class="mb-6">
          <VCol cols="12" sm="6">
            <VCard class="pa-4 fill-height" variant="tonal" color="primary">
              <div class="d-flex align-center ga-3"><VAvatar color="primary" variant="flat"><VIcon color="white">mdi-calendar</VIcon></VAvatar><div><div class="text-caption text-medium-emphasis">Date</div><div class="text-subtitle-1 font-weight-bold">{{ formatDate(session.starts_at) }}</div></div></div>
            </VCard>
          </VCol>
          <VCol cols="12" sm="6">
            <VCard class="pa-4 fill-height" variant="tonal" color="primary">
              <div class="d-flex align-center ga-3"><VAvatar color="primary" variant="flat"><VIcon color="white">mdi-clock-outline</VIcon></VAvatar><div><div class="text-caption text-medium-emphasis">Time</div><div class="text-subtitle-1 font-weight-bold">{{ formatTime(session.starts_at) }} - {{ formatTime(session.ends_at) }}</div></div></div>
            </VCard>
          </VCol>
        </VRow>

        <h2 class="text-h6 font-weight-bold mb-4">Seat Availability Breakdown</h2>
        <VRow class="mb-6">
          <VCol cols="6" sm="4" md="2"><VCard class="pa-4 text-center" variant="outlined"><div class="text-caption text-medium-emphasis mb-1">Total Capacity</div><div class="text-h4 font-weight-bold">{{ availability.capacity }}</div></VCard></VCol>
          <VCol cols="6" sm="4" md="2"><VCard class="pa-4 text-center" variant="outlined" color="success"><div class="text-caption text-medium-emphasis mb-1">Available Seats</div><div class="text-h4 font-weight-bold text-success">{{ availability.available_seats }}</div></VCard></VCol>
          <VCol cols="6" sm="4" md="2"><VCard class="pa-4 text-center" variant="outlined" color="info"><div class="text-caption text-medium-emphasis mb-1">Confirmed</div><div class="text-h4 font-weight-bold text-info">{{ availability.confirmed_count }}</div></VCard></VCol>
          <VCol cols="6" sm="4" md="2"><VCard class="pa-4 text-center" variant="outlined" color="warning"><div class="text-caption text-medium-emphasis mb-1">Active Holds</div><div class="text-h4 font-weight-bold text-warning">{{ availability.held_count }}</div></VCard></VCol>
          <VCol cols="6" sm="4" md="2"><VCard class="pa-4 text-center" variant="outlined" color="secondary"><div class="text-caption text-medium-emphasis mb-1">Waitlist Size</div><div class="text-h4 font-weight-bold">{{ availability.waitlist_count }}</div></VCard></VCol>
        </VRow>

        <VDivider class="my-6" />
        <section aria-labelledby="registration-heading">
          <h2 id="registration-heading" class="text-h6 font-weight-bold mb-2">Reserve your place</h2>
          <p v-if="canRegister" class="text-body-2 text-medium-emphasis mb-4">Enter your details to receive a seat hold or join the waitlist.</p>
          <VAlert v-else type="error" variant="tonal" class="mb-4">Registration is unavailable because this session has been cancelled.</VAlert>

          <VAlert v-if="operationError" type="error" variant="tonal" class="mb-4" closable @click:close="operationError = null">
            <strong>{{ operationError.code || 'Request failed' }}:</strong> {{ operationError.message }}
            <ul v-if="operationError.details?.length" class="mt-2 pl-4"><li v-for="detail in operationError.details" :key="detail">{{ detail }}</li></ul>
          </VAlert>

          <VForm v-if="canRegister" @submit.prevent="submitRegistration">
            <VRow>
              <VCol cols="12" md="5"><VTextField v-model="registrationForm.name" label="Full name" autocomplete="name" :error-messages="fieldErrors.name" required /></VCol>
              <VCol cols="12" md="5"><VTextField v-model="registrationForm.email" label="Email" type="email" autocomplete="email" :error-messages="fieldErrors.email" required /></VCol>
              <VCol cols="12" md="2" class="d-flex align-center"><VBtn type="submit" color="primary" block :loading="registrationLoading" :disabled="registrationLoading">Register</VBtn></VCol>
            </VRow>
          </VForm>

          <VAlert v-if="registration" :type="registrationAlertType" variant="tonal" class="mt-4">
            <VAlertTitle class="font-weight-bold">{{ registrationAlertTitle }}</VAlertTitle>
            <template v-if="registration.status === 'held'">
              Your seat is held until <strong>{{ formatDateTime(registration.hold_expires_at) }}</strong>. Confirm before it expires.
              <div class="mt-3"><VBtn color="success" :loading="confirmationLoading" :disabled="!canConfirm" @click="confirmRegistration">Confirm my seat</VBtn></div>
            </template>
            <template v-else-if="registration.status === 'waitlisted'">This session is currently full. You have joined the waitlist and will be notified if a seat becomes available.</template>
            <template v-else-if="registration.status === 'confirmed'">Your registration is confirmed. We look forward to seeing you there.</template>
            <template v-else>Registration status: {{ registration.status }}.</template>
          </VAlert>
        </section>
      </VCard>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '@/api'
import BaseError from '@/components/shared/BaseError.vue'
import BaseSkeletonLoader from '@/components/shared/BaseSkeletonLoader.vue'

const route = useRoute()
const session = ref(null)
const loading = ref(false)
const error = ref(null)
const registration = ref(null)
const registrationLoading = ref(false)
const confirmationLoading = ref(false)
const operationError = ref(null)
const registrationForm = reactive({ name: '', email: '' })
const fieldErrors = reactive({ name: [], email: [] })

const availability = computed(() => session.value?.availability || {
  capacity: session.value?.capacity || 0,
  available_seats: session.value?.capacity || 0,
  confirmed_count: 0,
  held_count: 0,
  waitlist_count: 0,
})
const canRegister = computed(() => session.value?.status !== 'cancelled')
const canConfirm = computed(() => registration.value?.status === 'held' && canRegister.value && !confirmationLoading.value)
const registrationAlertType = computed(() => registration.value?.status === 'waitlisted' ? 'warning' : registration.value?.status === 'confirmed' ? 'success' : 'info')
const registrationAlertTitle = computed(() => {
  if (registration.value?.status === 'held') return 'Your seat is temporarily held'
  if (registration.value?.status === 'waitlisted') return 'You are on the waitlist'
  if (registration.value?.status === 'confirmed') return 'Your seat is confirmed'
  return 'Registration updated'
})

async function fetchSessionDetail({ showLoading = true } = {}) {
  if (showLoading) loading.value = true
  error.value = null
  try {
    session.value = await api.sessions.get(route.params.id)
  } catch (requestError) {
    error.value = requestError
  } finally {
    if (showLoading) loading.value = false
  }
}

function validateRegistration() {
  fieldErrors.name = registrationForm.name.trim() ? [] : ['Name is required']
  fieldErrors.email = registrationForm.email.trim() ? [] : ['Email is required']
  return !fieldErrors.name.length && !fieldErrors.email.length
}

async function submitRegistration() {
  operationError.value = null
  if (!validateRegistration() || !canRegister.value) return
  registrationLoading.value = true
  try {
    registration.value = await api.sessions.register(route.params.id, {
      name: registrationForm.name.trim(),
      email: registrationForm.email.trim(),
    })
    await fetchSessionDetail({ showLoading: false })
  } catch (requestError) {
    operationError.value = requestError
  } finally {
    registrationLoading.value = false
  }
}

async function confirmRegistration() {
  if (!canConfirm.value) return
  operationError.value = null
  confirmationLoading.value = true
  try {
    registration.value = await api.registrations.confirm(registration.value.id)
    await fetchSessionDetail({ showLoading: false })
  } catch (requestError) {
    operationError.value = requestError
  } finally {
    confirmationLoading.value = false
  }
}

function getStatusColor(currentSession) {
  if (currentSession.status === 'cancelled') return 'error'
  if (currentSession.status === 'completed') return 'secondary'
  return availability.value.available_seats > 0 ? 'success' : 'warning'
}

function getStatusLabel(currentSession) {
  if (currentSession.status === 'cancelled') return 'Cancelled'
  if (currentSession.status === 'completed') return 'Completed'
  return availability.value.available_seats > 0 ? `${availability.value.available_seats} Seats Available` : 'Waitlist Open'
}

function formatDate(isoString) {
  if (!isoString) return ''
  return new Date(isoString).toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })
}

function formatTime(isoString) {
  if (!isoString) return ''
  return new Date(isoString).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

function formatDateTime(isoString) {
  if (!isoString) return 'an unknown time'
  return new Date(isoString).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })
}

onMounted(() => fetchSessionDetail())
</script>