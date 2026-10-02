-- ============================================================
-- ECOCOlONES DATABASE SCHEMA
-- ============================================================

-- ============================================================
-- TYPES
-- ============================================================

CREATE TYPE public.role AS ENUM (
  'admin',
  'user',
  'affiliate',
  'center'
);

CREATE TYPE public.gender AS ENUM (
  'male',
  'female',
  'other'
);

CREATE TYPE public.document_type AS ENUM (
  'passport',
  'dimex',
  'id'
);

CREATE TYPE public.state AS ENUM (
  'active',
  'inactive'
);


-- ============================================================
-- SEQUENCES
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS affiliatedbusinesstransaction_code_seq
  START WITH 1
  INCREMENT BY 1
  MINVALUE 1;

CREATE SEQUENCE IF NOT EXISTS collectioncentertransaction_code_seq
  START WITH 1
  INCREMENT BY 1
  MINVALUE 1;


-- ============================================================
-- LOCATION TABLES
-- Dependency:
-- country -> province -> city -> district
-- ============================================================

-- ------------------------------------------------------------
-- Country
-- ------------------------------------------------------------

CREATE TABLE public.country (
  country_id uuid NOT NULL DEFAULT gen_random_uuid(),
  country_name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT country_pkey
    PRIMARY KEY (country_id)
);


-- ------------------------------------------------------------
-- Province
-- ------------------------------------------------------------

CREATE TABLE public.province (
  province_id uuid NOT NULL DEFAULT gen_random_uuid(),
  country_id uuid NOT NULL,
  province_name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT province_pkey
    PRIMARY KEY (province_id),

  CONSTRAINT province_country_id_fkey
    FOREIGN KEY (country_id)
    REFERENCES public.country(country_id)
);


-- ------------------------------------------------------------
-- City
-- ------------------------------------------------------------

CREATE TABLE public.city (
  city_id uuid NOT NULL DEFAULT gen_random_uuid(),
  province_id uuid NOT NULL,
  city_name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT city_pkey
    PRIMARY KEY (city_id),

  CONSTRAINT city_province_id_fkey
    FOREIGN KEY (province_id)
    REFERENCES public.province(province_id)
);


-- ------------------------------------------------------------
-- District
-- ------------------------------------------------------------

CREATE TABLE public.district (
  district_id uuid NOT NULL DEFAULT gen_random_uuid(),
  city_id uuid NOT NULL,
  district_name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT district_pkey
    PRIMARY KEY (district_id),

  CONSTRAINT district_city_id_fkey
    FOREIGN KEY (city_id)
    REFERENCES public.city(city_id)
);


-- ============================================================
-- BASIC / INDEPENDENT TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Email
-- ------------------------------------------------------------

CREATE TABLE public.email (
  id_email bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  email character varying NOT NULL,

  CONSTRAINT email_pkey
    PRIMARY KEY (id_email)
);


-- ------------------------------------------------------------
-- Business Type
-- ------------------------------------------------------------

CREATE TABLE public.businesstype (
  business_type_id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT businesstype_pkey
    PRIMARY KEY (business_type_id)
);


-- ------------------------------------------------------------
-- Currency
-- ------------------------------------------------------------

CREATE TABLE public.currency (
  currency_id uuid NOT NULL DEFAULT gen_random_uuid(),
  currency_name character varying NOT NULL,

  -- Exchange rate
  currency_exchange numeric(12,4) NOT NULL
    CHECK (currency_exchange > 0),

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT currency_pkey
    PRIMARY KEY (currency_id)
);


-- ------------------------------------------------------------
-- Product
-- ------------------------------------------------------------

CREATE TABLE public.product (
  product_id uuid NOT NULL DEFAULT gen_random_uuid(),
  product_name character varying NOT NULL UNIQUE,
  description character varying,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  state public.state,

  CONSTRAINT product_pkey
    PRIMARY KEY (product_id)
);


-- ------------------------------------------------------------
-- Unit
-- ------------------------------------------------------------

CREATE TABLE public.unit (
  unit_id uuid NOT NULL DEFAULT gen_random_uuid(),
  unit_name character varying NOT NULL,

  unit_exchange numeric(12,4) NOT NULL
    CHECK (unit_exchange > 0),

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT unit_pkey
    PRIMARY KEY (unit_id)
);


-- ------------------------------------------------------------
-- Parameter
-- ------------------------------------------------------------

CREATE TABLE public.parameter (
  parameter_id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL UNIQUE,
  value uuid NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT parameter_pkey
    PRIMARY KEY (parameter_id)
);


-- ------------------------------------------------------------
-- Binnacle
-- ------------------------------------------------------------

