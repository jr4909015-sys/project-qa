from django.conf import settings
from django.db import models


class AuditLog(models.Model):
	actor = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL)
	action = models.CharField(max_length=40)
	object_type = models.CharField(max_length=80)
	object_id = models.PositiveIntegerField(null=True, blank=True)
	summary = models.TextField()
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']

	def __str__(self):
		return f'{self.action}: {self.summary}'
