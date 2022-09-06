-- 04.09
truncate table idb.groups;
truncate table idb.group_status_registry;
--truncate table idb.schedule;
--truncate table idb.week_day_schedule;
truncate table idb.class_record;
truncate table idb.class_record_status_registry;

truncate table idb.participant_organization;
truncate table idb.participant_organization_history;

truncate table idb.ref_contraindication;
truncate table idb.ref_dress_code;
truncate table idb.ref_inventory_requirement;

truncate table idb.group_contraindication;
truncate table idb.group_dress_code;
truncate table idb.group_inventory_requirement;


-- вспомогательная таблица маппинг id групп
create table if not exists idb.groups_map (
	aid bigint NOT NULL,
	id bigint NOT NULL,
	CONSTRAINT "groups_map_aid" UNIQUE ("aid"),
	CONSTRAINT "groups_map_id" UNIQUE ("id")
);

-- вспомогательныфе функции
-- маппинг sdb.groups.aid на наш внутренний md.groups.id
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

-- день недели из числа
-- не соответствует описанию в wiki (воскресенье - 7)
create or replace function idb.get_DOW(day_in int) returns varchar as
$body$
begin
	case
		when day_in = 6 then return 'SUNDAY';
		when day_in = 0 then return 'MONDAY';
		when day_in = 1 then return 'TUESDAY';
		when day_in = 2 then return 'WEDNESDAY';
		when day_in = 3 then return 'THURSDAY';
		when day_in = 4 then return 'FRIDAY';
		when day_in = 5 then return 'SATURDAY';
	else return null;
	end case;
end;
$body$ language plpgsql;

create or replace function idb.get_class_record_status(status_1 int, sc_status int) returns bigint as
$body$
declare
    res int;
begin
	case
		when status_1 = 1 and sc_status = 1 then
		    res := 1; -- статус Прикреплён
		when status_1 = 1 and sc_status = 2 then
		    res := 3; -- статус Зачислен
		when status_1 = 1 and (sc_status = 3 or sc_status = 4) then
		    res := 6; -- статус Приступил к занятиям
		when status_1 = 2 or status_1 = 3 then
		    res := 5; -- статус Отчислен
		else
		    res := 1;
	end case;
	return res;
end;
$body$ language plpgsql;


-- create or replace function idb.get_group_status(i_aid int, sc_status int) returns bigint as
-- $body$
-- declare
--     res int;
-- begin
-- 	case
-- 		when i_aid = 3 then
-- 		    res := 8;
-- 		when i_aid = 2 then
-- 		    res := 7;
-- 		when i_aid = 1 then
-- 		    res := 3;
-- 		when i_aid isnull then
-- 		    res := 1;
--         when sc_status = 3 then
--             res := 14;
--         else
--             res := 1;
-- 	end case;
-- 	return res;
-- end;
-- $body$ language plpgsql;

-- процесс
----------

do $$
DECLARE
	i_group_id bigint;
	i_schedule_id bigint;
	i_place_id bigint;
	i_class_record_id bigint;
	act_profile_id bigint;
	row record;

BEGIN
	for row in select
        c.id as contract_id,
        g.*
        from sdb.groups g
        left join idb.contract_map c on g.contract_id=c.aid
	loop

		i_group_id := idb.get_group_id_by_map_aid(row.aid);

		insert into idb.groups(
			id,
			need_note,
			min_count,
			max_count,
			-- fact_count,
			plan_start_date,
			plan_end_date,
			fact_start_date,
			fact_end_date,
			extend,
			organization_id,
			activity_id,
			comment,
			coworker_id,
			-- sync,
			contract_id,
			territory_centre_id,
			esz_code,
			public_date,
			order_date
		)
		values (
			i_group_id,
			row.need_note::boolean,
			row.min_count,
			row.max_count,
			to_date(row.plan_start_date, 'YYYY-MM-DD'),
			to_date(row.plan_end_date, 'YYYY-MM-DD'),
			to_date(row.fact_start_date, 'YYYY-MM-DD'),
			to_date(row.fact_end_date, 'YYYY-MM-DD'),
			row.extend::boolean,
			idb.get_organization_id_by_esz_id(row.organization_id),
			(case when idb.get_map_activity_id(row.activity_id) is null then 1 else idb.get_map_activity_id(row.activity_id) end),
			concat(row.code, E'\n', row.name),
			idb.get_coworkers_id_by_map_id(row.coworker_id),
			row.contract_id,
			idb.get_organization_id_by_esz_id(row.territory_centre_id),
			row.code,
			to_date(row.public_date, 'YYYY-MM-DD'),
			to_date(row.order_date, 'YYYY-MM-DD')
		);

		-- вставляем в реестр текущее значение статуса
		insert into idb.group_status_registry(
			id,
			group_id,
			status_id,
			start_date,
			is_expectation
		) values (
			nextval('idb.group_status_registry_id_seq'),
			i_group_id,
		  --  idb.get_group_status(row.group_status_id, row.sc_status_id), -- статус обновляем позже в update_group
			row.group_status_id,
			now(), -- либо с планируемой/фактической даты начала
		  false
		);

	end loop;

