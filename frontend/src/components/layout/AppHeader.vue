<template>
  <VAppBar elevation="2" class="app-header">
    <VAppBarNavIcon @click="$emit('toggle-drawer')" />

    <VAppBarTitle class="text-h6 font-weight-bold">
      <VIcon start color="primary">mdi-anvil</VIcon>
      SeatForge
    </VAppBarTitle>

    <VSpacer />

    <VBtn icon variant="text">
      <VIcon>mdi-bell-outline</VIcon>
    </VBtn>

    <VBtn icon variant="text">
      <VIcon>mdi-account-circle-outline</VIcon>
    </VBtn>
  </VAppBar>
</template>

<script setup>
defineEmits(['toggle-drawer'])
</script>

<style scoped>
.app-header {
  z-index: 100;
}
</style>
