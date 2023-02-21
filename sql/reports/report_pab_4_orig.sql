drop function if exists public.report_pab_4;
create function public.report_pab_4()
  returns TABLE (
    "Уникальный номер в КИС МД"         bigint,
    "Код группы в КИС МД"               character varying,
    "Направление"                       character varying,
    "Профиль"                           character varying,
    "Направленность"                    character varying,
    "Дата заключения Соглашения"        date,
    "Дата окончания действия Согл."     date,
    "Номер соглашения"                  character varying,
    "ФИО координатора"                  character varying,
    "Департамент"                       character varying,
    "Образовательная организация"       character varying,
    "Адрес оказания услуги"             character varying,
    "Тип площадки"                      character varying,
    "Активная площадка"                 character varying,
    "UNOM"                              bigint,
    "Округ оказания услуги"             character varying,
    "Район оказания услуги"             character varying,
    "Противопоказания"                  character varying,
    "Форма одежды"                      character varying,
    "Наличие инвентаря"                 character varying,
    "Краткое наименование ЦСО"          character varying,
    "Адрес ЦСО"                         character varying,
    "Телефон ЦСО"                       character varying,
    "Район ЦСО"                         character varying,
    "Код группы"                        character varying,
    "Расп-ие групп в активн. периодах"  character varying,
    "Расп-ие групп в закрытых периодах" character varying,
    "Плановый период"                   character varying,
    "Макс. кол-во человек в группе"     bigint,
    "Мин. кол-во человек в группе"      bigint,
    "Число обучающихся в группе"        bigint,
    "Занято мест в группе"              bigint,
    "Приостановлено участников в групп" bigint,
    "Режим работы ЦСО"                  character varying,
    "Плановая дата начала занятий"      date,
    "Фактическая дата начала"           date,
    "Дата окончания занятий"            date,
    "Статус группы обучения"            character varying,
    "Причина изменения статуса группы"  character varying,
    "Дата приказа"                      date,
    "Предельный охват"                  integer,
    "Разрешено доукомплектование, д/н"  character varying,
    "ФИО преподователя"                 character varying,
    "Наименование площадки"             character varying
  )
  language plpgsql
