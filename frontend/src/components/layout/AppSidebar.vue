<template>
  <VNavigationDrawer v-model="internalDrawer" :rail="rail" expand-on-hover permanent app>
    <template #prepend>
      <VList-item class="pa-4" lines="two">
        <template #prepend>
          <VAvatar color="primary" variant="tonal" size="40">
            <VIcon>mdi-anvil</VIcon>
          </VAvatar>
        </template>

        <VListItemTitle class="font-weight-bold">SeatForge</VListItemTitle>
        <VListItemSubtitle>Admin Panel</VListItemSubtitle>
      </VList-item>
    </template>

    <VDivider />

    <VList density="compact" nav>
      <VListItem
        v-for="item in navItems"
        :key="item.to"
        :to="item.to"
        :prepend-icon="item.icon"
        :title="item.label"
        :value="item.to"
        color="primary"
        rounded="lg"
        class="mx-2 mb-1"
        active-class="v-list-item--active"
      />
    </VList>

    <template #append>
      <VDivider />
      <VListItem
        prepend-icon="mdi-cog-outline"
        title="Settings"
        rounded="lg"
        class="mx-2 my-2"
      />
    </template>
  </VNavigationDrawer>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: { type: Boolean, default: true },
  rail: { type: Boolean, default: false },
})

const emit = defineEmits(['update:modelValue'])

const internalDrawer = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

const navItems = [
  { icon: 'mdi-view-dashboard-outline', label: 'Dashboard', to: '/' },
  { icon: 'mdi-information-outline', label: 'About', to: '/about' },
]
</script>
