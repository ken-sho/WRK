drop function if exists public.report_13;
CREATE OR REPLACE FUNCTION public.report_13(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    participant_id                              bigint,
    participant_full_name                       text,
    personal_phone_number                       text,
    responsible_person                          text,
    responsible_person_organization_short_title text,
    tcso_short_title                            text,
    area                                        text,
    distict                                     text,
    tcso_full_title                             text,
    plan_communication_date                     text,
    group_code                                  text,
    communication_result                        text,
    communication_reason                        text
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L1 as (select min(pt.id)                                                          participant_id,
                    max(concat(pt.second_name, ' ', pt.first_name, ' ', pt.patronymic)) fio,
                    max(md.organization.short_title)                                    organization_title,
                    max(md.class_record.group_id)                                       group_id,
                    (case
                       when CH.planned_communication_date is not null then CH.planned_communication_date
                       else CH.communication_date end)                                  next_date,
                    max(CR.title)                                                       communication_result,
                    max(reference.communication_reason.title)                           communication_reason,
                    array_to_string(array_agg(distinct district.title), '; ')           district_title,
                    max(neighbourhood.title)                                            neighbourhood_title,
                    array_to_string(array_agg(distinct pc.value), '; ')                 personal_phone_number
      
             from md.communication_history CH
                    left join md.class_record on (md.class_record.id = CH.communicated_id)
                    left join md.participant pt on (md.class_record.participant_id = pt.id)
          
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
                    left join md.territory_organization
                              on (md.territory_organization.organization_id = md.organization.id)
                    left join ar.territory district on (district.parent_id is not null and
                                                        (district.id = md.territory_organization.territory_id
                                                          or
                                                         district.parent_id = md.territory_organization.territory_id))
                    left join ar.territory neighbourhood
                              on (neighbourhood.parent_id is null and neighbourhood.id = district.parent_id)
          
                 -- коммуникации
                    left join reference.communication_result CR on (CH.communication_result_id = CR.id)
                    left join reference.communication_reason
                              on (CH.communication_reason_id = reference.communication_reason.id)
                    left join md.participant_contact pc on (pc.contact_type_id = 1 and pc.owner_id = pt.id)
      
             where CH.communicated_entity_id in (1, 2)
               and ((CH.planned_communication_date between i_date_from and i_date_to)
               or (CH.planned_communication_date is null and CH.communication_date between i_date_from and i_date_to))
               and CH.communication_result_id is null
        
               -- территории
               and (district_ids = '{}'
               or district.id in (select unnest(district_ids)))
               -- ТЦСО
               and (organization_ids = '{}'
               or md.organization.id in (select unnest(organization_ids)))
      
             group by CH.id
      )
    
    select L1.participant_id                                                                          participant_id,
           L1.fio                                                                                     participant_full_name,
           L1.personal_phone_number                                                                   personal_phone_number,
           concat(md.coworker.second_name, ' ', md.coworker.first_name, ' ',
                  md.coworker.middle_name)                                                            responsible_person,
           org.short_title::text                                                                      responsible_person_organization_short_title,
           L1.organization_title                                                                      tcso_short_title,
           L1.neighbourhood_title                                                                     area,
           L1.district_title                                                                          distict,
           'NOT_IMPLEMENTED_YET'                                                                      tcso_full_title,
           L1.next_date::text                                                                         plan_communication_date,
           L1.group_id::text                                                                          group_code,
           L1.communication_result                                                                    communication_result,
           L1.communication_reason                                                                    communication_reason
    from L1
           left join md.groups on (L1.group_id = md.groups.id)
           left join md.coworker on (md.groups.coworker_id = md.coworker.id)
           left join md.organization org on (org.id = md.coworker.organization_id);
end;
$$;