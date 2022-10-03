drop function if exists techsupport.chg_lesson_date;
create function techsupport.chg_lesson_date(
  i_lesson_id       bigint, i_lesson_date date, i_lesson_start_time time without time zone,
  i_lesson_end_time time without time zone, i_coworker bigint, i_place bigint) returns text
  security definer
  language plpgsql
as $$
declare
  revision_cnt bigint;
  lid_row      md.lesson%rowtype;
  lid_row_old  md.lesson%rowtype;
  stc_row      md.schedule_timesheet_coworkers%rowtype;
  cnt          int;
  row          record;
begin
  ---Изменение параметров занятия
  ---пример вызова
  /*
   select techsupport.chg_lesson_date(
                i_lesson_id := Код занятия,
                i_lesson_date := 'Дата проведения занятия'::date,
                i_lesson_start_time := 'Время начала занятия'::time,
                i_lesson_end_time := 'Время окончания занятия'::time,
                i_coworker := Код преподавателя,
                i_place := Код площадки
                );
   */
  ---https://jira.mos.social/browse/MDP-957
  ---Проверки входных параметров
  select l.* into lid_row_old from md.lesson l where l.id = i_lesson_id;
  select count(*) into cnt from md.lesson l2 where l2.group_id = lid_row_old.group_id;
  if lid_row_old.lesson_type = 'DELETED' then return '«Нельзя откорректировать удаленное занятие»'; end if;
  if lid_row_old.id isnull then return '«Занятие не найдено»'; end if;
  if lid_row_old.lesson_date < current_date then return '«Невозможно изменить прошедшее занятие»'; end if;
  if i_lesson_date is not null and i_lesson_date < current_date then return '«Ошибка входных параметров»'; end if;
  if i_lesson_date is null or i_lesson_date = current_date and i_lesson_start_time < current_time then
    return '«Ошибка входных параметров»';
  end if;
  if coalesce(i_lesson_end_time, lid_row_old.end_time) <= coalesce(i_lesson_start_time, lid_row_old.start_time) then
    return '«Ошибка входных параметров»';
  end if;
  if cnt != 1 then return 'Нельзя откорректировать данное занятие'; end if;
  ----Создаём новую запись lesson
  select l.* into lid_row_old from md.lesson l where l.id = i_lesson_id;
  insert into md.lesson(schedule_id, lesson_date, start_time, end_time, pause, place_id, day_of_week, lesson_type,
                        group_id,
                        attendance_data, is_exception)
  values (lid_row_old.schedule_id, coalesce(i_lesson_date, lid_row_old.lesson_date),
          coalesce(i_lesson_start_time, lid_row_old.start_time),
          coalesce(i_lesson_end_time, lid_row_old.end_time), lid_row_old.pause, coalesce(i_place, lid_row_old.place_id),
          coalesce(to_char(i_lesson_date, 'DAY'), lid_row_old.day_of_week), 'GROUP', lid_row_old.group_id,
          lid_row_old.attendance_data, lid_row_old.is_exception)
  returning * into lid_row;
  
  revision_cnt := nextval('public.hibernate_sequence');
  raise notice 'revision_cnt %',revision_cnt;
  insert into audit.revision (id, timestamp, user_id)
  values (revision_cnt, (trunc(extract(epoch from now()) * 1000)), 1)
  returning id into revision_cnt;
  insert into audit.lesson_aud(id, rev, revtype, attendance_data, day_of_week, group_id,
                               is_exception, lesson_type, end_time, lesson_date, pause, start_time, place_id,
                               schedule_id)
  values (lid_row.id, revision_cnt, 0, lid_row.attendance_data, lid_row.day_of_week, lid_row.group_id,
          lid_row.is_exception,
          lid_row.lesson_type, lid_row.end_time, lid_row.lesson_date, lid_row.pause, lid_row.start_time,
          lid_row.place_id, lid_row.schedule_id);
  ----Правим старое занятие и расписание преподователей
  for row in select stc.id as stc_id from md.schedule_timesheet_coworkers stc where stc.lesson_id = i_lesson_id
    loop
      if row.stc_id is not null then
        update md.schedule_timesheet_coworkers
        set lesson_id=lid_row.id,
            coworker_id=coalesce(i_coworker, coworker_id)
        where id = row.stc_id
        returning * into stc_row;
        revision_cnt := nextval('public.hibernate_sequence');
        raise notice 'revision_cnt %',revision_cnt;
        insert into audit.revision (id, timestamp, user_id)
        values (revision_cnt, (trunc(extract(epoch from now()) * 1000)), 1)
        returning id into revision_cnt;
        update audit.schedule_timesheet_coworkers_aud
        set revend=revision_cnt,
            revend_timestamp=current_timestamp
        where id = row.stc_id
          and revend isnull;
        insert into audit.schedule_timesheet_coworkers_aud(rev, lesson_id, coworker_id, revtype,
                                                           week_day_schedule_id, schedule_id, main_coworker, id)
        values (revision_cnt, stc_row.lesson_id, stc_row.coworker_id, 1, stc_row.week_day_schedule_id,
                stc_row.schedule_id,
                stc_row.main_coworker, stc_row.id);
      end if;
    end loop;
  -----
  delete from md.lesson l where l.id = i_lesson_id;
  revision_cnt := nextval('public.hibernate_sequence');
  raise notice 'revision_cnt %',revision_cnt;
  insert into audit.revision (id, timestamp, user_id)
  values (revision_cnt, (trunc(extract(epoch from now()) * 1000)), 1)
  returning id into revision_cnt;
  update audit.lesson_aud
  set revend=revision_cnt,
      revend_timestamp=current_timestamp
  where id = i_lesson_id
    and revend isnull;
  insert into audit.lesson_aud(id, rev, revtype, attendance_data, day_of_week, group_id,
                               is_exception, lesson_type, end_time, lesson_date, pause, start_time, place_id,
                               schedule_id)
  values (lid_row_old.id, revision_cnt, 2, lid_row_old.attendance_data, lid_row_old.day_of_week, lid_row_old.group_id,
          lid_row_old.is_exception,
          lid_row_old.lesson_type, lid_row_old.end_time, lid_row_old.lesson_date, lid_row_old.pause,
          lid_row_old.start_time, lid_row_old.place_id, lid_row_old.schedule_id);
  ----
  insert into techsupport.fnk_log(name_fnk, input_param, old_val, new_val)
  values ('chg_lesson_date', i_lesson_id, lid_row_old, lid_row);
  ----
  return 'success';

end;
$$;