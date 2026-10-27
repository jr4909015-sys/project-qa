from django.db import models
from django.conf import settings


class Laboratory(models.Model):
	name = models.CharField(max_length=160)
	building = models.CharField(max_length=100)
	room_number = models.CharField(max_length=40)
	description = models.TextField(blank=True)
	capacity = models.PositiveIntegerField(default=1)
	facilities = models.JSONField(default=list, blank=True)
	opening_time = models.TimeField(null=True, blank=True)
	closing_time = models.TimeField(null=True, blank=True)
	is_active = models.BooleanField(default=True)

	class Meta:
		ordering = ['building', 'room_number']
		unique_together = [('building', 'room_number')]

	def __str__(self):
		return f'{self.name} - {self.building} {self.room_number}'


class LaboratoryBlock(models.Model):
	laboratory = models.ForeignKey(Laboratory, on_delete=models.CASCADE, related_name='blocks')
	start_at = models.DateTimeField()
	end_at = models.DateTimeField()
	reason = models.CharField(max_length=240)
	created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)

	def __str__(self):
		return f'{self.laboratory} blocked: {self.reason}'

# Create your models here.
