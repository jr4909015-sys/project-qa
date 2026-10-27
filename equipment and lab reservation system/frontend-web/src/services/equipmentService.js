import apiClient from './apiClient.js';

export const equipmentService = {
  list: (params) => apiClient.get('/equipment/', { params }),
  get: (id) => apiClient.get(`/equipment/${id}/`),
  create: (data) => apiClient.post('/equipment/', data, data instanceof FormData ? { headers: { 'Content-Type': 'multipart/form-data' } } : undefined),
  update: (id, data) => apiClient.patch(`/equipment/${id}/`, data, data instanceof FormData ? { headers: { 'Content-Type': 'multipart/form-data' } } : undefined),
  archive: (id) => apiClient.patch(`/equipment/${id}/`, { is_active: false }),
  loans: (params) => apiClient.get('/loans/', { params }),
  checkOut: (data) => apiClient.post('/loans/', data),
  returnItem: (id, returnCondition) => apiClient.post(`/loans/${id}/return_item/`, { return_condition: returnCondition }),
};