drop function if exists public.report_pab_5_groups;
CREATE OR REPLACE FUNCTION public.report_pab_5_groups(neighbourhood text default ''::text)
  returns TABLE (
    "Номер группы КИС МД"           bigint,
    "Код группы ЕСЗ"                character varying,
    "Макс. кол-во человек в группе" integer,
    "Число обучающихся в группе"    bigint,
    "Плановая дата начала занятий"  date,
    "Дата окончания занятий"        date,
    "Статус группы обучения КИС МД" character varying,
    "Направление"                   character varying,
    "Профиль"                       character varying,
    "Направленность"                character varying,
    "Дата заключения Соглашения"    date,
    "Дата окончания действия Согл." date,
    "Номер соглашения"              character varying,
    "Образовательная организация"   character varying,
    "Противопоказания"              character varying,
    "Форма одежды"                  character varying,
    "Наличие инвентаря"             character varying,
    "Краткое наименование ЦСО"      character varying,
    "Расписание группы"             character varying,
    "Адрес площадки"                character varying,
    "Округ"                         character varying,
    "Район"                         character varying,
    "ФИО Преподавателя"             character varying,
    "Номер обращения"               character varying,
    "Статус обращения"              character varying,
    "Примечание"                    character varying
  )
  language plpgsql
as $$
begin
  return query
    with
      G0_0 as ( -- последний статус записи в группу
        select distinct on (class_record_id)
               class_record_id,
               first_value(class_record_status_id) over (partition by class_record_id order by id desc) as last_status
        from md.class_record_status_registry
      ),
      G0 as (
        select cr.group_id,
               count(cr.id) as group_count
        from md.class_record cr
               left join G0_0 on (cr.id = G0_0.class_record_id)
        where G0_0.last_status in (1, 3, 6)
        group by cr.group_id
      ),
      G1 as ( -- последний статус группы
        select distinct on (group_id)
               group_id,
               first_value(status_id) over (partition by group_id order by id desc) as last_status
        from md.group_status_registry
      ),
      G2 as ( -- Направление
        select act1.id       activity_id,
               act1.title as direction,
               act2.title as profile,
               act3.title as focus
        from reference.activity act1
               left join reference.activity act2 on (act2.id = act1.parent_id)
               left join reference.activity act3 on (act3.id = act2.parent_id)
      ),
      G3 as ( -- Контракты
        select gr1.id                                                  group_id,
               org.id                                                  orgid,
               cont.date_from                                       as date_begin_cont,
               cont.date_to                                         as date_end_cont,
               coalesce(cont.contract_number, cont.document_number) as cont_num,
               org.short_title                                      as org_name
        from md.groups gr1
               left join md.contract cont on (cont.id = gr1.contract_id)
               left join md.organization org on (org.id = gr1.organization_id)
      ),
      G4 as ( -- Противопоказания/Расписание групп
        select gr.id                                               group_id,
               array_to_string(array_agg(distinct c1.title), '; ') contraindications,
               string_agg(case
                            when wds.day_of_week = 'MONDAY' then 'Пн.'
                            when wds.day_of_week = 'TUESDAY' then 'Вт.'
                            when wds.day_of_week = 'WEDNESDAY' then 'Ср.'
                            when wds.day_of_week = 'THURSDAY' then 'Чт.'
                            when wds.day_of_week = 'FRIDAY' then 'Пт.'
                            when wds.day_of_week = 'SATURDAY' then 'Сб.'
                            when wds.day_of_week = 'SUNDAY' then 'Вс.'
                            end ||
                          to_char(wds.start_time, 'HH24:MI') || '-' || to_char(wds.end_time, 'HH24:MI'),
                          '; ') as                                 group_schedule
        from md.groups gr
               left join md.group_contraindication gc on (gc.group_id = gr.id)
               left join reference.contraindication c1 on (c1.id = gc.contraindication_id)
               left join md.schedule sh on (sh.group_id = gr.id)
               left join md.week_day_schedule wds on (wds.schedule_id = sh.id)
        group by gr.id
      ),
      G5 as ( -- Форма одежды
        select gdс.group_id,
               dc.title as dress_code
        from md.group_dress_code gdс
               left join reference.dress_code dc on (dc.id = gdс.dress_code_id)
      ),
      G6 as ( -- Инвентарь
        select gir.group_id,
               ir.title as inventory
        from md.group_inventory_requirement gir
               left join reference.inventory_requirement ir on (ir.id = gir.inventory_requirement_id)
      ),
      G7 as ( -- Адрес оказания услуг
        select l.group_id,
               ar.address       as service_addr,
               tr1.title        as service_district,
               tr2.title        as service_neighbourhood,
               string_agg(distinct initcap(
                 concat(cw.second_name, ' ', substr(cw.first_name, 1, 1), '.', substr(cw.middle_name, 1, 1), '.')),
                          ', ') as teacher
        from md.lesson l
               left join md.place pl on (pl.id = l.place_id)
               left join ar.address_registry ar on (ar.id = pl.address)
               left join ar.territory tr1 on (ar.adm_area = tr1.id)
               left join ar.territory tr2 on (ar.district = tr2.id)
               left join md.schedule_timesheet_coworkers stc on l.id = stc.lesson_id
               left join md.coworker cw on stc.coworker_id = cw.id
        group by l.group_id, ar.address, ar.unom, tr1.title, tr2.title
      )
    select g.id,
           g.esz_code,
           g.max_count,
           G0.group_count,
           g.plan_start_date,
           g.plan_end_date,
           gs.title,
           G2.direction,
           G2.profile,
           G2.focus,
           G3.date_begin_cont,
           G3.date_end_cont,
           G3.cont_num,
           G3.org_name,
           G4.contraindications::varchar,
           G5.dress_code,
           G6.inventory,
           org.short_title,
           G4.group_schedule::varchar,
           G7.service_addr,
           G7.service_district,
           G7.service_neighbourhood,
           G7.teacher::varchar,
           ''::varchar as ref_num,
           ''::varchar as ref_stat,
           ''::varchar as note
    from md.groups g
           left join G1 on (G1.group_id = g.id)
           left join reference.group_status gs on (G1.last_status = gs.id)
           left join G0 on (G0.group_id = g.id)
           left join G2 on (G2.activity_id = g.activity_id)
           left join G3 on (G3.group_id = g.id)
           left join G4 on (G4.group_id = g.id)
           left join G5 on (G5.group_id = g.id)
           left join G6 on (G6.group_id = g.id)
           left join md.organization org on (org.id = g.territory_centre_id)
           left join G7 on (G7.group_id = g.id)
           left join md.territory_organization torg on org.id = torg.organization_id
           left join ar.territory t1 on torg.territory_id = t1.id
           left join ar.territory t2 on t1.parent_id = t2.id
    where g.activity_id not in (
      select a3.id activity_id
      from reference.activity a3
             left join reference.activity a2 on (a3.parent_id = a2.id)
             left join reference.activity a1 on (a2.parent_id = a1.id)
      where a1.title = 'Кружки ЦСО'
         or a1.title = 'Мероприятия ЦСО'
    )
      and (case
             when neighbourhood = '' then neighbourhood
             when t2.title = 'Северный административный округ' then 'САО'
             when t2.title = 'Северо-Восточный административный округ' then 'СВАО'
             when t2.title = 'Северо-Западный административный округ' then 'СЗАО'
             when t2.title = 'Восточный административный округ' then 'ВАО'
             when t2.title = 'Западный административный округ' then 'ЗАО'
             when t2.title = 'Южный административный округ' then 'ЮАО'
             when t2.title = 'Юго-Восточный административный округ' then 'ЮВАО'
             when t2.title = 'Юго-Западный административный округ' then 'ЮЗАО'
             when t2.title = 'Центральный административный округ' then 'ЦАО'
             when t2.title = 'Троицкий административный округ' then 'ТиНАО'
             when t2.title = 'Новомосковский административный округ' then 'ТиНАО'
             when t2.title = 'Зеленоградский административный округ' then 'ЗелАО'
      end) = neighbourhood
    order by g.id;

end
$$;