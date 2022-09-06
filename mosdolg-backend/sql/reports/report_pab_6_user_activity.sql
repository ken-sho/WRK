drop function if exists public.report_pab_r10;
CREATE OR REPLACE FUNCTION public.report_pab_r10(
  district_1  bigint[] default array []::integer[], district_2 bigint[] default array []::integer[],
  district_3  bigint[] default array []::integer[], district_4 bigint[] default array []::integer[],
  tcso_1      bigint[] default array []::integer[], tcso_2 bigint[] default array []::integer[],
  tcso_3      bigint[] default array []::integer[], stt_1 bigint[] default array []::integer[],
  stt_2       bigint[] default array []::integer[], stt_3 bigint[] default array []::integer[],
  sign_online text default ''::text, arr_act_1 bigint[] default array []::integer[],
  arr_act_2   bigint[] default array []::integer[], arr_act_3 bigint[] default array []::integer[])
  returns TABLE (
    "Номер строки"                      bigint,
    "ФИО"                               text,
    "Номер личного дела"                bigint,
    "Дата рождения"                     text,
    "Пол"                               text,
    "Возраст"                           double precision,
    "Район проживания"                  text,
    "Район регистрации"                 text,
    "ТЦСО создания личного дела"        text,
    "Дата создания ЛД"                  text,
    "Статус ЛД"                         text,
    "Причина отказа"                    text,
    "Направление 1-го уровня"           text,
    "Направление 2-го уровня"           text,
    "Направление 3-го уровня"           text,
    "Дата создания профиля активности"  text,
    "ТЦСО/Организации Поставщика созда" text,
    "Код группы"                        text,
    "Статус группы"                     text,
    "Статус записи в группу"            text,
    "Дата зачисления"                   text,
    "Причина приостановки"              text,
    "Дата отчисления"                   text,
    "Причина отчисления"                text,
    "Признак онлайн"                    text,
    "Краткое наименование поставщика"   text,
    "Краткое наименование ТЦСО координ" text,
    "Район ЦСО  координации группы"     text,
    "Округ ТЦСО координации группы"     text
  )
  language plpgsql
