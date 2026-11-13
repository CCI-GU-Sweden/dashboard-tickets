from dashboard.schema_setup import SchemaSetupCommand


class Command(SchemaSetupCommand):
    help = 'Check or explicitly create the PostgreSQL ticket table baseline.'
    package = 'dashboard_tickets'
    tables = ('ticket_equipment', 'microscope_ticket', 'microscope_ticket_event', 'microscope_ticket_image')
