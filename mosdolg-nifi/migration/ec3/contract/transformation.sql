-- 23.08
truncate table idb.contract;
truncate table idb.contract_map;
truncate table idb.contract_property;
truncate table idb.contract_status_registry;

do $$
declare
    cid bigint;
    cpid bigint;
    csrid bigint;
    cp bigint;
    act_id bigint;
    contract_cur cursor for select * from sdb.contract;
begin
    for row in contract_cur loop
        -- select idb.get_contract_id_by_esz_id(row.aid) into cid;

        select id from idb.contract_map cm where
            row.contract_number = cm.contract_number
            and row.provider_id = cm.provider_id
        into cid;

        if cid is null then
            select nextval('idb.contract_id_seq') into cid;
            select nextval('idb.contract_status_registry_id_seq') into csrid;
            insert into idb.contract_status_registry(
                id,
                contract_id,
                status_id,
                status_reason_id,
                start_date,
                end_date,
                idm_ent_user_profiles_id
            ) values (
                csrid,
                cid,
                5,
                1,
                to_timestamp(row.date_from, 'YYYY-MM-DD'),
                null,--to_timestamp(row.date_to, 'YYYY-MM-DD'),
                1
            );
        end if;

        insert into idb.contract_map(id, aid, provider_id, contract_number)
        values (cid, row.aid, row.provider_id, row.contract_number);

        insert into idb.contract(
            id,
            provider_id,
            contract_number,
            organization_id,
            date_from,
            date_to,
            document_number
        ) values (
            cid,
            idb.get_organization_id_by_esz_id(row.provider_id),
            row.contract_number,
            idb.get_organization_id_by_esz_id(row.organization_id),
            to_timestamp(row.date_from, 'YYYY-MM-DD'),
            to_timestamp(row.date_to, 'YYYY-MM-DD'),
            nextval('idb.contract_document_number_seq')
        ) on conflict do nothing;

        act_id := idb.get_map_activity_id(row.activity_id);

        select id from idb.contract_property
        where contract_id=cid and activity_id=act_id
        into cp;

        if cp is null then
            select nextval('idb.contract_property_id_seq') into cpid;
            insert into idb.contract_property(
                id,
                contract_id,
                activity_id,
                grant_value
            ) values (
                cpid,
                cid,
                act_id,
                row.full_price
            );
        end if;

    end loop;
end;
$$ language plpgsql;