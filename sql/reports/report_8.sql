drop function if exists public.report_8;
CREATE OR REPLACE FUNCTION public.report_8(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    "Краткое наименование поставщика"   text,
    "Полное наименование поставщика"    text,
    "ТЦСО"                              text,
    "Направленность 1 уровня"           text,
    "Направленность 2 уровня"           text,
    "Направленность 3 уровня"           text,
    "Код группы"                        text,
    "ФИО координатора"                  text,
    "Статус группы"                     text,
    "Количество приостановок"           bigint,
    "Причина приостановки"              text,
    "Комментарий приостановки"          text,
    "Дата начала приостановки занятий"  text,
    "Дата окончания приостановки занят" text,
    "Количество дней в приостановке"    integer
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L0 as (
        select gsr.group_id,
               count(*)                                          numb_susp,
               array_agg(grsr.title order by gsr.id desc)     as gr_reason,
               array_agg(gsr.comment order by gsr.id desc)    as gr_comment,
               array_agg(gsr.start_date order by gsr.id desc) as gr_start_date,
               array_agg(gsr.end_date order by gsr.id desc)      gr_end_date
        from md.group_status_registry gsr
               join reference.group_status gs on gsr.status_id = gs.id
               left join reference.group_status_reason grsr on gs.id = grsr.status_id
        where gsr.is_expectation = false
          and gsr.start_date >= i_date_from
          and gsr.start_date <= i_date_to
          and gsr.status_id = 9
        group by gsr.group_id
      )
    select o1.short_title::text                                                     as org_name,
           o1.full_title::text                                                      as full_name,
           o2.short_title::text                                                     as tcso,
           a1.title::text                                                           as activity1,
           a2.title::text                                                           as activity2,
           a3.title::text                                                           as activity3,
           concat('G-', lpad(g.id::text, 8, '0'))                                   as gcode,
           concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name)          as coordanator,
           gs.title::text                                                           as group_status,
           L0.numb_susp,
           L0.gr_reason[1]::text                                                    as gr_reason,
           L0.gr_comment[1]::text                                                   as gr_comment,
           to_char(L0.gr_start_date[1], 'dd.mm.yyyy')                               as gr_start_date,
           to_char(coalesce(L0.gr_end_date[1], g.plan_end_date), 'dd.mm.yyyy')      as gr_end_date,
           coalesce(L0.gr_end_date[1]::date, i_date_to) - L0.gr_start_date[1]::date as day_num_susp
    from md.groups g
           join L0 on g.id = L0.group_id
           join md.group_status_registry gsr on g.id = gsr.group_id
           join reference.group_status gs on gsr.status_id = gs.id
           left join md.coworker cw on g.coworker_id = cw.id
           left join md.coworker_contact cc on cw.id = cc.owner_id and cc.contact_type_id = 1
           left join md.organization o1 on g.organization_id = o1.id
           left join md.organization o2 on g.territory_centre_id = o2.id
           left join md.territory_organization torg on o2.id = torg.organization_id
           left join ar.territory tr1 on torg.territory_id = tr1.id
           left join reference.activity a3 on g.activity_id = a3.id
           left join reference.activity a2 on a3.parent_id = a2.id
           left join reference.activity a1 on a2.parent_id = a1.id
    where gsr.is_expectation = false
      and gsr.end_date isnull
      -- территории
      and (district_ids = '{}'
      or tr1.id in (select unnest(district_ids)))
      -- ТЦСО
      and (organization_ids = '{}'
      or g.organization_id in (select unnest(organization_ids)))
    order by g.id
    limit limit_param offset offset_param;
end;
$$;