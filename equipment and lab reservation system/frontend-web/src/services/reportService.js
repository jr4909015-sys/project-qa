import apiClient from './apiClient.js';

export const reportService = {
  dashboard: () => apiClient.get('/reports/summary/'),
  reservations: (params) => apiClient.get('/reports/reservations/', { params }),
  exportReservations: (params, format = 'xlsx') => apiClient.get('/reports/reservations/', { params: { ...params, export: format }, responseType: 'blob' }),
};