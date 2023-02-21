drop function if exists rep.r10_datamart_cre;
create function rep.r10_datamart_cre() returns text
  security definer
  language plpgsql
as $$
DECLARE

BEGIN
  ----создаём таблицу витрины
create table if not exists rep.r10_datamart (
  participant_id              bigint,
  participant_json            jsonb,
  livingregion                bigint,
  registrationregion          bigint,
  creatortcso                 bigint,
  creationdate                date,
  participantstatus           text,
  rejectionreason text,
  activityprofilecreationdate timestamp,
  activitycreatortcso         text,
  group_id                    bigint,
  enrollmentdate              timestamp,
  stopreason                  text,
  leavingdate                 timestamp,
  leavingreason               text,
  providerid                  bigint,
  tcsoproviderregion          text,
  tcsoproviderdistrict        text,
  i_district_1                  bigint,
  i_district_2                  bigint,
  i_district_3                  bigint,
  i_district_4                  bigint,
  i_tcso_1                      bigint,
  i_tcso_3                      bigint,
  i_stt_1                       int,
  i_stt_2                       int,
  i_stt_3                       int,
  i_arr_act_1                   bigint,
  i_arr_act_2                   bigint,
  i_arr_act_3                   bigint,
  i_isonline text
);
  ---создаём индексы витрины
create index if not exists r10_datamart_participant_id_index on rep.r10_datamart (participant_id);
  ----
truncate table rep.r10_datamart;
insert into rep.r10_datamart
with
  PSL as (select distinct
                 psl.participant_id,
                 first_value(psl.start_date)
                 over (partition by psl.participant_id order by psl.start_date)                    as start_date,
                 first_value(ps.title) over (partition by psl.participant_id order by psl.id desc) as last_stt,
                 first_value(ps.id)
                 over (partition by psl.participant_id order by psl.id desc)                       as last_stt_num,
               first_value(case when ps.id in (1, 8) then psr.reason else null end)
               over (partition by psl.participant_id order by psl.id desc)                                as last_reason
          from reference.participant_status_log psl
                 join reference.participant_status ps on psl.status_id = ps.id
                 left join reference.participant_status_reason psr on psl.reason_id = psr.id),
  ACT as (select pap.participant_id,
                 act1.id                                                 as act1_num,
                 case when act1.parent_id isnull then 0 else act2.id end as act2_num,
                 case
                   when act1.parent_id isnull or act2.parent_id isnull then 0
                   else act3.id end                                      as act3_num,
                 pap.date_from,
                 cr.group_id                                             as group_id,
                 gsr.status_id                                           as group_status_num,
                 crsr.class_record_status_id                             as "cr_status_num",
               case when act1.activity_type = 6 then 'ДА' else 'НЕТ' end     as activity_type,
                 o1.id                                                   as org_id,
                 o2.id                                                   as tcso_id,
                 string_agg(distinct tr1.title, ', ')                    as cso,
                 string_agg(distinct tr2.title, ', ')                    as district_cso,
                 cr.id                                                   as cr_id,
                 pap.activity_id                                         as pap_activity_id,
                 max(cw_org.short_title)                                 as cw_org_name,
                 max(cw_org.id)                                          as cw_org_id
          from md.participant_activity_profile pap
                 left join reference.activity act1 on pap.activity_id = act1.id
                 left join reference.activity act2 on act2.id = act1.parent_id
                 left join reference.activity act3 on act3.id = act2.parent_id
                 left join md.class_record cr
                           on pap.participant_id = cr.participant_id and pap.id = cr.participant_activity_profile_id
                 left join md.class_record_status_registry crsr on cr.id = crsr.class_record_id and crsr.end_date isnull
                 left join md.groups g on cr.group_id = g.id
                 left join md.group_status_registry gsr
                           on g.id = gsr.group_id and gsr.end_date isnull and gsr.is_expectation = false
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
          where pap.status_id = 1
          group by pap.participant_id, act1.parent_id,
                   act1.id, act2.id, act2.parent_id, act3.id, pap.date_from, cr.group_id,
                   gsr.status_id, crsr.class_record_status_id,
                   o2.id, cr.id, pap.activity_id, pap.id,o1.id),
  reg_cr as (select cr.id                                                                            as cr_id,
                    min(crsr.start_date)                                                             as crsr_dateb,
                    max(case when crsr.class_record_status_id = 2 then crsrr.title end)              as crsr_reason_stop,
                    max(case when crsr.class_record_status_id in (4, 5, 8) then crsr.start_date end) as crsr_datee,
                    max(case when crsr.class_record_status_id in (4, 5, 8) then crsrr.title end)     as crsr_reason_end
             from md.class_record cr
                    join md.class_record_status_registry crsr on cr.id = crsr.class_record_id
                    left join reference.class_record_status_reason crsrr on crsr.reason = crsrr.id
             group by cr.id)
select p.id                                                                        as participant_id,
       jsonb_build_object('second_name', p.second_name, 'first_name', p.first_name, 'patronymic', p.patronymic,
                          'date_of_birth', to_char(p.date_of_birth, 'dd.mm.yyyy'),'gender',substr(g.title, 1, 1)) as participant_json,
       tr1.id                                                                      as livingregion,
       tr2.id                                                                      as registrationregion,
       o.id                                                                        as creatortcso,
       PSL.start_date                                                              as creationdate,
       PSL.last_stt::text                                                          as participantstatus,
       PSL.last_reason::text                                                    as rejectionreason,
       ACT.date_from                                                               as activityprofilecreationdate,
       ACT.cw_org_name::text                                                       as activitycreatortcso,
       ACT.group_id,
       reg_cr.crsr_dateb                                                           as enrollmentdate,
       reg_cr.crsr_reason_stop::text                                                  stopreason,
       reg_cr.crsr_datee                                                           as leavingdate,
       reg_cr.crsr_reason_end::text                                                as leavingreason,
       ACT.org_id                                                                  as providerid,
       ACT.cso::text                                                               as tcsoproviderregion,
       ACT.district_cso::text                                                      as tcsoproviderdistrict,
       ar1.adm_area,
       ar2.adm_area,
       ar1.district,
       ar2.district,
       ACT.tcso_id,
       ACT.cw_org_id,
       PSL.last_stt_num,
       ACT.cr_status_num,
       ACT.group_status_num,
       ACT.act1_num                                                                as act_l1,
       ACT.act2_num                                                                as act_l2,
       ACT.act3_num                                                                as act_l3,
       ACT.activity_type as isonline
from md.participant p
       left join reference.gender g on p.gender = g.id
       left join ar.address_registry ar1 on p.fact_address = ar1.id
       left join ar.territory tr1 on ar1.district = tr1.id
       left join ar.address_registry ar2 on p.registration_address = ar2.id
       left join ar.territory tr2 on ar2.district = tr2.id
       left join md.organization o on p.organization_id = o.id
       left join PSL on p.id = PSL.participant_id
       join ACT on p.id = ACT.participant_id
       left join reg_cr on ACT.cr_id = reg_cr.cr_id
  --limit 1
  ;
  ----
  --execute 'vacuum analyse rep.r10_datamart';
  ----
	return 'success';
  --exception when others then return 'error';
END;
$$;