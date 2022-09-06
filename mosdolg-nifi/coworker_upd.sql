--select * from test.coworker_update
/*
 create table test.coworker_update (
  cw_id          bigint[],
  cw_id_good     bigint,
  cw_id_bad      bigint[],
  note           text,
  status         integer,
  org_id         bigint,
  is_teacher     boolean,
  is_coordinator boolean,
  is_deputy      boolean,
  is_director    boolean,
  manager_id     bigint,
  position       text
);
 */
do $$----phaze 1
  declare
    i_cw_id           bigint;
    cnt               int;
    cnt2              int;
    array_bint        bigint[];
    ar_is_teacher     bool[];
    ar_is_deputy      bool[];
    ar_is_director    bool[];
    ar_is_coordinator bool[];
    ar_manager        bigint[];
    ar_position       text[];
    case_1 cursor for
      with
        L0 as (
          select array_agg(distinct cw.id)                                                 as cw_id,
                 array_remove(array_agg(distinct coalesce(stc.coworker_id, 0)), 0::bigint) as stc_id,
                 array_remove(array_agg(distinct coalesce(g.coworker_id, 0)), 0::bigint)   as coworker_group,
                 cw.organization_id
          from md.coworker cw
                 left join md.schedule_timesheet_coworkers stc on cw.id = stc.coworker_id
                 left join md.groups g on cw.id = g.coworker_id
          
          group by trim(concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name)), cw.organization_id
          --having count(*) > 1
        )
      select L0.*, L0.stc_id || L0.coworker_group as all_cw
      from L0
      where array_length(L0.cw_id, 1) > 1
        and (array_length(L0.stc_id, 1) >= 1 or array_length(L0.coworker_group, 1) >= 1);
    case_other cursor for
      with
        L0 as (
          select array_agg(distinct cw.id)                                                 as cw_id,
                 array_remove(array_agg(distinct coalesce(stc.coworker_id, 0)), 0::bigint) as stc_id,
                 array_remove(array_agg(distinct coalesce(g.coworker_id, 0)), 0::bigint)   as coworker_group,
                 cw.organization_id
          from md.coworker cw
                 left join md.schedule_timesheet_coworkers stc on cw.id = stc.coworker_id
                 left join md.groups g on cw.id = g.coworker_id
          
          group by trim(concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name)), cw.organization_id
          --having count(*) > 1
        )
      select L0.*
      from L0
      where array_length(L0.cw_id, 1) > 1
        and array_length(L0.stc_id, 1) isnull
        and array_length(L0.coworker_group, 1) isnull;
  begin
    for Vres in case_1
      loop
        select min(unnest), count(distinct (unnest)) into i_cw_id,cnt from unnest(Vres.cw_id);
        if coalesce(cnt, 0) > 1 then
          
          select count(*),
                 array_agg(distinct cw.id),
                 array_agg(distinct cw.is_teacher),
                 array_agg(distinct cw.is_coordinator),
                 array_agg(distinct cw.is_deputy),
                 array_agg(distinct cw.is_director),
                 array_agg(distinct cw.manager_id),
                 array_remove(array_agg(distinct cw.position), null)
          into cnt2,array_bint,ar_is_teacher,ar_is_coordinator,ar_is_deputy,ar_is_director,ar_manager,ar_position
          from md.coworker cw
                 join unnest(Vres.cw_id) on cw.id = unnest.unnest;
          ar_manager := array_remove(ar_manager, null);
          if array_length(ar_manager, 1) > 1 then
            insert into test.coworker_update(cw_id, cw_id_good, cw_id_bad, note, status, org_id)
            values (Vres.cw_id, i_cw_id, array_remove(Vres.cw_id, i_cw_id), 'Несколько manager_id', 0,
                    Vres.organization_id);
          else
            insert into test.coworker_update(cw_id, cw_id_good, cw_id_bad, note, status, org_id)
            values (Vres.cw_id, i_cw_id, array_remove(Vres.cw_id, i_cw_id), 'success', 1, Vres.organization_id);
            update test.coworker_update
            set is_teacher=(case when true = any (ar_is_teacher) then true else false end),
                is_coordinator=(case when true = any (ar_is_coordinator) then true else false end),
                is_deputy=(case when true = any (ar_is_deputy) then true else false end),
                is_director=(case when true = any (ar_is_director) then true else false end),
                manager_id=ar_manager[1],
                position=ar_position[1]
            where cw_id_good = i_cw_id;
          end if;
        else---Когда 1 уникальный коворкер в расписаниях+координаторы
          insert into test.coworker_update(cw_id, cw_id_good, cw_id_bad, note, status, org_id)
          values (Vres.cw_id, i_cw_id, array_remove(Vres.cw_id, i_cw_id), 'success', 1, Vres.organization_id);
          with
            L0 as (
              select cw.is_teacher     as cw_is_teacher,
                     cw.is_coordinator as cw_is_coordinator,
                     cw.is_deputy      as cw_is_deputy,
                     cw.is_director    as cw_is_director,
                     cw.manager_id     as cw_manager_id
              from md.coworker cw
              where cw.id = i_cw_id
            )
          update test.coworker_update
          set is_teacher=L0.cw_is_teacher,
              is_coordinator=L0.cw_is_coordinator,
              is_deputy=L0.cw_is_deputy,
              is_director=L0.cw_is_director,
              manager_id=L0.cw_manager_id
          from L0
          where cw_id_good = i_cw_id;
        end if;
      end loop;
    for Vres in case_other
      loop
        select min(unnest) into i_cw_id from unnest(Vres.cw_id);
        
        insert into test.coworker_update(cw_id, cw_id_good, cw_id_bad, note, status, org_id)
        values (Vres.cw_id, i_cw_id, array_remove(Vres.cw_id, i_cw_id), 'success', 2, Vres.organization_id);
        with
          L0 as (
            select array_agg(distinct cw.is_teacher)                     as ar_is_teacher,
                   array_agg(distinct cw.is_coordinator)                 as ar_is_coordinator,
                   array_agg(distinct cw.is_deputy)                      as ar_is_deputy,
                   array_agg(distinct cw.is_director)                    as ar_is_director,
                   array_remove(array_agg(distinct cw.manager_id), null) as ar_manager,
                   array_remove(array_agg(distinct cw.position), null) as ar_position
            from md.coworker cw
                   join unnest(Vres.cw_id) on cw.id = unnest.unnest
          )
        update test.coworker_update
        set is_teacher=(case when true = any (L0.ar_is_teacher) then true else false end),
            is_coordinator=(case when true = any (L0.ar_is_coordinator) then true else false end),
            is_deputy=(case when true = any (L0.ar_is_deputy) then true else false end),
            is_director=(case when true = any (L0.ar_is_director) then true else false end),
            manager_id=L0.ar_manager[1],
            position=L0.ar_position[1]
        from L0
        where cw_id_good = i_cw_id;
      end loop;
    -----заменяем мертвых манагеров
    with
      L0 as (
        select cu.manager_id from test.coworker_update cu where cu.manager_id is not null
      ),
      L1 as (
        select cu.manager_id as cu_manager_id, cu.cw_id_good
        from test.coworker_update cu
               join L0 on L0.manager_id = any (cu.cw_id_bad)
      )
    update test.coworker_update
    set manager_id=L1.cw_id_good
    from L1
    where manager_id = L1.cu_manager_id;
  
  end;
