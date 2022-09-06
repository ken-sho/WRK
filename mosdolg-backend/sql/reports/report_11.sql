drop function if exists public.report_11;
CREATE OR REPLACE FUNCTION public.report_11(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    fio           text,
    phone         text,
    neighbourhood text,
    district      text,
    tcso          text,
    full_name     text,
    org_name      text,
    count_groups  bigint,
    group_code    text,
    nko           text,
    activity1     text,
    activity2     text,
    activity3     text,
    count         bigint,
    lesson_count  bigint
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L0 as (
        select g.coworker_id,
               count(*) as count_groups
        from md.groups g
        where g.coworker_id is not null
        group by g.coworker_id
      ),
      L1 as (
        select l.group_id,
               array_length(array_agg(distinct l.id), 1)                                   as lesson_cnt,
               coalesce(array_length(array_remove(array_agg(distinct ad.id), null), 1), 0) as coordinator_cnt,
               ad.user_id                                                                  as coordinator_id
        from md.lesson l
               left join md.attendance_data ad on l.id = ad.lesson_id and ad.user_role = 'COORDINATOR'
        where l.lesson_date between i_date_from and i_date_to
        group by l.group_id, ad.user_id
      )
    select trim(concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name))                    as fio,
           string_agg(cc.value, ';' order by cc.priority)                                           as phone,
           tr2.title::text                                                                          as neighbourhood,
           tr1.title::text                                                                          as district,
           o2.short_title::text                                                                     as tcso,
           o2.full_title::text                                                                      as full_name,
           o1.short_title::text                                                                     as org_name,
           coalesce(L0.count_groups, 0),
           concat('G-', lpad(g.id::text, 8, '0'))                                                   as group_code,
           d.title::text                                                                            as NKO,
           a1.title::text                                                                           as activity1,
           a2.title::text                                                                           as activity2,
           a3.title::text                                                                           as activity3,
           coalesce(sum(case when L1.coordinator_id = up.id then L1.coordinator_cnt else 0 end), 0) as count,
           coalesce(sum(L1.lesson_cnt), 0)                                                          as lesson_count
    from md.groups g
           join md.coworker cw on g.coworker_id = cw.id
           left join md.coworker_contact cc on cw.id = cc.owner_id and cc.contact_type_id = 1
           left join md.organization o1 on g.organization_id = o1.id
           left join reference.department d on o1.department_id = d.id
           left join md.organization o2 on g.territory_centre_id = o2.id
           left join md.territory_organization torg on o2.id = torg.organization_id
           left join ar.territory tr1 on torg.territory_id = tr1.id
           left join ar.territory tr2 on tr1.parent_id = tr2.id
           left join reference.activity a3 on g.activity_id = a3.id
           left join reference.activity a2 on a3.parent_id = a2.id
           left join reference.activity a1 on a2.parent_id = a1.id
           left join md.user_profile up on cw.id = up.coworker_id
           left join L0 on cw.id = L0.coworker_id
           left join L1 on g.id = L1.group_id
    where cw.is_coordinator = true
      -- территории
      and (district_ids = '{}'
      or tr1.id in (select unnest(district_ids)))
      -- ТЦСО
      and (organization_ids = '{}'
      or cw.organization_id in (select unnest(organization_ids)))
    group by g.id, cw.first_name, cw.second_name, cw.middle_name, tr2.title, tr1.title, o2.short_title,
             o2.full_title, o1.short_title, d.title, a1.title, a2.title, a3.title, L0.count_groups, cw.id
    order by cw.id
    limit limit_param offset offset_param;

end;
$$;