import { useAsyncState } from './useAsyncState'

export function useApi(apiFn) {
  return useAsyncState(apiFn)
}
