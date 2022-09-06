update idb.organization set is_provider = true where id in (
  select distinct idb.contract.provider_id from idb.contract
)