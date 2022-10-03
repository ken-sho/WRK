drop function if exists techsupport.chg_groups_max_count;----release 26.01.2022
create function techsupport.chg_groups_max_count(i_group_id bigint, max_cnt integer) returns text
  security definer
  language plpgsql
as $$
DECLARE
  min_cnt bigint;
  revision_cnt bigint;
  gid_row md.groups%rowtype;
  gid_row_old md.groups%rowtype;
  upd_id bigint;
BEGIN
  select coalesce(min_count,0) into min_cnt
  from md.groups g where g.id=i_group_id;
  ---https://jira.mos.social/browse/MDP-1003
  ---изменение максимального числа участников в группе
  ---пример вызова
  ---select techsupport.chg_groups_max_count('id группы',max_cnt)
  if min_cnt isnull then return 'Указанной группы не существует'; end if;
  if max_cnt<min_cnt then return 'Недопустимое значение входного параметра'; end if;
  select * into gid_row_old from md.groups g where g.id=i_group_id;
  update md.groups
  set max_count=max_cnt
  where
  id=i_group_id
  returning * into gid_row;
  revision_cnt:=nextval('public.hibernate_sequence');
  insert into audit.revision (id, timestamp, user_id)
  values(revision_cnt,(trunc(extract(epoch from now())*1000)),1) returning id into revision_cnt;
  upd_id=gid_row.id;
      update audit.groups_aud
      set revend=revision_cnt,
          revend_timestamp=CURRENT_TIMESTAMP
      where id=upd_id and revend isnull;
  insert into audit.groups_aud(id, rev, revtype, comment, esz_code, extend, fact_count, fact_end_date,
                               fact_start_date, max_count, min_count, need_note, order_date, plan_end_date, plan_start_date,
                               public_date, sync, activity_id, contract_id, coworker_id, organization_id, territory_centre_id,
                               "json", is_archived, parent_group_id, child_group_id, copy_number)
  values(gid_row.id, revision_cnt, 1, gid_row.comment, gid_row.esz_code, gid_row.extend, gid_row.fact_count, gid_row.fact_end_date,
                               gid_row.fact_start_date, gid_row.max_count, gid_row.min_count, gid_row.need_note, gid_row.order_date,
                               gid_row.plan_end_date, gid_row.plan_start_date, gid_row.public_date, gid_row.sync, gid_row.activity_id,
                               gid_row.contract_id, gid_row.coworker_id, gid_row.organization_id, gid_row.territory_centre_id,
                               gid_row."json", gid_row.is_archived, gid_row.parent_group_id, gid_row.child_group_id, gid_row.copy_number);
  ----
  insert into techsupport.fnk_log(name_fnk, input_param, old_val, new_val)
  values ('chg_groups_max_count',i_group_id::text,gid_row_old::text,gid_row::text);
  ----
	return 'success';
  exception when others then return 'error';
END;
$$;