from django.db import transaction
from django.db.models import Sum
from django.utils import timezone
from rest_framework import permissions, serializers
from rest_framework.decorators import action
from rest_framework.filters import OrderingFilter, SearchFilter
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from apps.accounts.permissions import IsStaffOrReadOnly
from apps.audit.services import record_audit
from .models import Equipment, EquipmentLoan
from .serializers import EquipmentLoanSerializer, EquipmentSerializer


class EquipmentViewSet(ModelViewSet):
	serializer_class = EquipmentSerializer
	permission_classes = [IsStaffOrReadOnly]
	parser_classes = [JSONParser, MultiPartParser, FormParser]
	filter_backends = [SearchFilter, OrderingFilter]
	search_fields = ['name', 'category', 'asset_tag', 'location']
	ordering_fields = ['name', 'category', 'quantity', 'created_at']

	def get_queryset(self):
		queryset = Equipment.objects.all()
		if not self.request.user.is_staff or self.request.query_params.get('include_archived') != 'true':
			queryset = queryset.filter(is_active=True)
		category = self.request.query_params.get('category')
		condition = self.request.query_params.get('condition')
		if category:
			queryset = queryset.filter(category__icontains=category)
		if condition:
			queryset = queryset.filter(condition=condition)
		return queryset

	def perform_create(self, serializer):
		item = serializer.save()
		record_audit(actor=self.request.user, action='equipment_created', instance=item, summary=f'Created equipment {item.name}.')

	def perform_update(self, serializer):
		item = serializer.save()
		record_audit(actor=self.request.user, action='equipment_updated', instance=item, summary=f'Updated equipment {item.name}.')

	def perform_destroy(self, instance):
		record_audit(actor=self.request.user, action='equipment_deleted', instance=instance, summary=f'Deleted equipment {instance.name}.')
		instance.delete()


class EquipmentLoanViewSet(ModelViewSet):
	serializer_class = EquipmentLoanSerializer
	permission_classes = [permissions.IsAuthenticated]

	def get_queryset(self):
		queryset = EquipmentLoan.objects.select_related('equipment', 'borrower', 'checked_out_by')
		return queryset if self.request.user.is_staff else queryset.filter(borrower=self.request.user)

	def get_permissions(self):
		if self.action in {'create', 'return_item', 'destroy', 'update', 'partial_update'}:
			return [permissions.IsAdminUser()]
		return super().get_permissions()

	@transaction.atomic
	def perform_create(self, serializer):
		equipment = serializer.validated_data['equipment']
		equipment = Equipment.objects.select_for_update().get(pk=equipment.pk)
		quantity = serializer.validated_data['quantity']
		loaned = EquipmentLoan.objects.filter(
			equipment=equipment, returned_at__isnull=True
		).aggregate(total=Sum('quantity'))['total'] or 0
		if equipment.condition in [Equipment.Condition.DAMAGED, Equipment.Condition.MAINTENANCE] or loaned + quantity > equipment.quantity:
			raise serializers.ValidationError({'quantity': 'That quantity is not available for check-out.'})
		loan = serializer.save(checked_out_by=self.request.user)
		record_audit(actor=self.request.user, action='checked_out', instance=loan, summary=f'Checked out {quantity} × {equipment.name}.')

	@action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
	def return_item(self, request, pk=None):
		loan = self.get_object()
		if loan.returned_at:
			raise serializers.ValidationError({'detail': 'This loan has already been returned.'})
		condition = request.data.get('return_condition', Equipment.Condition.GOOD)
		if condition not in Equipment.Condition.values:
			raise serializers.ValidationError({'return_condition': 'Choose a valid equipment condition.'})
		loan.returned_at = timezone.now()
		loan.returned_by = request.user
		loan.return_condition = condition
		loan.equipment.condition = condition
		loan.equipment.save(update_fields=['condition'])
		loan.save(update_fields=['returned_at', 'returned_by', 'return_condition'])
		record_audit(actor=request.user, action='returned', instance=loan, summary=f'Returned {loan.equipment.name} in {condition} condition.')
		return Response(self.get_serializer(loan).data)

# Create your views here.
