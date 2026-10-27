import apiClient from './apiClient.js';

export const reservationService = {
  list: (params) => apiClient.get('/reservations/', { params }),
  get: (id) => apiClient.get(`/reservations/${id}/`),
  create: (data) => apiClient.post('/reservations/', data),
  cancel: (id) => apiClient.post(`/reservations/${id}/cancel/`),
  review: (id, decision, remarks = '') => apiClient.post(`/reservations/${id}/review/`, { decision, remarks }),
  requestReschedule: (id, start_at, end_at) => apiClient.post(`/reservations/${id}/request_reschedule/`, { start_at, end_at }),
  reviewReschedule: (id, decision, remarks = '') => apiClient.post(`/reservations/${id}/review_reschedule/`, { decision, remarks }),
  availability: (params) => apiClient.get('/reservations/availability/', { params }),
  complete: (id) => apiClient.post(`/reservations/${id}/complete/`),
};