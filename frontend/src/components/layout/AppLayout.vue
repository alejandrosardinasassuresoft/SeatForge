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
  </VApp>
</template>

<script setup>
import { ref } from 'vue'
import AppHeader from './AppHeader.vue'
import AppSidebar from './AppSidebar.vue'
import AppFooter from './AppFooter.vue'

const drawer = ref(true)
const rail = ref(false)
</script>
