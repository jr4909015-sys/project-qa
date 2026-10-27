from rest_framework import serializers
from django.db.models import Sum
from .models import Equipment, EquipmentLoan


class EquipmentSerializer(serializers.ModelSerializer):
    available_quantity = serializers.SerializerMethodField()

    class Meta:
        model = Equipment
        fields = '__all__'

    def get_available_quantity(self, equipment):
        loaned = EquipmentLoan.objects.filter(
            equipment=equipment, returned_at__isnull=True
        ).aggregate(total=Sum('quantity'))['total'] or 0
        return max(equipment.quantity - loaned, 0)


class EquipmentLoanSerializer(serializers.ModelSerializer):
    equipment_name = serializers.CharField(source='equipment.name', read_only=True)
    borrower_name = serializers.CharField(source='borrower.username', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)

    class Meta:
        model = EquipmentLoan
        fields = '__all__'
        read_only_fields = ('checked_out_by', 'checked_out_at', 'returned_at', 'returned_by')