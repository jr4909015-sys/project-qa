import apiClient from './apiClient.js';

export const issueService = {
  list: () => apiClient.get('/issues/'),
  create: (details) => apiClient.post('/issues/', details, {
    headers: { 'Content-Type': 'multipart/form-data' },
  }),
  update: (id, details) => apiClient.patch(`/issues/${id}/`, details),
};
