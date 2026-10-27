from django.contrib import admin
from .models import Laboratory


@admin.register(Laboratory)
class LaboratoryAdmin(admin.ModelAdmin):
	list_display = ('name', 'building', 'room_number', 'capacity', 'is_active')
	list_filter = ('building', 'is_active')
	search_fields = ('name', 'room_number')

# Register your models here.
