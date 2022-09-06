drop function if exists public.report_14;
CREATE OR REPLACE FUNCTION public.report_14(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    participant_id          bigint,
    fio                     text,
    phones                  text,
    resonsible_person       text,
    org_short_title         text,
    org_full_title          text,
    neighbourhood           text,
    district                text,
    group_status            text,
    stopping_reason         text,
    stopping_start_date     date,
    stopping_end_date       date,
    stopping_comment        text,
    days_in_stopping_status integer,
    group_code              text,
    activity_l1_title       text,
    activity_l2_title       text,
    activity_l3_title       text
  )
  language plpgsql
as $$
begin
  
  return query
    
    -- участники со всеми регистрами
    with
      L1 as (
        select distinct on (pt.id)
               pt.id,
               max(R1.status_id)                                              status_id,
               concat(pt.second_name, ' ', pt.first_name, ' ', pt.patronymic) fio,
               max(md.organization.id)                                        organization_id,
               max(class_record.group_id)                                     group_id,
               max(crsr.title)                                                reason_title,
               max(R2.start_date)                                             stoppingStartDate,
               max(R2.end_date)                                               stoppingEndDate,
               max(R2.comment)                                                stoppingComment,
               max(crs.title)                                                 class_record_status_title,
               array_to_string(array_agg(district.title) over w1, '; ')       district_title,
               max(neighbourhood.title)                                       neighbourhood_title
        from md.participant pt
               -- R1, регистр статусов личного дела
               left join reference.participant_status_log R1 on (pt.id = R1.participant_id)
            
            -- R2, регистр записи в группу
               left join md.class_record on (pt.id = class_record.participant_id)
               left join md.class_record_status_registry R2 on (class_record.id = class_record_id)
               left join reference.class_record_status_reason crsr
                         on crsr.class_record_status_id = R2.class_record_status_id
               left join reference.class_record_status crs on crsr.class_record_status_id = crs.id
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
          -- статус записи в группу "Pause"
          R2.class_record_status_id = 2
          -- срез регистра
          and R2.start_date between i_date_from and i_date_to
          and (R2.end_date > i_date_from or R2.end_date is null)
          
          -- территории
          and (district_ids = '{}'
          or district.id in (select unnest(district_ids)))
          -- ТЦСО
          and (organization_ids = '{}'
          or md.organization.id in (select unnest(organization_ids)))
        
        group by pt.id, district.title, R1.id
          window
            w1 as (partition by R1.participant_id order by R1.id desc)
      )
    
    select L1.id                                                                    id,
           max(L1.fio)                                                              fio,
           array_to_string(array_agg(distinct contact.value), '; ')                 phones,
           'NOT_IMPLEMENTED_YET'                                                    resonsible_person,
    
           max(org.short_title)                                                     org_short_title,
           max(org.full_title)                                                      org_full_title,
           max(L1.neighbourhood_title)                                              neighbourhood,           --округ
           max(L1.district_title)                                                   district,--район
           max(L1.class_record_status_title)                                        group_status,            -- Статус записи в группу
           max(L1.reason_title)                                                     stopping_reason,         -- Причина приостановки
           max(L1.stoppingStartDate)::date                                          stopping_start_date,     -- Дата начала приостановки
           max(L1.stoppingEndDate)::date                                            stopping_end_date,       -- Плановая дата конца приостановки
           max(L1.stoppingComment)                                                  stopping_comment,        -- Комментарий приостановки
           (EXTRACT(epoch from age(now(), max(L1.stoppingStartDate))) / 86400)::int days_in_stopping_status, -- Количество дней в приостановке
           L1.group_id::text                                                        group_code,
           max(a1.title)                                                            activity_l1_title,
           max(a2.title)                                                            activity_l2_title,
           max(a3.title)                                                            activity_l3_title
    
    from L1
           -- подтягиваем справочники
           left join md.contact on (L1.id = contact.owner_id)
           left join md.organization org on (L1.organization_id = org.id)
           left join reference.participant_status status on (L1.status_id = status.id)
           left join md.groups on (L1.group_id = groups.id)
           left join md.coworker on (groups.coworker_id = coworker.id)
      
           left join reference.activity a3 on (groups.activity_id = a3.id)
           left join reference.activity a2 on (a3.parent_id = a2.id)
           left join reference.activity a1 on (a2.parent_id = a1.id)
        
        -- ещё раз регистр для статуса 3
           left join reference.participant_status_log R1_1 on (L1.id = R1_1.participant_id)
    
    where
      -- контактная инфа
      -- срок ожидания с момента создания личного дела
      md.contact.contact_owner_type_id = 1 -- тип "Личное дело"
      and contact.contact_type_id = 1      -- телефон
      and R1_1.status_id = 3               -- статус "Создан"
    
    group by L1.id, L1.group_id
    order by group_id, id
    limit limit_param offset offset_param;

end;
$$;