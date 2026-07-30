<template>
  <div>
    <h1 class="text-h4 font-weight-bold mb-2">About</h1>
    <p class="text-body-1 text-medium-emphasis mb-4">
      SeatForge is a seat management and booking platform.
    </p>

    <VCard class="pa-6" max-width="600">
      <VCardText>
        <VList lines="two">
          <VListItem
            prepend-icon="mdi-vuejs"
            title="Frontend"
            subtitle="Vue 3 + Vuetify 3 + Pinia"
          />
          <VListItem
            prepend-icon="mdi-rails"
            title="Backend"
            subtitle="Rails 7.2 API"
          />
          <VListItem
            prepend-icon="mdi-database"
            title="Database"
            subtitle="PostgreSQL"
          />
        </VList>
      </VCardText>
    </VCard>
  </div>
</template>

<script setup>
</script>
