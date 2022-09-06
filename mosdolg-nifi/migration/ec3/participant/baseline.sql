--+ PARTICIPANT
--+ Личное дело - Участники

--+ Необходимые таблицы:
--+ sdb.participant
----+ idb.participant
----+ idb.contact
----+ idb.contact_owner
----+ idb.personal_document
----+ idb.ref_participant_status_log

--+ Зависит от
--+ idb.participant_map
--+ idb.ar_address_registry

--+---------------------------------------------------------------------------------------------------------------------

--+---------------------------------------------------------------------------------------------------------------------
--+ создание migration.participant (Личное дело - Участники)
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.participant;
create table if not exists sdb.participant(
    aid bigint primary key,
    status_id int,
    first_name character varying,
    second_name character varying,
    patronymic character varying,
    date_of_birth character varying,
    gender int,
    home_phone_number character varying,
    personal_phone_number character varying,
    email character varying,
    snils character varying,
    skm character varying,
    skm_series character varying,
    reg_full_address character varying,
    fct_full_address character varying,
    document_type_id bigint,
    serial_number character varying,
    date_from character varying,
    department character varying,
    department_code character varying,
    pupil_decline_reason_id int,
    organization_id int,
    reg_adr_district int,
    fact_adr_district int,
    p_date_create varchar
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
--+ Участники idb.participant -> md.participant
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.participant;
CREATE TABLE if not exists idb.participant (
	id bigserial NOT NULL,
--	status_id int8 NULL,
	first_name varchar(100) NOT NULL,
	second_name varchar(100) NOT NULL,
	patronymic varchar(100) NULL,
	no_patronymic bool NULL,
	date_of_birth date NULL,
	gender int8 NULL,
	snils varchar(100) NULL,
	skm varchar(100) NULL,
	registration_address int8 NULL,
	fact_address int8 NULL,
	required_documents bool NULL DEFAULT false,
	occupation_id int4 NULL,
	agreement bool NOT NULL DEFAULT false,
	documents_absence_reason_id int8 NULL,
	sync bool NULL DEFAULT false,
	skm_series varchar(16) NULL,
	organization_id int8 NULL,
	CONSTRAINT pk_table_id PRIMARY KEY (id)
--	CONSTRAINT fk_participant_documents_absence_reason FOREIGN KEY (documents_absence_reason_id) REFERENCES reference.documents_absence_reason(id),
--	CONSTRAINT fk_participant_gender FOREIGN KEY (gender) REFERENCES reference.gender(id),
--	CONSTRAINT fk_participant_occupation FOREIGN KEY (occupation_id) REFERENCES reference.occupation(id),
--	CONSTRAINT fk_participant_status FOREIGN KEY (status_id) REFERENCES reference.participant_status(id),
--	CONSTRAINT participant_fact_address_fk FOREIGN KEY (fact_address) REFERENCES ar.address_registry(id),
--	CONSTRAINT participant_registration_address_fk FOREIGN KEY (registration_address) REFERENCES ar.address_registry(id)
);
--CREATE INDEX idx_participant_status_id ON md.participant USING btree (status_id);

--+---------------------------------------------------------------------------------------------------------------------
--+ Участники idb.personal_document -> md.personal_document
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.personal_document;
CREATE TABLE if not exists idb.personal_document(
	id bigserial NOT NULL,
	participant_id int8 NULL,
	document_type_id int8 NULL,
	serial_number varchar(100) NULL,
	date_from date NULL,
	department varchar(1000) NULL,
	department_code varchar(1000) NULL,
	date_to date NULL,
	CONSTRAINT pk_personal_document_id PRIMARY KEY (id)
--	CONSTRAINT fk_personal_document_document_type FOREIGN KEY (document_type_id) REFERENCES reference.document_type(id),
--	CONSTRAINT fk_personal_document_participant FOREIGN KEY (participant_id) REFERENCES md.participant(id)
);
--CREATE INDEX idx_personal_document_document_type_id ON md.personal_document USING btree (document_type_id);
--CREATE INDEX idx_personal_document_participant_id ON md.personal_document USING btree (participant_id);
drop table if exists idb.ref_participant_status_log;
CREATE TABLE if not exists idb.ref_participant_status_log (
	id bigserial NOT NULL,
	participant_id int8 NOT NULL,
	status_id int8, -- NOT NULL, -- NOT NULL убран потому что базово участники приходят или со статусом 1 или без статуса, статус добавляется позже
	"comment" varchar(10000) NULL,
	start_date timestamp NULL,
	reason_id int8 NULL,
	end_date timestamp NULL,
	planned_start_date date NULL,
	planned_end_date date NULL,
	CONSTRAINT participant_status_log_pkey PRIMARY KEY (id)
--	CONSTRAINT fk_participant_status_log_participant FOREIGN KEY (participant_id) REFERENCES md.participant(id) ON DELETE CASCADE,
--	CONSTRAINT fk_participant_status_log_reason FOREIGN KEY (reason_id) REFERENCES reference.participant_status_reason(id),
--	CONSTRAINT fk_participant_status_log_status FOREIGN KEY (status_id) REFERENCES reference.participant_status(id)
);

-- Связь с организациями

create table sdb.participant_organizations (
    participant_aid int,
    organization_aid int,
    date_created varchar
);

drop table if exists idb.participant_organization;
CREATE TABLE idb.participant_organization (
	participant_id int8 NOT NULL,
	organization_id int8 NOT NULL,
	link_type varchar(25) NOT NULL,
	id bigserial NOT NULL,
	enabled bool NOT NULL DEFAULT true,
	CONSTRAINT participant_organization_pkey PRIMARY KEY (id)
);

drop table if exists idb.participant_organization_history;
CREATE TABLE idb.participant_organization_history (
	id bigserial NOT NULL,
	participant_organization_id int8 NOT NULL,
	date_created timestamp NULL,
	created_by varchar(50) NULL,
	enabled bool NOT NULL,
	CONSTRAINT participant_organization_history_pkey PRIMARY KEY (id)
	-- CONSTRAINT history_participant_organization_fkey FOREIGN KEY (participant_organization_id) REFERENCES md.participant_organization(id)
);
