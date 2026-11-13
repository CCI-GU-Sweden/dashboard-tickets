-- Installed only after collision checks by setup_ticket_helpers.
CREATE FUNCTION public.dashboard_purge_archived_ticket(p_ticket_id bigint)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $$
BEGIN
    PERFORM 1 FROM public.microscope_ticket WHERE ticket_id = p_ticket_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Ticket not found'; END IF;
    IF NOT EXISTS (SELECT 1 FROM public.accounts_ticketarchive WHERE ticket_id = p_ticket_id) THEN
        RAISE EXCEPTION 'Ticket is not archived';
    END IF;
    DELETE FROM public.microscope_ticket_image WHERE ticket_id = p_ticket_id;
    DELETE FROM public.microscope_ticket_event WHERE ticket_id = p_ticket_id;
    DELETE FROM public.microscope_ticket WHERE ticket_id = p_ticket_id;
END;
$$;
REVOKE ALL ON FUNCTION public.dashboard_purge_archived_ticket(bigint) FROM PUBLIC;

CREATE FUNCTION public.dashboard_remove_ticket_image(p_ticket_id bigint, p_image_id bigint)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $$
BEGIN
    PERFORM 1 FROM public.microscope_ticket WHERE ticket_id = p_ticket_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Ticket not found'; END IF;
    IF EXISTS (SELECT 1 FROM public.accounts_ticketarchive WHERE ticket_id = p_ticket_id) THEN
        RAISE EXCEPTION 'Ticket is archived';
    END IF;
    DELETE FROM public.microscope_ticket_image WHERE ticket_id = p_ticket_id AND image_id = p_image_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Image not found'; END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.dashboard_remove_ticket_image(bigint, bigint) FROM PUBLIC;
