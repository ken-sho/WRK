drop function if exists rep.participant_attendance_view;
create function rep.participant_attendance_view(
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
    cso_short_title              text,
    tcso_district                text,
    tcso_area                    text,
    supplier_short_title         text,
    supplier_dept                text,
    contract_number              text,
    activity_title_l1            text,
    activity_title_l2            text,
    activity_title_l3            text,
    group_code                   text,
    tc_short_title               text,
    group_status                 text,
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
begin
  i_p_date_from := coalesce(p_date_from, '2019-01-01'::date);
  i_p_date_to := coalesce(p_date_to, '2099-01-01'::date);
  return query
    with
      p_status as (select distinct
                          psl.participant_id,
                          first_value(ps.title)
                          over (partition by psl.participant_id order by psl.start_date desc) as last_title
                   from reference.participant_status_log psl
                          join reference.participant_status ps on
                           psl.status_id = ps.id
                         and coalesce(psl.end_date::date, i_p_date_from) between i_p_date_from /*PARAM ???????? ??*/
                             and i_p_date_to /*PARAM ???????? ????*/
      ),
      cr_status as (select distinct
                           crsr.class_record_id,
                           first_value(crs.title)
                           over (partition by crsr.class_record_id order by crsr.start_date desc) as last_title
                    from reference.class_record_status crs
                           join md.class_record_status_registry crsr on
                            crs.id = crsr.class_record_status_id
                          and coalesce(crsr.end_date::date, i_p_date_from) between i_p_date_from /*PARAM ???????? ??*/
                              and i_p_date_to /*PARAM ???????? ????*/
      ),
      attendance as (select ad.id, ad."source", ad.user_role, crsr.class_record_id, l.id as lesson_id
                     from md.attendance_data ad
                            join md.lesson l on
                             l.id = ad.lesson_id
                           and l.lesson_date between i_p_date_from /*PARAM ???????? ??*/
                               and i_p_date_to /*PARAM ???????? ????*/
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
      /*?????????? ?????????????? ????????*/
           pad.participant_id,
      /*??????*/
           concat((pad.participant_json ->> 'second_name'), ' ', (pad.participant_json ->> 'first_name'), ' ',
                  (pad.participant_json ->> 'patronymic')) as fio_participant,
      /*??????????????*/
           (pad.participant_json ->> 'pc_tel')             as tel,
      /*???????????? ???? ??????????????????*/
           p_status.last_title                             as participant_last_status,
      /*???????????? ???????????? ?????????????????? ?? ????????????*/
           cr_status.last_title                            as cr_last_status,
           --null::varchar,
      /*???????? ???????????????????? ?????????????????? ?? ????????????*/
           pad.date_enrolled,
      /*?????????????? ???????????????????????? ??????*/
           pad.cso_short_title,
      /*??????????*/
           pad.tcso_district,
      /*??????????*/
           pad.tcso_area,
      /*?????????????? ???????????????????????? ?????????????????????? ????????????????????*/
           pad.supplier_short_title,
      /*?????????????????? ??????????????????????-????????????????????*/
           pad.supplier_dept,
      /*?????????? ??????????????????????*/
           pad.contract_number,
      /*???????????????????????? 1 ????????????*/
           pad.activity_title_L1,
      /*?????????????????????? 2 ????????????*/
           pad.activity_title_L2,
      /*?????????????????????? 3 ????????????*/
           pad.activity_title_L3,
      /*?????? ????????????*/
           pad.group_code,
      /*?????????????? ???????????????????????? ???????????????????????????????? ????????????*/
           pad.tc_short_title,
      /*???????????? ????????????*/
           pad.group_status,
      /*?????? ????????????????????????*/
           pad.fio_coordinator,
      /*?????? ?????????????????????????? ????????????*/
           pad.list_teachers_fio,
      /*?????????????? ??????????????????*/
           a_stat.cnt_lesson                               as cnt_lesson,
           --null::bigint,
      /*?????????????? ????????????????: ????????????*/
           a_stat.cnt_attended,
           --null::bigint,
      /*?? ??????*/
           a_stat.cnt_with_skm,
           --null::bigint,
      /*?????? ??????. ?????????????? ?? ????*/
           a_stat.cnt_without_skm,
           --null::bigint,
      /*?????? ??????. ?????????????? ?????????????????????????? ?? ?????? ????*/
           a_stat.cnt_web_coordinator,
           --null::bigint,
      /*?????? ??????. ?????????????? ?????????????????????? ?? ?????? ????*/
      /*?????????????????? ??????????????????????????????????*/
           a_stat.cnt_system_auto_confirmation,
           --null::bigint,
      /*?????????????? ??????????????????*/
           a_stat.cnt_missed,
           --null::bigint,
      /*????????????????????????, %*/
           a_stat.percent_attendance,
           --null::numeric,
      /*???????????? ????????????????????????*/
           case
             when a_stat.percent_attendance >= 80 and a_stat.percent_attendance <= 100 then '?????????????????? ???????????????? ??????????????'
             when a_stat.percent_attendance >= 50 and a_stat.percent_attendance < 80 then '?????????? ???????????????? ??????????????'
             when a_stat.percent_attendance >= 30 and a_stat.percent_attendance < 50 then '?????????? ???????????????? ??????????????'
             when a_stat.percent_attendance >= 0 and a_stat.percent_attendance < 30 then '?????????? ???????????????????? ??????????????'
             end                                           as status_attendance
           --null::text
    from rep.participant_attendance_datamart pad
           left join p_status on p_status.participant_id = pad.participant_id
           left join md.class_record cr on cr.participant_id = pad.participant_id and cr.group_id = pad.group_id
           left join cr_status on cr_status.class_record_id = cr.id
           join attendance_stat a_stat on a_stat.class_record_id = cr.id
           left join md.territory_organization torg on pad.territory_centre_id = torg.organization_id
    where (case
             when p_district_ids[1] isnull then true
             else
                 pad.i_p_district_ids in (select to2.organization_id
                                          from md.territory_organization to2
                                                 join ar.territory t on t.id = to2.territory_id and t.parent_id is not null
                                                 join unnest(p_district_ids) un on t.id = un.un)
      end)
      and (case
             when p_area_ids[1] isnull then true
             else
               pad.i_p_area_ids in (select unnest(p_area_ids)) /*PARAM ??????????*/
      end)
      and ((case
              when p_tcso_s_ch_ids[1] isnull then true
              else pad.i_p_tcso_s_ch_ids_1 in (select distinct to3.territory_id
                                           from md.territory_organization to3
                                           where to3.organization_id in (select unnest(p_tcso_s_ch_ids)) /*PARAM ???????? ("????????-??????????")*/
              )
      end)
      or (case
            when p_tcso_s_ch_ids[1] isnull then true
            else torg.territory_id in (select distinct to4.territory_id
                                       from md.territory_organization to4
                                       where to4.organization_id in (select unnest(p_tcso_s_ch_ids)) /*PARAM ???????? ("????????-??????????")*/
            )
        end))
      and (case
             when p_tcso_coordinators_ids[1] isnull then true
             else pad.i_p_tcso_coordinators_ids in
                  (select unnest(p_tcso_coordinators_ids)) /*PARAM ???????? (?????????????????????? ????????????)*/
      end)
      and (case
             when p_tcso_creator_ids[1] isnull then true
             else pad.i_p_tcso_creator_ids in (select unnest(p_tcso_creator_ids)) /*PARAM ???????? (?????????????????? ?????????????? ????????)*/
      end)
      and (case
             when p_uszn_ids[1] isnull then true
             else pad.i_p_district_ids in (select o4.id
                                           from md.organization o4
                                           where o4.parent_organization_id in (select o5.id
                                                                               from md.organization o5
                                                                               where o5.level_id = 2
                                                                                 and o5.parent_organization_id = 1095
                                                                                 and o5.id in (select unnest(p_uszn_ids)) /*PARAM ???????? ?????????????? ????????, ???????????????????????????? ????????????*/
                                           ))
               and pad.i_p_tcso_coordinators_ids in (select o4.id
                                                    from md.organization o4
                                                    where o4.parent_organization_id in (select o5.id
                                                                                        from md.organization o5
                                                                                        where o5.level_id = 2
                                                                                          and o5.parent_organization_id = 1095
                                                                                          and o5.id in (select unnest(p_uszn_ids)) /*PARAM ???????? ?????????????? ????????, ???????????????????????????? ????????????*/
                                                    ))
      end)
      and (case
             when p_provider_ids[1] isnull then true
             else pad.i_p_provider_ids in (select unnest(p_provider_ids)) /*PARAM ?????????????????????? ????????????????????*/
      end)
    limit p_limit_value offset p_offset_value;
end;
$$;