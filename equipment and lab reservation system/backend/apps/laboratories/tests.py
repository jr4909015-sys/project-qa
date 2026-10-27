from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from rest_framework.test import APIClient

from apps.laboratories.models import Laboratory, LaboratoryBlock


class LaboratoryBlockApiTests(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_superuser(
            username='schedule-admin',
            email='schedule@example.com',
            password='ScheduleAdmin!2026',
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.room = Laboratory.objects.create(
            name='Science Lab',
            building='North',
            room_number='101',
            capacity=24,
        )
        self.block = LaboratoryBlock.objects.create(
            laboratory=self.room,
            start_at=timezone.now() + timedelta(days=1),
            end_at=timezone.now() + timedelta(days=1, hours=2),
            reason='Maintenance',
            created_by=self.user,
        )

    def test_staff_can_list_room_schedule_blocks(self):
        response = self.client.get(f'/api/laboratories/{self.room.pk}/blocks/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual([block['id'] for block in response.data], [self.block.pk])

    def test_staff_can_remove_room_schedule_block(self):
        response = self.client.delete(
            f'/api/laboratories/{self.room.pk}/blocks/{self.block.pk}/'
        )

        self.assertEqual(response.status_code, 204)
        self.assertFalse(LaboratoryBlock.objects.filter(pk=self.block.pk).exists())
