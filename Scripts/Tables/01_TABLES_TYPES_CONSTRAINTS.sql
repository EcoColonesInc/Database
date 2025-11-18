-- Types

CREATE TYPE public.role as ENUM('admin', 'user', 'affiliate', 'center');
CREATE TYPE public.gender as ENUM('male', 'female', 'other');
CREATE TYPE public.document_type as ENUM('passport', 'dimex', 'id');
CREATE TYPE public.state as ENUM('active', 'inactive');

-- Tables

/*
 * The following SQL script creates the tables that will be referenced.
 * The exception is the "person" table, which references the "auth.users" table.
 */

-- Person Table
CREATE TABLE public.person (
  user_id uuid NOT NULL,
  first_name character varying NOT NULL DEFAULT NULL::character varying,
  last_name character varying NOT NULL DEFAULT NULL::character varying,
  second_last_name character varying DEFAULT NULL::character varying,
  telephone_number character varying NOT NULL DEFAULT NULL::character varying UNIQUE,
  birth_date date NOT NULL CHECK (birth_date <= (CURRENT_DATE - '18 years'::interval)),
  user_name character varying NOT NULL DEFAULT NULL::character varying UNIQUE,
  identification character varying NOT NULL UNIQUE,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  password_updated_at timestamp with time zone DEFAULT now(),
  role public.role,
  gender public.gender,
  document_type public.document_type,
  CONSTRAINT person_pkey PRIMARY KEY (user_id),
  CONSTRAINT person_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id),
  CONSTRAINT person_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id),
  CONSTRAINT person_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Email Table
CREATE TABLE public.email (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  email character varying NOT NULL,
  CONSTRAINT email_pkey PRIMARY KEY (id)
);

-- Business Type Table
CREATE TABLE public.businesstype (
  business_type_id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT businesstype_pkey PRIMARY KEY (business_type_id)
);

-- Currency Table
CREATE TABLE public.currency (
  currency_id uuid NOT NULL DEFAULT gen_random_uuid(),
  currency_name character varying NOT NULL,
  currency_exchange bigint NOT NULL CHECK (currency_exchange > 0),
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT currency_pkey PRIMARY KEY (currency_id)
);

-- Country Table
CREATE TABLE public.country (
  country_id uuid NOT NULL,
  country_name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT country_pkey PRIMARY KEY (country_id)
);

-- Product Table
CREATE TABLE public.product (
  product_id uuid NOT NULL DEFAULT gen_random_uuid(),
  product_name character varying NOT NULL UNIQUE,
  description character varying,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  state public.state,
  CONSTRAINT product_pkey PRIMARY KEY (product_id)
);

-- Unit Table
CREATE TABLE public.unit (
  unit_id uuid NOT NULL DEFAULT gen_random_uuid(),
  unit_name character varying NOT NULL,
  unit_exchange integer NOT NULL CHECK (unit_exchange > 0),
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT unit_pkey PRIMARY KEY (unit_id)
);

-- Parameter Table
CREATE TABLE public.parameter (
  parameter_id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL UNIQUE,
  value uuid NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT parameter_pkey PRIMARY KEY (parameter_id)
);

-- Binnacle Table
CREATE TABLE public.binnacle (
  binnacle_id uuid NOT NULL DEFAULT gen_random_uuid(),
  object_name character varying NOT NULL,
  change_type character varying NOT NULL,
  old_value text,
  new_value text,
  user_id uuid DEFAULT auth.uid(),
  date timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT binnacle_pkey PRIMARY KEY (binnacle_id)
);

/*
 * The following SQL script creates the tables that used foreign key references from
 * the tables without foreign key references.
 * This tables has only one foreign key reference per table.
 */

-- Material Table
CREATE TABLE public.material (
  material_id uuid NOT NULL DEFAULT gen_random_uuid(),
  unit_id uuid NOT NULL,
  name character varying NOT NULL,
  equivalent_points integer CHECK (equivalent_points >= 0),
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT material_pkey PRIMARY KEY (material_id),
  CONSTRAINT material_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.unit(unit_id)
);

-- Point Table
CREATE TABLE public.point (
  person_id uuid NOT NULL,
  point_amount bigint NOT NULL CHECK (point_amount >= 0),
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT point_pkey PRIMARY KEY (person_id),
  CONSTRAINT point_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(user_id)
);

-- Province Table
CREATE TABLE public.province (
  province_id uuid NOT NULL DEFAULT gen_random_uuid(),
  country_id uuid NOT NULL,
  province_name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT province_pkey PRIMARY KEY (province_id),
  CONSTRAINT province_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.country(country_id)
);

-- City Table
CREATE TABLE public.city (
  city_id uuid NOT NULL DEFAULT gen_random_uuid(),
  province_id uuid NOT NULL,
  city_name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT city_pkey PRIMARY KEY (city_id),
  CONSTRAINT city_province_id_fkey FOREIGN KEY (province_id) REFERENCES public.province(province_id)
);

-- District Table
CREATE TABLE public.district (
  district_id uuid NOT NULL DEFAULT gen_random_uuid(),
  city_id uuid NOT NULL,
  district_name character varying NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT district_pkey PRIMARY KEY (district_id),
  CONSTRAINT district_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city(city_id)
);

