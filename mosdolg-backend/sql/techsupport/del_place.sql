drop function if exists techsupport.del_place;
create function techsupport.del_place(pid bigint)
  returns TABLE(tbl_name text, id bigint, place_id bigint)
  language plpgsql
as $$
declare
  revision_cnt  bigint;
  pid_row       md.place%rowtype;
  upd_id        bigint;
begin
  ---Удаляем площадку
  ---пример вызова
  ---select techsupport.del_place(pid)
  ---https://jira.mos.social/browse/MDP-184
select
  p.id into upd_id
from md.place p
       left join md.attendance_data ad on p.id = ad.place_id
       left join md.certification c on p.id = c.place_id
       left join md.lesson l on p.id = l.place_id
       left join md.schedule s on p.id = s.place_id
       left join md.week_day_schedule wds on p.id = wds.place_id
where p.id = pid
and (
     ad.id is not null
  or c.id is not null
  or l.id is not null
  or s.id is not null
  or wds.id is not null
  )
limit 1;
select p.* into pid_row from md.place p where p.id=pid;

if upd_id is not null and pid_row is not null then
  return query
      select
      'md.attendance_data',ad.id,ad.place_id
      from md.attendance_data ad
      where
      ad.place_id=pid
      union all
      select
      'md.certification',c.id,c.place_id
      from md.certification c
      where
      c.place_id=pid
      union all
      select
      'md.lesson',l.id,l.place_id
      from md.lesson l
      where
      l.place_id=pid
      union all
      select
      'md.schedule',s.id,s.place_id
      from md.schedule s
      where
      s.place_id=pid
      union all
      select
      'md.week_day_schedule',wds.id,wds.place_id
      from md.week_day_schedule wds
      where
      wds.place_id=pid;
  else if upd_id isnull and pid_row isnull then
    ----error
    tbl_name:='запись на найдена';
    place_id:=pid;
    return next;
  else
    raise notice 'delete';
    delete from md.place_metro_stations pms where pms.place_id=pid;
    delete from md.place p where p.id=pid;
    revision_cnt:=nextval('public.hibernate_sequence');
    
    insert into audit.revision (id, timestamp, user_id)
    values(revision_cnt,(trunc(extract(epoch from now())*1000)),1)
    returning audit.revision.id into revision_cnt;

    update audit.place_aud
    set revend=revision_cnt,
        revend_timestamp=CURRENT_TIMESTAMP
    where audit.place_aud.id = pid
      and revend isnull;
    
    insert into audit.place_aud(id, rev, revtype, organization_id, title, address, validation,
                                sync, place_status_id, json, is_archived)
    values(pid_row.id,revision_cnt,2,pid_row.organization_id,pid_row.title,pid_row.address,pid_row.validation,
           pid_row.sync,pid_row.place_status_id,pid_row.json,pid_row.is_archived);
    ----log
    insert into techsupport.fnk_log(name_fnk, input_param, old_val)
    values ('del_place', pid, pid_row);
    ----
    tbl_name:='запись успешно удалена';
    place_id:=pid;
    return next;
  end if;end if;
end;
$$;