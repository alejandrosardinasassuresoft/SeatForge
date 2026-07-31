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
      const envelope = data?.error ?? {}
      return Promise.reject({
        status,
        code: envelope.code || 'unknown_error',
        message: envelope.message || 'Unexpected server error.',
        details: Array.isArray(envelope.details) ? envelope.details : [],
      })
    }

    if (error.request) {
      return Promise.reject({
        status: 0,
        code: 'network_error',
        message: 'Unable to reach the server. Please check your connection.',
        details: [],
      })
    }

    return Promise.reject({
      status: -1,
      code: 'request_error',
      message: error.message || 'The request could not be completed.',
      details: [],
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
