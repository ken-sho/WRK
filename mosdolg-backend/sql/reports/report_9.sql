drop function if exists public.report_9;
CREATE OR REPLACE FUNCTION public.report_9(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    "Номер анкеты"                      bigint,
    "ФИО участника"                     text,
    "Краткое наименование ЦСО"          text,
    "Направленность 1 уровня отчислен"  text,
    "Направленность 2 уровня отчислен"  text,
    "Направленность 3 уровня отчислен"  text,
    "Округ отчисленной группы"          text,
    "Район отчисленной группы"          text,
    "Код группы отчислен"               text,
    "ФИО координатора отчислен"         text,
    "ФИО преподавателей отчислен"       text,
    "Дата отчисления"                   text,
    "Статус записи в группе"            text,
    "Причина отчисления"                text,
    "Комментарий отчисления"            text,
    "Дата зачисления"                   text,
    "Код группы зачислен"               text,
    "Направленность 1 уровня зачислен"  text,
    "Направленность 2 уровня зачислен"  text,
    "Направленность 3 уровня зачислен"  text,
    "ФИО координатора зачислен"         text,
    "ФИО преподавателей зачислен"       text,
    "Округ зачисленной группы"          text,
    "Район зачисленной группы"          text,
    "Дней между отчислением и зачислен" double precision
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L0 as (
        select cr.participant_id,
               crsr.id                                                                                  as prev_crsrid,
               crsr.class_record_id                                                                     as prev_crid,
               crsr.class_record_status_id                                                              as prev_stt,
               crsr.start_date                                                                          as prev_date,
               crsr.comment                                                                             as prev_comment,
               crsr.reason                                                                              as prev_reason,
               lead(crsr.id) over (partition by cr.participant_id order by crsr.id)                     as next_crsrid,
               lead(crsr.class_record_status_id) over (partition by cr.participant_id order by crsr.id) as next_stt,
               lead(crsr.class_record_id) over (partition by cr.participant_id order by crsr.id)        as next_crid,
               lead(crsr.start_date) over (partition by cr.participant_id order by crsr.id)             as next_date
        from md.class_record cr
               join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
            and crsr.start_date >= i_date_from
            and crsr.start_date <= i_date_to
        order by cr.id, crsr.id
      ),
      L1 as (
        select L0.*,
               date_part('day', L0.next_date - L0.prev_date) as delta
        from L0
        where L0.prev_stt in (4, 5)
          and L0.next_stt in (1, 2, 3, 6, 7)
          and date_part('day', L0.next_date - L0.prev_date) < 14
      ),
      lesson as (
        select l.group_id,
               string_agg(
                 distinct concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name), ', '
                 ) as teacher
        from md.lesson l
               join md.schedule_timesheet_coworkers stc on l.id = stc.lesson_id
               join md.coworker cw on stc.coworker_id = cw.id
        group by l.group_id
      )
    
    select p.id                                                                           as participant_id,
           concat(p.second_name, ' ', p.first_name, ' ', p.patronymic)                    as participant_fio,
           o_part.short_title::text                                                       as cso,
           a1_prev.title::text                                                            as prev_act1,
           a2_prev.title::text                                                            as prev_act2,
           a3_prev.title::text                                                            as prev_act3,
           tr2_prev.title::text                                                           as prev_neighbourhood,
           tr1_prev.title::text                                                           as prev_district,
           concat('G-', lpad(g_prev.id::text, 8, '0'))                                    as prev_gcode,
           concat(cw_prev.second_name, ' ', cw_prev.first_name, ' ', cw_prev.middle_name) as prev_coordanator,
           lesson_prev.teacher                                                            as prev_teacher,
           to_char(L1.prev_date, 'dd.mm.yyyy')                                            as prev_date,
           crs_prev.title::text                                                           as prev_stt,
           crsr_prev.title::text                                                          as prev_reason,
           L1.prev_comment::text                                                          as prev_comment,
           to_char(L1.next_date, 'dd.mm.yyyy')                                            as next_date,
           concat('G-', lpad(g_next.id::text, 8, '0'))                                    as next_gcode,
           a1_next.title::text                                                            as next_act1,
           a2_next.title::text                                                            as next_act2,
           a3_next.title::text                                                            as next_act3,
           concat(cw_next.second_name, ' ', cw_next.first_name, ' ', cw_next.middle_name) as next_coordanator,
           lesson_next.teacher                                                            as next_teacher,
           tr2_next.title::text                                                           as next_neighbourhood,
           tr1_next.title::text                                                           as next_district,
           L1.delta
    from L1
           join md.participant p on L1.participant_id = p.id
           join md.organization o_part on p.organization_id = o_part.id
           join md.class_record cr_prev on L1.prev_crid = cr_prev.id
           join md.groups g_prev on cr_prev.group_id = g_prev.id
           left join reference.activity a3_prev on g_prev.activity_id = a3_prev.id
           left join reference.activity a2_prev on a3_prev.parent_id = a2_prev.id
           left join reference.activity a1_prev on a2_prev.parent_id = a1_prev.id
           left join md.organization o2 on g_prev.territory_centre_id = o2.id
           left join md.territory_organization torg on o2.id = torg.organization_id
           left join ar.territory tr1_prev on torg.territory_id = tr1_prev.id
           left join ar.territory tr2_prev on tr1_prev.parent_id = tr2_prev.id
           left join md.coworker cw_prev on g_prev.coworker_id = cw_prev.id
           left join lesson as lesson_prev on g_prev.id = lesson_prev.group_id
           left join reference.class_record_status crs_prev on L1.prev_stt = crs_prev.id
           left join reference.class_record_status_reason crsr_prev on L1.prev_reason = crsr_prev.id
           left join md.class_record cr_next on L1.next_crid = cr_next.id
           left join md.groups g_next on cr_next.group_id = g_next.id
           left join reference.activity a3_next on g_prev.activity_id = a3_next.id
           left join reference.activity a2_next on a3_next.parent_id = a2_next.id
           left join reference.activity a1_next on a2_next.parent_id = a1_next.id
           left join md.organization o3 on g_next.territory_centre_id = o3.id
           left join md.territory_organization torg2 on o3.id = torg2.organization_id
           left join ar.territory tr1_next on torg.territory_id = tr1_next.id
           left join ar.territory tr2_next on tr1_next.parent_id = tr2_next.id
           left join md.coworker cw_next on g_next.coworker_id = cw_next.id
           left join lesson as lesson_next on g_next.id = lesson_next.group_id
    where
      -- территории
      (district_ids = '{}'
        or tr1_prev.id in (select unnest(district_ids)))
      -- ТЦСО
      and (organization_ids = '{}'
      or g_prev.organization_id in (select unnest(organization_ids)))
    order by p.id
    limit limit_param offset offset_param;

end;
$$;