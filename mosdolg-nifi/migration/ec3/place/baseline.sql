--PLACE
--+---------------------------------------------------------------------------------------------------------------------
--+ Площадки
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.place;
create table if not exists sdb.place(
    id bigint,
    address_id bigint not null,
    title varchar(4096),
    address varchar(800) not null,
    unom varchar(20),
    metro_station_code bigint null
--    CONSTRAINT place_pkey PRIMARY KEY (id, metro_station_code)
);

drop table if exists idb.map_place;
create table if not exists idb.map_place(
   id_map bigint primary key,
   id_main bigint not null,
   id bigint
);

drop table if exists idb.place_metro_stations;
CREATE TABLE if not exists idb.place_metro_stations (
	id bigserial NOT NULL,
	place_id int8 NULL,
	station_id int8 NULL,
	CONSTRAINT place_metro_stations_pkey PRIMARY KEY (id)
);


drop table if exists idb.place;
CREATE TABLE if not exists idb.place (
	id bigserial NOT NULL,
	organization_id int8 NULL,
	title varchar(4000) NULL,
	address int8 NULL,
	validation bool NULL,
    CONSTRAINT place_pkey PRIMARY KEY (id)
--	CONSTRAINT fk_place_organization_id FOREIGN KEY (organization_id) REFERENCES md.organization(id) ON DELETE SET NULL,
--	CONSTRAINT place_address_fk FOREIGN KEY (address) REFERENCES ar.address_registry(id)
);