--	for row in select * from sdb.schedule
--	loop
--
--		i_schedule_id := nextval('idb.schedule_id_seq'); -- просто получаем из последовательности
--		i_group_id := idb.get_group_id_by_map_aid(row.group_id);
--		select id into i_place_id from idb.map_place where id_main = row.place_id; -- todo get_place?
--
--		insert into idb.schedule(
--			id,
--			group_id,
--			place_id,
--			start_time,
--			end_time,
--			start_date,
--			end_date
--			-- pause
--		) values (
--			i_schedule_id,
--			idb.get_group_id_by_map_aid(row.group_id),
--			i_place_id,
--			to_timestamp(row.start_time, 'HH24:MI:SS')::time,
--			to_timestamp(row.end_time, 'HH24:MI:SS')::time,
--			to_date(row.start_date, 'YYYY-MM-DD'),
--			to_date(row.end_date, 'YYYY-MM-DD')
--		);
--
--		insert into idb.week_day_schedule(
--			id,
--			schedule_id,
--			place_id,
--			start_time,
--			end_tim
--
--			e,
--			start_date,
--			end_date,
--			-- pause,
--			day_of_week
--		) values (
--			nextval('idb.week_day_schedule_id_seq'),
--			i_schedule_id,
--			i_place_id,
--			to_timestamp(row.start_time, 'HH24:MI:SS')::time,
--			to_timestamp(row.end_time, 'HH24:MI:SS')::time,
--			to_date(row.start_date, 'YYYY-MM-DD'),
--			to_date(row.end_date, 'YYYY-MM-DD'),
--			idb.get_DOW(row.day_of_week)
--		);
--	end loop;

	for row in
	   select
          cr.status_id as status_id,
          cr.reques_ad_id as reques_ad_id,
          g.activity_id as activity_aid,
          am.id as activity_id,
          g.group_status_id as group_status_id,
          to_timestamp(g.plan_start_date, 'YYYY-MM-DD') as plan_start_date,
          to_timestamp(g.plan_end_date, 'YYYY-MM-DD') as plan_end_date,
          to_timestamp(cr.date_from, 'YYYY-MM-DD') as date_from,
          to_timestamp(cr.date_to, 'YYYY-MM-DD') as date_to,
          pm.id as participant_id,
          gm.id as group_id,
          (case when cr.status_id = 3 then true else false end) as transferred,
          papm.id as act_profile_id
          --max(papm.id) over (partition by papm.aid) as act_profile_id
       from sdb.class_record cr
       left join sdb.groups g on (cr.group_id = g.aid)
       join idb.groups_map gm on (cr.group_id = gm.aid)
       join idb.participant_map pm on (cr.participant_id = pm.aid)
       join idb.ref_activity_map am on am.aid=g.activity_id
       left join idb.participant_activity_profile_map papm on (cr.reques_ad_id=papm.aid) and papm.activity_id=g.activity_id
	loop
			i_class_record_id := nextval('idb.class_record_id_seq');
			act_profile_id := row.act_profile_id;

			if act_profile_id is null then
                insert into idb.participant_activity_profile(
                    id,
                    participant_id,
                    activity_id,
                    date_from,
                    date_to,
                    status_id
                ) values (
                    nextval('idb.participant_activity_profile_id_seq'),
                    row.participant_id,
                    row.activity_id,
                    (case when now() < row.plan_start_date then row.plan_start_date else now() end),
                    row.date_to,
                    1
                ) returning id into act_profile_id;
            end if;


			--if act_profile_id is not null then
				insert into idb.class_record(
					id,
					participant_id,
					group_id,
					-- assigned_at
					participant_activity_profile_id,
					date_from,
					date_to,
					-- pause_date_from
					-- pause_date_to
					transferred
				) values (
					i_class_record_id,
					row.participant_id,--idb.get_participant_by_ec3(row.participant_id),
					row.group_id,--idb.get_group_id_by_map_aid(row.group_id),
					act_profile_id,--idb.get_participant_activity_profile_id(row.reques_ad_id, row.activity_id), -- TODO доработать хранимку для случая null
					row.date_from,
					row.date_to,
					row.transferred
				);

				insert into idb.class_record_status_registry(
				    id,
					class_record_id,
					class_record_status_id,
					-- comment,
					-- communication_history_id,
					start_date,
					end_date
					-- reason
				) values (
				    nextval('idb.class_record_status_registry_id_seq'),
					i_class_record_id,
					idb.get_class_record_status(row.status_id, row.group_status_id),
					row.date_from,
					row.date_to
				);
			--end if;
	end loop;
