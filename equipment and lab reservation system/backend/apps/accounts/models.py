from django.db import models
from django.conf import settings


class UserProfile(models.Model):
	user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='profile')
	student_employee_id = models.CharField(max_length=80, blank=True)
	department = models.CharField(max_length=120, blank=True)
	contact_number = models.CharField(max_length=40, blank=True)
	photo = models.ImageField(upload_to='profiles/', blank=True)

	def __str__(self):
		return f'Profile for {self.user}'
