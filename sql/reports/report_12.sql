drop function if exists public.report_12;
CREATE OR REPLACE FUNCTION public.report_12(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    participant_id     bigint,
    participant_fio    text,
    participant_phones text,
    org_short_title    text,
    org_full_title     text,
    neighbourhood      text,
    district           text,
    activity_l1_title  text,
    activity_l2_title  text,
    activity_l3_title  text,
    group_code         text,
    coordinator_fio    text,
    coworker_fio       text,
    scheduled_lessons  bigint,
    actual_lessons     bigint,
    skipped_lessons    bigint,
    attendance_rate    numeric,
    attendance_status  text
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L1 as (
        select distinct on (pt.id)
               pt.id,
               max(md.organization.id)                                                    org_id,
               array_to_string(array [pt.second_name, pt.first_name, pt.patronymic], ' ') fio,
               max(md.class_record.group_id)                                              group_id,
               array_to_string(array_agg(md.contact.value), '; ')                         phones,
               array_to_string(array_agg(district.title) over w1, '; ')                   district_title,
               max(neighbourhood.title)                                                   neighbourhood_title
        
        from md.participant pt
               -- регистр записи в группу
               left join md.class_record on (pt.id = md.class_record.participant_id)
               left join md.class_record_status_registry R1 on (md.class_record.id = R1.class_record_id)
            
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
            
            -- прочее
               left join md.contact on (pt.id = md.contact.owner_id)
        
        where
          -- статус записи в группу "lessons_started"
          R1.class_record_status_id = 6
          
          -- срез регистра
          and R1.start_date between i_date_from and i_date_to
          and (R1.end_date > i_date_from or R1.end_date is null)
          
          -- территории
          and (district_ids = '{}'
          or district.id in (select unnest(district_ids)))
          -- ТЦСО
          and (organization_ids = '{}'
          or md.organization.id in (select unnest(organization_ids)))
          
          -- контактная инфа
          and md.contact.contact_owner_type_id = 1 -- тип "Личное дело"
          and md.contact.contact_type_id = 1       -- телефон
        
        group by pt.id, district.title, R1.id, md.class_record.id
          window
            w1 as (partition by md.class_record.participant_id order by R1.id desc)
      ),
      
      --  кол-во посещений
      L2 as (
        select l.group_id,
               count(l.id)     scheduled_lessons,
               count(l.id)     actual_lessons, -- заменится на реальное значение
               -- (L2.scheduled_lessons/L2.actual_lessons*100)::numeric ,
               100::numeric as attendance_rate,
               string_agg(
                 distinct concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name), ', '
                 )          as teacher
        from md.lesson l
               join md.schedule_timesheet_coworkers stc on l.id = stc.lesson_id
               join md.coworker cw on stc.coworker_id = cw.id
        where l.lesson_date between i_date_from and i_date_to
          and l.group_id is not null
        
        group by l.group_id
      )
    
    select distinct on (L1.group_id, L1.id)
           L1.id                                                           participant_id,
           L1.fio                                                          participant_fio,
           L1.phones                                                       participant_phones,
           org.short_title::text                                           org_short_title,
           org.full_title::text                                            org_full_title,
           L1.neighbourhood_title                                          neighbourhood, --округ
           L1.district_title                                               district,--район
           a1.title::text                                                  activity_l1_title,
           a2.title::text                                                  activity_l2_title,
           a3.title::text                                                  activity_l3_title,
           L1.group_id::text                                               group_code,    -- здесь будет код группы
           concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name) coordinator_fio,
           L2.teacher,
           L2.scheduled_lessons,
           L2.actual_lessons,
           L2.scheduled_lessons - L2.actual_lessons                        skipped_lessons,
           L2.attendance_rate,
           attendance_status(L2.attendance_rate)
    
    from L1
           inner join L2 using (group_id)
        
        -- подтягиваем справочники
           left join md.organization org on (L1.org_id = org.id)
      
           left join md.groups gr on (L1.group_id = gr.id)
           left join md.coworker cw on (gr.coworker_id = cw.id)
        -- координаторов пока нет, будут позже
        -- left join md.coworker coords on (gr.coordinator_id = coords.id)
      
           left join reference.activity a3 on (gr.activity_id = a3.id)
           left join reference.activity a2 on (a3.parent_id = a2.id)
           left join reference.activity a1 on (a2.parent_id = a1.id)
    
    order by L1.group_id, participant_id
    limit limit_param offset offset_param;

end;
$$;