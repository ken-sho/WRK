drop function if exists public.report_6;
CREATE OR REPLACE FUNCTION public.report_6(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    neighbourhood       text,
    district            text,
    org_name            text,
    full_name           text,
    nko                 text,
    tcso                text,
    activity1           text,
    activity2           text,
    activity3           text,
    group_count         bigint,
    group_extend        bigint,
    group_max_cnt       bigint,
    group_max_per       numeric,
    group_pl_vacant     numeric,
    group_pl_vacant_per numeric,
    group_pl_free       numeric,
    group_pl_share      numeric,
    group_with_part     bigint,
    group_min_part      bigint,
    group_max_part      bigint,
    provider_total      bigint,
    provider_total_dep  bigint
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L0 as (
        select distinct gsr.group_id
        from md.group_status_registry gsr
        where gsr.is_expectation = false
          and gsr.status_id in (2, 3, 4, 6, 7, 8, 9, 11, 12)
          and gsr.end_date isnull
           or gsr.end_date >= i_date_to
      ),
      L1 as (
        select sum(g.max_count) as max_count_all
        from md.groups g
               join L0 on g.id = L0.group_id
      ),
      L2 as (
        select cr.group_id,
               count(*)       as cnt_part,
               sum(1) over () as cnt_part_all
        from md.class_record cr
               join L0 using (group_id)
               join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
        where (crsr.end_date isnull
          or (crsr.start_date <= i_date_to and crsr.end_date >= i_date_to))
          and crsr.class_record_status_id in (1, 2, 3, 6, 7)
        group by cr.group_id
      ),
      L3 as (
        select cr.group_id
        from md.class_record cr
               join L0 using (group_id)
               join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
        where (crsr.end_date isnull
          or (crsr.start_date <= i_date_to and crsr.end_date >= i_date_to))
          and crsr.class_record_status_id in (1, 4)
        group by cr.group_id
        union
        select g.id as group_id
        from md.groups g
               join L0 on g.id = L0.group_id
               left join md.class_record cr on g.id = cr.group_id
        where cr.id isnull
        group by g.id
      ),
      L4 as (
        select count(distinct o.id) as org_cnt
        from md.organization o
               join md.groups g on o.id = g.organization_id
               join L0 on g.id = L0.group_id
        where o.is_provider = true
      ),
      L5 as (
        select count(distinct d.id) as dep_cnt
        from md.organization o
               join reference.department d on o.department_id = d.id
               join md.groups g on o.id = g.organization_id
               join L0 on g.id = L0.group_id
        where o.is_provider = true
      )
    select tr2.title::text                                                                                       as neighbourhood,
           tr1.title::text                                                                                       as district,
           o1.short_title::text                                                                                  as org_name,
           o1.full_title::text                                                                                   as org_name_full,
           d.title::text                                                                                         as NKO,
           o2.short_title::text                                                                                  as tcso,
           a1.title::text                                                                                        as activity1,
           a2.title::text                                                                                        as activity2,
           a3.title::text                                                                                        as activity3,
           count(*)                                                                                              as group_count,
           sum(case when g.extend = false then 1 else 0 end)                                                     as group_extend,
           sum(g.max_count)                                                                                      as group_max_cnt,
           round(sum(g.max_count)::numeric / L1.max_count_all::numeric * 100,
                 3)                                                                                              as group_max_per,
           sum(L2.cnt_part),
           round(sum(L2.cnt_part)::numeric / L2.cnt_part_all::numeric * 100, 3),
           L1.max_count_all - sum(L2.cnt_part),
           round(sum(L2.cnt_part)::numeric /
                 ((L1.max_count_all::numeric - sum(L2.cnt_part)::numeric) + sum(L2.cnt_part)::numeric) * 100,
                 3)                                                                                              as group_pl_share,
           sum(case when L3.group_id isnull then 0 else 1 end)                                                   as group_with_part,
           sum(case when L2.cnt_part = g.min_count then 1 else 0 end)                                            as group_min_part,
           sum(case when L2.cnt_part = g.max_count then 1 else 0 end)                                            as group_max_part,
           L4.org_cnt                                                                                            as provider_total,
           L5.dep_cnt                                                                                            as provider_total_dep
    from md.groups g
           join L0 on g.id = L0.group_id
           left join md.organization o1 on g.organization_id = o1.id
           left join reference.department d on o1.department_id = d.id
           left join md.organization o2 on g.territory_centre_id = o2.id
           left join md.territory_organization torg on o2.id = torg.organization_id
           left join ar.territory tr1 on torg.territory_id = tr1.id
           left join ar.territory tr2 on tr1.parent_id = tr2.id
           left join reference.activity a3 on g.activity_id = a3.id
           left join reference.activity a2 on a3.parent_id = a2.id
           left join reference.activity a1 on a2.parent_id = a1.id
           left join L2 on g.id = L2.group_id
           left join L3 on g.id = L3.group_id
           cross join L1
           cross join L4
           cross join L5
    where g.plan_start_date <= i_date_to
      and g.plan_end_date >= i_date_from
      -- территории
      and (district_ids = '{}'
      or tr1.id in (select unnest(district_ids)))
      -- ТЦСО
      and (organization_ids = '{}'
      or g.organization_id in (select unnest(organization_ids)))
    group by tr2.title, tr1.title, o1.short_title, o1.full_title, d.title, o2.short_title, a1.title, a2.title, a3.title,
             L1.max_count_all, L2.cnt_part_all, L4.org_cnt, L5.dep_cnt
    order by tr2.title, tr1.title, o1.short_title
    limit limit_param offset offset_param;

end;
$$;