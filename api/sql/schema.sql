
CREATE TABLE public.job_depends (
    parent integer NOT NULL,
    child integer NOT NULL
);

CREATE TABLE public.jobs (
    id integer NOT NULL,
    queued timestamp without time zone DEFAULT (now())::timestamp without time zone NOT NULL,
    processing timestamp without time zone,
    returned timestamp without time zone,
    type character varying,
    variables jsonb,
    requirements jsonb,
    result jsonb,
    uid character varying,
    claimed character varying,
    status character varying DEFAULT 'submitted'::character varying NOT NULL
);

CREATE SEQUENCE public.jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;
ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);
ALTER TABLE ONLY public.jobs ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.job_depends
    ADD CONSTRAINT job_depends_child_fkey FOREIGN KEY (child) REFERENCES public.jobs(id);
ALTER TABLE ONLY public.job_depends
    ADD CONSTRAINT job_depends_parent_fkey FOREIGN KEY (parent) REFERENCES public.jobs(id);