CREATE TABLE public.binnacle (
  binnacle_id uuid NOT NULL DEFAULT gen_random_uuid(),
  object_name character varying NOT NULL,
  change_type character varying NOT NULL,
  old_value text,
  new_value text,
  user_id uuid DEFAULT auth.uid(),
  date timestamp with time zone NOT NULL DEFAULT now(),

  CONSTRAINT binnacle_pkey
    PRIMARY KEY (binnacle_id)
);


-- ============================================================
-- PERSON
-- Depends on:
-- auth.users
-- district
-- ============================================================

CREATE TABLE public.person (
  user_id uuid NOT NULL,

  first_name character varying NOT NULL,
  last_name character varying NOT NULL,
  second_last_name character varying,

  telephone_number character varying NOT NULL UNIQUE,

  birth_date date NOT NULL
    CHECK (
      birth_date <= (CURRENT_DATE - INTERVAL '18 years')
    ),

  user_name character varying NOT NULL UNIQUE,
  identification character varying NOT NULL UNIQUE,

  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),

  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  password_updated_at timestamp with time zone DEFAULT now(),

  role public.role,
  gender public.gender,
  document_type public.document_type,

  district_id uuid,

  CONSTRAINT person_pkey
    PRIMARY KEY (user_id),

  CONSTRAINT person_created_by_fkey
    FOREIGN KEY (created_by)
    REFERENCES auth.users(id),

  CONSTRAINT person_updated_by_fkey
    FOREIGN KEY (updated_by)
    REFERENCES auth.users(id),

  CONSTRAINT person_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES auth.users(id),

  CONSTRAINT person_district_id_fkey
    FOREIGN KEY (district_id)
    REFERENCES public.district(district_id)
);


-- ============================================================
-- MATERIAL
-- Depends on:
-- unit
-- ============================================================

CREATE TABLE public.material (
  material_id uuid NOT NULL DEFAULT gen_random_uuid(),

  unit_id uuid NOT NULL,
  name character varying NOT NULL,

  equivalent_points integer
    CHECK (equivalent_points >= 0),

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),

  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT material_pkey
    PRIMARY KEY (material_id),

  CONSTRAINT material_unit_id_fkey
    FOREIGN KEY (unit_id)
    REFERENCES public.unit(unit_id)
);


-- ============================================================
-- POINT
-- Depends on:
-- person
-- ============================================================

CREATE TABLE public.point (
  person_id uuid NOT NULL,

  point_amount bigint NOT NULL
    CHECK (point_amount >= 0),

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),

  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT point_pkey
    PRIMARY KEY (person_id),

  CONSTRAINT point_person_id_fkey
    FOREIGN KEY (person_id)
    REFERENCES public.person(user_id)
);


-- ============================================================
-- AFFILIATED BUSINESS
-- Depends on:
-- district
-- businesstype
-- email
-- person
-- ============================================================

CREATE TABLE public.affiliatedbusiness (
  affiliated_business_id uuid NOT NULL DEFAULT gen_random_uuid(),

  district_id uuid NOT NULL,
  business_type_id uuid NOT NULL,

  affiliated_business_name character varying NOT NULL UNIQUE,

  phone character varying NOT NULL,

  email bigint NOT NULL,

  description text,

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),

  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  manager_id uuid,

  CONSTRAINT affiliatedbusiness_pkey
    PRIMARY KEY (affiliated_business_id),

  CONSTRAINT affiliatedbussiness_district_id_fkey
    FOREIGN KEY (district_id)
    REFERENCES public.district(district_id),

  CONSTRAINT affiliatedbussiness_business_type_id_fkey
    FOREIGN KEY (business_type_id)
    REFERENCES public.businesstype(business_type_id),

  CONSTRAINT affiliatedbusiness_manager_id_fkey
    FOREIGN KEY (manager_id)
    REFERENCES public.person(user_id),

  CONSTRAINT affiliatedbusiness_email_fkey
    FOREIGN KEY (email)
    REFERENCES public.email(id_email)
);


-- ============================================================
-- COLLECTION CENTER
-- Depends on:
-- person
-- district
-- email
-- ============================================================

CREATE TABLE public.collectioncenter (
  collectioncenter_id uuid NOT NULL DEFAULT gen_random_uuid(),

  person_id uuid NOT NULL,
  district_id uuid NOT NULL,

  name character varying NOT NULL,
  phone character varying NOT NULL,

  -- Manager must reference an existing person.
  manager_id uuid NOT NULL,

  latitude numeric NOT NULL,
  longitude numeric NOT NULL,

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),

  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  email bigint,

  CONSTRAINT collectioncenter_pkey
    PRIMARY KEY (collectioncenter_id),

  CONSTRAINT collectioncenter_person_id_fkey
    FOREIGN KEY (person_id)
    REFERENCES public.person(user_id),

  CONSTRAINT collectioncenter_district_id_fkey
    FOREIGN KEY (district_id)
    REFERENCES public.district(district_id),

  CONSTRAINT collectioncenter_email_fkey
    FOREIGN KEY (email)
    REFERENCES public.email(id_email),

  CONSTRAINT collectioncenter_manager_id_fkey
    FOREIGN KEY (manager_id)
    REFERENCES public.person(user_id)
);


