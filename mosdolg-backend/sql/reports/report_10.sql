drop function if exists public.report_10;
CREATE OR REPLACE FUNCTION public.report_10(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    participant_id              bigint,
    participant_fio             text,
    participant_phones          text,
    responsible_person          text,
    responsible_person_tcso     text,
    participant_tcso            text,
    area                        text,
    district                    text,
    tcso_full_title             text,
    communication_date          text,
    group_code                  text,
    communication_result        text,
    communication_reason        text,
    communication_result_reason text,
    next_communication_date     text
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L1 as (
        select distinct on (pt.id)
               pt.id                                                          participant_id,
               R1.status_id                                                   status_id,
               concat(pt.second_name, ' ', pt.first_name, ' ', pt.patronymic) fio,
               max(md.organization.short_title)                               short_title,
               array_to_string(array_agg(district.title) over w1, '; ')       district_title,
               max(neighbourhood.title)                                       neighbourhood_title,
               max(md.class_record.group_id)                                  group_id,
               max(CH.communication_date)                                     communication_date,
               max(CH.planned_communication_date)                             next_date,
               max(CR.title)                                                  communication_result,
               max(CRS.title)                                                 communication_reason,
               max(CR2.title)                                                 communication_result_reason
        
        from md.communication_history CH
               left join md.class_record on (md.class_record.id = CH.communicated_id and CH.communicated_entity_id = 2)
               left join md.class_record_status_registry R2 on (md.class_record.id = class_record_id)
               left join md.participant pt on (md.class_record.participant_id = pt.id or (pt.id = CH.communicated_id
            and CH.communicated_entity_id = 1))
            -- R1, регистр статусов личного дела
               left join reference.participant_status_log R1 on (pt.id = R1.participant_id)
            
            -- территории
               left join reference.department on (reference.department.key = 'D_SOZ')
               left join md.participant_organization on (md.participant_organization.participant_id = pt.id
            and md.participant_organization.link_type = 'CREATED'
            and md.participant_organization.enabled = true)
               left join md.organization on ((md.organization.id = pt.organization_id
            or md.organization.id = md.participant_organization.organization_id)
            and md.organization.department_id = reference.department.id)
               left join md.territory_organization on (md.territory_organization.organization_id = md.organization.id)
               left join ar.territory district
                         on (district.parent_id is not null and (district.id = md.territory_organization.territory_id
                           or district.parent_id = md.territory_organization.territory_id))
               left join ar.territory neighbourhood
                         on (neighbourhood.parent_id is null and neighbourhood.id = district.parent_id)
            -- коммуникации
            -- это работает только для случая CH.communicated_entity_id = 2
            -- 	left join md.communication_history CH on (md.class_record.id = CH.communicated_id)
            -- для случая CH.communicated_entity_id = 1 (нужно через union реализовывать позже)
            -- left join md.communication_history CH on (pt.id = CH.communicated_id)
            
            -- Справочник типов коммуникаций
            -- left join reference.communicated_entity_type CH_TYPE on (CH.communicated_entity_id = CH_TYPE.id)
          
               left join reference.communication_result CR on (CH.communication_result_id = CR.id)
               left join reference.communication_reason CRS on (CH.communication_reason_id = CRS.id)
               left join reference.communication_result_reason CR2 on (CH.communication_reason_id = CR2.id)
        
        where CH.communication_date between i_date_from and i_date_to
          
          and CH.communicated_entity_id in (1, 2)
          
          -- территории
          and (district_ids = '{}'
          or district.id in (select unnest(district_ids)))
          -- ТЦСО
          and (organization_ids = '{}'
          or md.organization.id in (select unnest(organization_ids)))
        group by pt.id, district.title, R1.status_id, R1.id
          window
            w1 as (partition by R1.participant_id order by R1.id desc)
      )
    select L1.participant_id,
           max(L1.fio)                                                   participant_fio,
           array_to_string(array_agg(distinct (md.contact.value)), '; ') participant_phones,
           'NOT_IMPLEMENTED_YET'                                         responsible_person,
           'NOT_IMPLEMENTED_YET'                                         responsible_person_tcso,
    
           max(L1.short_title)                                           participant_tcso,
           max(L1.neighbourhood_title)                                   area,
           max(L1.district_title)                                        district,
           'NOT_IMPLEMENTED_YET'                                         tcso_full_title,
    
           max(L1.communication_date)::text                              communication_date,
           max(L1.group_id)::text                                        group_code,
           max(L1.communication_result)                                  communication_result,
           max(L1.communication_reason)                                  communication_reason,
           max(L1.communication_result_reason)                           communication_result_reason,
           max(L1.next_date)::text                                       next_communication_date
    
    from L1
           -- контакты
           left join md.contact on (L1.participant_id = md.contact.owner_id)
        -- подтягиваем справочники
           left join reference.participant_status status on (L1.status_id = status.id)
           left join md.groups on (L1.group_id = md.groups.id)
           left join md.coworker on (md.groups.coworker_id = md.coworker.id)
    where
      -- контактная инфа
      md.contact.contact_owner_type_id = 1 -- тип "Личное дело"
      and md.contact.contact_type_id = 1   -- телефон
    
    group by L1.participant_id, L1.group_id
    order by L1.group_id, L1.participant_id
    
    limit limit_param offset offset_param;

end;
$$;