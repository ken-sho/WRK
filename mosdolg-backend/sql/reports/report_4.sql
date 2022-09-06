drop function if exists public.report_4;
CREATE OR REPLACE FUNCTION public.report_4(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    row_id                    bigint,
    participant_id            bigint,
    participant_status        text,
    participant_creation_date text,
    participant_fio           text,
    neighbourhood             text,
    district                  text,
    creator_fio               text,
    org_short_title           text,
    activity_total_num        bigint,
    activity_filled_num       bigint,
    activity_unfilled_num     bigint,
    groups_total              bigint,
    groups_created            bigint,
    groups_prolong            bigint,
    groups_with_alerts        bigint,
    groups_waiting_lessons    bigint,
    groups_started            bigint,
    groups_continued          bigint,
    groups_on_pause           bigint,
    groups_resumed            bigint,
    groups_finished           bigint,
    attendance_possible       integer,
    attendance_actual         integer,
    attendance_rate           integer,
    communication_time        text,
    communication_reason      text,
    communication_result      text,
    notes                     text
  )
  language plpgsql
as $$
begin
  
  return query
    -- статусы участников, из reference.participant_status_log
    --
    -- формируем подзапрос по любым статусам,
    -- затем оставляем только те, у которых дата создания not null
    with
      L1 as (
        select distinct on (pt_id)
               pt.id                                                                  pt_id,
               concat(pt.second_name, ' ', pt.first_name, ' ', pt.patronymic)         fio,
               max(md.organization.short_title)                                       org_short_title,
        
               -- последний статус на дату выборки + причина + комментарий
               FIRST_VALUE(R1.status_id) over w1                                      status_id,
               FIRST_VALUE(R1.reason_id) over w1                                      reason_id,
               FIRST_VALUE(R1.comment) over w1                                        pcomment,
               -- дата создания
               max(case R1.status_id when 3 then R1.start_date else null end) over w2 creation_date,
               array_to_string(array_agg(district.title) over w1, '; ')               district_title,
               max(neighbourhood.title)                                               neighbourhood_title
        
        from md.participant pt
               -- R1, регистр изменений статуса участников
               left join reference.participant_status_log R1 on (pt.id = R1.participant_id)
            -- территории
               left join reference.department on (reference.department.key = 'D_SOZ')
               left join md.participant_organization on (md.participant_organization.participant_id = pt.id
            and md.participant_organization.link_type = 'CREATED'
            and md.participant_organization.enabled = true)
               left join md.organization on (md.organization.id = (case
                                                                     when md.participant_organization.organization_id is not null
                                                                       then md.participant_organization.organization_id
                                                                     else pt.organization_id end)
            and md.organization.department_id = reference.department.id)
               left join md.territory_organization on (md.territory_organization.organization_id = md.organization.id)
               left join ar.territory district
                         on (district.parent_id is not null and (district.id = md.territory_organization.territory_id
                           or district.parent_id = md.territory_organization.territory_id))
               left join ar.territory neighbourhood
                         on (neighbourhood.parent_id is null and neighbourhood.id = district.parent_id)
        where
          -- срез регистра
          R1.start_date between i_date_from and i_date_to
          and (R1.end_date > i_date_to or R1.end_date is null)
          
          -- территории
          and (district_ids = '{}'
          or district.id in (select unnest(district_ids)))
          -- ТЦСО
          and (organization_ids = '{}'
          or md.organization.id in (select unnest(organization_ids)))
        group by pt.id, district.title, R1.status_id, R1.id
          window
            w1 as (partition by R1.participant_id order by R1.id desc),
            w2 as (partition by R1.participant_id)
        
        order by pt_id
      ),
      
      -- статусы групп, здесь же профили активности
      L2 as (
        select distinct on (pt_id, gr_id)
               rec.participant_id                             pt_id,
               rec.group_id                                   gr_id,
               FIRST_VALUE(R1.class_record_status_id) over w1 last_status,
               FIRST_VALUE(R1.comment) over w1                last_comment,
               case P1.status_id when 1 then 1 else 0 end     active_profile
        
        from md.class_record rec
               -- R1, регистр статусов участия в группах
               left join md.class_record_status_registry R1 on (rec.id = R1.class_record_id)
            -- профили активности, нужны для проверки статусов профилей
               left join md.participant_activity_profile P1 on (rec.participant_activity_profile_id = P1.id)
        
        where
          -- срез регистра
          R1.start_date between i_date_from and i_date_to
          and (R1.end_date > i_date_from or R1.end_date is null)
          
          -- профиль активности в статусе "активен"
          and P1.status_id = 1
          window
            w1 as (partition by R1.class_record_id order by R1.id desc)
        
        order by pt_id, gr_id
      )
    
    select distinct on (pt_id)
           row_number() over ()                                                                      rec_id,--Номер записи
           pt_id                                                                                     participant_id,--Номер личного дела
           R1.title::text                                                                            participant_status,--Статус личного дела
           L1.creation_date::date::text                                                              participant_creation_date,--Дата создания личного дела
           L1.fio::text                                                                              participant_fio,--ФИО участника
           --Дата рождения
           --Пол
           --СКМ
           --Связанный сотрудник СПП
           --ТЦСО к которому привязан участник
           L1.neighbourhood_title                                                                    neighbourhood,--Округ
           L1.district_title                                                                         district,--Район
           'not implemented'                                                                         creator_fio,
           L1.org_short_title::text,--Организация создания
    
           -- профили активности
           sum(L2.active_profile) over w1                                                            activity_total_num,--Всего профилей активности
           sum(case when L2.last_status in (1, 2, 3, 6, 7) and L2.active_profile = 1 then 1 else 0 end)
           over w1                                                                                   activity_filled_num,--Удовлетворено профилей активности
           sum(case when L2.last_status not in (1, 2, 3, 6, 7) and L2.active_profile = 1 then 1 else 0 end)
           over w1                                                                                   activity_unfilled_num,--Неудовлетворенно профилей активности
    
           -- группы
           -- общее количество групп
           sum(case when L2.last_status in (3, 4, 6, 7, 8, 9, 11, 12, 13) then 1 else 0 end) over w1 groups_total,
           -- создана, идёт набор
           sum(case when L2.last_status = 3 then 1 else 0 end) over w1                               groups_created,
           -- создана, набор продлён
           sum(case when L2.last_status = 4 then 1 else 0 end) over w1                               groups_prolong,
           -- создана, уведомление участников
           sum(case when L2.last_status = 6 then 1 else 0 end) over w1                               groups_with_alerts,
           -- ожидание начала занятий
           sum(case when L2.last_status = 7 then 1 else 0 end) over w1                               groups_waiting_lessons,
           -- группа приступила к занятиям
           sum(case when L2.last_status = 8 then 1 else 0 end) over w1                               groups_started,
           -- продолжение занятий
           sum(case when L2.last_status = 12 then 1 else 0 end) over w1                              groups_continued,
           -- приостановка занятий
           sum(case when L2.last_status = 9 then 1 else 0 end) over w1                               groups_on_pause,
           -- возобновление занятий
           sum(case when L2.last_status = 11 then 1 else 0 end) over w1                              groups_resumed,
           -- занятия завершены
           sum(case when L2.last_status = 13 then 1 else 0 end) over w1                              groups_finished,
    
           -- посещаемость участника
           0                                                                                         attendance_possible,--Занятий было
           0                                                                                         attendance_actual,--Занятий посещено
           0                                                                                         attendance_rate,--Посещаемость
           --с СКМ
           --без СКМ
    
           -- прочее
           (FIRST_VALUE(R2.communication_date) over w2)::date::text                                  communication_time,--Дата и время последней коммуникации с пользователем
           (FIRST_VALUE(R3.title) over w2)::text                                                     communication_reason,--Причина коммуникации
           (FIRST_VALUE(R4.title) over w2)::text                                                     communication_result,--Результат коммуникации
           trim(concat(L2.last_comment, ' ', L1.pcomment))                                           notes--Комментарий
    
    from L1
           left join L2 using (pt_id)
        
        -- подтягиваем остальные справочники
           left join reference.participant_status R1 on (L1.status_id = R1.id)
           left join md.communication_history R2 on (L1.pt_id = R2.communicated_id)
           left join reference.communication_reason R3 on (R2.communication_reason_id = R3.id)
           left join reference.communication_result R4 on (R2.communication_result_id = R4.id)
    
    where L1.creation_date is not null
          -- AND R2.communicated_entity_id in (1, 2) -- личное дело либо запись участника
      
      window
        w1 as (partition by pt_id),
        w2 as (partition by pt_id order by R2.communication_date desc)
    limit limit_param offset offset_param;

end;
$$;