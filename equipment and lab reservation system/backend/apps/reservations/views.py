from django.db import transaction
from django.utils import timezone
from datetime import datetime, time, timedelta
from django.contrib.auth import get_user_model
from rest_framework import serializers, status
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from django.utils.dateparse import parse_date, parse_datetime
from apps.equipment.models import Equipment, EquipmentLoan
from apps.laboratories.models import Laboratory, LaboratoryBlock
from .availability import reservation_availability_error
from apps.audit.services import record_audit
from apps.notifications.services import notify_user
from .models import Reservation
from .serializers import ReservationSerializer

User = get_user_model()


class ReservationViewSet(ModelViewSet):
	serializer_class = ReservationSerializer
	permission_classes = [IsAuthenticated]
	http_method_names = ['get', 'post', 'head', 'options']

	def get_queryset(self):
		if self.request.user.is_staff:
			return Reservation.objects.select_related(
				'requester', 'equipment', 'laboratory', 'reviewed_by', 'reschedule_reviewed_by'
			)
		return Reservation.objects.filter(requester=self.request.user).select_related(
			'equipment', 'laboratory', 'reviewed_by', 'reschedule_reviewed_by'
		)

	@action(detail=False, methods=['get'])
	def availability(self, request):
		resource_type = request.query_params.get('resource_type')
		resource_id = request.query_params.get('resource_id')
		selected_date = parse_date(request.query_params.get('date', ''))
		requested_quantity = request.query_params.get('quantity', '1')
		try:
			requested_quantity = int(requested_quantity)
		except (TypeError, ValueError):
			requested_quantity = 0
		try:
			utc_offset_minutes = int(request.query_params.get('utc_offset_minutes', '0'))
		except (TypeError, ValueError):
			raise ValidationError({'utc_offset_minutes': 'The UTC offset must be an integer.'})
		if (
			resource_type not in {'equipment', 'laboratory'}
			or not resource_id
			or not selected_date
			or requested_quantity < 1
			or not -840 <= utc_offset_minutes <= 840
		):
			raise ValidationError({
				'detail': 'resource_type, resource_id, date (YYYY-MM-DD), a valid UTC offset, and a positive quantity are required.'
			})
		resource_model = Equipment if resource_type == 'equipment' else Laboratory
		resource = resource_model.objects.filter(is_active=True).filter(pk=resource_id).first()
		if resource is None:
			raise ValidationError({'resource_id': 'The selected resource is not available.'})

		tz = timezone.get_fixed_timezone(utc_offset_minutes)
		day_start = timezone.make_aware(datetime.combine(selected_date, time.min), tz)
		day_end = day_start + timedelta(days=1)
		if resource_type == 'laboratory':
			start_time = resource.opening_time or time(8, 0)
			end_time = resource.closing_time or time(17, 0)
		else:
			start_time, end_time = time(8, 0), time(17, 0)

		busy = []
		reservations = Reservation.objects.filter(
			**{resource_type: resource},
			status__in=[Reservation.Status.PENDING, Reservation.Status.APPROVED],
			start_at__lt=day_end,
			end_at__gt=day_start,
		).order_by('start_at')
		for reservation in reservations:
			busy.append({
				'start_at': reservation.start_at,
				'end_at': reservation.end_at,
				'status': 'booked',
				'detail': f'{reservation.get_status_display()} reservation',
				'quantity': reservation.quantity,
			})

		if resource_type == 'laboratory':
			blocks = LaboratoryBlock.objects.filter(
				laboratory=resource, start_at__lt=day_end, end_at__gt=day_start
			)
			for block in blocks:
				busy.append({
					'start_at': block.start_at,
					'end_at': block.end_at,
					'status': 'unavailable',
					'detail': block.reason,
					'quantity': 0,
				})
		else:
			loans = EquipmentLoan.objects.filter(
				equipment=resource,
				returned_at__isnull=True,
				checked_out_at__lt=day_end,
				due_at__gt=day_start,
			)
			for loan in loans:
				busy.append({
					'start_at': loan.checked_out_at,
					'end_at': loan.due_at,
					'status': 'booked',
					'detail': 'Equipment checked out',
					'quantity': loan.quantity,
				})

		slots = []
		cursor = timezone.make_aware(datetime.combine(selected_date, start_time), tz)
		close_at = timezone.make_aware(datetime.combine(selected_date, end_time), tz)
		if close_at <= cursor:
			raise ValidationError({'detail': 'The resource operating hours are invalid.'})
		slot_length = timedelta(minutes=30)
		resource_unavailable = resource_type == 'equipment' and resource.condition in [
			Equipment.Condition.DAMAGED,
			Equipment.Condition.MAINTENANCE,
		]
		while cursor + slot_length <= close_at:
			slot_end = cursor + slot_length
			overlapping = [
				item for item in busy
				if item['start_at'] < slot_end and item['end_at'] > cursor
			]
			if resource_type == 'equipment':
				occupied = sum(item['quantity'] for item in overlapping)
				is_available = (
					not resource_unavailable
					and resource.quantity - occupied >= requested_quantity
				)
				available_quantity = max(resource.quantity - occupied, 0)
			else:
				occupied = 0
				is_available = not overlapping
				available_quantity = None
			slot_unavailable = resource_unavailable or any(
				item['status'] == 'unavailable' for item in overlapping
			)
			if is_available:
				slot_status = 'available'
			elif slot_unavailable or (
				resource_type == 'equipment' and resource.quantity - occupied <= 0
			):
				slot_status = 'unavailable'
			else:
				slot_status = 'booked'
			slots.append({
				'start_at': cursor,
				'end_at': slot_end,
				'status': slot_status,
				'available_quantity': available_quantity,
				'detail': next(
					(item['detail'] for item in overlapping if item['status'] == 'unavailable'),
					'Equipment is damaged or under maintenance'
					if resource_unavailable
					else 'Conflicting booking' if overlapping else '',
				),
			})
			cursor = slot_end
		return Response({
			'resource_type': resource_type,
			'resource_id': resource.pk,
			'date': selected_date,
			'operating_start': start_time,
			'operating_end': end_time,
			'slots': slots,
		})

	@transaction.atomic
	def perform_create(self, serializer):
		equipment = serializer.validated_data.get('equipment')
		laboratory = serializer.validated_data.get('laboratory')
		if equipment:
			equipment = type(equipment).objects.select_for_update().get(pk=equipment.pk)
		if laboratory:
			laboratory = type(laboratory).objects.select_for_update().get(pk=laboratory.pk)
		error = reservation_availability_error(
			equipment=equipment,
			laboratory=laboratory,
			start_at=serializer.validated_data['start_at'],
			end_at=serializer.validated_data['end_at'],
			quantity=serializer.validated_data.get('quantity', 1),
			attendees=serializer.validated_data.get('attendees', 1),
		)
		if error:
			raise ValidationError({'availability': error})
		reservation = serializer.save(requester=self.request.user)
		notify_user(
			recipient=self.request.user,
			reservation=reservation,
			title='Reservation request submitted',
			message=f'Your reservation request #{reservation.pk} has been submitted for review.',
		)
		record_audit(actor=self.request.user, action='requested', instance=reservation, summary='Submitted a reservation request.')

	@action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
	def review(self, request, pk=None):
		decision = request.data.get('decision')
		if decision not in [Reservation.Status.APPROVED, Reservation.Status.DECLINED]:
			raise ValidationError({'decision': 'Choose approved or declined.'})
		with transaction.atomic():
			reservation = self.get_object()
			if reservation.status != Reservation.Status.PENDING:
				raise ValidationError({'status': 'Only pending requests can be reviewed.'})
			if reservation.equipment_id:
				reservation.equipment = type(reservation.equipment).objects.select_for_update().get(pk=reservation.equipment_id)
			if reservation.laboratory_id:
				reservation.laboratory = type(reservation.laboratory).objects.select_for_update().get(pk=reservation.laboratory_id)
			if decision == Reservation.Status.APPROVED:
				error = reservation_availability_error(
					equipment=reservation.equipment,
					laboratory=reservation.laboratory,
					start_at=reservation.start_at,
					end_at=reservation.end_at,
					quantity=reservation.quantity,
					attendees=reservation.attendees,
					exclude_id=reservation.pk,
				)
				if error:
					raise ValidationError({'availability': error})
			reservation.status = decision
			reservation.remarks = request.data.get('remarks', '').strip()
			reservation.reviewed_by = request.user
			reservation.reviewed_at = timezone.now()
			reservation.save(update_fields=['status', 'remarks', 'reviewed_by', 'reviewed_at'])
			notify_user(
				recipient=reservation.requester,
				reservation=reservation,
				title=f'Reservation {decision}',
				message=reservation.remarks or f'Your reservation request was {decision}.',
			)
			record_audit(actor=request.user, action=decision, instance=reservation, summary=reservation.remarks or f'Reservation {decision}.')
		return Response(self.get_serializer(reservation).data)

	@action(detail=True, methods=['post'])
	def cancel(self, request, pk=None):
		reservation = self.get_object()
		if reservation.requester_id != request.user.id and not request.user.is_staff:
			raise ValidationError({'detail': 'You cannot cancel this reservation.'})
		if reservation.status not in [Reservation.Status.PENDING, Reservation.Status.APPROVED]:
			raise ValidationError({'status': 'This reservation can no longer be cancelled.'})
		reservation.status = Reservation.Status.CANCELLED
		reservation.cancelled_at = timezone.now()
		reservation.save(update_fields=['status', 'cancelled_at'])
		if reservation.requester_id == request.user.id:
			for recipient in User.objects.filter(is_staff=True, is_active=True):
				notify_user(
					recipient=recipient,
					reservation=reservation,
					title='Reservation cancelled',
					message=f'{request.user.username} cancelled reservation #{reservation.pk}.',
				)
		record_audit(actor=request.user, action='cancelled', instance=reservation, summary='Cancelled a reservation.')
		return Response(self.get_serializer(reservation).data)

	@action(detail=True, methods=['post'])
	def request_reschedule(self, request, pk=None):
		reservation = self.get_object()
		if reservation.requester_id != request.user.id:
			raise ValidationError({'detail': 'You can only reschedule your own reservation.'})
		if reservation.status not in [Reservation.Status.PENDING, Reservation.Status.APPROVED]:
			raise ValidationError({'status': 'Only pending or approved reservations can be rescheduled.'})
		if reservation.reschedule_status == 'pending':
			raise ValidationError({'reschedule': 'A schedule change is already awaiting review.'})
		start_at = parse_datetime(request.data.get('start_at', ''))
		end_at = parse_datetime(request.data.get('end_at', ''))
		if not start_at or not end_at or end_at <= start_at:
			raise ValidationError({'end_at': 'A valid start and end time are required.'})
		if timezone.is_naive(start_at) or timezone.is_naive(end_at):
			raise ValidationError({'detail': 'Schedule change times must include a timezone.'})
		error = reservation_availability_error(
			equipment=reservation.equipment,
			laboratory=reservation.laboratory,
			start_at=start_at,
			end_at=end_at,
			quantity=reservation.quantity,
			attendees=reservation.attendees,
			exclude_id=reservation.pk,
		)
		if error:
			raise ValidationError({'availability': error})
		reservation.proposed_start_at = start_at
		reservation.proposed_end_at = end_at
		reservation.reschedule_status = 'pending'
		reservation.reschedule_remarks = ''
		reservation.reschedule_requested_at = timezone.now()
		reservation.save(update_fields=[
			'proposed_start_at', 'proposed_end_at', 'reschedule_status',
			'reschedule_remarks', 'reschedule_requested_at',
		])
		for recipient in User.objects.filter(is_staff=True, is_active=True):
			notify_user(
				recipient=recipient,
				reservation=reservation,
				title='Reservation schedule change requested',
				message=f'{request.user.username} requested a new time for reservation #{reservation.pk}.',
			)
		record_audit(actor=request.user, action='reschedule_requested', instance=reservation, summary='Requested a reservation schedule change.')
		return Response(self.get_serializer(reservation).data, status=status.HTTP_200_OK)

	@action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
	def review_reschedule(self, request, pk=None):
		decision = request.data.get('decision')
		if decision not in {'approved', 'declined'}:
			raise ValidationError({'decision': 'Choose approved or declined.'})
		with transaction.atomic():
			reservation = self.get_object()
			if reservation.reschedule_status != 'pending':
				raise ValidationError({'reschedule_status': 'No schedule change is awaiting review.'})
			if decision == 'approved':
				if reservation.equipment_id:
					reservation.equipment = type(reservation.equipment).objects.select_for_update().get(
						pk=reservation.equipment_id
					)
				if reservation.laboratory_id:
					reservation.laboratory = type(reservation.laboratory).objects.select_for_update().get(
						pk=reservation.laboratory_id
					)
				error = reservation_availability_error(
					equipment=reservation.equipment,
					laboratory=reservation.laboratory,
					start_at=reservation.proposed_start_at,
					end_at=reservation.proposed_end_at,
					quantity=reservation.quantity,
					attendees=reservation.attendees,
					exclude_id=reservation.pk,
				)
				if error:
					raise ValidationError({'availability': error})
				reservation.start_at = reservation.proposed_start_at
				reservation.end_at = reservation.proposed_end_at
			reservation.reschedule_status = decision
			reservation.reschedule_remarks = request.data.get('remarks', '').strip()
			reservation.reschedule_reviewed_by = request.user
			reservation.reschedule_reviewed_at = timezone.now()
			reservation.save(update_fields=[
				'start_at', 'end_at', 'reschedule_status', 'reschedule_remarks',
				'reschedule_reviewed_by', 'reschedule_reviewed_at',
			])
			notify_user(
				recipient=reservation.requester,
				reservation=reservation,
				title=f'Reservation schedule change {decision}',
				message=reservation.reschedule_remarks or f'Your requested schedule change was {decision}.',
			)
			record_audit(actor=request.user, action=f'reschedule_{decision}', instance=reservation, summary=reservation.reschedule_remarks or f'Schedule change {decision}.')
		return Response(self.get_serializer(reservation).data)

	@action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
	def complete(self, request, pk=None):
		reservation = self.get_object()
		if reservation.status != Reservation.Status.APPROVED:
			raise ValidationError({'status': 'Only approved reservations can be completed.'})
		reservation.status = Reservation.Status.COMPLETED
		reservation.completed_at = timezone.now()
		reservation.save(update_fields=['status', 'completed_at'])
		notify_user(
			recipient=reservation.requester,
			reservation=reservation,
			title='Reservation completed',
			message=f'Your reservation #{reservation.pk} has been marked completed.',
		)
		record_audit(actor=request.user, action='completed', instance=reservation, summary='Completed a reservation.')
		return Response(self.get_serializer(reservation).data)

# Create your views here.