END
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


do $$
  declare
    row record;
	begin
  
		----Создаём справочник противопоказаний
		for row in select nextval('reference.contraindication_id_seq') as id, t
							 from (select distinct title as t from sdb.group_contraindication) as unique_cnts
							 where t is not null
			loop
				insert into idb.ref_contraindication(id, title, legacy)
				values (row.id, row.t, 1);
			end loop;
		
		----Создаём справочник форма одежды
		for row in select nextval('reference.dress_code_id_seq') as id, t
					 from (select distinct title as t from sdb.group_dress_code) as unique_dc
					 where t is not null
		loop
			insert into idb.ref_dress_code(id, title, legacy)
			values (row.id, row.t, 1);
		end loop;
		
		----Создаём справочник требования к инвентарю
		for row in select nextval('reference.inventory_requirement_id_seq') as id, t
					 from (select distinct title as t from sdb.group_inventory_requirement) as unique_inv
			  	 where t is not null
    loop
			insert into idb.ref_inventory_requirement(id, title, legacy)
			values (row.id, row.t, 1);
		end loop;
		
	end;
$$ language plpgsql;

do $$
	declare
		row_contraindication record;
		row_dresscode        record;
		row_inventory        record;
		i_group_id           bigint;
	begin
		for row_contraindication in select gc.aid, rc.id
																from sdb.group_contraindication gc
																			 join idb.groups_map gm on gc.aid = gm.aid
																			 join idb.ref_contraindication rc on (gc.title = rc.title)
			loop
				i_group_id := idb.get_group_id_by_map_aid(row_contraindication.aid);
				insert into idb.group_contraindication(group_id, contraindication_id)
				values (i_group_id, row_contraindication.id);
			end loop;
		
		for row_dresscode in select gdc.aid, rdc.id
												 from sdb.group_dress_code gdc
																join idb.groups_map gm on gdc.aid = gm.aid
																join idb.ref_dress_code rdc on (gdc.title = rdc.title)
			loop
				i_group_id := idb.get_group_id_by_map_aid(row_dresscode.aid);
				insert into idb.group_dress_code(group_id, dress_code_id) values (i_group_id, row_dresscode.id);
			end loop;
		
		for row_inventory in select gir.aid, rir.id
												 from sdb.group_inventory_requirement gir
																join idb.groups_map gm on gir.aid = gm.aid
																join idb.ref_inventory_requirement rir on (gir.title = rir.title)
			loop
				i_group_id := idb.get_group_id_by_map_aid(row_inventory.aid);
				insert into idb.group_inventory_requirement(group_id, inventory_requirement_id)
				values (i_group_id, row_inventory.id);
			end loop;
	end;
$$ language plpgsql;