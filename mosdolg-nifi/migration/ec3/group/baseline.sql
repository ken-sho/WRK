-- 04.09
--+---------------------------------------------------------------------------------------------------------------------
--+ Группы и графики занятий
--+ https://wiki.og.mos.ru/pages/viewpage.action?pageId=9732102

--+ Необходимые таблицы:

--+ sdb.groups
----+ idb.groups
----+ idb.group_status_registry

--+ sdb.schedule
----+ idb.schedule
----+ idb.week_day_schedule

--+ sdb.class_record
----+ idb.class_record
----+ idb.class_record_status_registry

-- противопоказания, дресс-код и инвентарь
-- https://wiki.og.mos.ru/pages/viewpage.action?pageId=9732102

-- sdb.group_contraindication
----+ idb.ref_contraindication
----+ idb.group_contraindication

-- sdb.group_dress_code
----+ idb.ref_dress_code
----+ idb.group_dress_code

-- sdb.group_inventory_requirement
----+ idb.ref_inventory_requirement
----+ idb.group_inventory_requirement


--+---------------------------------------------------------------------------------------------------------------------
--+ sdb.groups
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb."groups";
create table if not exists sdb."groups"(
    aid bigint primary key,
    group_status_id int,
    sc_status_id int,
    coworker_id int,
    need_note int,
    min_count int,
    max_count int,
    plan_start_date varchar(20),
    plan_end_date varchar(20),
    fact_start_date varchar(20),
    fact_end_date varchar(20),
    extend int,
    organization_id int,
    activity_id int,
    contract_id int,
    territory_centre_id int,
    code varchar(200),
    name varchar(300),
		public_date varchar(20),
		order_date varchar(20)
);

--+---------------------------------------------------------------------------------------------------------------------
----+ idb.groups
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb."groups";
CREATE TABLE if not exists idb."groups"(
	id bigserial NOT NULL,
	need_note bool NULL,
	min_count int4 NULL,
	max_count int4 NULL,
	fact_count int4 NULL,
	plan_start_date date NULL,
	plan_end_date date NULL,
	fact_start_date date NULL,
	fact_end_date date NULL,
	extend bool NULL,
	organization_id int8 NULL,
	activity_id int8 NOT NULL,
	"comment" varchar(4000) NULL,
	coworker_id int8 NULL,
	sync bool NULL DEFAULT false,
	contract_id int8 NULL,
	territory_centre_id int8 NULL,
	CONSTRAINT groups_pkey PRIMARY KEY (id),
	esz_code varchar(200),
	order_date date NULL,
	public_date date NULL
--	CONSTRAINT fk_group_status FOREIGN KEY (status_id) REFERENCES reference.group_status(id),
--	CONSTRAINT fk_groups_activity_id FOREIGN KEY (activity_id) REFERENCES reference.activity(id),
--	CONSTRAINT fk_groups_contract_id FOREIGN KEY (contract_id) REFERENCES md.contract(id),
--	CONSTRAINT fk_groups_coworkers_id FOREIGN KEY (coworker_id) REFERENCES md.coworker(id),
--	CONSTRAINT fk_groups_organization_id FOREIGN KEY (organization_id) REFERENCES md.organization(id),
--	CONSTRAINT fk_groups_territory_centre FOREIGN KEY (territory_centre_id) REFERENCES md.organization(id)
);

--+---------------------------------------------------------------------------------------------------------------------
----+ idb.group_status_registry
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.group_status_registry;
CREATE TABLE if not exists idb.group_status_registry(
	id bigserial NOT NULL,
	group_id int8 NOT NULL,
	status_id int8 NOT NULL,
	reason_id int8 NULL,
	"comment" varchar NULL,
	communication_history_id int8 NULL,
	start_date timestamp NOT NULL,
	end_date timestamp NULL,
	is_expectation bool NOT NULL,
	initiator int8 NULL,
	created timestamp NOT NULL DEFAULT now(),
	operation varchar NULL,
	planned_start_date date,
	planned_end_date date,
	CONSTRAINT group_status_registry_pkey PRIMARY KEY (id)
--	CONSTRAINT fk_group_status_registry_group_status FOREIGN KEY (status_id) REFERENCES reference.group_status(id),
--	CONSTRAINT group_status_registry_communication_history_id_fkey FOREIGN KEY (communication_history_id) REFERENCES md.communication_history(id),
--	CONSTRAINT group_status_registry_group_id_fkey FOREIGN KEY (group_id) REFERENCES md.groups(id),
--	CONSTRAINT group_status_registry_initiator_fkey FOREIGN KEY (initiator) REFERENCES md.coworker(id),
--	CONSTRAINT group_status_registry_reason_id_fkey FOREIGN KEY (reason_id) REFERENCES reference.group_status_reason(id)
);