-- ============================================================
-- USER RECYCLING
-- Depends on:
-- person
-- collectioncenter
-- ============================================================

CREATE TABLE public.userrecycling (
  user_recycling uuid NOT NULL DEFAULT gen_random_uuid(),

  person_id uuid NOT NULL,
  collection_center_id uuid NOT NULL,

  amount_recycle numeric NOT NULL,

  date timestamp with time zone DEFAULT now(),

  CONSTRAINT userrecycling_pkey
    PRIMARY KEY (user_recycling),

  CONSTRAINT userrecycling_person_id_fkey
    FOREIGN KEY (person_id)
    REFERENCES public.person(user_id),

  CONSTRAINT userrecycling_collection_center_id_fkey
    FOREIGN KEY (collection_center_id)
    REFERENCES public.collectioncenter(collectioncenter_id)
);


-- ============================================================
-- AFFILIATED BUSINESS x PRODUCT
-- Depends on:
-- product
-- affiliatedbusiness
-- ============================================================

CREATE TABLE public.affiliatedbusinessxproduct (
  affiliated_business_x_prod uuid NOT NULL DEFAULT gen_random_uuid(),

  product_id uuid NOT NULL,
  affiliated_business_id uuid NOT NULL,

  product_price numeric(12,2) NOT NULL
    CHECK (product_price >= 0),

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),

  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT affiliatedbusinessxproduct_pkey
    PRIMARY KEY (affiliated_business_x_prod),

  CONSTRAINT affiliatedbusinessxproduct_product_id_fkey
    FOREIGN KEY (product_id)
    REFERENCES public.product(product_id),

  CONSTRAINT affiliatedbusinessxproduct_affiliated_business_id_fkey
    FOREIGN KEY (affiliated_business_id)
    REFERENCES public.affiliatedbusiness(affiliated_business_id)
);


-- ============================================================
-- COLLECTION CENTER x MATERIAL
-- Depends on:
-- material
-- collectioncenter
-- ============================================================

CREATE TABLE public.collectioncenterxmaterial (
  collection_center_x_product_id uuid NOT NULL DEFAULT gen_random_uuid(),

  material_id uuid NOT NULL,
  collection_center_id uuid NOT NULL,

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),

  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  CONSTRAINT collectioncenterxmaterial_pkey
    PRIMARY KEY (collection_center_x_product_id),

  CONSTRAINT collectioncenterxmaterial_material_id_fkey
    FOREIGN KEY (material_id)
    REFERENCES public.material(material_id),

  CONSTRAINT collectioncenterxmaterial_collection_center_id_fkey
    FOREIGN KEY (collection_center_id)
    REFERENCES public.collectioncenter(collectioncenter_id)
);


-- ============================================================
-- AFFILIATED BUSINESS TRANSACTION
-- Depends on:
-- person
-- affiliatedbusiness
-- currency
-- ============================================================

CREATE TABLE public.affiliatedbusinesstransaction (
  ab_transaction_id uuid NOT NULL DEFAULT gen_random_uuid(),

  person_id uuid NOT NULL,
  affiliated_business_id uuid NOT NULL,
  currency_id uuid NOT NULL,

  total_price numeric(12,2) NOT NULL
    CHECK (total_price > 0),

  transaction_code character varying NOT NULL
    DEFAULT (
      'TXN-' ||
      lpad(
        nextval(
          'affiliatedbusinesstransaction_code_seq'::regclass
        )::text,
        3,
        '0'
      )
    )
    UNIQUE,

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),

  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  state public.state,

  CONSTRAINT affiliatedbusinesstransaction_pkey
    PRIMARY KEY (ab_transaction_id),

  CONSTRAINT affiliatedbusinesstransaction_affiliated_business_id_fkey
    FOREIGN KEY (affiliated_business_id)
    REFERENCES public.affiliatedbusiness(affiliated_business_id),

  CONSTRAINT affiliatedbusinesstransaction_currency_id_fkey
    FOREIGN KEY (currency_id)
    REFERENCES public.currency(currency_id),

  CONSTRAINT affiliatedbusinesstransaction_person_id_fkey
    FOREIGN KEY (person_id)
    REFERENCES public.person(user_id)
);


