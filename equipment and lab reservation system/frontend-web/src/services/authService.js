import apiClient from './apiClient.js';

export const authService = {
  async login(credentials) {
    const { data } = await apiClient.post('/auth/token/', credentials);
    localStorage.setItem('access-token', data.access);
    localStorage.setItem('refresh-token', data.refresh);
    return data;
  },
  async register(details) {
    const { data } = await apiClient.post('/auth/register/', details);
    return data;
  },
  async currentUser() {
    const { data } = await apiClient.get('/auth/me/');
    return data;
  },
  async updateProfile(details) {
    const config = details instanceof FormData
      ? { headers: { 'Content-Type': 'multipart/form-data' } }
      : undefined;
    const { data } = await apiClient.patch('/auth/me/', details, config);
    return data;
  },
  changePassword(details) {
    return apiClient.post('/auth/password/change/', details);
  },
  requestPasswordReset: (email) => apiClient.post('/auth/password/reset/', { email }),
  resetPassword: (details) => apiClient.post('/auth/password/reset/confirm/', details),
  logout() {
    localStorage.removeItem('access-token');
    localStorage.removeItem('refresh-token');
  },
};