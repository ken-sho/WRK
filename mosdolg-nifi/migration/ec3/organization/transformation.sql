-- 26.08
truncate table idb.ref_department;
truncate table idb.organization;
truncate table idb.ref_recurrence_schedule;
truncate table idb.territory_organization;
delete from idb.contact c where c.contact_owner_type_id=4;
delete from idb.contact_owner where id in (select ow.id from idb.contact_owner ow join idb.contact c on c.owner_id=ow.id where c.contact_owner_type_id=4);


-- вспомогательная функция для заполнения адресного регистра
-- возвращает id добавленной записи

create or replace function idb.get_address_id_org(
	i_address varchar,
	i_district int,
    i_level_id int
)
RETURNS bigint as
$body$
DECLARE
	i_adm_area int;
	ar_district int;
    address_id bigint;
begin
if i_level_id=3 then
    select id into address_id from ar.address_registry where address=i_address and district is not null and adm_area is not null order by id limit 1;

    if address_id is null and i_address is not null and i_district is not null then
        select nextval('ar.address_registry_id_seq') into address_id;
        select id, parent_id from ar.territory where ar_code::int = i_district into ar_district, i_adm_area;
        insert into ar.address_registry(id, address, ar_object_status_id, district, adm_area)
        	values (address_id, i_address, 2, ar_district, i_adm_area);
    end if;
else
    select id into address_id from ar.address_registry where address = i_address order by id limit 1;

    if address_id isnull then
        insert into ar.address_registry(address, ar_object_status_id) values (i_address, 2) returning id into address_id;
    end if;
end if;
    return address_id;
end
$body$
language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ вносит данные в idb.organization, idb.contact, idb.ref_recurrence_schedule и при необходимости в ar.address_registry
--+---------------------------------------------------------------------------------------------------------------------
drop function if exists idb.is_valid_docnum;
create or replace function idb.is_valid_docnum(textd varchar) returns boolean language plpgsql immutable as $$
begin
  return case when textd::bigint is null then false else true end;
exception when others then
  return false;
end;$$;

-- select ar.id, o.unom from sdb.organization o join ar.address_registry ar on o.unom=ar.unom;

--+---------------------------------------------------------------------------------------------------------------------
--+ Переносим данные в целевую таблицу ref_department
--+---------------------------------------------------------------------------------------------------------------------
insert into idb.ref_department(id, title, long_title, level, key)
select
    idb.get_department_id_by_vedomstvo_id(v.aid),
    v.title,
    v.long_title,
    v.level::boolean,
    (case when v.level = 1 then 'D_SOZ' else concat('ESZ', idb.get_department_id_by_vedomstvo_id(v.aid)::varchar) end)
from sdb.vedomstvo v
on conflict (id) do update set title=excluded.title, long_title=excluded.long_title, level=excluded.level, key=excluded.key;

