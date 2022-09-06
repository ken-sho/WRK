drop function if exists public.report_1;
CREATE OR REPLACE FUNCTION public.report_1(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    rec_id                   bigint,
    fio                      text,
    phones                   text,
    input_date               text,
    organization_short_title text,
    neighbourhood            text,
    district                 text,
    rejection_reason         text,
    activity_title_level_1   text,
    activity_title_level_2   text,
    activity_title_level_3   text,
    group_id                 bigint,
    coordinators             text,
    leaving_status           text,
    leaving_reason           text,
    leaving_reason_comment   text,
    leaving_date             text,
    days_in_leaving_status   integer
  )
  language plpgsql
as $$
begin
  
  return query
    
    -- участники со всеми регистрами
    with
      L1 as (
        select distinct on (pt.id)
               pt.id                                                          id,
               FIRST_VALUE(R1.status_id) over w1                              status_id,
               concat(pt.second_name, ' ', pt.first_name, ' ', pt.patronymic) fio,
               max((case
                      when md.participant_organization.organization_id is not null
                        then md.participant_organization.organization_id
                      else pt.organization_id end))                           organization_id,
               max(md.class_record.group_id)                                  group_id,
               array_to_string(array_agg(district.title) over w1, '; ')       district_title,
               max(neighbourhood.title)                                       neighbourhood_title,
               max(reason.reason)::text                                       reason_title,
               max(class_record_status.title)::text                           class_record,
               max(class_reason.title)::text                                  class_reason,
               max(R2.comment)::text                                          leaving_comment,
               max(R1.start_date)::date::text                                 start_date
        
        from md.participant pt
               -- R1, регистр статусов личного дела
               left join reference.participant_status_log R1 on (pt.id = R1.participant_id)
            
            -- R2, регистр записи в группу
               left join md.class_record on (pt.id = md.class_record.participant_id)
               left join md.class_record_status_registry R2 on (md.class_record.id = class_record_id)
            --Справочники
               left join reference.class_record_status class_record_status
                         on (R2.class_record_status_id = class_record_status.id)
               left join reference.participant_status_reason reason on (R1.reason_id = reason.id)
               left join reference.class_record_status_reason class_reason
                         on (class_record_status.id = class_reason.class_record_status_id)
            
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
          -- статус личного дела "Отказ от участия" или "Отказано в участии"
          (R1.status_id in (1, 8)
            -- срез регистра
            and R1.start_date between i_date_from and i_date_to
            and (R1.end_date > i_date_to or R1.end_date is null))
          -- статус личного дела "Подбор направления"
           or (R1.status_id = 4
          -- статус записи в группу "Отчислен"
          and R2.class_record_status_id = 5
          -- срез регистра
          and R1.start_date between i_date_from and i_date_to
          and (R1.end_date > i_date_to or R1.end_date is null))
          
          -- территории
          and (district_ids = '{}'
            or district.id in (select unnest(district_ids)))
          -- ТЦСО
          and (organization_ids = '{}'
            or md.organization.id in (select unnest(organization_ids)))
        group by pt.id, R1.status_id, district.title, R1.id
          window
            w1 as (partition by R1.participant_id order by R1.id desc)
      )
    
    select L1.id                                              rec_id,--Номер личного дела (id)
           max(L1.fio)                                        fio,--ФИО
           array_to_string(array_agg(md.contact.value), '; ') phones,--телефон(ы)
           R1_1.start_date::date::text                        input_date, --Дата создания личного дела
           max(org.short_title)                               org_short_title,--ТЦСО краткое наименование
           max(L1.neighbourhood_title)                        neighbourhood, --округ
           max(L1.district_title)                             district,--район
           max(L1.reason_title)                               rejection_reason,--Причина отказа
           max(a1.title)                                      activity_l1_title,--направление 1 уровня
           max(a2.title)                                      activity_l2_title,--направление 2 уровня
           max(a3.title)                                      activity_l3_title,--направление 3 уровня
           L1.group_id                                        group_id,--код группы (id)
           array_to_string(array_agg(concat(coworker.second_name, ' ', coworker.first_name, ' ', coworker.middle_name)),
                           ' ')                               coordinators, --координаторы
           max(L1.class_record)                               leaving_status, --Статус отчисления
           max(L1.class_reason)                               leaving_reason, --Причина отчисления
           max(L1.leaving_comment)                            leaving_reason_comment, --комментарий
           max(L1.start_date)                                 leaving_date, --Дата отчисления
           age_in_days(max(L1.start_date)::date, i_date_to)   days_in_leaving_status --Количество дней в стадии отчисления
    
    from L1
           -- подтягиваем справочники
           left join md.contact on (L1.id = md.contact.owner_id)
           left join md.organization org on (L1.organization_id = org.id)
           left join reference.participant_status status on (L1.status_id = status.id)
           left join md.groups on (L1.group_id = md.groups.id)
        -- 	left join md.coworker on (md.groups.coworker_id = md.coworker.id)
      
           left join reference.activity a3 on (md.groups.activity_id = a3.id)
           left join reference.activity a2 on (a3.parent_id = a2.id)
           left join reference.activity a1 on (a2.parent_id = a1.id)
      
           left join reference.participant_status_log R1_1 on (L1.id = R1_1.participant_id)
      
           left join md.groups group_coworker on (L1.group_id = group_coworker.id)
           left join md.coworker coworker on (group_coworker.coworker_id = coworker.id)
    
    where
      -- контактная инфа
      md.contact.contact_owner_type_id = 1 -- тип "Личное дело"
      and md.contact.contact_type_id = 1   -- телефон
      
      -- срок ожидания с момента создания личного дела
      and R1_1.status_id = 3               -- статус "Создан"
    
    group by L1.id, L1.group_id, R1_1.start_date,
             L1.leaving_comment, L1.start_date
    order by L1.group_id, L1.id
    limit limit_param offset offset_param;

end;
$$;