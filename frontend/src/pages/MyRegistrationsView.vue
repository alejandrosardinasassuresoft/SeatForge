<template>
  <div>
    <h1 class="text-h4 font-weight-bold mb-2">My Registrations</h1>
    <p class="text-body-1 text-medium-emphasis mb-6">
      Look up an attendee to review their registration history and cancel bookings that the backend still allows.
    </p>

    <VCard class="pa-4 mb-6">
      <VForm ref="form" @submit.prevent="submitLookup">
        <VRow align="end">
          <VCol cols="12" sm="6" md="4">
            <VTextField
              v-model="attendeeId"
              label="Attendee ID"
              prepend-inner-icon="mdi-account-search-outline"
              type="number"
              min="1"
              hide-spin-buttons
              :rules="attendeeIdRules"
              :disabled="loading"
            />
          </VCol>
          <VCol cols="12" sm="6" md="auto">
            <VBtn
              type="submit"
              color="primary"
              prepend-icon="mdi-magnify"
              :loading="loading"
              :disabled="!attendeeId"
            >
              Look Up Registrations
            </VBtn>
          </VCol>
        </VRow>
      </VForm>
    </VCard>

    <BaseLoading v-if="loading" text="Loading registrations..." class="mb-6" />

    <BaseError
      v-else-if="status === 'error'"
      :title="errorMessage(error, 'Unable to load registrations')"
      :text="errorDetails(error)"
      action-label="Try Again"
      class="mb-6"
      @action="submitLookup"
    />

    <template v-else-if="status === 'success'">
      <VCard class="pa-4 mb-6">
        <div class="d-flex align-center ga-4 flex-wrap">
          <VAvatar color="primary" variant="tonal" size="48">
            <VIcon>mdi-account</VIcon>
          </VAvatar>
          <div>
            <div class="text-h6 font-weight-bold">{{ data.attendee.name }}</div>
            <div class="text-body-2 text-medium-emphasis">{{ data.attendee.email }}</div>
          </div>
          <VSpacer />
          <VChip color="primary" variant="tonal" :prepend-icon="registrations.length ? 'mdi-ticket-confirmation-outline' : 'mdi-ticket-outline'">
            {{ registrations.length }} registration{{ registrations.length === 1 ? '' : 's' }}
          </VChip>
        </div>
      </VCard>

      <VCard v-if="registrations.length" class="pa-2">
        <div class="d-flex align-center ga-3 flex-wrap px-2 pt-2">
          <VTextField
            v-model="search"
            label="Search workshop or status"
            prepend-inner-icon="mdi-magnify"
            density="compact"
            hide-details
            class="flex-grow-0"
            style="max-width: 280px"
          />
          <VSelect
            v-model="statusFilter"
            :items="statusFilterOptions"
            label="Status"
            density="compact"
            hide-details
            class="flex-grow-0"
            style="max-width: 200px"
          />
          <VSpacer />
        </div>

        <VDataTable
          :headers="headers"
          :items="filteredRegistrations"
          :search="search"
          :sort-by="[{ key: 'createdAt', order: 'desc' }]"
          hover
          density="comfortable"
        >
          <template #item.workshopTitle="{ item }">
            <span class="font-weight-medium">{{ item.workshopTitle }}</span>
          </template>

          <template #item.startsAt="{ item }">
            <span>{{ formatDateTime(item.startsAt) }}</span>
          </template>

          <template #item.endsAt="{ item }">
            <span>{{ formatDateTime(item.endsAt) }}</span>
          </template>

          <template #item.status="{ item }">
            <VChip
              :color="registrationStatusMeta(item.status).color"
              variant="tonal"
              size="small"
              :prepend-icon="registrationStatusMeta(item.status).icon"
            >
              {{ registrationStatusMeta(item.status).label }}
            </VChip>
          </template>

          <template #item.holdExpiresAt="{ item }">
            <span>{{ formatDateTime(item.holdExpiresAt) }}</span>
          </template>

          <template #item.confirmedAt="{ item }">
            <span>{{ formatDateTime(item.confirmedAt) }}</span>
          </template>

          <template #item.cancelledAt="{ item }">
            <span>{{ formatDateTime(item.cancelledAt) }}</span>
          </template>

          <template #item.createdAt="{ item }">
            <span>{{ formatDateTime(item.createdAt) }}</span>
          </template>

          <template #item.actions="{ item }">
            <VBtn
              v-if="canCancelRegistration(item.status)"
              size="small"
              color="error"
              variant="tonal"
              prepend-icon="mdi-cancel"
              @click="openCancelDialog(item)"
            >
              Cancel
            </VBtn>
            <span v-else class="text-body-2 text-disabled">—</span>
          </template>

          <template #no-data>
            <BaseEmpty
              icon="mdi-ticket-outline"
              title="No registrations match"
              text="Try a different status filter or search term."
              flat
            />
          </template>
        </VDataTable>
      </VCard>

      <BaseEmpty
        v-else
        icon="mdi-ticket-outline"
        title="No registrations yet"
        :text="`${data.attendee.name} has no registration history.`"
        class="mb-6"
      />
    </template>

    <BaseEmpty
      v-else
      icon="mdi-account-search-outline"
      title="Look up an attendee"
      text="Enter an attendee ID above to see their registration statuses and cancellable bookings."
      class="mb-6"
    />

    <VDialog v-model="cancelDialog" max-width="520" persistent>
      <VCard>
        <VCardTitle class="d-flex align-center ga-2 text-error">
          <VIcon>mdi-alert-outline</VIcon>
          <span>Cancel Registration</span>
        </VCardTitle>

        <VCardText>
          <p>
            You are about to cancel the registration for
            <strong>{{ cancelling?.workshopTitle }}</strong> starting
            <strong>{{ formatDateTime(cancelling?.startsAt) }}</strong>.
          </p>
          <p class="text-body-2 text-medium-emphasis mt-2">
            If this registration holds or confirms a seat, it will be released immediately and offered to the oldest
            eligible waitlisted attendee.
          </p>

          <VAlert
            v-if="cancelError"
            type="error"
            variant="tonal"
            class="mt-4"
            :title="errorMessage(cancelError, 'Cancellation failed')"
            :text="errorDetails(cancelError)"
          />
        </VCardText>

        <VCardActions>
          <VSpacer />
          <VBtn variant="tonal" :disabled="cancellingSubmit" @click="closeCancelDialog">
            Keep Registration
          </VBtn>
          <VBtn color="error" :loading="cancellingSubmit" @click="submitCancellation">
            Cancel Registration
          </VBtn>
        </VCardActions>
      </VCard>
    </VDialog>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { api } from '@/api'
