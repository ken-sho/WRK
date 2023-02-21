drop function if exists public.participant_attendance_report;
create function public.participant_attendance_report(
  p_date_from        date default current_date, p_date_to date default current_date,
  p_district_ids     bigint[] default array []::integer[], p_area_ids bigint[] default array []::integer[],
  p_tcso_s_ch_ids    bigint[] default array []::integer[], p_tcso_coordinators_ids bigint[] default array []::integer[],
  p_tcso_creator_ids bigint[] default array []::integer[], p_uszn_ids bigint[] default array []::integer[],
  p_provider_ids     bigint[] default array []::integer[], p_limit_value integer default null::integer,
  p_offset_value     bigint default null::bigint)
  returns TABLE (
    id                              bigint,
    fio_participant                 text,
    tel                             text,
    participant_last_status         character varying,
    cr_last_status                  character varying,
    date_enrolled                   date,
    cso_short_title                 character varying,
    tcso_district                   text,
    tcso_area                       character varying,
    supplier_short_title            character varying,
    supplier_dept                   character varying,
    contract_number                 character varying,
    activity_title_l1               character varying,
    activity_title_l2               character varying,
    activity_title_l3               character varying,
    group_code                      text,
    tc_short_title                  character varying,
    group_status                    character varying,
    fio_coordinator                 text,
    list_teachers_fio               text,
    cnt_lesson                      bigint,
    cnt_attended                    bigint,
    cnt_with_skm                    bigint,
    cnt_without_skm_mob             bigint,
    cnt_without_skm_web_coordinator bigint,
    cnt_without_skm_web_provider    bigint,
    cnt_missed                      bigint,
    percent_attendance              numeric,
    status_attendance               text
  )
  language plpgsql
