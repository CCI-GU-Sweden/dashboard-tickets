"""Ticket registration and scoped overview for the dashboard core."""
from accounts.permissions import operational_access, researcher_access
from dashboard.modules import DashboardModule
from . import data


def can_view(user):
    return operational_access(user) or researcher_access(user)


def overview_metrics(user):
    summary = data.ticket_summary(researcher_id=user.pk if researcher_access(user) else None)
    result = []
    for key, label in (('total', 'Total tickets'), ('active', 'Active tickets'), ('resolved', 'Resolved · last 30 days')):
        change = summary['changes'][key]
        detail = 'Comparison unavailable' if change is None else f"{change:+,} {'vs previous 30 days' if key == 'resolved' else 'vs 30 days ago'}"
        result.append({'key': key, 'label': label, 'value': f"{summary[key]:,}", 'detail': detail})
    return result


module = DashboardModule(
    key='tickets', name='Tickets', eyebrow='Facility support', icon='🎫',
    url_name='tickets', urlconf='dashboard_tickets.urls', can_view=can_view,
    get_metrics=overview_metrics, overview_template='ticket_overview_card.html',
    overview_script='js/ticket_overview.js',
)
