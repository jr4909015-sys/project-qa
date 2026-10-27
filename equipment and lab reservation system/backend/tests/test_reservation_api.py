from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.equipment.models import Equipment
from apps.laboratories.models import Laboratory
from apps.reservations.models import Reservation


class ReservationApiTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(username='student', password='test-password')
        self.other_user = get_user_model().objects.create_user(username='other', password='test-password')
        self.equipment = Equipment.objects.create(name='Camera', category='Media', asset_tag='CAM-001')
        now = timezone.now()
        self.existing_reservation = Reservation.objects.create(
            requester=self.other_user,
            equipment=self.equipment,
            start_at=now + timedelta(days=1),
            end_at=now + timedelta(days=1, hours=1),
            purpose='Project work',
        )

    def test_catalogue_is_public(self):
        response = self.client.get('/api/equipment/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)

    def test_reservations_require_authentication(self):
        response = self.client.get('/api/reservations/')
        self.assertEqual(response.status_code, 401)

    def test_user_only_sees_own_reservations(self):
        self.client.force_authenticate(self.user)
        response = self.client.get('/api/reservations/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, [])

    def test_equipment_overallocation_is_rejected(self):
        self.client.force_authenticate(self.user)
        response = self.client.post('/api/reservations/', {
            'equipment': self.equipment.pk,
            'start_at': (timezone.now() + timedelta(days=1)).isoformat(),
            'end_at': (timezone.now() + timedelta(days=1, hours=1)).isoformat(),
            'purpose': 'Science project',
            'quantity': 1,
        })
        self.assertEqual(response.status_code, 400)
        self.assertIn('availability', response.data)

    def test_laboratory_double_booking_is_rejected(self):
        laboratory = Laboratory.objects.create(
            name='Chemistry Lab', building='C', room_number='204', capacity=20,
        )
        start_at = timezone.now() + timedelta(days=2)
        Reservation.objects.create(
            requester=self.other_user,
            laboratory=laboratory,
            start_at=start_at,
            end_at=start_at + timedelta(hours=1),
            purpose='Lab work',
        )
        self.client.force_authenticate(self.user)
        response = self.client.post('/api/reservations/', {
            'laboratory': laboratory.pk,
            'start_at': start_at.isoformat(),
            'end_at': (start_at + timedelta(hours=1)).isoformat(),
            'purpose': 'Group study',
            'attendees': 5,
        })
        self.assertEqual(response.status_code, 400)
        self.assertIn('availability', response.data)

    def test_staff_can_approve_with_remarks(self):
        admin = get_user_model().objects.create_user(
            username='manager', password='test-password', is_staff=True,
        )
        self.client.force_authenticate(admin)
        response = self.client.post(
            f'/api/reservations/{self.existing_reservation.pk}/review/',
            {'decision': 'approved', 'remarks': 'Collect from the media desk.'},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['status'], Reservation.Status.APPROVED)
        self.assertEqual(response.data['remarks'], 'Collect from the media desk.')

    def test_requester_can_cancel_own_reservation(self):
        reservation = Reservation.objects.create(
            requester=self.user,
            equipment=Equipment.objects.create(name='Mic', category='Audio', asset_tag='MIC-002'),
            start_at=timezone.now() + timedelta(days=3),
            end_at=timezone.now() + timedelta(days=3, hours=1),
            purpose='Presentation',
        )
        self.client.force_authenticate(self.user)
        response = self.client.post(f'/api/reservations/{reservation.pk}/cancel/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['status'], Reservation.Status.CANCELLED)

    def test_catalogue_writes_require_staff(self):
        self.client.force_authenticate(self.user)
        response = self.client.post('/api/equipment/', {
            'name': 'Tripod', 'category': 'Media', 'asset_tag': 'TRI-001', 'quantity': 1,
        })
        self.assertEqual(response.status_code, 403)

    def test_staff_can_download_excel_report(self):
        admin = get_user_model().objects.create_user(
            username='reporter', password='test-password', is_staff=True,
        )
        self.client.force_authenticate(admin)
        response = self.client.get('/api/reports/reservations/?export=xlsx')
        self.assertEqual(response.status_code, 200, response.data if hasattr(response, 'data') else response.content[:500])
        self.assertEqual(
            response['Content-Type'],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
        self.assertTrue(response.content.startswith(b'PK'))

    def test_user_can_change_password_with_current_password(self):
        self.client.force_authenticate(self.user)
        response = self.client.post('/api/auth/password/change/', {
            'old_password': 'test-password',
            'new_password': 'a-new-long-secure-password',
        })
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('a-new-long-secure-password'))