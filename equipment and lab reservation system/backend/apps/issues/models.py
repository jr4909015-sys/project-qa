from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models


class IssueReport(models.Model):
	class Status(models.TextChoices):
		REPORTED = 'reported', 'Reported'
		IN_PROGRESS = 'in_progress', 'In progress'
		RESOLVED = 'resolved', 'Resolved'

	reporter = models.ForeignKey(
		settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='issue_reports'
	)
	equipment = models.ForeignKey(
		'equipment.Equipment', null=True, blank=True, on_delete=models.SET_NULL, related_name='issue_reports'
	)
	laboratory = models.ForeignKey(
		'laboratories.Laboratory', null=True, blank=True, on_delete=models.SET_NULL, related_name='issue_reports'
	)
	description = models.TextField()
	photo = models.ImageField(upload_to='issue-reports/', blank=True)
	status = models.CharField(max_length=16, choices=Status.choices, default=Status.REPORTED)
	resolution_note = models.TextField(blank=True)
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)

	def clean(self):
		if bool(self.equipment_id) == bool(self.laboratory_id):
			raise ValidationError('Choose exactly one equipment item or laboratory.')

	def __str__(self):
		return f'Issue #{self.pk} reported by {self.reporter}'