import { useAsyncState } from '@/composables/useAsyncState'
import { useAppStore } from '@/stores/app'
import BaseEmpty from '@/components/shared/BaseEmpty.vue'
import BaseError from '@/components/shared/BaseError.vue'
import BaseLoading from '@/components/shared/BaseLoading.vue'
import { formatDateTime } from '@/utils/format'
import { errorMessage, errorDetails } from '@/utils/errors'
import {
  REGISTRATION_STATUSES,
  registrationStatusMeta,
  canCancelRegistration,
} from '@/utils/registrations'

const store = useAppStore()

const form = ref(null)
const attendeeId = ref('')
const attendeeIdRules = [
  (value) => !!value || 'Attendee ID is required.',
  (value) => (Number.isInteger(Number(value)) && Number(value) > 0) || 'Enter a valid attendee ID.',
]

const lookup = useAsyncState((id) => api.attendees.registrations(id))

const { data, error, status, loading } = lookup

const search = ref('')
const statusFilter = ref('all')

const statusFilterOptions = [{ title: 'All statuses', value: 'all' }, ...REGISTRATION_STATUSES]

const headers = [
  { title: 'Workshop', key: 'workshopTitle', sortable: true },
  { title: 'Starts', key: 'startsAt', sortable: true },
  { title: 'Ends', key: 'endsAt', sortable: true },
  { title: 'Status', key: 'status', sortable: true },
  { title: 'Hold Expires', key: 'holdExpiresAt', sortable: true },
  { title: 'Confirmed At', key: 'confirmedAt', sortable: true },
  { title: 'Cancelled At', key: 'cancelledAt', sortable: true },
  { title: 'Created At', key: 'createdAt', sortable: true },
  { title: 'Actions', key: 'actions', sortable: false },
]

const registrations = computed(() => (data.value?.registrations ?? []).map(mapRegistration))

const filteredRegistrations = computed(() => {
  if (statusFilter.value === 'all') return registrations.value
  return registrations.value.filter((registration) => registration.status === statusFilter.value)
})

const cancelDialog = ref(false)
const cancelling = ref(null)
const cancellingSubmit = ref(false)
const cancelError = ref(null)

async function submitLookup() {
  const { valid } = await form.value.validate()
  if (!valid) return

  try {
    await lookup.execute(Number(attendeeId.value))
  } catch {
    // Error state is rendered from the lookup composable.
  }
}

function mapRegistration(registration) {
  return {
    id: registration.id,
    status: registration.status,
    workshopTitle: registration.session?.workshop_title ?? '—',
    startsAt: registration.session?.starts_at ?? null,
    endsAt: registration.session?.ends_at ?? null,
    holdExpiresAt: registration.hold_expires_at ?? null,
    confirmedAt: registration.confirmed_at ?? null,
    cancelledAt: registration.cancelled_at ?? null,
    createdAt: registration.created_at ?? null,
  }
}

function openCancelDialog(registration) {
  cancelling.value = registration
  cancelError.value = null
  cancelDialog.value = true
}

function closeCancelDialog() {
  if (cancellingSubmit.value) return
  cancelDialog.value = false
  cancelling.value = null
  cancelError.value = null
}

async function submitCancellation() {
  if (!cancelling.value) return
  cancellingSubmit.value = true
  cancelError.value = null

  try {
    await api.registrations.cancel(cancelling.value.id)
  } catch (err) {
    cancelError.value = err
    return
  } finally {
    cancellingSubmit.value = false
  }

  cancelDialog.value = false
  cancelling.value = null
  store.notify('Registration cancelled. Registrations refreshed.', 'success')

  try {
    await lookup.execute(Number(attendeeId.value))
  } catch {
    // Error state is rendered from the lookup composable.
  }
}
</script>
