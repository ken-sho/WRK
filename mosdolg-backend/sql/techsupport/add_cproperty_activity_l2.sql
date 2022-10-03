drop function if exists techsupport.add_cproperty_activity_l2;
create function techsupport.add_cproperty_activity_l2(cid bigint, i_activity_id bigint) returns text
  security definer
  language plpgsql
as $$
declare
    cp_cnt               int;
    act_cnt_l1               int;
    act_cnt_l2               int;
    revision_cnt bigint;
    conp_row md.contract_property%rowtype;
    g_amount bigint;
  begin
    select
      count(*) into cp_cnt
    from md.contract_property cp
    where cp.contract_id=cid
    and cp.activity_id=i_activity_id;
    select a1.parent_id,a2.parent_id into act_cnt_l2,act_cnt_l1
    from reference.activity a1
         join reference.activity a2 on a1.parent_id=a2.id
    where
    a1.id=i_activity_id;
    ---добавление направления активности 2 уровня у группы.
    ---https://jira.mos.social/browse/MDP-400
    ---пример вызова
    ---select techsupport.add_cproperty_activity_l2(id соглашения,id активности)
    if cp_cnt!=0 then return 'Добавляемое направление активности уже присутствует в свойствах Соглашения'; end if;
    if act_cnt_l2 isnull or act_cnt_l1 is not null then return 'Добавляемое направление активности не является направлением активности 2-го уровня'; end if;
    select
    count(*) into g_amount
    from md.groups g
    where g.activity_id=i_activity_id;
    revision_cnt:=nextval('public.hibernate_sequence');
    insert into audit.revision (id, timestamp, user_id)
    values(revision_cnt,(trunc(extract(epoch from now())*1000)),1) returning id into revision_cnt;
    insert into md.contract_property(contract_id, activity_id, grant_value, group_amount)
    values(cid,i_activity_id,0,(g_amount+1)) returning * into conp_row;
    insert into audit.contract_property_aud(id, rev, revtype, activity_id, contract_id, grant_value, group_amount)
    values (conp_row.id,revision_cnt,0,cid,i_activity_id,0,(g_amount+1));
    ----
    insert into techsupport.fnk_log(name_fnk, input_param, new_val)
    values ('add_cproperty_activity_l2',cid,conp_row.activity_id);
    ----
    return 'success';
    exception when others then return 'error';
  end;
$$;