$$ language plpgsql;

do $$----phaze 2
  declare
    ar_text      text[];
    i_contact    text;
    cnt          integer;
    cnt2         integer;
    cntall       integer;
    jsonb_val    jsonb;
    jsonb_val_c  jsonb;
    json_result  jsonb;
    row          record;
    roww         record;
    revision_cnt bigint;
    upd_id       bigint;
    cwcon_row    md.coworker_contact%ROWTYPE;
    cw_row       md.coworker%ROWTYPE;
    g_row        md.groups%ROWTYPE;
    main_tbl cursor for
      select cw_id,
             cw_id_good,
             cw_id_bad,
             note,
             status,
             is_teacher     as iis_teacher,
             is_coordinator as iis_coordinator,
             is_deputy      as iis_deputy,
             is_director    as iis_director,
             manager_id     as i_manager_id,
             position       as i_position
      from test.coworker_update cu;
  begin
    cntall := 0;
    select max(id) into revision_cnt from audit.revision;
    insert into audit.revision (id, timestamp, user_id)
    values ((revision_cnt + 1), (trunc(extract(epoch from now()) * 1000)), 1::varchar)
    returning id into revision_cnt;
    for Vres in main_tbl
      loop
        for row in select * from unnest(Vres.cw_id_bad)
          loop
            for roww in select cw.id as cw_id from md.coworker cw where cw.manager_id = row.unnest
              loop
                update md.coworker
                set manager_id=null
                where id = roww.cw_id
                returning * into cw_row;
                if cw_row.id is not null then
                  upd_id := cw_row.id;
                  update audit.coworker_aud
                  set revend=revision_cnt,
                      revend_timestamp=CURRENT_TIMESTAMP
                  where id = upd_id
                    and revend isnull;
                  insert into audit.coworker_aud(id, rev, revtype, fired_date, first_name, idm_sid, is_coordinator,
                                                 is_deputy, is_director, is_teacher, middle_name, position, second_name,
                                                 manager_id, organization_id)
                  values (cw_row.id, revision_cnt, 1, cw_row.fired_date, cw_row.first_name, cw_row.idm_sid,
                          cw_row.is_coordinator, cw_row.is_deputy,
                          cw_row.is_director, cw_row.is_teacher, cw_row.middle_name, cw_row.position,
                          cw_row.second_name, cw_row.manager_id, cw_row.organization_id);
                end if;
              end loop;
          end loop;
        cntall := cntall + 1;
        if cntall % 1000 = 0 then
          raise notice 'count_manager: %', quote_ident(cntall::text);
        end if;
      end loop;
    cntall := 0;
    for Vres in main_tbl
      loop
        select---Groups
              count(*),
              jsonb_object_agg(g.coworker_id, g.id)
        into cnt,jsonb_val
        from md.groups g
               join unnest(Vres.cw_id_bad) on g.coworker_id = unnest.unnest;
        if coalesce(cnt, 0) > 0 then
          json_result := jsonb_build_object('groups', jsonb_val);
          raise notice 'Groups: %', quote_ident(jsonb_val::text);
          for row in select distinct g.id as gid
                     from md.groups g
                            join unnest(Vres.cw_id_bad) on g.coworker_id = unnest.unnest
            loop
              update md.groups
              set coworker_id=Vres.cw_id_good
              where id = row.gid
              returning * into g_row;
              if g_row.id is not null then
                upd_id := g_row.id;
                update audit.groups_aud
                set revend=revision_cnt,
                    revend_timestamp=CURRENT_TIMESTAMP
                where id = upd_id
                  and revend isnull;
                
                insert into audit.groups_aud(id, rev, revtype, "comment", esz_code, extend, fact_count, fact_end_date,
                                             fact_start_date, max_count, min_count,
                                             need_note, order_date, plan_end_date, plan_start_date, public_date, sync,
                                             activity_id, contract_id, coworker_id, organization_id,
                                             territory_centre_id, "json")
                values (g_row.id, revision_cnt, 1, g_row."comment", g_row.esz_code, g_row.extend, g_row.fact_count,
                        g_row.fact_end_date, g_row.fact_start_date, g_row.max_count,
                        g_row.min_count, g_row.need_note, g_row.order_date, g_row.plan_end_date, g_row.plan_start_date,
                        g_row.public_date, g_row.sync, g_row.activity_id, g_row.contract_id,
                        g_row.coworker_id, g_row.organization_id, g_row.territory_centre_id, g_row."json");
              end if;
            end loop;
        else
          json_result := jsonb_build_object('groups', null);
        end if;
        ------
        select---group_status_registry
              count(*),
              jsonb_object_agg(gsr.initiator, gsr.id)
        into cnt,jsonb_val
        from md.group_status_registry gsr
               join unnest(Vres.cw_id_bad) on gsr.initiator = unnest.unnest;
        if coalesce(cnt, 0) > 0 then
          json_result := json_result || jsonb_build_object('gsr', jsonb_val);
          raise notice 'group_status_registry: %', quote_ident(jsonb_val::text);
          with
            L0 as (
              select distinct
                     gsr.id as gsrid
              from md.group_status_registry gsr
                     join unnest(Vres.cw_id_bad) on gsr.initiator = unnest.unnest
            )
          update md.group_status_registry
          set initiator=Vres.cw_id_good
          from L0
          where id = L0.gsrid;
        else
          json_result := json_result || jsonb_build_object('gsr', null);
        end if;
        ------
        select---schedule_timesheet_coworkers
              count(*),
              jsonb_object_agg(stc.coworker_id, stc.id)
        into cnt,jsonb_val
        from md.schedule_timesheet_coworkers stc
               join unnest(Vres.cw_id_bad) on stc.coworker_id = unnest.unnest;
        if coalesce(cnt, 0) > 0 then
          json_result := json_result || jsonb_build_object('stc', jsonb_val);
          raise notice 'schedule_timesheet_coworkers: %', quote_ident(jsonb_val::text);
          for row in select distinct stc.id as stcid
                     from md.schedule_timesheet_coworkers stc
                            join unnest(Vres.cw_id_bad) on stc.coworker_id = unnest.unnest
            loop
              update md.schedule_timesheet_coworkers
              set coworker_id=Vres.cw_id_good
              where id = row.stcid;
            end loop;
        else
          json_result := json_result || jsonb_build_object('stc', null);
        end if;
        ------------Phone
        select jsonb_object_agg('priority_' || cc.priority, cc.value)
        into jsonb_val_c
        from md.coworker_contact cc
        where cc.owner_id = Vres.cw_id_good
          and cc.contact_type_id = 1;
        
        if jsonb_val_c -> 'priority_0' isnull and jsonb_val_c -> 'priority_1' isnull then
          select---contact
                count(*),
                jsonb_object_agg(cc.owner_id, cc.id),
                array_remove(array_agg(distinct cc.value),null)
          into cnt2,jsonb_val,ar_text
          from md.coworker_contact cc
                 join unnest(Vres.cw_id) on cc.owner_id = unnest.unnest
          where contact_type_id = 1;
          if cnt2 > 0 then
            insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
            values (Vres.cw_id_good, 1, ar_text[1], 0, 1)
            returning * into cwcon_row;
            ar_text := array_remove(ar_text, cwcon_row.value::text);
            insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                    owner_id, contact_type_id)
            values (cwcon_row.id, 1, 0, cwcon_row.priority, cwcon_row.value, cwcon_row.contact_availability_type_id,
                    cwcon_row.owner_id, cwcon_row.contact_type_id);
            if array_length(ar_text, 1) > 0 and array_length(ar_text, 1) is not null then
              select string_agg(unnest.unnest, ', ') into i_contact from unnest(ar_text);
              insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
              values (Vres.cw_id_good, 1, i_contact, 1, 1)
              returning * into cwcon_row;
              insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                      owner_id, contact_type_id)
              values (cwcon_row.id, 1, 0, cwcon_row.priority, cwcon_row.value, cwcon_row.contact_availability_type_id,
                      cwcon_row.owner_id, cwcon_row.contact_type_id);
            end if;
          end if;
        else
          if jsonb_val_c -> 'priority_0' is not null and jsonb_val_c -> 'priority_1' isnull then
            select---contact
                  count(*),
                  jsonb_object_agg(cc.owner_id, cc.id),
                  array_remove(array_agg(distinct cc.value),null)
            into cnt2,jsonb_val,ar_text
            from md.coworker_contact cc
                   join unnest(Vres.cw_id_bad) on cc.owner_id = unnest.unnest
            where contact_type_id = 1;
            if cnt2 > 0 then
              select string_agg(distinct unnest.unnest, ', ') into i_contact from unnest(ar_text);
              insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
              values (Vres.cw_id_good, 1, i_contact, 1, 1)
              returning * into cwcon_row;
              insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                      owner_id, contact_type_id)
              values (cwcon_row.id, 1, 0, cwcon_row.priority, cwcon_row.value, cwcon_row.contact_availability_type_id,
                      cwcon_row.owner_id, cwcon_row.contact_type_id);
            end if;
          else
            if jsonb_val_c -> 'priority_0' is not null and jsonb_val_c -> 'priority_1' is not null then
              select---contact
                    count(*),
                    jsonb_object_agg(cc.owner_id, cc.id),
                    array_remove(array_agg(distinct cc.value),null)
              into cnt2,jsonb_val,ar_text
              from md.coworker_contact cc
                     join unnest(Vres.cw_id_bad) on cc.owner_id = unnest.unnest
              where contact_type_id = 1;
              if cnt2 > 0 then
                ar_text := array_append(ar_text, jsonb_val_c ->> 'priority_1');
                select string_agg(distinct unnest.unnest, ', ') into i_contact from unnest(ar_text);
                delete
                from md.coworker_contact cc
                where cc.owner_id = Vres.cw_id_good and cc.contact_type_id = 1 and cc.priority = 1;
                insert into md.coworker_contact(owner_id, contact_type_id, value, priority,
                                                contact_availability_type_id)
                values (Vres.cw_id_good, 1, i_contact, 1, 1)
                returning * into cwcon_row;
                insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                        owner_id, contact_type_id)
                values (cwcon_row.id, 1, 0, cwcon_row.priority, cwcon_row.value, cwcon_row.contact_availability_type_id,
                        cwcon_row.owner_id, cwcon_row.contact_type_id);
              end if;
            end if;
          end if;
        end if;
        json_result := json_result || jsonb_build_object('contact_phone', jsonb_val_c);
        with
          L0 as (
            select cc.id as cc_id
            from md.coworker_contact cc
                   join unnest(Vres.cw_id_bad) on cc.owner_id = unnest.unnest
            where cc.contact_type_id = 1
          )
        delete
        from md.coworker_contact cc
        where cc.id in (select L0.cc_id from L0);
        ------------email
        select jsonb_object_agg('priority_' || cc.priority, cc.value)
        into jsonb_val_c
        from md.coworker_contact cc
        where cc.owner_id = Vres.cw_id_good
          and cc.contact_type_id = 2;
        
        if jsonb_val_c -> 'priority_0' isnull and jsonb_val_c -> 'priority_1' isnull then
          select---contact
                count(*),
                jsonb_object_agg(cc.owner_id, cc.id),
                array_remove(array_agg(distinct cc.value),null)
          into cnt2,jsonb_val,ar_text
          from md.coworker_contact cc
                 join unnest(Vres.cw_id) on cc.owner_id = unnest.unnest
          where contact_type_id = 2;
          if cnt2 > 0 then
            insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
            values (Vres.cw_id_good, 2, ar_text[1], 0, 1)
            returning * into cwcon_row;
            ar_text := array_remove(ar_text, cwcon_row.value::text);
            insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                    owner_id, contact_type_id)
            values (cwcon_row.id, 1, 0, cwcon_row.priority, cwcon_row.value, cwcon_row.contact_availability_type_id,
                    cwcon_row.owner_id, cwcon_row.contact_type_id);
            if array_length(ar_text, 1) > 0 and array_length(ar_text, 1) is not null then
              select string_agg(unnest.unnest, ', ') into i_contact from unnest(ar_text);
              insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
              values (Vres.cw_id_good, 2, i_contact, 1, 1)
              returning * into cwcon_row;
              insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                      owner_id, contact_type_id)
              values (cwcon_row.id, 1, 0, cwcon_row.priority, cwcon_row.value, cwcon_row.contact_availability_type_id,
                      cwcon_row.owner_id, cwcon_row.contact_type_id);
            end if;
          end if;
        else
          if jsonb_val_c -> 'priority_0' is not null and jsonb_val_c -> 'priority_1' isnull then
            select---contact
                  count(*),
                  jsonb_object_agg(cc.owner_id, cc.id),
                  array_remove(array_agg(distinct cc.value),null)
            into cnt2,jsonb_val,ar_text
            from md.coworker_contact cc
                   join unnest(Vres.cw_id_bad) on cc.owner_id = unnest.unnest
            where contact_type_id = 2;
            if cnt2 > 0 then
              select string_agg(distinct unnest.unnest, ', ') into i_contact from unnest(ar_text);
              insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
              values (Vres.cw_id_good, 2, i_contact, 1, 1)
              returning * into cwcon_row;
              insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                      owner_id, contact_type_id)
              values (cwcon_row.id, 1, 0, cwcon_row.priority, cwcon_row.value, cwcon_row.contact_availability_type_id,
                      cwcon_row.owner_id, cwcon_row.contact_type_id);
            end if;
          else
            if jsonb_val_c -> 'priority_0' is not null and jsonb_val_c -> 'priority_1' is not null then
              select---contact
                    count(*),
                    jsonb_object_agg(cc.owner_id, cc.id),
                    array_remove(array_agg(distinct cc.value),null)
              into cnt2,jsonb_val,ar_text
              from md.coworker_contact cc
                     join unnest(Vres.cw_id_bad) on cc.owner_id = unnest.unnest
              where contact_type_id = 2;
              if cnt2 > 0 then
                ar_text := array_append(ar_text, jsonb_val_c ->> 'priority_1');
                select string_agg(distinct unnest.unnest, ', ') into i_contact from unnest(ar_text);
                delete
                from md.coworker_contact cc
                where cc.owner_id = Vres.cw_id_good and cc.contact_type_id = 2 and cc.priority = 1;
                insert into md.coworker_contact(owner_id, contact_type_id, value, priority,
                                                contact_availability_type_id)
                values (Vres.cw_id_good, 2, i_contact, 1, 1)
                returning * into cwcon_row;
                insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                        owner_id, contact_type_id)
                values (cwcon_row.id, 1, 0, cwcon_row.priority, cwcon_row.value, cwcon_row.contact_availability_type_id,
                        cwcon_row.owner_id, cwcon_row.contact_type_id);
              end if;
            end if;
          end if;
        end if;
        with
          L0 as (
            select cc.id as cc_id
            from md.coworker_contact cc
                   join unnest(Vres.cw_id_bad) on cc.owner_id = unnest.unnest
            where cc.contact_type_id = 2
          )
        delete
        from md.coworker_contact cc
        where cc.id in (select L0.cc_id from L0);
        json_result := json_result || jsonb_build_object('contact_email', jsonb_val_c);
        --RAISE NOTICE 'contact';
        ---------УДАЛЕНИЕ финал 2 фазы
        json_result := json_result || jsonb_build_object('coworker', Vres.cw_id_bad);
        update md.coworker
        set is_teacher=Vres.iis_teacher,
            is_director=Vres.iis_director,
            is_deputy=Vres.iis_deputy,
            is_coordinator=Vres.iis_coordinator,
            manager_id=(case when Vres.i_manager_id != Vres.cw_id_good then Vres.i_manager_id else null end),
            position=Vres.i_position
        where id = Vres.cw_id_good
        returning * into cw_row;
        upd_id := cw_row.id;
        update audit.coworker_aud
        set revend=revision_cnt,
            revend_timestamp=CURRENT_TIMESTAMP
        where id = upd_id
          and revend isnull;
        insert into audit.coworker_aud(id, rev, revtype, fired_date, first_name, idm_sid, is_coordinator,
                                       is_deputy, is_director, is_teacher, middle_name, position, second_name,
                                       manager_id, organization_id)
        values (cw_row.id, revision_cnt, 1, cw_row.fired_date, cw_row.first_name, cw_row.idm_sid, cw_row.is_coordinator,
                cw_row.is_deputy,
                cw_row.is_director, cw_row.is_teacher, cw_row.middle_name, cw_row.position, cw_row.second_name,
                cw_row.manager_id, cw_row.organization_id);
        
        with
          L0 as (
            select *
            from unnest(Vres.cw_id_bad)
          )
        delete
        from md.coworker c
        where c.id in (select L0.unnest from L0);
        
        insert into techsupport.fnk_log(name_fnk, input_param, old_val, new_val)
        values ('script_coworker_delete', Vres.cw_id_good, Vres.cw_id_bad, json_result);
        cntall := cntall + 1;
        if cntall % 100 = 0 then
          raise notice 'count_delete: %', quote_ident(cntall::text);
        end if;
      end loop;
  end ;
