from django.db import models


class Equipment(models.Model):
	class Condition(models.TextChoices):
		GOOD = 'good', 'Good'
		FAIR = 'fair', 'Fair'
		DAMAGED = 'damaged', 'Damaged'
		MAINTENANCE = 'maintenance', 'Under maintenance'

	name = models.CharField(max_length=160)
	category = models.CharField(max_length=100)
	description = models.TextField(blank=True)
	asset_tag = models.CharField(max_length=80, unique=True)
	location = models.CharField(max_length=160, blank=True)
	quantity = models.PositiveIntegerField(default=1)
	condition = models.CharField(max_length=16, choices=Condition.choices, default=Condition.GOOD)
	image = models.ImageField(upload_to='equipment/', blank=True)
	is_active = models.BooleanField(default=True)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['name']

	def __str__(self):
		return f'{self.name} ({self.asset_tag})'


class EquipmentLoan(models.Model):
	equipment = models.ForeignKey(Equipment, on_delete=models.PROTECT, related_name='loans')
	borrower = models.ForeignKey('auth.User', on_delete=models.PROTECT, related_name='equipment_loans')
	reservation = models.OneToOneField(
		'reservations.Reservation', null=True, blank=True, on_delete=models.SET_NULL, related_name='loan'
	)
	quantity = models.PositiveIntegerField(default=1)
	checked_out_at = models.DateTimeField(auto_now_add=True)
	due_at = models.DateTimeField()
	returned_at = models.DateTimeField(null=True, blank=True)
	return_condition = models.CharField(max_length=16, choices=Equipment.Condition.choices, blank=True)
	checked_out_by = models.ForeignKey(
		'auth.User', on_delete=models.PROTECT, related_name='loans_checked_out'
	)
	returned_by = models.ForeignKey(
		'auth.User', null=True, blank=True, on_delete=models.PROTECT, related_name='loans_returned'
	)

	class Meta:
		ordering = ['-checked_out_at']

	@property
	def is_overdue(self):
		from django.utils import timezone

		return self.returned_at is None and self.due_at < timezone.now()

# Create your models here.
