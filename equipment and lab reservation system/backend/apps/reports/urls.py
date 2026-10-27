from django.urls import path
from .views import DashboardSummaryView, ReservationReportView

urlpatterns = [
    path('summary/', DashboardSummaryView.as_view(), name='dashboard-summary'),
    path('reservations/', ReservationReportView.as_view(), name='reservation-report'),
]