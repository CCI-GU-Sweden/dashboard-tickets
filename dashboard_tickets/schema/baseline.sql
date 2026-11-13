-- Ticket tables baseline. Apply via setup_ticket_schema, not directly.
CREATE TABLE public.ticket_equipment (
    equipment_id varchar(100) PRIMARY KEY,
    name varchar(200) NOT NULL,
    category varchar(100) NOT NULL,
    active boolean NOT NULL DEFAULT true,
    CONSTRAINT ticket_equipment_id_nonempty CHECK (length(trim(equipment_id)) > 0),
    CONSTRAINT ticket_equipment_name_nonempty CHECK (length(trim(name)) > 0),
    CONSTRAINT ticket_equipment_category_nonempty CHECK (length(trim(category)) > 0)
);
COMMENT ON TABLE public.ticket_equipment IS
    'Equipment catalogue for ticket selection; inactive items remain available for history.';
CREATE UNIQUE INDEX ticket_equipment_name_uq ON public.ticket_equipment (lower(name));


-- Current ticket state and immutable event history.
CREATE TABLE public.microscope_ticket (
    ticket_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reporter_name varchar(200) NOT NULL
        CHECK (char_length(btrim(reporter_name)) > 0),
    reporter_identifier varchar(254),
    microscope varchar(150)
        CHECK (microscope IS NULL OR char_length(btrim(microscope)) > 0),
    message text NOT NULL
        CHECK (char_length(btrim(message)) > 0 AND char_length(message) <= 20000),
    ticket_type varchar(30) NOT NULL DEFAULT 'USER_REQUEST'
        CHECK (ticket_type IN ('USER_REQUEST', 'USER_REPORT', 'INTERNAL_ISSUE', 'INCIDENT')),
    issue_type varchar(30)
        CHECK (issue_type IN (
            'SOFTWARE', 'HARDWARE', 'CONNECTION', 'ACCESS_PERMISSIONS',
            'ACQUISITION_IMAGE_QUALITY', 'OTHER'
        )),
    priority varchar(10) NOT NULL DEFAULT 'NORMAL'
        CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'CRITICAL')),
    source varchar(20) NOT NULL
        CHECK (source IN ('CONTACT_FORM', 'DASHBOARD')),
    source_event_id varchar(200)
        CHECK (source_event_id IS NULL OR char_length(btrim(source_event_id)) > 0),
    status varchar(20) NOT NULL DEFAULT 'OPEN'
        CHECK (status IN ('OPEN', 'IN_PROGRESS', 'WAITING', 'RESOLVED', 'CANCELLED')),
    opened_at timestamptz NOT NULL DEFAULT now(),
    resolved_at timestamptz,
    resolution_note text CHECK (
        resolution_note IS NULL
        OR (char_length(btrim(resolution_note)) > 0
            AND char_length(resolution_note) <= 2000)
    ),
    assigned_to varchar(200),
    chat_thread_id varchar(200),
    chat_url text CHECK (char_length(chat_url) <= 2000),
    chat_state varchar(20) NOT NULL DEFAULT 'NOT_REQUESTED'
        CHECK (chat_state IN ('NOT_REQUESTED', 'PENDING', 'OPEN', 'FAILED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by varchar(200) NOT NULL CHECK (char_length(btrim(created_by)) > 0),
    updated_by varchar(200) NOT NULL CHECK (char_length(btrim(updated_by)) > 0),
    version integer NOT NULL DEFAULT 1 CHECK (version > 0),
    CONSTRAINT microscope_ticket_source_event_uq UNIQUE (source, source_event_id),
    CONSTRAINT microscope_ticket_resolution_state_ck CHECK (
        (status = 'RESOLVED' AND resolved_at IS NOT NULL)
        OR
        (status <> 'RESOLVED' AND resolved_at IS NULL)
    ),
    CONSTRAINT microscope_ticket_closing_note_state_ck CHECK (
        status IN ('RESOLVED', 'CANCELLED') OR resolution_note IS NULL
    ),
    CONSTRAINT microscope_ticket_resolution_time_ck CHECK (
        resolved_at IS NULL OR resolved_at >= opened_at
    ),
    CONSTRAINT microscope_ticket_update_time_ck CHECK (updated_at >= created_at)
);

CREATE INDEX microscope_ticket_opened_idx
    ON public.microscope_ticket (opened_at DESC, ticket_id DESC);
CREATE INDEX microscope_ticket_status_opened_idx
    ON public.microscope_ticket (status, opened_at DESC, ticket_id DESC);
CREATE INDEX microscope_ticket_microscope_opened_idx
    ON public.microscope_ticket (microscope, opened_at DESC, ticket_id DESC);
CREATE INDEX microscope_ticket_resolved_idx
    ON public.microscope_ticket (resolved_at DESC, ticket_id DESC)
    WHERE resolved_at IS NOT NULL;

CREATE TABLE public.microscope_ticket_event (
    event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id bigint NOT NULL REFERENCES public.microscope_ticket(ticket_id),
    event_type varchar(30) NOT NULL
        CHECK (event_type IN ('CREATED', 'STATUS_CHANGED', 'UPDATED', 'CHAT_UPDATED')),
    old_status varchar(20)
        CHECK (old_status IN ('OPEN', 'IN_PROGRESS', 'WAITING', 'RESOLVED', 'CANCELLED')),
    new_status varchar(20)
        CHECK (new_status IN ('OPEN', 'IN_PROGRESS', 'WAITING', 'RESOLVED', 'CANCELLED')),
    note text CHECK (char_length(note) <= 2000),
    changes jsonb NOT NULL DEFAULT '{}'::jsonb
        CHECK (jsonb_typeof(changes) = 'object'),
    actor varchar(200) NOT NULL CHECK (char_length(btrim(actor)) > 0),
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX microscope_ticket_event_history_idx
    ON public.microscope_ticket_event (ticket_id, occurred_at, event_id);

-- Optional small PNG/JPEG attachments; one ticket can have several images.
CREATE TABLE public.microscope_ticket_image (
    image_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id bigint NOT NULL
        REFERENCES public.microscope_ticket(ticket_id) ON DELETE RESTRICT,
    filename varchar(255) NOT NULL
        CHECK (char_length(btrim(filename)) > 0),
    extension varchar(4) NOT NULL
        CHECK (extension IN ('png', 'jpg', 'jpeg')),
    image_data bytea NOT NULL,
    CONSTRAINT microscope_ticket_image_size_ck CHECK (
        octet_length(image_data) BETWEEN 1 AND 5242880
    ),
    CONSTRAINT microscope_ticket_image_signature_ck CHECK (
        (extension = 'png'
            AND substring(image_data FROM 1 FOR 8) = decode('89504e470d0a1a0a', 'hex'))
        OR
        (extension IN ('jpg', 'jpeg')
            AND substring(image_data FROM 1 FOR 3) = decode('ffd8ff', 'hex'))
    )
);

CREATE INDEX microscope_ticket_image_ticket_idx
    ON public.microscope_ticket_image (ticket_id, image_id);

