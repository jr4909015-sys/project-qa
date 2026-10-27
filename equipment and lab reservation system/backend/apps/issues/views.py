from django.contrib.auth import get_user_model
from rest_framework import permissions
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.viewsets import ModelViewSet

from apps.audit.services import record_audit
from apps.notifications.services import notify_user

from .models import IssueReport
from .serializers import IssueReportSerializer


class IssueReportViewSet(ModelViewSet):
	serializer_class = IssueReportSerializer
	permission_classes = [permissions.IsAuthenticated]
	parser_classes = [JSONParser, MultiPartParser, FormParser]

	def get_queryset(self):
		queryset = IssueReport.objects.select_related('reporter', 'equipment', 'laboratory')
		if not self.request.user.is_staff:
			queryset = queryset.filter(reporter=self.request.user)
		return queryset

	def get_permissions(self):
		if self.action in {'update', 'partial_update', 'destroy'}:
			return [permissions.IsAdminUser()]
		return super().get_permissions()

	def perform_create(self, serializer):
		report = serializer.save(reporter=self.request.user)
		record_audit(
			actor=self.request.user,
			action='issue_reported',
			instance=report,
			summary=f'Reported a problem with {report.equipment or report.laboratory}.',
		)
		for recipient in get_user_model().objects.filter(is_staff=True, is_active=True):
			notify_user(
				recipient=recipient,
				title='New resource problem reported',
				message=f'{self.request.user.username} reported: {report.description[:180]}',
			)

	def perform_update(self, serializer):
		old_status = serializer.instance.status
		report = serializer.save()
		if old_status != report.status:
			notify_user(
				recipient=report.reporter,
				title='Your resource problem report was updated',
				message=report.resolution_note or f'Report status: {report.get_status_display()}.',
			)
		record_audit(
			actor=self.request.user,
			action='issue_report_updated',
			instance=report,
			summary=f'Updated resource issue report #{report.pk}.',
		)
