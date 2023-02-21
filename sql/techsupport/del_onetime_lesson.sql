drop function if exists techsupport.del_onetime_lesson;
create function techsupport.del_onetime_lesson(i_lesson_id bigint) returns text
  language plpgsql
as $$
DECLARE
  sh_id bigint;
  l_date date;
  cnt integer;
  l_row md.lesson%rowtype;
  stc_row md.schedule_timesheet_coworkers%rowtype;
  revision_cnt bigint;
  upd_id bigint;
  i_old_val text;
  row record;
  lid bigint;
BEGIN

  ---Удалению разовых занятий
  ---пример вызова
  ---select techsupport.del_onetime_lesson(lesson_id)
  ---https://jira.mos.social/browse/MDP-270
  select l.schedule_id,l.lesson_date,l.id into sh_id,l_date,lid from md.lesson l where l.id=i_lesson_id;
  if lid isnull then return i_lesson_id||' нет такого занятия'; end if;
  if sh_id is not null then return i_lesson_id||' удалить нельзя: не являеться разовым занятием'; end if;
  
  ---Проверка на отсуствие ведомости учета посещаемости и даты занятия
  select count(*) into cnt
  from md.attendance_record ar
                join md.attendance_record_sheet ars on ar.id = ars.attendance_record_id
  where ars.lesson_id=i_lesson_id;
  if cnt>0 and l_date>=to_date('01.01.2021','dd.mm.yyyy') then return i_lesson_id||' удалить нельзя: есть сведения в "Состав ведомости учёта посещаемости"  или в "Ведомость учёта посещаемости"'; end if;
  ----
  select
    count(*) into cnt
  from md.attendance_data ad
       join md.lesson_attendance_list lal on ad.id = lal.attendance_data_id
       join md.candidate cd on ad.id = cd.attendance_data_id
  where
    ad.lesson_id=i_lesson_id;
  if cnt>0 then return i_lesson_id||' удалить нельзя: есть сведения в "Кандидаты"'; end if;
  ----
  select
    count(*) into cnt
  from md.attendance_data ad
       join md.lesson_attendance_list lal on ad.id = lal.attendance_data_id
  where
    ad.lesson_id=i_lesson_id
    and ad.attendance_data_type='CONFIRMED'
    and lal.presence_mark=true;
  if cnt>0 then return i_lesson_id||' удалить нельзя:  "Данные учёта посещаемости" имеют признак подтверждения и есть хотя бы одна отметка о посещении занятия в "Список посещения занятия"'; end if;
  ----удаление
  raise notice '1';
  delete from md.lesson_attendance_list_rating lalr
  where lalr.lesson_attendance_list_id in (
    select lal.id
    from md.attendance_data ad
           join md.lesson_attendance_list lal on ad.id = lal.attendance_data_id
    where ad.lesson_id=i_lesson_id
  );
  raise notice '2 %',i_lesson_id;
  for row in select stc.id as stc_id from md.schedule_timesheet_coworkers stc where stc.lesson_id=i_lesson_id
  loop
    delete from md.schedule_timesheet_coworkers stc where stc.id=row.stc_id returning * into stc_row;
    revision_cnt := nextval('public.hibernate_sequence');
    raise notice 'revision_cnt %',revision_cnt;
    insert into audit.revision (id, timestamp, user_id)
    values (revision_cnt, (trunc(extract(epoch from now()) * 1000)), 1)
    returning id into revision_cnt;
    upd_id:=stc_row.id;
    update audit.schedule_timesheet_coworkers_aud
    set revend=revision_cnt,
        revend_timestamp=current_timestamp
    where id = upd_id
      and revend isnull;
    insert into audit.schedule_timesheet_coworkers_aud(rev, lesson_id, coworker_id, revtype,week_day_schedule_id, schedule_id, main_coworker, id)
    values (revision_cnt,stc_row.lesson_id,stc_row.coworker_id, 2,stc_row.week_day_schedule_id, stc_row.schedule_id, stc_row.main_coworker, stc_row.id);
  end loop;
  raise notice '3';
  delete from md.lesson l where l.id=i_lesson_id returning * into l_row;
  revision_cnt := nextval('public.hibernate_sequence');
  raise notice 'revision_cnt %',revision_cnt;
  insert into audit.revision (id, timestamp, user_id)
  values (revision_cnt, (trunc(extract(epoch from now()) * 1000)), 1)
  returning id into revision_cnt;
  upd_id:=l_row.id;
  update audit.lesson_aud
  set revend=revision_cnt,
      revend_timestamp=current_timestamp
  where id = upd_id
    and revend isnull;
  insert into audit.lesson_aud(id, rev, revtype, attendance_data, day_of_week, group_id, is_exception, lesson_type,
                               end_time, lesson_date, pause, start_time, place_id, schedule_id)
  values(l_row.id, revision_cnt, 2, l_row.attendance_data, l_row.day_of_week, l_row.group_id, l_row.is_exception, l_row.lesson_type,
                      l_row.end_time, l_row.lesson_date, l_row.pause, l_row.start_time, l_row.place_id, l_row.schedule_id);
  ----
  i_old_val:=jsonb_build_object('schedule_timesheet_coworkers',stc_row,'lesson',l_row);
  insert into techsupport.fnk_log(name_fnk, input_param, old_val,user_name)
  values ('del_onetime_lesson',i_lesson_id::text,i_old_val,current_user);
  ----
	return i_lesson_id||' удален';
  exception when others then return 'error';
END;
$$;