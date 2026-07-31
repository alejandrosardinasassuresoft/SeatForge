<template>
  <VApp>
    <AppHeader @toggle-drawer="drawer = !drawer" />

    <AppSidebar v-model="drawer" :rail="rail" @update:rail="rail = $event" />

    <VMain>
      <VContainer fluid class="pa-6">
        <slot />
      </VContainer>
    </VMain>

    <AppFooter />

    <VSnackbar
      v-model="snackbar.show"
      :color="snackbar.color"
      location="bottom"
      timeout="4000"
      @update:model-value="(value) => !value && store.clearNotification()"
    >
      {{ snackbar.message }}
      <template #actions>
        <VBtn variant="text" @click="store.clearNotification()">Close</VBtn>
      </template>
    </VSnackbar>
  </VApp>
</template>

<script setup>
import { ref, computed } from 'vue'
import AppHeader from './AppHeader.vue'
import AppSidebar from './AppSidebar.vue'
import AppFooter from './AppFooter.vue'
import { useAppStore } from '@/stores/app'

const store = useAppStore()

const drawer = ref(true)
const rail = ref(false)

const snackbar = computed(() => store.snackbar)
</script>
