import apiClient from './apiClient.js';

export const notificationService = {
  list: () => apiClient.get('/notifications/'),
  markRead: (id) => apiClient.post(`/notifications/${id}/mark_read/`),
};