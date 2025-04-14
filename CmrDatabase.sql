--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: issue_state; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.issue_state AS ENUM (
    'CLOSED',
    'OPEN',
    'NEW'
);


ALTER TYPE public.issue_state OWNER TO postgres;

--
-- Name: role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.role AS ENUM (
    'USER',
    'ADMIN'
);


ALTER TYPE public.role OWNER TO postgres;

--
-- Name: sender; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.sender AS ENUM (
    'CUSTOMER',
    'SUPPORT',
    'BOT'
);


ALTER TYPE public.sender OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: companies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.companies (
    id integer NOT NULL,
    name character varying
);


ALTER TABLE public.companies OWNER TO postgres;

--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.companies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.companies_id_seq OWNER TO postgres;

--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: issues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.issues (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    company_id integer,
    customer_email character varying NOT NULL,
    subject character varying,
    state public.issue_state NOT NULL,
    title character varying,
    created timestamp without time zone NOT NULL
);


ALTER TABLE public.issues OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    issue_id uuid NOT NULL,
    message text NOT NULL,
    sender public.sender NOT NULL,
    username character varying NOT NULL,
    "time" timestamp without time zone NOT NULL
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: companies_issues; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.companies_issues AS
 SELECT i.id,
    c.name AS company_name,
    i.customer_email,
    i.subject,
    i.state,
    i.title,
    i.created,
    m."time" AS latest
   FROM ((public.issues i
     JOIN public.companies c ON ((i.company_id = c.id)))
     JOIN ( SELECT messages.issue_id,
            max(messages."time") AS "time"
           FROM public.messages
          GROUP BY messages.issue_id) m ON ((i.id = m.issue_id)));


ALTER VIEW public.companies_issues OWNER TO postgres;

--
-- Name: issue_messages; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.issue_messages AS
 SELECT m.id,
    m.issue_id,
    m.message,
    m.sender,
    m.username,
    m."time"
   FROM (public.messages m
     JOIN public.issues i ON ((m.issue_id = i.id)))
  ORDER BY m.id;


ALTER VIEW public.issue_messages OWNER TO postgres;

--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_id_seq OWNER TO postgres;

--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subjects (
    id integer NOT NULL,
    company_id integer,
    name character varying
);


ALTER TABLE public.subjects OWNER TO postgres;

--
-- Name: subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subjects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subjects_id_seq OWNER TO postgres;

--
-- Name: subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subjects_id_seq OWNED BY public.subjects.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying,
    password character varying,
    role public.role,
    email character varying,
    company integer NOT NULL,
    firstname character varying,
    lastname character varying
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_with_company; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.users_with_company AS
 SELECT u.id AS user_id,
    u.firstname,
    u.lastname,
    u.username,
    u.password,
    u.email,
    u.role,
    c.id AS company_id,
    c.name AS company_name
   FROM (public.users u
     JOIN public.companies c ON ((u.company = c.id)));


ALTER VIEW public.users_with_company OWNER TO postgres;