/*
 * The following SQL script creates the tables that used foreign key references from
 * the tables before.
 * These tables has two foreign key references per table.
 */

-- Affiliated Business Table
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
  CONSTRAINT affiliatedbusiness_pkey PRIMARY KEY (affiliated_business_id),
  CONSTRAINT affiliatedbussiness_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.district(district_id),
  CONSTRAINT affiliatedbussiness_business_type_id_fkey FOREIGN KEY (business_type_id) REFERENCES public.businesstype(business_type_id),
  CONSTRAINT affiliatedbusiness_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.person(user_id),
  CONSTRAINT affiliatedbusiness_email_fkey FOREIGN KEY (email) REFERENCES public.email(id)
);

-- Collection Center Table
CREATE TABLE public.collectioncenter (
  collectioncenter_id uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL,
  district_id uuid NOT NULL,
  name character varying NOT NULL,
  phone character varying NOT NULL,
  manager_id uuid NOT NULL DEFAULT gen_random_uuid(),
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  email bigint,
  CONSTRAINT collectioncenter_pkey PRIMARY KEY (collectioncenter_id),
  CONSTRAINT collectioncenter_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(user_id),
  CONSTRAINT collectioncenter_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.district(district_id),
  CONSTRAINT collectioncenter_email_fkey FOREIGN KEY (email) REFERENCES public.email(id),
  CONSTRAINT collectioncenter_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.person(user_id)
);

/*
 * The following SQL script creates the tables that has multiple foreign key references or
 * needs a reference from the tables in the previous section.
 */

-- User Recycling Table
CREATE TABLE public.userrecycling (
  user_recycling uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL,
  collection_center_id uuid NOT NULL,
  amount_recycle numeric NOT NULL,
  date timestamp with time zone DEFAULT now(),
  CONSTRAINT userrecycling_pkey PRIMARY KEY (user_recycling),
  CONSTRAINT userrecycling_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(user_id),
  CONSTRAINT userrecycling_collection_center_id_fkey FOREIGN KEY (collection_center_id) REFERENCES public.collectioncenter(collectioncenter_id)
);

-- Affiliated Business x Product Table
CREATE TABLE public.affiliatedbusinessxproduct (
  affiliated_business_x_prod uuid NOT NULL DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL,
  affiliated_business_id uuid NOT NULL,
  product_price integer NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT affiliatedbusinessxproduct_pkey PRIMARY KEY (affiliated_business_x_prod),
  CONSTRAINT affiliatedbusinessxproduct_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id),
  CONSTRAINT affiliatedbusinessxproduct_affiliated_business_id_fkey FOREIGN KEY (affiliated_business_id) REFERENCES public.affiliatedbusiness(affiliated_business_id)
);

-- Collection Center x Material Table
CREATE TABLE public.collectioncenterxmaterial (
  collection_center_x_product_id uuid NOT NULL DEFAULT gen_random_uuid(),
  material_id uuid NOT NULL,
  collection_center_id uuid NOT NULL,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT collectioncenterxmaterial_pkey PRIMARY KEY (collection_center_x_product_id),
  CONSTRAINT collectioncenterxmaterial_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.material(material_id),
  CONSTRAINT collectioncenterxmaterial_collection_center_id_fkey FOREIGN KEY (collection_center_id) REFERENCES public.collectioncenter(collectioncenter_id)
);

-- Affiliated Business Transaction Table
CREATE TABLE public.affiliatedbusinesstransaction (
  ab_transaction_id uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL,
  affiliated_business_id uuid NOT NULL,
  currency_id uuid NOT NULL,
  product_id uuid NOT NULL,
  total_price integer NOT NULL CHECK (total_price > 0),
  product_amount numeric NOT NULL CHECK (product_amount > 0::numeric),
  transaction_code character varying NOT NULL UNIQUE,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  state public.state,
  CONSTRAINT affiliatedbusinesstransaction_pkey PRIMARY KEY (ab_transaction_id),
  CONSTRAINT affiliatedbusinesstransaction_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(user_id),
  CONSTRAINT affiliatedbusinesstransaction_affiliated_business_id_fkey FOREIGN KEY (affiliated_business_id) REFERENCES public.affiliatedbusiness(affiliated_business_id),
  CONSTRAINT affiliatedbusinesstransaction_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currency(currency_id),
  CONSTRAINT affiliatedbusinesstransaction_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id)
);

-- Collection Center Transaction Table
CREATE TABLE public.collectioncentertransaction (
  cc_transaction_id uuid NOT NULL DEFAULT gen_random_uuid(),
  person_id uuid,
  collection_center_id uuid NOT NULL,
  material_id uuid NOT NULL,
  total_points integer NOT NULL CHECK (total_points > 0),
  material_amount numeric NOT NULL CHECK (material_amount > 0::numeric),
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_by uuid,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT collectioncentertransaction_pkey PRIMARY KEY (cc_transaction_id),
  CONSTRAINT collectioncentertransaction_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.material(material_id),
  CONSTRAINT collectioncentertransaction_collection_center_id_fkey FOREIGN KEY (collection_center_id) REFERENCES public.collectioncenter(collectioncenter_id),
  CONSTRAINT collectioncentertransaction_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(user_id)
);
