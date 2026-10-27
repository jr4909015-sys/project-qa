import apiClient from './apiClient.js';

export const auditService = {
  list: (params) => apiClient.get('/audit/', { params }),
};