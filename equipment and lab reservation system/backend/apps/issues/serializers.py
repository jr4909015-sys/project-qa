from rest_framework import serializers

from .models import IssueReport


class IssueReportSerializer(serializers.ModelSerializer):
	reporter_name = serializers.CharField(source='reporter.username', read_only=True)
	equipment_name = serializers.CharField(source='equipment.name', read_only=True, default='')
	laboratory_name = serializers.CharField(source='laboratory.name', read_only=True, default='')

	class Meta:
		model = IssueReport
		fields = '__all__'
		read_only_fields = (
			'reporter',
			'created_at',
			'updated_at',
		)

	def get_fields(self):
		fields = super().get_fields()
		request = self.context.get('request')
		if request and not request.user.is_staff:
			fields['status'].read_only = True
			fields['resolution_note'].read_only = True
		return fields

	def validate(self, attrs):
		equipment = attrs.get('equipment', getattr(self.instance, 'equipment', None))
		laboratory = attrs.get('laboratory', getattr(self.instance, 'laboratory', None))
		if bool(equipment) == bool(laboratory):
			raise serializers.ValidationError('Choose exactly one equipment item or laboratory.')
		if not attrs.get('description', getattr(self.instance, 'description', '')).strip():
			raise serializers.ValidationError({'description': 'Describe the damage or problem.'})
		return attrs
