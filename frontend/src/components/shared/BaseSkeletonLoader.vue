<template>
  <VCard :flat="flat" :class="cls">
    <VCardText v-if="type === 'card'" class="d-flex flex-column ga-3">
      <VSkeletonLoader type="subtitle" />
      <VSkeletonLoader v-for="i in lines" :key="i" type="text" />
    </VCardText>

    <VCardText v-else-if="type === 'table'" class="d-flex flex-column ga-2">
      <VSkeletonLoader type="table-heading" />
      <VSkeletonLoader v-for="i in rows" :key="i" type="table-row" />
    </VCardText>

    <VCardText v-else-if="type === 'avatar'" class="d-flex align-center ga-4">
      <VSkeletonLoader type="avatar" />
      <div class="flex-grow-1 d-flex flex-column ga-2">
        <VSkeletonLoader v-for="i in lines" :key="i" type="text" />
      </div>
    </VCardText>

    <VCardText v-else class="d-flex flex-column ga-3">
      <VSkeletonLoader v-for="i in lines" :key="i" type="text" />
    </VCardText>
  </VCard>
</template>

<script setup>
defineProps({
  type: { type: String, default: 'card' },
  lines: { type: Number, default: 3 },
  rows: { type: Number, default: 5 },
  flat: { type: Boolean, default: false },
  cls: { type: String, default: '' },
})
</script>