--+---------------------------------------------------------------------------------------------------------------------
--+ sdb.schedule
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.schedule;
create table if not exists sdb.schedule(
    aid bigint primary key,
    group_id int,
    place_id int,
    start_date varchar(20),
    end_date varchar(20),
    start_time varchar(20),
    end_time varchar(20),
    day_of_week int
);

--+---------------------------------------------------------------------------------------------------------------------
----+ idb.schedule
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.schedule;
CREATE TABLE if not exists idb.schedule (
	id bigserial NOT NULL,
	group_id int8 NULL,
	place_id int8 NULL,
	start_time time NULL,
	end_time time NULL,
	start_date date NULL,
	end_date date NULL,
	pause int4 NULL,
	CONSTRAINT schedule_pkey PRIMARY KEY (id)
--	CONSTRAINT fk_schedule_groups_id FOREIGN KEY (group_id) REFERENCES md.groups(id) ON DELETE CASCADE
);

--+---------------------------------------------------------------------------------------------------------------------
----+ idb.week_day_schedule
--+---------------------------------------------------------------------------------------------------------------------
CREATE TABLE if not exists idb.week_day_schedule (
	id bigserial NOT NULL,
	schedule_id int8 NULL,
	place_id int8 NULL,
	start_time time NULL,
	end_time time NULL,
	start_date date NULL,
	end_date date NULL,
	pause int4 NULL,
	day_of_week varchar(255) NULL,
	CONSTRAINT week_day_schedule_pkey PRIMARY KEY (id)
--	CONSTRAINT fk_week_day_schedule_place_id FOREIGN KEY (place_id) REFERENCES md.place(id),
--	CONSTRAINT fk_week_day_schedule_schedule_id FOREIGN KEY (schedule_id) REFERENCES md.schedule(id) ON DELETE CASCADE
);


--+---------------------------------------------------------------------------------------------------------------------
--+ sdb.class_record
--+---------------------------------------------------------------------------------------------------------------------
create table if not exists sdb.class_record(
    aid bigint primary key,
    participant_id int,
    group_id int,
    reques_ad_id int,
    date_from varchar(20),
    date_to varchar(20),
    status_id int
--    group_id int,
--    place_id int,
--    status_id int,
--    request_ad_id int,
--    start_date varchar(20),
--    end_date varchar(20),
--    start_time varchar(20),
--    end_time varchar(20),
--    day_of_week int
);

--+---------------------------------------------------------------------------------------------------------------------
----+ idb.class_record
--+---------------------------------------------------------------------------------------------------------------------
CREATE TABLE if not exists idb.class_record (
	participant_id int8 NOT NULL,
	group_id int8 NOT NULL,
	assigned_at timestamp NULL DEFAULT now(),
	participant_activity_profile_id int8 NOT NULL,
	id bigserial NOT NULL,
	date_from timestamp NULL,
	date_to timestamp NULL,
	pause_date_from timestamp NULL,
	pause_date_to timestamp NULL,
	transferred bool NULL,
	CONSTRAINT pk__participant_group PRIMARY KEY (id)
--	CONSTRAINT fk__participant_group_1 FOREIGN KEY (participant_id) REFERENCES md.participant(id),
--	CONSTRAINT fk__participant_group_2 FOREIGN KEY (group_id) REFERENCES md.groups(id),
--	CONSTRAINT fk_participant_group_activity_profile_id FOREIGN KEY (participant_activity_profile_id) REFERENCES md.participant_activity_profile(id)
);

