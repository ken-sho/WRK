drop function if exists rep.participant_attendance_report_datamart_cre;
create function rep.participant_attendance_report_datamart_cre() returns text
  security definer
  language plpgsql
as $$
declare

begin
  ----создаём таблицу витрины
  create table if not exists rep.participant_attendance_datamart (
    participant_id            bigint,
    participant_json          jsonb,
    date_enrolled             date,
    cso_short_title           text,
    tcso_district             text,
    tcso_area                 text,
    supplier_short_title      text,
    supplier_dept             text,
    contract_number           text,
    activity_title_L1         text,
    activity_title_L2         text,
    activity_title_L3         text,
    group_code                text,
    group_id                  bigint,
    tc_short_title            text,
    group_status              text,
    fio_coordinator           text,
    list_teachers_fio         text,
    i_p_district_ids          bigint,
    i_p_area_ids              bigint,
    i_p_tcso_s_ch_ids_1       bigint,
    territory_centre_id       bigint,
    --i_p_tcso_s_ch_ids_2       bigint,
    i_p_tcso_coordinators_ids bigint,
    i_p_tcso_creator_ids      bigint,
    i_p_provider_ids          int
  );
  ---создаём индексы витрины
  create index if not exists participant_attendance_datamart_participant_id_index on rep.participant_attendance_datamart (participant_id);
  create index participant_attendance_datamart_group_id_index on rep.participant_attendance_datamart (group_id);
  ----
  truncate table rep.participant_attendance_datamart;
  insert into rep.participant_attendance_datamart
  with
    pc_tel as (select pc.owner_id,
                      string_agg(pc.value, '; ' order by pc.priority nulls last) as tel
               from md.participant_contact pc
               where pc.contact_type_id = 1
               group by pc.owner_id),
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
                when crsr2.end_date isnull and cr_date_L0.arr_sd1[2] is not null  then cr_date_L0.arr_sd1[2]
                when array_length(cr_date_L0.arr_sd1, 1) = 1 then cr_date_L0.arr_sd2[1]
                else crsr2.end_date
               end)::date as crsr_start_date
      from cr_date_L0
             join md.class_record_status_registry crsr2 on cr_date_L0.arr_sd1_id[1] = crsr2.id
      where array_length(cr_date_L0.arr_stt, 1) > 1
        and array_length(cr_date_L0.arr_sd2, 1) is not null
      union all
      ---(6)3.1.2.2/4/5
      select cr_date_L0.class_record_id,
             coalesce(cr_date_L0.arr_sd1[1], cr_date_L0.arr_sd2[1])::date
               as crsr_start_date
      from cr_date_L0
      where (cr_date_L0.arr_stt[1] in (4, 5) and array_length(cr_date_L0.arr_stt, 1) = 1)
         or array_length(cr_date_L0.arr_sd1, 1) isnull),
    terr_district as (select to2.organization_id,
                             t.parent_id,
                             string_agg(t.title, ', ' order by t.title) as title
                      from md.territory_organization to2
                             join ar.territory t on
                          t.id = to2.territory_id
                      group by to2.organization_id, t.parent_id),
    teachers as (select l.group_id,
                        string_agg(distinct trim(concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name)),
                                   ', ') as tfio
                 from md.lesson l
                        join md.schedule_timesheet_coworkers stc on l.id = stc.lesson_id
                        join md.coworker cw on stc.coworker_id = cw.id
                 group by l.group_id)
  select distinct
         p.id                                                                  as pid,
         jsonb_build_object('second_name', p.second_name, 'first_name', p.first_name, 'patronymic', p.patronymic,
                            'pc_tel', pc_tel.tel)                              as participant_json,
         cr_date.crsr_start_date                                               as date_enrolled,
         o.short_title                                                         as cso_short_title,
         case when tt.parent_id is not null then tt.title end                  as tcso_district,
         t2.title                                                              as tcso_area,
         o2.short_title                                                        as supplier_short_title,
         d.title                                                               as supplier_dept,
         c.contract_number,
         a1.title                                                              as activity_title_L1,
         a2.title                                                              as activity_title_L2,
         a3.title                                                              as activity_title_L3,
         'G-' || (lpad(cr.group_id::text, 8, '0'))::varchar                    as group_code,
         cr.group_id,
         o3.short_title                                                        as tc_short_title,
         gs.title                                                              as group_status,
         trim(c2.second_name || ' ' || c2.first_name || ' ' || c2.middle_name) as fio_coordinator,
         teachers.tfio                                                         as list_teachers_fio,
         p.organization_id                                                     as i_p_district_ids,
         t2.id                                                                 as i_p_area_ids,
         ar.district                                                           as i_p_tcso_s_ch_ids_1,
         g.territory_centre_id,
         o3.id                                                                 as i_p_tcso_coordinators_ids,
         o.id                                                                  as i_p_tcso_creator_ids,
         o2.id                                                                 as i_p_provider_ids
  from md.participant p
         left join pc_tel on pc_tel.owner_id = p.id
         left join md.organization o on o.id = p.organization_id
         left join md.class_record cr on cr.participant_id = p.id
         left join cr_date on cr_date.class_record_id = cr.id
         left join terr_district tt on tt.organization_id = p.organization_id and tt.parent_id is not null
         left join ar.territory t2 on t2.id = tt.parent_id
         left join md."groups" g on g.id = cr.group_id
         left join md.organization o2 on o2.id = g.organization_id
         left join reference.department d on d.id = o2.department_id
         left join md.contract c on c.id = g.contract_id
         left join reference.activity a3 on a3.id = g.activity_id
         left join reference.activity a2 on a2.id = a3.parent_id
         left join reference.activity a1 on a1.id = a2.parent_id
         left join md.organization o3 on o3.id = g.territory_centre_id
         left join md.group_status_registry gsr
                   on gsr.group_id = g.id and gsr.end_date is null and gsr.is_expectation = false
         left join reference.group_status gs on gs.id = gsr.status_id
         left join md.coworker c2 on c2.id = g.coworker_id
         left join ar.address_registry ar on coalesce(p.fact_address, p.registration_address) = ar.id
         left join teachers on teachers.group_id = g.id
  ;
  return 'success';
exception
  when others then return 'error';
end;
$$;