from django.test import TestCase
from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.utils import timezone
from datetime import timedelta

from apps.equipment.models import Equipment, EquipmentLoan
from apps.notifications.models import Notification
from apps.reservations.models import Reservation


class ReminderCommandTests(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='reminder-user',
            email='reminder@example.com',
            password='Reminder!2026Strong',
        )
        self.equipment = Equipment.objects.create(
            name='Student laptop',
            category='Computing',
            asset_tag='LAP-REM-01',
            quantity=3,
        )
        now = timezone.now()
        Reservation.objects.create(
            requester=self.user,
            equipment=self.equipment,
            start_at=now + timedelta(hours=2),
            end_at=now + timedelta(hours=3),
            purpose='Reminder test',
            status=Reservation.Status.APPROVED,
        )
        EquipmentLoan.objects.create(
            equipment=self.equipment,
            borrower=self.user,
            quantity=1,
            due_at=now + timedelta(hours=4),
            checked_out_by=self.user,
        )

    def test_reminder_command_creates_idempotent_in_app_reminders(self):
        call_command('send_reservation_reminders')
        self.assertEqual(Notification.objects.count(), 2)

        call_command('send_reservation_reminders')
        self.assertEqual(Notification.objects.count(), 2)
        self.assertSetEqual(
            set(Notification.objects.values_list('title', flat=True)),
            {'Upcoming reservation reminder', 'Equipment return due soon'},
        )

    def test_overdue_loan_reminder_is_limited_to_once_per_day(self):
        loan = EquipmentLoan.objects.get(borrower=self.user)
        loan.due_at = timezone.now() - timedelta(days=1)
        loan.save(update_fields=['due_at'])

        call_command('send_reservation_reminders')
        overdue = Notification.objects.filter(title='Equipment return overdue')
        self.assertEqual(overdue.count(), 1)

        call_command('send_reservation_reminders')
        self.assertEqual(overdue.count(), 1)
