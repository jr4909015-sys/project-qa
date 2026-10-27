import axios from 'axios';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://127.0.0.1:8001/api',
  headers: { 'Content-Type': 'application/json' },
  timeout: 15000,
});

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access-token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

apiClient.interceptors.response.use(undefined, async (error) => {
  const originalRequest = error.config;
  const refresh = localStorage.getItem('refresh-token');
  if (error.response?.status !== 401 || !refresh || originalRequest?._retry) {
    return Promise.reject(error);
  }

  originalRequest._retry = true;
  try {
    const { data } = await axios.post(`${apiClient.defaults.baseURL}/auth/token/refresh/`, { refresh });
    localStorage.setItem('access-token', data.access);
    originalRequest.headers.Authorization = `Bearer ${data.access}`;
    return apiClient(originalRequest);
  } catch (refreshError) {
    localStorage.removeItem('access-token');
    localStorage.removeItem('refresh-token');
    localStorage.removeItem('school-user');
    return Promise.reject(refreshError);
  }
});

export default apiClient;