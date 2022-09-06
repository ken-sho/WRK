drop function if exists public.report_pab_1_1;
CREATE OR REPLACE FUNCTION public.report_pab_1_1()
  returns TABLE (
    groups_total                          numeric,
    groups_started                        numeric,
    groups_started_full                   numeric,
    groups_started_0_50                   numeric,
    groups_started_51_80                  numeric,
    groups_started_81_99                  numeric,
    groups_continued                      numeric,
    groups_without_people                 numeric,
    groups_on_pause                       numeric,
    groups_finished                       numeric,
    group_places_total                    numeric,
    group_places_vacant                   numeric,
    group_places_occupied                 numeric,
    participants_unique                   numeric,
    participants_total                    numeric,
    participants_started                  numeric,
    participants_on_pause                 numeric,
    participants_on_pause_only            numeric,
    participants_on_pause_enrolled        numeric,
    participants_on_pause_participated    numeric,
    participants_awaiting                 numeric,
    participants_awaiting_enrolled        numeric,
    participants_awaiting_participated    numeric,
    participants_choose_direction         numeric,
    participants_choose_direction_current numeric,
    participants_choose_direction_former  numeric,
    participants_created                  numeric,
    participants_created_current          numeric,
    participants_created_former           numeric,
    participants_out                      numeric,
    participants_rejected                 numeric,
    participants_rejected_1               numeric,
    participants_rejected_2               numeric,
    participants_rejected_3               numeric,
    participants_rejected_4               numeric,
    participants_rejected_5               numeric,
    participants_rejected_6               numeric,
    participants_rejected_7               numeric,
    participants_prohibited               numeric,
    participants_prohibited_1             numeric,
    participants_prohibited_2             numeric,
    participants_prohibited_3             numeric,
    participants_in_group                 numeric,
    participants_in_group_1_activity      numeric,
    participants_in_group_2_activity      numeric,
    participants_in_group_3_activity      numeric,
    participants_in_group_1_group         numeric,
    participants_in_group_2_group         numeric,
    participants_in_group_3_group         numeric,
    participants_all_gender               numeric,
    participants_men                      numeric,
    participants_women                    numeric,
    participants_age_1                    numeric,
    participants_age_2                    numeric,
    participants_age_3                    numeric,
    participants_age_4                    numeric,
    participants_age_5                    numeric,
    participants_age_6                    numeric,
    participants_age_7                    numeric
  )
  language plpgsql
