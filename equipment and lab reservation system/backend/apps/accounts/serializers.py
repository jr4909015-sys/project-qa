from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from rest_framework import serializers

from .models import UserProfile

User = get_user_model()
ROLE_CHOICES = [('student', 'Student'), ('teacher', 'Teacher'), ('staff', 'Staff'), ('admin', 'Admin')]


class UserManagementSerializer(serializers.ModelSerializer):
    role = serializers.ChoiceField(choices=ROLE_CHOICES, write_only=True, required=False)
    role_name = serializers.SerializerMethodField()
    password = serializers.CharField(write_only=True, required=False, min_length=10)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'is_active', 'role', 'role_name', 'password')

    def get_role_name(self, user):
        if user.is_superuser:
            return 'admin'
        return user.groups.values_list('name', flat=True).first() or ('staff' if user.is_staff else 'student')

    def _apply_role(self, user, role):
        group, _ = Group.objects.get_or_create(name=role)
        user.groups.set([group])
        user.is_staff = role in {'staff', 'admin'}
        user.is_superuser = role == 'admin'

    def create(self, validated_data):
        password = validated_data.pop('password', None)
        if not password:
            raise serializers.ValidationError({'password': 'A password is required.'})
        role = validated_data.pop('role', 'student')
        user = User.objects.create_user(password=password, **validated_data)
        self._apply_role(user, role)
        user.save()
        return user

    def update(self, user, validated_data):
        password = validated_data.pop('password', None)
        role = validated_data.pop('role', None)
        for field, value in validated_data.items():
            setattr(user, field, value)
        if password:
            user.set_password(password)
        if role:
            self._apply_role(user, role)
        user.save()
        return user


class RegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=10)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'password')
        read_only_fields = ('id',)

    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        group, _ = Group.objects.get_or_create(name='student')
        user.groups.add(group)
        return user


class ProfileSerializer(serializers.ModelSerializer):
    role = serializers.SerializerMethodField()
    student_employee_id = serializers.CharField(
        source='profile.student_employee_id', required=False, allow_blank=True
    )
    department = serializers.CharField(
        source='profile.department', required=False, allow_blank=True
    )
    contact_number = serializers.CharField(
        source='profile.contact_number', required=False, allow_blank=True
    )
    photo = serializers.ImageField(source='profile.photo', required=False)

    class Meta:
        model = User
        fields = (
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'role',
            'student_employee_id',
            'department',
            'contact_number',
            'photo',
        )
        read_only_fields = ('id', 'username', 'role')

    def update(self, instance, validated_data):
        profile_data = validated_data.pop('profile', {})
        for field, value in validated_data.items():
            setattr(instance, field, value)
        instance.save()
        profile, _ = UserProfile.objects.get_or_create(user=instance)
        for field, value in profile_data.items():
            setattr(profile, field, value)
        if profile_data:
            profile.save()
        return instance

    def to_representation(self, instance):
        UserProfile.objects.get_or_create(user=instance)
        return super().to_representation(instance)

    def get_role(self, user):
        if user.is_superuser:
            return 'admin'
        return user.groups.values_list('name', flat=True).first() or ('staff' if user.is_staff else 'student')