-- 23.08
truncate table md.contract cascade;
truncate table md.contract_property cascade;
truncate table md.contract_status_registry cascade;

insert into md.contract
select * from idb.contract c
where
-- c.organization_id is null or
(c.organization_id in (select id from md.organization)
and c.provider_id in (select id from md.organization));

insert into md.contract_property (id, activity_id, contract_id, grant_value)
select
    id,
    activity_id,
    contract_id,
    grant_value
from idb.contract_property p where p.contract_id in (select id from md.contract);

insert into md.contract_status_registry select * from idb.contract_status_registry p where p.contract_id in (select id from md.contract);

update md.organization set is_provider = true where id in (
  select distinct md.contract.provider_id from md.contract
)