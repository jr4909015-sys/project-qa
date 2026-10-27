from rest_framework import serializers
from .models import Laboratory, LaboratoryBlock


class LaboratorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Laboratory
        fields = '__all__'


class LaboratoryBlockSerializer(serializers.ModelSerializer):
    class Meta:
        model = LaboratoryBlock
        fields = '__all__'
        read_only_fields = ('created_by',)

    def validate(self, attrs):
        start_at = attrs.get('start_at')
        end_at = attrs.get('end_at')
        if start_at and end_at and end_at <= start_at:
            raise serializers.ValidationError({'end_at': 'End time must be after start time.'})
        return attrs