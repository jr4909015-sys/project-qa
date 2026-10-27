from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from rest_framework.test import APIClient

from apps.equipment.models import Equipment, EquipmentLoan


class EquipmentLoanApiTests(TestCase):
    def setUp(self):
        user_model = get_user_model()
        self.staff = user_model.objects.create_superuser(
            username='loan-admin',
            email='loan-admin@example.com',
            password='LoanAdmin!2026',
        )
        self.borrower = user_model.objects.create_user(
            username='borrower',
            email='borrower@example.com',
            password='Borrower!2026Strong',
        )
        self.equipment = Equipment.objects.create(
            name='Digital camera',
            category='Media',
            asset_tag='CAM-001',
            quantity=3,
        )
        self.client = APIClient()
        self.client.force_authenticate(self.staff)

    def test_staff_can_check_out_and_record_return_condition(self):
        checkout = self.client.post(
            '/api/loans/',
            {
                'equipment': self.equipment.pk,
                'borrower': self.borrower.pk,
                'quantity': 1,
                'due_at': (timezone.now() + timedelta(days=3)).isoformat(),
            },
            format='json',
        )

        self.assertEqual(checkout.status_code, 201)
        self.assertEqual(checkout.data['borrower_name'], self.borrower.username)
        self.assertEqual(checkout.data['is_overdue'], False)

        returned = self.client.post(
            f"/api/loans/{checkout.data['id']}/return_item/",
            {'return_condition': Equipment.Condition.FAIR},
            format='json',
        )

        self.assertEqual(returned.status_code, 200)
        self.assertEqual(returned.data['return_condition'], Equipment.Condition.FAIR)
        loan = EquipmentLoan.objects.get(pk=checkout.data['id'])
        self.assertEqual(loan.equipment.condition, Equipment.Condition.FAIR)
