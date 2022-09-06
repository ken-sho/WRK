-- 26.08
-- Подготовка
-------------
truncate table idb.participant;
--truncate table idb.participant_map;
truncate table idb.ar_address_registry;
truncate table idb.personal_document;

truncate table idb.participant_organization;
truncate table idb.participant_organization_history;
truncate table idb.ref_participant_status_log;
delete from idb.contact c where c.contact_owner_type_id=1;
delete from idb.contact_owner where id in (select ow.id from idb.contact_owner ow join idb.contact c on c.owner_id=ow.id where c.contact_owner_type_id=1);


-- добавляем индекс для полнотекстового поиска по регистру адресов
create INDEX if not exists "idx_address" ON idb.ar_address_registry ("address");


-- вспомогательная функция
-- маппинг sdb.participant.aid на наш внутренний md.participant.id
create or replace function idb.participant_aid_to_id(
	i_aid bigint
)
RETURNS void as
$body$
DECLARE
    pt_id bigint;
begin
    select nextval('idb.contact_owner_id_seq') into pt_id;
    insert into idb.contact_owner(id, created, modified) values (pt_id, now(), now());
    insert into idb.participant_map(id, aid) values (pt_id, i_aid);
end
$body$
language plpgsql;


-- вспомогательная функция для заполнения адресного регистра
-- рег. и факт. адрес -> id
-- возвращает id добавленной записи
create or replace function idb.get_address_id(
	i_address varchar,
	i_district int
)
RETURNS bigint as
$body$
DECLARE
	address_id bigint;
	i_adm_area int;
	ar_district int;
begin
    select id into address_id from idb.ar_address_registry where address=i_address;

    if address_id is null and i_address is not null then
        select nextval('ar.address_registry_id_seq') into address_id;
        select id, parent_id from ar.territory where ar_code::int = i_district into ar_district, i_adm_area;
        insert into idb.ar_address_registry(id, address, ar_object_status_id, p1, district, adm_area)
        	values (address_id, i_address, 2, 10, ar_district, i_adm_area);
    end if;

    return address_id;
end
$body$
language plpgsql;


-- Функция перекодировки статуса участника. только без выборок на каждый статус
create or replace function idb.convert_participant_status_simple(
	status_id         int,
	decline_reason_id int
)
RETURNS bigint as
$body$
DECLARE
	result bigint;
begin
	case
		when status_id = 1 then select 7 into result;
		when status_id = 2 or status_id = 3 then select 6 into result;
		when status_id = 4 or status_id = 6 then select 4 into result;
		when status_id = 5 then select 3 into result;
		when status_id = 7 and decline_reason_id = 4 then select 8 into result;
		when status_id = 8 or status_id = 7 then select 1 into result;

		else select 3 into result;
	end case;

	return result;
end
$body$
language plpgsql;


--+-----------------------------------------------------------------------------
--+ Функция перекодировки для справочника типов документов, без изменений
--+-----------------------------------------------------------------------------
create or replace function idb.get_document_type_by_EC3_id(type_id bigint) returns bigint as
$$
begin
    case
        when type_id = 1 then return 7;
        when type_id = 2 then return 1;
        when type_id = 5 then return 3;
        when type_id = 6 then return 4;
        when type_id = 9 then return 2;
        else return null;
    end case;
end;
$$ language plpgsql;


-- процесс
----------
-- заполняем participant_map и contact_owner
do $$
declare
	res bigint;
	cur cursor for (select * from sdb.participant s left join idb.participant_map m on s.aid=m.aid where m.aid is null);
begin
	for row in cur loop
    	perform idb.participant_aid_to_id(row.aid);
    end loop;
end;
$$ language plpgsql;

-- заполняем address_map и ar_address_registry
drop table if exists idb.address_map;
select
	aid,
	idb.get_address_id(reg_full_address, reg_adr_district) reg_id,
	idb.get_address_id(fct_full_address, fact_adr_district) fact_id
into idb.address_map
from sdb.participant; -- exp ~0.6s, без индекса 4.6s
-- 205,462 rows affected. (14.578 s)


-- наконец, заполняем idb.participant, idb.contact, idb.personal_document, status_log
do $$
declare
    pid  bigint;
    arr  varchar array[2];
    indx varchar;
    row  record;
    priority int;
