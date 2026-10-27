from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from apps.equipment.models import Equipment
from apps.notifications.models import Notification
from .models import IssueReport


class IssueReportApiTests(TestCase):
	def setUp(self):
		users = get_user_model()
		self.reporter = users.objects.create_user(
			username='issue-reporter',
			password='Reporter!2026Strong',
		)
		self.admin = users.objects.create_superuser(
			username='issue-admin',
			email='issue-admin@example.com',
			password='Admin!2026Strong',
		)
		self.equipment = Equipment.objects.create(
			name='Issue camera',
			category='Media',
			asset_tag='ISSUE-001',
		)
		self.client = APIClient()

	def test_user_report_notifies_staff_and_staff_can_update_it(self):
		self.client.force_authenticate(self.reporter)
		created = self.client.post(
			'/api/issues/',
			{'equipment': self.equipment.pk, 'description': 'A cable is missing.'},
			format='multipart',
		)
		self.assertEqual(created.status_code, 201, created.data)
		report = IssueReport.objects.get(pk=created.data['id'])
		self.assertEqual(report.status, IssueReport.Status.REPORTED)
		self.assertTrue(
			Notification.objects.filter(
				recipient=self.admin,
				title='New resource problem reported',
			).exists()
		)

		self.client.force_authenticate(self.admin)
		updated = self.client.patch(
			f'/api/issues/{report.pk}/',
			{'status': IssueReport.Status.RESOLVED, 'resolution_note': 'Accessory replaced.'},
			format='json',
		)
		self.assertEqual(updated.status_code, 200, updated.data)
		report.refresh_from_db()
		self.assertEqual(report.status, IssueReport.Status.RESOLVED)
		self.assertTrue(
			Notification.objects.filter(
				recipient=self.reporter,
				title='Your resource problem report was updated',
			).exists()
		)

	def test_users_can_only_see_their_own_reports(self):
		IssueReport.objects.create(
			reporter=self.reporter,
			equipment=self.equipment,
			description='A cable is missing.',
		)
		other = get_user_model().objects.create_user(
			username='other-reporter',
			password='Other!2026Strong',
		)
		self.client.force_authenticate(other)

		response = self.client.get('/api/issues/')
		self.assertEqual(response.status_code, 200)
		self.assertEqual(response.data, [])
