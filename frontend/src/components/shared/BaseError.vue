<template>
  <VCard class="d-flex flex-column align-center justify-center pa-8 text-center" :flat="flat">
    <VIcon :size="iconSize" color="error" class="mb-4">
      {{ icon }}
    </VIcon>
    <span class="text-h6 text-error">{{ title }}</span>
    <span v-if="text" class="text-body-2 text-medium-emphasis mt-1">{{ text }}</span>

    <ul v-if="errors?.length" class="text-body-2 text-error mt-2 text-start" style="list-style: none; padding: 0;">
      <li v-for="(err, i) in errors" :key="i">
        {{ err.title }}: {{ err.detail }}
      </li>
    </ul>

    <VBtn v-if="actionLabel" variant="tonal" color="error" class="mt-4" @click="$emit('action')">
      {{ actionLabel }}
    </VBtn>
  </VCard>
</template>

<script setup>
defineEmits(['action'])

defineProps({
  icon: { type: String, default: 'mdi-alert-circle-outline' },
  iconSize: { type: Number, default: 64 },
  title: { type: String, default: 'Something went wrong' },
  text: { type: String, default: '' },
  errors: { type: Array, default: () => [] },
  actionLabel: { type: String, default: 'Retry' },
  flat: { type: Boolean, default: false },
})
</script>
