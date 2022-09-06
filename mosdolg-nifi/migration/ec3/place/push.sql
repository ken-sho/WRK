-- 25.06.2019
truncate table md.place cascade;
truncate table md.place_metro_stations cascade;

insert into md.place select * from idb.place;
insert into md.place_metro_stations select * from idb.place_metro_stations;
