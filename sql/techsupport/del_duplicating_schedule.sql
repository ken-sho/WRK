drop function if exists techsupport.del_duplicating_schedule;
create function techsupport.del_duplicating_schedule(i_group_id text) returns text
  security definer
  language plpgsql
as $$
DECLARE
  row record;
  row1 record;
  row2 record;
  row3 record;
  dell_row record;
  cnt_arr_sh integer;
  cnt integer;
  cnt_err integer;
  jsonb_log jsonb:='{}';
  jsonb_row jsonb;
  base_shedule_id bigint;
  new_lesson_arr bigint[];
  old_lesson_arr bigint[];
BEGIN
  ---Удаление дублей расписания в группе
  ---пример вызова
  ---select techsupport.del_duplicating_schedule('номер группы (можно из КИС МД G-00000931)')
  /*
   https://gost-jira.atlassian.net/browse/DITDOLLET-6020
   */
for row in
            with L0 as (
              select s.id as schedule_id,
                     s.place_id,
                     s.end_date,
                     s.start_date,
                     s.start_time,
                     s.end_time,
                     s.group_id,
                     array_agg(distinct stc.coworker_id) as coworker,
                     wds.day_of_week,
                     count(distinct lal.id) as cnt1
              from md.schedule s
                     join md.schedule_timesheet_coworkers stc on s.id = stc.schedule_id
                     join md.week_day_schedule wds on s.id = wds.schedule_id
                     join md.lesson l on s.id=l.schedule_id
                     left join md.attendance_data ad on l.id = ad.lesson_id
                     left join md.attendance_record_sheet arh on l.id = arh.lesson_id
                     left join md.lesson_attendance_list lal on ad.id = lal.attendance_data_id and lal.presence_mark=true
              where s.group_id=regexp_replace(i_group_id, '[^0-9]', '', 'g')::bigint
              group by s.id,s.place_id,s.end_date,s.start_date,s.start_time,s.end_time,s.group_id,wds.day_of_week
            ),L1 as (select L0.place_id,
                            L0.end_date,
                            L0.start_date,
                            L0.start_time,
                            L0.end_time,
                            L0.group_id,
                            L0.coworker,
                            L0.schedule_id,
                            array_agg(distinct L0.day_of_week order by L0.day_of_week) as day_of_week,
                            L0.cnt1
                     from L0
                     group by L0.schedule_id, L0.place_id, L0.end_date, L0.start_date, L0.start_time, L0.end_time,
                              L0.group_id, L0.coworker,L0.cnt1
            )
            select
              array_agg(L1.schedule_id order by L1.schedule_id) as schedule_id,
              array_agg(L1.cnt1 order by L1.schedule_id) as cnt_adsl,
               L1.place_id, end_date, start_date, start_time, end_time, group_id, coworker, day_of_week, count(*) as ccnt
            from L1
            group by L1.place_id, end_date, start_date, start_time, end_time, group_id, coworker, day_of_week
            having count(*)>1
            order by group_id
