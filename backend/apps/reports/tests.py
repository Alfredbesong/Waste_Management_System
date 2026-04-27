from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from .models import Confirmation, WasteReport


class ReportApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = get_user_model().objects.create_user(
            username='citizen1',
            email='citizen@example.com',
            password='password123',
        )
        self.admin = get_user_model().objects.create_user(
            username='admin1',
            email='admin@example.com',
            password='password123',
            is_staff=True,
            role='admin',
        )
        self.client.force_authenticate(self.user)

    def test_anonymous_user_cannot_list_reports(self):
        self.client.force_authenticate(user=None)

        response = self.client.get('/api/reports/')

        self.assertEqual(response.status_code, 401)

    def test_user_can_create_report(self):
        image = SimpleUploadedFile('waste.jpg', b'filecontent', content_type='image/jpeg')

        response = self.client.post(
            '/api/reports/',
            {
                'description': 'Waste beside the road',
                'photo': image,
                'latitude': 4.156,
                'longitude': 9.265,
            },
            format='multipart',
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(WasteReport.objects.count(), 1)

    def test_citizen_cannot_update_report_status(self):
        report = WasteReport.objects.create(
            user=self.user,
            description='Waste beside the road',
            photo=SimpleUploadedFile('waste.jpg', b'filecontent', content_type='image/jpeg'),
            latitude=4.156,
            longitude=9.265,
        )

        response = self.client.patch(
            f'/api/reports/{report.id}/',
            {'status': WasteReport.Status.RESOLVED},
            format='json',
        )

        self.assertEqual(response.status_code, 403)

    def test_admin_can_update_report_status(self):
        report = WasteReport.objects.create(
            user=self.user,
            description='Waste beside the road',
            photo=SimpleUploadedFile('waste.jpg', b'filecontent', content_type='image/jpeg'),
            latitude=4.156,
            longitude=9.265,
        )

        self.client.force_authenticate(self.admin)
        response = self.client.patch(
            f'/api/reports/{report.id}/',
            {'status': WasteReport.Status.RESOLVED},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['status'], WasteReport.Status.RESOLVED)

    def test_user_can_confirm_own_report(self):
        report = WasteReport.objects.create(
            user=self.user,
            description='Waste beside the road',
            photo=SimpleUploadedFile('waste.jpg', b'filecontent', content_type='image/jpeg'),
            latitude=4.156,
            longitude=9.265,
        )

        response = self.client.post(
            '/api/confirm/',
            {'report': report.id, 'is_cleared': True},
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(Confirmation.objects.count(), 1)
