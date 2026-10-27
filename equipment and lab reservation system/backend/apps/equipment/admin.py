from django.contrib import admin
from .models import Equipment


@admin.register(Equipment)
class EquipmentAdmin(admin.ModelAdmin):
	list_display = ('name', 'category', 'asset_tag', 'quantity', 'is_active')
	list_filter = ('category', 'is_active')
	search_fields = ('name', 'asset_tag')

# Register your models here.
