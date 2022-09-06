drop function if exists public.report_2;
CREATE OR REPLACE FUNCTION public.report_2(
  i_date_from  date default CURRENT_DATE, i_date_to date default CURRENT_DATE,
  district_ids bigint[] default array []::integer[], organization_ids bigint[] default array []::integer[],
  limit_param  integer default null::integer, offset_param bigint default null::bigint)
  returns TABLE (
    id                bigint,
    fio               text,
    phones            text,
    days_in_system    integer,
    org_short_title   text,
    area              text,
    district          text,
    org_full_title    text,
    status_title      text,
    activity_l1_title text,
    activity_l2_title text,
    activity_l3_title text,
    group_id          bigint,
    coordinators      text,
    start_by_plan     date,
    days_to_wait      integer
  )
  language plpgsql
as $$
begin
  
  return query
    
    -- участники со всеми регистрами
    with
      L1 as (
        select distinct on (pt.id)
               pt.id,
               FIRST_VALUE(R1.status_id) over w1                              status_id,
               concat(pt.second_name, ' ', pt.first_name, ' ', pt.patronymic) fio,
               max((case
                      when md.participant_organization.organization_id is not null
                        then md.participant_organization.organization_id
                      else pt.organization_id end))                           organization_id,
               array_to_string(array_agg(distinct district.title), '; ')      district_title,
               max(neighbourhood.title)                                       neighbourhood_title,
               max(md.class_record.group_id)                                  group_id,
               array_to_string(array_agg(distinct pc.value), '; ')            personal_phone_number,
               age_in_days(max(R2.start_date)::date, i_date_to)               days,
               max(md.groups.plan_start_date)                                 plan_start_date,--Плановая дата начала занятий
               age_in_days(min(md.groups.plan_start_date)::date, i_date_to)   days_to_wait--	Количество дней ожидания
        
        from md.participant pt
               -- R1, регистр статусов личного дела
               left join reference.participant_status_log R1 on (pt.id = R1.participant_id)
            
            -- R2, регистр записи в группу
               left join md.class_record on (pt.id = md.class_record.participant_id)
               left join md.class_record_status_registry R2 on (md.class_record.id = class_record_id)
            
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
          
               left join md.participant_contact pc on (pc.contact_type_id = 1 and pc.owner_id = pt.id)
               left join md.groups on (md.class_record.group_id = md.groups.id)
        
        where
          -- статус личного дела "Подбор группы"
          R1.status_id = 6
          -- срез регистра
          and R1.start_date between i_date_from and i_date_to
          and (R1.end_date > i_date_to or R1.end_date is null)
          
          -- статус записи в группу "Зачислен"
          and R2.class_record_status_id = 3
          -- срез регистра
          and R2.start_date between i_date_from and i_date_to
          and (R2.end_date > i_date_to or R2.end_date is null)
          
          -- территории
          and (district_ids = '{}'
          or district.id in (select unnest(district_ids)))
          -- ТЦСО
          and (organization_ids = '{}'
          or md.organization.id in (select unnest(organization_ids)))
        
        group by pt.id, R1.status_id, R1.id
          window
            w1 as (partition by R1.participant_id order by R1.id desc)
      )
    
    select distinct on (L1.id)
           L1.id,--Номер личного дела
           L1.fio,--ФИО
           L1.personal_phone_number                                                                   phones,--Телефон
           L1.days                                                                                    age,--Дней создан в системе
    
           org.short_title::text                                                                      org_short_title,--Краткое наименование ЦСО
           L1.neighbourhood_title::text                                                               area,--Округ
           L1.district_title                                                                          district,--Район
           org.full_title::text                                                                       org_full_title,--Полное наименование ЦСО(не реализуется в версии 1)
           status.title::text                                                                         status_title,--Статус личного дела
    
           a1.title::text                                                                             activity_l1_title,--Направление 1 уровня
           a2.title::text                                                                             activity_l2_title,--Направление 2 уровня
           a3.title::text                                                                             activity_l3_title,--Направление 3 уровня
    
           L1.group_id,--Код группы
    
           concat(md.coworker.second_name, ' ', md.coworker.first_name, ' ', md.coworker.middle_name) coworker_fio,--ФИО координатора
           L1.plan_start_date,--Плановая дата начала занятий
           L1.days_to_wait--	Количество дней ожидания
    
    from L1
           -- подтягиваем справочники
           left join md.contact on (L1.id = md.contact.owner_id)
           left join md.organization org on (L1.organization_id = org.id)
           left join reference.participant_status status on (L1.status_id = status.id)
           left join md.groups on (L1.group_id = md.groups.id)
           left join md.coworker on (md.groups.coworker_id = md.coworker.id)
      
           left join reference.activity a3 on (md.groups.activity_id = a3.id)
           left join reference.activity a2 on (a3.parent_id = a2.id)
           left join reference.activity a1 on (a2.parent_id = a1.id)
    
    order by L1.id
    limit limit_param offset offset_param;

end;
$$;