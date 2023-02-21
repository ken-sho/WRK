drop function if exists techsupport.add_contract_property;
create function techsupport.add_contract_property(i_contract_id bigint,i_activity_id bigint) returns text
  language plpgsql
as $$
DECLARE
  act1 bigint;
  act2 bigint;
  cnt integer;
  cp_row md.contract_property%rowtype;
  revision_cnt bigint;
  upd_id bigint;
  i_old_val text;
  row record;
  lid bigint;
BEGIN

  ---добавление направления активности 2-го уровня в свойства Соглашения
  ---пример вызова
  ---select techsupport.add_contract_property(i_contract_id,i_activity_id)
  ---https://jira.mos.social/browse/MDP-400
  ---Проверка на отсуствие активности свойствах Соглашения
  select count(*) into cnt
  from md.contract_property cp
  where
  cp.contract_id=i_contract_id
  and cp.activity_id=i_activity_id;
  if cnt>0 then return 'Направление активности уже присутствует в свойствах Соглашения'; end if;
  ---
  select
  a1.parent_id,a2.parent_id into act1,act2
  from reference.activity a1
       join reference.activity a2 on a1.parent_id = a2.id
  where
  a1.id=i_activity_id;
  ----Проверка что добавляемое напрявление 2 уровня
  if act1 is not null and act2 isnull then
  ----
    insert into md.contract_property(contract_id, activity_id, grant_value, group_amount)
    values(i_contract_id,i_activity_id,0,0) returning * into cp_row;
    
    revision_cnt := nextval('public.hibernate_sequence');
    raise notice 'revision_cnt %',revision_cnt;
    insert into audit.revision (id, timestamp, user_id)
    values (revision_cnt, (trunc(extract(epoch from now()) * 1000)), 1)
    returning id into revision_cnt;
      
    insert into audit.contract_property_aud(id, rev, revtype, activity_id, contract_id, grant_value, group_amount)
    values (cp_row.id, revision_cnt, 0, cp_row.activity_id, cp_row.contract_id, cp_row.grant_value, cp_row.group_amount);

    insert into techsupport.fnk_log(name_fnk, input_param, new_val,user_name)
    values ('add_contract_property',i_activity_id::text,cp_row,current_user);
  else return 'Добавляемое направление активности не является направлением активности 2-го уровня';
  end if;
	return 'success';
  exception when others then return 'error';
END;
$$;