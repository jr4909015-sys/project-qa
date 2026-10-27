from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient


class UsernameOrEmailLoginTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.password = 'CampusAdmin!2026Strong'
        self.user = get_user_model().objects.create_superuser(
            username='campus-admin',
            email='admin@campus.example',
            password=self.password,
        )

    def test_admin_can_sign_in_with_username_and_open_admin_api(self):
        response = self.client.post(
            '/api/auth/token/',
            {'username': self.user.username, 'password': self.password},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")
        profile = self.client.get('/api/auth/me/')
        self.assertEqual(profile.status_code, 200)
        self.assertEqual(profile.data['role'], 'admin')

    def test_admin_can_sign_in_with_email(self):
        response = self.client.post(
            '/api/auth/token/',
            {'username': self.user.email, 'password': self.password},
            format='json',
        )

        self.assertEqual(response.status_code, 200)

    def test_profile_supports_shared_contact_and_department_fields(self):
        self.client.force_authenticate(self.user)
        update = self.client.patch(
            '/api/auth/me/',
            {
                'first_name': 'Campus',
                'student_employee_id': 'STU-104',
                'department': 'Science',
                'contact_number': '555-0104',
            },
            format='json',
        )

        self.assertEqual(update.status_code, 200, update.data)
        self.assertEqual(update.data['student_employee_id'], 'STU-104')
        self.assertEqual(update.data['department'], 'Science')
        self.assertEqual(update.data['contact_number'], '555-0104')


class UserManagementTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = get_user_model().objects.create_superuser(
            username='user-manager',
            email='user-manager@campus.example',
            password='Manager!2026Strong',
        )

    def test_admin_can_create_and_update_user_accounts(self):
        self.client.force_authenticate(self.admin)
        response = self.client.post(
            '/api/users/',
            {
                'username': 'new-teacher',
                'email': 'teacher@campus.example',
                'first_name': 'New',
                'last_name': 'Teacher',
                'password': 'Teacher!2026Strong',
                'role': 'teacher',
                'is_active': True,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201, response.data)
        user = get_user_model().objects.get(username='new-teacher')
        self.assertTrue(user.check_password('Teacher!2026Strong'))
        self.assertEqual(response.data['role_name'], 'teacher')

        response = self.client.patch(
            f'/api/users/{user.pk}/',
            {'role': 'staff', 'is_active': False},
            format='json',
        )
        self.assertEqual(response.status_code, 200, response.data)
        user.refresh_from_db()
        self.assertFalse(user.is_active)
        self.assertTrue(user.is_staff)
        self.assertEqual(response.data['role_name'], 'staff')

    def test_non_admin_cannot_manage_user_accounts(self):
        student = get_user_model().objects.create_user(
            username='regular-student',
            password='Student!2026Strong',
        )
        self.client.force_authenticate(student)

        response = self.client.get('/api/users/')
        self.assertEqual(response.status_code, 403)

    def test_admin_cannot_deactivate_or_change_own_role(self):
        self.client.force_authenticate(self.admin)

        response = self.client.patch(
            f'/api/users/{self.admin.pk}/',
            {'is_active': False},
            format='json',
        )
        self.assertEqual(response.status_code, 400)

        response = self.client.patch(
            f'/api/users/{self.admin.pk}/',
            {'role': 'student'},
            format='json',
        )
        self.assertEqual(response.status_code, 400)

        self.admin.refresh_from_db()
        self.assertTrue(self.admin.is_active)
        self.assertTrue(self.admin.is_superuser)
