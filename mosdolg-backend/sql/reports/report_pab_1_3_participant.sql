drop function if exists public.report_pab_1_3_participant;
CREATE OR REPLACE FUNCTION public.report_pab_1_3_participant(participant_name text)
  returns TABLE (
    esz_aid           bigint,
    esz_lastname      character varying,
    esz_name          character varying,
    esz_patronymic    character varying,
    esz_fio           text,
    esz_birth_date    date,
    esz_priority      bigint,
    sep_1             text,
    p_aid             bigint,
    p_id              bigint,
    p_lastname        character varying,
    p_name            character varying,
    p_patronymic      character varying,
    p_fio             text,
    p_birth_date      date,
    p_status          character varying,
    sep_2             text,
    "Тип пересечения" text,
    "Совпало ФИОДР"   text,
    "Совпало ФИО"     text,
    "Совпало ДР"      text
  )
  language plpgsql
as $$
declare
  participant_array integer[];
begin
  execute
      'with REG_cr as ( -- статус записи в группу
			select distinct on (class_record_id) class_record_id,
																					 first_value(class_record_status_id)
																					 over (partition by class_record_id order by id desc) as last_status
			from md.class_record_status_registry
			),
			 REG_p as ( -- статус участника
					 select distinct on (participant_id) participant_id,
																							 first_value(status_id)
																							 over (partition by participant_id order by id desc) as last_status,
																							 first_value(reason_id)
																							 over (partition by participant_id order by id desc) as last_reason
					 from reference.participant_status_log
			 ),
			 -- Participants
			 L3 as ( -- вспомогательная выборка для участников
					 select p.id as p_count, psl.last_status, psl.last_reason
					 from md.participant p
										join REG_p psl on p.id = psl.participant_id
					 group by p.id, psl.last_status, psl.last_reason
			 ),
			 participants_unique as (
					 select array_agg(p_count) as array_value from L3
			 ),
			 participants_total as (
					 select array_agg(p_count) as array_value from L3 where last_status not in (1, 2, 8)
			 ),
			 participants_started as (
					 select array_agg(p_count) as array_value from L3 where last_status = 7
			 ),
			 participants_on_pause as (
					 select array_agg(p_count) as array_value from L3 where last_status = 5
			 ),
			 paused_partcipants as ( -- только участники на паузе
					 select distinct p.id                                 participant_id,
													 array_agg(distinct crsr.last_status) statuses
					 from md.participant p
										join REG_p psl on p.id = psl.participant_id
										join md.class_record cr using (participant_id)
										join REG_cr crsr on cr.id = crsr.class_record_id
					 where psl.last_status = 5
					 group by p.id
			 ),
			 participants_on_pause_only as (
					 select array_agg(participant_id) as array_value
					 from paused_partcipants
					 where 1 != all (statuses)
						 and 3 != all (statuses)
			 ),
			 participants_on_pause_enrolled as (
					 select array_agg(participant_id) as array_value
					 from paused_partcipants
					 where 3 = any (statuses)
			 ),
			 participants_on_pause_participated as (
					 select array_agg(participant_id) as array_value
					 from paused_partcipants
					 where 1 = any (statuses)
						 and 3 != all (statuses)
			 ),
			 awaiting_partcipants as ( -- участники на подборе
					 select distinct p.id                                 participant_id,
													 array_agg(distinct crsr.last_status) statuses
					 from md.participant p
										join REG_p psl on p.id = psl.participant_id
										join md.class_record cr using (participant_id)
										join REG_cr crsr on cr.id = crsr.class_record_id
					 where psl.last_status = 6
					 group by p.id
			 ),
			 participants_awaiting as (
					 select array_agg(p_count) as array_value from L3 where last_status = 6
			 ),
			 participants_awaiting_enrolled as (
					 select array_agg(participant_id) as array_value
					 from awaiting_partcipants
					 where 3 = any (statuses)
			 ),
	
			 participants_awaiting_participated as (
					 select array_agg(participant_id) as array_value
					 from awaiting_partcipants
					 where 1 = any (statuses)
						 and 3 != all (statuses)
			 ),
			 choose_direction_partcipants as (
					 select distinct p.id                                              as participant_id,
													 array_agg(distinct coalesce(crsr.last_status, 0)) as statuses
					 from md.participant p
										join REG_p psl on p.id = psl.participant_id
										left join md.class_record cr using (participant_id)
										left join REG_cr crsr on cr.id = crsr.class_record_id
					 where psl.last_status = 4
					 group by p.id
			 ),
			 participants_choose_direction as (
					 select array_agg(p_count) as array_value from L3 where last_status = 4
			 ),
			 participants_choose_direction_current as (
					 select array_agg(participant_id) as array_value
					 from choose_direction_partcipants
					 where 4 != all (statuses)
						 and 5 != all (statuses)
			 ),
	
			 participants_choose_direction_former as (
					 select array_agg(participant_id) as array_value
					 from choose_direction_partcipants
					 where 4 = any (statuses)
							or 5 = any (statuses)
			 ),
			 participants_created as (
					 select array_agg(p_count) as array_value from L3 where last_status = 3
			 ),
			 created_partcipants as (
					 select distinct p.id                                              as participant_id,
													 array_agg(distinct coalesce(crsr.last_status, 0)) as statuses
					 from md.participant p
										join REG_p psl on p.id = psl.participant_id
										left join md.class_record cr using (participant_id)
										left join REG_cr crsr on cr.id = crsr.class_record_id
					 where psl.last_status = 3
					 group by p.id
			 ),
			 participants_created_current as (
					 select array_agg(participant_id) as array_value
					 from created_partcipants
					 where 4 != all (statuses)
						 and 5 != all (statuses)
			 ),
			 participants_created_former as (
					 select array_agg(participant_id) as array_value
					 from created_partcipants
					 where 4 = any (statuses)
							or 5 = any (statuses)
			 ),
			 participants_out as (
					 select array_agg(p_count) as array_value from L3 where last_status in (1, 8)
			 ),
			 participants_rejected as (
					 select array_agg(p_count) as array_value from L3 where last_status = 8
			 ),
			 participants_rejected_1 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 8 and last_reason = 17
			 ),
			 participants_rejected_2 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 8 and last_reason = 18
			 ),
			 participants_rejected_3 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 8 and last_reason = 19
			 ),
			 participants_rejected_4 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 8 and last_reason = 20
			 ),
			 participants_rejected_5 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 8 and last_reason = 21
			 ),
			 participants_rejected_6 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 8 and last_reason = 22
			 ),
			 participants_rejected_7 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 8 and last_reason = 23
			 ),
			 participants_prohibited as (
					 select array_agg(p_count) as array_value from L3 where last_status = 1
			 ),
			 participants_prohibited_1 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 1 and last_reason in (1, 2)
			 ),
			 participants_prohibited_2 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 1 and last_reason = 3
			 ),
			 participants_prohibited_3 as (
					 select array_agg(p_count) as array_value from L3 where last_status = 1 and last_reason = 4
			 ),
			 participants_in_group as (
					 select array_agg(p_count) as array_value from L3 where last_status in (5, 6, 7)
			 ),
			 L4 as ( -- вспомогательный запрос для подсчета активностей
					 select p.id as participant_id, count(pap.id) as activity_count
					 from md.participant p
										join md.participant_activity_profile pap on p.id = pap.participant_id
										join REG_p psl on p.id = psl.participant_id
					 where psl.last_status in (5, 6, 7)
					 group by p.id
			 ),
			 participants_in_group_1_activity as (
					 select array_agg(participant_id) as array_value from L4 where activity_count = 1
			 ),
			 participants_in_group_2_activity as (
					 select array_agg(participant_id) as array_value from L4 where activity_count = 2
			 ),
			 participants_in_group_3_activity as (
					 select array_agg(participant_id) as array_value from L4 where activity_count >= 3
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
			 participants_in_group_1_group as (
					 select array_agg(participant_id) as array_value from L4_1 where class_record_count = 1
			 ),
			 participants_in_group_2_group as (
					 select array_agg(participant_id) as array_value from L4_1 where class_record_count = 2
			 ),
			 participants_in_group_3_group as (
					 select array_agg(participant_id) as array_value from L4_1 where class_record_count >= 3
			 ),
			 participants_all_gender as (
					 select array_agg(p.id) as array_value
					 from md.participant p
										join REG_p psl on p.id = psl.participant_id
					 where psl.last_status not in (1, 2, 8)
			 ),
			 participants_men as (
					 select array_agg(p.id) as array_value
					 from md.participant p
										join REG_p psl on p.id = psl.participant_id
					 where psl.last_status not in (1, 2, 8)
						 and p.gender = 1
			 ),
			 participants_women as (
					 select array_agg(p.id) as array_value
					 from md.participant p
										join REG_p psl on p.id = psl.participant_id
					 where psl.last_status not in (1, 2, 8)
						 and p.gender = 2
			 ),
			 L7 as ( -- вспомогательная выборка для возраста
					 select p.id as p_count, p.date_of_birth as birth_date
					 from md.participant p
										join REG_p psl on p.id = psl.participant_id
					 where psl.last_status not in (1, 2, 8)
					 group by p.id,p.date_of_birth
					 order by p.id,p.date_of_birth
			 ),
			 participants_age_1 as (
					 select array_agg(p_count) as array_value
					 from L7
					 where extract(year from (age(current_date, birth_date))) < 55
			 ),
			 participants_age_2 as (
					 select array_agg(p_count) as array_value
					 from L7
					 where extract(year from (age(current_date, birth_date))) between 55 and 59
			 ),
			 participants_age_3 as (
					 select array_agg(p_count) as array_value
					 from L7
					 where extract(year from (age(current_date, birth_date))) between 60 and 64
			 ),
			 participants_age_4 as (
					 select array_agg(p_count) as array_value
					 from L7
					 where extract(year from (age(current_date, birth_date))) between 65 and 69
			 ),
			 participants_age_5 as (
					 select array_agg(p_count) as array_value
					 from L7
					 where extract(year from (age(current_date, birth_date))) between 70 and 74
			 ),
			 participants_age_6 as (
					 select array_agg(p_count) as array_value
					 from L7
					 where extract(year from (age(current_date, birth_date))) between 75 and 79
			 ),
			 participants_age_7 as (
					 select array_agg(p_count) as array_value
					 from L7
					 where extract(year from (age(current_date, birth_date))) >= 80
			 )
			 -- @formatter:off
	select array_value from '||participant_name into participant_array;

return query
with
	p1 as (
		select p_esz.aid,
					 p_esz.lastname,
					 p_esz.name,
					 p_esz.patronymic,
					 concat(
						 lower(lastname), ' ', lower("name"), ' ', lower(patronymic)
						 ) as fio,
					 p_esz.birth_date,
					 priority
		from idb._participants_from_esz p_esz
		order by aid
	),
	p2 as (
		select aid,
					 p.id,
					 second_name as lastname,
					 first_name  as name,
					 patronymic,
					 concat(
						 lower(second_name), ' ', lower(first_name), ' ', lower(patronymic)
						 )         as fio,

					 date_of_birth  birth_date,
					 ps.title  status
		from md.participant p
					 left join idb.participant_map pm using (id)
					 left join reference.participant_status_log psl on p.id = psl.participant_id
		             left join reference.participant_status ps on psl.status_id = ps.id
		order by aid
	)

select p1.*,
			 ''                                                                       as sep_1,
			 p2.*,
			 ''                                                                       as sep_2,
			 case
				 when p1.aid is null then 'есть только в КИС МД'
				 when p2.aid is null then 'есть только в ЕСЗ'
				 else 'есть и там и там'
				 end                                                                    as "Тип пересечения",
			 case when p1.fio = p2.fio and p1.birth_date = p2.birth_date then '+' end as "Совпало ФИОДР",
			 case when p1.fio = p2.fio then '+' end                                   as "Совпало ФИО",
			 case when p1.birth_date = p2.birth_date then '+' end                     as "Совпало ДР"

from p1
			 full join p2 using (aid)
             join unnest(participant_array) as pid on p2.id=pid 
order by p2.fio, p1.fio
;

END
$$;