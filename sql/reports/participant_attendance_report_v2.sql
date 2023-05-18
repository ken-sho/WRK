drop function if exists public.participant_attendance_report_v2;
create function public.participant_attendance_report_v2(
  p_date_from        date default null::date, p_date_to date default null::date,
  p_area_ids         bigint[] default array []::integer[], p_district_ids bigint[] default array []::integer[],
  p_tcso_s_ch_ids    bigint[] default array []::integer[], p_tcso_coordinators_ids bigint[] default array []::integer[],
  p_tcso_creator_ids bigint[] default array []::integer[], p_uszn_ids bigint[] default array []::integer[],
  p_provider_ids     bigint[] default array []::integer[], p_limit_value integer default null::integer,
  p_offset_value     bigint default null::bigint)
  returns TABLE (
    id                           bigint,
    fio_participant              text,
    tel                          text,
    participant_last_status      character varying,
    cr_last_status               character varying,
    date_enrolled                date,
    cso_short_title              character varying,
    tcso_district                text,
    tcso_area                    character varying,
    supplier_short_title         character varying,
    supplier_dept                character varying,
    contract_number              character varying,
    activity_title_l1            character varying,
    activity_title_l2            character varying,
    activity_title_l3            character varying,
    group_code                   text,
    tc_short_title               character varying,
    group_status                 character varying,
    fio_coordinator              text,
    list_teachers_fio            text,
    cnt_lesson                   bigint,
    cnt_attended                 bigint,
    cnt_with_skm                 bigint,
    cnt_without_skm              bigint,
    cnt_web_coordinator          bigint,
    cnt_system_auto_confirmation bigint,
    cnt_missed                   bigint,
    percent_attendance           numeric,
    status_attendance            text
  )
  language plpgsql
as $$
declare
  i_p_date_from date;
  i_p_date_to   date;
  uszn_arr bigint[];
