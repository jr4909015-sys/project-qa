import apiClient from './apiClient.js';

export const userService = {
  list: (params) => apiClient.get('/users/', { params }),
  get: (id) => apiClient.get(`/users/${id}/`),
  create: (data) => apiClient.post('/users/', data),
  update: (id, data) => apiClient.patch(`/users/${id}/`, data),
  deactivate: (id) => apiClient.patch(`/users/${id}/`, { is_active: false }),
  updateProfile: (data) => apiClient.patch('/users/me/', data),
};