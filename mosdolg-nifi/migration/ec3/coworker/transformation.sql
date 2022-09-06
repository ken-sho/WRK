-- 26.08
truncate table idb.coworkers;
delete from idb.contact_owner where id in (select ow.id from idb.contact_owner ow join idb.contact c on c.owner_id=ow.id where c.contact_owner_type_id=2);
delete from idb.contact c where c.contact_owner_type_id=2;

--+---------------------------------------------------------------------------------------------------------------------
--+ трансформация из миграционной таблицы в основную
--+---------------------------------------------------------------------------------------------------------------------
do $$
declare
    pid bigint;
    cid bigint;
    arr_nm varchar array;
    usr_cur cursor for select * from sdb.coworker_user;
    tch_cur cursor for select
        distinct t.aid,
        t.first_name,
        t.middle_name,
        t.second_name,
        t.organization_id,
        t.phone,
        t.email
     from sdb.coworker_teacher t;-- inner join sdb.group_teachers gt on t.aid=gt.teacher_aid group by t.aid;
begin
    for row in usr_cur loop
        arr_nm := regexp_split_to_array(row.name, E'\\s+');
        select idb.get_coworkers_id_by_map_id(row.aid) into pid;
        insert into idb.coworkers(id, second_name, first_name, middle_name, organization_id, position, is_teacher, is_deputy, is_director, idm_sid)
        values (pid, initcap(arr_nm[1]), initcap(COALESCE(arr_nm[2], arr_nm[1])), initcap(COALESCE(arr_nm[3], arr_nm[2])), idb.get_organization_id_by_esz_id(row.organization_id), row.position, 0::boolean, 0::boolean, 0::boolean, row.login);

        insert into idb.contact_owner(id, created, modified) values (pid, now(), now()) on conflict do nothing;

        if row.phone is not null then
            select nextval('idb.contact_id_seq') into cid;
            insert into idb.contact(id, owner_id, contact_owner_type_id, contact_type_id, value, contact_availability_type_id, priority)
            values (cid, pid, 2, 1, row.phone, 1, 0) on conflict do nothing;
        end if;
        if row.email is not null then
            select nextval('idb.contact_id_seq') into cid;
            insert into idb.contact(id, owner_id, contact_owner_type_id, contact_type_id, value, contact_availability_type_id, priority)
            values (cid, pid, 2, 2, row.email, 1, 0) on conflict do nothing;
        end if;
    end loop;
    for row in tch_cur loop
        select idb.get_teachers_id_by_map_id(row.aid) into pid;
        insert into idb.coworkers(id, second_name, first_name, middle_name, organization_id, is_teacher, is_deputy, is_director)
        values (pid, COALESCE(initcap(row.second_name), '(не задано)'), COALESCE(initcap(row.first_name), '(не задано)'),
                COALESCE(initcap(row.middle_name), null), idb.get_organization_id_by_esz_id(row.organization_id), 1::boolean, 0::boolean, 0::boolean)
        on conflict do nothing; -- FIXME

        insert into idb.contact_owner(id, created, modified) values (pid, now(), now()) on conflict do nothing;

        if row.phone is not null then
            select nextval('idb.contact_id_seq') into cid;
            insert into idb.contact(id, owner_id, contact_owner_type_id, contact_type_id, value, contact_availability_type_id, priority)
            values (cid, pid, 3, 1, row.phone, 1, 0) on conflict do nothing;
        end if;
        if row.email is not null then
            select nextval('idb.contact_id_seq') into cid;
            insert into idb.contact(id, owner_id, contact_owner_type_id, contact_type_id, value, contact_availability_type_id, priority)
            values (cid, pid, 3, 2, row.email, 1, 0) on conflict do nothing;
        end if;
    end loop;
end;
$$ language plpgsql;