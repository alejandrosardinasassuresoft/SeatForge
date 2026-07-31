<template>
  <div>
    <header class="mb-6">
      <h1 class="text-h4 font-weight-bold mb-1">Workshop Catalog</h1>
      <p class="text-body-1 text-medium-emphasis">
        Discover upcoming technical workshops and check real-time seat availability.
      </p>
    </header>

    <!-- Filters Bar -->
    <VCard class="pa-4 mb-6" variant="outlined">
      <VRow align="center" density="comfortable">
        <VCol cols="12" sm="6" md="3">
          <VSelect
            v-model="filters.topic"
            :items="topicOptions"
            label="Topic"
            density="compact"
            variant="outlined"
            hide-details
            clearable
            @update:model-value="fetchSessions(1)"
          />
        </VCol>

        <VCol cols="12" sm="6" md="3">
          <VSelect
            v-model="filters.sort"
            :items="sortOptions"
            label="Sort By"
            density="compact"
            variant="outlined"
            hide-details
            @update:model-value="fetchSessions(1)"
          />
        </VCol>

        <VCol cols="12" sm="6" md="3">
          <VSelect
            v-model="filters.order"
            :items="orderOptions"
            label="Order"
            density="compact"
            variant="outlined"
            hide-details
            @update:model-value="fetchSessions(1)"
          />
        </VCol>

        <VCol cols="12" sm="6" md="3">
          <VSwitch
            v-model="filters.available"
            label="Available Seats Only"
            color="primary"
            density="compact"
            hide-details
            @update:model-value="fetchSessions(1)"
          />
        </VCol>
      </VRow>
    </VCard>

    <!-- Loading State -->
    <div v-if="loading" class="my-8">
      <BaseSkeletonLoader />
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="my-8">
      <BaseError :error="error" @retry="fetchSessions(pagination.current_page)" />
    </div>

    <!-- Empty State -->
    <div v-else-if="sessions.length === 0" class="my-8">
      <BaseEmpty title="No sessions found" message="No upcoming sessions match your current filter criteria." />
    </div>

    <!-- Sessions Grid -->
    <div v-else>
      <VRow>
        <VCol v-for="session in sessions" :key="session.id" cols="12" md="6" lg="4">
          <VCard class="fill-height d-flex flex-column" variant="outlined">
            <VCardItem>
              <template #prepend>
                <VChip color="primary" size="small" variant="tonal" class="text-uppercase font-weight-bold">
                  {{ session.workshop?.topic || 'General' }}
                </VChip>
              </template>

              <template #append>
                <VChip
                  :color="getStatusColor(session)"
                  size="small"
                  variant="flat"
                  class="font-weight-bold"
                >
                  {{ getStatusLabel(session) }}
                </VChip>
              </template>
            </VCardItem>

            <VCardTitle class="text-h6 font-weight-bold">
              <router-link :to="`/sessions/${session.id}`" class="text-decoration-none text-high-emphasis">
                {{ session.workshop?.title || 'Workshop Session' }}
              </router-link>
            </VCardTitle>

            <VCardText class="flex-grow-1">
              <div class="d-flex align-center ga-2 text-body-2 text-medium-emphasis mb-3">
                <VIcon size="small">mdi-calendar-clock</VIcon>
                <span>{{ formatDate(session.starts_at) }} — {{ formatTime(session.ends_at) }}</span>
              </div>

              <VDivider class="my-3" />

              <div class="d-flex flex-column ga-2 text-caption">
                <div class="d-flex justify-space-between">
                  <span class="text-medium-emphasis">Capacity:</span>
                  <span class="font-weight-bold">{{ session.capacity }} seats</span>
                </div>
                <div class="d-flex justify-space-between">
                  <span class="text-medium-emphasis">Available:</span>
                  <span class="font-weight-bold text-success">{{ getAvailableSeats(session) }} seats</span>
                </div>
              </div>

              <div v-if="session.status === 'cancelled'" class="mt-3 text-caption text-error font-weight-medium">
                <VIcon size="small" color="error">mdi-alert-circle</VIcon>
                Cancelled: {{ session.cancellation_reason || 'Session cancelled by organizer' }}
              </div>
            </VCardText>

            <VCardActions class="pa-4 pt-0">
              <VBtn
                :to="`/sessions/${session.id}`"
                color="primary"
                variant="tonal"
                block
                prepend-icon="mdi-eye-outline"
              >
                View Details
              </VBtn>
            </VCardActions>
          </VCard>
        </VCol>
      </VRow>

      <!-- Pagination -->
      <div v-if="pagination.total_pages > 1" class="d-flex justify-center my-6">
        <VPagination
          v-model="pagination.current_page"
          :length="pagination.total_pages"
          :total-visible="7"
          color="primary"
          @update:model-value="fetchSessions"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { api } from '@/api'
import BaseSkeletonLoader from '@/components/shared/BaseSkeletonLoader.vue'
import BaseEmpty from '@/components/shared/BaseEmpty.vue'
import BaseError from '@/components/shared/BaseError.vue'

const sessions = ref([])
const loading = ref(false)
const error = ref(null)

const pagination = reactive({
  current_page: 1,
  total_pages: 1,
  total_records: 0,
})

const filters = reactive({
  topic: null,
  sort: 'starts_at',
  order: 'asc',
  available: false,
})

const topicOptions = [
  { title: 'All Topics', value: null },
  { title: 'Rails', value: 'rails' },
  { title: 'Backend', value: 'Backend' },
  { title: 'Vue', value: 'vue' },
  { title: 'PostgreSQL', value: 'postgresql' },
  { title: 'DevOps', value: 'devops' },
]

const sortOptions = [
  { title: 'Start Date', value: 'starts_at' },
  { title: 'Capacity', value: 'capacity' },
  { title: 'Created Date', value: 'created_at' },
]

const orderOptions = [
  { title: 'Ascending', value: 'asc' },
  { title: 'Descending', value: 'desc' },
]

const fetchSessions = async (page = pagination.current_page) => {
  loading.value = true
  error.value = null
  try {
    const params = {
      page,
      per_page: 9,
      sort: filters.sort,
      order: filters.order,
    }
    if (filters.topic) params.topic = filters.topic
    if (filters.available) params.available = 'true'

    const res = await api.sessions.list(params)
    sessions.value = res.sessions || []
    if (res.pagination) {
      pagination.current_page = res.pagination.current_page
      pagination.total_pages = res.pagination.total_pages
      pagination.total_records = res.pagination.total_records
    }
  } catch (err) {
    error.value = err
  } finally {
    loading.value = false
  }
}

const getAvailableSeats = (session) => {
  if (session.available_seats !== undefined) return session.available_seats
  return session.capacity || 0
}

const getStatusColor = (session) => {
  if (session.status === 'cancelled') return 'error'
  if (session.status === 'completed') return 'secondary'
  const seats = getAvailableSeats(session)
  return seats > 0 ? 'success' : 'warning'
}

const getStatusLabel = (session) => {
  if (session.status === 'cancelled') return 'Cancelled'
  if (session.status === 'completed') return 'Completed'
  const seats = getAvailableSeats(session)
  return seats > 0 ? `${seats} Seats Left` : 'Waitlist Open'
}

const formatDate = (isoStr) => {
  if (!isoStr) return ''
  return new Date(isoStr).toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })
}

const formatTime = (isoStr) => {
  if (!isoStr) return ''
  return new Date(isoStr).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

onMounted(() => {
  fetchSessions(1)
})
</script>
