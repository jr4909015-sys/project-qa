from django.contrib import admin
from .models import Reservation


@admin.register(Reservation)
class ReservationAdmin(admin.ModelAdmin):
	list_display = ('id', 'requester', 'equipment', 'laboratory', 'start_at', 'status')
	list_filter = ('status', 'start_at')
	search_fields = ('requester__username', 'equipment__name', 'laboratory__name')

# Register your models here.
