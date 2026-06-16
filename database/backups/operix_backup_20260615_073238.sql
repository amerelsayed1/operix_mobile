--
-- PostgreSQL database dump
--

\restrict WzpFRr9HqWdQsKO7zHejf3zov7dc9cHEkj1uJYda3xAGvdtlT6UF8nddjUVhI5o

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: clients; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.clients (
    id bigint NOT NULL,
    client_code character varying(40) NOT NULL,
    name character varying(180) NOT NULL,
    phone character varying(60),
    receivable_balance numeric(14,2) DEFAULT 0 NOT NULL,
    status character varying(40) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.clients OWNER TO operix;

--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.clients_id_seq OWNER TO operix;

--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.clients_id_seq OWNED BY public.clients.id;


--
-- Name: company_profile; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.company_profile (
    id smallint DEFAULT 1 NOT NULL,
    business_name character varying(160) NOT NULL,
    branch_name character varying(120),
    logo_path text,
    currency_code character(3) DEFAULT 'EGP'::bpchar NOT NULL,
    locale character varying(12) DEFAULT 'en'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    email character varying(160),
    phone character varying(60),
    phone_country_code character varying(8) DEFAULT '+20'::character varying NOT NULL,
    commercial_registration character varying(80),
    city character varying(120),
    region character varying(120),
    country character varying(80),
    postal_code character varying(40),
    address text,
    CONSTRAINT company_profile_id_check CHECK ((id = 1))
);


ALTER TABLE public.company_profile OWNER TO operix;

--
-- Name: gl_accounts; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.gl_accounts (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(180) NOT NULL,
    name_ar character varying(180),
    account_type character varying(20) NOT NULL,
    normal_balance character varying(6) NOT NULL,
    parent_id bigint,
    is_active boolean DEFAULT true NOT NULL,
    is_system boolean DEFAULT false NOT NULL,
    is_cogs boolean DEFAULT false NOT NULL,
    allows_manual_posting boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT gl_accounts_account_type_check CHECK (((account_type)::text = ANY ((ARRAY['asset'::character varying, 'liability'::character varying, 'equity'::character varying, 'revenue'::character varying, 'expense'::character varying])::text[]))),
    CONSTRAINT gl_accounts_normal_balance_check CHECK (((normal_balance)::text = ANY ((ARRAY['debit'::character varying, 'credit'::character varying])::text[])))
);


ALTER TABLE public.gl_accounts OWNER TO operix;

--
-- Name: gl_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.gl_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gl_accounts_id_seq OWNER TO operix;

--
-- Name: gl_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.gl_accounts_id_seq OWNED BY public.gl_accounts.id;


--
-- Name: journal_entries; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.journal_entries (
    id bigint NOT NULL,
    reference_no character varying(50) NOT NULL,
    source_type character varying(100),
    source_id bigint,
    entry_type character varying(50),
    description text,
    transaction_date date DEFAULT CURRENT_DATE NOT NULL,
    posted_at timestamp with time zone,
    status character varying(10) DEFAULT 'draft'::character varying NOT NULL,
    currency_code character varying(10),
    exchange_rate numeric(15,6),
    created_by bigint,
    reversed_entry_id bigint,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT journal_entries_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'posted'::character varying, 'reversed'::character varying])::text[])))
);


ALTER TABLE public.journal_entries OWNER TO operix;

--
-- Name: journal_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.journal_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.journal_entries_id_seq OWNER TO operix;

--
-- Name: journal_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.journal_entries_id_seq OWNED BY public.journal_entries.id;


--
-- Name: journal_entry_lines; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.journal_entry_lines (
    id bigint NOT NULL,
    journal_entry_id bigint NOT NULL,
    gl_account_id bigint NOT NULL,
    line_type character varying(6) NOT NULL,
    amount numeric(14,2) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT journal_entry_lines_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT journal_entry_lines_line_type_check CHECK (((line_type)::text = ANY ((ARRAY['debit'::character varying, 'credit'::character varying])::text[])))
);


ALTER TABLE public.journal_entry_lines OWNER TO operix;

--
-- Name: journal_entry_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.journal_entry_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.journal_entry_lines_id_seq OWNER TO operix;

--
-- Name: journal_entry_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.journal_entry_lines_id_seq OWNED BY public.journal_entry_lines.id;


--
-- Name: journal_entry_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.journal_entry_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.journal_entry_seq OWNER TO operix;

