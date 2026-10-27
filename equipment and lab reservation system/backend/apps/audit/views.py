from rest_framework.permissions import IsAdminUser
from rest_framework.viewsets import ReadOnlyModelViewSet
from .models import AuditLog
from .serializers import AuditLogSerializer


class AuditLogViewSet(ReadOnlyModelViewSet):
	queryset = AuditLog.objects.select_related('actor')
	serializer_class = AuditLogSerializer
	permission_classes = [IsAdminUser]
