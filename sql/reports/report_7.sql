drop function if exists public.report_7;
CREATE OR REPLACE FUNCTION public.report_7(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    "Общее количество Поставщиков"      bigint,
    "Общее количество групп"            bigint,
    "Начали заниматься"                 bigint,
    "Полностью укомплектованных"        bigint,
    "Без зачисленных"                   bigint,
    "Охват обучающихся"                 bigint,
    "Количество уникальных участников " bigint,
    "Не выбрана активность"             bigint,
    "Не выбрана группа"                 bigint,
    "Выбрана группа"                    bigint,
    "Личные дела, отозванные заявителя" bigint,
    "Участники отчислены"               bigint,
    "Количество уникальных участников"  bigint,
    "Мужчины"                           bigint,
    "Женщины"                           bigint,
    "до 55"                             numeric,
    "55-59"                             numeric,
    "60-64"                             numeric,
    "65-69"                             numeric,
    "70-74"                             numeric,
    "75-79"                             numeric,
    "80 и более"                        numeric,
    "Одна активность"                   bigint,
    "Две активности"                    bigint,
    "Три активности"                    bigint,
    "Четыре активности"                 bigint,
    "Пять активностей"                  bigint,
    "Шесть активностей"                 bigint
  )
  language plpgsql
as $$
begin
  
  return query
    with
      REG_groups as ( -- статус группы
        select distinct on (group_id)
               group_id,
               first_value(status_id) over (partition by group_id order by id desc) as last_status
        from md.group_status_registry
        where is_expectation = false
      ),
      REG_p as ( -- статус участника
        select distinct on (participant_id)
               participant_id,
               first_value(status_id)
               over (partition by participant_id order by id desc) as last_status,
               first_value(reason_id)
               over (partition by participant_id order by id desc) as last_reason
        from reference.participant_status_log
      ),
      L0 as (
        select count(*)::bigint
        from md.organization o
        where o.is_provider = true
      ),
      G1 as (
        select count(*)
        from md.groups g
               join REG_groups on g.id = REG_groups.group_id
        where REG_groups.last_status not in (1, 14)
      ),
      G2 as (
        select count(*)
        from md.groups g
               join REG_groups on g.id = REG_groups.group_id
        where REG_groups.last_status = 8
      ),
      G3 as (
        select count(*)
        from md.groups g
               join REG_groups on g.id = REG_groups.group_id
        where REG_groups.last_status = 7
      ),
      G4 as (
        select count(*)
        from md.groups g
               left join md.class_record cr on g.id = cr.group_id
        where cr.id isnull
      ),
      G5 as (
        select sum(g.max_count)
        from md.groups g
      ),
      P1 as (
        select count(*)
        from md.participant p
               join REG_p on p.id = REG_p.participant_id
      ),
      P2 as (
        select count(*)
        from md.participant p
               join REG_p on p.id = REG_p.participant_id
            and REG_p.last_status = 3
      ),
      P3 as (
        select count(*)
        from md.participant p
               join REG_p on p.id = REG_p.participant_id
            and REG_p.last_status = 4
      ),
      P4 as (
        select count(*)
        from md.participant p
               join REG_p on p.id = REG_p.participant_id
            and REG_p.last_status = 6
      ),
      P5 as (
        select count(*)
        from md.participant p
               join REG_p on p.id = REG_p.participant_id
            and REG_p.last_status in (2, 8)
      ),
      P6 as (
        select count(*)
        from md.participant p
               join REG_p on p.id = REG_p.participant_id
            and REG_p.last_status = 1
      ),
      P7 as (
        select count(distinct p.id)
        from md.participant p
               join REG_p on p.id = REG_p.participant_id
      ),
      P8 as (
        select count(*)
        from md.participant p
        where p.gender = 1
      ),
      P9 as (
        select count(*)
        from md.participant p
        where p.gender = 2
      ),
      L1 as ( -- вспомогательная выборка для возраста
        select count(p.id) as p_count, p.date_of_birth as birth_date
        from md.participant p
        group by birth_date
        order by birth_date
      ),
      R1 as (
        select sum(p_count) as participants_age_1
        from L1
        where extract(year from (age(current_date, birth_date))) < 55
      ),
      R2 as (
        select sum(p_count) as participants_age_2
        from L1
        where extract(year from (age(current_date, birth_date))) between 55 and 59
      ),
      R3 as (
        select sum(p_count) as participants_age_3
        from L1
        where extract(year from (age(current_date, birth_date))) between 60 and 64
      ),
      R4 as (
        select sum(p_count) as participants_age_4
        from L1
        where extract(year from (age(current_date, birth_date))) between 65 and 69
      ),
      R5 as (
        select sum(p_count) as participants_age_5
        from L1
        where extract(year from (age(current_date, birth_date))) between 70 and 74
      ),
      R6 as (
        select sum(p_count) as participants_age_6
        from L1
        where extract(year from (age(current_date, birth_date))) between 75 and 79
      ),
      R7 as (
        select sum(p_count) as participants_age_7
        from L1
        where extract(year from (age(current_date, birth_date))) >= 80
      ),
      L2 as (
        select pap.participant_id,
               count(*) cnt
        from md.participant_activity_profile pap
               join md.class_record cr on pap.participant_id = cr.participant_id
        where pap.status_id = 1
        group by pap.participant_id
      ),
      A1 as (
        select count(*)
        from L2
        where L2.cnt = 1
      ),
      A2 as (
        select count(*)
        from L2
        where L2.cnt = 2
      ),
      A3 as (
        select count(*)
        from L2
        where L2.cnt = 3
      ),
      A4 as (
        select count(*)
        from L2
        where L2.cnt = 4
      ),
      A5 as (
        select count(*)
        from L2
        where L2.cnt = 5
      ),
      A6 as (
        select count(*)
        from L2
        where L2.cnt = 6
      )
    select *
    from L0,G1,G2,G3,G4,G5,
        P1,P2,P3,P4,P5,P6,P7,P8,P9,
        R1,R2,R3,R4,R5,R6,R7,
        A1,A2,A3,A4,A5,A6
    limit limit_param offset offset_param;
end;
$$;