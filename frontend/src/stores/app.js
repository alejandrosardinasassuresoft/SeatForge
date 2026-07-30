import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAppStore = defineStore('app', () => {
  const globalLoading = ref(false)
  const snackbar = ref({ show: false, message: '', color: 'info' })

  const isLoading = computed(() => globalLoading.value)

  function setLoading(val) {
    globalLoading.value = val
  }

  function notify(message, color = 'info') {
    snackbar.value = { show: true, message, color }
  }

  function clearNotification() {
    snackbar.value = { show: false, message: '', color: 'info' }
  }

  return {
    globalLoading,
    snackbar,
    isLoading,
    setLoading,
    notify,
    clearNotification,
  }
})
