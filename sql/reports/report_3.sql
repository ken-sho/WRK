drop function if exists public.report_3;
CREATE OR REPLACE FUNCTION public.report_3(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    rec_id                 bigint,
    fio                    text,
    participant_phones     text,
    responsible_person     text,
    creation_date          text,
    days_in_waiting_status integer,
    org_short_title        text,
    org_full_title         text,
    neighbourhood          text,
    district               text,
    participant_status     text
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L1 as (
        select distinct on (pt.id)
               pt.id         id,
               R1.start_date start_date
        from md.participant pt
               left join reference.participant_status_log R1 on (pt.id = R1.participant_id)
        where R1.status_id = 3
      )
    select distinct on (pt.id)
           pt.id                                                          rec_id,--Номер личного дела (id)
           concat(pt.second_name, ' ', pt.first_name, ' ', pt.patronymic) fio,--ФИО
           array_to_string(array_agg(distinct (md.contact.value)), '; ')  participant_phones,--телефон(ы)
           'NOT_IMPLEMENTED_YET'                                          responsible_person,
           max(L1.start_date)::date::text                                 creation_date, --Дата создания личного дела
           age_in_days(max(L1.start_date)::date, i_date_to)               days_in_waiting_status, --Кол-во дней ожидания
           max(md.organization.short_title)                               org_short_title,--ТЦСО краткое наименование
           'NOT_IMPLEMENTED_YET'                                          org_full_title,--ТЦСО полное наименование
           max(neighbourhood.title)                                       neighbourhood, --округ
           array_to_string(array_agg(district.title) over w1, '; ')       district,--район
           max(reference.participant_status.title)                        participant_status --Статус личного дела
    
    from md.participant pt
           left join L1 on (pt.id = L1.id)
        -- контакты
           left join md.contact on (pt.id = md.contact.owner_id)
        -- регистр изменений статуса участников
           left join reference.participant_status_log R2 on (pt.id = R2.participant_id)
           left join md.class_record on (pt.id = md.class_record.participant_id)
           left join reference.participant_status on (R2.status_id = reference.participant_status.id)
        
        -- территории
           left join reference.department on (reference.department.key = 'D_SOZ')
           left join md.participant_organization on (md.participant_organization.participant_id = pt.id
        and md.participant_organization.link_type = 'CREATED'
        and md.participant_organization.enabled = true)
           left join md.organization on ((md.organization.id = pt.organization_id
        or md.organization.id = md.participant_organization.organization_id)
        and md.organization.department_id = reference.department.id)
           left join md.territory_organization on (md.territory_organization.organization_id = md.organization.id)
           left join ar.territory district
                     on (district.parent_id is not null and (district.id = md.territory_organization.territory_id
                       or district.parent_id = md.territory_organization.territory_id))
           left join ar.territory neighbourhood
                     on (neighbourhood.parent_id is null and neighbourhood.id = district.parent_id)
    
    where (R2.status_id = 3
      or R2.status_id = 4)
      and R2.start_date between i_date_from and i_date_to
      and (R2.end_date > i_date_to or R2.end_date is null)
      -- территории
      and (district_ids = '{}'
      or district.id in (select unnest(district_ids)))
      -- ТЦСО
      and (organization_ids = '{}'
      or md.organization.id in (select unnest(organization_ids)))
    
    group by pt.id, R2.status_id, R2.id, district.title
      window
        w1 as (partition by R2.participant_id order by R2.id desc)
    
    order by rec_id
    limit limit_param offset offset_param;
end;
$$;