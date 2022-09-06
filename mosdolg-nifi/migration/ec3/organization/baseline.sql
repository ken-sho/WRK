--ORGANIZATION
--+---------------------------------------------------------------------------------------------------------------------
--+ Организации
--+---------------------------------------------------------------------------------------------------------------------

--+---------------------------------------------------------------------------------------------------------------------
--+ Создание таблицы sdb.organization
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.organization;
create table if not exists sdb.organization(
    aid bigint primary key,
    short_title character varying,
    full_title character varying,
    inn varchar(12),
    kpp varchar(9),
    ogrn varchar(20),
    parent_organization_id bigint,
    representative_full_name varchar(200),
    representative_position varchar(200),
    website varchar(500),
    email varchar(500),
    phone character varying,
    description character varying,
    unom bigint,
    full_address character varying,
    opf_id int,
    is_provider int,
    is_css_organization int,
    is_dspp_organization int,
    types_providing_services_id int,
    territory_code bigint, -- получаем из TerritoryEntity по адресу te.Id = adr.TerritoryEntityId
    department_id int,
    territory_1_code varchar,
    territory_2_code varchar,
    dtszn_code int
);

--+---------------------------------------------------------------------------------------------------------------------
--+ sdb.ref_recurrence_schedule
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.ref_recurrence_schedule;
create table if not exists sdb.ref_recurrence_schedule(
    id bigint primary key,
    oid bigint, -- оригинальный идентификатор организации
    day_of_week int,
    time_from varchar(32),
    time_to varchar(32)
);

--+---------------------------------------------------------------------------------------------------------------------
--+ sdb.vedomstvo
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.vedomstvo;
create table if not exists sdb.vedomstvo(
    aid bigint primary key,
    title character varying,
    long_title character varying,
    level int
);

--+---------------------------------------------------------------------------------------------------------------------
--+ sdb.ar_address_registry
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.ar_address_registry;
create table if not exists sdb.ar_address_registry(
    short_name character varying,
    AddressId int,	
    district int,
	adm_area int
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Организации (IDB)
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.organization;
create table if not exists idb.organization (
	id bigserial NOT NULL,
	short_title varchar(255) NOT NULL,
	full_title varchar(800) NOT NULL,
	inn int8 NOT NULL,
	kpp int8 NULL,
	ogrn int8 NOT NULL,
	parent_organization_id int8 NULL,
	representative_full_name varchar(800) NULL,
	representative_position varchar(800) NULL,
	website varchar(255) NULL,
	description varchar(800) NULL,
	physical_address int8 NULL,
	legal_address int8 NULL,
	opf_id int8 NOT NULL,
	is_provider bool NOT NULL,
	is_filial bool NOT NULL DEFAULT false,
	level_id int8 NULL,
	type_id int8 NULL,
	territory_id int8 NULL,
	department_id int8 NULL,
	CONSTRAINT organization_pkey PRIMARY KEY (id)
);


drop table if exists idb.territory_organization;
CREATE TABLE if not exists idb.territory_organization (
	organization_id int8 NOT NULL,
	territory_id int8 NOT NULL,
	CONSTRAINT territory_organization_pk UNIQUE (organization_id, territory_id)
--	CONSTRAINT territory_organization_organization_id_fk FOREIGN KEY (organization_id) REFERENCES md.organization(id),
--	CONSTRAINT territory_organization_territory_id_fk FOREIGN KEY (territory_id) REFERENCES ar.territory(id)
);


--+---------------------------------------------------------------------------------------------------------------------
--+ idb.ref_recurrence_schedule -> reference.recurrence_schedule
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.ref_recurrence_schedule;
CREATE TABLE if not exists idb.ref_recurrence_schedule(
	id bigserial NOT NULL,
	organization_id int8 NULL,
	day_of_week varchar(9) NULL,
	time_from time NULL,
	time_to time NULL,
	break_from time NULL,
	break_to time NULL,
	description text NULL,
	CONSTRAINT recurrence_schedule_pkey PRIMARY KEY (id)
--	CONSTRAINT schedule_organization_fk FOREIGN KEY (organization_id) REFERENCES md.organization(id)
);

--+---------------------------------------------------------------------------------------------------------------------
--+ idb.contact_owner -> md.contact_owner
--+---------------------------------------------------------------------------------------------------------------------
-- drop table if exists idb.contact_owner;
CREATE TABLE if not exists idb.contact_owner (
	id bigserial NOT NULL,
	created timestamp NULL,
	modified timestamp NULL,
	CONSTRAINT contact_owner_pkey PRIMARY KEY (id)
);


--+---------------------------------------------------------------------------------------------------------------------
--+ idb.territory_organization -> md.territory_organization
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.territory_organization;
CREATE TABLE if not exists idb.territory_organization (
	organization_id int8 NOT NULL,
	territory_id int8 NOT NULL,
	CONSTRAINT territory_organization_pk UNIQUE (organization_id, territory_id)
--	CONSTRAINT territory_organization_organization_id_fk FOREIGN KEY (organization_id) REFERENCES md.organization(id),
--	CONSTRAINT territory_organization_territory_id_fk FOREIGN KEY (territory_id) REFERENCES ar.territory(id)
);


--+---------------------------------------------------------------------------------------------------------------------
--+ idb.ref_department -> reference.department
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.ref_department;
CREATE TABLE idb.ref_department(
	id bigserial NOT NULL,
	title varchar(255) NOT NULL,
	long_title varchar(1000) NULL,
	"level" bool NOT NULL,
	"key" varchar(64) NOT NULL, -- может быть null?
	CONSTRAINT department_pk PRIMARY KEY (id)
);
--CREATE UNIQUE INDEX department_key_uindex ON reference.department USING btree (key);