--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: subjects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects ALTER COLUMN id SET DEFAULT nextval('public.subjects_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.companies (id, name) FROM stdin;
1	Demo AB
2	Test AB
\.


--
-- Data for Name: issues; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.issues (id, company_id, customer_email, subject, state, title, created) FROM stdin;
7bab65b7-7ff1-4119-aa34-3d537848d0a2	1	m@email.com	Skada	NEW	Test	2025-04-07 11:46:28.590383
bc7a9974-24c7-49e8-9ea6-14537da597aa	1	tim.bjorkegren@gmail.com	Reklamation	NEW	Hjälppppppp	2025-04-07 11:49:32.683696
c09dc94a-73b3-4505-aaac-c9ff0c8ffde0	1	m@email.com	Skada	NEW	Test	2025-04-07 11:57:28.178926
c4812c45-217c-4563-b6a2-f912a704afc3	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 11:58:04.73622
9624f0e1-4375-4866-af77-1a3e9357d77d	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:23:35.271265
8c6509d3-bb72-42c4-96ed-b98e1e4d806f	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:24:13.095774
95174724-b419-457e-b2d9-1cfdb0e382f3	1	linus@nodehill.com	Test	CLOSED	Test Issue	2025-03-17 16:32:07
46307946-bf0d-48fa-9900-9bc367d995aa	1	tim.bjorkegren@gmail.com	Skada	CLOSED	My computer is broken	2025-04-07 11:51:59.137209
75e2e748-f7c4-49da-bfe5-d1a9907f4bd4	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 12:23:35.147172
2267797a-d564-40fa-878e-a57b66c33e76	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 12:25:01.648305
e9077323-08f8-4eb8-a035-439e35bba118	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 12:41:06.811538
5be206c5-dc51-49eb-9737-7f8f1fbeb4f9	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 12:49:22.012636
6072c6c5-c1a1-4967-ba27-2cee07663575	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 12:52:45.84716
168a53c3-99e4-419c-b842-96d53c898985	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:24:33.512948
8d64e656-1599-4b68-a3ab-218cee46ae3a	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:00:29.642322
5f1f3181-1cb0-4832-b660-ac1caeeceae8	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 23:39:51.579831
c00933e1-d5fc-49eb-8e96-0b60124af962	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:00:59.547333
ddfca7c5-fcb3-46f7-8bc9-acf43a9f37bd	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 14:42:57.508577
0e6d2d3e-1e4e-4659-a8f4-9520fda6005b	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:07:40.530443
9f8309d9-915c-474c-bfd8-6f5ee7fdf288	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:34.057332
0a568019-c6f8-4858-a68a-4d9b599fa0d5	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:31:19.019051
30462272-a4c5-4efb-8a80-7016b8f86e9e	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:31:46.454627
847f9210-0b52-43c7-b781-51d9cdb698a9	1	testlol@gmai.com	Reklamation	OPEN	dishwasheeeerr	2025-04-08 00:39:10.506977
8366011b-7d9b-4712-a884-363924a374c6	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:39:23.459295
5d2c2731-d601-4755-acfe-738b2dac19a1	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 10:51:04.662787
98350c9a-247a-460a-b9ef-491176964776	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:42:52.841332
2e29c727-5e82-43bc-97f8-a8d574736515	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 10:52:24.142967
9e5caf19-b637-4f78-9145-a8ac8f5e49f5	1	linus@nodehill.com	Övrigt	OPEN	Test Issue 2	2025-03-17 10:05:37
aae0fb2a-6b8a-4d96-8b69-65567efbdfab	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:44:13.495849
e1b3d954-2124-4187-b7f5-34dfb626da8a	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:44:45.909837
5bf49a76-8e63-407b-98b1-6adddd5755e0	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 10:59:59.496287
9e789eb8-b2b1-411b-ac3f-1adf02d9cef6	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:52:15.061014
bbf28639-7de1-44f2-937e-291f5d0f7d8c	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:22:31.296223
177c945e-4293-4d58-a902-40a87b040ff3	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 11:16:14.468853
92e679b7-aae7-45cd-b35d-3595d0f24dc3	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 13:54:41.003341
58d84374-0d30-4ed8-a4c9-000ef8d868e9	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 15:14:34.670247
df200085-3de8-426a-8e46-c2cbf53cff33	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:39.758528
897e109d-700b-4371-9ea7-0d3c6602734f	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 15:15:09.488501
65151ce3-854f-49d8-b386-0cc76de2d2e7	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:13.100577
48e14b8b-f28c-47d7-931c-8630ec4c0a1f	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 15:30:53.837347
ee793533-f975-4c51-82fc-f35dcccb550c	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 11:18:15.735532
e715ae99-5c4c-4ef2-b0a7-ce452b441fdd	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 15:32:37.372978
d01bc9ac-d12b-42a7-a18e-719bc7facaf2	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 11:21:54.818961
36cffbf0-b876-483c-9054-4cc2fbfd2f4f	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 15:33:27.093037
0e278f7f-be28-403f-bb35-59da85d66600	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:35.52442
826887f7-45a6-4459-8cfe-a20903051d42	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 15:34:23.004663
cbf79b3b-76a9-4ce9-b623-dc6956124671	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 11:23:15.155234
4b6c61e4-9694-4230-83e5-2904f91c9d0b	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 15:37:19.506941
62c338f5-f983-4f6b-9827-18d6a4ed24e5	1	tim.bjorkegren@gmail.com	Reklamation	NEW	Tim	2025-04-07 15:39:04.329069
f0ed612a-06b9-41ca-96d9-31d5952ac510	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-07 15:54:40.496885
6bcf6316-d7ea-4686-bfe5-a1eb0ac01c5b	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:28.430501
9f3e23bb-dfd1-4c9c-8866-168974c2f3e1	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:15:48.964952
d75e501f-01c0-432c-8d13-b879d62055a2	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:18:26.885682
fbff4be9-b68f-4b19-a1d5-8cb1538d8ae3	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:20:21.299625
d9513309-b94f-4666-b3b6-31c0116a9594	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:20:38.304154
d6892f08-595b-429c-9e6a-d2facb4794eb	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:21:08.063036
fafff4e7-23e1-4547-b942-101f3a8b1a12	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:21:34.385692
a79753bc-047e-4a72-8c0f-df900e0acc46	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-07 17:23:28.186116
e5bf9e89-0296-49cc-9aba-9c8b199b4b9c	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 11:25:31.509478
3fa7d2eb-2793-4c77-bc03-a13f2d15219f	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:29.904651
4dd01d0d-ad95-455a-9700-ffaf411504e8	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:36.916882
4c383ff8-53d7-46ca-b798-2fa55292bca7	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 11:28:06.980221
e9c9efd9-76a0-41bb-8c20-b40679940022	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 11:33:00.10875
834508de-bdf0-44b6-a15c-ab87e7e8b789	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:31.277361
e96f2669-44ec-488b-89be-d914825d9817	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 14:22:17.301693
e3f1cec3-db9a-482e-b28f-d8f3f6a3a1b2	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:41.180342
2b3c2604-69c1-4bc2-a950-a37018e8d53b	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:42.578585
72ff8cf3-06b6-427a-8e3c-ad95ce115b77	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-08 14:41:12.128732
da357dab-50bd-4c91-9ddd-7f0c3a8e7243	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:32.663055
c76d0c75-f313-4b2d-85db-418294babf48	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:38.374616
e7030985-749a-434e-a1c5-8e3c536304d8	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:43.952566
312891b4-7618-40bd-bb10-cc1d2074e411	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:45.369376
2c3a1898-8232-4cb8-87f6-56a4ace78e90	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:46.783493
3a472a87-6669-4d2f-a62c-0b7982dde908	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:48.115436
ca1d9a1b-4f1d-40f9-83bb-56ae73d47d4d	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:49.578481
d8090cba-860e-436f-a739-9ee70331762b	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:51.005455
9720c377-be0c-4a93-b0b3-23aa08fc4c70	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:52.699438
aca66a11-89f7-4aa5-8610-3fec248a132d	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:23:54.212675
950994eb-7bf8-4220-9fd4-4576817d753d	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:27:01.740341
aaba91b2-9272-42a7-a214-3fe212d059a2	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman	2025-04-09 14:52:57.14529
e8d9657a-7c2d-439c-88fb-877d00de6efc	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1	2025-04-09 15:07:24.250086
e5e2476e-f311-4dcf-93c1-dd22f8dbf595	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-09 15:21:39.121656
cf1c1e38-d7e6-4027-aa7d-998c68e0d494	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-09 15:22:27.564123
a36d2080-889f-46d0-bf3a-3af76ca9591e	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-09 15:24:11.583892
60d35b16-bfaf-4bbe-b5de-6661f7e633e1	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-09 15:24:58.512886
5033e704-b149-4c63-bcd2-3a15f800ad6c	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-09 15:25:01.076306
801e6211-4368-446f-abad-6fb56b2f2c16	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-09 15:27:32.238333
44e5faf7-e49a-4b26-9e44-9fc4ebd96dab	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-09 15:29:09.127074
0fee5c51-856a-4092-88a9-de7075960aca	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-09 15:30:06.255882
18d88864-2f06-4c71-9361-68103f0920b7	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 12:25:01.078699
5d67a038-3e3d-4390-b804-65b9483d4966	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 12:27:22.618744
785c6e88-9c7b-4c9c-8b7a-01449030feb7	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 12:39:16.841464
21ec360b-d381-40c1-9725-692ef62fa6cf	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 12:40:39.960043
28052e6b-8d88-4268-98cc-82e28bb6e960	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 12:42:46.278189
5175f68b-a151-40cd-9746-6cc6c57f9e0c	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 12:49:31.545068
77496e22-fe5a-4b49-830c-a08dd15300a8	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 12:51:45.446677
7795a8b4-2f6d-4efe-a6c4-28c5cb4e4e92	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 13:09:35.970417
b4e13a0d-16ec-48c0-9590-0c22df6d8b82	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 13:11:48.114322
3c20aa94-c02e-49c5-b6a4-86518f37e8da	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 13:13:31.765582
279bf366-8414-491d-8e51-44aa10f81078	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 13:15:57.991789
05d7bea4-0297-41e1-ba2e-bcd08d4b7900	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 13:17:41.298638
e878cf01-1a84-4f91-ad8f-98724139db37	2	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-10 13:18:44.760197
e4f4bf48-ac25-4929-b4a2-cb09aec99a0f	1	tim.bjorkegren@email.com	Skada	NEW	Test	2025-04-13 11:38:23.789962
b8721ed0-f128-4b73-b621-372f4312d30c	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:33.925193
4109723d-531a-45c4-8bec-09b53b10a138	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:36.580132
60604563-5bf3-42dd-ad2b-42e84baac743	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:38.523962
3407c57e-360a-46f2-ab32-a4712472d176	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:40.540687
dd92652f-7284-4533-af7e-af8f1be0adef	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:42.501717
c3b0929c-fa11-4aa8-9efe-c97e5ba62cf4	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:44.429745
51d52fb9-efe6-4218-87af-90c59d6921cc	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:46.366346
4632c554-724a-4814-bb8e-f8d643b41dda	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:48.559118
e1bf4c19-ec22-4216-a0a6-47a548d43aaa	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:51.421829
fda4ddbc-b086-4e1d-a922-5957a565f2d7	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:53.462736
4f71fa2a-90be-4e9b-8bcc-1a43bdbd6063	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:55.492106
d1418f0d-6d55-4310-a66c-c55bb7ecc7a2	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:00:58.326528
019149fe-2374-40d6-a753-dd55db35584f	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:01:00.322657
e605ca46-badd-46bf-8fd6-ddeec854bec3	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:01:02.424711
2e18e20f-be18-4436-9252-8e52b2a9c582	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:01:05.381164
d02a9ab9-a92b-4c8d-aebe-eebdefe80b2b	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:01:07.70621
be6fa7d2-722b-43d4-a239-a044591547ab	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:01:09.757222
aa41adb0-81ee-4d03-b2fd-886c442393c3	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:01:12.878958
2dff5a42-192b-4379-949f-30ce8bcc31cb	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:01:15.837453
454c5190-0b9d-47b5-82f5-5d9114c2d3f3	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:01:18.004415
6b3a3571-2147-45c6-9d58-9f3390d150c1	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 13:08:21.824143
ee87c022-2c18-4ec2-a094-91ad6586a947	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:25.396484
d79a5781-375c-4bd2-b84f-dda56a8926ac	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:28.374737
2969062d-373c-4ec8-9e17-8c37bab78183	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:30.963856
3d8bd309-e6ae-4677-99e3-dce6bc6fc9ee	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:33.751783
d6761fe8-2cfa-4a88-bf29-190fe5524aca	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:36.509783
fb05f356-dd9e-4b7b-a09e-afa0ccd407b6	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:39.380694
29958376-8c94-499e-9097-827bc883890e	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:42.251208
25665b30-9773-4d09-99d5-afc85ca93e5f	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:45.791979
636b4e6e-8e30-492d-93c2-d9a3095afb29	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:48.580664
192a4d16-12dc-469f-a2d9-5d8ea0a62c67	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:51.391821
0b5c1ea7-bb15-43a9-8d35-531329cb6a2a	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:54.107188
59476f26-876f-4957-856c-403fbb3ce333	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:56.801677
6bf651c7-54d0-4a16-bfa8-3ebfae7ed87d	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:17:59.546147
b749e141-9d04-4590-85ac-74b8d5b7e148	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:18:02.294316
0f28c5eb-2617-4000-8250-3c6fe07f94f0	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:18:05.101041
04ea0883-89a3-4416-b918-067962d75ff2	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:18:07.86172
04cccd36-064f-4e7a-b43b-8c85626274a7	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:18:10.557911
799dafbe-3ff5-440a-988b-b0b2472ad244	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:18:13.335381
4f063d08-56d4-498c-a4d5-97b1fcef9b0e	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:18:16.068422
58334a4a-00ef-4dff-8610-3fb83e98b11e	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:18:18.860407
d846d264-0303-41f4-ae52-704e829b0df5	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:09.515999
eb3d8268-2004-496f-a67d-0b61433e85ad	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:12.142425
40c4bb6c-90c7-4b1a-9fb7-7c7e65e0ee24	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:14.914977
bfd3315d-65b4-49ca-b43c-51db4c4d667a	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:17.695182
27f63001-4c07-4fd5-be9a-4672fdf8ac66	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:21.187723
c994fe5c-ac0e-404e-aa2a-d0789d1c3863	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:24.005727
bbb73699-fbb8-4f24-88fc-581c218c6806	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:27.469471
e7e823eb-4f57-404d-a4ad-0c11aaf92214	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:30.302732
08163a15-8d8f-4bc8-a561-4ba5eae447cc	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:33.010954
22d7b1d6-c6f7-4936-b5ae-6de033c8711b	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:36.006656
5c9e2142-d1bb-4dbf-8a02-5f25275c8aa7	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:38.74951
37c343c8-8950-4b9a-a347-42f01ef6aff7	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:41.507432
f3d3bbfc-7162-4246-8122-365e76d724ad	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:44.16159
3aeb47cb-5fdf-41c2-974a-40dd4846cfe7	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:47.015113
a385691f-187f-4fc3-835e-9da68ad19c9b	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:49.760019
68cf08ff-2c3f-44e0-9420-801a5509ab20	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:52.559585
013f3538-e095-4a1f-9c82-3b2fdd02ed45	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:56.190964
67f75842-44bb-4c7c-ae5a-5cc1eea868c7	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:21:59.112598
a25eb8dc-333b-4ada-855e-0e74b10a223c	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:22:01.992397
f586ca96-585f-41ee-9fa4-2aba301472f0	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:22:04.756413
f821f05c-0d2d-4377-98fa-70169134d5e9	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:22:07.412873
e0d716ec-bcf9-4374-a506-2d2996150e2f	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:22:10.832633
fcdc355e-3e4b-41ab-8575-b646046f53e7	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:30:15.961417
101fe150-79e1-48cd-b0a8-f5d50d2d5c3d	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:30:18.975564
0c41c8d4-f214-4932-9a83-0dfe73c37656	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:30:21.731944
f1020312-9708-414b-852b-fe4224fe0e6b	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:30:24.816023
101041f5-5a48-48e4-a9dc-e20c9c53568d	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:30:27.590483
6112de44-7aeb-4045-8c73-f434638ac9a0	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:32:36.412369
c5a84924-52ff-49cd-9b9f-72d8ad05bf96	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:32:39.191019
91ba9740-c789-49a4-9eaf-edff6960218b	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:32:41.951693
d3fd37f0-8ced-4b20-9638-803c3fba212f	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:32:44.868171
ceee17f3-5cd9-4c35-89cd-13bee77a1630	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:32:47.875709
e4e2d552-e2e9-458e-bc48-110f95fc71eb	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:33:35.190356
15a6bf22-aa35-41e5-bc01-0459f80d0dd7	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:33:38.031083
4a27cabc-0a0f-4bd6-8aa4-97472575514d	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:33:40.779781
40ad61b8-4539-462b-a630-aebbeef04684	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:33:43.647287
36d8bc9a-3241-4455-98a1-342416b8c078	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:33:46.5207
b4abed30-f439-4461-ba17-5494f5e64af4	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:36:17.36245
16f87c41-efb4-4ec6-8c74-2ad37a6bf9bd	1	tim.bjorkegren@gmail.com	Övrigt	NEW	Test for postman TEST1111	2025-04-14 15:36:20.265687
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, issue_id, message, sender, username, "time") FROM stdin;
1	95174724-b419-457e-b2d9-1cfdb0e382f3	Some message.	CUSTOMER	Linus@email.test	2025-03-17 10:05:37
2	9e5caf19-b637-4f78-9145-a8ac8f5e49f5	This is just a test.	CUSTOMER	linus.lindroth.92@gmail.com	2025-03-17 16:32:07
3	95174724-b419-457e-b2d9-1cfdb0e382f3	 Lorem ipsum dolor sit amet consectetur adipisicing elit. Quo corporis nemo error provident eligendi consequuntur cum aliquam placeat aspernatur amet dolore ut quasi impedit culpa laboriosam suscipit, nobis natus nesciunt. Aliquam exercitationem facere in cupiditate voluptates voluptatum, perspiciatis est quidem dolores veniam magnam atque vitae. Rerum aut id delectus debitis exercitationem eos harum perspiciatis, voluptatem tenetur officiis libero aliquam iste. Repellendus autem placeat hic odit dignissimos. Blanditiis odio, facilis sequi ratione repudiandae iusto, distinctio reiciendis consectetur deleniti eius fugit numquam laborum nobis quasi magnam cupiditate laudantium illo, provident labore. Impedit.	CUSTOMER	Linus@email.test	2025-03-18 10:08:02
13	7bab65b7-7ff1-4119-aa34-3d537848d0a2	Hello i need help with my dishwasher please help me sir	CUSTOMER	m@email.com	2025-04-07 11:46:28.595482
14	bc7a9974-24c7-49e8-9ea6-14537da597aa	dwdawdwadadadawdaw	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 11:49:32.688879
15	46307946-bf0d-48fa-9900-9bc367d995aa	the computer i got from you are broken i need a refund please	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 11:51:59.139171
16	c09dc94a-73b3-4505-aaac-c9ff0c8ffde0	Hello i need help with my dishwasher please help me sir	CUSTOMER	m@email.com	2025-04-07 11:57:28.184558
17	c4812c45-217c-4563-b6a2-f912a704afc3	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 11:58:04.740657
18	75e2e748-f7c4-49da-bfe5-d1a9907f4bd4	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 12:23:35.157018
19	2267797a-d564-40fa-878e-a57b66c33e76	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 12:25:01.65297
20	e9077323-08f8-4eb8-a035-439e35bba118	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 12:41:06.822173
21	5be206c5-dc51-49eb-9737-7f8f1fbeb4f9	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 12:49:22.022216
22	6072c6c5-c1a1-4967-ba27-2cee07663575	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 12:52:45.856158
23	8d64e656-1599-4b68-a3ab-218cee46ae3a	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:00:29.650996
24	c00933e1-d5fc-49eb-8e96-0b60124af962	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:00:59.552478
25	0e6d2d3e-1e4e-4659-a8f4-9520fda6005b	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:07:40.538686
26	0a568019-c6f8-4858-a68a-4d9b599fa0d5	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:31:19.028199
27	30462272-a4c5-4efb-8a80-7016b8f86e9e	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:31:46.460843
28	8366011b-7d9b-4712-a884-363924a374c6	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:39:23.468833
29	98350c9a-247a-460a-b9ef-491176964776	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:42:52.8475
30	aae0fb2a-6b8a-4d96-8b69-65567efbdfab	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:44:13.498323
31	e1b3d954-2124-4187-b7f5-34dfb626da8a	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:44:45.918229
32	9e789eb8-b2b1-411b-ac3f-1adf02d9cef6	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:52:15.068618
33	92e679b7-aae7-45cd-b35d-3595d0f24dc3	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 13:54:41.005918
34	58d84374-0d30-4ed8-a4c9-000ef8d868e9	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 15:14:34.682548
35	897e109d-700b-4371-9ea7-0d3c6602734f	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 15:15:09.495108
36	48e14b8b-f28c-47d7-931c-8630ec4c0a1f	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 15:30:53.848563
37	e715ae99-5c4c-4ef2-b0a7-ce452b441fdd	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 15:32:37.379996
38	36cffbf0-b876-483c-9054-4cc2fbfd2f4f	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 15:33:27.096057
39	826887f7-45a6-4459-8cfe-a20903051d42	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 15:34:23.006885
40	4b6c61e4-9694-4230-83e5-2904f91c9d0b	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 15:37:19.513749
41	62c338f5-f983-4f6b-9827-18d6a4ed24e5	dwadwadadwadwad	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 15:39:04.331723
42	f0ed612a-06b9-41ca-96d9-31d5952ac510	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-07 15:54:40.505788
43	9f3e23bb-dfd1-4c9c-8866-168974c2f3e1	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:15:49.003934
44	d75e501f-01c0-432c-8d13-b879d62055a2	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:18:26.920861
45	fbff4be9-b68f-4b19-a1d5-8cb1538d8ae3	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:20:21.304473
46	d9513309-b94f-4666-b3b6-31c0116a9594	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:20:38.335327
47	d6892f08-595b-429c-9e6a-d2facb4794eb	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:21:08.093896
48	fafff4e7-23e1-4547-b942-101f3a8b1a12	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:21:34.416659
49	a79753bc-047e-4a72-8c0f-df900e0acc46	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:23:28.220679
50	9624f0e1-4375-4866-af77-1a3e9357d77d	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:23:35.29635
51	8c6509d3-bb72-42c4-96ed-b98e1e4d806f	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:24:13.12667
52	168a53c3-99e4-419c-b842-96d53c898985	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 17:24:33.544352
53	5f1f3181-1cb0-4832-b660-ac1caeeceae8	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-07 23:39:51.589117
54	847f9210-0b52-43c7-b781-51d9cdb698a9	dwdawdwaddwdada	CUSTOMER	testlol@gmai.com	2025-04-08 00:39:10.51331
55	5d2c2731-d601-4755-acfe-738b2dac19a1	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 10:51:04.677726
56	2e29c727-5e82-43bc-97f8-a8d574736515	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 10:52:24.152731
57	5bf49a76-8e63-407b-98b1-6adddd5755e0	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 10:59:59.50478
58	177c945e-4293-4d58-a902-40a87b040ff3	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 11:16:14.484575
59	ee793533-f975-4c51-82fc-f35dcccb550c	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 11:18:15.741164
60	d01bc9ac-d12b-42a7-a18e-719bc7facaf2	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 11:21:54.820769
61	cbf79b3b-76a9-4ce9-b623-dc6956124671	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 11:23:15.162019
62	e5bf9e89-0296-49cc-9aba-9c8b199b4b9c	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 11:25:31.512431
63	4c383ff8-53d7-46ca-b798-2fa55292bca7	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 11:28:06.988823
64	e9c9efd9-76a0-41bb-8c20-b40679940022	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 11:33:00.114872
65	e96f2669-44ec-488b-89be-d914825d9817	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 14:22:17.309306
66	72ff8cf3-06b6-427a-8e3c-ad95ce115b77	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 14:41:12.139121
67	ddfca7c5-fcb3-46f7-8bc9-acf43a9f37bd	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-08 14:42:57.51725
68	bbf28639-7de1-44f2-937e-291f5d0f7d8c	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:22:31.318611
69	65151ce3-854f-49d8-b386-0cc76de2d2e7	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:13.102537
70	6bcf6316-d7ea-4686-bfe5-a1eb0ac01c5b	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:28.43248
71	3fa7d2eb-2793-4c77-bc03-a13f2d15219f	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:29.906023
72	834508de-bdf0-44b6-a15c-ab87e7e8b789	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:31.278835
73	da357dab-50bd-4c91-9ddd-7f0c3a8e7243	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:32.665041
74	9f8309d9-915c-474c-bfd8-6f5ee7fdf288	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:34.059983
75	0e278f7f-be28-403f-bb35-59da85d66600	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:35.526334
76	4dd01d0d-ad95-455a-9700-ffaf411504e8	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:36.918468
77	c76d0c75-f313-4b2d-85db-418294babf48	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:38.376559
78	df200085-3de8-426a-8e46-c2cbf53cff33	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:39.761144
79	e3f1cec3-db9a-482e-b28f-d8f3f6a3a1b2	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:41.182156
80	2b3c2604-69c1-4bc2-a950-a37018e8d53b	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:42.580191
81	e7030985-749a-434e-a1c5-8e3c536304d8	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:43.954274
82	312891b4-7618-40bd-bb10-cc1d2074e411	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:45.370888
83	2c3a1898-8232-4cb8-87f6-56a4ace78e90	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:46.785035
84	3a472a87-6669-4d2f-a62c-0b7982dde908	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:48.11774
85	ca1d9a1b-4f1d-40f9-83bb-56ae73d47d4d	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:49.580066
86	d8090cba-860e-436f-a739-9ee70331762b	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:51.007924
87	9720c377-be0c-4a93-b0b3-23aa08fc4c70	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:52.701886
88	aca66a11-89f7-4aa5-8610-3fec248a132d	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:23:54.214311
89	950994eb-7bf8-4220-9fd4-4576817d753d	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:27:01.749003
90	aaba91b2-9272-42a7-a214-3fe212d059a2	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 14:52:57.15118
91	e8d9657a-7c2d-439c-88fb-877d00de6efc	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 15:07:24.259665
92	e5e2476e-f311-4dcf-93c1-dd22f8dbf595	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 15:21:39.12688
93	cf1c1e38-d7e6-4027-aa7d-998c68e0d494	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 15:22:27.568734
94	a36d2080-889f-46d0-bf3a-3af76ca9591e	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 15:24:11.589545
95	60d35b16-bfaf-4bbe-b5de-6661f7e633e1	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 15:24:58.514752
96	5033e704-b149-4c63-bcd2-3a15f800ad6c	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 15:25:01.081029
97	801e6211-4368-446f-abad-6fb56b2f2c16	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 15:27:32.244581
98	44e5faf7-e49a-4b26-9e44-9fc4ebd96dab	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 15:29:09.134415
99	0fee5c51-856a-4092-88a9-de7075960aca	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-09 15:30:06.257227
100	18d88864-2f06-4c71-9361-68103f0920b7	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 12:25:01.105098
101	5d67a038-3e3d-4390-b804-65b9483d4966	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 12:27:22.631247
102	785c6e88-9c7b-4c9c-8b7a-01449030feb7	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 12:39:16.850482
103	21ec360b-d381-40c1-9725-692ef62fa6cf	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 12:40:39.966204
104	28052e6b-8d88-4268-98cc-82e28bb6e960	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 12:42:46.291164
105	5175f68b-a151-40cd-9746-6cc6c57f9e0c	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 12:49:31.556952
106	77496e22-fe5a-4b49-830c-a08dd15300a8	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 12:51:45.453681
107	7795a8b4-2f6d-4efe-a6c4-28c5cb4e4e92	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 13:09:35.982175
108	b4e13a0d-16ec-48c0-9590-0c22df6d8b82	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 13:11:48.119051
109	3c20aa94-c02e-49c5-b6a4-86518f37e8da	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 13:13:31.767283
110	279bf366-8414-491d-8e51-44aa10f81078	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 13:15:57.998263
111	05d7bea4-0297-41e1-ba2e-bcd08d4b7900	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 13:17:41.301656
112	e878cf01-1a84-4f91-ad8f-98724139db37	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-10 13:18:44.762271
113	e4f4bf48-ac25-4929-b4a2-cb09aec99a0f	Hello i need help with my dishwasher please help me sir	CUSTOMER	tim.bjorkegren@email.com	2025-04-13 11:38:23.804958
114	b8721ed0-f128-4b73-b621-372f4312d30c	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:33.936313
115	4109723d-531a-45c4-8bec-09b53b10a138	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:36.581489
116	60604563-5bf3-42dd-ad2b-42e84baac743	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:38.525265
117	3407c57e-360a-46f2-ab32-a4712472d176	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:40.545303
118	dd92652f-7284-4533-af7e-af8f1be0adef	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:42.506428
119	c3b0929c-fa11-4aa8-9efe-c97e5ba62cf4	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:44.431335
120	51d52fb9-efe6-4218-87af-90c59d6921cc	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:46.369764
121	4632c554-724a-4814-bb8e-f8d643b41dda	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:48.562038
122	e1bf4c19-ec22-4216-a0a6-47a548d43aaa	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:51.426128
123	fda4ddbc-b086-4e1d-a922-5957a565f2d7	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:53.467241
124	4f71fa2a-90be-4e9b-8bcc-1a43bdbd6063	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:55.494293
125	d1418f0d-6d55-4310-a66c-c55bb7ecc7a2	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:00:58.327785
126	019149fe-2374-40d6-a753-dd55db35584f	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:01:00.324481
127	e605ca46-badd-46bf-8fd6-ddeec854bec3	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:01:02.426797
128	2e18e20f-be18-4436-9252-8e52b2a9c582	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:01:05.385709
129	d02a9ab9-a92b-4c8d-aebe-eebdefe80b2b	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:01:07.707545
130	be6fa7d2-722b-43d4-a239-a044591547ab	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:01:09.763795
131	aa41adb0-81ee-4d03-b2fd-886c442393c3	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:01:12.883398
132	2dff5a42-192b-4379-949f-30ce8bcc31cb	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:01:15.842774
133	454c5190-0b9d-47b5-82f5-5d9114c2d3f3	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:01:18.006448
134	6b3a3571-2147-45c6-9d58-9f3390d150c1	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 13:08:21.834086
135	ee87c022-2c18-4ec2-a094-91ad6586a947	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:25.404687
136	d79a5781-375c-4bd2-b84f-dda56a8926ac	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:28.379306
137	2969062d-373c-4ec8-9e17-8c37bab78183	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:30.969041
138	3d8bd309-e6ae-4677-99e3-dce6bc6fc9ee	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:33.756784
139	d6761fe8-2cfa-4a88-bf29-190fe5524aca	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:36.514287
140	fb05f356-dd9e-4b7b-a09e-afa0ccd407b6	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:39.385528
141	29958376-8c94-499e-9097-827bc883890e	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:42.255645
142	25665b30-9773-4d09-99d5-afc85ca93e5f	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:45.796344
143	636b4e6e-8e30-492d-93c2-d9a3095afb29	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:48.58224
144	192a4d16-12dc-469f-a2d9-5d8ea0a62c67	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:51.397315
145	0b5c1ea7-bb15-43a9-8d35-531329cb6a2a	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:54.111637
146	59476f26-876f-4957-856c-403fbb3ce333	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:56.806006
147	6bf651c7-54d0-4a16-bfa8-3ebfae7ed87d	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:17:59.55054
148	b749e141-9d04-4590-85ac-74b8d5b7e148	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:18:02.296076
149	0f28c5eb-2617-4000-8250-3c6fe07f94f0	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:18:05.105785
150	04ea0883-89a3-4416-b918-067962d75ff2	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:18:07.866132
151	04cccd36-064f-4e7a-b43b-8c85626274a7	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:18:10.562616
152	799dafbe-3ff5-440a-988b-b0b2472ad244	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:18:13.340027
153	4f063d08-56d4-498c-a4d5-97b1fcef9b0e	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:18:16.073662
154	58334a4a-00ef-4dff-8610-3fb83e98b11e	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:18:18.865635
155	d846d264-0303-41f4-ae52-704e829b0df5	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:09.532188
156	eb3d8268-2004-496f-a67d-0b61433e85ad	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:12.150707
157	40c4bb6c-90c7-4b1a-9fb7-7c7e65e0ee24	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:14.929569
158	bfd3315d-65b4-49ca-b43c-51db4c4d667a	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:17.703515
159	27f63001-4c07-4fd5-be9a-4672fdf8ac66	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:21.197073
160	c994fe5c-ac0e-404e-aa2a-d0789d1c3863	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:24.014874
161	bbb73699-fbb8-4f24-88fc-581c218c6806	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:27.479282
162	e7e823eb-4f57-404d-a4ad-0c11aaf92214	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:30.314265
163	08163a15-8d8f-4bc8-a561-4ba5eae447cc	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:33.022706
164	22d7b1d6-c6f7-4936-b5ae-6de033c8711b	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:36.019902
165	5c9e2142-d1bb-4dbf-8a02-5f25275c8aa7	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:38.75128
166	37c343c8-8950-4b9a-a347-42f01ef6aff7	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:41.522238
167	f3d3bbfc-7162-4246-8122-365e76d724ad	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:44.17245
168	3aeb47cb-5fdf-41c2-974a-40dd4846cfe7	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:47.028557
169	a385691f-187f-4fc3-835e-9da68ad19c9b	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:49.762056
170	68cf08ff-2c3f-44e0-9420-801a5509ab20	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:52.571334
171	013f3538-e095-4a1f-9c82-3b2fdd02ed45	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:56.198758
172	67f75842-44bb-4c7c-ae5a-5cc1eea868c7	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:21:59.123458
173	a25eb8dc-333b-4ada-855e-0e74b10a223c	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:22:02.005747
174	f586ca96-585f-41ee-9fa4-2aba301472f0	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:22:04.76041
175	f821f05c-0d2d-4377-98fa-70169134d5e9	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:22:07.417928
176	e0d716ec-bcf9-4374-a506-2d2996150e2f	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:22:10.833901
177	fcdc355e-3e4b-41ab-8575-b646046f53e7	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:30:15.965758
178	101fe150-79e1-48cd-b0a8-f5d50d2d5c3d	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:30:18.977091
179	0c41c8d4-f214-4932-9a83-0dfe73c37656	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:30:21.733584
180	f1020312-9708-414b-852b-fe4224fe0e6b	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:30:24.818128
181	101041f5-5a48-48e4-a9dc-e20c9c53568d	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:30:27.591902
182	6112de44-7aeb-4045-8c73-f434638ac9a0	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:32:36.420364
183	c5a84924-52ff-49cd-9b9f-72d8ad05bf96	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:32:39.1928
184	91ba9740-c789-49a4-9eaf-edff6960218b	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:32:41.95432
185	d3fd37f0-8ced-4b20-9638-803c3fba212f	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:32:44.869595
186	ceee17f3-5cd9-4c35-89cd-13bee77a1630	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:32:47.877398
187	e4e2d552-e2e9-458e-bc48-110f95fc71eb	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:33:35.195703
188	15a6bf22-aa35-41e5-bc01-0459f80d0dd7	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:33:38.038967
189	4a27cabc-0a0f-4bd6-8aa4-97472575514d	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:33:40.781308
190	40ad61b8-4539-462b-a630-aebbeef04684	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:33:43.649688
192	b4abed30-f439-4461-ba17-5494f5e64af4	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:36:17.364071
191	36d8bc9a-3241-4455-98a1-342416b8c078	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:33:46.522189
193	16f87c41-efb4-4ec6-8c74-2ad37a6bf9bd	Test for postman tim bjorkegren	CUSTOMER	tim.bjorkegren@gmail.com	2025-04-14 15:36:20.267453
\.


