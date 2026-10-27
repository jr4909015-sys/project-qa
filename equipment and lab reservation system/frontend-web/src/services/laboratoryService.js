import apiClient from './apiClient.js';

export const laboratoryService = {
  list: (params) => apiClient.get('/laboratories/', { params }),
  get: (id) => apiClient.get(`/laboratories/${id}/`),
  create: (data) => apiClient.post('/laboratories/', data),
  update: (id, data) => apiClient.patch(`/laboratories/${id}/`, data),
  archive: (id) => apiClient.patch(`/laboratories/${id}/`, { is_active: false }),
  block: (id, data) => apiClient.post(`/laboratories/${id}/block/`, data),
  blocks: (id) => apiClient.get(`/laboratories/${id}/blocks/`),
  deleteBlock: (laboratoryId, blockId) => apiClient.delete(`/laboratories/${laboratoryId}/blocks/${blockId}/`),
  availability: (id, startAt, endAt) => apiClient.get(`/laboratories/${id}/availability/`, { params: { start_at: startAt, end_at: endAt } }),
};