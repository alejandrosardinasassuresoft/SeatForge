<template>
  <VCard class="d-flex align-center justify-center pa-8" :class="{ 'base-loading--overlay': overlay }" :flat="flat">
    <VProgressCircular :size="size" :width="width" color="primary" indeterminate />
    <span v-if="text" class="text-body-2 text-medium-emphasis ml-4">{{ text }}</span>
  </VCard>
</template>

<script setup>
defineProps({
  text: { type: String, default: 'Loading...' },
  size: { type: Number, default: 40 },
  width: { type: Number, default: 4 },
  flat: { type: Boolean, default: false },
  overlay: { type: Boolean, default: false },
})
</script>

<style scoped>
.base-loading--overlay {
  position: absolute;
  inset: 0;
  background: rgba(255, 255, 255, 0.8);
  z-index: 100;
}
</style>
