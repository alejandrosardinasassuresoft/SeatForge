<template>
  <div>
    <div class="mb-4">
      <VBtn
        to="/workshops"
        variant="text"
        prepend-icon="mdi-arrow-left"
        class="px-0"
      >
        Back to Workshop Catalog
      </VBtn>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="my-8">
      <BaseSkeletonLoader />
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="my-8">
      <BaseError :error="error" @retry="fetchSessionDetail" />
    </div>

    <!-- Session Detail Content -->
    <div v-else-if="session">
      <!-- Cancelled Banner -->
      <VAlert
        v-if="session.status === 'cancelled'"
        type="error"
        variant="tonal"
        prominent
        class="mb-6"
        icon="mdi-cancel"
      >
        <VAlertTitle class="font-weight-bold">Session Cancelled</VAlertTitle>
        <div>
          <strong>Reason:</strong> {{ session.cancellation_reason || 'Cancelled by organizer' }}
        </div>
        <div v-if="session.cancelled_at" class="text-caption mt-1">
          Cancelled on: {{ formatDate(session.cancelled_at) }} {{ formatTime(session.cancelled_at) }}
        </div>
      </VAlert>

      <VCard class="pa-6" variant="outlined">
        <div class="d-flex align-center justify-space-between mb-4 flex-wrap ga-2">
          <VChip color="primary" variant="tonal" size="large" class="font-weight-bold text-uppercase">
            {{ session.workshop?.topic || 'General' }}
          </VChip>

          <VChip
            :color="getStatusColor(session)"
            size="large"
            variant="flat"
            class="font-weight-bold"
          >
            {{ getStatusLabel(session) }}
          </VChip>
        </div>

        <h1 class="text-h3 font-weight-bold mb-3">
          {{ session.workshop?.title }}
        </h1>

        <p class="text-body-1 text-medium-emphasis mb-6">
          {{ session.workshop?.description || 'No detailed description provided for this workshop.' }}
        </p>

        <VDivider class="my-6" />

        <!-- Schedule Section -->
        <h2 class="text-h6 font-weight-bold mb-4">Schedule</h2>
        <VRow class="mb-6">
          <VCol cols="12" sm="6">
            <VCard class="pa-4 fill-height" variant="tonal" color="primary">
              <div class="d-flex align-center ga-3">
                <VAvatar color="primary" variant="flat">
                  <VIcon color="white">mdi-calendar</VIcon>
                </VAvatar>
                <div>
                  <div class="text-caption text-medium-emphasis">Date</div>
                  <div class="text-subtitle-1 font-weight-bold">{{ formatDate(session.starts_at) }}</div>
                </div>
              </div>
            </VCard>
          </VCol>

          <VCol cols="12" sm="6">
            <VCard class="pa-4 fill-height" variant="tonal" color="primary">
              <div class="d-flex align-center ga-3">
                <VAvatar color="primary" variant="flat">
                  <VIcon color="white">mdi-clock-outline</VIcon>
                </VAvatar>
                <div>
                  <div class="text-caption text-medium-emphasis">Time</div>
                  <div class="text-subtitle-1 font-weight-bold">
                    {{ formatTime(session.starts_at) }} — {{ formatTime(session.ends_at) }}
                  </div>
                </div>
              </div>
            </VCard>
          </VCol>
        </VRow>

        <!-- Availability Metrics Grid -->
        <h2 class="text-h6 font-weight-bold mb-4">Seat Availability Breakdown</h2>
        <VRow class="mb-6">
          <VCol cols="6" sm="4" md="2.4">
            <VCard class="pa-4 text-center" variant="outlined">
              <div class="text-caption text-medium-emphasis mb-1">Total Capacity</div>
              <div class="text-h4 font-weight-bold">{{ availability.capacity }}</div>
            </VCard>
          </VCol>

          <VCol cols="6" sm="4" md="2.4">
            <VCard class="pa-4 text-center" variant="outlined" color="success">
              <div class="text-caption text-medium-emphasis mb-1">Available Seats</div>
              <div class="text-h4 font-weight-bold text-success">{{ availability.available_seats }}</div>
            </VCard>
          </VCol>

          <VCol cols="6" sm="4" md="2.4">
            <VCard class="pa-4 text-center" variant="outlined" color="info">
              <div class="text-caption text-medium-emphasis mb-1">Confirmed</div>
              <div class="text-h4 font-weight-bold text-info">{{ availability.confirmed_count }}</div>
            </VCard>
          </VCol>

          <VCol cols="6" sm="4" md="2.4">
            <VCard class="pa-4 text-center" variant="outlined" color="warning">
              <div class="text-caption text-medium-emphasis mb-1">Active Holds</div>
              <div class="text-h4 font-weight-bold text-warning">{{ availability.held_count }}</div>
            </VCard>
          </VCol>

          <VCol cols="6" sm="4" md="2.4">
            <VCard class="pa-4 text-center" variant="outlined" color="secondary">
              <div class="text-caption text-medium-emphasis mb-1">Waitlist Size</div>
              <div class="text-h4 font-weight-bold">{{ availability.waitlist_count }}</div>
            </VCard>
          </VCol>
        </VRow>
      </VCard>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '@/api'
import BaseSkeletonLoader from '@/components/shared/BaseSkeletonLoader.vue'
import BaseError from '@/components/shared/BaseError.vue'

const route = useRoute()
const session = ref(null)
const loading = ref(false)
const error = ref(null)

const availability = computed(() => {
  if (!session.value?.availability) {
    return {
      capacity: session.value?.capacity || 0,
      available_seats: session.value?.capacity || 0,
      confirmed_count: 0,
      held_count: 0,
      waitlist_count: 0,
    }
  }
  return session.value.availability
})

const fetchSessionDetail = async () => {
  loading.value = true
  error.value = null
  try {
    const id = route.params.id
    const data = await api.sessions.get(id)
    session.value = data
  } catch (err) {
    error.value = err
  } finally {
    loading.value = false
  }
}

const getStatusColor = (session) => {
  if (session.status === 'cancelled') return 'error'
  if (session.status === 'completed') return 'secondary'
  const seats = availability.value.available_seats
  return seats > 0 ? 'success' : 'warning'
}

const getStatusLabel = (session) => {
  if (session.status === 'cancelled') return 'Cancelled'
  if (session.status === 'completed') return 'Completed'
  const seats = availability.value.available_seats
  return seats > 0 ? `${seats} Seats Available` : 'Waitlist Open'
}

const formatDate = (isoStr) => {
  if (!isoStr) return ''
  return new Date(isoStr).toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })
}

const formatTime = (isoStr) => {
  if (!isoStr) return ''
  return new Date(isoStr).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

onMounted(() => {
  fetchSessionDetail()
})
</script>
