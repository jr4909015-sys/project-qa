from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.equipment.models import Equipment
from apps.laboratories.models import Laboratory, LaboratoryBlock
from .models import Reservation


class SharedReservationApiTests(TestCase):
    def setUp(self):
        users = get_user_model()
        self.user = users.objects.create_user(
            username='reservation-user',
            email='reservation-user@example.com',
            password='User!2026Strong',
        )
        self.admin = users.objects.create_superuser(
            username='reservation-admin',
            email='reservation-admin@example.com',
            password='Admin!2026Strong',
        )
        self.equipment = Equipment.objects.create(
            name='Availability camera',
            category='Media',
            asset_tag='AVAIL-001',
            quantity=2,
        )
        self.laboratory = Laboratory.objects.create(
            name='Availability lab',
            building='Science',
            room_number='A-12',
            capacity=20,
        )
        self.start = timezone.localtime(timezone.now() + timedelta(days=3)).replace(
            hour=10, minute=0, second=0, microsecond=0
        )
        self.end = self.start + timedelta(hours=1)
        self.reservation = Reservation.objects.create(
            requester=self.user,
            equipment=self.equipment,
            start_at=self.start,
            end_at=self.end,
            purpose='Camera research',
            status=Reservation.Status.PENDING,
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_availability_lists_booked_slots_and_open_times(self):
        response = self.client.get(
            '/api/reservations/availability/',
            {
                'resource_type': 'equipment',
                'resource_id': self.equipment.pk,
                'date': self.start.date().isoformat(),
                'quantity': 2,
            },
        )

        self.assertEqual(response.status_code, 200, response.data)
        slots = response.data['slots']
        booked_slot = next(
            slot for slot in slots
            if timezone.localtime(slot['start_at']).hour == self.start.hour
        )
        self.assertEqual(booked_slot['status'], 'booked')
        self.assertTrue(any(slot['status'] == 'available' for slot in slots))

    def test_availability_slots_use_the_requested_local_utc_offset(self):
        response = self.client.get(
            '/api/reservations/availability/',
            {
                'resource_type': 'laboratory',
                'resource_id': self.laboratory.pk,
                'date': self.start.date().isoformat(),
                'utc_offset_minutes': 330,
            },
        )

        self.assertEqual(response.status_code, 200, response.data)
        first_slot = response.data['slots'][0]['start_at']
        local_slot = timezone.localtime(first_slot, timezone.get_fixed_timezone(330))
        self.assertEqual((local_slot.hour, local_slot.minute), (8, 0))

    def test_availability_marks_maintenance_and_lab_blocks_unavailable(self):
        self.equipment.condition = Equipment.Condition.MAINTENANCE
        self.equipment.save(update_fields=['condition'])
        equipment_response = self.client.get(
            '/api/reservations/availability/',
            {
                'resource_type': 'equipment',
                'resource_id': self.equipment.pk,
                'date': self.start.date().isoformat(),
            },
        )
        self.assertEqual(equipment_response.status_code, 200)
        equipment_slot = next(
            slot for slot in equipment_response.data['slots']
            if timezone.localtime(slot['start_at']).hour == 8
        )
        self.assertEqual(equipment_slot['status'], 'unavailable')

        LaboratoryBlock.objects.create(
            laboratory=self.laboratory,
            start_at=self.start.replace(hour=8),
            end_at=self.start.replace(hour=9),
            reason='School event',
            created_by=self.admin,
        )
        lab_response = self.client.get(
            '/api/reservations/availability/',
            {
                'resource_type': 'laboratory',
                'resource_id': self.laboratory.pk,
                'date': self.start.date().isoformat(),
            },
        )
        self.assertEqual(lab_response.status_code, 200)
        lab_slot = next(
            slot for slot in lab_response.data['slots']
            if timezone.localtime(slot['start_at']).hour == 8
        )
        self.assertEqual(lab_slot['status'], 'unavailable')
        self.assertEqual(lab_slot['detail'], 'School event')

    def test_reservations_cannot_be_directly_edited_to_bypass_rescheduling(self):
        response = self.client.patch(
            f'/api/reservations/{self.reservation.pk}/',
            {'start_at': (self.start + timedelta(days=1)).isoformat()},
            format='json',
        )

        self.assertEqual(response.status_code, 405)

    def test_reschedule_requires_staff_approval_and_notifies_requester(self):
        proposed_start = self.start + timedelta(days=1)
        proposed_end = self.end + timedelta(days=1)
        response = self.client.post(
            f'/api/reservations/{self.reservation.pk}/request_reschedule/',
            {'start_at': proposed_start.isoformat(), 'end_at': proposed_end.isoformat()},
            format='json',
        )

        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data['reschedule_status'], 'pending')
        self.assertEqual(
            timezone.localtime(Reservation.objects.get(pk=self.reservation.pk).start_at),
            self.start,
        )

        self.client.force_authenticate(self.admin)
        reviewed = self.client.post(
            f'/api/reservations/{self.reservation.pk}/review_reschedule/',
            {'decision': 'approved', 'remarks': 'New time approved.'},
            format='json',
        )
        self.assertEqual(reviewed.status_code, 200, reviewed.data)
        reservation = Reservation.objects.get(pk=self.reservation.pk)
        self.assertEqual(reservation.reschedule_status, 'approved')
        self.assertEqual(timezone.localtime(reservation.start_at), proposed_start)
        self.assertTrue(reservation.notifications.filter(recipient=self.user).exists())

    def test_staff_can_reject_reschedule_without_changing_original_time(self):
        proposed_start = self.start + timedelta(days=1)
        proposed_end = self.end + timedelta(days=1)
        self.client.post(
            f'/api/reservations/{self.reservation.pk}/request_reschedule/',
            {'start_at': proposed_start.isoformat(), 'end_at': proposed_end.isoformat()},
            format='json',
        )
        self.client.force_authenticate(self.admin)
        response = self.client.post(
            f'/api/reservations/{self.reservation.pk}/review_reschedule/',
            {'decision': 'declined', 'remarks': 'Room unavailable.'},
            format='json',
        )

        self.assertEqual(response.status_code, 200, response.data)
        reservation = Reservation.objects.get(pk=self.reservation.pk)
        self.assertEqual(reservation.reschedule_status, 'declined')
        self.assertEqual(timezone.localtime(reservation.start_at), self.start)
        self.assertEqual(reservation.reschedule_remarks, 'Room unavailable.')