--
-- Data for Name: subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subjects (id, company_id, name) FROM stdin;
2	1	Skada
46	1	Teknisk Hjälp
34	1	Test-70aa5d
47	1	T-shirts
49	1	T-shirtsss
53	1	T-shirtss123
54	1	MatVaror
1	1	Reklamation
29	2	Skada
30	2	Övrigt
24	1	Test-03fa68
35	1	Test-bb5a69
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, password, role, email, company, firstname, lastname) FROM stdin;
2	no92one	abc123	USER	no@email.com	1	Linus	Lindroth
3	Testare	abc123	ADMIN	test@gmail.com	2	Testaren	Testsson
1	Master	abc123	ADMIN	m@email.com	1	Kalle	Bjork
12	Timmy_bjork	abc123	USER	Timmytest@gmail.com	1	Timmy	bjork
18	wdawdwad_dwdadwadw	dwadwadawda	USER	bjorkis@gmail.com	1	wdawdwad	dwdadwadw
19	bjorkee_tim	Aqws12aqwsed	USER	bjorkegrentim@gmail.com	1	bjorkee	tim
20	dwdwada_wdwadwadadwdad	dwadawdwadwad	USER	dwadada@gmail.com	1	dwdwada	wdwadwadadwdad
21	Test-d06746_Test-17c8be	Test-572450	USER	Test-58ee3d@gmail.com	1	Test-d06746	Test-17c8be
22	timlol_timylol	abc123	ADMIN	tim.bjorkegren@gmail.com	1	timlol	timylol
23	Test-46e10a_Test-c91842	Test-46202a	USER	Test-d1428d@gmail.com	1	Test-46e10a	Test-c91842
24	Test-54eb9d_Test-4c4109	Test-34af51	USER	Test-d5eb86@gmail.com	1	Test-54eb9d	Test-4c4109
25	Test-094060_Test-002945	Test-dce411	USER	Test-5ebb3b@gmail.com	1	Test-094060	Test-002945
26	Test-071a2a_Test-f7779c	Test-30527d	USER	Test-b0c4f8@gmail.com	1	Test-071a2a	Test-f7779c
27	Test-9e3bb7_Test-473ed3	Test-48d91f	USER	Test-44f3ca@gmail.com	1	Test-9e3bb7	Test-473ed3
7	Tim_bjork	abc123	ADMIN	emailtest@gmail.com	1	Kalle	Bjork
\.


--
-- Name: companies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.companies_id_seq', 60, true);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 193, true);


--
-- Name: subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subjects_id_seq', 114, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 103, true);


--
-- Name: companies companies_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pk PRIMARY KEY (id);


--
-- Name: companies companies_pk_2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pk_2 UNIQUE (name);


--
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pk PRIMARY KEY (id);


--
-- Name: subjects subjects_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pk PRIMARY KEY (id);


--
-- Name: subjects subjects_pk_2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pk_2 UNIQUE (company_id, name);


--
-- Name: users users_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pk PRIMARY KEY (id);


--
-- Name: users users_pk_2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pk_2 UNIQUE (username);


--
-- Name: users users_pk_3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pk_3 UNIQUE (email);


--
-- Name: issues issues_companies_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_companies_id_fk FOREIGN KEY (company_id) REFERENCES public.companies(id);


--
-- Name: messages messages_issues_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_issues_id_fk FOREIGN KEY (issue_id) REFERENCES public.issues(id);


--
-- Name: users users_companies_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_companies_id_fk FOREIGN KEY (company) REFERENCES public.companies(id);


--
-- PostgreSQL database dump complete
--

