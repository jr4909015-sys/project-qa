from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.equipment.models import EquipmentLoan
from apps.notifications.models import Notification
from apps.notifications.services import notify_user
from apps.reservations.models import Reservation


class Command(BaseCommand):
    help = 'Create in-app reminders for reservations and equipment due soon.'

    def handle(self, *args, **options):
        now = timezone.now()
        reminder_cutoff = now + timedelta(hours=24)
        created = 0

        reservations = Reservation.objects.filter(
            status=Reservation.Status.APPROVED,
            start_at__gt=now,
            start_at__lte=reminder_cutoff,
        ).select_related('requester', 'equipment', 'laboratory')
        for reservation in reservations:
            if Notification.objects.filter(
                recipient=reservation.requester,
                reservation=reservation,
                title='Upcoming reservation reminder',
            ).exists():
                continue
            resource = reservation.equipment or reservation.laboratory
            notify_user(
                recipient=reservation.requester,
                reservation=reservation,
                title='Upcoming reservation reminder',
                message=f'{resource} is reserved for {timezone.localtime(reservation.start_at):%b %d at %I:%M %p}.',
            )
            created += 1

        pickup_cutoff = now + timedelta(hours=1)
        pickup_reservations = Reservation.objects.filter(
            status=Reservation.Status.APPROVED,
            start_at__gt=now,
            start_at__lte=pickup_cutoff,
        ).select_related('requester', 'equipment', 'laboratory')
        for reservation in pickup_reservations:
            title = 'Reservation pickup reminder'
            if Notification.objects.filter(
                recipient=reservation.requester,
                reservation=reservation,
                title=title,
            ).exists():
                continue
            resource = reservation.equipment or reservation.laboratory
            notify_user(
                recipient=reservation.requester,
                reservation=reservation,
                title=title,
                message=f'Your reservation for {resource} starts at {timezone.localtime(reservation.start_at):%b %d at %I:%M %p}.',
            )
            created += 1

        loans = EquipmentLoan.objects.filter(
            returned_at__isnull=True,
            due_at__gt=now,
            due_at__lte=reminder_cutoff,
        ).select_related('borrower', 'equipment')
        for loan in loans:
            title = 'Equipment return due soon'
            message = (
                f'Loan #{loan.pk}: return {loan.quantity} × {loan.equipment.name} '
                f'by {timezone.localtime(loan.due_at):%b %d at %I:%M %p}.'
            )
            if Notification.objects.filter(
                recipient=loan.borrower,
                title=title,
                message=message,
            ).exists():
                continue
            notify_user(
                recipient=loan.borrower,
                reservation=loan.reservation,
                title=title,
                message=message,
            )
            created += 1

        overdue_loans = EquipmentLoan.objects.filter(
            returned_at__isnull=True,
            due_at__lte=now,
        ).select_related('borrower', 'equipment')
        for loan in overdue_loans:
            title = 'Equipment return overdue'
            message = (
                f'Loan #{loan.pk}: return {loan.quantity} × {loan.equipment.name}. '
                f'The due date was {timezone.localtime(loan.due_at):%b %d at %I:%M %p}.'
            )
            if Notification.objects.filter(
                recipient=loan.borrower,
                title=title,
                message=message,
                created_at__gte=now - timedelta(days=1),
            ).exists():
                continue
            notify_user(
                recipient=loan.borrower,
                reservation=loan.reservation,
                title=title,
                message=message,
            )
            created += 1

        self.stdout.write(self.style.SUCCESS(f'Created {created} in-app reminder(s).'))
