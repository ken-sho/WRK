drop function if exists public.report_pab_r10;
create function public.report_pab_r10(
  district_1  bigint[] default array []::integer[], district_2 bigint[] default array []::integer[],
  district_3  bigint[] default array []::integer[], district_4 bigint[] default array []::integer[],
  tcso_1      bigint[] default array []::integer[], tcso_2 bigint[] default array []::integer[],
  tcso_3      bigint[] default array []::integer[], stt_1 bigint[] default array []::integer[],
  stt_2       bigint[] default array []::integer[], stt_3 bigint[] default array []::integer[],
  sign_online text default ''::text, arr_act_1 bigint[] default array []::integer[],
  arr_act_2   bigint[] default array []::integer[], arr_act_3 bigint[] default array []::integer[])
  returns TABLE (
    rownum                      bigint,
    fio                         text,
    participantid               bigint,
    dateofbirth                 text,
    gender                      text,
    age                         double precision,
    livingregion                text,
    registrationregion          text,
    creatortcso                 text,
    creationdate                text,
    participantstatus           text,
    rejectionreason             text,
    firstlevelactivity          text,
    secondlevelactivity         text,
    thirdlevelactivity          text,
    activityprofilecreationdate text,
    activitycreatortcso         text,
    groupid                     text,
    groupstatus                 text,
    classrecordstatus           text,
    enrollmentdate              text,
    stopreason                  text,
    leavingdate                 text,
    leavingreason               text,
    isonline                    text,
    providershortname           text,
    tcsoprovidershortname       text,
    tcsoproviderregion          text,
    tcsoproviderdistrict        text
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
               act1.title                                                    as level_3,
               case when act1.parent_id isnull then null else act2.title end as level_2,
               case
                 when act1.parent_id isnull or act2.parent_id isnull then null
                 else act3.title end                                         as level_1,
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
               string_agg(distinct tr1.title, ', ')                          as cso,-----------------!!!
               string_agg(distinct tr2.title, ', ')                          as district_cso,
               cr.id                                                         as cr_id,
               pap.activity_id                                               as pap_activity_id,
               max(cw_org.short_title)                                       as cw_org_name,
               max(cw_org.id)                                                as cw_org_id
        from md.participant_activity_profile pap
               left join reference.activity act1 on pap.activity_id = act1.id
               left join reference.activity act2 on act2.id = act1.parent_id
               left join reference.activity act3 on act3.id = act2.parent_id
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
               left join ar.territory tr1 on torg.territory_id = tr1.id and tr1.parent_id is not null
               left join ar.territory tr2 on tr1.parent_id = tr2.id
               left join audit.participant_activity_profile_aud papa
                         on pap.activity_id = papa.activity_id and pap.participant_id = papa.participant_id and
                            papa.revtype = 0
               left join audit.revision r on papa.rev = r.id
               left join md.user_profile up on r.user_id = up.id
               left join md.coworker cw on up.coworker_id = cw.id
               left join md.organization cw_org on cw.organization_id = cw_org.id
        group by pap.participant_id, act1.title, act1.parent_id, act2.title, act3.title,
                 act1.id, act2.id, act2.parent_id, act3.id, pap.date_from, cr.group_id,
                 gs.title, gs.id, crs.title, crs.id, act1.activity_type, o1.short_title,
                 o2.short_title, o2.id, cr.id, pap.activity_id
      ),
      reg_cr as (
        select cr.id                                                                                      as cr_id,
               min(crsr.start_date)                                                                       as crsr_dateb,
               max(
                 case when crsr.class_record_status_id = 2 then crsrr.title else null end)                as crsr_reason_stop,
               max(case when crsr.class_record_status_id in (4, 5, 8) then crsr.start_date else null end) as crsr_datee,
               max(case
                     when crsr.class_record_status_id in (4, 5, 8) then crsrr.title
                     else null end)                                                                       as crsr_reason_end
        from md.class_record cr
               join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
               left join reference.class_record_status_reason crsrr on crsr.reason = crsrr.id
             --where crsr.class_record_status_id in (1, 2, 4, 5, 8)
        group by cr.id
      )
    select row_number() over (order by p.id)                                                     as rn,
           concat(p.second_name, ' ', p.first_name, ' ', p.patronymic)              as "ФИО",
           p.id                                                                     as "Номер личного дела",
           to_char(p.date_of_birth, 'dd.mm.yyyy')                                   as "Дата рождения",
           substr(g.title, 1, 1)                                                    as "Пол",
           extract(year from justify_interval(current_timestamp - p.date_of_birth)) as "Возраст",
           tr1.title::text                                                          as "Район проживания",
           tr2.title::text                                                          as "Район регистрации",
           o.short_title::text                                                         "Краткое наименование ТЦСО создания ЛД",
           to_char(PSL.start_date, 'dd.mm.yyyy HH24:MI')                                    as "Дата создания ЛД",
           PSL.last_stt::text                                                       as "Статус ЛД",
           PSL.last_reason::text                                                    as "Причина отказа",
           case
             when ACT.level_1 isnull and ACT.level_2 isnull then ACT.level_3::text
             when ACT.level_1 isnull and ACT.level_2 is not null then ACT.level_2::text
             else ACT.level_1::text end                                             as "Направление 1-го уровня",
           case
             when ACT.level_1 isnull and ACT.level_2 is not null then ACT.level_3::text
             else ACT.level_2::text end                                             as "Направление 2-го уровня",
           case when ACT.level_1 isnull then null else ACT.level_3::text end        as "Направление 3-го уровня",
           to_char(ACT.date_from, 'dd.mm.yyyy HH24:MI')                             as "Дата создания профиля активности",
           ACT.cw_org_name::text                                                    as "ТЦСО - Организации Поставщика создания профиля активности",
           ACT.group_num                                                            as "Код группы",
           ACT.group_status::text                                                   as "Статус группы",
           ACT.cr_status::text                                                      as "Статус записи в группу",
           to_char(reg_cr.crsr_dateb, 'dd.mm.yyyy HH24:MI')                                 as "Дата зачисления",
           reg_cr.crsr_reason_stop::text                                            as "Причина приостановки",
           to_char(reg_cr.crsr_datee, 'dd.mm.yyyy HH24:MI')                                 as "Дата отчисления",
           reg_cr.crsr_reason_end::text                                             as "Причина отчисления",
           ACT.activity_type::text                                                  as "Признак онлайн",
           ACT.org_name::text                                                       as "Краткое наименование поставщика",
           ACT.tcso::text                                                           as "Краткое наименование ТЦСО координации группы",
           ACT.cso::text                                                            as "Район ЦСО  координации группы",
           ACT.district_cso::text                                                   as "Округ ТЦСО координации группы"
    from md.participant p
           left join reference.gender g on p.gender = g.id
           left join ar.address_registry ar1 on p.fact_address = ar1.id
           left join ar.territory tr1 on ar1.district = tr1.id
           left join ar.address_registry ar2 on p.registration_address = ar2.id
           left join ar.territory tr2 on ar2.district = tr2.id
           left join md.organization o on p.organization_id = o.id
           left join PSL on p.id = PSL.participant_id
           left join ACT on p.id = ACT.participant_id
           left join reg_cr on ACT.cr_id = reg_cr.cr_id
    where (case
             when district_1[1] isnull then true
             else
               ar1.adm_area in (select * from unnest(district_1)) end)
      and (case
             when district_2[1] isnull then true
             else
               ar2.adm_area in (select * from unnest(district_2)) end)
      and (case
             when district_3[1] isnull then true
             else
               ar1.district in (select * from unnest(district_3)) end)
      and (case
             when district_4[1] isnull then true
             else
               ar2.district in (select * from unnest(district_4)) end)
      
      and (case
             when tcso_1[1] isnull then true
             else
               ACT.tcso_id in (select * from unnest(tcso_1)) end)
      and (case
             when tcso_2[1] isnull then true
             else
               o.id in (select * from unnest(tcso_2)) end)
      and (case
             when tcso_3[1] isnull then true
             else
               ACT.cw_org_id in (select * from unnest(tcso_3)) end)
      
      and (case
             when stt_1[1] isnull then true
             else
               PSL.last_stt_num in (select * from unnest(stt_1)) end)
      and (case
             when stt_2[1] isnull then true
             else
               ACT.cr_status_num in (select * from unnest(stt_2)) end)
      and (case
             when stt_3[1] isnull then true
             else
               ACT.group_status_num in (select * from unnest(stt_3)) end)
      
      and (case
             when arr_act_1[1] isnull then true
             else
               ACT.act1_num in (select * from unnest(arr_act_1)) end)
      and (case
             when arr_act_2[1] isnull then true
             else
               ACT.act2_num in (select * from unnest(arr_act_2)) end)
      and (case
             when arr_act_3[1] isnull then true
             else
               ACT.act3_num in (select * from unnest(arr_act_3)) end)
      
      and coalesce(ACT.activity_type,'') = (case when upper(sign_online) = '' then coalesce(ACT.activity_type,'') else upper(sign_online) end)

  
  --and p.id in (2945726, 514579)*/
   order by p.id
  ;

end
$$;