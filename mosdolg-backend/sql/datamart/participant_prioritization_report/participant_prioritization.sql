drop function if exists rep.participant_prioritization;
create function rep.participant_prioritization(
  tcso   bigint[] default array []::integer[], areas bigint[] default array []::integer[],
  p_date date default current_date)
  returns TABLE (
    id                   bigint,
    fio                  text,
    create_date          text,
    status               character varying,
    group_code           text,
    supplier_dept        text,
    supplier_name        text,
    activity_title_l1    text,
    activity_title_l2    text,
    activity_title_l3    text,
    group_status         character varying,
    enrollment_date      text,
    cr_last_status       character varying,
    creator_tcso         text,
    area_tcso            text,
    district_tcso        text,
    fio_coordinator      text,
    init_enrollment_tcso text,
    fio_enrollment_user  text
  )
  language plpgsql
as $$
declare

begin
  return query
    with
      L0 as (select psl.participant_id,
                    psl.status_id,
                    cr.group_id,
                    crsr.class_record_status_id,
                    crsr.class_record_id,
                    crsr.user_profile_id
             from reference.participant_status_log psl
                    join md.class_record cr on psl.participant_id = cr.participant_id
                    join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
             where p_date between psl.start_date::date
               and coalesce(psl.end_date::date, current_date)
               and psl.status_id in (5, 6, 7)
               and p_date between crsr.start_date::date
               and coalesce(crsr.end_date::date, current_date)
               and crsr.class_record_status_id = any
                   (case
                      when psl.status_id = 7 then (array [6::bigint])
                      when psl.status_id = 5 then (array [2::bigint])
                      when psl.status_id = 6 then (array [7::bigint,3::bigint,1::bigint])
                      else (array [0::bigint]) end
                     )),
      L1 as (select ppd.participant_id,
                    array_agg(ppd.id order by ppd.enrollment_date) ppd_ar
             from rep.participant_prioritization_datamart ppd
                    join L0 on ppd.participant_id = L0.participant_id and ppd.group_id = L0.group_id
             group by ppd.participant_id)
    select ---Номер личного дела
           ppd.participant_id,
           ---ФИО участника
           ppd.fio,
           ---Дата и время создания личного дела
           to_char(ppd.create_date,'dd.mm.yyyy HH24:MI'),
           ---Статус личного дела
           ps.title,
           ---Код группы
           ppd.group_code,
           ---Ведомство поставщика
           ppd.supplier_dept,
           ---Наименование поставщика
           ppd.supplier_name,
           ---Направление 1 уровня
           ppd.activity_title_l1,
           ---Направление 2 уровня
           ppd.activity_title_l2,
           ---Направление 3 уровня
           ppd.activity_title_l3,
           ---Статус группы
           gs.title,
           ---Дата и время  зачисления
           to_char(ppd.enrollment_date,'dd.mm.yyyy HH24:MI'),
           ---Статус записи участника в группу
           crs.title,
           ---Краткое наименование ТЦСО координации группы (учета уникальных участников)
           ppd.creator_tcso,
           ---Район ТЦСО
           tr1.title::text,
           ---Округ ТЦСО
           tr2.title::text,
           ---ФИО координатора
           ppd.fio_coordinator,
           ---ТЦСО, проводившее зачисление участника в группу
           ppd.init_enrollment_tcso,
           ---ФИО специалиста, зачислявшего участника в группу
           trim(concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name))
    from rep.participant_prioritization_datamart ppd
           join L1 on ppd.id = L1.ppd_ar[1]
           join L0 on ppd.participant_id = L0.participant_id and ppd.group_id = L0.group_id
           join reference.class_record_status crs on L0.class_record_status_id = crs.id
           join reference.participant_status ps on L0.status_id = ps.id
           join md.group_status_registry gsr on ppd.group_id = gsr.group_id
           join reference.group_status gs on gsr.status_id = gs.id
           left join md.territory_organization torg on ppd.creator_tcso_id = torg.organization_id
           left join ar.territory tr1 on torg.territory_id = tr1.id
           left join ar.territory tr2 on tr1.parent_id = tr2.id
           left join md.user_profile up on L0.user_profile_id = up.id
           left join md.coworker cw on up.coworker_id = cw.id
    where p_date between gsr.start_date::date
      and coalesce(gsr.end_date::date, current_date)
      and (case
             when areas[1] isnull then true
             else
               tr2.id in (select unnest(areas)) /*PARAM Округ*/
      end)
      and (case
             when tcso[1] isnull then true
             else
               ppd.creator_tcso_id in (select unnest(tcso)) /*PARAM ТЦСО*/
      end)
    order by ppd.participant_id;

end;
$$;