as $$
begin
  
  return query
    with
      PSL as (
        select distinct
               psl.participant_id,
               first_value(psl.start_date) over (partition by psl.participant_id order by psl.start_date) as start_date,
               first_value(ps.title) over (partition by psl.participant_id order by psl.id desc)          as last_stt,
               first_value(ps.id)
               over (partition by psl.participant_id order by psl.id desc)                                as last_stt_num,
               first_value(case when ps.id in (1, 8) then psr.reason else null end)
               over (partition by psl.participant_id order by psl.id desc)                                as last_reason
        from reference.participant_status_log psl
               join reference.participant_status ps on psl.status_id = ps.id
               left join reference.participant_status_reason psr on psl.reason_id = psr.id
      ),
      ACT as (
        select pap.participant_id,
               act1.title                                                    as level_1,
               case when act1.parent_id isnull then null else act2.title end as level_2,
               case
                 when act1.parent_id isnull or act2.parent_id isnull then null
                 else act3.title end                                         as level_3,
               act1.id                                                       as act1_num,
               case when act1.parent_id isnull then 0 else act2.id end       as act2_num,
               case
                 when act1.parent_id isnull or act2.parent_id isnull then 0
                 else act3.id end                                            as act3_num,
               pap.date_from,
               case
                 when cr.group_id is null then null
                 else concat('G-', lpad(cr.group_id::text, 8, '0')) end      as group_num,
               gs.title                                                      as group_status,
               gs.id                                                         as group_status_num,
               crs.title                                                     as cr_status,
               crs.id                                                        as cr_status_num,
               case when act1.activity_type = 6 then 'ДА' else 'НЕТ' end     as activity_type,
               o1.short_title                                                as org_name,
               o2.short_title                                                as tcso,
               o2.id                                                         as tcso_id,
               tr1.title                                                     as cso,
               tr2.title                                                     as district_cso,
               cr.id                                                         as cr_id,
               pap.activity_id                                               as pap_activity_id
        from md.participant_activity_profile pap
               join reference.activity act1 on pap.activity_id = act1.id
               join reference.activity act2 on act2.id = act1.parent_id
               join reference.activity act3 on act3.id = act2.parent_id
               left join md.class_record cr
                         on pap.participant_id = cr.participant_id and pap.id = cr.participant_activity_profile_id
               left join md.class_record_status_registry crsr on cr.id = crsr.class_record_id and crsr.end_date isnull
               left join reference.class_record_status crs on crsr.class_record_status_id = crs.id
               left join md.groups g on cr.group_id = g.id
               left join md.group_status_registry gsr
                         on g.id = gsr.group_id and gsr.end_date isnull and gsr.is_expectation = false
               left join reference.group_status gs on gsr.status_id = gs.id
               left join md.organization o1 on g.organization_id = o1.id
               left join md.organization o2 on g.territory_centre_id = o2.id
               left join md.territory_organization torg on o2.id = torg.organization_id
               left join ar.territory tr1 on torg.territory_id = tr1.id
               left join ar.territory tr2 on tr1.parent_id = tr2.id
        --left join audit.participant_activity_profile_aud papa on pap.activity_id=papa.activity_id and pap.participant_id=papa.participant_id and papa.revtype=0
        --left join audit.revision r on papa.rev = r.id
      ),
      reg_cr as (
        select cr.id                                                                                      as cr_id,
               max(case when crsr.class_record_status_id = 1 then crsr.start_date else null end)          as crsr_dateb,
               max(
                 case when crsr.class_record_status_id = 2 then crsrr.title else null end)                as crsr_reason_stop,
               max(case when crsr.class_record_status_id in (4, 5, 8) then crsr.start_date else null end) as crsr_datee,
               max(case
                     when crsr.class_record_status_id in (4, 5, 8) then crsrr.title
                     else null end)                                                                       as crsr_reason_end
        from md.class_record cr
               join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
               left join reference.class_record_status_reason crsrr on crsr.reason = crsrr.id
        where crsr.class_record_status_id in (1, 2, 4, 5, 8)
        group by cr.id
      )
    select row_number() over ()                                                     as rn,
           concat(p.second_name, ' ', p.first_name, ' ', p.patronymic)              as "ФИО",
           p.id                                                                     as "Номер личного дела",
           to_char(p.date_of_birth, 'dd.mm.yyyy')                                   as "Дата рождения",
           substr(g.title, 1, 1)                                                    as "Пол",
           extract(year from justify_interval(current_timestamp - p.date_of_birth)) as "Возраст",
           tr1.title::text                                                          as "Район проживания",
           tr2.title::text                                                          as "Район регистрации",
           o.short_title::text                                                         "Краткое наименование ТЦСО создания ЛД",
           to_char(PSL.start_date, 'dd.mm.yyyy')                                    as "Дата создания ЛД",
           PSL.last_stt::text                                                       as "Статус ЛД",
           PSL.last_reason::text                                                    as "Причина отказа",
           ACT.level_1::text                                                        as "Направление 1-го уровня",
           ACT.level_2::text                                                        as "Направление 2-го уровня",
           ACT.level_3::text                                                        as "Направление 3-го уровня",
           to_char(ACT.date_from, 'dd.mm.yyyy')                                     as "Дата создания профиля активности",
           ''                                                                       as "ТЦСО - Организации Поставщика создания профиля активности",
           ACT.group_num                                                            as "Код группы",
           ACT.group_status::text                                                   as "Статус группы",
           ACT.cr_status::text                                                      as "Статус записи в группу",
           to_char(reg_cr.crsr_dateb, 'dd.mm.yyyy')                                 as "Дата зачисления",
           reg_cr.crsr_reason_stop::text                                            as "Причина приостановки",
           to_char(reg_cr.crsr_datee, 'dd.mm.yyyy')                                 as "Дата отчисления",
           reg_cr.crsr_reason_end::text                                             as "Причина отчисления",
           ACT.activity_type::text                                                  as "Признак онлайн",
           ACT.org_name::text                                                       as "Краткое наименование поставщика",
           ACT.tcso::text                                                           as "Краткое наименование ТЦСО координации группы",
           ACT.cso::text                                                            as "Район ЦСО  координации группы",
           ACT.district_cso::text                                                   as "Округ ТЦСО координации группы"
    from md.participant p
           join reference.gender g on p.gender = g.id
           left join ar.address_registry ar1 on p.fact_address = ar1.id
           left join ar.territory tr1 on ar1.district = tr1.id
           left join ar.address_registry ar2 on p.registration_address = ar2.id
           left join ar.territory tr2 on ar2.district = tr2.id
           left join md.organization o on p.organization_id = o.id
           left join PSL on p.id = PSL.participant_id
           left join ACT on p.id = ACT.participant_id
           left join reg_cr on ACT.cr_id = reg_cr.cr_id
    where ACT.activity_type = upper(sign_online)
      
      and ar1.adm_area in (select unnest(district_1))
      and ar2.adm_area in (select unnest(district_2))
      and ar1.district in (select unnest(district_3))
      and ar2.district in (select unnest(district_4))
      
      and ACT.tcso_id in (select unnest(tcso_1))
      and o.id in (select unnest(tcso_2))
      --and
      
      and PSL.last_stt_num in (select unnest(stt_1))
      and ACT.cr_status_num in (select unnest(stt_2))
      and ACT.group_status_num in (select unnest(stt_3))
      
      and ACT.act1_num in (select unnest(arr_act_1))
      and ACT.act2_num in (select unnest(arr_act_2))
      and ACT.act3_num in (select unnest(arr_act_3))
      
      --and p.id in (2945726, 514579)
    
    order by p.id;

end
$$;