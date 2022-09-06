drop function if exists public.report_5;
CREATE OR REPLACE FUNCTION public.report_5(
  i_date_from  date default current_date, i_date_to date default current_date,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    rec_id                                 bigint,
    neighbourhood                          text,
    district                               text,
    tcso                                   text,
    org_full_title                         text,
    org_short_title                        text,
    activity_l1_title                      text,
    activity_l2_title                      text,
    activity_l3_title                      text,
    group_code                             text,
    status_title                           text,
    reason_title                           text,
    plan_start_date                        date,
    plan_end_date                          date,
    fact_start_date                        date,
    fact_end_date                          date,
    lessons_pause_date                     date,
    lessons_resume_date                    date,
    planned_number_classes                 bigint,
    actual_number_classes                  bigint,
    number_recorded_participant_for_period bigint,
    total_dismissed                        bigint,
    total_relocated                        bigint,
    total_finished                         bigint,
    coworker_fio                           text,
    contraindications                      text,
    dress_code                             text,
    inventory_requirements                 text,
    need_note                              boolean
  )
  language plpgsql
as $$
begin
  
  return query
    
    -- группы с актуальным статусом на момент выборки
    with
      L1 as (
        select distinct on (group_id, status_id)
               md.groups.id                             group_id,
               md.groups.group_code                     group_code,
               first_value(R1.status_id) over w1        status_id,
               first_value(R1.reason_id) over w1        reason_id,
               first_value(R1.start_date::date) over w1 status_start_date,
               max(neighbourhood.title)                 neighbourhood_title,
               max(tcso.short_title)                    tcso_short_title,
               district.title::text                     district_title
        
        from md.groups
               -- R1, регистр групп
               left join md.group_status_registry R1 on (md.groups.id = group_id)
            -- территории
               left join reference.department on (reference.department.key = 'D_SOZ')
               left join md.organization tcso on (md.groups.territory_centre_id = tcso.id
            and tcso.department_id = reference.department.id)
               left join md.territory_organization on (md.territory_organization.organization_id = tcso.id)
               left join ar.territory district
                         on (district.parent_id is not null and (district.id = md.territory_organization.territory_id
                           or district.parent_id = md.territory_organization.territory_id))
               left join ar.territory neighbourhood
                         on (neighbourhood.parent_id is null and neighbourhood.id = district.parent_id)
        
        where R1.status_id in (2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)
          
          -- срез регистра
          and R1.start_date between i_date_from and i_date_to
          and (R1.end_date > i_date_to or R1.end_date is null)
          -- территории
          and (district_ids = '{}'
          or district.id in (select unnest(district_ids)))
          -- ТЦСО
          and (organization_ids = '{}'
          or tcso.id in (select unnest(organization_ids)))
        group by md.groups.id, R1.status_id, district.title, R1.id
          window
            w1 as (partition by group_id order by R1.id desc)
        order by group_id
      ),
      
      L2 as (
        select distinct on (group_id, participant_id)
               md.class_record.group_id                       group_id,
               md.class_record.participant_id,
               array_agg(R1.class_record_status_id) over w1   all_statuses,
               first_value(R1.class_record_status_id) over w2 status_id,
               first_value(R1.reason) over w2                 reason_id
        
        from md.class_record
               -- R1, регистр статусов участия
               left join md.class_record_status_registry R1 on (md.class_record.id = class_record_id)
        
        where
          -- срез регистра
          R1.start_date between i_date_from and i_date_to
          and (R1.end_date > i_date_from or R1.end_date is null)
          window
            w1 as (partition by R1.class_record_id),
            w2 as (partition by R1.class_record_id order by R1.id desc)
        
        order by group_id, participant_id
      ),
      
      -- здесь все справочники которые мапятся как многие-ко-многим по group_id
      -- по-хорошему это вообще в materialized view вынести можно
      L3 as (
        select group_id,
               array_to_string(array_agg(distinct c1.title), '; ') contraindications,
               array_to_string(array_agg(distinct c2.title), '; ') dress_code,
               array_to_string(array_agg(distinct c3.title), '; ') inventory_requirements
        
        from (select distinct group_id from md.class_record) G1
               left join md.group_contraindication rel1 using (group_id)
               left join reference.contraindication c1 on (rel1.contraindication_id = c1.id)
          
               left join md.group_dress_code rel2 using (group_id)
               left join reference.dress_code c2 on (rel2.dress_code_id = c2.id)
          
               left join md.group_inventory_requirement rel3 using (group_id)
               left join reference.inventory_requirement c3 on (rel3.inventory_requirement_id = c3.id)
        
        group by group_id
      ),
      
      L4 as (
        select group_id,
               count(schedule.id) planned_number_classes
        
        from md.schedule schedule
        
        where schedule.start_date >= i_date_from
          and schedule.end_date <= i_date_to
          and group_id is not null
        
        group by group_id
      ),
      
      L5 as (
        select group_id,
               count(md.lesson.id) actual_number_classes
        
        from md.lesson
        
        where md.lesson.lesson_date between i_date_from and i_date_to
          and md.lesson.attendance_data = true
          and group_id is not null
        
        group by group_id
      )
    
    select distinct on (group_id)
           row_number() over ()                                                                       rec_id,
           L1.neighbourhood_title                                                                     neighbourhood,
           L1.district_title                                                                          district,
           L1.tcso_short_title                                                                        tcso,
           org.full_title::text                                                                       org_full_title,
           org.short_title::text                                                                      org_short_title,
           a1.title::text                                                                             activity_l1_title,
           a2.title::text                                                                             activity_l2_title,
           a3.title::text                                                                             activity_l3_title,
           L1.group_code, -- здесь будет код группы когда появится
           status.title::text                                                                         status_title,
           reason.title::text                                                                         reason_title,
           gr.plan_start_date,
           gr.plan_end_date,
           gr.fact_start_date,
           gr.fact_end_date,
           case L1.status_id when 9 then L1.status_start_date else null end                           lessons_pause_date,
           case L1.status_id when 11 then L1.status_start_date else null end                          lessons_resume_date,
           L4.planned_number_classes,
           L5.actual_number_classes,
           -- Состав участников
           sum(case 3 = any (L2.all_statuses) when true then 1 else 0 end) over w1                    number_recorded_participant_for_period,
           sum(
           case L2.status_id = 5 and L2.reason_id != any ('{22,23}'::int[])
             when true then 1
             else 0 end
             ) over w1                                                                                total_dismissed,
           sum(
           case L2.status_id = 5 and L2.reason_id = any ('{22,23}'::int[])
             when true then 1
             else 0 end
             ) over w1                                                                                total_relocated,
           sum(case L2.status_id = 8 when true then 1 else 0 end) over w1                             total_finished,
    
           -- прочий стафф
           concat(md.coworker.second_name, ' ', md.coworker.first_name, ' ', md.coworker.middle_name) coworker_fio,
           L3.contraindications,
           L3.dress_code,
           L3.inventory_requirements,
           gr.need_note
    
    from L1
           inner join L2 using (group_id)
           left join L3 using (group_id)
           left join L4 using (group_id)
           left join L5 using (group_id)
        -- подтягиваем остальные справочники
           left join md.groups gr on (L1.group_id = gr.id)
           left join md.organization org on (gr.organization_id = org.id)
           left join md.coworker on (gr.coworker_id = md.coworker.id)
           left join reference.activity a3 on (gr.activity_id = a3.id)
           left join reference.activity a2 on (a3.parent_id = a2.id)
           left join reference.activity a1 on (a2.parent_id = a1.id)
      
           left join reference.group_status status on (L1.status_id = status.id)
           left join reference.group_status_reason reason on (L1.reason_id = reason.id)
      window
        w1 as (partition by L1.group_id)
    limit limit_param offset offset_param;

end;
$$;
