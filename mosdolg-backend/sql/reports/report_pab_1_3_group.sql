drop function if exists public.report_pab_1_3_group;
CREATE OR REPLACE FUNCTION public.report_pab_1_3_group(group_name text)
  returns TABLE (
    "Направление"                      character varying,
    "Профиль"                          character varying,
    "Направленность"                   character varying,
    "Дата заключения Соглашения"       date,
    "Дата окончания действия Согл."    date,
    "Номер соглашения"                 character varying,
    "Департамент"                      character varying,
    "Образовательная организация"      character varying,
    "Адрес оказания услуги"            character varying,
    "UNOM"                             bigint,
    "Округ оказания услуги"            character varying,
    "Район оказания услуги"            character varying,
    "Противопоказания"                 character varying,
    "Форма одежды"                     character varying,
    "Наличие инвентаря"                character varying,
    "Краткое наименование ЦСО"         character varying,
    "Адрес ЦСО"                        character varying,
    "Телефон ЦСО"                      character varying,
    "Район ЦСО"                        character varying,
    "Код группы"                       character varying,
    "Расписание группы"                character varying,
    "Макс. кол-во человек в группе"    integer,
    "Число обучающихся в группе"       bigint,
    "Режим работы ЦСО"                 character varying,
    "Плановая дата начала занятий"     date,
    "Фактическая дата начала"          date,
    "Дата окончания занятий"           date,
    "Статус группы обучения"           character varying,
    "Дата приказа"                     date,
    "Предельный охват"                 integer,
    "Разрешено доукомплектование, д/н" integer,
    "Имя преподавателя"                character varying,
    "Отчество преподавателя"           character varying,
    "Фамилия преподавателя"            character varying,
    "aid из ЕСЗ"                       bigint
  )
  language plpgsql
as $$
declare
  groups_array integer[];