as $$
begin
  return query
    with
      pc_tel as (
        select pc.owner_id,
               string_agg(pc.value, '; ' order by pc.priority nulls last) as tel
        from md.participant_contact pc
        where pc.contact_type_id = 1
        group by pc.owner_id
      ),
      p_status as (
        select distinct
               psl.participant_id,
               first_value(ps.title) over (partition by psl.participant_id order by psl.start_date desc) as last_title
        from reference.participant_status_log psl
               join reference.participant_status ps on
                psl.status_id = ps.id
              and date_trunc('day', psl.start_date) between p_date_from /*PARAM Дата С*/
                  and p_date_to /*PARAM Дата по*/
      ),
      cr_status as (
        select distinct
               crsr.class_record_id,
               first_value(crs.title)
               over (partition by crsr.class_record_id order by crsr.start_date desc) as last_title
        from reference.class_record_status crs
               join md.class_record_status_registry crsr on
                crs.id = crsr.class_record_status_id
              and date_trunc('day', crsr.start_date) between p_date_from /*PARAM Дата С*/
                  and p_date_to /*PARAM Дата по*/
      ),
      cr_date_4_5 as (
        /*1) В регистре статусов записи участника в группе (md.class_record_status_registry)
				найти все записи со значением статуса записи (reference.class_record_status)
						4 - Откреплен или 5 - Отчислен (md.class_record_status_registry.class_record_status_id in (4, 5) ).
						Результаты поиска отсортировать по убыванию по дате начала действия статуса (md.class_record_status_registry.start_date)*/
        select crsr2.class_record_id, crsr2.start_date --, crsr2.class_record_status_id
        from md.class_record_status_registry crsr2
        where crsr2.class_record_status_id in (4, 5) /*Откреплен, Отчислен*/
        order by crsr2.class_record_id, crsr2.start_date desc
      ),
      cr_date_1_2_3_6_7 as (
        /*2) Если таких записей нет (Участник ни разу не был отчислен или откреплен), то значение поля "Дата последнего зачисления в группу" = md.class_record_status_registry.start_date у самой ранней по дате начала действия статуса записи в регистре статусов записи в группе (статусы с id = 1, 2, 3, 6, 7). Конец алгоритма.*/
        /*3.1.2.2 Если такой записи нет, то берём значение start_date у записи в статусном регистре с самой ранней start_date (статусы с id = 1, 2, 3, 6, 7).*/
        select crsr3.class_record_id, min(crsr3.start_date) as min_start_date
        from md.class_record_status_registry crsr3
        where crsr3.class_record_status_id in (1, 2, 3, 6, 7) /*Прикреплен, Приостановка, Зачислен, Приступил к занятиям, Возобновление*/
        group by crsr3.class_record_id
      ),
      cr_date_next_not_4_5 as (
        /*3) Для каждой записи найденной на шаге 1:
					3.1 Проверяем есть ли запись со статусом, отличным от 4 или 5 ( md.class_record_status_registry.class_record_status_id not in (4, 5)), следующая по дате начала действия статуса за найденной в п.1 записью (ближайшая по дате начала действия статуса к дате начала действия статуса найденной записи).
					3.1.1 Если такая запись есть, то значение поля "Дата последнего зачисления в группу" = md.class_record_status_registry.start_date этой записи.*/
        select crsr4.class_record_id, min(crsr4.start_date) as min_start_date
        from md.class_record_status_registry crsr4
               join cr_date_4_5 on
                cr_date_4_5.class_record_id = crsr4.class_record_id
              and crsr4.class_record_status_id not in (4, 5)
              and crsr4.start_date > cr_date_4_5.start_date
        group by crsr4.class_record_id
      ),
      cr_date_next_after_prev_4_5 as (
        /*3.1.2 Если такой записи нет, то найти предыдущую запись со статусом 4 или 5.
					3.1.2.1 Если такая запись есть, то берём значение start_date следующей за ней записи;*/
        select crsr6.class_record_id, min(crsr6.start_date) as min_start_date
        from md.class_record_status_registry crsr5
               join cr_date_4_5 on
                cr_date_4_5.class_record_id = crsr5.class_record_id
              and crsr5.class_record_status_id in (4, 5)
              and crsr5.start_date < cr_date_4_5.start_date
               join md.class_record_status_registry crsr6 on
                crsr6.class_record_id = crsr5.class_record_id
              and crsr6.start_date > crsr5.start_date
        group by crsr6.class_record_id
      ),
      cr_cnt as (
        /*4). Для записей найденных на шаге 1, и если такая запись одна в базе данных со статусом 5, то значение поля "Дата последнего зачисления в группу" = md.class_record_status_registry.start_date
					5). Для записей найденных на шаге 1, и если такая запись одна в базе данных со статусом 4, то значение поля "Дата последнего зачисления в группу" = md.class_record_status_registry.start_date*/
        select crsr7.class_record_id, count(*) cnt
        from md.class_record_status_registry crsr7
               join cr_date_4_5 on
            cr_date_4_5.class_record_id = crsr7.class_record_id
        group by crsr7.class_record_id
      ),
      cr_date as (
        select distinct
               cr2.id,
               case
                 when cr_cnt.cnt = 1 and cr_date_4_5.start_date is not null then cr_date_4_5.start_date
                 when cr_date_4_5.start_date is null then cr_date_1_2_3_6_7.min_start_date
                 else case
                        when cr_date_next_not_4_5.min_start_date is not null then cr_date_next_not_4_5.min_start_date
                        when cr_date_next_after_prev_4_5.min_start_date is not null
                          then cr_date_next_after_prev_4_5.min_start_date
                        else cr_date_1_2_3_6_7.min_start_date
                   end
                 end as start_date
        from md.class_record cr2
               left join cr_date_4_5 on
            cr_date_4_5.class_record_id = cr2.id
               left join cr_date_1_2_3_6_7 on
            cr_date_1_2_3_6_7.class_record_id = cr2.id
               left join cr_date_next_not_4_5 on
            cr_date_next_not_4_5.class_record_id = cr2.id
               left join cr_date_next_after_prev_4_5 on
            cr_date_next_after_prev_4_5.class_record_id = cr2.id
               left join cr_cnt on
            cr_cnt.class_record_id = cr2.id
      ),
      terr_district as (
        select to2.organization_id,
               t.parent_id,
               string_agg(t.title, ', ' order by t.title) as title
        from md.territory_organization to2
               join ar.territory t on
            t.id = to2.territory_id
        group by to2.organization_id, t.parent_id
      ),
      teachers as (
        select f.group_id,
               string_agg(f.fio, ', ' order by f.fio) as list_fio
        from (
               select distinct l.group_id, trim(c.second_name || ' ' || c.first_name || ' ' || c.middle_name) as fio
               from md.lesson l
                      join md.schedule_timesheet_coworkers stc on
                       stc.lesson_id = l.id
                     and l.lesson_date between p_date_from /*PARAM Дата С*/
                         and p_date_to /*PARAM Дата по*/
                      join md.coworker c on
                   c.id = stc.coworker_id
             ) f
        group by f.group_id
      ),
      attendance as (
        select ad.id, ad."source", ad.user_role, crsr.class_record_id
        from md.attendance_data ad
               join md.lesson l on
                l.id = ad.lesson_id
              and l.lesson_date between p_date_from /*PARAM Дата С*/
                  and p_date_to /*PARAM Дата по*/
              and ad.attendance_data_type = 'CONFIRMED'
               join md.class_record cr on
            cr.group_id = l.group_id
               join md.class_record_status_registry crsr on
                crsr.class_record_id = cr.id
              and crsr.class_record_status_id = 6
              and l.lesson_date between crsr.start_date
                  and coalesce(crsr.end_date, now())
      ),
      attendance_stat as (
        select s.*,
               s.cnt_lesson - s.cnt_attended                                as cnt_missed,
               round(s.cnt_attended::numeric / s.cnt_lesson::numeric * 100) as percent_attendance
        from (
               select a.class_record_id,
                      count(*)                                                                                as cnt_lesson,
                      sum(case when lal.presence_mark = true then 1 else 0 end)                               as cnt_attended,
                      sum(case
                            when lal.presence_mark = true and lal."method" = 'SCANNING' then 1
                            else 0 end)                                                                       as cnt_with_skm,
                      sum(case
                            when lal.presence_mark = true and lal."method" = 'MANUAL' and a."source" = 'MOB' then 1
                            else 0 end)                                                                       as cnt_without_skm_mob,
                      sum(case
                            when lal.presence_mark = true and lal."method" = 'MANUAL' and a."source" = 'WEB' and
                                 a.user_role = 'COORDINATOR' then 1
                            else 0 end)                                                                       as cnt_without_skm_web_coordinator,
                      sum(case
                            when lal.presence_mark = true and lal."method" = 'MANUAL' and a."source" = 'WEB' and
                                 a.user_role = 'PROVIDER' then 1
                            else 0 end)                                                                       as cnt_without_skm_web_provider
               from attendance a
                      left join md.lesson_attendance_list lal on
                       a.id = lal.attendance_data_id
                     and a.class_record_id = lal.class_record_id
               group by a.class_record_id
             ) s
      )
    select
      /*Номер личного дела*/
      p.id,
      /*ФИО*/
      trim(p.second_name || ' ' || p.first_name || ' ' || p.patronymic)     as fio_participant,
      /*Телефон*/
      pc_tel.tel,
      /*Статус ЛД участника*/
      p_status.last_title                                                   as participant_last_status,
      /*Статус записи участника в группе*/
      cr_status.last_title                                                  as cr_last_status,
      /*Дата зачисления участника в группу*/
      date_trunc('day', cr_date.start_date)::date                           as date_enrolled,
      /*Краткое наименование ЦСО*/
      o.short_title                                                         as cso_short_title,
      /*Район*/
      case when tt.parent_id is not null then tt.title end                  as tcso_district,
      /*Округ*/
      t2.title                                                              as tcso_area,
      /*Краткое наименование организации поставщика*/
      o2.short_title                                                        as supplier_short_title,
      /*Ведомство организации-поставщика*/
      d.title                                                               as supplier_dept,
      /*Номер соглашения */
      c.contract_number,
      /*Направление  1 уровня*/
      a1.title                                                              as activity_title_L1,
      /*Направление 2 уровня*/
      a2.title                                                              as activity_title_L2,
      /*Направление 3 уровня*/
      a3.title                                                              as activity_title_L3,
      /*Код группы*/
      'G-' || lpad(cast(cr.group_id as varchar(50)), 8, '0')                as group_code,
      /*Краткое наименование ТЦСО координации группы*/
      o3.short_title                                                        as tc_short_title,
      /*Статус группы*/
      gs.title                                                              as group_status,
      /*ФИО координатора*/
      trim(c2.second_name || ' ' || c2.first_name || ' ' || c2.middle_name) as fio_coordinator,
      /*ФИО преподавателя группы*/
      teachers.list_fio                                                     as list_teachers_fio,
      /*Занятий проведено*/
      a_stat.cnt_lesson                                                     as cnt_lesson,
      /*Занятий посещено: Всего */
      a_stat.cnt_attended,
      /*С СКМ*/
      a_stat.cnt_with_skm,
      /*Без СКМ. Отметка в МП*/
      a_stat.cnt_without_skm_mob,
      /*Без СКМ. Отметка координатором в КИС МД*/
      a_stat.cnt_without_skm_web_coordinator,
      /*Без СКМ. Отметка поставщиком в КИС МД*/
      a_stat.cnt_without_skm_web_provider,
      /*Занятий пропущено*/
      a_stat.cnt_missed,
      /*Посещаемость, %*/
      a_stat.percent_attendance,
      /*Статус посещаемости*/
      case
        when a_stat.percent_attendance >= 80 and a_stat.percent_attendance <= 100 then 'Регулярно посещает занятия'
        when a_stat.percent_attendance >= 50 and a_stat.percent_attendance < 80 then 'Часто посещает занятия'
        when a_stat.percent_attendance >= 30 and a_stat.percent_attendance < 50 then 'Редко посещает занятия'
        when a_stat.percent_attendance >= 0 and a_stat.percent_attendance < 30 then 'Часто пропускает занятия'
        end                                                                 as status_attendance
    from md.participant p
           left join pc_tel on
        pc_tel.owner_id = p.id
           left join p_status on
        p_status.participant_id = p.id
           left join md.organization o on
        o.id = p.organization_id
           left join md.class_record cr on
        cr.participant_id = p.id
           left join cr_status on
        cr_status.class_record_id = cr.id
           left join cr_date on
        cr_date.id = cr.id
           left join terr_district tt on
            tt.organization_id = p.organization_id
          and tt.parent_id is not null
           left join ar.territory t2 on
        t2.id = tt.parent_id
           left join md."groups" g on
        g.id = cr.group_id
           left join md.organization o2 on
        o2.id = g.organization_id
           left join reference.department d on
        d.id = o2.department_id
           left join md.contract c on
        c.id = g.contract_id
           left join reference.activity a3 on
        a3.id = g.activity_id
           left join reference.activity a2 on
        a2.id = a3.parent_id
           left join reference.activity a1 on
        a1.id = a2.parent_id
           left join md.organization o3 on
        o3.id = g.territory_centre_id
           left join md.group_status_registry gsr on
            gsr.group_id = g.id and gsr.end_date is null and gsr.is_expectation = false
           left join reference.group_status gs on
        gs.id = gsr.status_id
           left join md.coworker c2 on
        c2.id = g.coworker_id
           left join teachers on
        teachers.group_id = g.id
           join attendance_stat a_stat on
        a_stat.class_record_id = cr.id
    where (case
             when p_district_ids[1] isnull then true
             else
                 p.organization_id in (
                 select to2.organization_id
                 from md.territory_organization to2
                        join ar.territory t on
                         t.id = to2.territory_id
                       and t.parent_id is not null
                 where t.id in (select unnest(p_district_ids)) /*PARAM Район*/
               )
      end)
      and (case
             when p_area_ids[1] isnull then true
             else
               t2.id in (select unnest(p_area_ids)) /*PARAM Округ*/
      end)
      and (case
             when p_tcso_s_ch_ids[1] isnull then true
             else
                 p.organization_id in (
                 select to2.organization_id
                 from md.territory_organization to2
                 where to2.organization_id in (select unnest(p_tcso_s_ch_ids)) /*PARAM ТЦСО ("свой-чужой")*/
               ) end)
      and (case
             when p_tcso_coordinators_ids[1] isnull then true
             else
               o3.id in (select unnest(p_tcso_coordinators_ids)) /*PARAM ТЦСО (координатор группы)*/
      end)
      and (case
             when p_tcso_creator_ids[1] isnull then true
             else
               o.id in (select unnest(p_tcso_creator_ids)) /*PARAM ТЦСО (создатель личного дела)*/
      end)
      and (case
             when p_uszn_ids[1] isnull then true
             else
                 p.organization_id in (
                 select o4.id
                 from md.organization o4
                 where o4.parent_organization_id in (
                   select o5.id
                   from md.organization o5
                   where o5.level_id = 2
                     and o5.parent_organization_id = 1095
                     and o5.id in (select unnest(p_uszn_ids)) /*PARAM УСЗН куратор ТЦСО, координирующих группы*/
                 )
               )
      end)
      and (case
             when p_provider_ids[1] isnull then true
             else
               o2.id in (select unnest(p_provider_ids)) /*PARAM Организация поставщика*/
      end)
      /*order by trim(p.second_name || ' ' || p.first_name || ' ' || p.patronymic), cr.group_id*/
    limit p_limit_value offset p_offset_value;
end;
$$;