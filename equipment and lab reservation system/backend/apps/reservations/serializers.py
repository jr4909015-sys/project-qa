from rest_framework import serializers
from .availability import reservation_availability_error
from .models import Reservation


class ReservationSerializer(serializers.ModelSerializer):
    requester_name = serializers.CharField(source='requester.username', read_only=True)
    equipment_name = serializers.CharField(source='equipment.name', read_only=True, default='')
    laboratory_name = serializers.CharField(source='laboratory.name', read_only=True, default='')

    class Meta:
        model = Reservation
        fields = '__all__'
        read_only_fields = (
            'requester',
            'status',
            'reviewed_by',
            'reviewed_at',
            'cancelled_at',
            'completed_at',
            'proposed_start_at',
            'proposed_end_at',
            'reschedule_status',
            'reschedule_remarks',
            'reschedule_requested_at',
            'reschedule_reviewed_by',
            'reschedule_reviewed_at',
            'created_at',
        )

    def validate(self, attrs):
        start_at = attrs.get('start_at', getattr(self.instance, 'start_at', None))
        end_at = attrs.get('end_at', getattr(self.instance, 'end_at', None))
        equipment = attrs.get('equipment', getattr(self.instance, 'equipment', None))
        laboratory = attrs.get('laboratory', getattr(self.instance, 'laboratory', None))
        if not ((equipment is None) ^ (laboratory is None)):
            raise serializers.ValidationError('Choose exactly one equipment item or laboratory.')
        if start_at and end_at and end_at <= start_at:
            raise serializers.ValidationError({'end_at': 'End time must be after start time.'})
        if start_at and end_at:
            availability_error = reservation_availability_error(
                equipment=equipment,
                laboratory=laboratory,
                start_at=start_at,
                end_at=end_at,
                quantity=attrs.get('quantity', getattr(self.instance, 'quantity', 1)),
                attendees=attrs.get('attendees', getattr(self.instance, 'attendees', 1)),
                exclude_id=self.instance.pk if self.instance else None,
            )
            if availability_error:
                raise serializers.ValidationError({'availability': availability_error})
        return attrs