begin
  i_p_date_from := coalesce(p_date_from, '2019-01-01'::date);
  i_p_date_to := coalesce(p_date_to, '2099-01-01'::date);
  ----p_uszn_ids предвыбор ID
  select array_agg(t.id)
  into uszn_arr
  from (select o4.id
        from md.organization o4
        where
          /* grand child */
            o4.parent_organization_id in
            ((select o5.id from md.organization o5 where (parent_organization_id in (select unnest(p_uszn_ids)))))
           or
          /* direct child */
            o4.id in
            (select o6.id from md.organization o6 where (parent_organization_id in (select unnest(p_uszn_ids))))) t;
  ----
  return query
    with
      pc_tel as (select pc.owner_id,
                        string_agg(pc.value, '; ' order by pc.priority nulls last) as tel
                 from md.participant_contact pc
                 where pc.contact_type_id = 1
                 group by pc.owner_id),
      p_status as (select distinct
                          psl.participant_id,
                          first_value(ps.title)
                          over (partition by psl.participant_id order by psl.start_date desc) as last_title
                   from reference.participant_status_log psl
                          join reference.participant_status ps on
                           psl.status_id = ps.id
                         and coalesce(psl.end_date::date, i_p_date_from) between i_p_date_from /*PARAM Дата С*/
                             and i_p_date_to /*PARAM Дата по*/
      ),
      cr_status as (select distinct
                           crsr.class_record_id,
                           first_value(crs.title)
                           over (partition by crsr.class_record_id order by crsr.start_date desc) as last_title
                    from reference.class_record_status crs
                           join md.class_record_status_registry crsr on
                            crs.id = crsr.class_record_status_id
                          and coalesce(crsr.end_date::date, i_p_date_from) between i_p_date_from /*PARAM Дата С*/
                              and i_p_date_to /*PARAM Дата по*/
      ),
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
                   where l.lesson_date between i_p_date_from /*PARAM Дата С*/
                           and i_p_date_to /*PARAM Дата по*/
                   group by l.group_id),
      attendance as (select ad.id, ad."source", ad.user_role, crsr.class_record_id, l.id as lesson_id
                     from md.attendance_data ad
                            join md.lesson l on
                             l.id = ad.lesson_id
                           and l.lesson_date between i_p_date_from /*PARAM Дата С*/
                               and i_p_date_to /*PARAM Дата по*/
                           and ad.attendance_data_type = 'CONFIRMED'
                            join md.class_record cr on
                         cr.group_id = l.group_id
                            join md.class_record_status_registry crsr on
                             crsr.class_record_id = cr.id
                           and crsr.class_record_status_id = 6
                           and l.lesson_date between crsr.start_date::date
                               and coalesce(crsr.end_date::date, now())),
      attendance_stat as (select s.*,
                                 s.cnt_lesson - s.cnt_attended                                as cnt_missed,
                                 round(s.cnt_attended::numeric / s.cnt_lesson::numeric * 100) as percent_attendance
                          from (select t.*,
                                       (case
                                          when (t.cnt_with_skm + t.cnt_without_skm) > 0
                                            then (t.cnt_with_skm + t.cnt_without_skm)
                                          when (t.cnt_web_coordinator + t.cnt_system_auto_confirmation) > 0 then
                                            (t.cnt_web_coordinator + t.cnt_system_auto_confirmation)
                                          else 0 end) as cnt_attended
                                from (select a.class_record_id,
                                             count(distinct a.lesson_id)                as cnt_lesson,
                                             --sum(case when lal.presence_mark = true then 1 else 0 end) as cnt_attended,
                                             count(distinct (case
                                                               when lal.presence_mark = true and lal."method" = 'SCANNING'
                                                                 then a.lesson_id end)) as cnt_with_skm,
                                             count(distinct (case
                                                               when lal.presence_mark = true and lal."method" = 'MANUAL'
                                                                 then a.lesson_id end)) as cnt_without_skm,
                                             count(distinct (case
                                                               when lal.presence_mark = true and
                                                                    lal."method" = 'MANUAL' and
                                                                    a."source" = 'WEB' and
                                                                    a.user_role = 'COORDINATOR'
                                                                 then a.lesson_id end)) as cnt_web_coordinator,
                                             count(distinct (case
                                                               when lal.presence_mark = true and
                                                                    lal."method" in ('MANUAL', 'SCANNING') and
                                                                    a."source" = 'SYSTEM' and
                                                                    a.user_role = 'SYSTEM'
                                                                 then a.lesson_id end)) as cnt_system_auto_confirmation
                                      from attendance a
                                             left join md.lesson_attendance_list lal on
                                              a.id = lal.attendance_data_id
                                            and a.class_record_id = lal.class_record_id
                                      group by a.class_record_id) t) s)
    select distinct
      /*Номер личного дела*/
           p.id,
      /*ФИО*/
           trim(p.second_name || ' ' || p.first_name || ' ' || p.patronymic)     as fio_participant,
      /*Телефон*/
           pc_tel.tel,
      /*Статус ЛД участника*/
           p_status.last_title                                                   as participant_last_status,
      /*Статус записи участника в группе*/
           cr_status.last_title                                                  as cr_last_status,
      /*Дата зачисления участника в группу*/
           cr_date.crsr_start_date                                               as date_enrolled,
      /*Краткое наименование ЦСО*/
           o.short_title                                                         as cso_short_title,
      /*Район*/
           case when tt.parent_id is not null then tt.title end                  as tcso_district,
      /*Округ*/
           t2.title                                                              as tcso_area,
      /*Краткое наименование организации поставщика*/
           o2.short_title                                                        as supplier_short_title,
      /*Ведомство организации-поставщика*/
           d.title                                                               as supplier_dept,
      /*Номер соглашения */
           c.contract_number,
      /*Направление  1 уровня*/
           a1.title                                                              as activity_title_L1,
      /*Направление 2 уровня*/
           a2.title                                                              as activity_title_L2,
      /*Направление 3 уровня*/
           a3.title                                                              as activity_title_L3,
      /*Код группы*/
           'G-' || (lpad(cr.group_id::text, 8, '0'))::varchar                    as group_code,
      /*Краткое наименование ТЦСО координации группы*/
           o3.short_title                                                        as tc_short_title,
      /*Статус группы*/
           gs.title                                                              as group_status,
      /*ФИО координатора*/
           trim(c2.second_name || ' ' || c2.first_name || ' ' || c2.middle_name) as fio_coordinator,
      /*ФИО преподавателя группы*/
           teachers.tfio                                                         as list_teachers_fio,
      /*Занятий проведено*/
           a_stat.cnt_lesson                                                     as cnt_lesson,
      /*Занятий посещено: Всего */
           a_stat.cnt_attended,
      /*С СКМ*/
           a_stat.cnt_with_skm,
      /*Без СКМ. Отметка в МП*/
           a_stat.cnt_without_skm,
      /*Без СКМ. Отметка координатором в КИС МД*/
           a_stat.cnt_web_coordinator,
      /*Без СКМ. Отметка поставщиком в КИС МД*/
      /*Системное автоподтверждение*/
           a_stat.cnt_system_auto_confirmation,
      /*Занятий пропущено*/
           a_stat.cnt_missed,
      /*Посещаемость, %*/
           a_stat.percent_attendance,
      /*Статус посещаемости*/
           case
             when a_stat.percent_attendance >= 80 and a_stat.percent_attendance <= 100 then 'Регулярно посещает занятия'
             when a_stat.percent_attendance >= 50 and a_stat.percent_attendance < 80 then 'Часто посещает занятия'
             when a_stat.percent_attendance >= 30 and a_stat.percent_attendance < 50 then 'Редко посещает занятия'
             when a_stat.percent_attendance >= 0 and a_stat.percent_attendance < 30 then 'Часто пропускает занятия'
             end                                                                 as status_attendance
    from md.participant p
           left join pc_tel on pc_tel.owner_id = p.id
           left join p_status on p_status.participant_id = p.id
           left join md.organization o on o.id = p.organization_id
           left join md.class_record cr on cr.participant_id = p.id
           left join cr_status on cr_status.class_record_id = cr.id
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
           left join md.territory_organization torg on g.territory_centre_id = torg.organization_id
           left join teachers on teachers.group_id = g.id
           join attendance_stat a_stat on a_stat.class_record_id = cr.id
    where (case
             when p_district_ids[1] isnull then true
             else
                 p.organization_id in (select to2.organization_id
                                       from md.territory_organization to2
                                              join ar.territory t on t.id = to2.territory_id and t.parent_id is not null
                                              join unnest(p_district_ids) un on t.id = un.un)
      end)
      and (case
             when p_area_ids[1] isnull then true
             else
               t2.id in (select unnest(p_area_ids)) /*PARAM Округ*/
      end)
      and ((case
              when p_tcso_s_ch_ids[1] isnull then true
              else ar.district in (select distinct to3.territory_id
                                   from md.territory_organization to3
                                   where to3.organization_id in (select unnest(p_tcso_s_ch_ids)) /*PARAM ТЦСО ("свой-чужой")*/
              )
      end)
      or (case
            when p_tcso_s_ch_ids[1] isnull then true
            else torg.territory_id in (select distinct to4.territory_id
                                       from md.territory_organization to4
                                       where to4.organization_id in (select unnest(p_tcso_s_ch_ids)) /*PARAM ТЦСО ("свой-чужой")*/
            )
        end))
      
      and (case
             when p_tcso_coordinators_ids[1] isnull then true
             else o3.id in (select unnest(p_tcso_coordinators_ids)) /*PARAM ТЦСО (координатор группы)*/
      end)
      and (case
             when p_tcso_creator_ids[1] isnull then true
             else o.id in (select unnest(p_tcso_creator_ids)) /*PARAM ТЦСО (создатель личного дела)*/
      end)
      and (case
             when p_uszn_ids[1] isnull then true
             else g.territory_centre_id in (select u.u from unnest(uszn_arr)u)/**/
      end)
      and (case
             when p_provider_ids[1] isnull then true
             else o2.id in (select unnest(p_provider_ids)) /*PARAM Организация поставщика*/
      end)
      /*order by trim(p.second_name || ' ' || p.first_name || ' ' || p.patronymic), cr.group_id
    group by p.id,p.second_name,p.first_name,p.patronymic,pc_tel.tel,p_status.last_title,
      cr_status.last_title,cr_date.crsr_start_date,o.short_title,tt.parent_id,tt.title,
      t2.title,o2.short_title,d.title,c.contract_number,a1.title,a2.title,a3.title,
      cr.group_id,o3.short_title,gs.title,c2.second_name,c2.first_name,c2.middle_name,
      teachers.tfio,a_stat.cnt_lesson,a_stat.cnt_attended,a_stat.cnt_with_skm,a_stat.cnt_without_skm,
      a_stat.cnt_web_coordinator,a_stat.cnt_system_auto_confirmation,a_stat.cnt_missed,a_stat.percent_attendance*/
    limit p_limit_value offset p_offset_value;
end;
$$;