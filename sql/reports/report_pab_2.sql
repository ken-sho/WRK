drop function if exists public.report_pab_2;
CREATE OR REPLACE FUNCTION public.report_pab_2(i_date_to date default CURRENT_DATE)
  returns TABLE (
    ter             character varying,
    group_count     bigint,
    max_place_count bigint,
    i_busy_place    bigint,
    i_free_place    bigint,
    i_free_range    numeric
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L1 as (
        select ter2.title as    district,
               count(*)         group_cnt,
               sum(g.max_count) max_place_cnt
        from md."groups" g
               join md.group_status_registry gsr on g.id = gsr.group_id
               left join md.organization org on org.id = g.territory_centre_id
               left join md.territory_organization tero on tero.organization_id = org.id
               left join ar.territory ter on tero.territory_id = ter.id
               left join ar.territory ter2 on ter.parent_id = ter2.id
        where gsr.is_expectation = false
          and gsr.status_id in (2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16)
          --and '01.06.2019'::date between gsr.start_date and gsr.end_date
          --and i_date_to >= gsr.start_date
          and (i_date_to <= gsr.end_date or gsr.end_date is null)
        
        group by ter2.title
      ),
      L2 as (
        select ter2.title as district,
               count(*)   as busy_place
        from md."groups" g
               join md.class_record rec on g.id = rec.group_id
               join md.group_status_registry gsr on g.id = gsr.group_id
               join md.organization org on org.id = g.territory_centre_id
               join md.territory_organization tero on tero.organization_id = org.id
               join ar.territory ter on tero.territory_id = ter.id
               join ar.territory ter2 on ter.parent_id = ter2.id
        where gsr.is_expectation = false
          and gsr.status_id in (1, 2, 3, 6, 7)
        group by ter2.title
        -- and i_date_to >= gsr.start_date and (i_date_to <= gsr.end_date or gsr.end_date is null)
      )
    
    select ter_m.title                                                                          as i_territory,
           L1.group_cnt                                                                         as i_group_number,
           L1.max_place_cnt                                                                     as i_max_place_cnt,
           L2.busy_place                                                                        as i_busy_places,
           (L1.max_place_cnt - L2.busy_place)                                                   as i_free_places,
           round((L1.max_place_cnt - L2.busy_place)::numeric / L1.max_place_cnt::numeric * 100) as free_range
    from L1
           right join ar.territory ter_m on ter_m.title = L1.district
           left join L2 on ter_m.title = L2.district
    where ter_m.parent_id is null;

end
$$;