$$ language plpgsql;

do $$----phaze 3
  declare
    cw_id            bigint;
    cnt              int;
    i_is_teacher     bool;
    i_is_coordinator bool;
    cw_row           md.coworker%ROWTYPE;
    cw_con           md.coworker_contact%ROWTYPE;
    revision_cnt     bigint;
    upd_id           bigint;
    new_cw cursor for
      select coalesce((regexp_split_to_array(apf.fio, E'\\s+'))[2], '') as FN,
             coalesce((regexp_split_to_array(apf.fio, E'\\s+'))[1], '') as SN,
             coalesce((regexp_split_to_array(apf.fio, E'\\s+'))[3], '') as MN,
             coalesce(apf.login_entuser, apf.ulogin)                       i_login,
             apf.urole,
             om.id                                                         orgid,
             apf.phone,
             apf.email,
             apf.id_entuser
      from test._aveleksusers_pred_final apf
             join idb.organization_map om on apf.org_id = om.aid::text or apf.md_org_id = om.id
             join md.organization o on om.id = o.id
             left join md.coworker cw on apf.fio = trim(concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name))
          and coalesce(om.id, apf.md_org_id) = cw.organization_id
      where cw.id isnull
        and apf.status >= 0;
    upd_cw cursor for
      select (regexp_split_to_array(apf.fio, E'\\s+'))[2] as FN,
             (regexp_split_to_array(apf.fio, E'\\s+'))[1] as SN,
             (regexp_split_to_array(apf.fio, E'\\s+'))[3] as MN,
             coalesce(apf.login_entuser, apf.ulogin)         i_login,
             om.id                                           orgid,
             apf.phone,
             apf.email,
             apf.id_entuser,
             cw.id                                        as cw_id
      from test._aveleksusers_pred_final apf
             join idb.organization_map om on apf.org_id = om.aid::text or apf.md_org_id = om.id
             join md.coworker cw on apf.fio = trim(concat(cw.second_name, ' ', cw.first_name, ' ', cw.middle_name))
          and coalesce(om.id, apf.md_org_id) = cw.organization_id
      where apf.status >= 0;
  
  begin
    update test._aveleksusers_pred_final
    set status= -1
    where upper(ulogin) like '%DELETE%';
    for Vres in new_cw
      loop
        if Vres.urole = 'MobileUser' then i_is_teacher := true; else i_is_teacher := false; end if;
        if Vres.urole in ('MobileUser PowerUser', 'PowerUser', 'Administrator', 'PowerUser MobileUser') then
          i_is_coordinator := true;
        else
          i_is_coordinator := false;
        end if;
        insert into md.coworker (first_name, second_name, middle_name, organization_id, idm_sid, is_teacher,
                                 is_coordinator, is_deputy, is_director)
        values (Vres.FN, Vres.SN, Vres.MN, Vres.orgid, Vres.i_login, i_is_teacher, i_is_coordinator, false, false)
        on conflict do nothing
        returning * into cw_row;
        if cw_row.id is not null then
          insert into audit.coworker_aud(id, rev, revtype, fired_date, first_name, idm_sid, is_coordinator, is_deputy,
                                         is_director, is_teacher,
                                         middle_name, position, second_name, manager_id, organization_id)
          values (cw_row.id, 1, 0, cw_row.fired_date, cw_row.first_name, cw_row.idm_sid, cw_row.is_coordinator,
                  cw_row.is_deputy, cw_row.is_director, cw_row.is_teacher,
                  cw_row.middle_name, cw_row.position, cw_row.second_name, cw_row.manager_id, cw_row.organization_id);
        end if;
        if Vres.phone is not null then
          insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
          values (cw_row.id, 1, Vres.phone, 0, 1)
          returning * into cw_con;
          insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                  owner_id, contact_type_id)
          values (cw_con.id, 1, 0, cw_con.priority, cw_con.value, cw_con.contact_availability_type_id, cw_con.owner_id,
                  cw_con.contact_type_id);
        end if;
        if Vres.email is not null then
          insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
          values (cw_row.id, 2, Vres.email, 0, 1)
          returning * into cw_con;
          insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                  owner_id, contact_type_id)
          values (cw_con.id, 1, 0, cw_con.priority, cw_con.value, cw_con.contact_availability_type_id, cw_con.owner_id,
                  cw_con.contact_type_id);
        end if;
      end loop;
    select max(id) into revision_cnt from audit.revision;
    insert into audit.revision (id, timestamp, user_id)
    values ((revision_cnt + 1), (trunc(extract(epoch from now()) * 1000)), 1::varchar)
    returning id into revision_cnt;
    for Vres in upd_cw
      loop
        select count(*) into cnt from md.coworker cw where cw.idm_sid = Vres.i_login;
        if cnt = 0 then
          update md.coworker
          set idm_sid=Vres.i_login
          where id = Vres.cw_id
            and idm_sid is null
          returning * into cw_row;
          if cw_row is not null then
            upd_id := cw_row.id;
            update audit.coworker_aud
            set revend=revision_cnt,
                revend_timestamp=CURRENT_TIMESTAMP
            where id = upd_id
              and revend is null;
            insert into audit.coworker_aud(id, rev, revtype, fired_date, first_name, idm_sid, is_coordinator, is_deputy,
                                           is_director, is_teacher,
                                           middle_name, position, second_name, manager_id, organization_id)
            values (cw_row.id, revision_cnt, 1, cw_row.fired_date, cw_row.first_name, cw_row.idm_sid,
                    cw_row.is_coordinator, cw_row.is_deputy, cw_row.is_director, cw_row.is_teacher,
                    cw_row.middle_name, cw_row.position, cw_row.second_name, cw_row.manager_id, cw_row.organization_id);
          end if;
          select count(*)
          into cnt
          from md.coworker_contact cc
          where cc.owner_id = Vres.cw_id and cc.contact_type_id = 1;
          if Vres.phone is not null and cnt = 0 then
            insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
            values (cw_id, 1, Vres.phone, 0, 1)
            returning * into cw_con;
            insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                    owner_id, contact_type_id)
            values (cw_con.id, 1, 0, cw_con.priority, cw_con.value, cw_con.contact_availability_type_id,
                    cw_con.owner_id, cw_con.contact_type_id);
          end if;
          select count(*)
          into cnt
          from md.coworker_contact cc
          where cc.owner_id = Vres.cw_id and cc.contact_type_id = 2;
          if Vres.email is not null and cnt = 0 then
            insert into md.coworker_contact(owner_id, contact_type_id, value, priority, contact_availability_type_id)
            values (cw_id, 2, Vres.email, 0, 1)
            returning * into cw_con;
            insert into audit.coworker_contact_aud (id, rev, revtype, priority, value, contact_availability_type_id,
                                                    owner_id, contact_type_id)
            values (cw_con.id, 1, 0, cw_con.priority, cw_con.value, cw_con.contact_availability_type_id,
                    cw_con.owner_id, cw_con.contact_type_id);
          end if;
        end if;
      end loop;
  
  end;
