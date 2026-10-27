from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models import Q

from apps.equipment.models import Equipment
from apps.laboratories.models import Laboratory


class Reservation(models.Model):
	class Status(models.TextChoices):
		PENDING = 'pending', 'Pending'
		APPROVED = 'approved', 'Approved'
		DECLINED = 'declined', 'Rejected'
		CANCELLED = 'cancelled', 'Cancelled'
		COMPLETED = 'completed', 'Completed'

	requester = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reservations')
	equipment = models.ForeignKey(Equipment, null=True, blank=True, on_delete=models.PROTECT, related_name='reservations')
	laboratory = models.ForeignKey(Laboratory, null=True, blank=True, on_delete=models.PROTECT, related_name='reservations')
	start_at = models.DateTimeField()
	end_at = models.DateTimeField()
	purpose = models.TextField()
	quantity = models.PositiveIntegerField(default=1)
	attendees = models.PositiveIntegerField(default=1)
	status = models.CharField(max_length=12, choices=Status.choices, default=Status.PENDING)
	remarks = models.TextField(blank=True)
	reviewed_by = models.ForeignKey(
		settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name='reviewed_reservations'
	)
	reviewed_at = models.DateTimeField(null=True, blank=True)
	cancelled_at = models.DateTimeField(null=True, blank=True)
	completed_at = models.DateTimeField(null=True, blank=True)
	proposed_start_at = models.DateTimeField(null=True, blank=True)
	proposed_end_at = models.DateTimeField(null=True, blank=True)
	reschedule_status = models.CharField(max_length=12, blank=True)
	reschedule_remarks = models.TextField(blank=True)
	reschedule_requested_at = models.DateTimeField(null=True, blank=True)
	reschedule_reviewed_by = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		null=True,
		blank=True,
		on_delete=models.SET_NULL,
		related_name='reviewed_reschedule_requests',
	)
	reschedule_reviewed_at = models.DateTimeField(null=True, blank=True)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-created_at']
		constraints = [models.CheckConstraint(condition=(Q(equipment__isnull=False, laboratory__isnull=True) | Q(equipment__isnull=True, laboratory__isnull=False)), name='reservation_exactly_one_resource')]

	def clean(self):
		if self.end_at <= self.start_at:
			raise ValidationError({'end_at': 'End time must be after start time.'})
		if self.quantity < 1 or self.attendees < 1:
			raise ValidationError('Quantity and attendee count must be at least one.')

	def __str__(self):
		resource = self.equipment or self.laboratory
		return f'{resource} - {self.get_status_display()}'

# Create your models here.