as $$
begin
  
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
        select l.group_id,
               ar.address                                                                                 as service_addr,
               ar.unom                                                                                    as unom,
               tr1.title                                                                                  as service_district,
               tr2.title                                                                                  as service_neighbourhood,
               string_agg(distinct concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name), ', ') as teacher,
               array_agg(distinct s.end_date)                                                             as schedule,
               string_agg(distinct p.title, ', ')                                                         as place_name,
               string_agg(distinct pt.title, ', ')                                                        as place_type
        from md.lesson l
               left join md.schedule s on l.schedule_id = s.id
               left join md.place p on (l.place_id = p.id)
               left join reference.place_type pt on p.place_type_id = pt.id
               left join ar.address_registry ar on (p.address = ar.id)
               left join ar.territory tr1 on (ar.adm_area = tr1.id)
               left join ar.territory tr2 on (ar.district = tr2.id)
               left join md.schedule_timesheet_coworkers stc on l.id = stc.lesson_id
               left join md.coworker cw on stc.coworker_id = cw.id
        group by l.group_id, ar.address, ar.unom, tr1.title, tr2.title
      ),
      G3 as ( -- Форма одежды
        select gdс.group_id,
               string_agg(dc.title, ', ')::varchar as dress_code
        from md.group_dress_code gdс
               left join reference.dress_code dc on (dc.id = gdс.dress_code_id)
        group by gdс.group_id
      ),
      G4 as ( -- Инвентарь
        select gir.group_id,
               string_agg(ir.title, ', ') as inventory
        from md.group_inventory_requirement gir
               left join reference.inventory_requirement ir on (ir.id = gir.inventory_requirement_id)
        group by gir.group_id
      ),
      G4_1 as ( -- Противопоказания
        select gc.group_id,
               string_agg(c.title, ', ') as contraindications
        from md.group_contraindication gc
               left join reference.contraindication c on gc.contraindication_id = c.id
        group by gc.group_id
      ),
      G5 as ( -- Адрес ЦСО
        select gr.id                                  group_id,
               org.id                                 orgid_cso,
               org.short_title                     as short_name_cso,
               ar.address                          as addr_cso,
               string_agg(distinct tr.title, ', ') as neighbourhood_cso,
               string_agg(distinct cn.value, ', ') as phone_cso
        from md.groups gr
               left join md.territory_organization torg on gr.territory_centre_id = torg.organization_id
               left join ar.territory tr on torg.territory_id = tr.id
               left join md.organization org on (org.id = gr.territory_centre_id)
               left join ar.address_registry ar on (ar.id = org.physical_address)
            --left join ar.territory tr3 on (tr3.id = ar2.district)
               left join md.contact cn on (cn.owner_id = org.id and cn.contact_type_id = 1)
        group by gr.id, org.id, org.short_title, ar.address
      ),
      G6 as ( -- Расписание групп
        select gr.id                                                     group_id,
               string_agg(case
                            when sh.start_date < current_date and sh.end_date > current_date and
                                 wds.day_of_week = 'MONDAY' then 'Пн.'
                            when sh.start_date < current_date and sh.end_date > current_date and
                                 wds.day_of_week = 'TUESDAY' then 'Вт.'
                            when sh.start_date < current_date and sh.end_date > current_date and
                                 wds.day_of_week = 'WEDNESDAY' then 'Ср.'
                            when sh.start_date < current_date and sh.end_date > current_date and
                                 wds.day_of_week = 'THURSDAY' then 'Чт.'
                            when sh.start_date < current_date and sh.end_date > current_date and
                                 wds.day_of_week = 'FRIDAY' then 'Пт.'
                            when sh.start_date < current_date and sh.end_date > current_date and
                                 wds.day_of_week = 'SATURDAY' then 'Сб.'
                            when sh.start_date < current_date and sh.end_date > current_date and
                                 wds.day_of_week = 'SUNDAY' then 'Вс.'
                            end ||
                          wds.start_time || '-' || wds.end_time, ',') as group_schedule_activ,
               string_agg(case
                            when sh.end_date <= current_date and wds.day_of_week = 'MONDAY' then 'Пн.'
                            when sh.end_date <= current_date and wds.day_of_week = 'TUESDAY' then 'Вт.'
                            when sh.end_date <= current_date and wds.day_of_week = 'WEDNESDAY' then 'Ср.'
                            when sh.end_date <= current_date and wds.day_of_week = 'THURSDAY' then 'Чт.'
                            when sh.end_date <= current_date and wds.day_of_week = 'FRIDAY' then 'Пт.'
                            when sh.end_date <= current_date and wds.day_of_week = 'SATURDAY' then 'Сб.'
                            when sh.end_date <= current_date and wds.day_of_week = 'SUNDAY' then 'Вс.'
                            end ||
                          wds.start_time || '-' || wds.end_time, ',') as group_schedule_inactive,
               string_agg(case
                            when sh.start_date > current_date and wds.day_of_week = 'MONDAY' then 'Пн.'
                            when sh.start_date > current_date and wds.day_of_week = 'TUESDAY' then 'Вт.'
                            when sh.start_date > current_date and wds.day_of_week = 'WEDNESDAY' then 'Ср.'
                            when sh.start_date > current_date and wds.day_of_week = 'THURSDAY' then 'Чт.'
                            when sh.start_date > current_date and wds.day_of_week = 'FRIDAY' then 'Пт.'
                            when sh.start_date > current_date and wds.day_of_week = 'SATURDAY' then 'Сб.'
                            when sh.start_date > current_date and wds.day_of_week = 'SUNDAY' then 'Вс.'
                            end ||
                          wds.start_time || '-' || wds.end_time, ',') as group_plan_period
        from md.groups gr
               left join md.schedule sh on (sh.group_id = gr.id)
               left join md.week_day_schedule wds on (wds.schedule_id = sh.id)
        group by gr.id
      ),
      
      G7_0 as ( -- последний статус записи в группу
        select crsr.class_record_id,
               array_agg(crsr.class_record_status_id order by crsr.id desc)                         status_arr,
               jsonb_object_agg(coalesce(crsr.end_date::text, 'null'), crsr.class_record_status_id) status_json
        from md.class_record_status_registry crsr
        where crsr.end_date is null
          and crsr.start_date is not null
        group by crsr.class_record_id
      ),
      G7 as (
        select cr.group_id,
               --count(cr.id) as group_count
               sum(case
                     when coalesce((status_json ->> 'null')::bigint, status_arr[1]) in (1, 3, 6) then 1
                     else 0 end) as group_count,
               sum(case
                     when coalesce((status_json ->> 'null')::bigint, status_arr[1]) in (1, 2, 3, 6, 7) then 1
                     else 0 end) as group_vacant,
               sum(case
                     when coalesce((status_json ->> 'null')::bigint, status_arr[1]) in (2) then 1
                     else 0 end) as group_pause
        from md.class_record cr
               left join G7_0 on (cr.id = G7_0.class_record_id)
        where coalesce((status_json ->> 'null')::bigint, status_arr[1]) in (1, 2, 3, 6, 7)
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
        select gsr.group_id,
               gsr.status_id as last_status,
               grst.title    as last_reason
        from md.group_status_registry gsr
               left join reference.group_status_reason grst on gsr.reason_id = grst.id
        where gsr.is_expectation = false
          and gsr.end_date isnull
      ),
      G10 as ( -- последний статус группы
        select l.group_id,
               min(l.lesson_date) as fact_start_date
        from md.lesson l
        group by l.group_id
      )
    select
      -- g.activity_id,
      g.id                                                                     as group_id,
      concat('G-', lpad(g.id::varchar, 8, '0'))::varchar                       as group_num,
      G0.direction,
      G0.profile,
      G0.focus,
      G1.date_begin_cont,
      G1.date_end_cont,
      G1.cont_num,
      concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name)::varchar as coordinator,
      G1.department,
      G1.org_name,
      G2.service_addr,
      G2.place_type::varchar,
      (case when current_date > all (G2.schedule) then 'нет' else 'да' end)::varchar,
      G2.unom,
      G2.service_district,
      G2.service_neighbourhood,
      regexp_replace(G4_1.contraindications, '[^0-9а-яА-Я -.,#()?!№*/\<>+"]', '', 'g')::varchar,
      G3.dress_code,
      G4.inventory::varchar,
      G5.short_name_cso,
      G5.addr_cso,
      G5.phone_cso::varchar,
      G5.neighbourhood_cso::varchar,
      -- g.id,
      g.esz_code,
      G6.group_schedule_activ::varchar,
      G6.group_schedule_inactive::varchar,
      G6.group_plan_period::varchar,
      g.max_count,
      g.min_count,
      coalesce(G7.group_count, 0)                                              as group_count,
      coalesce(G7.group_vacant, 0)                                             as group_vacant,
      coalesce(G7.group_pause, 0)                                              as group_pause,
      G8.operating_mode_cso::varchar,
      g.plan_start_date,
      G10.fact_start_date,
      g.plan_end_date,
      gs.title,
      G9.last_reason,
      g.order_date,
      round(g.max_count * 1.5)::integer                                        as coverage,
      (case when g.extend = true then 'да' else 'нет' end)::varchar            as allowed_yes_no,
      G2.teacher::varchar,
      G2.place_name::varchar
    from md.groups g
           left join G0 on (G0.activity_id = g.activity_id)
           left join G1 on (G1.group_id = g.id)
           left join G2 on (G2.group_id = g.id)
           left join G3 on (G3.group_id = g.id)
           left join G4 on (G4.group_id = g.id)
           left join G4_1 on (G4_1.group_id = g.id)
           left join G5 on (G5.group_id = g.id)
           left join G6 on (G6.group_id = g.id)
           left join G7 on (G7.group_id = g.id)
           left join G8 on (G8.organization_id = g.territory_centre_id)
           left join G9 on (G9.group_id = g.id)
           left join G10 on (G10.group_id = g.id)
           left join reference.group_status gs on (G9.last_status = gs.id)
           left join md.coworker cw on (cw.id = g.coworker_id);

end
$$;