begin
  execute
      'with
			-- REG - последние записи из регистров
			-- L0-n - вспомогательные выборки
			-- R1-n - результирующие ряды, номер соответствует строке из запроса
			REG_groups as ( -- статус группы
					select distinct on (group_id) group_id,
																				first_value(status_id) over (partition by group_id order by id desc) as last_status
					from md.group_status_registry
					where is_expectation = false
			),
			REG_cr as ( -- статус записи в группу
					select distinct on (class_record_id) class_record_id,
																							 first_value(class_record_status_id)
																							 over (partition by class_record_id order by id desc) as last_status
					from md.class_record_status_registry
			),
			L0 as ( -- только группы, не входящие в направления ЦСО
					select *
					from md.groups
					where activity_id not in (
							select a3.id activity_id
							from reference.activity a3
											 left join reference.activity a2 on (a3.parent_id = a2.id)
											 left join reference.activity a1 on (a2.parent_id = a1.id)
							where a1.title = ''Кружки ЦСО''
								 or a1.title = ''Мероприятия ЦСО''
					)
			),
	
			L1 as ( -- вспомогательная выборка для групп
					select last_status as status_id, g.id as gr_id
					from L0 g
									 left join REG_groups gsr on g.id = gsr.group_id
					where last_status != 1
					group by last_status,g.id
			),
	
			L2 as ( -- вспомогательная выборка для количества участников в группах
					select g.id as group_id, coalesce(participants_number, 0) as participants_number
					from L0 g
									 join REG_groups gsr on g.id = gsr.group_id
									 left join (
							select group_id, count(*) as participants_number
							from REG_groups gsr
											 left join md.class_record cr using (group_id)
											 left join REG_cr on cr.id = REG_cr.class_record_id
							where gsr.last_status = 8
								and REG_cr.last_status in (1, 3, 6, 7)
							group by gsr.group_id
					) as P0 on (g.id = P0.group_id)
					where gsr.last_status = 8
			),
			groups_total as ( -- общее кол-во групп
					select array_agg(distinct gr_id) as array_value
					from L1
			),
			groups_started as ( -- приступили к занятиям
					select array_agg(distinct gr_id) as array_value
					from L1
					where status_id = 8
			),
			groups_started_full as (
					select array_agg(distinct g.id) as array_value
					from md.groups g
									 join L2 on g.id = L2.group_id
					where L2.participants_number >= g.max_count
			),
			groups_started_0_50 as (
					select array_agg(distinct g.id) as array_value
					from md.groups g
									 join L2 on g.id = L2.group_id
					where (L2.participants_number::numeric / g.max_count::numeric) <= 0.5
			),
			groups_started_51_80 as (
					select array_agg(distinct g.id) as array_value
					from md.groups g
									 join L2 on g.id = L2.group_id
					where (L2.participants_number::numeric / g.max_count::numeric) > 0.5
						and (L2.participants_number::numeric / g.max_count::numeric) <= 0.8
			),
			groups_started_81_99 as (
					select array_agg(distinct g.id) as array_value
					from md.groups g
									 join L2 on g.id = L2.group_id
					where (L2.participants_number::numeric / g.max_count::numeric) > 0.8
						and (L2.participants_number::numeric / g.max_count::numeric) < 1
			),
			L2_0 as (
					select g.id, gsr.last_status
					from L0 g
									 join REG_groups gsr on g.id = gsr.group_id
					where (gsr.last_status in (8, 9, 11, 12) and g.extend = true)
						 or (gsr.last_status in (3, 4, 6, 7))
			),
			groups_continued as (
					select array_agg(L2_0.id) as array_value
					from L2_0
			),
			groups_continued_start as (
					select array_agg(L2_0.id) as array_value
					from L2_0
					where L2_0.last_status = 8
			),
			groups_continued_paused as (
					select array_agg(L2_0.id) as array_value
					from L2_0
					where L2_0.last_status = 9
			),
			groups_continued_restart as (
					select array_agg(L2_0.id) as array_value
					from L2_0
					where L2_0.last_status = 11
			),
			groups_continued_waiting as (
					select array_agg(L2_0.id) as array_value
					from L2_0
					where L2_0.last_status = 7
			),
			L2_1 as (---Только группы в статусе "Ожидание начала занятий"
					select g.id, g.max_count::numeric, count(cr.id)::numeric as cnt_part
					from L0 g
									 join REG_groups gsr on g.id = gsr.group_id
									 left join md.class_record cr on g.id = cr.group_id
									 left join REG_cr crsr on cr.id = crsr.class_record_id and crsr.last_status in (1, 3)
					where gsr.last_status = 7
					group by g.id, g.max_count
			),
			groups_continued_waiting_full as (
					select array_agg(L2_1.id) as array_value
					from L2_1
					where L2_1.cnt_part >= L2_1.max_count
			),
			groups_continued_waiting_0_50 as (
					select array_agg(L2_1.id) as array_value
					from L2_1
					where L2_1.cnt_part <= L2_1.max_count * 0.5
			),
			groups_continued_waiting_51_80 as (
					select array_agg(L2_1.id) as array_value
					from L2_1
					where L2_1.cnt_part > L2_1.max_count * 0.5
						and L2_1.cnt_part <= L2_1.max_count * 0.8
			),
			groups_continued_waiting_81_99 as (
					select array_agg(L2_1.id) as array_value
					from L2_1
					where L2_1.cnt_part > L2_1.max_count * 0.8
						and L2_1.cnt_part < L2_1.max_count
			),
			groups_continued_created as (
					select array_agg(L2_0.id) as array_value
					from L2_0
					where L2_0.last_status in (3, 4, 6)
			),
			L2_2 as (
					select g.id, gsr.last_status,count(crsr.class_record_id) as cnt_patr_ingroup,
								 sum(case when crsr.last_status in (2, 4, 5) then 1 else 0 end) as cnt_patr_null
					from L0 g
									 join REG_groups gsr on g.id = gsr.group_id
									 left join md.class_record cr on g.id = cr.group_id
									 left join REG_cr crsr on cr.id = crsr.class_record_id
					where gsr.last_status in (3, 4, 6, 7)
					group by g.id, gsr.last_status
			),
			groups_continued_null as (
					select array_agg(distinct L2_2.id) as array_value
					from L2_2
					where cnt_patr_ingroup-cnt_patr_null=0
			),
			groups_continued_with_participant as (
					select array_agg(distinct L2_2.id) as array_value
					from L2_2
					where cnt_patr_ingroup!=0
					and cnt_patr_ingroup-cnt_patr_null!=0
			),
			active_groups as ( -- только группы в активных статусах
					select g.id group_id, gsr.last_status
					from L0 g
									 left join REG_groups gsr on g.id = gsr.group_id
					where gsr.last_status in (3, 4, 6, 7, 8, 11, 12)
			),
			-- R8 вспомогательные выборки
			-- R8 собираем из двух частей: в первой те группы, у которых нет записей в cr совсем.
			-- Во второй - те группы, у которых количество всех статусов равно количеству искомых (неактивных) статусов
			-- todo переделать по аналогии с R18
			R8_all_stt as ( -- группы для которых нет cr вообще
					select ag.group_id, ag.last_status, true as cr_isnull
					from active_groups ag
									 left join md.class_record cr using (group_id)
					where cr.id is null
					union
					select ag.group_id, ag.last_status, false as cr_isnull
					from active_groups ag
									 join md.class_record cr using (group_id)
									 join REG_cr crsr on cr.id = crsr.class_record_id
					group by ag.group_id, ag.last_status
					having count(crsr.class_record_id) - sum(case when crsr.last_status in (2, 4, 5, 9) then 1 else 0 end) = 0
			),
			groups_without_people as ( -- группы без активных участников
					select array_agg(distinct R8_all_stt.group_id) as array_value
					from R8_all_stt
					where last_status in (3, 4, 6, 7, 8, 11, 12)
			),
			groups_without_people_month as (
					select array_agg(distinct R8_all_stt.group_id) as array_value
					from R8_all_stt
					where last_status in (3, 4, 6, 8, 11)
						and cr_isnull = true
			),
			groups_without_people_started as (
					select array_agg(distinct R8_all_stt.group_id) as array_value
					from R8_all_stt
					where last_status in (8, 11, 12)
			),
			groups_without_people_waiting as (
					select array_agg(distinct R8_all_stt.group_id) as array_value
					from R8_all_stt
					where last_status = 7
			),
			groups_without_people_not_started as (
					select array_agg(distinct R8_all_stt.group_id) as array_value
					from R8_all_stt
					where last_status in (3, 4, 6)
			),
			groups_on_pause as (
					select array_agg(gr_id) as array_value
					from L1
					where status_id = 9
			),
			groups_finished as (
					select array_agg(gr_id) as array_value
					from L1
					where status_id = 13
			),
			-- group places
			group_places_cnt as ( -- total active 353992
					select g.id, g.max_count::numeric, sum(1)::numeric as group_places_cnt
					from L0 g
									 join REG_groups gsr on g.id = gsr.group_id
									 join md.class_record cr on g.id = cr.group_id
									 join REG_cr crsr on cr.id = crsr.class_record_id
					where gsr.last_status not in (1, 2, 5, 10, 13)
						and crsr.last_status in (1, 3, 6, 7)
					group by g.id, g.max_count
			),
			groups_overbooked as (
					select array_agg(gp.id) as array_value
					from group_places_cnt gp
					where gp.max_count < gp.group_places_cnt
			)
			select array_value from ' || group_name into groups_array;
  
  return query
    with
      G0 as ( -- Направление
        select act1.id       activity_id,
               act1.title as direction,
               act2.title as profile,
               act3.title as focus
        from reference.activity act1
               left join reference.activity act2 on (act2.id = act1.parent_id)
               left join reference.activity act3 on (act3.id = act2.parent_id)
      ),
      G1 as (
        select gr1.id                  group_id,
               org.id                  orgid,
               cont.date_from       as date_begin_cont,
               cont.date_to         as date_end_cont,
               cont.contract_number as cont_num,
               dep.title            as department,
               org.short_title      as org_name
        from md.groups gr1
               left join md.contract cont on (cont.id = gr1.contract_id)
               left join md.organization org on (org.id = gr1.organization_id)
               left join reference.department dep on (dep.id = org.department_id)
      ),
      G2 as ( -- Адрес оказания услуг
        select distinct on (l.group_id)
               l.group_id,
               ar.address as service_addr,
               ar.unom    as unom,
               tr1.title  as service_district,
               tr2.title  as service_neighbourhood
        from md.lesson l
               left join md.place p on (l.place_id = p.id)
               left join ar.address_registry ar on (p.address = ar.id)
               left join ar.territory tr1 on (ar.adm_area = tr1.id)
               left join ar.territory tr2 on (ar.district = tr2.id)
      ),
      G3 as ( -- Форма одежды
        select gdс.group_id,
               dc.title as dress_code
        from md.group_dress_code gdс
               left join reference.dress_code dc on (dc.id = gdс.dress_code_id)
      ),
      G4 as ( -- Инвентарь
        select gir.group_id,
               ir.title as inventory
        from md.group_inventory_requirement gir
               left join reference.inventory_requirement ir on (ir.id = gir.inventory_requirement_id)
      ),
      G5 as ( -- Адрес ЦСО
        select gr.id                         group_id,
               org.id                        orgid_cso,
               org.short_title            as short_name_cso,
               ar2.address                as addr_cso,
               tr3.title                  as neighbourhood_cso,
               string_agg(cn.value, ', ') as phone_cso
        from md.groups gr
               left join md.organization org on (org.id = gr.territory_centre_id)
               left join ar.address_registry ar2 on (ar2.id = org.legal_address)
               left join ar.territory tr3 on (tr3.id = ar2.district)
               left join md.contact cn on (cn.owner_id = org.id and cn.contact_type_id = 1)
        group by gr.id, org.id, org.short_title, ar2.address, tr3.title
      ),
      G6 as ( -- Противопоказания/Расписание групп
        select gr.id                                                     group_id,
               string_agg(c1.title, ', ')                                contraindications,
               string_agg(case
                            when wds.day_of_week = 'MONDAY' then 'Пн.'
                            when wds.day_of_week = 'TUESDAY' then 'Вт.'
                            when wds.day_of_week = 'WEDNESDAY' then 'Ср.'
                            when wds.day_of_week = 'THURSDAY' then 'Чт.'
                            when wds.day_of_week = 'FRIDAY' then 'Пт.'
                            when wds.day_of_week = 'SATURDAY' then 'Сб.'
                            when wds.day_of_week = 'SUNDAY' then 'Вс.'
                            end ||
                          wds.start_time || '-' || wds.end_time, ',') as group_schedule
        from md.groups gr
               left join md.group_contraindication gc on (gc.group_id = gr.id)
               left join reference.contraindication c1 on (c1.id = gc.contraindication_id)
               left join md.schedule sh on (sh.group_id = gr.id)
               left join md.week_day_schedule wds on (wds.schedule_id = sh.id)
        group by gr.id
      ),
      
      G7_0 as ( -- последний статус записи в группу
        select distinct on (class_record_id)
               class_record_id,
               first_value(class_record_status_id) over (partition by class_record_id order by id desc) as last_status
        from md.class_record_status_registry
      ),
      G7 as (
        select cr.group_id,
               count(cr.id) as group_count
        from md.class_record cr
               left join G7_0 on (cr.id = G7_0.class_record_id)
        where G7_0.last_status in (1, 3, 6)
        group by cr.group_id
      ),
      
      G8 as (
        select string_agg(case
                            when rs.day_of_week = '0' then 'Пн.'
                            when rs.day_of_week = '1' then 'Вт.'
                            when rs.day_of_week = '2' then 'Ср.'
                            when rs.day_of_week = '3' then 'Чт.'
                            when rs.day_of_week = '4' then 'Пт.'
                            when rs.day_of_week = '5' then 'Сб.'
                            when rs.day_of_week = '6' then 'Вс.'
                            end ||
                          rs.time_from || '-' || rs.time_to, ',' order by rs.day_of_week) as operating_mode_cso,
               rs.organization_id
        from reference.recurrence_schedule rs
        group by rs.organization_id
      ),
      G9 as ( -- последний статус группы
        select distinct on (group_id)
               group_id,
               first_value(status_id) over (partition by group_id order by id desc) as last_status
        from md.group_status_registry
      )
    
    select
      -- g.activity_id,
      G0.direction,
      G0.profile,
      G0.focus,
      G1.date_begin_cont,
      G1.date_end_cont,
      G1.cont_num,
      G1.department,
      G1.org_name,
      G2.service_addr,
      G2.unom,
      G2.service_district,
      G2.service_neighbourhood,
      G6.contraindications::varchar,
      G3.dress_code,
      G4.inventory,
      G5.short_name_cso,
      G5.addr_cso,
      G5.phone_cso::varchar,
      G5.neighbourhood_cso,
      -- g.id,
      g.esz_code,
      G6.group_schedule::varchar,
      g.max_count,
      coalesce(G7.group_count, 0)                 as group_count,
      G8.operating_mode_cso::varchar,
      g.plan_start_date,
      g.fact_start_date,
      g.plan_end_date,
      gs.title,
      g.order_date,
      g.max_count,
      case when g.extend = true then 1 else 0 end as allowed_yes_no,
      cw.first_name,
      cw.middle_name,
      cw.second_name,
      gm.aid
    from md.groups g
           join unnest(groups_array) as gid on g.id = gid
           left join G0 on (G0.activity_id = g.activity_id)
           left join G1 on (G1.group_id = g.id)
           left join G2 on (G2.group_id = g.id)
           left join G3 on (G3.group_id = g.id)
           left join G4 on (G4.group_id = g.id)
           left join G5 on (G5.group_id = g.id)
           left join G6 on (G6.group_id = g.id)
           left join G7 on (G7.group_id = g.id)
           left join G8 on (G8.organization_id = g.territory_centre_id)
           left join G9 on (G9.group_id = g.id)
           left join reference.group_status gs on (G9.last_status = gs.id)
           left join md.coworker cw on (cw.id = g.coworker_id)
           left join idb.groups_map gm on (g.id = gm.id);

end
$$;