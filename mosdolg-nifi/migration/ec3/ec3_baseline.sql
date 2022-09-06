--BASELINE
--+---------------------------------------------------------------------------------------------------------------------
--+ Миграция из ЕСЗ 1.0
--+---------------------------------------------------------------------------------------------------------------------

drop schema sdb cascade;
drop schema idb cascade;

create schema sdb;
create schema idb;

ALTER SEQUENCE if exists idb.ent_users_id_seq RESTART WITH 1000001;
create sequence if not exists idb.ent_users_id_seq start 1000001;

ALTER SEQUENCE if exists idb.ent_user_profiles_id_seq RESTART WITH 1000001;
create sequence if not exists idb.ent_user_profiles_id_seq start 1000001;

ALTER SEQUENCE if exists idb.ent_user_lock_id_seq RESTART WITH 1000001;
create sequence if not exists idb.ent_user_lock_id_seq start 1000001;

ALTER SEQUENCE if exists idb.contract_document_number_seq RESTART WITH 1000001;
create sequence if not exists idb.contract_document_number_seq start 1000001;

--+-------------------------
--+ Сиквенсы
--+-------------------------
-- соглашения
create sequence idb.contract_id_seq start 101;
create sequence idb.contract_property_id_seq start 101;
create sequence idb.contract_status_registry_id_seq start 101;
-- контакты
create sequence idb.contact_id_seq start 101;
create sequence idb.contact_owner_id_seq start 101;
-- адресный реестр
create sequence idb.ar_address_registry_id_seq start 101;
-- участники
create sequence idb.ref_participant_status_log_id_seq start 101;
create sequence idb.personal_document_id_seq start 101;
create sequence idb.participant_organization_id_seq start 101;
create sequence idb.participant_organization_history_id_seq start 101;
-- площадки
create sequence idb.place_id_seq start 101;
create sequence idb.place_metro_stations_id_seq start 101;
-- профили активности
create sequence idb.participant_activity_profile_id_seq start 101;
-- организации
create sequence idb.ref_recurrence_schedule_id_seq start 101;
create sequence idb.ref_department_id_seq start 101;
create sequence idb.ref_activity_id_seq start 101;
-- группы
create sequence idb.groups_id_seq start 101;
create sequence idb.group_status_registry_id_seq start 101;
create sequence idb.class_record_id_seq start 101;
create sequence idb.class_record_status_registry_id_seq start 101;

CREATE TABLE if not exists idb.ar_address_registry (
	id bigserial NOT NULL,
	aid int8 NULL,
	obj_type int8 NULL,
	address varchar(1024) NULL,
	unom int8 NULL,
	p1 varchar(255) NULL,
	p3 int8 NULL,
	p4 int8 NULL,
	p5 int8 NULL,
	p6 int8 NULL,
	p7 int8 NULL,
	p90 int8 NULL,
	p91 int8 NULL,
	l1_type varchar(255) NULL,
	l1_value varchar(255) NULL,
	l2_type varchar(255) NULL,
	l2_value varchar(255) NULL,
	l3_type varchar(255) NULL,
	l3_value varchar(255) NULL,
	l4_type int8 NULL,
	l4_value varchar(255) NULL,
	l5_type varchar(255) NULL,
	l5_value varchar(255) NULL,
	adm_area int8 NULL,
	district int8 NULL,
	nreg int8 NULL,
	dreg date NULL,
	n_fias varchar NULL,
	d_fias date NULL,
	kladr varchar(255) NULL,
	adr_type varchar(255) NULL,
	sostad varchar(255) NULL,
	status varchar(255) NULL,
	geodata varchar(2048) NULL,
	postal_code varchar(20) NULL,
	ar_object_status_id int8 NOT NULL
--	CONSTRAINT address_registry_pkey PRIMARY KEY (id)
--	CONSTRAINT address_registry_adm_area_fkey FOREIGN KEY (adm_area) REFERENCES ar.territory(id),
--	CONSTRAINT address_registry_ar_object_status_id_fkey FOREIGN KEY (ar_object_status_id) REFERENCES ar.ar_object_status(id),
--	CONSTRAINT address_registry_district_fkey FOREIGN KEY (district) REFERENCES ar.territory(id),
--	CONSTRAINT address_registry_l4_type_fkey FOREIGN KEY (l4_type) REFERENCES ar.room_type(id),
--	CONSTRAINT address_registry_obj_type_fkey FOREIGN KEY (obj_type) REFERENCES ar.address_object_type(id),
--	CONSTRAINT address_registry_p3_fkey FOREIGN KEY (p3) REFERENCES ar.settlement(id),
--	CONSTRAINT address_registry_p4_fkey FOREIGN KEY (p4) REFERENCES ar.city(id),
--	CONSTRAINT address_registry_p5_fkey FOREIGN KEY (p5) REFERENCES ar.territory(id),
--	CONSTRAINT address_registry_p6_fkey FOREIGN KEY (p6) REFERENCES ar.settlement_point(id),
--	CONSTRAINT address_registry_p7_fkey FOREIGN KEY (p7) REFERENCES ar.street(id),
--	CONSTRAINT address_registry_p90_fkey FOREIGN KEY (p90) REFERENCES ar.address_additional(id),
--	CONSTRAINT address_registry_p91_fkey FOREIGN KEY (p91) REFERENCES ar.additional_address_entity(id)
);
--CREATE INDEX address_registry_index_aid ON ar.address_registry USING btree (aid);
--CREATE INDEX indx_address_registry_unom ON ar.address_registry USING btree (unom);

