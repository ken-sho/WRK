truncate table idb.place_metro_stations;
truncate table idb.place;

-- truncate table idb.map_place;

do $$
begin

insert into idb.map_place(id, id_map, id_main)
select
	nextval('idb.place_id_seq'),
	unnest(arr) as id_map, id_main
from (
     select (select max(idmn) from unnest(arr) idmn) id_main, arr
     from (select array_agg(distinct id order by id desc) arr from sdb.place group by address_id, title) data
) xx
on conflict do NOTHING;

-- для ситуаций когда импортируются площадки с одинаковым адресом (address_id, title), но разные id
update idb.map_place set id_main = id_map where id_main != id_map;

insert into idb.place(
	id,
	title,
	address,
	validation
)
select
    distinct u.id,
    mp.title,
    adr.id,--idb.get_address_id_by_unom_address(mp.unom, mp.address),
    true
from idb.map_place u
join sdb.place mp on mp.id = u.id_main
left join ar.address_registry adr on mp.unom::int=adr.unom
on conflict do nothing;

-- связь с метро
insert into idb.place_metro_stations
select
	nextval('idb.place_metro_stations_id_seq'),
   	mp.id,
    ms.id
from sdb.place u
join ar.metro_station ms on ms.aid = u.metro_station_code
join idb.map_place mp on mp.id_map=u.id;


--PARAM.MIGRATION.SQL.DUBLICATE
with upd_dublicate as (
    select mp1.id_map as id_map, mp2.id as id
    from idb.map_place mp1 join idb.map_place mp2 on mp1.id_main = mp2.id_main
    where mp1.id is null and mp2.id is not null
)
update idb.map_place
set id = (select id from upd_dublicate where upd_dublicate.id_map = map_place.id_map)
where id is null;
end;
$$ language plpgsql;

-- выбираем адреса, которые не найдены у нас в классификаторе
-- ищем для них совпадение по полному адресу
-- если не найден - добавляем в address_registry
do $$
  declare
    i_address_id bigint;
    cur cursor for (
      select distinct on (idb_p.id, sdb_p.id)
        idb_p.id as id,
             sdb_p.id as aid,
             sdb_p.address
      from idb.place idb_p
             join idb.map_place mp on idb_p.id = mp.id
             join sdb.place sdb_p on mp.id_main = sdb_p.id
      where idb_p.address is null
    );
  begin
    for row in cur
      loop
        select id into i_address_id from ar.address_registry where address = row.address order by id limit 1;

        if i_address_id is null then
          select nextval('ar.address_registry_id_seq') into i_address_id;
          insert into ar.address_registry(id, address, ar_object_status_id) values (i_address_id, row.address, 2);
        end if;

        update idb.place set address = i_address_id where id = row.id;
      end loop;
  end;
$$ language plpgsql;