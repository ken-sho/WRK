--+---------------------------------------------------------------------------------------------------------------------
--+ Сущность Пользователи и роли
--+---------------------------------------------------------------------------------------------------------------------

--+---------------------------------------------------------------------------------------------------------------------
--+ Создаем схемы idb в БД idm
--+---------------------------------------------------------------------------------------------------------------------
create schema if not exists idb;
create schema if not exists sdb;

ALTER SEQUENCE if exists idb.ent_users_id_seq RESTART WITH 400001;
create sequence if not exists idb.ent_users_id_seq start 400001;

ALTER SEQUENCE if exists idb.ent_user_profiles_id_seq RESTART WITH 400001;
create sequence if not exists idb.ent_user_profiles_id_seq start 400001;

ALTER SEQUENCE if exists idb.ent_user_lock_id_seq RESTART WITH 400001;
create sequence if not exists idb.ent_user_lock_id_seq start 400001;

ALTER SEQUENCE if exists idb.dep_user_profiles_roles_id_seq RESTART WITH 400001;
create sequence if not exists idb.dep_user_profiles_roles_id_seq start 400001;

--+---------------------------------------------------------------------------------------------------------------------
--+ Таблица для миграционных данных Пользователи (sdb.ent_user)  БД longevity
--+---------------------------------------------------------------------------------------------------------------------
--create table if not exists sdb.ent_user(
--    aid bigint primary key,
--    name character varying,
--    email character varying,
--    phone character varying,
--    organization_id bigint,
--    creation_date character varying,
--    last_login character varying,
--    login character varying,
--    user_status_id int,
--    is_blocked_by_auth_attempts int,
--    lock_form character varying,
--    password_hash character varying,
--    password_salt character varying,
--    password_last_change_date character varying
--);

--+---------------------------------------------------------------------------------------------------------------------
--+ Таблица для миграции данных по Ролям (sdb.ent_role) БД longevity
--+---------------------------------------------------------------------------------------------------------------------
-- На текущий момент(27.05.2019) их не переносим

