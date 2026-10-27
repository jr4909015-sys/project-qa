from rest_framework import permissions, status
from rest_framework.decorators import action
from rest_framework.filters import OrderingFilter, SearchFilter
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from django.shortcuts import get_object_or_404
from django.utils.dateparse import parse_datetime
from apps.accounts.permissions import IsStaffOrReadOnly
from apps.audit.services import record_audit
from apps.reservations.models import Reservation
from .models import Laboratory, LaboratoryBlock
from .serializers import LaboratoryBlockSerializer, LaboratorySerializer


class LaboratoryViewSet(ModelViewSet):
	serializer_class = LaboratorySerializer
	permission_classes = [IsStaffOrReadOnly]
	filter_backends = [SearchFilter, OrderingFilter]
	search_fields = ['name', 'building', 'room_number']
	ordering_fields = ['name', 'building', 'capacity']

	def get_queryset(self):
		queryset = Laboratory.objects.all()
		if not self.request.user.is_staff:
			queryset = queryset.filter(is_active=True)
		building = self.request.query_params.get('building')
		min_capacity = self.request.query_params.get('min_capacity')
		if building:
			queryset = queryset.filter(building__icontains=building)
		if min_capacity:
			try:
				queryset = queryset.filter(capacity__gte=int(min_capacity))
			except ValueError:
				return queryset.none()
		return queryset

	def perform_create(self, serializer):
		room = serializer.save()
		record_audit(actor=self.request.user, action='laboratory_created', instance=room, summary=f'Created laboratory {room.name}.')

	def perform_update(self, serializer):
		room = serializer.save()
		record_audit(actor=self.request.user, action='laboratory_updated', instance=room, summary=f'Updated laboratory {room.name}.')

	def perform_destroy(self, instance):
		record_audit(actor=self.request.user, action='laboratory_deleted', instance=instance, summary=f'Deleted laboratory {instance.name}.')
		instance.delete()

	@action(detail=True, methods=['get'], permission_classes=[permissions.AllowAny])
	def availability(self, request, pk=None):
		laboratory = self.get_object()
		start_at = parse_datetime(request.query_params.get('start_at', ''))
		end_at = parse_datetime(request.query_params.get('end_at', ''))
		if not start_at or not end_at or end_at <= start_at:
			return Response({'detail': 'start_at and end_at are required.'}, status=status.HTTP_400_BAD_REQUEST)
		conflicts = Reservation.objects.filter(
			laboratory=laboratory,
			status__in=[Reservation.Status.PENDING, Reservation.Status.APPROVED],
			start_at__lt=end_at,
			end_at__gt=start_at,
		).exists()
		blocks = LaboratoryBlock.objects.filter(
			laboratory=laboratory, start_at__lt=end_at, end_at__gt=start_at
		).exists()
		within_hours = True
		if laboratory.opening_time and laboratory.closing_time:
			within_hours = (
				start_at.date() == end_at.date()
				and start_at.time() >= laboratory.opening_time
				and end_at.time() <= laboratory.closing_time
			)
		return Response({'available': not conflicts and not blocks and within_hours})

	@action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
	def block(self, request, pk=None):
		laboratory = self.get_object()
		serializer = LaboratoryBlockSerializer(data={**request.data, 'laboratory': laboratory.pk})
		serializer.is_valid(raise_exception=True)
		block = serializer.save(created_by=request.user)
		record_audit(actor=request.user, action='laboratory_blocked', instance=block, summary=f'Blocked {laboratory.name}: {block.reason}.')
		return Response(serializer.data, status=status.HTTP_201_CREATED)

	@action(detail=True, methods=['get'], permission_classes=[permissions.IsAdminUser])
	def blocks(self, request, pk=None):
		laboratory = self.get_object()
		blocks = LaboratoryBlock.objects.filter(laboratory=laboratory).order_by('start_at')
		return Response(LaboratoryBlockSerializer(blocks, many=True).data)

	@action(
		detail=True,
		methods=['delete'],
		url_path=r'blocks/(?P<block_id>[^/.]+)',
		permission_classes=[permissions.IsAdminUser],
	)
	def delete_block(self, request, pk=None, block_id=None):
		laboratory = self.get_object()
		block = get_object_or_404(LaboratoryBlock, pk=block_id, laboratory=laboratory)
		record_audit(actor=request.user, action='laboratory_unblocked', instance=block, summary=f'Removed block from {laboratory.name}: {block.reason}.')
		block.delete()
		return Response(status=status.HTTP_204_NO_CONTENT)

# Create your views here.
