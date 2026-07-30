<template>
  <VCard class="d-flex flex-column align-center justify-center pa-8 text-center" :flat="flat">
    <VIcon :size="iconSize" color="text-disabled" class="mb-4">
      {{ icon }}
    </VIcon>
    <span class="text-h6 text-medium-emphasis">{{ title }}</span>
    <span v-if="text" class="text-body-2 text-disabled mt-1">{{ text }}</span>
    <VBtn v-if="actionLabel" variant="tonal" class="mt-4" @click="$emit('action')">
      {{ actionLabel }}
    </VBtn>
  </VCard>
</template>

<script setup>
defineEmits(['action'])

defineProps({
  icon: { type: String, default: 'mdi-inbox-outline' },
  iconSize: { type: Number, default: 64 },
  title: { type: String, default: 'No data found' },
  text: { type: String, default: '' },
  actionLabel: { type: String, default: '' },
  flat: { type: Boolean, default: false },
})
</script>
