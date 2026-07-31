import { ref, readonly, unref } from 'vue'

export function useAsyncState(asyncFn) {
  const data = ref(null)
  const error = ref(null)
  const loading = ref(false)
  const status = ref('idle')

  async function execute(...args) {
    loading.value = true
    status.value = 'loading'
    error.value = null

    try {
      const fn = unref(asyncFn)
      const result = await fn(...args)
      data.value = result
      status.value = 'success'
      return result
    } catch (err) {
      error.value = err
      status.value = 'error'
      throw err
    } finally {
      loading.value = false
    }
  }

  function reset() {
    data.value = null
    error.value = null
    loading.value = false
    status.value = 'idle'
  }

  return {
    data: readonly(data),
    error: readonly(error),
    loading: readonly(loading),
    status: readonly(status),
    execute,
    reset,
  }
}
