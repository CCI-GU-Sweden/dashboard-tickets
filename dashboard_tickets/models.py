from django.conf import settings
from django.db import models

User = settings.AUTH_USER_MODEL


class TicketStaffAssignment(models.Model):
    ticket_id = models.PositiveBigIntegerField(db_index=True)
    staff = models.ForeignKey(User, on_delete=models.PROTECT, related_name='ticket_assignments')

    class Meta:
        db_table = 'accounts_ticketstaffassignment'
        constraints = [models.UniqueConstraint(fields=['ticket_id', 'staff'], name='unique_ticket_staff')]


class TicketResearcherLink(models.Model):
    ticket_id = models.PositiveBigIntegerField(unique=True)
    researcher = models.ForeignKey(User, on_delete=models.PROTECT, related_name='linked_tickets')

    class Meta:
        db_table = 'accounts_ticketresearcherlink'


class TicketArchive(models.Model):
    ticket_id = models.PositiveBigIntegerField(primary_key=True)
    reason = models.CharField(max_length=1000)
    archived_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name='archived_tickets')
    archived_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'accounts_ticketarchive'


class TicketTag(models.Model):
    name = models.CharField(max_length=60)

    class Meta:
        db_table = 'accounts_tickettag'
        constraints = [models.UniqueConstraint(models.functions.Lower('name'), name='unique_ticket_tag_name_ci')]
        ordering = ['name', 'id']


class TicketTagAssignment(models.Model):
    ticket_id = models.PositiveBigIntegerField(db_index=True)
    tag = models.ForeignKey(TicketTag, on_delete=models.CASCADE, related_name='assignments')

    class Meta:
        db_table = 'accounts_tickettagassignment'
        constraints = [models.UniqueConstraint(fields=['ticket_id', 'tag'], name='unique_ticket_tag_assignment')]
