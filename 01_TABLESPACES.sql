create table public.province (
  province_id uuid not null,
  country_id uuid not null,
  province_name character varying not null,
  created_by uuid not null,
  created_at timestamp without time zone not null,
  uploaded_by uuid not null,
  uploaded_at timestamp without time zone not null,
  constraint province_pkey primary key (province_id),
  constraint province_country_id_fkey foreign KEY (country_id) references country (country_id)
) TABLESPACE pg_default;

create table public.currency (
  currency_id uuid not null,
  currency_name character varying not null,
  currency_exchange bigint not null,
  created_by uuid not null,
  created_at timestamp without time zone not null,
  uploaded_by uuid not null,
  uploaded_at timestamp without time zone not null,
  constraint currency_pkey primary key (currency_id)
) TABLESPACE pg_default;

create table public.city (
  city_id uuid not null,
  province_id uuid not null,
  city_name character varying not null,
  created_by uuid not null,
  created_at timestamp without time zone not null,
  uploaded_by uuid not null,
  uploaded_at timestamp without time zone not null,
  constraint city_pkey primary key (city_id),
  constraint city_province_id_fkey foreign KEY (province_id) references province (province_id)
) TABLESPACE pg_default;

create table public.district (
  district_id uuid not null,
  city_id uuid not null,
  district_name character varying not null,
  created_by uuid not null,
  created_at timestamp without time zone not null,
  uploaded_by uuid not null,
  uploaded_at timestamp without time zone not null,
  constraint district_pkey primary key (district_id),
  constraint district_city_id_fkey foreign KEY (city_id) references city (city_id)
) TABLESPACE pg_default;


create table public.country (
  country_id uuid not null,
  country_name character varying not null,
  created_by uuid not null,
  created_at timestamp without time zone not null,
  uploaded_by uuid not null,
  uploaded_at timestamp without time zone not null,
  constraint country_pkey primary key (country_id)
) TABLESPACE pg_default;

create table public.point (
  user_id uuid not null,
  point_amount bigint not null,
  constraint point_pkey primary key (user_id),
  constraint point_user_id_fkey foreign KEY (user_id) references "user" (user_id)
) TABLESPACE pg_default;

create table public.collectioncentertransaction (
  cc_transaction_id uuid primary key not null,
  person_id uuid null,
  collection_center_id uuid null,
  material_id uuid null,
  total_points integer not null,
  material_amount decimal (10,2) not null,
  created_by uuid null,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  updated_by uuid null,
  updated_at timestamp without time zone null default CURRENT_TIMESTAMP
);

create table public.user (
  user_id uuid not null,
  email character varying not null,
  password character varying not null,
  created_by uuid not null,
  created_at timestamp with time zone not null,
  uploaded_by uuid not null,
  uploaded_at timestamp without time zone not null,
  role_id uuid null,
  constraint user_pkey primary key (user_id)
) TABLESPACE pg_default;

create table UserRecycling(
  user_recycling uuid primary key,
  user_id uuid not null,
  collection_center_id uuid not null,
  amount_recycle decimal (10,2) not null,
  created_by uuid not null,
  created_at timestamp default current_timestamp,
  updated_by uuid not null,
  updated_at timestamp default current_timestamp
)

create table Parameter (
  parameter_id uuid primary key,
  name varchar(50) not null,
  value uuid not null,
  created_by uuid not null,
  created_at timestamp default current_timestamp,
  updated_by uuid not null,
  updated_at timestamp default current_timestamp
)

create table State(
  state_id uuid primary key,
  name varchar(50) not null,
  created_by uuid not null,
  created_at timestamp default current_timestamp,
  updated_by uuid not null,
  updated_at timestamp default current_timestamp
)

create table AffiliatedBussiness (
  affiliated_business_id UUID PRIMARY KEY,
  district_id UUID NOT NULL,
  business_type_id UUID NOT NULL,
  affiliated_business_name VARCHAR(50) NOT NULL UNIQUE,
  phone VARCHAR(50) NOT NULL,
  manager_name VARCHAR(50) NOT NULL,
  email VARCHAR(50) NOT NULL,
  description VARCHAR(50),
  created_by UUID,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_by UUID,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

create table BusinessType(
  business_type_type uuid primary key,
  district_id uuid not null,
  name varchar(50) not null, 
  created_by uuid not null,
  created_at timestamp default current_timestamp,
  updated_by uuid not null,
  updated_at timestamp default current_timestamp
)

create table CollectionCenterXMaterial (
  collection_center_x_product_id uuid primary key,
  material_id uuid not null,
  collection_center_id uuid not null,
  created_by uuid not null,
  created_at timestamp default current_timestamp,
  updated_by uuid not null,
  updated_at timestamp default current_timestamp
);


CREATE TABLE AffiliatedBusinessXProduct (
    affiliated_business_x_prod UUID PRIMARY KEY,
    product_id UUID NOT NULL,
    affiliated_business_id UUID NOT NULL,
    product_price INT NOT NULL,
    created_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE Product (
    product_id UUID PRIMARY KEY,
    state_id UUID NOT NULL,
    product_name VARCHAR(50) UNIQUE,
    description VARCHAR(100),
    created_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE AffiliatedBusinessTransaction (
    ab_transaction_id UUID PRIMARY KEY,
    person_id UUID NOT NULL,
    affiliated_business_id UUID NOT NULL,
    currency_id UUID NOT NULL,
    product_id UUID NOT NULL,
    state_id UUID NOT NULL,
    total_price INT NOT NULL,
    product_amount DECIMAL(10,2) NOT NULL,
    transaction_code VARCHAR(100) NOT NULL UNIQUE,
    created_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

create table Unit(
  unit_id uuid primary key,
  unit_name varchar(50) not null,
  unit_exchange int not null,
  created_by uuid not null,
  created_at timestamp default current_timestamp,
  updated_by uuid not null,
  updated_at timestamp default current_timestamp
)

create table public.role (
  role_id uuid not null,
  name character varying not null,
  created_by uuid not null,
  created_at timestamp without time zone not null,
  uploaded_by uuid not null,
  uploaded_at timestamp without time zone not null,
  constraint role_pkey primary key (role_id)
) TABLESPACE pg_default;

create table Material(
  material_id uuid primary key,
  unit_id uuid not null,
  name varchar(50) not null,
  equivalent_points int,
  created_by uuid not null,
  created_at timestamp default current_timestamp,
  updated_by uuid not null,
  updated_at timestamp default current_timestamp
);

CREATE TABLE TypeID (
    type_id UUID PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    created_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Gender (
    gender_id UUID PRIMARY KEY,
    gender_name VARCHAR(50) NOT NULL UNIQUE,
    created_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Person (
    user_id UUID PRIMARY KEY,
    type_id UUID  NOT NULL,
    photo_id UUID  NOT NULL,
    gender_id UUID  NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    second_last_name VARCHAR(100) NOT NULL,
    telephone_number VARCHAR(50) NOT NULL UNIQUE,
    birth_date TIMESTAMP,
    user_name VARCHAR(100) NOT NULL UNIQUE,
    identification NUMERIC(11) NOT NULL UNIQUE,
    created_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

create table CollectionCenter (
  collectionCenter_Id uuid primary key,
  user_Id uuid not null,
  districtId uuid not null,
  name varchar(50) not null,
  phone varchar(50) not null,
  manager_name varchar(50) not null,
  latitude decimal (10,8) not null,
  longitude decimal (10,8) not null,
  created_by uuid not null,
  created_at timestamp default current_timestamp,
  updated_by uuid not null,
  updated_at timestamp default current_timestamp
);