--+---------------------------------------------------------------------------------------------------------------------
--+ Таблица для предпоготовки перед валидацией для Пользователей (idb.ent_user) БД idm
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.ent_users;
create table if not exists sdb.ent_users(
    id bigint primary key, -- содержит id пользователя из ЕСЗ 1.0
    lastname varchar(255),
    firstname varchar(255),
    middlename varchar(255),
    email varchar(255),
    phone varchar(16),
    creation_date character varying,
    last_login character varying
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Таблица для предпоготовки перед валидацией для Профилей пользователей (idb.ent_user_profile) и
--+ Профилей внутренних пользователей (idb.ent_local_user_profile) БД idm
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.ent_user_profile;
create table if not exists sdb.ent_user_profile(
    userid bigint primary key, -- содержит id пользователя из ЕСЗ 1.0
    login varchar(255),
    password varchar(100),
    password_last_change_date character varying
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Таблица для предпоготовки перед валидацией для Блокировок пользователей (idb.ent_user_lock) БД idm
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.ent_user_lock;
create table if not exists sdb.ent_user_lock(
    user_id bigint primary key, -- содержит id пользователя из ЕСЗ 1.0
    lock_from character varying,
    type character varying
);

drop table if exists sdb.dep_user_profiles_roles;
create table if not exists sdb.dep_user_profiles_roles(
    aid bigint,
    role_id bigint
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Перекодировочная таблица Пользователей (idb.ent_user_map) - необходимо выполнить в обоих БД: idm, longevity
--+---------------------------------------------------------------------------------------------------------------------


drop table if exists idb.ent_users;
CREATE TABLE if not exists idb.ent_users (
	id bigserial NOT NULL,
	lastname varchar(255) NULL,
	firstname varchar(255) NULL,
	middlename varchar(255) NULL,
	email varchar(255) NULL,
	organizationid int8 NULL,
	"attributes" json NULL,
	creation_date timestamp NULL,
	removal_date timestamptz NULL,
	phone varchar(16) NULL,
	locale varchar(8) NULL,
	active_from timestamp NULL,
	active_to timestamp NULL,
	last_login timestamp NULL,
	CONSTRAINT table_pkey PRIMARY KEY (id)
--	CONSTRAINT users_fk FOREIGN KEY (organizationid) REFERENCES ent_organizations(id)
);


drop table if exists idb.new_users;
CREATE TABLE if not exists idb.new_users (
	id bigserial NOT NULL,
	lastname varchar(255) NULL,
	firstname varchar(255) NULL,
	middlename varchar(255) NULL,
	email varchar(255) NULL,
	organizationid int8 NULL,
	"attributes" json NULL,
	creation_date timestamp NULL,
	removal_date timestamptz NULL,
	phone varchar(16) NULL,
	locale varchar(8) NULL,
	active_from timestamp NULL,
	active_to timestamp NULL,
	last_login timestamp NULL,
	CONSTRAINT table_new_users_pkey PRIMARY KEY (id)
--	CONSTRAINT users_fk FOREIGN KEY (organizationid) REFERENCES ent_organizations(id)
);
--CREATE INDEX ent_users_idx ON public.ent_users USING btree (lastname);
--CREATE INDEX ent_users_idx1 ON public.ent_users USING btree (email);
--CREATE INDEX ent_users_idx2 ON public.ent_users USING btree (organizationid);
--CREATE INDEX ent_users_removal_date_idx ON public.ent_users USING btree (removal_date);


drop table if exists idb.ent_local_user_profiles;
CREATE TABLE if not exists idb.ent_local_user_profiles (
	id bigserial NOT NULL,
	"password" varchar(100) NULL,
	password_expired_date timestamp NULL,
	passwordhistory json NULL,
	blacklist json NULL,
	removal_date timestamptz NULL,
	password_last_change_date timestamp NOT NULL DEFAULT now(),
	CONSTRAINT local_profiles_pkey PRIMARY KEY (id)
);
-- CREATE INDEX ent_local_profiles_removal_date_idx ON public.ent_local_user_profiles USING btree (removal_date);
drop table if exists idb.ent_user_profiles;
CREATE TABLE if not exists idb.ent_user_profiles (
	id bigserial NOT NULL,
	userid int8 NOT NULL,
	login varchar(255) NOT NULL,
	resourceid int4 NOT NULL,
	removal_date timestamptz NULL,
	first_login_date timestamptz NULL,
	CONSTRAINT table_user_profiles_pkey PRIMARY KEY (id)
--	CONSTRAINT user_profiles_fk FOREIGN KEY (userid) REFERENCES ent_users(id)
);
--CREATE INDEX ent_profiles_removal_date_idx ON public.ent_user_profiles USING btree (removal_date);
--CREATE INDEX ent_user_profiles_idx ON public.ent_user_profiles USING btree (userid);
--CREATE INDEX ent_user_profiles_idx1 ON public.ent_user_profiles USING btree (login);
--CREATE INDEX ent_user_profiles_idx2 ON public.ent_user_profiles USING btree (resourceid);
drop table if exists idb.ent_user_lock;
CREATE TABLE if not exists idb.ent_user_lock (
	id bigserial NOT NULL,
	user_id int8 NULL,
	lock_from timestamp NOT NULL,
	lock_to timestamp NULL,
	"type" varchar(32) NOT NULL DEFAULT 'MANUAL'::character varying,
	CONSTRAINT ent_user_lock_pkey PRIMARY KEY (id)
--	CONSTRAINT ent_user_lock_user_id_fkey FOREIGN KEY (user_id) REFERENCES ent_users(id)
);
--CREATE INDEX user_lock_userid_idx ON public.ent_user_lock USING btree (user_id);

create table if not exists idb.ent_user_profiles_map (
    user_aid bigserial not null,
    profile_id bigserial not null
);


create table if not exists idb.dep_user_profiles_roles(
    id bigserial NOT NULL,
	entityid int8 NOT NULL,
	roleid int8 NOT NULL,
	datefrom timestamp NULL,
	dateto timestamp NULL
);


-- Для этого нужно чтобы на сервере был создан postgres fdw для idm базы

drop foreign table if exists idb.foreign_ent_users;
CREATE FOREIGN table if not exists idb.foreign_ent_users (
    id bigserial NOT NULL,
	lastname varchar(255) NULL,
	firstname varchar(255) NULL,
	middlename varchar(255) NULL,
	email varchar(255) NULL,
	organizationid int8 NULL,
	"attributes" json NULL,
	creation_date timestamp NULL,
	removal_date timestamptz NULL,
	phone varchar(16) NULL,
	locale varchar(8) NULL,
	active_from timestamp NULL,
	active_to timestamp NULL,
	last_login timestamp NULL
	--CONSTRAINT table_pkey PRIMARY KEY (id)
) SERVER idm_server
OPTIONS (schema_name 'public', table_name 'ent_users');

drop foreign table if exists idb.foreign_ent_local_user_profiles;
CREATE foreign TABLE if not exists idb.foreign_ent_local_user_profiles (
	id bigserial NOT NULL,
	"password" varchar(100) NULL,
	password_expired_date timestamp NULL,
	passwordhistory json NULL,
	blacklist json NULL,
	removal_date timestamptz NULL,
	password_last_change_date timestamp NOT NULL DEFAULT now()
--	CONSTRAINT local_profiles_pkey PRIMARY KEY (id)
) SERVER idm_server
OPTIONS (schema_name 'public', table_name 'ent_local_user_profiles');

drop foreign table if exists idb.foreign_ent_user_profiles;
CREATE foreign TABLE if not exists idb.foreign_ent_user_profiles (
	id bigserial NOT NULL,
	userid int8 NOT NULL,
	login varchar(255) NOT NULL,
	resourceid int4 NOT NULL,
	removal_date timestamptz NULL,
	first_login_date timestamptz NULL
) SERVER idm_server
OPTIONS (schema_name 'public', table_name 'ent_user_profiles');

drop foreign table if exists idb.foreign_ent_user_lock;
CREATE foreign TABLE if not exists idb.foreign_ent_user_lock (
	id bigserial NOT NULL,
	user_id int8 NULL,
	lock_from timestamp NOT NULL,
	lock_to timestamp NULL,
	"type" varchar(32) NOT NULL DEFAULT 'MANUAL'::character varying
) SERVER idm_server
OPTIONS (schema_name 'public', table_name 'ent_user_lock');

drop foreign table if exists idb.foreign_dep_user_profiles_roles;
CREATE foreign TABLE if not exists idb.foreign_dep_user_profiles_roles (
    id bigserial NOT NULL,
	entityid int8 NOT NULL,
	roleid int8 NOT NULL,
	datefrom timestamp NULL,
	dateto timestamp NULL
--	CONSTRAINT user_profiles_roles_pkey PRIMARY KEY (id),
--	CONSTRAINT user_profiles_roles_fk FOREIGN KEY (entityid) REFERENCES ent_user_profiles(id) ON DELETE CASCADE,
--	CONSTRAINT user_profiles_roles_fk1 FOREIGN KEY (roleid) REFERENCES ent_roles(id) ON DELETE CASCADE
) SERVER idm_server
OPTIONS (schema_name 'public', table_name 'dep_user_profiles_roles');


