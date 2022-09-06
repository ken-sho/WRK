drop function if exists techsupport.add_timesheet_coworkers;
create function techsupport.add_timesheet_coworkers(i_schedule_id bigint,i_coworker_id bigint) returns text
  language plpgsql
as $$
DECLARE
  row record;
  revision_cnt bigint;
  jsonb_log jsonb:='{}';
  jsonb_row jsonb:='{}';
  stc_row md.schedule_timesheet_coworkers%rowtype;
BEGIN
  ---Добавление преподователя в расписание
  ---пример вызова
  ---select techsupport.add_timesheet_coworkers(schedule_id,coworker_id)
  ---https://jira.mos.social/browse/MDP-265
  for row in select----schedule
              s.id as sid
              from md.schedule s
                   left join md.schedule_timesheet_coworkers stc on s.id = stc.schedule_id
              where
              s.id=i_schedule_id
              and stc.id isnull
  loop
    revision_cnt:=nextval('public.hibernate_sequence');
    insert into audit.revision (id, timestamp, user_id)
    values(revision_cnt,(trunc(extract(epoch from now())*1000)),1)
    returning id into revision_cnt;
    
    insert into md.schedule_timesheet_coworkers(coworker_id, schedule_id)
    values(i_coworker_id,row.sid) returning * into stc_row;
    insert into audit.schedule_timesheet_coworkers_aud(rev, lesson_id, coworker_id, revtype,
                                                       week_day_schedule_id, schedule_id, main_coworker, id)
    values(revision_cnt,stc_row.lesson_id,stc_row.coworker_id,0,stc_row.week_day_schedule_id,stc_row.schedule_id,
           stc_row.main_coworker,stc_row.id);
    jsonb_row:=jsonb_row||jsonb_build_object(stc_row.id,stc_row);
  end loop;
  jsonb_log:=jsonb_log||jsonb_build_object('md.schedule',jsonb_log);
  for row in select----lesson
              l.id as lid
              from md.schedule s
                   join md.lesson l on s.id = l.schedule_id
                   left join md.schedule_timesheet_coworkers stc on l.id = stc.lesson_id
              where
              s.id=i_schedule_id
              and stc.id isnull
  loop
    revision_cnt:=nextval('public.hibernate_sequence');
    insert into audit.revision (id, timestamp, user_id)
    values(revision_cnt,(trunc(extract(epoch from now())*1000)),1)
    returning id into revision_cnt;
    
    insert into md.schedule_timesheet_coworkers(coworker_id, lesson_id)
    values(i_coworker_id,row.lid) returning * into stc_row;
    insert into audit.schedule_timesheet_coworkers_aud(rev, lesson_id, coworker_id, revtype,
                                                       week_day_schedule_id, schedule_id, main_coworker, id)
    values(revision_cnt,stc_row.lesson_id,stc_row.coworker_id,0,stc_row.week_day_schedule_id,stc_row.schedule_id,
           stc_row.main_coworker,stc_row.id);
    jsonb_row:=jsonb_row||jsonb_build_object(stc_row.id,stc_row);
  end loop;
  jsonb_log:=jsonb_log||jsonb_build_object('md.lesson',jsonb_log);
  for row in select----week_day_schedule
              wds.id as wds_id
              from md.schedule s
                   join md.week_day_schedule wds on s.id = wds.schedule_id
                   left join md.schedule_timesheet_coworkers stc on wds.id = stc.week_day_schedule_id
              where
              s.id=i_schedule_id
              and stc.id isnull
  loop
    revision_cnt:=nextval('public.hibernate_sequence');
    insert into audit.revision (id, timestamp, user_id)
    values(revision_cnt,(trunc(extract(epoch from now())*1000)),1)
    returning id into revision_cnt;
    
    insert into md.schedule_timesheet_coworkers(coworker_id, week_day_schedule_id)
    values(i_coworker_id,row.wds_id) returning * into stc_row;
    insert into audit.schedule_timesheet_coworkers_aud(rev, lesson_id, coworker_id, revtype,
                                                       week_day_schedule_id, schedule_id, main_coworker, id)
    values(revision_cnt,stc_row.lesson_id,stc_row.coworker_id,0,stc_row.week_day_schedule_id,stc_row.schedule_id,
           stc_row.main_coworker,stc_row.id);
    jsonb_row:=jsonb_row||jsonb_build_object(stc_row.id,stc_row);
  end loop;
  jsonb_log:=jsonb_log||jsonb_build_object('md.week_day_schedule',jsonb_log);
  ----
  insert into techsupport.fnk_log(name_fnk, input_param, old_val,user_name)
  values ('add_timesheet_coworkers',i_schedule_id,jsonb_log,current_user);
  ----
	return 'success';
  exception when others then return 'critical error';
END;
$$;
