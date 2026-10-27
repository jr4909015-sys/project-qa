from django.utils import timezone
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from .models import Notification
from .serializers import NotificationSerializer


class NotificationViewSet(ModelViewSet):
	serializer_class = NotificationSerializer
	permission_classes = [IsAuthenticated]
	http_method_names = ['get', 'head', 'options', 'post']

	def get_queryset(self):
		return Notification.objects.filter(recipient=self.request.user)

	@action(detail=True, methods=['post'])
	def mark_read(self, request, pk=None):
		notification = self.get_object()
		notification.read_at = notification.read_at or timezone.now()
		notification.save(update_fields=['read_at'])
		return Response(self.get_serializer(notification).data)
