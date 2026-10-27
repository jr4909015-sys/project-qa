from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.forms import PasswordResetForm
from django.contrib.auth.tokens import default_token_generator
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.hashers import check_password
from django.core.mail import send_mail
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import generics, permissions, serializers, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers import ProfileSerializer, RegistrationSerializer, UserManagementSerializer

User = get_user_model()


class UserManagementViewSet(viewsets.ModelViewSet):
	queryset = User.objects.prefetch_related('groups').order_by('username')
	serializer_class = UserManagementSerializer
	permission_classes = [permissions.IsAdminUser]
	search_fields = ['username', 'email', 'first_name', 'last_name']

	def perform_update(self, serializer):
		if serializer.instance == self.request.user:
			role = serializer.validated_data.get('role')
			current_role = serializer.fields['role_name'].to_representation(self.request.user)
			if serializer.validated_data.get('is_active') is False or (role and role != current_role):
				raise serializers.ValidationError(
					'You cannot deactivate your own account or change your own role.'
				)
		serializer.save()


class RegistrationView(generics.CreateAPIView):
	serializer_class = RegistrationSerializer
	permission_classes = [permissions.AllowAny]


class CurrentUserView(APIView):
	permission_classes = [permissions.IsAuthenticated]

	def get(self, request):
		return Response(ProfileSerializer(request.user).data)

	def patch(self, request):
		serializer = ProfileSerializer(request.user, data=request.data, partial=True)
		serializer.is_valid(raise_exception=True)
		serializer.save()
		return Response(serializer.data)


class PasswordChangeView(APIView):
	permission_classes = [permissions.IsAuthenticated]

	def post(self, request):
		old_password = request.data.get('old_password', '')
		new_password = request.data.get('new_password', '')
		if not check_password(old_password, request.user.password):
			return Response({'old_password': ['Current password is incorrect.']}, status=400)
		try:
			validate_password(new_password, request.user)
		except Exception as error:
			return Response({'new_password': list(error.messages)}, status=400)
		request.user.set_password(new_password)
		request.user.save(update_fields=['password'])
		return Response({'detail': 'Password updated.'})


class PasswordResetRequestView(APIView):
	permission_classes = [permissions.AllowAny]

	def post(self, request):
		email = request.data.get('email', '').strip()
		form = PasswordResetForm(data={'email': email})
		if email and form.is_valid():
			for user in form.get_users(email):
				uid = urlsafe_base64_encode(force_bytes(user.pk))
				token = default_token_generator.make_token(user)
				reset_url = f"{settings.FRONTEND_URL}/reset-password?uid={uid}&token={token}"
				send_mail(
					'Reset your campus reservation password',
					f'Use this link to reset your password: {reset_url}',
					settings.DEFAULT_FROM_EMAIL,
					[user.email],
					fail_silently=False,
				)
		return Response({'detail': 'If the account exists, a reset link has been sent.'}, status=202)


class PasswordResetConfirmView(APIView):
	permission_classes = [permissions.AllowAny]

	def post(self, request):
		try:
			user_id = force_str(urlsafe_base64_decode(request.data.get('uid', '')))
			user = User.objects.get(pk=user_id)
		except (TypeError, ValueError, OverflowError, User.DoesNotExist):
			return Response({'detail': 'Reset link is invalid or expired.'}, status=400)
		token = request.data.get('token', '')
		if not default_token_generator.check_token(user, token):
			return Response({'detail': 'Reset link is invalid or expired.'}, status=400)
		password = request.data.get('new_password', '')
		try:
			validate_password(password, user)
		except Exception as error:
			return Response({'new_password': list(error.messages)}, status=400)
		user.set_password(password)
		user.save(update_fields=['password'])
		return Response({'detail': 'Password reset.'})