--+---------------------------------------------------------------------------------------------------------------------
----+ idb.class_record_status_registry
--+---------------------------------------------------------------------------------------------------------------------
CREATE TABLE if not exists idb.class_record_status_registry (
	id bigserial NOT NULL,
	class_record_id int8 NOT NULL,
	class_record_status_id int8 NULL,
	"comment" varchar(10000) NULL,
	communication_history_id int8 NULL,
	start_date date NULL,
	end_date date NULL,
	reason int8 NULL,
	planned_start_date date,
	planned_end_date date,
	CONSTRAINT pk_class_record_status_registry_id PRIMARY KEY (id)
--	CONSTRAINT fk_class_record FOREIGN KEY (class_record_id) REFERENCES md.class_record(id),
--	CONSTRAINT fk_class_record_status FOREIGN KEY (class_record_status_id) REFERENCES reference.class_record_status(id),
--	CONSTRAINT fk_communication_history FOREIGN KEY (communication_history_id) REFERENCES md.communication_history(id),
--	CONSTRAINT fk_reason FOREIGN KEY (reason) REFERENCES reference.class_record_status_reason(id)
);


create table if not exists sdb.group_teachers(
    aid bigint primary key,
    group_aid int,
    teacher_aid int
--    group_id int,
--    place_id int,
--    status_id int,
--    request_ad_id int,
--    start_date varchar(20),
--    end_date varchar(20),
--    start_time varchar(20),
--    end_time varchar(20),
--    day_of_week int
);

create table if not exists sdb.paused_groups(
    group_aid int,
    activity_aid int,
    start_date varchar(20)
);

create table if not exists sdb.paused_class_records(
    aid bigint primary key,
    group_aid int,
    participant_aid int,
    activity_aid int,
    date_from varchar(20),
    date_to varchar(20)
);

--+---------------------------------------------------------------------------------------------------------------------
--+ sdb.group_contraindication
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.group_contraindication;
create table if not exists sdb.group_contraindication(
	aid bigint,
	title varchar(10000)
);

--+---------------------------------------------------------------------------------------------------------------------
--+ idb.ref_contraindication
--+---------------------------------------------------------------------------------------------------------------------
create table if not exists idb.ref_contraindication(
    id bigserial primary key,
    title varchar(10000),
    legacy integer default 0
);

--+---------------------------------------------------------------------------------------------------------------------
--+ idb.group_contraindication
--+---------------------------------------------------------------------------------------------------------------------
create table if not exists idb.group_contraindication(
	group_id bigint,
	contraindication_id bigint
);

--+---------------------------------------------------------------------------------------------------------------------
--+ sdb.group_dress_code
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.group_dress_code;
create table if not exists sdb.group_dress_code(
	aid bigint,
	title varchar(255)
);

--+---------------------------------------------------------------------------------------------------------------------
--+ idb.ref_dress_code
--+---------------------------------------------------------------------------------------------------------------------
create table if not exists idb.ref_dress_code(
    id bigserial primary key,
    title varchar(255),
    legacy integer default 0
);

--+---------------------------------------------------------------------------------------------------------------------
--+ idb.group_dress_code
--+---------------------------------------------------------------------------------------------------------------------
create table if not exists idb.group_dress_code(
	group_id bigint,
	dress_code_id bigint
);

--+---------------------------------------------------------------------------------------------------------------------
--+ sdb.group_inventory_requirement
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.group_inventory_requirement;
create table if not exists sdb.group_inventory_requirement(
	aid bigint,
	title varchar(10000)
);

--+---------------------------------------------------------------------------------------------------------------------
--+ idb.ref_inventory_requirement
--+---------------------------------------------------------------------------------------------------------------------
create table if not exists idb.ref_inventory_requirement(
    id bigserial primary key,
    title varchar(10000),
    legacy integer default 0
);

--+---------------------------------------------------------------------------------------------------------------------
--+ idb.group_inventory_requirement
--+---------------------------------------------------------------------------------------------------------------------
create table if not exists idb.group_inventory_requirement(
    group_id bigint,
    inventory_requirement_id bigint
);