<template>
  <div>
    <h1 class="text-h4 font-weight-bold mb-2">Home</h1>
    <p class="text-body-1 text-medium-emphasis mb-6">
      Welcome to SeatForge. Use the sidebar to navigate.
    </p>

    <VRow>
      <VCol cols="12" md="4">
        <VCard class="pa-4" color="primary" variant="tonal">
          <VCardTitle class="d-flex align-center ga-3">
            <VIcon>mdi-server</VIcon>
            <span class="text-subtitle-1">API Status</span>
          </VCardTitle>
          <VCardText>
            <div v-if="status === 'loading' || status === 'idle'">
              <VSkeletonLoader type="text" />
            </div>
            <div v-else-if="status === 'error'" class="text-error">
              <div class="d-flex align-center ga-2">
                <VIcon color="error">mdi-alert-circle</VIcon>
                <span class="text-error">Connection failed — API is unreachable</span>
              </div>
            </div>
            <div v-else class="d-flex align-center ga-2">
              <VIcon color="success">mdi-check-circle</VIcon>
              <span>Backend is reachable</span>
            </div>
          </VCardText>
        </VCard>
      </VCol>

      <VCol cols="12" md="4">
        <VCard class="pa-4" color="success" variant="tonal">
          <VCardTitle class="d-flex align-center ga-3">
            <VIcon>mdi-account-group</VIcon>
            <span class="text-subtitle-1">Users</span>
          </VCardTitle>
          <VCardText class="text-h3 font-weight-bold">—</VCardText>
        </VCard>
      </VCol>

      <VCol cols="12" md="4">
        <VCard class="pa-4" color="warning" variant="tonal">
          <VCardTitle class="d-flex align-center ga-3">
            <VIcon>mdi-ticket-outline</VIcon>
            <span class="text-subtitle-1">Bookings</span>
          </VCardTitle>
          <VCardText class="text-h3 font-weight-bold">—</VCardText>
        </VCard>
      </VCol>
    </VRow>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { api } from '@/api'

const status = ref('idle')

onMounted(async () => {
  status.value = 'loading'
  try {
    await api.health.check()
    status.value = 'success'
  } catch {
    status.value = 'error'
  }
})
</script>
