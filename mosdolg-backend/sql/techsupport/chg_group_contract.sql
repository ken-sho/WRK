drop function if exists techsupport.chg_group_contract;
create function techsupport.chg_group_contract(gid bigint, i_contract bigint) returns text
  security definer
  language plpgsql
as $$
declare
  oldval        text;
  old_org_id    bigint;
  old_prov_id   bigint;
  old_stt       bigint;
  old_gstt      bigint;
  old_gpdateb   timestamp;
  old_gpdatee   timestamp;
  old_gsgroup   bigint;
  new_org_id    bigint;
  new_prov_id   bigint;
  new_stt       bigint;
  new_stt_dateb timestamp;
  revision_cnt  bigint;
  gid_row       md.groups%rowtype;
  upd_id        bigint;
  c_amount numeric;
  klt_id bigint;
begin
  select g.contract_id,
         c.provider_id,
         c.organization_id,
         csr.status_id,
         gsr.status_id,
         --gsr.start_date,
         gsr.planned_start_date,
         gsr.planned_end_date,
         gsr.supporting_group_id,
         c.amount,
         klt.id as klt_id
  into oldval,old_prov_id,old_org_id,old_stt,old_gstt,old_gpdateb,old_gpdatee,old_gsgroup,
    c_amount,klt_id
  from md.groups g
         join md.contract c on g.contract_id = c.id
         join md.contract_status_registry csr on c.id = csr.contract_id
         join md.group_status_registry gsr on g.id = gsr.group_id
         left join md.kbk_limit_turnover klt on c.id = klt.contract_id
  where g.id = gid
    and csr.end_date is null
    and gsr.end_date isnull
    and gsr.is_expectation = false;
  select c.provider_id, c.organization_id, csr.status_id, csr.start_date
  into new_prov_id,new_org_id,new_stt,new_stt_dateb
  from md.contract c
         join md.contract_status_registry csr on c.id = csr.contract_id
  where c.id = i_contract
    and csr.end_date is null;
  ---изменение у группы
  ---пример вызова
  ---select techsupport.chg_group_contract(id группы,id контракта)
  ---проверки
  if oldval isnull then return 'no_group'; end if;
  if c_amount!=0 then  return 'contract_amount_notzero'; end if;
  if klt_id is not null then return 'kbk_limit_turnover_exists'; end if;
  if old_org_id != coalesce(new_org_id, 0) or old_prov_id != coalesce(new_prov_id, 0) then return 'different_organizations'; end if;
  if old_stt not in (1, 5) then return 'bad_old_status'; end if;
  if old_stt = 1 and new_stt not in (1, 5) then return 'bad_new_status'; end if;
  if old_stt = 5 and new_stt != 5 then return 'bad_new_status'; end if;
  revision_cnt := nextval('public.hibernate_sequence');
  insert into audit.revision (id, timestamp, user_id)
  values (revision_cnt, (trunc(extract(epoch from now()) * 1000)), 1::varchar)
  returning id into revision_cnt;
  ----update group_status_registry
  if old_gstt = 2 and old_stt = 1 and new_stt = 5 then
    update md.group_status_registry
    set end_date=CURRENT_TIMESTAMP
    where end_date isnull
      and is_expectation = false;
    insert into md.group_status_registry(group_id, status_id, start_date, end_date, is_expectation,
                                         planned_start_date, planned_end_date, supporting_group_id)
    values (gid, 3, CURRENT_TIMESTAMP, null, false, old_gpdateb, old_gpdatee, old_gsgroup);
  end if;
  ----update groups
  update md.groups
  set contract_id=i_contract
  where id = gid
  returning * into gid_row;
  upd_id = gid_row.id;
  update audit.groups_aud
  set revend=revision_cnt,
      revend_timestamp=CURRENT_TIMESTAMP
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
  ----log
  insert into techsupport.fnk_log(name_fnk, input_param, old_val, new_val)
  values ('chg_group_contract', gid, oldval, gid_row.contract_id);
  ----
  return 'success';
exception
  when others then return 'error';
end;
$$;