--
-- Name: pos_order_items; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.pos_order_items (
    id bigint NOT NULL,
    pos_order_id bigint NOT NULL,
    product_id bigint,
    name character varying(180) NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    unit_price numeric(14,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public.pos_order_items OWNER TO operix;

--
-- Name: pos_order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.pos_order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pos_order_items_id_seq OWNER TO operix;

--
-- Name: pos_order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.pos_order_items_id_seq OWNED BY public.pos_order_items.id;


--
-- Name: pos_order_payments; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.pos_order_payments (
    id bigint NOT NULL,
    pos_order_id bigint NOT NULL,
    method character varying(20) NOT NULL,
    method_label character varying(60),
    amount numeric(14,2) DEFAULT 0 NOT NULL,
    reference character varying(120),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.pos_order_payments OWNER TO operix;

--
-- Name: pos_order_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.pos_order_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pos_order_payments_id_seq OWNER TO operix;

--
-- Name: pos_order_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.pos_order_payments_id_seq OWNED BY public.pos_order_payments.id;


--
-- Name: pos_orders; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.pos_orders (
    id bigint NOT NULL,
    receipt_number character varying(80) NOT NULL,
    total_amount numeric(14,2) DEFAULT 0 NOT NULL,
    payment_status character varying(40) DEFAULT 'paid'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    shift_id bigint,
    cashier_id bigint,
    cashier_name character varying(160),
    customer_name character varying(180),
    subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    discount_amount numeric(14,2) DEFAULT 0 NOT NULL,
    tax_amount numeric(14,2) DEFAULT 0 NOT NULL,
    paid_amount numeric(14,2) DEFAULT 0 NOT NULL,
    change_amount numeric(14,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'completed'::character varying NOT NULL,
    client_id bigint
);


ALTER TABLE public.pos_orders OWNER TO operix;

--
-- Name: pos_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.pos_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pos_orders_id_seq OWNER TO operix;

--
-- Name: pos_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.pos_orders_id_seq OWNED BY public.pos_orders.id;


--
-- Name: pos_receipt_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.pos_receipt_seq
    START WITH 10500
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pos_receipt_seq OWNER TO operix;

--
-- Name: pos_shift_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.pos_shift_seq
    START WITH 1001
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pos_shift_seq OWNER TO operix;

--
-- Name: pos_shifts; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.pos_shifts (
    id bigint NOT NULL,
    shift_number character varying(40) NOT NULL,
    cashier_id bigint,
    cashier_name character varying(160) NOT NULL,
    opening_float numeric(14,2) DEFAULT 0 NOT NULL,
    expected_cash numeric(14,2),
    counted_cash numeric(14,2),
    cash_difference numeric(14,2),
    status character varying(20) DEFAULT 'open'::character varying NOT NULL,
    notes text,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone
);


ALTER TABLE public.pos_shifts OWNER TO operix;

--
-- Name: pos_shifts_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.pos_shifts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pos_shifts_id_seq OWNER TO operix;

--
-- Name: pos_shifts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.pos_shifts_id_seq OWNED BY public.pos_shifts.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.products (
    id bigint NOT NULL,
    sku character varying(80) NOT NULL,
    name character varying(180) NOT NULL,
    category character varying(120) DEFAULT 'General'::character varying NOT NULL,
    quantity_on_hand integer DEFAULT 0 NOT NULL,
    reorder_level integer DEFAULT 0 NOT NULL,
    unit_price numeric(14,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    barcode character varying(80),
    unit character varying(40) DEFAULT 'Piece'::character varying NOT NULL,
    cost_price numeric(14,2) DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.products OWNER TO operix;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_id_seq OWNER TO operix;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.role_permissions (
    role_id bigint NOT NULL,
    permission_key character varying(120) NOT NULL
);


ALTER TABLE public.role_permissions OWNER TO operix;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name character varying(80) NOT NULL,
    description character varying(255) DEFAULT ''::character varying NOT NULL,
    is_system boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.roles OWNER TO operix;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO operix;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: sales_invoice_items; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.sales_invoice_items (
    id bigint NOT NULL,
    sales_invoice_id bigint NOT NULL,
    product_id bigint,
    name character varying(180) NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    unit_price numeric(14,2) DEFAULT 0 NOT NULL,
    line_total numeric(14,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public.sales_invoice_items OWNER TO operix;

--
-- Name: sales_invoice_items_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.sales_invoice_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_invoice_items_id_seq OWNER TO operix;

--
-- Name: sales_invoice_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.sales_invoice_items_id_seq OWNED BY public.sales_invoice_items.id;


--
-- Name: sales_invoice_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.sales_invoice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_invoice_seq OWNER TO operix;

--
-- Name: sales_invoices; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.sales_invoices (
    id bigint NOT NULL,
    invoice_number character varying(80) NOT NULL,
    client_id bigint,
    status character varying(40) DEFAULT 'draft'::character varying NOT NULL,
    issue_date date DEFAULT CURRENT_DATE NOT NULL,
    total_amount numeric(14,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    tax_amount numeric(14,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public.sales_invoices OWNER TO operix;

--
-- Name: sales_invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.sales_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_invoices_id_seq OWNER TO operix;

--
-- Name: sales_invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.sales_invoices_id_seq OWNED BY public.sales_invoices.id;


--
-- Name: sales_return_items; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.sales_return_items (
    id bigint NOT NULL,
    sales_return_id bigint NOT NULL,
    product_id bigint,
    name character varying(180) NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(14,2) NOT NULL,
    line_total numeric(14,2) NOT NULL
);


ALTER TABLE public.sales_return_items OWNER TO operix;

--
-- Name: sales_return_items_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.sales_return_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_return_items_id_seq OWNER TO operix;

--
-- Name: sales_return_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.sales_return_items_id_seq OWNED BY public.sales_return_items.id;


--
-- Name: sales_return_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.sales_return_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_return_seq OWNER TO operix;

--
-- Name: sales_returns; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.sales_returns (
    id bigint NOT NULL,
    return_number character varying(80) NOT NULL,
    pos_order_id bigint,
    cashier_id bigint,
    cashier_name character varying(160),
    reason text,
    refund_method character varying(20) DEFAULT 'cash'::character varying NOT NULL,
    total_amount numeric(14,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'completed'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.sales_returns OWNER TO operix;

--
-- Name: sales_returns_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.sales_returns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_returns_id_seq OWNER TO operix;

--
-- Name: sales_returns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.sales_returns_id_seq OWNED BY public.sales_returns.id;


--
-- Name: stock_movements; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.stock_movements (
    id bigint NOT NULL,
    product_id bigint,
    type character varying(30) NOT NULL,
    quantity integer NOT NULL,
    reason character varying(120),
    note text,
    reference_type character varying(50),
    reference_id bigint,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.stock_movements OWNER TO operix;

--
-- Name: stock_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.stock_movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.stock_movements_id_seq OWNER TO operix;

--
-- Name: stock_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.stock_movements_id_seq OWNED BY public.stock_movements.id;


--
-- Name: supplier_invoice_items; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.supplier_invoice_items (
    id bigint NOT NULL,
    supplier_invoice_id bigint NOT NULL,
    product_id bigint,
    name character varying(180) NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    unit_price numeric(14,2) DEFAULT 0 NOT NULL,
    line_total numeric(14,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public.supplier_invoice_items OWNER TO operix;

--
-- Name: supplier_invoice_items_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.supplier_invoice_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.supplier_invoice_items_id_seq OWNER TO operix;

--
-- Name: supplier_invoice_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.supplier_invoice_items_id_seq OWNED BY public.supplier_invoice_items.id;


--
-- Name: supplier_invoice_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.supplier_invoice_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.supplier_invoice_seq OWNER TO operix;

--
-- Name: supplier_invoices; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.supplier_invoices (
    id bigint NOT NULL,
    invoice_number character varying(80) NOT NULL,
    supplier_id bigint,
    status character varying(40) DEFAULT 'pending'::character varying NOT NULL,
    issue_date date DEFAULT CURRENT_DATE NOT NULL,
    total_amount numeric(14,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    tax_amount numeric(14,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public.supplier_invoices OWNER TO operix;

--
-- Name: supplier_invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.supplier_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.supplier_invoices_id_seq OWNER TO operix;

--
-- Name: supplier_invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.supplier_invoices_id_seq OWNED BY public.supplier_invoices.id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.suppliers (
    id bigint NOT NULL,
    supplier_code character varying(40) NOT NULL,
    company_name character varying(180) NOT NULL,
    phone character varying(60),
    payable_balance numeric(14,2) DEFAULT 0 NOT NULL,
    status character varying(40) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.suppliers OWNER TO operix;

--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.suppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.suppliers_id_seq OWNER TO operix;

--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: operix
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    username character varying(60) NOT NULL,
    full_name character varying(160) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(40) DEFAULT 'cashier'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_login_at timestamp with time zone
);


ALTER TABLE public.users OWNER TO operix;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: operix
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO operix;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: operix
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: clients id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.clients ALTER COLUMN id SET DEFAULT nextval('public.clients_id_seq'::regclass);


--
-- Name: gl_accounts id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.gl_accounts ALTER COLUMN id SET DEFAULT nextval('public.gl_accounts_id_seq'::regclass);


--
-- Name: journal_entries id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.journal_entries ALTER COLUMN id SET DEFAULT nextval('public.journal_entries_id_seq'::regclass);


--
-- Name: journal_entry_lines id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.journal_entry_lines ALTER COLUMN id SET DEFAULT nextval('public.journal_entry_lines_id_seq'::regclass);


--
-- Name: pos_order_items id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_order_items ALTER COLUMN id SET DEFAULT nextval('public.pos_order_items_id_seq'::regclass);


--
-- Name: pos_order_payments id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_order_payments ALTER COLUMN id SET DEFAULT nextval('public.pos_order_payments_id_seq'::regclass);


--
-- Name: pos_orders id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_orders ALTER COLUMN id SET DEFAULT nextval('public.pos_orders_id_seq'::regclass);


--
-- Name: pos_shifts id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_shifts ALTER COLUMN id SET DEFAULT nextval('public.pos_shifts_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: sales_invoice_items id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_invoice_items ALTER COLUMN id SET DEFAULT nextval('public.sales_invoice_items_id_seq'::regclass);


--
-- Name: sales_invoices id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_invoices ALTER COLUMN id SET DEFAULT nextval('public.sales_invoices_id_seq'::regclass);


--
-- Name: sales_return_items id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_return_items ALTER COLUMN id SET DEFAULT nextval('public.sales_return_items_id_seq'::regclass);


--
-- Name: sales_returns id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_returns ALTER COLUMN id SET DEFAULT nextval('public.sales_returns_id_seq'::regclass);


--
-- Name: stock_movements id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.stock_movements ALTER COLUMN id SET DEFAULT nextval('public.stock_movements_id_seq'::regclass);


--
-- Name: supplier_invoice_items id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.supplier_invoice_items ALTER COLUMN id SET DEFAULT nextval('public.supplier_invoice_items_id_seq'::regclass);


--
-- Name: supplier_invoices id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.supplier_invoices ALTER COLUMN id SET DEFAULT nextval('public.supplier_invoices_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.clients (id, client_code, name, phone, receivable_balance, status, created_at) FROM stdin;
5	CUST-0001	ساره حمدي	\N	0.00	active	2026-06-14 04:31:09.792823+00
\.


--
-- Data for Name: company_profile; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.company_profile (id, business_name, branch_name, logo_path, currency_code, locale, created_at, email, phone, phone_country_code, commercial_registration, city, region, country, postal_code, address) FROM stdin;
1	Hello Kid	شارع الجيش	\N	EGP	en	2026-06-14 03:46:27.311697+00	\N	\N	+20	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: gl_accounts; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.gl_accounts (id, code, name, name_ar, account_type, normal_balance, parent_id, is_active, is_system, is_cogs, allows_manual_posting, description, created_at, updated_at) FROM stdin;
1	1000	Assets	الأصول	asset	debit	\N	t	t	f	t	\N	2026-06-14 03:43:20.950996+00	2026-06-14 03:43:20.950996+00
2	2000	Liabilities	الخصوم	liability	credit	\N	t	t	f	t	\N	2026-06-14 03:43:20.950996+00	2026-06-14 03:43:20.950996+00
3	3000	Equity	حقوق الملكية	equity	credit	\N	t	t	f	t	\N	2026-06-14 03:43:20.950996+00	2026-06-14 03:43:20.950996+00
4	4000	Revenue	الإيرادات	revenue	credit	\N	t	t	f	t	\N	2026-06-14 03:43:20.950996+00	2026-06-14 03:43:20.950996+00
5	5000	Expenses	المصروفات	expense	debit	\N	t	t	f	t	\N	2026-06-14 03:43:20.950996+00	2026-06-14 03:43:20.950996+00
6	1100	Cash	النقدية	asset	debit	1	t	t	f	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
7	1200	Accounts Receivable	الذمم المدينة	asset	debit	1	t	t	f	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
8	1300	Inventory	المخزون	asset	debit	1	t	t	f	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
9	2100	Accounts Payable	الذمم الدائنة	liability	credit	2	t	t	f	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
10	2200	Tax Payable	ضرائب مستحقة	liability	credit	2	t	t	f	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
11	3100	Owner Capital	رأس المال	equity	credit	3	t	t	f	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
12	3200	Retained Earnings	الأرباح المحتجزة	equity	credit	3	t	t	f	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
13	4100	Sales Revenue	إيرادات المبيعات	revenue	credit	4	t	t	f	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
14	5100	Cost of Goods Sold	تكلفة البضاعة المباعة	expense	debit	5	t	t	t	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
15	5200	Operating Expenses	مصروفات تشغيلية	expense	debit	5	t	t	f	t	\N	2026-06-14 03:43:20.952437+00	2026-06-14 03:43:20.952437+00
\.


--
-- Data for Name: journal_entries; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.journal_entries (id, reference_no, source_type, source_id, entry_type, description, transaction_date, posted_at, status, currency_code, exchange_rate, created_by, reversed_entry_id, notes, created_at, updated_at) FROM stdin;
1	JE-000001	sales_invoice	1	invoice_posting	Sales invoice SINV-0001	2026-06-11	2026-06-11 03:43:20.967835+00	posted	\N	\N	\N	\N	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
2	JE-000002	sales_invoice	1	invoice_cogs	COGS for SINV-0001	2026-06-11	2026-06-11 03:43:20.967835+00	posted	\N	\N	\N	\N	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
3	JE-000003	sales_invoice	2	invoice_posting	Sales invoice SINV-0002	2026-06-13	2026-06-13 03:43:20.967835+00	posted	\N	\N	\N	\N	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
4	JE-000004	sales_invoice	2	invoice_cogs	COGS for SINV-0002	2026-06-13	2026-06-13 03:43:20.967835+00	posted	\N	\N	\N	\N	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
5	JE-000005	sales_invoice	3	invoice_posting	Sales invoice SINV-0003	2026-06-14	2026-06-14 01:43:20.967835+00	posted	\N	\N	\N	\N	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
6	JE-000006	sales_invoice	3	invoice_cogs	COGS for SINV-0003	2026-06-14	2026-06-14 01:43:20.967835+00	posted	\N	\N	\N	\N	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
7	JE-000007	supplier_invoice	1	invoice_posting	Purchase invoice PINV-0001	2026-06-09	2026-06-09 03:43:20.967835+00	posted	\N	\N	\N	\N	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
8	JE-000008	supplier_invoice	2	invoice_posting	Purchase invoice PINV-0002	2026-06-10	2026-06-10 03:43:20.967835+00	posted	\N	\N	\N	\N	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
9	JE-000009	supplier_invoice	3	invoice_posting	Purchase invoice PINV-0003	2026-06-11	2026-06-11 03:43:20.967835+00	posted	\N	\N	\N	\N	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
\.


--
-- Data for Name: journal_entry_lines; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.journal_entry_lines (id, journal_entry_id, gl_account_id, line_type, amount, description, created_at, updated_at) FROM stdin;
1	1	7	debit	627.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
2	1	13	credit	550.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
3	1	10	credit	77.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
4	2	14	debit	330.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
5	2	8	credit	330.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
6	3	7	debit	763.80	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
7	3	13	credit	670.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
8	3	10	credit	93.80	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
9	4	14	debit	430.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
10	4	8	credit	430.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
11	5	6	debit	752.40	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
12	5	13	credit	660.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
13	5	10	credit	92.40	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
14	6	14	debit	404.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
15	6	8	credit	404.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
16	7	8	debit	2200.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
17	7	10	debit	308.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
18	7	9	credit	2508.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
19	8	8	debit	1500.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
20	8	10	debit	210.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
21	8	9	credit	1710.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
22	9	8	debit	1560.00	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
23	9	10	debit	218.40	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
24	9	9	credit	1778.40	\N	2026-06-14 03:43:20.967835+00	2026-06-14 03:43:20.967835+00
\.


--
-- Data for Name: pos_order_items; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.pos_order_items (id, pos_order_id, product_id, name, quantity, unit_price) FROM stdin;
1	1	\N	Bottled Water 500ml	2	10.00
9	5	\N	Bottled Water 500ml	4	10.00
6	3	\N	Chocolate Bar	2	20.00
5	3	\N	Cola Can 330ml	3	15.00
8	4	\N	Croissant	2	16.00
10	5	\N	Dish Soap 500ml	1	45.00
4	2	\N	Milk 1L	1	30.00
3	2	\N	Orange Juice 1L	1	35.00
13	6	\N	Paper Towels	1	38.00
2	1	\N	Potato Chips	2	25.00
12	6	\N	Salted Peanuts	1	18.00
7	4	\N	White Bread	1	22.00
11	6	\N	Yogurt 200g	2	12.00
\.


--
-- Data for Name: pos_order_payments; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.pos_order_payments (id, pos_order_id, method, method_label, amount, reference, created_at) FROM stdin;
1	1	cash	\N	70.00	\N	2026-06-14 03:43:20.955716+00
2	2	card	\N	65.00	\N	2026-06-14 03:43:20.955716+00
3	3	cash	\N	85.00	\N	2026-06-14 03:43:20.955716+00
4	4	card	\N	54.00	\N	2026-06-14 03:43:20.955716+00
5	5	cash	\N	85.00	\N	2026-06-14 03:43:20.955716+00
6	6	custom	Instapay	80.00	\N	2026-06-14 03:43:20.955716+00
\.


--
-- Data for Name: pos_orders; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.pos_orders (id, receipt_number, total_amount, payment_status, created_at, shift_id, cashier_id, cashier_name, customer_name, subtotal, discount_amount, tax_amount, paid_amount, change_amount, status, client_id) FROM stdin;
1	SEED-0001	70.00	paid	2026-06-12 03:43:20.955716+00	1	\N	Seed Cashier	\N	70.00	0.00	0.00	70.00	0.00	completed	\N
2	SEED-0002	65.00	paid	2026-06-12 04:43:20.955716+00	1	\N	Seed Cashier	\N	65.00	0.00	0.00	65.00	0.00	completed	\N
3	SEED-0003	85.00	paid	2026-06-13 03:43:20.955716+00	1	\N	Seed Cashier	\N	85.00	0.00	0.00	85.00	0.00	completed	\N
4	SEED-0004	54.00	paid	2026-06-13 05:43:20.955716+00	1	\N	Seed Cashier	\N	54.00	0.00	0.00	54.00	0.00	completed	\N
5	SEED-0005	85.00	paid	2026-06-14 00:43:20.955716+00	2	\N	Seed Cashier	\N	85.00	0.00	0.00	85.00	0.00	completed	\N
6	SEED-0006	80.00	paid	2026-06-14 02:43:20.955716+00	2	\N	Seed Cashier	Cafe Downtown	80.00	0.00	0.00	80.00	0.00	completed	\N
\.


--
-- Data for Name: pos_shifts; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.pos_shifts (id, shift_number, cashier_id, cashier_name, opening_float, expected_cash, counted_cash, cash_difference, status, notes, opened_at, closed_at) FROM stdin;
1	SEED-SH-01	\N	Seed Cashier	500.00	1290.00	1290.00	0.00	closed	\N	2026-06-12 03:43:20.955716+00	2026-06-12 11:43:20.955716+00
2	SEED-SH-02	\N	Seed Cashier	500.00	\N	\N	\N	open	\N	2026-06-13 23:43:20.955716+00	\N
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.products (id, sku, name, category, quantity_on_hand, reorder_level, unit_price, created_at, barcode, unit, cost_price, is_active) FROM stdin;
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.role_permissions (role_id, permission_key) FROM stdin;
1	dashboard.view
1	settings.view
1	settings.edit
1	company.view
1	company.edit
1	roles.view
1	roles.create
1	roles.edit
1	roles.delete
1	employees.view
1	employees.create
1	employees.edit
1	employees.delete
1	profile.edit
1	billing.view
1	billing.manage
1	branches.view
1	branches.create
1	branches.edit
1	branches.delete
1	pos.enter
1	pos.create
1	pos.edit
1	pos.delete
1	pos.browse
1	pos.assign
1	shifts.view
1	shifts.open
1	shifts.close
1	shifts.delete
1	shifts.extraAccounts
1	salesInvoices.view
1	salesInvoices.create
1	salesInvoices.edit
1	salesInvoices.delete
1	salesInvoices.approve
1	salesInvoices.return
1	salesInvoices.export
1	salesInvoices.collectCredit
1	salesInvoices.collectPayment
1	crm.view
1	crm.create
1	crm.edit
1	crm.delete
2	pos.enter
2	pos.create
2	pos.edit
2	pos.delete
2	pos.browse
2	pos.assign
2	shifts.view
2	shifts.open
2	shifts.close
2	shifts.delete
2	shifts.extraAccounts
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.roles (id, name, description, is_system, created_at) FROM stdin;
1	Admin	Tenant Administrator with full access	t	2026-06-14 05:04:08.294787+00
2	كاشير	تيست	f	2026-06-14 05:04:41.953399+00
\.


--
-- Data for Name: sales_invoice_items; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.sales_invoice_items (id, sales_invoice_id, product_id, name, quantity, unit_price, line_total) FROM stdin;
1	1	\N	Cola Can 330ml	20	15.00	300.00
3	2	\N	Milk 1L	15	30.00	450.00
5	3	\N	Orange Juice 1L	12	35.00	420.00
2	1	\N	Potato Chips	10	25.00	250.00
4	2	\N	White Bread	10	22.00	220.00
6	3	\N	Yogurt 200g	20	12.00	240.00
\.


--
-- Data for Name: sales_invoices; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.sales_invoices (id, invoice_number, client_id, status, issue_date, total_amount, created_at, subtotal, tax_amount) FROM stdin;
1	SINV-0001	\N	posted	2026-06-11	627.00	2026-06-11 03:43:20.967835+00	550.00	77.00
3	SINV-0003	\N	paid	2026-06-14	752.40	2026-06-14 01:43:20.967835+00	660.00	92.40
2	SINV-0002	\N	posted	2026-06-13	763.80	2026-06-13 03:43:20.967835+00	670.00	93.80
\.


--
-- Data for Name: sales_return_items; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.sales_return_items (id, sales_return_id, product_id, name, quantity, unit_price, line_total) FROM stdin;
\.


--
-- Data for Name: sales_returns; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.sales_returns (id, return_number, pos_order_id, cashier_id, cashier_name, reason, refund_method, total_amount, status, created_at) FROM stdin;
\.


--
-- Data for Name: stock_movements; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.stock_movements (id, product_id, type, quantity, reason, note, reference_type, reference_id, created_by, created_at) FROM stdin;
1	\N	opening_stock	200	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
15	\N	pos_sale	-2	\N	\N	pos_order	1	\N	2026-06-12 03:43:20.955716+00
23	\N	pos_sale	-4	\N	\N	pos_order	5	\N	2026-06-14 00:43:20.955716+00
5	\N	opening_stock	90	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
20	\N	pos_sale	-2	\N	\N	pos_order	3	\N	2026-06-13 03:43:20.955716+00
2	\N	opening_stock	150	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
19	\N	pos_sale	-3	\N	\N	pos_order	3	\N	2026-06-13 03:43:20.955716+00
8	\N	opening_stock	35	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
22	\N	pos_sale	-2	\N	\N	pos_order	4	\N	2026-06-13 03:43:20.955716+00
11	\N	opening_stock	30	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
24	\N	pos_sale	-1	\N	\N	pos_order	5	\N	2026-06-14 00:43:20.955716+00
9	\N	opening_stock	50	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
18	\N	pos_sale	-1	\N	\N	pos_order	2	\N	2026-06-12 03:43:20.955716+00
3	\N	opening_stock	60	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
17	\N	pos_sale	-1	\N	\N	pos_order	2	\N	2026-06-12 03:43:20.955716+00
12	\N	opening_stock	25	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
27	\N	pos_sale	-1	\N	\N	pos_order	6	\N	2026-06-14 02:43:20.955716+00
4	\N	opening_stock	120	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
16	\N	pos_sale	-2	\N	\N	pos_order	1	\N	2026-06-12 03:43:20.955716+00
6	\N	opening_stock	75	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
26	\N	pos_sale	-1	\N	\N	pos_order	6	\N	2026-06-14 02:43:20.955716+00
7	\N	opening_stock	40	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
13	\N	adjustment	-3	Damage	Spoiled loaves	\N	\N	\N	2026-06-13 03:43:20.955716+00
21	\N	pos_sale	-1	\N	\N	pos_order	4	\N	2026-06-13 03:43:20.955716+00
10	\N	opening_stock	80	\N	Seed opening stock	\N	\N	\N	2026-06-09 03:43:20.955716+00
14	\N	adjustment	-2	Loss	Expired units	\N	\N	\N	2026-06-13 03:43:20.955716+00
25	\N	pos_sale	-2	\N	\N	pos_order	6	\N	2026-06-14 02:43:20.955716+00
\.


--
-- Data for Name: supplier_invoice_items; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.supplier_invoice_items (id, supplier_invoice_id, product_id, name, quantity, unit_price, line_total) FROM stdin;
1	1	\N	Bottled Water 500ml	100	6.00	600.00
5	2	\N	Chocolate Bar	50	12.00	600.00
2	1	\N	Cola Can 330ml	80	9.00	720.00
6	3	\N	Milk 1L	50	20.00	1000.00
3	1	\N	Orange Juice 1L	40	22.00	880.00
4	2	\N	Potato Chips	60	15.00	900.00
7	3	\N	Yogurt 200g	80	7.00	560.00
\.


--
-- Data for Name: supplier_invoices; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.supplier_invoices (id, invoice_number, supplier_id, status, issue_date, total_amount, created_at, subtotal, tax_amount) FROM stdin;
3	PINV-0003	\N	pending	2026-06-11	1778.40	2026-06-11 03:43:20.967835+00	1560.00	218.40
1	PINV-0001	\N	pending	2026-06-09	2508.00	2026-06-09 03:43:20.967835+00	2200.00	308.00
2	PINV-0002	\N	pending	2026-06-10	1710.00	2026-06-10 03:43:20.967835+00	1500.00	210.00
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.suppliers (id, supplier_code, company_name, phone, payable_balance, status, created_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: operix
--

COPY public.users (id, username, full_name, password_hash, role, is_active, created_at, last_login_at) FROM stdin;
1	admin	Amer Mahsoub	pbkdf2_sha256$120000$cO1+O2PH5slA3taa7WHBog==$ywg8Pl3jIsTA+j8sl9LUOwijQSkYJIWiWJk56TKrIDQ=	admin	t	2026-06-14 03:46:43.422327+00	2026-06-14 04:30:24.575168+00
\.


--
-- Name: clients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.clients_id_seq', 5, true);


--
-- Name: gl_accounts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.gl_accounts_id_seq', 15, true);


--
-- Name: journal_entries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.journal_entries_id_seq', 9, true);


--
-- Name: journal_entry_lines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.journal_entry_lines_id_seq', 24, true);


--
-- Name: journal_entry_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.journal_entry_seq', 9, true);


--
-- Name: pos_order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.pos_order_items_id_seq', 13, true);


--
-- Name: pos_order_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.pos_order_payments_id_seq', 6, true);


--
-- Name: pos_orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.pos_orders_id_seq', 6, true);


--
-- Name: pos_receipt_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.pos_receipt_seq', 10500, false);


--
-- Name: pos_shift_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.pos_shift_seq', 1001, false);


--
-- Name: pos_shifts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.pos_shifts_id_seq', 2, true);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.products_id_seq', 13, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.roles_id_seq', 2, true);


--
-- Name: sales_invoice_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.sales_invoice_items_id_seq', 6, true);


--
-- Name: sales_invoice_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.sales_invoice_seq', 1, false);


--
-- Name: sales_invoices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.sales_invoices_id_seq', 3, true);


--
-- Name: sales_return_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.sales_return_items_id_seq', 1, false);


--
-- Name: sales_return_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.sales_return_seq', 1, false);


--
-- Name: sales_returns_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.sales_returns_id_seq', 1, false);


--
-- Name: stock_movements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.stock_movements_id_seq', 27, true);


--
-- Name: supplier_invoice_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.supplier_invoice_items_id_seq', 7, true);


--
-- Name: supplier_invoice_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.supplier_invoice_seq', 1, false);


--
-- Name: supplier_invoices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.supplier_invoices_id_seq', 3, true);


--
-- Name: suppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.suppliers_id_seq', 3, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: operix
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);


--
-- Name: clients clients_client_code_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_client_code_key UNIQUE (client_code);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: company_profile company_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.company_profile
    ADD CONSTRAINT company_profile_pkey PRIMARY KEY (id);


--
-- Name: gl_accounts gl_accounts_code_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.gl_accounts
    ADD CONSTRAINT gl_accounts_code_key UNIQUE (code);


--
-- Name: gl_accounts gl_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.gl_accounts
    ADD CONSTRAINT gl_accounts_pkey PRIMARY KEY (id);


--
-- Name: journal_entries journal_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.journal_entries
    ADD CONSTRAINT journal_entries_pkey PRIMARY KEY (id);


--
-- Name: journal_entries journal_entries_reference_no_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.journal_entries
    ADD CONSTRAINT journal_entries_reference_no_key UNIQUE (reference_no);


--
-- Name: journal_entry_lines journal_entry_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.journal_entry_lines
    ADD CONSTRAINT journal_entry_lines_pkey PRIMARY KEY (id);


--
-- Name: pos_order_items pos_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_order_items
    ADD CONSTRAINT pos_order_items_pkey PRIMARY KEY (id);


--
-- Name: pos_order_payments pos_order_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_order_payments
    ADD CONSTRAINT pos_order_payments_pkey PRIMARY KEY (id);


--
-- Name: pos_orders pos_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_orders
    ADD CONSTRAINT pos_orders_pkey PRIMARY KEY (id);


--
-- Name: pos_orders pos_orders_receipt_number_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_orders
    ADD CONSTRAINT pos_orders_receipt_number_key UNIQUE (receipt_number);


--
-- Name: pos_shifts pos_shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_shifts
    ADD CONSTRAINT pos_shifts_pkey PRIMARY KEY (id);


--
-- Name: pos_shifts pos_shifts_shift_number_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_shifts
    ADD CONSTRAINT pos_shifts_shift_number_key UNIQUE (shift_number);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: products products_sku_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_sku_key UNIQUE (sku);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_key);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sales_invoice_items sales_invoice_items_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_invoice_items
    ADD CONSTRAINT sales_invoice_items_pkey PRIMARY KEY (id);


--
-- Name: sales_invoices sales_invoices_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_invoices
    ADD CONSTRAINT sales_invoices_invoice_number_key UNIQUE (invoice_number);


--
-- Name: sales_invoices sales_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_invoices
    ADD CONSTRAINT sales_invoices_pkey PRIMARY KEY (id);


--
-- Name: sales_return_items sales_return_items_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_return_items
    ADD CONSTRAINT sales_return_items_pkey PRIMARY KEY (id);


--
-- Name: sales_returns sales_returns_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_returns
    ADD CONSTRAINT sales_returns_pkey PRIMARY KEY (id);


--
-- Name: sales_returns sales_returns_return_number_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_returns
    ADD CONSTRAINT sales_returns_return_number_key UNIQUE (return_number);


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (id);


--
-- Name: supplier_invoice_items supplier_invoice_items_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.supplier_invoice_items
    ADD CONSTRAINT supplier_invoice_items_pkey PRIMARY KEY (id);


--
-- Name: supplier_invoices supplier_invoices_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.supplier_invoices
    ADD CONSTRAINT supplier_invoices_invoice_number_key UNIQUE (invoice_number);


--
-- Name: supplier_invoices supplier_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.supplier_invoices
    ADD CONSTRAINT supplier_invoices_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_supplier_code_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_supplier_code_key UNIQUE (supplier_code);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: clients_status_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX clients_status_idx ON public.clients USING btree (status);


--
-- Name: gl_accounts_parent_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX gl_accounts_parent_idx ON public.gl_accounts USING btree (parent_id);


--
-- Name: gl_accounts_type_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX gl_accounts_type_idx ON public.gl_accounts USING btree (account_type);


--
-- Name: jel_account_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX jel_account_idx ON public.journal_entry_lines USING btree (gl_account_id);


--
-- Name: jel_entry_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX jel_entry_idx ON public.journal_entry_lines USING btree (journal_entry_id, line_type);


--
-- Name: journal_entries_date_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX journal_entries_date_idx ON public.journal_entries USING btree (transaction_date);


--
-- Name: journal_entries_source_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX journal_entries_source_idx ON public.journal_entries USING btree (source_type, source_id);


--
-- Name: journal_entries_source_uidx; Type: INDEX; Schema: public; Owner: operix
--

CREATE UNIQUE INDEX journal_entries_source_uidx ON public.journal_entries USING btree (source_type, source_id, entry_type, status) WHERE (source_type IS NOT NULL);


--
-- Name: journal_entries_status_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX journal_entries_status_idx ON public.journal_entries USING btree (status);


--
-- Name: pos_order_payments_order_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX pos_order_payments_order_idx ON public.pos_order_payments USING btree (pos_order_id);


--
-- Name: pos_orders_client_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX pos_orders_client_idx ON public.pos_orders USING btree (client_id);


--
-- Name: pos_orders_created_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX pos_orders_created_idx ON public.pos_orders USING btree (created_at);


--
-- Name: pos_orders_shift_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX pos_orders_shift_idx ON public.pos_orders USING btree (shift_id);


--
-- Name: pos_shifts_cashier_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX pos_shifts_cashier_idx ON public.pos_shifts USING btree (cashier_id);


--
-- Name: pos_shifts_status_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX pos_shifts_status_idx ON public.pos_shifts USING btree (status);


--
-- Name: products_active_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX products_active_idx ON public.products USING btree (is_active);


--
-- Name: products_barcode_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX products_barcode_idx ON public.products USING btree (barcode);


--
-- Name: products_category_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX products_category_idx ON public.products USING btree (category);


--
-- Name: products_quantity_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX products_quantity_idx ON public.products USING btree (quantity_on_hand);


--
-- Name: sales_invoice_items_invoice_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX sales_invoice_items_invoice_idx ON public.sales_invoice_items USING btree (sales_invoice_id);


--
-- Name: sales_invoice_items_product_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX sales_invoice_items_product_idx ON public.sales_invoice_items USING btree (product_id);


--
-- Name: sales_invoices_date_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX sales_invoices_date_idx ON public.sales_invoices USING btree (issue_date);


--
-- Name: sales_return_items_return_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX sales_return_items_return_idx ON public.sales_return_items USING btree (sales_return_id);


--
-- Name: sales_returns_created_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX sales_returns_created_idx ON public.sales_returns USING btree (created_at);


--
-- Name: sales_returns_order_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX sales_returns_order_idx ON public.sales_returns USING btree (pos_order_id);


--
-- Name: stock_movements_created_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX stock_movements_created_idx ON public.stock_movements USING btree (created_at);


--
-- Name: stock_movements_product_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX stock_movements_product_idx ON public.stock_movements USING btree (product_id, created_at);


--
-- Name: stock_movements_type_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX stock_movements_type_idx ON public.stock_movements USING btree (type);


--
-- Name: supplier_invoice_items_invoice_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX supplier_invoice_items_invoice_idx ON public.supplier_invoice_items USING btree (supplier_invoice_id);


--
-- Name: supplier_invoice_items_product_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX supplier_invoice_items_product_idx ON public.supplier_invoice_items USING btree (product_id);


--
-- Name: supplier_invoices_date_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX supplier_invoices_date_idx ON public.supplier_invoices USING btree (issue_date);


--
-- Name: suppliers_status_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX suppliers_status_idx ON public.suppliers USING btree (status);


--
-- Name: users_active_idx; Type: INDEX; Schema: public; Owner: operix
--

CREATE INDEX users_active_idx ON public.users USING btree (is_active);


--
-- Name: gl_accounts gl_accounts_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.gl_accounts
    ADD CONSTRAINT gl_accounts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.gl_accounts(id) ON DELETE SET NULL;


--
-- Name: journal_entries journal_entries_reversed_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.journal_entries
    ADD CONSTRAINT journal_entries_reversed_entry_id_fkey FOREIGN KEY (reversed_entry_id) REFERENCES public.journal_entries(id) ON DELETE SET NULL;


--
-- Name: journal_entry_lines journal_entry_lines_gl_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.journal_entry_lines
    ADD CONSTRAINT journal_entry_lines_gl_account_id_fkey FOREIGN KEY (gl_account_id) REFERENCES public.gl_accounts(id);


--
-- Name: journal_entry_lines journal_entry_lines_journal_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.journal_entry_lines
    ADD CONSTRAINT journal_entry_lines_journal_entry_id_fkey FOREIGN KEY (journal_entry_id) REFERENCES public.journal_entries(id) ON DELETE CASCADE;


--
-- Name: pos_order_items pos_order_items_pos_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_order_items
    ADD CONSTRAINT pos_order_items_pos_order_id_fkey FOREIGN KEY (pos_order_id) REFERENCES public.pos_orders(id) ON DELETE CASCADE;


--
-- Name: pos_order_items pos_order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_order_items
    ADD CONSTRAINT pos_order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: pos_order_payments pos_order_payments_pos_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_order_payments
    ADD CONSTRAINT pos_order_payments_pos_order_id_fkey FOREIGN KEY (pos_order_id) REFERENCES public.pos_orders(id) ON DELETE CASCADE;


--
-- Name: pos_orders pos_orders_cashier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_orders
    ADD CONSTRAINT pos_orders_cashier_id_fkey FOREIGN KEY (cashier_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: pos_orders pos_orders_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_orders
    ADD CONSTRAINT pos_orders_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE SET NULL;


--
-- Name: pos_orders pos_orders_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_orders
    ADD CONSTRAINT pos_orders_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.pos_shifts(id) ON DELETE SET NULL;


--
-- Name: pos_shifts pos_shifts_cashier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.pos_shifts
    ADD CONSTRAINT pos_shifts_cashier_id_fkey FOREIGN KEY (cashier_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: sales_invoice_items sales_invoice_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_invoice_items
    ADD CONSTRAINT sales_invoice_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: sales_invoice_items sales_invoice_items_sales_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_invoice_items
    ADD CONSTRAINT sales_invoice_items_sales_invoice_id_fkey FOREIGN KEY (sales_invoice_id) REFERENCES public.sales_invoices(id) ON DELETE CASCADE;


--
-- Name: sales_invoices sales_invoices_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_invoices
    ADD CONSTRAINT sales_invoices_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE SET NULL;


--
-- Name: sales_return_items sales_return_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_return_items
    ADD CONSTRAINT sales_return_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: sales_return_items sales_return_items_sales_return_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_return_items
    ADD CONSTRAINT sales_return_items_sales_return_id_fkey FOREIGN KEY (sales_return_id) REFERENCES public.sales_returns(id) ON DELETE CASCADE;


--
-- Name: sales_returns sales_returns_pos_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.sales_returns
    ADD CONSTRAINT sales_returns_pos_order_id_fkey FOREIGN KEY (pos_order_id) REFERENCES public.pos_orders(id) ON DELETE SET NULL;


--
-- Name: stock_movements stock_movements_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: supplier_invoice_items supplier_invoice_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.supplier_invoice_items
    ADD CONSTRAINT supplier_invoice_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: supplier_invoice_items supplier_invoice_items_supplier_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.supplier_invoice_items
    ADD CONSTRAINT supplier_invoice_items_supplier_invoice_id_fkey FOREIGN KEY (supplier_invoice_id) REFERENCES public.supplier_invoices(id) ON DELETE CASCADE;


--
-- Name: supplier_invoices supplier_invoices_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: operix
--

ALTER TABLE ONLY public.supplier_invoices
    ADD CONSTRAINT supplier_invoices_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict WzpFRr9HqWdQsKO7zHejf3zov7dc9cHEkj1uJYda3xAGvdtlT6UF8nddjUVhI5o

