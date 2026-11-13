from django.urls import path
from . import views

urlpatterns = [
    path('tickets/', views.tickets, name='tickets'),
    path('api/tickets', views.ticket_inventory, name='ticket_inventory'),
    path('api/tickets/summary', views.ticket_summary, name='ticket_summary'),
    path('api/tickets/archived', views.archived_tickets, name='archived_tickets'),
    path('api/tickets/tags', views.ticket_tags, name='ticket_tags'),
    path('api/tickets/tags/<int:tag_id>', views.ticket_tags, name='ticket_tag'),
    path('api/tickets/equipment', views.ticket_equipment, name='ticket_equipment'),
    path('api/tickets/equipment/manage', views.manage_ticket_equipment, name='manage_ticket_equipment'),
    path('api/tickets/equipment/manage/<str:equipment_id>', views.manage_ticket_equipment, name='manage_ticket_equipment_item'),
    path('api/tickets/staff', views.ticket_staff, name='ticket_staff'),
    path('api/tickets/researchers', views.ticket_researchers, name='ticket_researchers'),
    path('tickets/<int:ticket_id>/', views.ticket_detail, name='ticket_detail'),
    path('api/tickets/<int:ticket_id>', views.ticket_detail_data, name='ticket_detail_data'),
    path('api/tickets/<int:ticket_id>/researcher', views.ticket_researcher_link, name='ticket_researcher_link'),
    path('api/tickets/<int:ticket_id>/tags', views.ticket_tag_assignments, name='ticket_tag_assignments'),
    path('api/tickets/<int:ticket_id>/admin-edit', views.ticket_admin_edit, name='ticket_admin_edit'),
    path('api/tickets/<int:ticket_id>/images/<int:image_id>/remove', views.ticket_admin_remove_image, name='ticket_admin_remove_image'),
    path('api/tickets/<int:ticket_id>/export', views.ticket_export, name='ticket_export'),
    path('api/tickets/<int:ticket_id>/<str:action>/archive-action', views.ticket_archive_action, name='ticket_archive_action'),
    path('api/tickets/<int:ticket_id>/images/<int:image_id>', views.ticket_image, name='ticket_image'),
]
