drop function if exists techsupport.chg_group_activity_adv;
create function techsupport.chg_group_activity_adv(gid bigint, i_activity_id bigint) returns text
  security definer
  language plpgsql
as $$
declare
  oldval            text;
  oldval_arr        bigint[];
  newval            text;
  i_activity_id_arr bigint[];
  i_activity_id_p   bigint;
  i_contract_id     bigint[];
  cnt               int;
  cp_id             bigint;
  revision_cnt      bigint;
  gid_row           md.groups%rowtype;
  conp_row          md.contract_property%rowtype;
  upd_id            bigint;
begin
  select array_agg(distinct g.activity_id),
         array_agg(distinct g.contract_id),
         array_remove(array_agg(distinct a.id), null)
  into oldval_arr,i_contract_id,i_activity_id_arr
  from md.groups g
         join md.contract_property cp on g.contract_id = cp.contract_id
         left join reference.activity a on cp.activity_id = a.parent_id and a.id = i_activity_id
  where g.id = gid;
  oldval := oldval_arr[1];
  ---изменение направления активности 3 уровня у группы.
  ---пример вызова
  ---select techsupport.chg_group_activity_adv(id группы,id активности)
  if oldval isnull then return 'oldval_error'; end if;
  if array_length(i_activity_id_arr, 1) > 1 then return 'more_than_one_activity_error'; end if;
  revision_cnt := nextval('public.hibernate_sequence');
  insert into audit.revision (id, timestamp, user_id)
  values (revision_cnt, (trunc(extract(epoch from now()) * 1000)), 1)
  returning id into revision_cnt;
  if i_activity_id_arr[1] isnull then
    raise notice 'isnull';
    with
      L0 as (select cp.id as cp_id
             from reference.activity a
                    join md.contract_property cp on a.parent_id = cp.activity_id
             where a.id = oldval_arr[1]
               and cp.contract_id = i_contract_id[1])
    update md.contract_property
    set group_amount=group_amount - 1
    from L0
    where id = L0.cp_id
    returning * into conp_row;
    if conp_row isnull then return 'Направление не связано с соглашением'; end if;
    if conp_row.group_amount < 0 then return 'old_group_amount_less_zero 1'; end if;
    upd_id = conp_row.id;
    update audit.contract_property_aud
    set revend=revision_cnt,
        revend_timestamp=current_timestamp
    where id = upd_id
      and revend isnull;
    --raise notice '%',conp_row::text;
    insert into audit.contract_property_aud(id, rev, revtype, activity_id, contract_id, grant_value, group_amount)
    values (conp_row.id, revision_cnt, 1, conp_row.activity_id, conp_row.contract_id, conp_row.grant_value,
            conp_row.group_amount);
    
    select a.parent_id into i_activity_id_p from reference.activity a where a.id = i_activity_id;
    
    insert into md.contract_property (contract_id, activity_id, grant_value, group_amount)
    values (i_contract_id[1], i_activity_id_p, 0, 1)
    returning id into cp_id;
    
    insert into audit.contract_property_aud (id, rev, revtype, activity_id, contract_id, grant_value, group_amount)
    select cp.id, 1, 0, cp.activity_id, cp.contract_id, cp.grant_value, cp.group_amount
    from md.contract_property cp
    where cp.id = cp_id;
  
  else
    raise notice 'is not null';
    raise notice 'oldval_arr=%  i_contract_id=%',oldval_arr[1],i_contract_id[1];
    with
      L0 as (select cp.id as cp_id
             from reference.activity a
                    join md.contract_property cp on a.parent_id = cp.activity_id
             where a.id = oldval_arr[1]
               and cp.contract_id = i_contract_id[1])
    update md.contract_property
    set group_amount=group_amount - 1
    from L0
    where id = L0.cp_id
    returning * into conp_row;
    if conp_row isnull then return 'Направление не связано с соглашением'; end if;
    raise notice 'group_amount=%',conp_row::text;
    if conp_row.group_amount < 0 then return 'old_group_amount_less_zero 2'; end if;
    upd_id = conp_row.id;
    update audit.contract_property_aud
    set revend=revision_cnt,
        revend_timestamp=current_timestamp
    where id = upd_id
      and revend isnull;
    insert into audit.contract_property_aud(id, rev, revtype, activity_id, contract_id, grant_value, group_amount)
    values (conp_row.id, revision_cnt, 1, conp_row.activity_id, conp_row.contract_id, conp_row.grant_value,
            conp_row.group_amount);
    
    revision_cnt := nextval('public.hibernate_sequence');
    insert into audit.revision (id, timestamp, user_id)
    values (revision_cnt, (trunc(extract(epoch from now()) * 1000)), 1)
    returning id into revision_cnt;
    
    with
      L0 as (select cp.id as cp_id
             from reference.activity a
                    join md.contract_property cp on a.parent_id = cp.activity_id
             where a.id = i_activity_id_arr[1]
               and cp.contract_id = i_contract_id[1])
    update md.contract_property
    set group_amount=group_amount + 1
    from L0
    where id = L0.cp_id
    returning * into conp_row;
    upd_id = conp_row.id;
    update audit.contract_property_aud
    set revend=revision_cnt,
        revend_timestamp=current_timestamp
    where id = upd_id
      and revend isnull;
    insert into audit.contract_property_aud(id, rev, revtype, activity_id, contract_id, grant_value, group_amount)
    values (conp_row.id, revision_cnt, 1, conp_row.activity_id, conp_row.contract_id, conp_row.grant_value,
            conp_row.group_amount);
  end if;
  
  update md.groups
  set activity_id=i_activity_id
  where id = gid
  returning * into gid_row;
  upd_id = gid_row.id;
  update audit.groups_aud
  set revend=revision_cnt,
      revend_timestamp=current_timestamp
  where id = upd_id
    and revend isnull;
  insert into audit.groups_aud(id, rev, revtype, "comment", esz_code, extend, fact_count, fact_end_date,
                               fact_start_date, max_count, min_count, need_note, order_date,
                               plan_end_date, plan_start_date, public_date, sync, activity_id, contract_id, coworker_id,
                               organization_id, territory_centre_id, "json")
  values (gid_row.id, revision_cnt, 1, gid_row.comment, gid_row.esz_code, gid_row.extend, gid_row.fact_count,
          gid_row.fact_end_date, gid_row.fact_start_date, gid_row.max_count,
          gid_row.min_count, gid_row.need_note, gid_row.order_date, gid_row.plan_end_date, gid_row.plan_start_date,
          gid_row.public_date, gid_row.sync, gid_row.activity_id,
          gid_row.contract_id, gid_row.coworker_id, gid_row.organization_id, gid_row.territory_centre_id, gid_row.json);
  ----
  insert into techsupport.fnk_log(name_fnk, input_param, old_val, new_val)
  values ('chg_group_activity_adv', gid, oldval, gid_row.activity_id);
  ----
  return 'success';
exception
  when others then return 'error';
end;
$$;