from django.db.models import Sum

from apps.equipment.models import EquipmentLoan
from apps.laboratories.models import LaboratoryBlock
from .models import Reservation


def reservation_availability_error(*, equipment, laboratory, start_at, end_at, quantity, attendees, exclude_id=None):
    reservations = Reservation.objects.filter(
        status__in=[Reservation.Status.PENDING, Reservation.Status.APPROVED],
        start_at__lt=end_at,
        end_at__gt=start_at,
    )
    if exclude_id:
        reservations = reservations.exclude(pk=exclude_id)

    if equipment:
        reserved = reservations.filter(equipment=equipment).aggregate(total=Sum('quantity'))['total'] or 0
        loaned = EquipmentLoan.objects.filter(
            equipment=equipment, returned_at__isnull=True, due_at__gt=start_at
        ).aggregate(total=Sum('quantity'))['total'] or 0
        if reserved + loaned + quantity > equipment.quantity:
            return 'The requested equipment quantity is not available for this time.'
        if equipment.condition in [equipment.Condition.DAMAGED, equipment.Condition.MAINTENANCE]:
            return 'This equipment is not currently available for reservation.'

    if laboratory:
        if attendees > laboratory.capacity:
            return 'Attendee count exceeds the laboratory capacity.'
        if reservations.filter(laboratory=laboratory).exists():
            return 'The laboratory is already reserved for this time.'
        if LaboratoryBlock.objects.filter(
            laboratory=laboratory, start_at__lt=end_at, end_at__gt=start_at
        ).exists():
            return 'The laboratory is blocked for this time.'
        if laboratory.opening_time and laboratory.closing_time:
            if start_at.date() != end_at.date() or start_at.time() < laboratory.opening_time or end_at.time() > laboratory.closing_time:
                return 'The requested time is outside laboratory operating hours.'

    return None