begin
    for row in select idb.participant_map.id id, pt.first_name, pt.second_name, pt.patronymic, pt.date_of_birth, pt.gender,
                      pt.home_phone_number, pt.personal_phone_number, pt.status_id,
                      pt.document_type_id, pt.serial_number, pt.date_from, pt.department, pt.department_code,
                      pt.snils, pt.email, pt.skm, pt.skm_series, idb.address_map.reg_id, idb.address_map.fact_id,
                      idb.organization_map.id org_id
                      from sdb.participant pt
    	inner join idb.participant_map using (aid)
    	left join idb.address_map using (aid)
        -- используем джойн а не get_organization_id() чтобы избежать вставок новых id организаций если вдруг не найдено
        left join idb.organization_map on (pt.organization_id = idb.organization_map.aid)
    loop
        
        insert into idb.participant(
            id,
            --status_id,
            first_name,
            second_name,
            patronymic,
            date_of_birth,
            gender,
            snils,
            skm,
            skm_series,
            registration_address,
            fact_address,
            agreement,
			organization_id
        )
        values (
            row.id,
            initcap(row.first_name),
            initcap(row.second_name),
            initcap(row.patronymic),
            to_date(row.date_of_birth, 'YYYY-MM-DD'),
            row.gender,
            row.snils,
            row.skm,
            row.skm_series,
            row.reg_id,
            row.fact_id,
            true,
			row.org_id
        );

        insert into idb.contact_owner(id, created, modified) values (row.id, now(), now()) on conflict do nothing;
        
		-- вставка доп. информации
		
		-- телефоны
		if row.personal_phone_number is not null then
            insert into idb.contact
            values (nextval('idb.contact_id_seq'), row.id, 1, 1, replace(row.personal_phone_number, ' ', ''), 0, 1);
        end if;

        priority := case when row.personal_phone_number is null then 0 else 1 end;

        if row.home_phone_number is not null then
            insert into idb.contact
            values (nextval('idb.contact_id_seq'), row.id, 1, 1, replace(row.home_phone_number, ' ', ''), priority, 1);
        end if;

        -- email
        if row.email is not null then
            insert into idb.contact
            values (nextval('idb.contact_id_seq'), row.id, 1, 2, row.email, 0, 1);
        end if;
        
        -- статусы
        insert into idb.ref_participant_status_log(
        	id,
        	participant_id, 
        	status_id, 
        	start_date
    	)
        values (
        	nextval('idb.ref_participant_status_log_id_seq'),
        	row.id,
        	row.status_id,--idb.convert_participant_status_simple(row.status_id, 3),
        	now()
    	);
        
        insert into idb.personal_document
        values (
        	nextval('idb.personal_document_id_seq'),
        	row.id,
        	idb.get_document_type_by_EC3_id(row.document_type_id),
        	row.serial_number,
            to_date(row.date_from, 'YYYY-MM-DD'),
           	row.department,
          	row.department_code,
          	null
        );

    end loop;
end;
$$ language plpgsql;

-- Связь участников с организациями через несколько организаций

create or replace function idb.insert_p_o(
	participant_id bigint,
	organization_id bigint,
	link_type varchar,
	date_created timestamp
)
RETURNS int as
$body$
DECLARE
	po_id int;
begin

    insert into idb.participant_organization (
        participant_id,
        organization_id,
        link_type,
        id,
        enabled
    ) values (
        participant_id,
        organization_id,
        link_type,
        nextval('idb.participant_organization_id_seq'),
        true
    ) returning id into po_id;

    insert into idb.participant_organization_history (
        id,
        participant_organization_id,
        date_created,
        created_by,
        enabled
    ) values (
        nextval('idb.participant_organization_history_id_seq'),
        po_id,
        date_created,
        'admin',
        true
    );

	return po_id;
end
$body$
language plpgsql;

do $$
declare
    row_created record;
    row_territory record;
    row_group record;
    dummy int;
begin

    for row_created in
        select
            pm.id as participant_id,
            om.id as organization_id,
            po.date_created as date_created
        from sdb.participant_organizations po
        left join idb.participant_map pm on pm.aid=po.participant_aid
        left join idb.organization_map om on om.aid=po.organization_aid
        where om.id is not null and pm.id is not null
    loop
        select idb.insert_p_o(
            row_created.participant_id,
            row_created.organization_id,
            'CREATED'::varchar,
            to_date(row_created.date_created, 'YYYY-MM-DD')
        ) into dummy;
    end loop;

    for row_territory in
        select distinct
            pm.id as participant_id,
            om.id as organization_id,
            p.p_date_create as date_created
        from sdb.participant p
        left join sdb.organization o on (o.territory_1_code::int = p.reg_adr_district or (o.territory_1_code::int = p.fact_adr_district and p.fact_adr_district != p.reg_adr_district))
        left join idb.participant_map pm on pm.aid=p.aid
        left join idb.organization_map om on om.aid=o.aid
        where  o.is_css_organization = 1 and (o.types_providing_services_id = 3 or o.types_providing_services_id = 4)
        order by pm.id
    loop
        select idb.insert_p_o(
            row_territory.participant_id,
            row_territory.organization_id,
            'TERRITORY'::varchar,
            to_date(row_territory.date_created, 'YYYY-MM-DD')
        ) into dummy;
    end loop;

    for row_group in
        select distinct on (p.id, o.id)
            p.id as participant_id,
            o.id as organization_id,
            cr.date_from as date_created
          from idb.participant p
          left join idb.class_record cr on cr.participant_id=p.id
          left join idb."groups" g on cr.group_id=g.id
          left join idb.organization o on g.territory_centre_id=o.id
          where o.id is not null
          and o.level_id = 3
    loop
        select idb.insert_p_o(
            row_group.participant_id,
            row_group.organization_id,
            'GROUP'::varchar,
            row_group.date_created
        ) into dummy;
    end loop;
end;
$$ language plpgsql;