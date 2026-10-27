"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.contrib.auth import get_user_model
from django.conf import settings
from django.urls import include, path
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from apps.equipment.views import EquipmentViewSet
from apps.equipment.views import EquipmentLoanViewSet
from apps.laboratories.views import LaboratoryViewSet
from apps.reservations.views import ReservationViewSet
from apps.accounts.views import (
    CurrentUserView,
    PasswordChangeView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    RegistrationView,
    UserManagementViewSet,
)
from apps.audit.views import AuditLogViewSet
from apps.notifications.views import NotificationViewSet
from apps.issues.views import IssueReportViewSet

router = DefaultRouter()
router.register('equipment', EquipmentViewSet, basename='equipment')
router.register('laboratories', LaboratoryViewSet, basename='laboratory')
router.register('reservations', ReservationViewSet, basename='reservation')
router.register('users', UserManagementViewSet, basename='user')
router.register('loans', EquipmentLoanViewSet, basename='loan')
router.register('notifications', NotificationViewSet, basename='notification')
router.register('audit', AuditLogViewSet, basename='audit')
router.register('issues', IssueReportViewSet, basename='issue')


class UsernameOrEmailTokenSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        identifier = attrs.get(self.username_field, '')
        if identifier and '@' in identifier:
            matching_users = get_user_model().objects.filter(email__iexact=identifier)
            if matching_users.count() == 1:
                attrs[self.username_field] = matching_users.get().get_username()
        return super().validate(attrs)


class UsernameOrEmailTokenView(TokenObtainPairView):
    serializer_class = UsernameOrEmailTokenSerializer


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/token/', UsernameOrEmailTokenView.as_view(), name='token_obtain_pair'),
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/register/', RegistrationView.as_view(), name='register'),
    path('api/auth/me/', CurrentUserView.as_view(), name='current-user'),
    path('api/auth/password/change/', PasswordChangeView.as_view(), name='password-change'),
    path('api/auth/password/reset/', PasswordResetRequestView.as_view(), name='password-reset'),
    path('api/auth/password/reset/confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
    path('api/reports/', include('apps.reports.urls')),
    path('api/', include(router.urls)),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
