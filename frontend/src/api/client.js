import axios from 'axios'

const client = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
  timeout: 15000,
})

client.interceptors.request.use(
  (config) => {
    return config
  },
  (error) => Promise.reject(error),
)

client.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response) {
      const { status, data } = error.response
      return Promise.reject({
        status,
        errors: data?.errors ?? [{ title: 'Server Error', detail: error.message }],
        data: data?.data ?? null,
        meta: data?.meta ?? {},
      })
    }

    if (error.request) {
      return Promise.reject({
        status: 0,
        errors: [{ title: 'Network Error', detail: 'Unable to reach the server. Please check your connection.' }],
        data: null,
        meta: {},
      })
    }

    return Promise.reject({
      status: -1,
      errors: [{ title: 'Request Error', detail: error.message }],
      data: null,
      meta: {},
    })
  },
)

function get(path, config = {}) {
  return client.get(path, config)
}

function post(path, data, config) {
  return client.post(path, data, config)
}

function put(path, data, config) {
  return client.put(path, data, config)
}

function patch(path, data, config) {
  return client.patch(path, data, config)
}

function del(path, config) {
  return client.delete(path, config)
}

export { get, post, put, patch, del }
export default client