-- ============================================================
-- COLLECTION CENTER TRANSACTION
-- Depends on:
-- person
-- collectioncenter
-- ============================================================

CREATE TABLE public.collectioncentertransaction (
  cc_transaction_id uuid NOT NULL DEFAULT gen_random_uuid(),

  person_id uuid NOT NULL,
  collection_center_id uuid NOT NULL,

  total_points integer NOT NULL
    CHECK (total_points > 0),

  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),

  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),

  transaction_code character varying NOT NULL
    DEFAULT (
      'TXN-' ||
      lpad(
        nextval(
          'collectioncentertransaction_code_seq'::regclass
        )::text,
        3,
        '0'
      )
    )
    UNIQUE,

  CONSTRAINT collectioncentertransaction_pkey
    PRIMARY KEY (cc_transaction_id),

  CONSTRAINT collectioncentertransaction_collection_center_id_fkey
    FOREIGN KEY (collection_center_id)
    REFERENCES public.collectioncenter(collectioncenter_id),

  CONSTRAINT collectioncentertransaction_person_id_fkey
    FOREIGN KEY (person_id)
    REFERENCES public.person(user_id)
);


-- ============================================================
-- AFFILIATED BUSINESS TRANSACTION ITEM
-- Depends on:
-- affiliatedbusinesstransaction
-- product
-- ============================================================

CREATE TABLE public.affiliatedbusinesstransactionitem (
  item_id uuid NOT NULL DEFAULT gen_random_uuid(),

  ab_transaction_id uuid NOT NULL,
  product_id uuid NOT NULL,

  product_amount integer NOT NULL
    CHECK (product_amount > 0),

  CONSTRAINT affiliatedbusinesstransactionitem_pkey
    PRIMARY KEY (item_id),

  CONSTRAINT affiliatedbusinesstransactionitem_product_id_fkey
    FOREIGN KEY (product_id)
    REFERENCES public.product(product_id),

  CONSTRAINT affiliatedbusinesstransactionitem_ab_transaction_id_fkey
    FOREIGN KEY (ab_transaction_id)
    REFERENCES public.affiliatedbusinesstransaction(ab_transaction_id)
);


-- ============================================================
-- COLLECTION CENTER TRANSACTION ITEM
-- Depends on:
-- collectioncentertransaction
-- material
-- ============================================================

CREATE TABLE public.collectioncentertransactionitem (
  item_id uuid NOT NULL DEFAULT gen_random_uuid(),

  cc_transaction_id uuid NOT NULL,
  material_id uuid NOT NULL,

  material_amount integer NOT NULL
    CHECK (material_amount > 0),

  CONSTRAINT collectioncentertransactionitem_pkey
    PRIMARY KEY (item_id),

  CONSTRAINT collectioncentertransactionitem_cc_transaction_id_fkey
    FOREIGN KEY (cc_transaction_id)
    REFERENCES public.collectioncentertransaction(cc_transaction_id),

  CONSTRAINT collectioncentertransactionitem_material_id_fkey
    FOREIGN KEY (material_id)
    REFERENCES public.material(material_id)
);


-- ============================================================
-- REQUEST
-- Depends on:
-- district
-- businesstype
-- ============================================================

CREATE TABLE public.request (
  request_id uuid NOT NULL DEFAULT gen_random_uuid(),

  district_id uuid NOT NULL,
  business_type_id uuid,

  name character varying NOT NULL,
  phone character varying NOT NULL,
  email character varying NOT NULL,
  description character varying NOT NULL,
  manager character varying NOT NULL,

  latitude numeric,
  longitude numeric,

  CONSTRAINT request_pkey
    PRIMARY KEY (request_id),

  CONSTRAINT request_district_id_fkey
    FOREIGN KEY (district_id)
    REFERENCES public.district(district_id),

  CONSTRAINT request_business_type_id_fkey
    FOREIGN KEY (business_type_id)
    REFERENCES public.businesstype(business_type_id)
);


-- ============================================================
-- REQUEST MATERIAL
-- Depends on:
-- request
-- material
-- ============================================================

CREATE TABLE public.request_material (
  request_material_id uuid NOT NULL DEFAULT gen_random_uuid(),

  request_id uuid NOT NULL,
  material_id uuid NOT NULL,

  CONSTRAINT request_material_pkey
    PRIMARY KEY (request_material_id),

  CONSTRAINT request_material_material_id_fkey
    FOREIGN KEY (material_id)
    REFERENCES public.material(material_id),

  CONSTRAINT request_material_request_id_fkey
    FOREIGN KEY (request_id)
    REFERENCES public.request(request_id)
);


-- ============================================================
-- END OF SCHEMA
-- ============================================================
