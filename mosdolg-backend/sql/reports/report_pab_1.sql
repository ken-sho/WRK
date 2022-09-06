drop function if exists public.report_pab_1;
CREATE OR REPLACE FUNCTION public.report_pab_1(i_date_to date default CURRENT_DATE)
  returns TABLE (
    groups_total                     numeric,
    groups_started                   numeric,
    groups_started_full              numeric,
    groups_started_0_50              numeric,
    groups_started_51_80             numeric,
    groups_started_81_99             numeric,
    groups_continued                 numeric,
    groups_without_people            numeric,
    groups_on_pause                  numeric,
    groups_finished                  numeric,
    group_places_total               numeric,
    group_places_vacant              numeric,
    group_places_occupied            numeric,
    participants_unique              numeric,
    participants_total               numeric,
    participants_started             numeric,
    participants_awaiting            numeric,
    participants_awaiting_formed     numeric,
    participants_awaiting_other      numeric,
    participants_created             numeric,
    participants_created_1_activity  numeric,
    participants_created_1_profile   numeric,
    participants_created_0_activity  numeric,
    participants_created_on_pause    numeric,
    participants_rejected            numeric,
    participants_rejected_1          numeric,
    participants_rejected_2          numeric,
    participants_rejected_3          numeric,
    participants_rejected_4          numeric,
    participants_rejected_5          numeric,
    participants_rejected_6          numeric,
    participants_rejected_7          numeric,
    participants_prohibited          numeric,
    participants_prohibited_1        numeric,
    participants_prohibited_2        numeric,
    participants_prohibited_3        numeric,
    participants_in_group            numeric,
    participants_in_group_1_activity numeric,
    participants_in_group_2_activity numeric,
    participants_in_group_3_activity numeric,
    participants_out                 numeric,
    participants_out_rejected        numeric,
    participants_out_rejected_1      numeric,
    participants_out_rejected_2      numeric,
    participants_out_rejected_3      numeric,
    participants_out_rejected_4      numeric,
    participants_out_rejected_5      numeric,
    participants_out_rejected_6      numeric,
    participants_out_rejected_7      numeric,
    participants_out_outgroup        numeric,
    participants_out_outgroup_1      numeric,
    participants_out_outgroup_2      numeric,
    participants_out_outgroup_3      numeric,
    participants_out_outgroup_4      numeric,
    participants_out_outgroup_5      numeric,
    participants_out_outgroup_6      numeric,
    participants_out_outgroup_7      numeric,
    participants_out_outgroup_8      numeric,
    participants_out_outgroup_9      numeric,
    participants_out_outgroup_10     numeric,
    participants_all_gender          numeric,
    participants_men                 numeric,
    participants_women               numeric,
    participants_age_1               numeric,
    participants_age_2               numeric,
    participants_age_3               numeric,
    participants_age_4               numeric,
    participants_age_5               numeric,
    participants_age_6               numeric,
    participants_age_7               numeric
  )
  language plpgsql
