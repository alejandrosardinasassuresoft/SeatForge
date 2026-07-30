<template>
  <VFooter app height="48" class="text-center text-body-3 text-medium-emphasis">
    <VContainer class="d-flex align-center justify-center ga-1">
      &copy; {{ year }} SeatForge. All rights reserved.
    </VContainer>
  </VFooter>
</template>

<script setup>
const year = new Date().getFullYear()
</script>