CREATE TABLE if not exists idb.contact(
	id bigserial NOT NULL,
	owner_id int8 NOT NULL,
	contact_owner_type_id int4 NULL,
	contact_type_id int4 NULL,
	value varchar NULL,
	priority int4 NULL,
	contact_availability_type_id int4 NULL,
	CONSTRAINT contact_pkey PRIMARY KEY (id)
--	CONSTRAINT fk_contact_contact_availability_type FOREIGN KEY (contact_availability_type_id) REFERENCES reference.contact_availability_type(id),
--	CONSTRAINT fk_contact_contact_owner FOREIGN KEY (owner_id) REFERENCES md.contact_owner(id),
--	CONSTRAINT fk_contact_contact_owner_type FOREIGN KEY (contact_owner_type_id) REFERENCES reference.contact_owner_type(id),
--	CONSTRAINT fk_contact_contact_type FOREIGN KEY (contact_type_id) REFERENCES reference.contact_type(id)
);


--+---------------------------------------------------------------------------------------------------------------------
--+ Перекодировочные таблицы
--+ В комментарии указываются использующие сущности
--+---------------------------------------------------------------------------------------------------------------------


--+ activity_profile, contract
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.ref_activity_map;
create table if not exists idb.ref_activity_map(
    id bigint,
    aid bigint primary key
);

--+ activity_profile
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.participant_activity_profile_map;
create table if not exists idb.participant_activity_profile_map(
    id bigint,
    aid bigint,
    activity_id int,
    primary key (aid, activity_id)
);

--+ contract
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.contract_map;
create table if not exists idb.contract_map(
    id bigint,
    aid bigint primary key,
    provider_id bigint,
    contract_number varchar
);

--+ participant, activity_profile
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.participant_map;
create table if not exists idb.participant_map(
    id bigint,
    aid bigint primary key
);

--+ coworker, group
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.coworkers_map;
create table if not exists idb.coworkers_map(
    id bigint,
    aid bigint primary key
);

--+ coworker, group
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.teachers_map;
create table if not exists idb.teachers_map(
    id bigint,
    aid bigint primary key
);

--+ coworker, user
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.ent_user_map;
create table if not exists idb.ent_user_map(
    id bigint,
    aid bigint primary key -- содержит id пользователя из ЕСЗ 1.0
);

--+ organization
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.department_map;
create table if not exists idb.department_map(
    id bigint primary key,
    aid bigint
);

--+ contract, coworker, organization
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.organization_map;
create table if not exists idb.organization_map(
    id bigint primary key,
    aid bigint
);

