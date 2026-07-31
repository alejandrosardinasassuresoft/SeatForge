<template>
  <div>
    <h1 class="text-h4 font-weight-bold mb-2">Operations Dashboard</h1>
    <p class="text-body-1 text-medium-emphasis mb-6">
      Live capacity and waitlist metrics across every upcoming session.
    </p>

    <BaseLoading v-if="loading" text="Loading dashboard metrics..." class="mb-6" />

    <BaseError
      v-else-if="status === 'error'"
      :title="errorMessage(error, 'Unable to load dashboard metrics')"
      :text="errorDetails(error)"
      action-label="Try Again"
      class="mb-6"
      @action="execute"
    />

    <template v-else-if="status === 'success'">
      <VRow class="mb-6">
        <VCol v-for="metric in metrics" :key="metric.key" cols="12" sm="6" md="4" xl="2">
          <VCard class="pa-4">
            <VCardTitle class="d-flex align-center ga-2 text-subtitle-2 text-medium-emphasis pa-0 mb-3">
              <VIcon :color="metric.color" size="24">{{ metric.icon }}</VIcon>
              <span>{{ metric.label }}</span>
            </VCardTitle>
            <VCardText class="pa-0 text-h3 font-weight-bold">
              {{ metricValue(metric.key) }}
            </VCardText>
          </VCard>
        </VCol>
      </VRow>

      <VRow>
        <VCol cols="12" xl="6">
          <VCard class="pa-2 mb-6">
            <VCardTitle class="px-3 pt-3">Full Sessions</VCardTitle>
            <VDataTable
              :headers="fullSessionsHeaders"
              :items="fullSessions"
              hover
              density="comfortable"
            >
              <template #item.startsAt="{ item }">
                <span>{{ formatDateTime(item.startsAt) }}</span>
              </template>

              <template #no-data>
                <BaseEmpty
                  icon="mdi-check-all"
                  title="No full sessions"
                  text="Every upcoming session still has available seats."
                  flat
                />
              </template>
            </VDataTable>
          </VCard>
        </VCol>

        <VCol cols="12" xl="6">
          <VCard class="pa-2 mb-6">
            <VCardTitle class="px-3 pt-3">Top Waitlisted Sessions</VCardTitle>
            <VDataTable
              :headers="topWaitlistedHeaders"
              :items="topWaitlisted"
              hover
              density="comfortable"
            >
              <template #item.startsAt="{ item }">
                <span>{{ formatDateTime(item.startsAt) }}</span>
              </template>

              <template #no-data>
                <BaseEmpty
                  icon="mdi-account-clock-outline"
                  title="No waitlisted sessions"
                  text="No upcoming session currently has a waitlist."
                  flat
                />
              </template>
            </VDataTable>
          </VCard>
        </VCol>
      </VRow>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { api } from '@/api'
import { useAsyncState } from '@/composables/useAsyncState'
import BaseEmpty from '@/components/shared/BaseEmpty.vue'
import BaseError from '@/components/shared/BaseError.vue'
import BaseLoading from '@/components/shared/BaseLoading.vue'
import { formatDateTime } from '@/utils/format'
import { errorMessage, errorDetails } from '@/utils/errors'

const dashboard = useAsyncState(() => api.dashboard.show())

const { data, error, status, loading, execute } = dashboard

const metrics = [
  { key: 'upcoming_scheduled_sessions', label: 'Upcoming Sessions', icon: 'mdi-calendar-month-outline', color: 'primary' },
  { key: 'total_held', label: 'Held', icon: 'mdi-timer-sand', color: 'info' },
  { key: 'total_confirmed', label: 'Confirmed', icon: 'mdi-check-circle-outline', color: 'success' },
  { key: 'total_waitlisted', label: 'Waitlisted', icon: 'mdi-account-clock-outline', color: 'warning' },
  { key: 'expired_holds_today', label: 'Expired Today', icon: 'mdi-clock-alert-outline', color: 'grey' },
]

const fullSessionsHeaders = [
  { title: 'Workshop', key: 'workshop', sortable: true },
  { title: 'Starts', key: 'startsAt', sortable: true },
  { title: 'Capacity', key: 'capacity', sortable: true },
  { title: 'Confirmed', key: 'confirmed', sortable: true },
]

const topWaitlistedHeaders = [
  { title: 'Workshop', key: 'workshop', sortable: true },
  { title: 'Starts', key: 'startsAt', sortable: true },
  { title: 'Capacity', key: 'capacity', sortable: true },
  { title: 'Waitlist', key: 'waitlistSize', sortable: true },
]

const fullSessions = computed(() => (data.value?.full_sessions ?? []).map(mapFullSession))

const topWaitlisted = computed(() =>
  (data.value?.top_waitlisted_sessions ?? []).map(mapTopWaitlistedSession),
)

function metricValue(key) {
  return data.value?.[key] ?? 0
}

function mapFullSession(session) {
  return {
    id: session.id,
    workshop: session.workshop ?? '—',
    startsAt: session.starts_at ?? null,
    capacity: session.capacity ?? 0,
    confirmed: session.confirmed ?? 0,
  }
}

function mapTopWaitlistedSession(session) {
  return {
    id: session.id,
    workshop: session.workshop ?? '—',
    startsAt: session.starts_at ?? null,
    capacity: session.capacity ?? 0,
    waitlistSize: session.waitlist_size ?? 0,
  }
}

onMounted(() => {
  execute()
})
</script>
