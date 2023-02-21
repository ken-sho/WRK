drop function if exists rep.participant_prioritization_report_datamart_cre;
create function rep.participant_prioritization_report_datamart_cre() returns text
  security definer
  language plpgsql
as $$
declare

begin
  ----создаём таблицу витрины
  create table if not exists rep.participant_prioritization_datamart (
    id                   bigserial not null constraint participant_prioritization_datamart_pk primary key,
    participant_id       bigint,
    fio                  text,
    create_date          timestamp,
    group_code           text,
    group_id             bigint,
    supplier_dept        text,
    supplier_name        text,
    activity_title_L1    text,
    activity_title_L2    text,
    activity_title_L3    text,
    enrollment_date      timestamp,
    creator_tcso         text,
    creator_tcso_id      bigint,
    fio_coordinator      text,
    init_enrollment_tcso text
  );
  ---создаём индексы витрины
  create index if not exists participant_prioritization_datamart_id_index on rep.participant_prioritization_datamart (id);
  create index if not exists participant_prioritization_datamart_participant_id_index on rep.participant_prioritization_datamart (participant_id);
  create index if not exists participant_prioritization_datamart_group_id_index on rep.participant_prioritization_datamart (group_id);
  create index if not exists participant_prioritization_datamart_enrollment_date_index on rep.participant_prioritization_datamart (enrollment_date);
  ----
  truncate table rep.participant_prioritization_datamart;
  insert into rep.participant_prioritization_datamart(participant_id, fio, create_date,
  group_code,group_id,supplier_dept,supplier_name,activity_title_L1,activity_title_L2,
  activity_title_L3,enrollment_date,creator_tcso,creator_tcso_id,
  fio_coordinator,init_enrollment_tcso)
  with
    pls_cre as (select psl.participant_id,
                       min(psl.start_date) as date_cre
                from reference.participant_status_log psl
                group by psl.participant_id),
    cr_date_L0 as ( ---(6)1/2
      select crsr.class_record_id,
             array_agg(crsr.class_record_status_id order by crsr.id) as arr_stt,
             array_remove(array_agg(
                            (case
                               when crsr.class_record_status_id in (4, 5)
                                 then crsr.start_date end)
                            order by crsr.start_date desc), null)    as arr_sd1,
             array_remove(array_agg(
                            (case
                               when crsr.class_record_status_id in (4, 5)
                                 then crsr.id end)
                            order by crsr.start_date desc), null)    as arr_sd1_id,
             array_remove(array_agg(
                            (case
                               when crsr.class_record_status_id in (1, 2, 3, 6, 7)
                                 then crsr.start_date end)
                            order by crsr.start_date), null)         as arr_sd2
      from md.class_record_status_registry crsr
      where crsr.class_record_status_id in (4, 5, 1, 2, 3, 6, 7)
      group by crsr.class_record_id),
    cr_date as (---(6)3.1.1/3.1.2.1
      select cr_date_L0.class_record_id,
             (case
                when crsr2.end_date isnull then cr_date_L0.arr_sd1[2]
                else crsr2.end_date
               end) as crsr_start_date
      from cr_date_L0
             join md.class_record_status_registry crsr2 on cr_date_L0.arr_sd1_id[1] = crsr2.id
      where array_length(cr_date_L0.arr_stt, 1) > 1
        and array_length(cr_date_L0.arr_sd2, 1) is not null
      union all
      ---(6)3.1.2.2/4/5
      select cr_date_L0.class_record_id,
             coalesce(cr_date_L0.arr_sd1[1], cr_date_L0.arr_sd2[1])
               as crsr_start_date
      from cr_date_L0
      where (cr_date_L0.arr_stt[1] in (4, 5) and array_length(cr_date_L0.arr_stt, 1) = 1)
         or array_length(cr_date_L0.arr_sd1, 1) isnull)
  select distinct
         p.id,
         trim(concat(p.second_name, ' ', p.first_name, ' ', p.patronymic))     as fio,
         pls_cre.date_cre                                                      as create_date,
         'G-' || (lpad(g.id::text, 8, '0'))                                    as group_code,
         g.id                                                                  as group_id,
         d.title                                                               as supplier_dept,
         o.short_title                                                         as supplier_name,
         a1.title                                                              as activity_title_l1,
         a2.title                                                              as activity_title_l2,
         a3.title                                                              as activity_title_L3,
         cr_date.crsr_start_date                                               as enrollment_date,
         o2.short_title                                                        as creator_tcso,
         o2.id                                                                 as creator_tcso_id,
         trim(concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name)) as fio_coordinator,
         o3.short_title                                                        as init_enrollment_tcso
  from md.participant p
         left join pls_cre on p.id = pls_cre.participant_id
         left join md.class_record cr on p.id = cr.participant_id
         left join md.groups g on cr.group_id = g.id
         left join md.organization o on g.organization_id = o.id
         left join md.organization o2 on g.territory_centre_id = o2.id
         --left join md.territory_organization torg on o2.id = torg.organization_id
         --left join ar.territory tr1 on torg.territory_id = tr1.id
         --left join ar.territory tr2 on tr1.parent_id = tr2.id
         left join reference.department d on o.department_id = d.id
         left join reference.activity a3 on a3.id = g.activity_id
         left join reference.activity a2 on a2.id = a3.parent_id
         left join reference.activity a1 on a1.id = a2.parent_id
         left join cr_date on cr.id = cr_date.class_record_id
         left join md.coworker cw on g.coworker_id = cw.id
         left join md.organization o3 on cw.organization_id = o3.id
  --limit 1
  ;
  ----
  ----
  return 'success';
  exception when others then return 'error';
end;
$$;