--+ groups, group_status_registry, schedule, class_record
drop table if exists idb.groups_map;
create table if not exists idb.groups_map (
		aid bigint NOT NULL,
		id bigint NOT NULL,
		CONSTRAINT "groups_map_aid" UNIQUE ("aid"),
		CONSTRAINT "groups_map_id" UNIQUE ("id")
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Функции
--+ - Вызываются в разных сущностях, используют перекодировочные таблицы выше
--+---------------------------------------------------------------------------------------------------------------------

create or replace function idb.get_user_id_by_ec3_id(in bigint) returns bigint as $$
declare rslt bigint;
begin
    if $1 isnull then
        return null;
    end if;
    select id into rslt from idb.ent_user_map where aid = $1;
    if rslt isnull then
        select nextval('idb.ent_users_id_seq') into rslt;
        insert into idb.ent_user_map(id, aid) values (rslt, $1);
    end if;
    return rslt;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция добавления адреса в адресном реестре
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.add_full_address(in varchar) returns bigint as
$$
declare result bigint;
begin
    select id into result from idb.ar_address_registry where address=$1;
    if result isnull then
        select nextval('ar.address_registry_id_seq') into result;
        insert into idb.ar_address_registry(id, address, ar_object_status_id, p1) values (result, $1, 2, 10);
    end if;
    return result;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция определения идентификатора в нашей схеме по идентификатору из ЕСЗ
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_organization_id_by_esz_id(in bigint) returns bigint as
$$
declare result bigint;
begin
    if $1 isnull then
        return null;
    end if;
    select id into  result from idb.organization_map where aid = $1;
    if result isnull then
        select nextval('idb.contact_owner_id_seq') into result;
        insert into idb.contact_owner(id, created, modified) values (result, now(), now());
        insert into idb.organization_map(id, aid) values (result, $1);
    end if;
    return result;
end;
$$ language plpgsql;


--+---------------------------------------------------------------------------------------------------------------------
--+ Функция определения идентификатора в нашей схеме по идентификатору из ЕСЗ
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_contract_id_by_esz_id(in bigint) returns bigint as
$$
declare result bigint;
begin
    if $1 isnull then
        return null;
    end if;
    select id into result from idb.contract_map where aid = $1;
    if result isnull then
        select nextval('idb.contract_id_seq') into result;
        insert into idb.contract_map(id, aid) values (result, $1);
    end if;
    return result;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция определения идентификатора в нашей схеме по идентификатору из ЕСЗ
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_department_id_by_vedomstvo_id(in bigint) returns bigint as
$$
declare result bigint;
begin
    if $1 isnull then
        return null;
    end if;
    select id into  result from idb.department_map where aid = $1;
    if result isnull then
        select nextval('idb.ref_department_id_seq') into result;
        insert into idb.department_map(id, aid) values (result, $1);
    end if;
    return result;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция получения id ЕСЗ 2.0 по id ЕСЗ 1.0 и id ЕСЗ 1.0 справочника направления. Результатом является id ЕСЗ 2.0
--+ профиля активности
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_participant_activity_profile_id(in aid bigint, in act_id bigint) returns bigint as
$$
declare
    result bigint;
    mid bigint;
begin
	if aid isnull or act_id isnull then
		return null;
	end if;
    select m.id into result from idb.participant_activity_profile_map m where m.aid = aid and m.activity_id = act_id;
    if result isnull then
        select nextval('idb.participant_activity_profile_id_seq') into result;
        select id into mid from idb.ref_activity_map m where m.aid = $2;
        if mid isnull then
            return null;
        end if;
        insert into idb.participant_activity_profile_map(id, aid, activity_id) values (result, $1, $2);
    end if;
    return result;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция использует перекодировочную таблицу для справочника Направления. Если нет данных в перекодировочной таблице
--+ то берется следующее id из основной последовательности справочника Направления (reference.activity_id_seq) и вносим
--+ информацию в перекодировочную таблицу
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_map_activity_id(in orig_id bigint) returns bigint as
$$
declare result bigint;
begin
    if orig_id isnull then
        return null;
    end if;
    select id into result from idb.ref_activity_map where aid = orig_id;
    if result isnull then
        select nextval('idb.ref_activity_id_seq') into result;
        insert into idb.ref_activity_map(id, aid) values (result, orig_id);
    end if;
    return result;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция получения id ЕСЗ 2.0 по id ЕСЗ 1.0 участника
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_participant_by_ec3(in bigint) returns bigint as
$$
declare
    result bigint;
begin
    if $1 isnull then
        return null;
    end if;
    select id into result from idb.participant_map where aid = $1;
    if result isnull then
        select nextval('idb.contact_owner_id_seq') into result;
        insert into idb.contact_owner(id, created, modified) values (result, now(), now());
        insert into idb.participant_map(id, aid) values (result, $1);
    end if;
    return result;
end
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция получения id ЕСЗ 2.0 через перекодировочную таблицу по id ЕСЗ 1.0 для сотрудников
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_coworkers_id_by_map_id(in bigint) returns bigint as
$$
declare result bigint;
begin
    if $1 isnull then
        return null;
    end if;
    select id into result from idb.coworkers_map where aid=$1;
    if result isnull then
        select nextval('idb.contact_owner_id_seq') into result;
        insert into idb.contact_owner(id, created, modified) values (result, now(), now()) on conflict do nothing;
        insert into idb.coworkers_map(id, aid) values (result, $1);
    end if;
    return result;
end;
$$ language plpgsql;

create or replace function idb.get_teachers_id_by_map_id(in bigint) returns bigint as
$$
declare result bigint;
begin
    if $1 isnull then
        return null;
    end if;
    select id into result from idb.teachers_map where aid=$1;
    if result isnull then
        select nextval('idb.contact_owner_id_seq') into result;
        insert into idb.contact_owner(id, created, modified) values (result, now(), now()) on conflict do nothing;
        insert into idb.teachers_map(id, aid) values (result, $1);
    end if;
    return result;
end;
$$ language plpgsql;


--+---------------------------------------------------------------------------------------------------------------------
--+ Функция определения идентификатора адреса из ЕХД по УНОМу
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_address_id_by_unom(in bigint) returns bigint as
$$
declare result bigint;
begin
    select (select max(arr) into result from unnest(array (select id from ar.address_registry where unom = $1)) arr);
    return result;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция соответствия Время проведения занятий
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_daytime(in bigint) returns int as
$$
declare
    res int;
begin
    case
        when $1 = 1 then
          res := 2;
        when $1 = 2 then
          res:= 3;
        when $1 = 4 then
          res := 4;
        else
          res := null;
    end case;
    return res;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция количество дней недели по типу дней недели для профиля активности
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_profile_active_weekdays_by_typeid(in bigint) returns int array as
$$
declare
    res int array;
begin
    case
        when $1 = 0 then
            res := '{0,1,2,3,4}';
        when $1 = 1 then
            res := '{5,6}';
        else
            res := null;
    end case;
    return res;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция добавления адреса в адресном реестре
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_address_id_by_unom_address(in p_unom varchar, in p_address varchar) returns bigint as
$$
declare result bigint;
begin
    if p_unom is not null then
        select id into result from ar.address_registry where unom is not null and unom = cast(p_unom as bigint) order by id desc limit 1;
    end if;
    if result isnull then
        select nextval('ar.address_registry_id_seq') into result;
        if p_unom isnull then
            insert into ar.address_registry(id, address, unom, ar_object_status_id) values (result, p_address, 0, 2);
        else
            insert into ar.address_registry(id, address, unom, ar_object_status_id) values (result, p_address, cast(p_unom as bigint), 2);
        end if;
    end if;
    return result;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Функция получения id ЕСЗ 2.0 по id ЕСЗ 1.0 группы
--+---------------------------------------------------------------------------------------------------------------------
create or replace function idb.get_group_id_by_map_aid(i_aid bigint)	RETURNS bigint AS
$body$
DECLARE
	gr_id bigint;
BEGIN
	select id into gr_id from idb.groups_map where aid = i_aid;
	if gr_id isnull then
		select nextval('idb.groups_id_seq') into gr_id;
		insert into idb.groups_map(id, aid) values (gr_id, i_aid);
	end if;
	return gr_id;
END
$body$
	language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Валидация
--+---------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS idb.fallout_rule CASCADE;
CREATE TABLE if not exists idb.fallout_rule
(
    id                      int PRIMARY KEY,
    name                    varchar
);
INSERT INTO idb.fallout_rule(id, name) values (1, 'PRIMARY_KEY_CONSTRAINT');
INSERT INTO idb.fallout_rule(id, name) values (2, 'FOREIGN_KEY_CONSTRAINT');
INSERT INTO idb.fallout_rule(id, name) values (3, 'UNIQUE/DUPLICATE_VALUE_CONSTRAINT');

DROP TABLE IF EXISTS idb.fallout_report;
CREATE TABLE if not exists idb.fallout_report
(
    id                           bigserial PRIMARY KEY,
    session_id                   uuid      NOT NULL,
    rule_id                      int       REFERENCES idb.fallout_rule (id),
    table_name                   varchar   NULL,
    column_name                  varchar   NULL,
    record_id                    bigint    NOT NULL,
    value                        varchar   NULL
);