as $$
begin
  
  return query
    with
      -- REG - последние записи из регистров
      -- L0-n - вспомогательные выборки
      -- R1-n - результирующие ряды, номер соответствует строке из запроса
      REG_groups as ( -- статус группы
        select distinct on (group_id)
               group_id,
               first_value(status_id) over (partition by group_id order by id desc) as last_status
        from md.group_status_registry
        where is_expectation = false
      ),
      REG_cr as ( -- статус записи в группу
        select distinct on (class_record_id)
               class_record_id,
               first_value(class_record_status_id) over (partition by class_record_id order by id desc) as last_status
        from md.class_record_status_registry
      ),
      REG_p as ( -- статус участника
        select distinct on (participant_id)
               participant_id,
               first_value(status_id) over (partition by participant_id order by id desc) as last_status,
               first_value(reason_id) over (partition by participant_id order by id desc) as last_reason
        from reference.participant_status_log
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
        group by last_status
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
      ),
      
      R1 as ( -- общее кол-во групп
        select sum(gr_count) as groups_total
        from L1
      ),
      R2 as ( -- приступили к занятиям
        select sum(gr_count) as groups_started
        from L1
        where status_id = 8
      ),
      R3 as (
        select count(g.id)::numeric as groups_started_full
        from md.groups g
               join L2 on g.id = L2.group_id
        where L2.participants_number >= g.max_count
      ),
      R4 as (
        select count(g.id)::numeric as groups_started_0_50
        from md.groups g
               join L2 on g.id = L2.group_id
        where (L2.participants_number::numeric / g.max_count::numeric) <= 0.5
      ),
      R5 as (
        select count(g.id)::numeric as groups_started_51_80
        from md.groups g
               join L2 on g.id = L2.group_id
        where (L2.participants_number::numeric / g.max_count::numeric) > 0.5
          and (L2.participants_number::numeric / g.max_count::numeric) <= 0.8
      ),
      R6 as (
        select count(g.id)::numeric as groups_started_81_99
        from md.groups g
               join L2 on g.id = L2.group_id
        where (L2.participants_number::numeric / g.max_count::numeric) > 0.8
          and (L2.participants_number::numeric / g.max_count::numeric) < 1
      ),
      R7 as (
        select count(g.id)::numeric as groups_continued
        from L0 g
               join REG_groups gsr on g.id = gsr.group_id
        where (gsr.last_status in (8, 9, 11, 12) and g.extend = true)
           or (gsr.last_status in (3, 4, 6, 7) and g.extend = false)
      ),
      
      active_groups as ( -- только группы в активных статусах
        select g.id group_id
        from L0 g
               left join REG_groups gsr on g.id = gsr.group_id
        where gsr.last_status in (3, 4, 6, 8, 11)
      ),
      
      -- R8 вспомогательные выборки
      -- R8 собираем из двух частей: в первой те группы, у которых нет записей в cr совсем.
      -- Во второй - те группы, у которых количество всех статусов равно количеству искомых (неактивных) статусов
      -- todo переделать по аналогии с R18
      R8_1 as ( -- группы для которых нет cr вообще
        select ag.group_id
        from active_groups ag
               left join md.class_record cr using (group_id)
        where cr.id is null
      ),
      
      R8_2_required_statuses as ( -- группы с количеством требуемых статусов
        select ag.group_id, count(crsr.class_record_id) num_of_statuses
        from active_groups ag
               join md.class_record cr using (group_id)
               join REG_cr crsr on cr.id = crsr.class_record_id
        where crsr.last_status in (2, 4, 5, 9)
        group by group_id
      ),
      
      R8_2_all_statuses as (
        select ag.group_id, count(crsr.class_record_id) num_of_statuses
        from active_groups ag
               join md.class_record cr using (group_id)
               join REG_cr crsr on cr.id = crsr.class_record_id
        group by group_id
      ),
      
      R8_2 as (
        select group_id
        from R8_2_required_statuses s_all
               join R8_2_all_statuses s_req using (group_id)
        where s_all.num_of_statuses - s_req.num_of_statuses = 0
      ),
      
      R8 as ( -- группы без активных участников
        select count(distinct R8_1.group_id)::numeric
                 + count(distinct R8_2.group_id)::numeric as groups_without_people
        from R8_1,
             R8_2
      ),
      
      R9 as (
        select sum(gr_count) as groups_on_pause
        from L1
        where status_id = 9
      ),
      R10 as (
        select sum(gr_count) as groups_finished
        from L1
        where status_id = 13
      ),
      
      -- group places
      R11 as ( -- total active
        select sum(g.max_count)::numeric as group_places_total
        from L0 g
               join REG_groups gsr on g.id = gsr.group_id
        where gsr.last_status not in (1, 2, 5, 10, 13)
      ),
      
      R12 as (
        select sum(case when t.group_places_vacant < 0 then 0 else t.group_places_vacant end) as group_places_vacant
        from (
               select g.id,
                      g.max_count -
                      sum(case
                            when gsr.last_status in (3, 4, 6, 7) then 1
                            when g.extend = true and gsr.last_status in (8, 9, 11, 12) then 1
                            else 0 end)::numeric as group_places_vacant
               from L0 g
                      join REG_groups gsr on g.id = gsr.group_id
                      join md.class_record cr on g.id = cr.group_id
                      join REG_cr crsr on cr.id = crsr.class_record_id
               where gsr.last_status in (3, 4, 6, 7, 8, 9, 11, 12)
                 and crsr.last_status in (1, 2, 3, 6, 7)
               group by g.id, g.max_count
             ) t
      ),
      
      R13 as (
        select count(1)::numeric as group_places_occupied
        from md.class_record cr
               join REG_cr crsr on cr.id = crsr.class_record_id
        where crsr.last_status in (1, 2, 3, 6, 7)
      ),
      
      -- Participants
      L3 as ( -- вспомогательная выборка для участников
        select count(p.id) as p_count, psl.last_status, psl.last_reason
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
        group by psl.last_status, psl.last_reason
      ),
      
      R14 as (
        select sum(p_count) as participants_unique
        from L3
      ),
      
      R15 as (
        select sum(p_count) as participants_total from L3 where last_status not in (1, 2, 8)
      ),
      
      R16 as (
        select sum(p_count) as participants_started
        from L3
        where last_status = 7
      ),
      
      R17 as (
        select sum(p_count) as participants_on_pause
        from L3
        where last_status = 5
      ),
      
      paused_partcipants as ( -- только участники на паузе
        select distinct
               p.id                                 participant_id,
               array_agg(distinct crsr.last_status) statuses
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
               join md.class_record cr using (participant_id)
               join REG_cr crsr on cr.id = crsr.class_record_id
        where psl.last_status = 5
        group by p.id
      ),
      
      R18 as (
        select count(*)::numeric as participants_on_pause_only
        from paused_partcipants
        where 1 != all (statuses)
          and 3 != all (statuses)
      ),
      
      R19 as (
        select count(*)::numeric as participants_on_pause_enrolled
        from paused_partcipants
        where 3 = any (statuses)
      ),
      
      R20 as (
        select count(*)::numeric as participants_on_pause_participated
        from paused_partcipants
        where 1 = any (statuses)
          and 3 != all (statuses)
      ),
      
      awaiting_partcipants as ( -- участники на подборе
        select distinct
               p.id                                 participant_id,
               array_agg(distinct crsr.last_status) statuses
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
               join md.class_record cr using (participant_id)
               join REG_cr crsr on cr.id = crsr.class_record_id
        where psl.last_status = 6
        group by p.id
      ),
      
      R21 as (
        select sum(p_count) as participants_awaiting
        from L3
        where last_status = 6
      ),
      
      R22 as (
        select count(*)::numeric as participants_awaiting_enrolled
        from awaiting_partcipants
        where 3 = any (statuses)
      ),
      
      R23 as (
        select count(*)::numeric as participants_awaiting_participated
        from awaiting_partcipants
        where 1 = any (statuses)
          and 3 != all (statuses)
      ),
      
      choose_direction_partcipants as (
        select distinct
               p.id                                              as participant_id,
               array_agg(distinct coalesce(crsr.last_status, 0)) as statuses
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
               left join md.class_record cr using (participant_id)
               left join REG_cr crsr on cr.id = crsr.class_record_id
        where psl.last_status = 4
        group by p.id
      ),
      
      R24 as (
        select sum(p_count) as participants_choose_direction
        from L3
        where last_status = 4
      ),
      
      R25 as (
        select count(*)::numeric as participants_choose_direction_current
        from choose_direction_partcipants
        where 4 != all (statuses)
          and 5 != all (statuses)
      ),
      
      R26 as (
        select count(*)::numeric as participants_choose_direction_former
        from choose_direction_partcipants
        where 4 = any (statuses)
           or 5 = any (statuses)
      ),
      
      R27 as (
        select sum(p_count) as participants_created
        from L3
        where last_status = 3
      ),
      
      created_partcipants as (
        select distinct
               p.id                                              as participant_id,
               array_agg(distinct coalesce(crsr.last_status, 0)) as statuses
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
               left join md.class_record cr using (participant_id)
               left join REG_cr crsr on cr.id = crsr.class_record_id
        where psl.last_status = 3
        group by p.id
      ),
      
      R28 as (
        select count(*)::numeric as participants_created_current
        from created_partcipants
        where 4 != all (statuses)
          and 5 != all (statuses)
      ),
      
      R29 as (
        select count(*)::numeric as participants_created_former
        from created_partcipants
        where 4 = any (statuses)
           or 5 = any (statuses)
      ),
      
      R30 as (
        select sum(p_count) as participants_out
        from L3
        where last_status in (1, 8)
      ),
      
      R31 as (
        select sum(p_count) as participants_rejected
        from L3
        where last_status = 8
      ),
      R32 as (
        select sum(p_count) as participants_rejected_1 from L3 where last_status = 8 and last_reason = 17
      ),
      R33 as (
        select sum(p_count) as participants_rejected_2 from L3 where last_status = 8 and last_reason = 18
      ),
      R34 as (
        select sum(p_count) as participants_rejected_3 from L3 where last_status = 8 and last_reason = 19
      ),
      R35 as (
        select sum(p_count) as participants_rejected_4 from L3 where last_status = 8 and last_reason = 20
      ),
      R36 as (
        select sum(p_count) as participants_rejected_5 from L3 where last_status = 8 and last_reason = 21
      ),
      R37 as (
        select sum(p_count) as participants_rejected_6 from L3 where last_status = 8 and last_reason = 22
      ),
      R38 as (
        select sum(p_count) as participants_rejected_7 from L3 where last_status = 8 and last_reason = 23
      ),
      
      R39 as (
        select sum(p_count) as participants_prohibited from L3 where last_status = 1
      ),
      R40 as (
        select sum(p_count) as participants_prohibited_1 from L3 where last_status = 1 and last_reason in (1, 2)
      ),
      R41 as (
        select sum(p_count) as participants_prohibited_2 from L3 where last_status = 1 and last_reason = 3
      ),
      R42 as (
        select sum(p_count) as participants_prohibited_3 from L3 where last_status = 1 and last_reason = 4
      ),
      
      R43 as (
        select sum(p_count) as participants_in_group from L3 where last_status in (5, 6, 7)
      ),
      
      L4 as ( -- вспомогательный запрос для подсчета активностей
        select p.id as participant_id, count(pap.id) as activity_count
        from md.participant p
               join md.participant_activity_profile pap on p.id = pap.participant_id
               join REG_p psl on p.id = psl.participant_id
        where psl.last_status in (5, 6, 7)
        group by p.id
      ),
      
      R44 as (
        select count(participant_id)::numeric as participants_in_group_1_activity from L4 where activity_count = 1
      ),
      R45 as (
        select count(participant_id)::numeric as participants_in_group_2_activity from L4 where activity_count = 2
      ),
      R46 as (
        select count(participant_id)::numeric as participants_in_group_3_activity from L4 where activity_count >= 3
      ),
      
      L4_1 as ( -- вспомогательный запрос для подсчета активных записей в группу
        select p.id as participant_id, count(cr.id) as class_record_count
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
               join md.class_record cr on p.id = cr.participant_id
               join REG_cr crsr on cr.id = crsr.class_record_id
        where psl.last_status in (5, 6, 7)
          and crsr.last_status in (1, 2, 3, 6, 7)
        group by p.id
      ),
      
      R47 as (
        select count(participant_id)::numeric as participants_in_group_1_group from L4_1 where class_record_count = 1
      ),
      R48 as (
        select count(participant_id)::numeric as participants_in_group_2_group from L4_1 where class_record_count = 2
      ),
      R49 as (
        select count(participant_id)::numeric as participants_in_group_3_group from L4_1 where class_record_count >= 3
      ),
      
      R50 as (
        select count(p.id)::numeric as participants_all_gender
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
        where psl.last_status not in (1, 2, 8)
      ),
      R51 as (
        select count(p.id)::numeric as participants_men
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
        where psl.last_status not in (1, 2, 8)
          and p.gender = 1
      ),
      R52 as (
        select count(p.id)::numeric as participants_women
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
        where psl.last_status not in (1, 2, 8)
          and p.gender = 2
      ),
      
      L7 as ( -- вспомогательная выборка для возраста
        select count(p.id) as p_count, p.date_of_birth as birth_date
        from md.participant p
               join REG_p psl on p.id = psl.participant_id
        where psl.last_status not in (1, 2, 8)
        group by birth_date
        order by birth_date
      ),
      
      R53 as (
        select sum(p_count) as participants_age_1
        from L7
        where extract(year from (age(current_date, birth_date))) < 55
      ),
      R54 as (
        select sum(p_count) as participants_age_2
        from L7
        where extract(year from (age(current_date, birth_date))) between 55 and 59
      ),
      R55 as (
        select sum(p_count) as participants_age_3
        from L7
        where extract(year from (age(current_date, birth_date))) between 60 and 64
      ),
      R56 as (
        select sum(p_count) as participants_age_4
        from L7
        where extract(year from (age(current_date, birth_date))) between 65 and 69
      ),
      R57 as (
        select sum(p_count) as participants_age_5
        from L7
        where extract(year from (age(current_date, birth_date))) between 70 and 74
      ),
      R58 as (
        select sum(p_count) as participants_age_6
        from L7
        where extract(year from (age(current_date, birth_date))) between 75 and 79
      ),
      R59 as (
        select sum(p_count) as participants_age_7
        from L7
        where extract(year from (age(current_date, birth_date))) >= 80
      )
      
      -- @formatter:off
select * from R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, -- groups
              R11, R12, R13,  -- group places
							R14, R15, R16, R17, R18, R19, R20, R21, R22, R23, R24, R25, R26, R27,
							R28, R29, R30, R31, R32, R33, R34, R35, R36, R37, R38, R39, R40, R41,
							R42, R43, R44, R45, R46, R47, R48, R49,
							
							R50, R51, R52, R53, R54, R55, R56, R57, R58, R59
;

END;
$$;