-- Run with psql after Django migrations and both setup commands.
-- Example: psql -v ON_ERROR_STOP=1 -v runtime_role=YOUR_ROLE -f runtime-grants.example.sql
-- Confirm the role and privileges with the database owner before use.
BEGIN;
GRANT USAGE ON SCHEMA public TO :"runtime_role";
GRANT SELECT, INSERT ON public.ticket_equipment TO :"runtime_role";
GRANT UPDATE (name, category, active) ON public.ticket_equipment TO :"runtime_role";
GRANT SELECT, INSERT ON public.microscope_ticket, public.microscope_ticket_event, public.microscope_ticket_image TO :"runtime_role";
GRANT UPDATE (status, resolved_at, resolution_note, priority, assigned_to, issue_type, chat_thread_id, chat_url, chat_state, updated_at, updated_by, version, reporter_name, reporter_identifier, microscope, message, ticket_type) ON public.microscope_ticket TO :"runtime_role";
GRANT USAGE ON SEQUENCE public.microscope_ticket_ticket_id_seq, public.microscope_ticket_event_event_id_seq, public.microscope_ticket_image_image_id_seq TO :"runtime_role";
GRANT SELECT, INSERT, UPDATE, DELETE ON public.accounts_ticketresearcherlink, public.accounts_ticketstaffassignment TO :"runtime_role";
GRANT SELECT, INSERT, DELETE ON public.accounts_ticketarchive, public.accounts_tickettag, public.accounts_tickettagassignment TO :"runtime_role";
GRANT UPDATE (name) ON public.accounts_tickettag TO :"runtime_role";
GRANT USAGE, SELECT ON SEQUENCE public.accounts_ticketresearcherlink_id_seq, public.accounts_ticketstaffassignment_id_seq, public.accounts_tickettag_id_seq, public.accounts_tickettagassignment_id_seq TO :"runtime_role";
GRANT EXECUTE ON FUNCTION public.dashboard_purge_archived_ticket(bigint), public.dashboard_remove_ticket_image(bigint, bigint) TO :"runtime_role";
COMMIT;