do $$
    declare
        cur cursor for
            select
                o.aid as aid,
                idb.get_organization_id_by_esz_id(o.aid) as id,
                o.short_title, o.full_title,
                (case when idb.is_valid_docnum(replace(o.inn,'-','')) then cast(replace(o.inn,'-','') as bigint) else 111 end) as inn,
                (case when idb.is_valid_docnum(replace(o.kpp,'-','')) then cast(replace(o.kpp,'-','') as bigint) else 111 end) as kpp,
                (case when idb.is_valid_docnum(regexp_replace(o.ogrn,'\D','','g')) then cast(regexp_replace(o.ogrn,'\D','','g') as bigint) else 111 end) as ogrn,
                idb.get_organization_id_by_esz_id(o.parent_organization_id) as parent_organization_id,
                idb.get_department_id_by_vedomstvo_id(o.department_id) as department_id,
                o.representative_full_name,
                o.representative_position, o.website, o.email, o.phone, o.description, o.unom, o.full_address,
                o.opf_id as opf_id,
                (case when o.is_provider = 1 then 1 else 0 end) as is_provider,
                (case
                    when o.is_css_organization = 1 and (o.types_providing_services_id = 3 or o.types_providing_services_id = 4) then 3
                    when o.is_dspp_organization = 1 then 2
                    when o.dtszn_code = 6467 then 4
                    else null
                end) as level_id,
                (select max(t.id) from ar.territory t where t.ar_code = cast(o.territory_code as varchar)) as territory_id,
                (case when o.is_css_organization=1 then case when o.types_providing_services_id=3 then 0 when o.types_providing_services_id=4 then 1 else null end else null end) as is_filial,
                adr.id as address,
                adr2.district
            from sdb.organization o
            left join ar.address_registry adr on o.unom=adr.unom
            left join sdb.ar_address_registry adr2 on o.short_title=adr2.short_name
            order by o.aid;
        legalAddress bigint;
        dayOfWeek int;
        timeFrom time;
        timeTo time;
        row_recurrence_schedule record;
    begin
        for row in cur loop
            select
            	(case when s.time_from isnull then null else to_timestamp(s.time_from, 'HH24:MI:SS')::time end),
                (case when s.time_to isnull then null else to_timestamp(s.time_to, 'HH24:MI:SS')::time end),
                s.day_of_week
            into timeFrom, timeTo, dayOfWeek
            from sdb.ref_recurrence_schedule s where s.oid = row.aid;

            insert into idb.contact_owner(id, created, modified) values (row.id, now(), now()) on conflict do nothing;

            legalAddress := row.address;--idb.get_address_id_by_unom(row.unom); 

            if legalAddress isnull then
                legalAddress := idb.get_address_id_org(row.full_address,row.district,row.level_id);
            end if;
            
            insert into idb.organization(
                id, short_title, full_title, inn, kpp, ogrn, parent_organization_id, representative_full_name,
                representative_position, website, description, legal_address, physical_address, opf_id, is_provider, level_id,
                --territory_id,
                is_filial, department_id
            ) values (
                row.id,
                row.short_title,
                substring(row.full_title, 0, 800),
                row.inn,
                row.kpp,
                row.ogrn,
                row.parent_organization_id,
                substring(row.representative_full_name, 0, 800),
                substring(row.representative_position, 0, 800),
                row.website,
                substring(row.description, 0, 800),
                legalAddress,
                legalAddress, -- такое же значение пишется в физ. адрес
                row.opf_id,
                (case when row.is_provider = 1 then true else false end),
                row.level_id,
                --row.territory_id,
                (case when row.is_filial = 1 then true else false end),
                row.department_id
            );
----заполняем таблицу idb.territory_organization
----только для уровня организаций 3
            if row.level_id=3 and row.territory_id is not null then
                insert into idb.territory_organization(organization_id,territory_id)
                values (row.id,row.territory_id);
            end if;

            for row_recurrence_schedule in
              select
								(case when s.time_from isnull then null else to_timestamp(s.time_from, 'HH24:MI:SS')::time end) as timeFrom,
									(case when s.time_to isnull then null else to_timestamp(s.time_to, 'HH24:MI:SS')::time end) as timeTo,
									s.day_of_week as dayOfWeek
							from sdb.ref_recurrence_schedule s where s.oid = row.aid
            loop
                if row_recurrence_schedule.dayOfWeek = 8 then
								for i in 1..5
									loop
										insert into idb.ref_recurrence_schedule(id, organization_id, day_of_week, time_from, time_to)
										values (nextval('idb.ref_recurrence_schedule_id_seq'), row.id, i, row_recurrence_schedule.timeFrom,
														row_recurrence_schedule.timeTo);
									end loop;
                elseif row_recurrence_schedule.dayOfWeek = 9 then
								for i in 6..7
									loop
										insert into idb.ref_recurrence_schedule(id, organization_id, day_of_week, time_from, time_to)
										values (nextval('idb.ref_recurrence_schedule_id_seq'), row.id, i, row_recurrence_schedule.timeFrom,
														row_recurrence_schedule.timeTo);
									end loop;
                elseif row_recurrence_schedule.dayOfWeek is not null then
								insert into idb.ref_recurrence_schedule(id, organization_id, day_of_week, time_from, time_to)
								values (nextval('idb.ref_recurrence_schedule_id_seq'), row.id, row_recurrence_schedule.dayOfWeek,
												row_recurrence_schedule.timeFrom, row_recurrence_schedule.timeTo);
							end if;
						end loop;

						if row.phone is not null then
                insert into idb.contact(id, owner_id, contact_owner_type_id, contact_type_id, value, contact_availability_type_id, priority)
                values (nextval('idb.contact_id_seq'), row.id, 4, 1, row.phone, 1, 0);
            end if;
            if row.email is not null then
                insert into idb.contact(id, owner_id, contact_owner_type_id, contact_type_id, value, contact_availability_type_id, priority)
                values (nextval('idb.contact_id_seq'), row.id, 4, 2, row.email, 1, 0);
            end if;
        end loop;
--        close cur;
--        commit work;
       
      	-- удаление пробелов из номеров телефонов
      	update idb.contact set value = replace(value, ' ', '') where contact_owner_type_id = 1 AND contact_type_id = 1;
    end
$$ language plpgsql;