$$ language plpgsql;

do $$----phaze 4 IDM
  declare
    uid    bigint;
    uid_p  bigint;
    i_role bigint;
    new_user cursor for
      select coalesce((regexp_split_to_array(asw.fio, E'\\s+'))[2], '') as FN,
             coalesce((regexp_split_to_array(asw.fio, E'\\s+'))[1], '') as SN,
             coalesce((regexp_split_to_array(asw.fio, E'\\s+'))[3], '') as MN,
             asw.email,
             asw.phone,
             asw.ulogin,
             asw.urole
      from test._aveleksusers_stt_without asw
      where asw.id_entusers is null;
  
  begin
    for Vres in new_user
      loop
        if Vres.urole = 'MobileUser' then i_role := 40; end if;
        if Vres.urole in ('MobileUser PowerUser', 'PowerUser', 'Administrator', 'PowerUser MobileUser') then
          i_role := 39;
        end if;
        insert into public.ent_users(lastname, firstname, middlename, email, organizationid, creation_date, phone)
        values (Vres.SN, Vres.FN, Vres.MN, Vres.email, 1, now(), Vres.phone)
        returning id into uid;
        
        insert into public.ent_user_profiles(userid, login, resourceid)
        values (uid, Vres.ulogin, 1)
        returning id into uid_p;
        
        insert into public.dep_user_profiles_roles (entityid, roleid, datefrom)
        values (uid_p, i_role, now());
      end loop;
  end;
$$ language plpgsql;

