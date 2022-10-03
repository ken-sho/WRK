drop function if exists rep.r10_view;
create function rep.r10_view(
  district_1  bigint[] default array []::integer[], district_2 bigint[] default array []::integer[],
  district_3  bigint[] default array []::integer[], district_4 bigint[] default array []::integer[],
  tcso_1      bigint[] default array []::integer[], tcso_2 bigint[] default array []::integer[],
  tcso_3      bigint[] default array []::integer[], stt_1 bigint[] default array []::integer[],
  stt_2       bigint[] default array []::integer[], stt_3 bigint[] default array []::integer[],
  sign_online text default ''::text, arr_act_1 bigint[] default array []::integer[],
  arr_act_2   bigint[] default array []::integer[], arr_act_3 bigint[] default array []::integer[],
  limit_param integer default null::integer, offset_param bigint default null::bigint,
  participantlst bigint[] default array []::integer[])
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
    select --rownum
           row_number() over (order by r.participant_id)                                                        as rn,
           --fio
           concat((r.participant_json ->> 'second_name'), ' ', (r.participant_json ->> 'first_name'), ' ',
                  (r.participant_json ->> 'patronymic'))                                                        as "ФИО",
           --participantid
           r.participant_id                                                                                     as "Номер личного дела",
           --dateofbirth
           (r.participant_json ->> 'date_of_birth')                                                             as "Дата рождения",
           --gender
           (r.participant_json ->> 'gender')                                                                    as "Пол",
           --age
           extract(year from justify_interval(current_timestamp -
                                              to_date((r.participant_json ->> 'date_of_birth'), 'dd.mm.yyyy'))) as "Возраст",
           --livingregion
           tr1.title::text                                                                                      as "Район проживания",
           --registrationregion
           tr2.title::text                                                                                      as "Район регистрации",
           --creatortcso
           o.short_title::text                                                                                     "Краткое наименование ТЦСО создания ЛД",
           --creationdate
           to_char(r.creationdate, 'dd.mm.yyyy HH24:MI')                                                        as "Дата создания ЛД",
           --participantstatus
           r.participantstatus                                                                                  as "Статус ЛД",
           --rejectionreason
           r.rejectionreason                                                                                    as "Причина отказа",
           --firstlevelactivity
           case when a1.title isnull then null else a3.title::text end                                          as "Направление 1-го уровня",
           --secondlevelactivity
           case
             when a1.title isnull and a2.title is not null then a3.title::text
             else a2.title::text end                                                                            as "Направление 2-го уровня",
           --thirdlevelactivity
           case
             when a1.title isnull and a2.title isnull then a3.title::text
             when a1.title isnull and a2.title is not null then a2.title::text
             else a1.title::text end                                                                            as "Направление 3-го уровня",
           --activityprofilecreationdate
           to_char(r.activityprofilecreationdate, 'dd.mm.yyyy HH24:MI')                                         as "Дата создания профиля активности",
           --activitycreatortcso
           r.activitycreatortcso::text                                                                          as "ТЦСО - Организации Поставщика создания профиля активности",
           --groupid
           (case
              when r.group_id is null then null
              else concat('G-', lpad(r.group_id::text, 8, '0')) end)                                            as "Код группы",
           --groupstatus
           gs.title::text                                                                                       as "Статус группы",
           --classrecordstatus
           crs.title::text                                                                                      as "Статус записи в группу",
           --enrollmentdate
           to_char(r.enrollmentdate, 'dd.mm.yyyy HH24:MI')                                                      as "Дата зачисления",
           --stopreason
           r.stopreason                                                                                         as "Причина приостановки",
           --leavingdate
           to_char(r.leavingdate, 'dd.mm.yyyy HH24:MI')                                                         as "Дата отчисления",
           --leavingreason
           r.leavingreason                                                                                      as "Причина отчисления",
           --isonline
           r.i_isonline                                                                                         as "Признак онлайн",
           --providershortname
           o2.short_title::text                                                                                 as "Краткое наименование поставщика",
           --tcsoprovidershortname
           o3.short_title::text                                                                                 as "Краткое наименование ТЦСО координации группы",
           --tcsoproviderregion
           r.tcsoproviderregion                                                                                 as "Район ЦСО  координации группы",
           --tcsoproviderdistrict
           r.tcsoproviderdistrict                                                                               as "Округ ТЦСО координации группы"
    from rep.r10_datamart r
           left join md.organization o on r.creatortcso = o.id
           left join md.organization o2 on r.providerid = o2.id
           left join md.organization o3 on r.i_tcso_1 = o3.id
           left join ar.territory tr1 on r.livingregion = tr1.id
           left join ar.territory tr2 on r.registrationregion = tr2.id
           left join reference.activity a1 on r.i_arr_act_1 = a1.id
           left join reference.activity a2 on r.i_arr_act_2 = a2.id
           left join reference.activity a3 on r.i_arr_act_3 = a3.id
           left join reference.group_status gs on r.i_stt_3 = gs.id
           left join reference.class_record_status crs on r.i_stt_2 = crs.id
    where (case
             when district_1[1] isnull then true
             else
               r.i_district_1 in (select * from unnest(district_1)) end)
      and (case
             when district_2[1] isnull then true
             else
               r.i_district_2 in (select * from unnest(district_2)) end)
      and (case
             when district_3[1] isnull then true
             else
               r.i_district_3 in (select * from unnest(district_3)) end)
      and (case
             when district_4[1] isnull then true
             else
               r.i_district_4 in (select * from unnest(district_4)) end)
      
      and (case
             when tcso_1[1] isnull then true
             else
               r.i_tcso_1 in (select * from unnest(tcso_1)) end)
      and (case
             when tcso_2[1] isnull then true
             else
               r.creatortcso in (select * from unnest(tcso_2)) end)
      and (case
             when tcso_3[1] isnull then true
             else
               r.i_tcso_3 in (select * from unnest(tcso_3)) end)
      
      and (case
             when stt_1[1] isnull then true
             else
               r.i_stt_1 in (select * from unnest(stt_1)) end)
      and (case
             when stt_2[1] isnull then true
             else
               r.i_stt_2 in (select * from unnest(stt_2)) end)
      and (case
             when stt_3[1] isnull then true
             else
               r.i_stt_3 in (select * from unnest(stt_3)) end)
      
      and (case
             when arr_act_3[1] isnull then true
             else
               r.i_arr_act_1 in (select * from unnest(arr_act_3)) end)
      and (case
             when arr_act_2[1] isnull then true
             else
               r.i_arr_act_2 in (select * from unnest(arr_act_2)) end)
      and (case
             when arr_act_1[1] isnull then true
             else
               r.i_arr_act_3 in (select * from unnest(arr_act_1)) end)
      and (case
             when participantlst[1] isnull then true
             else
               r.participant_id in (select * from unnest(participantlst)) end)
      and coalesce(r.i_isonline, '') =
          (case when upper(sign_online) = '' then coalesce(r.i_isonline, '') else upper(sign_online) end)
    order by r.participant_id
    limit limit_param offset offset_param;
end
$$;