loop
  if 0=all(row.cnt_adsl) then raise notice 'dell any'; ---dell any
    cnt_arr_sh:=row.ccnt;
    if cnt_arr_sh<=1 then raise exception 'logical error'; end if;
    cnt:=1;
        loop
          jsonb_row:='{}'::jsonb;
          cnt:=cnt+1;
          ---Lesson
          for row1 in select * from md.lesson l where l.schedule_id=row.schedule_id[cnt]
            loop
                ---attendance_sheet/lesson_attendance_list
                  for row2 in select ad.* from md.attendance_data ad
                             where ad.lesson_id=row1.id
                  loop
                    select array_agg(lal.*) into dell_row from md.lesson_attendance_list lal where lal.attendance_data_id=row2.id;
                    delete from md.lesson_attendance_list lal where lal.attendance_data_id=row2.id and lal.presence_mark!=true;
                    jsonb_row:=jsonb_row||jsonb_build_object('md.lesson_attendance_list',dell_row);
                  end loop;
              ---attendance_data
                select array_agg(ad.*) into dell_row from md.attendance_data ad where ad.lesson_id=row1.id;
                delete from md.attendance_data ad where ad.lesson_id=row1.id;
                jsonb_row:=jsonb_row||jsonb_build_object('md.attendance_data',dell_row);
            ---schedule_timesheet_coworkers
            select array_agg(stc.* order by stc.id) into dell_row from md.schedule_timesheet_coworkers stc where stc.lesson_id=row1.id;
            delete from md.schedule_timesheet_coworkers stc where stc.lesson_id=row1.id;
            jsonb_row:=jsonb_row||jsonb_build_object('md.schedule_timesheet_coworkers_l',dell_row);
            ---lesson
            delete from md.lesson l where l.id=row1.id returning * into dell_row;
            jsonb_row:=jsonb_row||jsonb_build_object('md.lesson',dell_row);
          end loop;
          ---week_day_schedule
          for row1 in select * from md.week_day_schedule wds where wds.schedule_id=row.schedule_id[cnt]
          loop
            ---schedule_timesheet_coworkers
            select array_agg(stc.*) into dell_row from md.schedule_timesheet_coworkers stc where stc.week_day_schedule_id=row1.id;
            delete from md.schedule_timesheet_coworkers stc where stc.week_day_schedule_id=row1.id;
            jsonb_row:=jsonb_row||jsonb_build_object('md.schedule_timesheet_coworkers_wds',dell_row);
            ---week_day_schedule
            delete from md.week_day_schedule wds where wds.id=row1.id returning * into dell_row;
            jsonb_row:=jsonb_row||jsonb_build_object('md.week_day_schedule',dell_row);
          end loop;
          ---schedule
          for row1 in select * from md.schedule s where s.id=row.schedule_id[cnt]
          loop
            ---schedule_timesheet_coworkers
            select array_agg(stc.*) into dell_row from md.schedule_timesheet_coworkers stc where stc.schedule_id=row1.id;
            delete from md.schedule_timesheet_coworkers stc where stc.schedule_id=row1.id;
            jsonb_row:=jsonb_row||jsonb_build_object('md.schedule_timesheet_coworkers_s',dell_row);
            ---schedule
            delete from md.schedule s where s.id=row1.id returning * into dell_row;
            jsonb_row:=jsonb_row||jsonb_build_object('md.schedule',dell_row);
          end loop;
        jsonb_log:=jsonb_log||jsonb_build_object('schedule_id_'||row.schedule_id[cnt],jsonb_row);
        exit when cnt>=cnt_arr_sh;
        end loop;
  else raise notice 'do not dell any';
    cnt_arr_sh:=row.ccnt;
    if cnt_arr_sh<=1 then raise exception 'logical error'; end if;
    cnt:=1;
    base_shedule_id:=row.schedule_id[1];
        loop
          jsonb_row:='{}'::jsonb;
          cnt:=cnt+1;
          if row.cnt_adsl[cnt]=0 then ---удаляем если в дублирующей записи нет данных о посещаемости
              raise notice 'zero shedule %',row.cnt_adsl[cnt];
              ---Lesson
              for row1 in select * from md.lesson l where l.schedule_id=row.schedule_id[cnt]
              loop
                  ---attendance_sheet/lesson_attendance_list
                    for row2 in select ad.* from md.attendance_data ad
                               where ad.lesson_id=row1.id
                    loop
                      select array_agg(lal.*) into dell_row from md.lesson_attendance_list lal where lal.attendance_data_id=row2.id;
                      delete from md.lesson_attendance_list lal where lal.attendance_data_id=row2.id and lal.presence_mark!=true;
                      jsonb_row:=jsonb_row||jsonb_build_object('md.lesson_attendance_list',dell_row);
                    end loop;
                ---attendance_data
                  select array_agg(ad.*) into dell_row from md.attendance_data ad where ad.lesson_id=row1.id;
                  delete from md.attendance_data ad where ad.lesson_id=row1.id;
                  jsonb_row:=jsonb_row||jsonb_build_object('md.attendance_data',dell_row);
                ---schedule_timesheet_coworkers
                select array_agg(stc.* order by stc.id) into dell_row from md.schedule_timesheet_coworkers stc where stc.lesson_id=row1.id;
                delete from md.schedule_timesheet_coworkers stc where stc.lesson_id=row1.id;
                jsonb_row:=jsonb_row||jsonb_build_object('md.schedule_timesheet_coworkers_l',dell_row);
                ---lesson
                delete from md.lesson l where l.id=row1.id returning * into dell_row;
                jsonb_row:=jsonb_row||jsonb_build_object('md.lesson',dell_row);
              end loop;
              ---week_day_schedule
              for row1 in select * from md.week_day_schedule wds where wds.schedule_id=row.schedule_id[cnt]
              loop
                ---schedule_timesheet_coworkers
                select array_agg(stc.*) into dell_row from md.schedule_timesheet_coworkers stc where stc.week_day_schedule_id=row1.id;
                delete from md.schedule_timesheet_coworkers stc where stc.week_day_schedule_id=row1.id;
                jsonb_row:=jsonb_row||jsonb_build_object('md.schedule_timesheet_coworkers_wds',dell_row);
                ---week_day_schedule
                delete from md.week_day_schedule wds where wds.id=row1.id returning * into dell_row;
                jsonb_row:=jsonb_row||jsonb_build_object('md.week_day_schedule',dell_row);
              end loop;
              ---schedule
              for row1 in select * from md.schedule s where s.id=row.schedule_id[cnt]
              loop
                ---schedule_timesheet_coworkers
                select array_agg(stc.*) into dell_row from md.schedule_timesheet_coworkers stc where stc.schedule_id=row1.id;
                delete from md.schedule_timesheet_coworkers stc where stc.schedule_id=row1.id;
                jsonb_row:=jsonb_row||jsonb_build_object('md.schedule_timesheet_coworkers_s',dell_row);
                ---schedule
                delete from md.schedule s where s.id=row1.id returning * into dell_row;
                jsonb_row:=jsonb_row||jsonb_build_object('md.schedule',dell_row);
              end loop;
          else raise notice 'merge attendance&statement %',row.cnt_adsl[cnt];
              ---Lesson
              for row1 in select * from md.lesson l where l.schedule_id=row.schedule_id[cnt]
              loop
                -----merge
                select
                       array_remove(array_agg(distinct l.id order by l.id),null)
                       into new_lesson_arr
                from md.schedule s
                       join md.schedule_timesheet_coworkers stc on s.id = stc.schedule_id
                       join md.week_day_schedule wds on s.id = wds.schedule_id
                       join md.lesson l on s.id=l.schedule_id
                       join md.attendance_data ad on l.id = ad.lesson_id
                       join md.attendance_record_sheet arh on l.id = arh.lesson_id
                       join md.lesson_attendance_list lal on ad.id = lal.attendance_data_id and lal.presence_mark=true
                       --join md.statement st on l.id = st.lesson_id
                       --join md.statement_list sl on st.id = sl.statement_id and sl.presence_mark=true
                where s.id=row.schedule_id[cnt];
                
                with L0 as(select unnest(new_lesson_arr)
                )select array_agg(l2.id order by l2.id) as old_lesson_id
                        into old_lesson_arr
                  from md.lesson l
                         join L0 on l.id = L0.unnest
                         join md.lesson l2 on l.group_id = l2.group_id
                      and l2.schedule_id = base_shedule_id and l.lesson_date = l2.lesson_date
                      and l.start_time = l2.start_time and l.end_time = l2.end_time
                      and l.place_id = l2.place_id and l.day_of_week = l2.day_of_week;
                ------проверка и перенос
                  for row2 in select unnest(old_lesson_arr) as old_lesson,unnest(new_lesson_arr) as new_lesson
                  loop
                      select----проверка что в старом уроке нет активности
                             count(*) into cnt_err
                      from md.schedule s
                             join md.schedule_timesheet_coworkers stc on s.id = stc.schedule_id
                             join md.week_day_schedule wds on s.id = wds.schedule_id
                             join md.lesson l on s.id=l.schedule_id
                             join md.attendance_data ad on l.id = ad.lesson_id
                             join md.attendance_record_sheet arh on l.id = arh.lesson_id
                             join md.lesson_attendance_list lal on ad.id = lal.attendance_data_id and lal.presence_mark=true
                      where l.id=row2.old_lesson;
                        if cnt_err!=0 then --raise exception 'logigal error attendance_data not empty';
                          ---перенос посещаемости на новый урок
                          update md.attendance_data
                          set lesson_id=row2.new_lesson
                          where lesson_id=row2.old_lesson;
                          update md.attendance_record_sheet
                          set lesson_id=row2.new_lesson
                          where lesson_id=row2.old_lesson;
                          ---перенос уроков
                          update md.lesson---upd old lesson
                          set schedule_id=row.schedule_id[cnt]
                          where id=row2.old_lesson;
                          update md.lesson---upd new lesson
                          set schedule_id=base_shedule_id
                          where id=row2.new_lesson;
                        else
                          update md.lesson---upd old lesson
                          set schedule_id=row.schedule_id[cnt]
                          where id=row2.old_lesson;
                          update md.lesson---upd new lesson
                          set schedule_id=base_shedule_id
                          where id=row2.new_lesson;
                        end if;
                  ----end merge
                  end loop;
              end loop;
              for row1 in select * from md.lesson l where l.schedule_id=row.schedule_id[cnt]
              loop
                  ---attendance_sheet/lesson_attendance_list
                    for row2 in select ad.* from md.attendance_data ad
                               where ad.lesson_id=row1.id
                    loop
                      select array_agg(lal.*) into dell_row from md.lesson_attendance_list lal where lal.attendance_data_id=row2.id;
                      delete from md.lesson_attendance_list lal where lal.attendance_data_id=row2.id and lal.presence_mark!=true;
                      jsonb_row:=jsonb_row||jsonb_build_object('md.lesson_attendance_list',dell_row);
                    end loop;
                ---attendance_data
                  select array_agg(ad.*) into dell_row from md.attendance_data ad where ad.lesson_id=row1.id;
                  delete from md.attendance_data ad where ad.lesson_id=row1.id;
                  jsonb_row:=jsonb_row||jsonb_build_object('md.attendance_data',dell_row);
                ---schedule_timesheet_coworkers
                select array_agg(stc.* order by stc.id) into dell_row from md.schedule_timesheet_coworkers stc where stc.lesson_id=row1.id;
                delete from md.schedule_timesheet_coworkers stc where stc.lesson_id=row1.id;
                jsonb_row:=jsonb_row||jsonb_build_object('md.schedule_timesheet_coworkers_l',dell_row);
                ---lesson
                delete from md.lesson l where l.id=row1.id returning * into dell_row;
                jsonb_row:=jsonb_row||jsonb_build_object('md.lesson',dell_row);
              end loop;
              ---week_day_schedule
              for row1 in select * from md.week_day_schedule wds where wds.schedule_id=row.schedule_id[cnt]
              loop
                ---schedule_timesheet_coworkers
                select array_agg(stc.*) into dell_row from md.schedule_timesheet_coworkers stc where stc.week_day_schedule_id=row1.id;
                delete from md.schedule_timesheet_coworkers stc where stc.week_day_schedule_id=row1.id;
                jsonb_row:=jsonb_row||jsonb_build_object('md.schedule_timesheet_coworkers_wds',dell_row);
                ---week_day_schedule
                delete from md.week_day_schedule wds where wds.id=row1.id returning * into dell_row;
                jsonb_row:=jsonb_row||jsonb_build_object('md.week_day_schedule',dell_row);
              end loop;
              ---schedule
              for row1 in select * from md.schedule s where s.id=row.schedule_id[cnt]
              loop
                ---schedule_timesheet_coworkers
                select array_agg(stc.*) into dell_row from md.schedule_timesheet_coworkers stc where stc.schedule_id=row1.id;
                delete from md.schedule_timesheet_coworkers stc where stc.schedule_id=row1.id;
                jsonb_row:=jsonb_row||jsonb_build_object('md.schedule_timesheet_coworkers_s',dell_row);
                ---schedule
                delete from md.schedule s where s.id=row1.id returning * into dell_row;
                jsonb_row:=jsonb_row||jsonb_build_object('md.schedule',dell_row);
                end loop;
          end if;
          --raise exception 'good delete';
        jsonb_log:=jsonb_log||jsonb_build_object('schedule_id_'||row.schedule_id[cnt],jsonb_row);
        exit when cnt>=cnt_arr_sh;
        end loop;
  end if;
end loop;
  ----
  insert into techsupport.fnk_log(name_fnk, input_param, old_val,user_name)
  values ('del_duplicating_schedule',i_group_id,jsonb_log,current_user);
  ----
	return 'success';
  exception when others then return 'critical error';
END;
$$;


