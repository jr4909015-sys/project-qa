from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from rest_framework.test import APIClient

from apps.equipment.models import Equipment
from apps.reservations.models import Reservation


class ReportApiTests(TestCase):
    def setUp(self):
        self.admin = get_user_model().objects.create_superuser(
            username='report-admin',
            email='report@example.com',
            password='ReportAdmin!2026',
        )
        self.client = APIClient()
        self.client.force_authenticate(self.admin)
        self.equipment = Equipment.objects.create(
            name='Lab microscope',
            category='Science',
            asset_tag='MIC-001',
            quantity=4,
        )
        Reservation.objects.create(
            requester=self.admin,
            equipment=self.equipment,
            start_at=timezone.now() + timedelta(days=1),
            end_at=timezone.now() + timedelta(days=1, hours=1),
            purpose='CSV export test',
            quantity=1,
        )

    def test_csv_export_contains_reservation_details(self):
        response = self.client.get('/api/reports/reservations/?export=csv')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response['Content-Type'], 'text/csv')
        self.assertContains(response, 'Requester,Equipment,Laboratory')
        self.assertContains(response, 'report-admin,Lab microscope,,')
        self.assertContains(response, 'CSV export test')

    def test_dashboard_reports_available_and_unavailable_units(self):
        self.equipment.condition = Equipment.Condition.DAMAGED
        self.equipment.save(update_fields=['condition'])

        response = self.client.get('/api/reports/summary/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['available_units'], 0)
        self.assertEqual(response.data['unavailable_units'], 4)
