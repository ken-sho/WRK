drop function if exists techsupport.chg_group_activity;
create function techsupport.chg_group_activity(gid bigint, i_title text) returns text
  security definer
  language plpgsql
as $$
DECLARE
  oldval text;
  oldval_arr bigint[];
  newval text;
  i_activity_id bigint[];
  i_contract_id bigint[];
  cnt int;
  revision_cnt bigint;
  conp_row md.contract_property%rowtype;
  gid_row md.groups%rowtype;
  upd_id bigint;
  row record;
BEGIN
select array_agg(g.activity_id),array_agg(g.contract_id),array_agg(a.id),count(*)
       into oldval_arr,i_contract_id,i_activity_id,cnt
from md.groups g
     join md.contract_property cp on g.contract_id=cp.contract_id
     join reference.activity a on cp.activity_id=a.parent_id
where g.id=gid and trim(a.title)=i_title
group by trim(a.title);
oldval:=oldval_arr[1];
  ---изменение направления активности 3 уровня у группы.
  ---пример вызова
  ---select techsupport.chg_group_activity('номер группы (id группы,'наименование _активности_текст')
  --if oldval isnull then return 'oldval_error'; end if;
  if oldval isnull then return 'Направления нет в соглашении'; end if;
  if cnt>1 then return 'more_than_one_activity_error'; end if;
  revision_cnt:=nextval('public.hibernate_sequence');
  insert into audit.revision (id, timestamp, user_id)
  values(revision_cnt,(trunc(extract(epoch from now())*1000)),1) returning id into revision_cnt;
  for row in
       select cp.id as cp_id
       from reference.activity a
            join md.contract_property cp on a.parent_id = cp.activity_id
       where a.id = oldval_arr[1]
       and cp.contract_id = i_contract_id[1]
   loop
        update md.contract_property
        set group_amount=group_amount-1
        where id=row.cp_id returning * into conp_row;
        if conp_row.group_amount<0 then raise exception 'old_group_amount_less_zero'; end if;
        upd_id=conp_row.id;
        update audit.contract_property_aud
        set revend=revision_cnt,
            revend_timestamp=CURRENT_TIMESTAMP
        where id=upd_id and revend isnull;
        insert into audit.contract_property_aud(id, rev, revtype, activity_id, contract_id, grant_value, group_amount)
        values (conp_row.id,revision_cnt,1,conp_row.activity_id,conp_row.contract_id,conp_row.grant_value,conp_row.group_amount);
   end loop;
  revision_cnt:=nextval('public.hibernate_sequence');
  insert into audit.revision (id, timestamp, user_id)
  values(revision_cnt,(trunc(extract(epoch from now())*1000)),1) returning id into revision_cnt;
   for row in
       select cp.id as cp_id
       from reference.activity a
            join md.contract_property cp on a.parent_id = cp.activity_id
       where a.id = i_activity_id[1]
       and cp.contract_id = i_contract_id[1]
    loop
        update md.contract_property
        set group_amount=group_amount+1
        where id=row.cp_id
        returning * into conp_row;
        upd_id=conp_row.id;
        update audit.contract_property_aud
        set revend=revision_cnt,
            revend_timestamp=CURRENT_TIMESTAMP
        where id=upd_id and revend isnull;
        insert into audit.contract_property_aud(id, rev, revtype, activity_id, contract_id, grant_value, group_amount)
        values (conp_row.id,revision_cnt,1,conp_row.activity_id,conp_row.contract_id,conp_row.grant_value,conp_row.group_amount);
  end loop;
  update md.groups
  set activity_id=i_activity_id[1]
  where id=gid returning * into gid_row;
  upd_id=gid_row.id;
    update audit.groups_aud
    set revend=revision_cnt,
        revend_timestamp=CURRENT_TIMESTAMP
    where id=upd_id and revend isnull;
    insert into audit.groups_aud(id, rev, revtype, "comment", esz_code, extend, fact_count, fact_end_date, fact_start_date, max_count, min_count, need_note, order_date,
                                 plan_end_date, plan_start_date, public_date, sync, activity_id, contract_id, coworker_id, organization_id, territory_centre_id, "json")
    values (gid_row.id,revision_cnt,1,gid_row.comment,gid_row.esz_code,gid_row.extend,gid_row.fact_count,gid_row.fact_end_date,gid_row.fact_start_date,gid_row.max_count,
            gid_row.min_count,gid_row.need_note,gid_row.order_date,gid_row.plan_end_date,gid_row.plan_start_date,gid_row.public_date,gid_row.sync,gid_row.activity_id,
            gid_row.contract_id,gid_row.coworker_id,gid_row.organization_id,gid_row.territory_centre_id,gid_row.json);
  ----
  insert into techsupport.fnk_log(name_fnk, input_param, old_val, new_val)
  values ('chg_group_activity',gid,oldval,gid_row.activity_id);
  ----
	return 'success';
  --exception when others then return 'error';
END;
$$;