as $$
begin
  
  return query
    with
      REG_groups as ( -- последний статус группы
        select distinct on (group_id)
               group_id,
               first_value(status_id) over (partition by group_id order by id desc) as last_status
        from md.group_status_registry
        where is_expectation = false
          and i_date_to >= start_date
          and (i_date_to <= end_date or end_date is null)
      ),
      REG_cr as ( -- последний статус записи в группу
        select distinct on (class_record_id)
               class_record_id,
               first_value(class_record_status_id) over (partition by class_record_id order by id desc) as last_status
        from md.class_record_status_registry
        where i_date_to >= start_date
          and (i_date_to <= end_date or end_date is null)
      ),
      L0 as ( -- только группы, не входящие в направления ЦСО
        select *
        from md.groups
        where activity_id not in (
          select a3.id activity_id
          from reference.activity a3
                 left join reference.activity a2 on (a3.parent_id = a2.id)
                 left join reference.activity a1 on (a2.parent_id = a1.id)
          where a1.title = 'Кружки ЦСО'
             or a1.title = 'Мероприятия ЦСО'
        )
      ),
      L1 as ( -- вспомогательная выборка для групп
        select last_status as status_id, count(g.id) as gr_count
        from L0 g
               left join REG_groups gsr on g.id = gsr.group_id
        where last_status != 1
              -- and g.public_date is not null
        group by last_status
      ),
      G1 as ( -- общее кол-во групп
        select sum(gr_count) as groups_total
        from L1
      ),
      G2 as ( -- приступили к занятиям
        select sum(gr_count) as groups_started
        from L1
        where status_id = 8
      ),
      G3 as ( -- каникулы (на паузе)
        select sum(gr_count) as groups_on_pause
        from L1
        where status_id = 9
      ),
      G4 as (
        select sum(gr_count) as groups_finished
        from L1
        where status_id = 13
      ),
      
      G5 as (
        select count(g.id)::numeric as groups_continued
        from L0 g
               join md.group_status_registry gsr on g.id = gsr.group_id
        where gsr.is_expectation = false
          and i_date_to >= gsr.start_date -- todo from REG_groups
          and (i_date_to <= gsr.end_date or gsr.end_date is null)
          and (
            (gsr.status_id in (3, 4, 6, 7, 8, 9, 11, 12) and g.extend = true)
            or (gsr.status_id in (3, 4, 6, 7) and g.extend = false)
          )
        -- and g.public_date is not null
      ),
      
      G6_0 as ( -- все группы в активных статусах
        select count(distinct g.id) as gr_count
        from L0 g
               left join REG_groups gsr on g.id = gsr.group_id
        where gsr.last_status != 1
      ),
      G6_1 as ( -- все группы, у которых хотя бы один активный участник
        select count(distinct g.id) as gr_count
        from L0 g
               left join REG_groups gsr on g.id = gsr.group_id
               left join md.class_record cr using (group_id)
               left join REG_cr on cr.id = REG_cr.class_record_id
        where gsr.last_status in (3, 4, 6, 7, 8, 9, 11, 12)
          and REG_cr.last_status in (1, 3, 6, 7)
      ),
      G6 as (
        select (G6_0.gr_count - G6_1.gr_count)::numeric as groups_without_people
        from G6_0,
             G6_1
      ),
      
      L2 as ( -- вспомогательная выборка для количества участников в группах
        select g.id as group_id, coalesce(participants_number, 0) as participants_number
        from L0 g
               join REG_groups gsr on g.id = gsr.group_id
               left join (
            select group_id, count(*) as participants_number
            from REG_groups gsr
                   left join md.class_record cr using (group_id)
                   left join REG_cr on cr.id = REG_cr.class_record_id
            where gsr.last_status = 8
              and REG_cr.last_status in (1, 3, 6, 7)
            group by gsr.group_id
          ) as P0 on (g.id = P0.group_id)
        where gsr.last_status = 8
        -- and g.public_date is not null
      ),
      G7 as (
        select count(g.id)::numeric as groups_started_full
        from md.groups g
               join L2 on g.id = L2.group_id
        where L2.participants_number >= g.max_count
      ),
      G8 as (
        select count(g.id)::numeric as groups_started_0_50
        from md.groups g
               join L2 on g.id = L2.group_id
        where (L2.participants_number::numeric / g.max_count::numeric) <= 0.5
      ),
      G9 as (
        select count(g.id)::numeric as groups_started_51_80
        from md.groups g
               join L2 on g.id = L2.group_id
        where (L2.participants_number::numeric / g.max_count::numeric) > 0.5
          and (L2.participants_number::numeric / g.max_count::numeric) <= 0.8
      ),
      G10 as (
        select count(g.id)::numeric as groups_started_81_99
        from md.groups g
               join L2 on g.id = L2.group_id
        where (L2.participants_number::numeric / g.max_count::numeric) > 0.8
          and (L2.participants_number::numeric / g.max_count::numeric) < 1
      ),
      
      -- group places
      GP1 as (
        select sum(g.max_count)::numeric as total_group_places
        from L0 g
               join REG_groups gsr on g.id = gsr.group_id
        where gsr.last_status in (3, 4, 6, 7)
           or (gsr.last_status in (8, 9, 11, 12) and g.extend != false)
      ),
      GP2 as (
        select count(1)::numeric as occupied_group_places
        from md.class_record cr
               join REG_cr crsr on cr.id = crsr.class_record_id
        where crsr.last_status in (1, 3, 6, 7)
      ),
      GP3 as (
        select total_group_places - occupied_group_places as group_places_vacant
        from GP1,
             GP2
      ),
      
      L3 as ( -- вспомогательная выборка для участников
        select count(p.id) as p_count, psl.status_id, psl.reason_id
        from md.participant p
               join reference.participant_status_log psl on p.id = psl.participant_id
        where i_date_to >= psl.start_date
          and (i_date_to <= psl.end_date or psl.end_date is null)
          and psl.status_id in (1, 2, 3, 4, 5, 6, 7, 8)
        group by psl.status_id, psl.reason_id
      ),
      P0 as (
        select sum(p_count) as participants_unique
        from L3
      ),
      P1 as (
        select sum(p_count) as participants_total from L3 where status_id in (2, 3, 4, 5, 6, 7)
      ),
      P2 as (
        select sum(p_count) as participants_started
        from L3
        where status_id = 7
      ),
      P3 as (
        select sum(p_count) as awaiting_participants
        from L3
        where status_id = 6
      ),
      P3_1 as (
        select count(p.id)::numeric as awaiting_participants_formed
        from md.participant p
               join reference.participant_status_log psl on p.id = psl.participant_id
               join md.class_record cl on p.id = cl.participant_id
               join md.class_record_status_registry crsr on cl.id = crsr.class_record_id
        where i_date_to >= psl.start_date
          and (i_date_to <= psl.end_date or psl.end_date is null)
          and i_date_to >= cl.date_from
          and (i_date_to <= cl.date_to or cl.date_to is null)
          and psl.status_id = 6
          and crsr.class_record_status_id = 3
      ),
      P3_2 as (
        select awaiting_participants - awaiting_participants_formed as participants_awaiting_other
        from P3,
             P3_1
      ),
      P4 as (
        select sum(p_count) as participants_created from L3 where status_id in (2, 3, 4, 5)
      ),
      P4_1 as (
        select sum(p_count) as participants_created_1_activity from L3 where status_id = 2
      ),
      P4_2 as (
        select sum(p_count) as participants_created_1_profile from L3 where status_id = 3
      ),
      P4_3 as (
        select sum(p_count) as participants_created_0_activity from L3 where status_id = 4
      ),
      P4_4 as (
        select sum(p_count) as participants_created_on_pause from L3 where status_id = 5
      ),
      
      -- Участники отчисленные (отказавшиеся от участия в проекте)
      P5 as (
        select sum(p_count) as participants_rejected
        from L3
        where status_id = 8
      ),
      P5_1 as (
        select sum(p_count) as participants_rejected_1 from L3 where status_id = 8 and reason_id = 17
      ),
      P5_2 as (
        select sum(p_count) as participants_rejected_2 from L3 where status_id = 8 and reason_id = 18
      ),
      P5_3 as (
        select sum(p_count) as participants_rejected_3 from L3 where status_id = 8 and reason_id = 19
      ),
      P5_4 as (
        select sum(p_count) as participants_rejected_4 from L3 where status_id = 8 and reason_id = 20
      ),
      P5_5 as (
        select sum(p_count) as participants_rejected_5 from L3 where status_id = 8 and reason_id = 21
      ),
      P5_6 as (
        select sum(p_count) as participants_rejected_6 from L3 where status_id = 8 and reason_id = 22
      ),
      P5_7 as (
        select sum(p_count) as participants_rejected_7 from L3 where status_id = 8 and reason_id = 23
      ),
      
      P6 as (
        select sum(p_count) as participants_prohibited from L3 where status_id = 1
      ),
      P6_1 as (
        select sum(p_count) as participants_prohibited_1 from L3 where status_id = 1 and reason_id in (1, 2)
      ),
      P6_2 as (
        select sum(p_count) as participants_prohibited_2 from L3 where status_id = 1 and reason_id = 3
      ),
      P6_3 as (
        select sum(p_count) as participants_prohibited_3 from L3 where status_id = 1 and reason_id = 4
      ),
      
      P7 as (
        select sum(p_count) as participants_in_group from L3 where status_id in (6, 7)
      ),
      L4 as ( -- вспомогательный запрос для подсчета активностей
        select p.id as participant_id, count(pap.id) as activity_count
        from md.participant p
               join md.participant_activity_profile pap on p.id = pap.participant_id
               join reference.participant_status_log psl on p.id = psl.participant_id
        where i_date_to >= psl.start_date
          and (i_date_to <= psl.end_date or psl.end_date is null)
          and psl.status_id in (6, 7)
        group by p.id
      ),
      P7_1 as (
        select count(participant_id)::numeric as participants_in_group_1_activity from L4 where activity_count = 1
      ),
      P7_2 as (
        select count(participant_id)::numeric as participants_in_group_2_activity from L4 where activity_count = 2
      ),
      P7_3 as (
        select count(participant_id)::numeric as participants_in_group_3_activity from L4 where activity_count >= 3
      ),
      
      -- отток участников
      P8 as (
        select sum(p_count) as participants_out from L3 where status_id in (1, 8)
      ),
      L5 as ( -- вспомогательный запрос для учета оттока тех, у кого не было записи в группу
        select count(p.id) as p_count, psl.status_id, psl.reason_id
        from md.participant p
               join reference.participant_status_log psl on p.id = psl.participant_id
               join md.class_record cr on p.id = cr.participant_id
        where i_date_to >= psl.start_date
          and (i_date_to <= psl.end_date or psl.end_date is null)
          and psl.status_id = 8
          and cr.id is null
        group by psl.status_id, psl.reason_id
      ),
      P8_0 as (
        select sum(p_count) as participants_out_ingroup
        from L5
      ),
      P8_1 as (
        select sum(p_count) as participants_out_ingroup_1 from L5 where reason_id = 17
      ),
      P8_2 as (
        select sum(p_count) as participants_out_ingroup_2 from L5 where reason_id = 18
      ),
      P8_3 as (
        select sum(p_count) as participants_out_ingroup_3 from L5 where reason_id = 19
      ),
      P8_4 as (
        select sum(p_count) as participants_out_ingroup_4 from L5 where reason_id = 20
      ),
      P8_5 as (
        select sum(p_count) as participants_out_ingroup_5 from L5 where reason_id = 21
      ),
      P8_6 as (
        select sum(p_count) as participants_out_ingroup_6 from L5 where reason_id = 22
      ),
      P8_7 as (
        select sum(p_count) as participants_out_ingroup_7 from L5 where reason_id = 23
      ),
      
      L6_0 as ( -- еще один вспомогательный запрос - для последних статусов class_record
        select distinct on (crsr.class_record_id)
               crsr.class_record_id,
               first_value(crsr.reason)
               over (partition by crsr.class_record_id order by crsr.start_date desc) as last_reason
        from md.participant p
               join reference.participant_status_log psl on p.id = psl.participant_id
               join md.class_record cr on p.id = cr.participant_id
               join md.class_record_status_registry crsr on crsr.class_record_id = cr.id
        where i_date_to >= psl.start_date
          and (i_date_to <= psl.end_date or psl.end_date is null)
          and reason is not null
      ),
      
      L6 as ( -- вспомогательный запрос для учета оттока тех, у кого была хотя бы одна запись в группу
        select count(distinct p.id) as p_count, L6_0.last_reason as reason
        from md.participant p
               join reference.participant_status_log psl on p.id = psl.participant_id
               join md.class_record cr on p.id = cr.participant_id
               join L6_0 on L6_0.class_record_id = cr.id
        where i_date_to >= psl.start_date
          and (i_date_to <= psl.end_date or psl.end_date is null)
          and psl.status_id = 8
          and cr.id is not null
        group by L6_0.last_reason
      ),
      
      P9_0 as (
        select sum(p_count) as participants_out_outgroup
        from L6
      ),
      P9_1 as (
        select sum(p_count) as participants_out_outgroup_1 from L6 where reason = 19 or reason = 11
      ),
      P9_2 as (
        select sum(p_count) as participants_out_outgroup_2 from L6 where reason = 20
      ),
      P9_3 as (
        select sum(p_count) as participants_out_outgroup_3 from L6 where reason = 21 or reason = 12
      ),
      P9_4 as (
        select sum(p_count) as participants_out_outgroup_4 from L6 where reason = 22 or reason = 13
      ),
      P9_5 as (
        select sum(p_count) as participants_out_outgroup_5 from L6 where reason = 23
      ),
      P9_6 as (
        select sum(p_count) as participants_out_outgroup_6 from L6 where reason = 24
      ),
      P9_7 as (
        select sum(p_count) as participants_out_outgroup_7 from L6 where reason = 25 or reason = 14
      ),
      P9_8 as (
        select sum(p_count) as participants_out_outgroup_8 from L6 where reason = 26 or reason = 16
      ),
      P9_9 as (
        select sum(p_count) as participants_out_outgroup_9 from L6 where reason = 15
      ),
      P9_10 as (
        select sum(p_count) as participants_out_outgroup_10 from L6 where reason = 27 or reason = 18
      ),
      
      P10 as (
        select sum(p_count) as participants_all_gender
        from L3
      ),
      P10_1 as (
        select count(p.id)::numeric as participants_men
        from md.participant p
               join reference.participant_status_log psl on p.id = psl.participant_id
        where i_date_to >= psl.start_date
          and (i_date_to <= psl.end_date or psl.end_date is null)
          and psl.status_id in (1, 2, 3, 4, 5, 6, 7, 8)
          and p.gender = 1
      ),
      P10_2 as (
        select count(p.id)::numeric as participants_women
        from md.participant p
               join reference.participant_status_log psl on p.id = psl.participant_id
        where i_date_to >= psl.start_date
          and (i_date_to <= psl.end_date or psl.end_date is null)
          and psl.status_id in (1, 2, 3, 4, 5, 6, 7, 8)
          and p.gender = 2
      ),
      L7 as ( -- вспомогательная выборка для возраста
        select count(p.id) as p_count, p.date_of_birth as birth_date
        from md.participant p
               join reference.participant_status_log psl on p.id = psl.participant_id
        where i_date_to >= psl.start_date
          and (i_date_to <= psl.end_date or psl.end_date is null)
          and psl.status_id in (1, 2, 3, 4, 5, 6, 7, 8)
        group by birth_date
        order by birth_date
      ),
      P10_3 as (
        select sum(p_count) as participants_age_1
        from L7
        where extract(year from (age(i_date_to, birth_date))) < 55
      ),
      P10_4 as (
        select sum(p_count) as participants_age_2
        from L7
        where extract(year from (age(i_date_to, birth_date))) between 55 and 59
      ),
      P10_5 as (
        select sum(p_count) as participants_age_3
        from L7
        where extract(year from (age(i_date_to, birth_date))) between 60 and 64
      ),
      P10_6 as (
        select sum(p_count) as participants_age_4
        from L7
        where extract(year from (age(i_date_to, birth_date))) between 65 and 69
      ),
      P10_7 as (
        select sum(p_count) as participants_age_5
        from L7
        where extract(year from (age(i_date_to, birth_date))) between 70 and 74
      ),
      P10_8 as (
        select sum(p_count) as participants_age_6
        from L7
        where extract(year from (age(i_date_to, birth_date))) between 75 and 79
      ),
      P10_9 as (
        select sum(p_count) as participants_age_7
        from L7
        where extract(year from (age(i_date_to, birth_date))) >= 80
      )
      
      -- @formatter:off
select * from G1, G2, G7, G8, G9, G10, G5, G6, G3, G4,
              GP1, GP3, GP2,
							P0, P1, P2, P3, P3_1, P3_2,
              P4, P4_1, P4_2, P4_3, P4_4,
              P5, P5_1, P5_2, P5_3, P5_4, P5_5, P5_6, P5_7,
              P6, P6_1, P6_2, P6_3,
              P7, P7_1, P7_2, P7_3,
              P8, P8_0, P8_1, P8_2, P8_3, P8_4, P8_5, P8_6, P8_7,
              P9_0, P9_1, P9_2, P9_3, P9_4, P9_5, P9_6, P9_7, P9_8, P9_9, P9_10,
              P10, P10_1, P10_2, P10_3, P10_4, P10_5, P10_6, P10_7, P10_8, P10_9
;

END;
$$;