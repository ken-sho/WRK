--+--------------------------------------------------------------------------------------------------------------------+
-- SCHEMAS
--+--------------------------------------------------------------------------------------------------------------------+
-- SCHEMA: ehd

DROP SCHEMA IF EXISTS ehd CASCADE;
CREATE SCHEMA IF NOT EXISTS ehd;
--   AUTHORIZATION postgres;

--+--------------------------------------------------------------------------------------------------------------------+
-- VIEWS
--+--------------------------------------------------------------------------------------------------------------------+

-- Drop materialize views
-- drop materialized view if exists ehd.additional_address_entity_map cascade;
-- drop materialized view if exists ehd.address_additional_map cascade;
-- drop materialized view if exists ehd.addres_object_type_map cascade;
-- drop materialized view if exists ehd.address_registry_map cascade;
-- drop materialized view if exists ehd.city_map cascade;
-- drop materialized view if exists ehd.room_type_map cascade;
-- drop materialized view if exists ehd.settlement_map cascade;
-- drop materialized view if exists ehd.settlement_point_map cascade;
-- drop materialized view if exists ehd.street_map cascade;
-- drop materialized view if exists ehd.territory_map cascade;
-- drop materialized view if exists ehd.metro_station_map cascade;
-- drop materialized view if exists ehd.metro_line_map cascade;

-- Создание перекодировочных матерализованных вьюх
create materialized view if not exists ehd.additional_address_entity_map as select id, aid from ar.additional_address_entity;
create materialized view if not exists ehd.address_additional_map as select id, aid from ar.address_additional;
create materialized view if not exists ehd.address_object_type_map as select id, aid from ar.address_object_type;
create materialized view if not exists ehd.address_registry_map as select id, aid from ar.address_registry;
create materialized view if not exists ehd.city_map as select id, aid from ar.city;
create materialized view if not exists ehd.room_type_map as select id, aid from ar.room_type;
create materialized view if not exists ehd.settlement_map as select id, aid from ar.settlement;
create materialized view if not exists ehd.settlement_point_map as select id, aid from ar.settlement_point;
create materialized view if not exists ehd.street_map as select id, aid from ar.street;
create materialized view if not exists ehd.territory_map as select id, aid from ar.territory;
create materialized view if not exists ehd.metro_station_map as select id, aid from ar.metro_station;
create materialized view if not exists ehd.metro_line_map as select id, aid from ar.metro_line;

--+--------------------------------------------------------------------------------------------------------------------+
-- TABLES
--+--------------------------------------------------------------------------------------------------------------------+

-- Table: ehd.dict_address_object_type Dict:1971

CREATE TABLE IF NOT EXISTS ehd.dict_address_object_type
(
   id        BIGINT PRIMARY KEY,         -- Идентификатор
   parent_id BIGINT,                     -- Ссылка на родителя
   name      CHARACTER VARYING NOT NULL, -- Название
   isDeleted BOOLEAN DEFAULT FALSE       -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_address_object_type
--     OWNER to postgres;
COMMENT ON TABLE ehd.dict_address_object_type IS 'ID 1971::Единый справочник классификаторов ГБУ МосгорБТИ. 160';

-- Table: ehd.dict_address_subject Dict:1972

CREATE TABLE IF NOT EXISTS ehd.dict_address_subject
(
    id BIGINT PRIMARY KEY,                                    -- Идентификатор
    parent_id BIGINT,                                         -- Ссылка на родителя
    name CHARACTER VARYING NOT NULL,                          -- Название
    isDeleted BOOLEAN DEFAULT FALSE                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_address_subject OWNER to postgres;
COMMENT ON TABLE ehd.dict_address_subject IS 'ID 1972::Единый справочник классификаторов ГБУ МосгорБТИ. 531';

-- Table: ehd.dict_address_settlement Dict:1974

CREATE TABLE IF NOT EXISTS ehd.dict_address_settlement
(
    id BIGINT PRIMARY KEY,                                    -- Идентификатор
    parent_id BIGINT,                                         -- Ссылка на родителя
    name CHARACTER VARYING NOT NULL,                          -- Название
    isDeleted BOOLEAN DEFAULT FALSE                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_address_settlement OWNER to postgres;
COMMENT ON TABLE ehd.dict_address_settlement IS 'ID 1974::Единый справочник классификаторов ГБУ МосгорБТИ. 532';

-- Table: ehd.dict_address_city Dict:1976

CREATE TABLE IF NOT EXISTS ehd.dict_address_city
(
    id BIGINT PRIMARY KEY,                                    -- Идентификатор
    parent_id BIGINT,                                         -- Ссылка на родителя
    name CHARACTER VARYING NOT NULL,                          -- Название
    isDeleted BOOLEAN DEFAULT FALSE                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_address_city OWNER to postgres;
COMMENT ON TABLE ehd.dict_address_city IS 'ID 1976::Единый справочник классификаторов ГБУ МосгорБТИ. 623';

-- Table: ehd.dict_address_municipal_district Dict:1978

CREATE TABLE IF NOT EXISTS ehd.dict_address_municipal_district
(
    id BIGINT PRIMARY KEY,                                    -- Идентификатор
    parent_id BIGINT,                                         -- Ссылка на родителя
    name CHARACTER VARYING NOT NULL,                          -- Название
    isDeleted BOOLEAN DEFAULT FALSE                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_address_municipal_district OWNER to postgres;
COMMENT ON TABLE ehd.dict_address_municipal_district IS 'ID 1978::Единый справочник классификаторов ГБУ МосгорБТИ. 45';

-- Table: ehd.dict_address_locality Dict:1980

CREATE TABLE IF NOT EXISTS ehd.dict_address_locality
(
    id BIGINT PRIMARY KEY,                                    -- Идентификатор
    parent_id BIGINT,                                         -- Ссылка на родителя
    name CHARACTER VARYING NOT NULL,                          -- Название
    isDeleted BOOLEAN DEFAULT FALSE                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_address_locality OWNER to postgres;
COMMENT ON TABLE ehd.dict_address_locality IS 'ID 1980::Единый справочник классификаторов ГБУ МосгорБТИ. 534';

-- Table: ehd.dict_element_names_street_network Dict:1982

CREATE TABLE IF NOT EXISTS ehd.dict_element_names_street_network
(
    id        bigint PRIMARY KEY,         -- Идентификатор
    parent_id bigint,                     -- Ссылка на родителя
    name      character varying NOT NULL, -- Название
    isDeleted boolean DEFAULT false       -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_element_names_street_network
--     OWNER to postgres;
COMMENT ON TABLE ehd.dict_element_names_street_network IS 'ID 1982::Единый справочник классификаторов ГБУ МосгорБТИ. 562';

-- Table: ehd.dict_additional_address_elements Dict:1984

CREATE TABLE IF NOT EXISTS ehd.dict_additional_address_elements
(
  id bigint PRIMARY KEY,                                    -- Идентификатор
  parent_id bigint,                                         -- Ссылка на родителя
  name character varying NOT NULL,                           -- Название
  isDeleted boolean DEFAULT false                       -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_additional_address_elements
--   OWNER to postgres;
COMMENT ON TABLE ehd.dict_additional_address_elements IS 'ID 1984::Единый справочник классификаторов ГБУ МосгорБТИ. 541';

-- Table: ehd.dict_comments_additional_address_elements Dict:1988

CREATE TABLE IF NOT EXISTS ehd.dict_comments_additional_address_elements
(
  id bigint PRIMARY KEY,                                    -- Идентификатор
  parent_id bigint,                                         -- Ссылка на родителя
  name character varying NOT NULL,                           -- Название
  isDeleted boolean DEFAULT false                       -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_comments_additional_address_elements
--   OWNER to postgres;
COMMENT ON TABLE ehd.dict_comments_additional_address_elements IS 'ID 1988::Единый справочник классификаторов ГБУ МосгорБТИ. 586';

-- Table: ehd.dict_premises_number_type Dict:1990

CREATE TABLE IF NOT EXISTS ehd.dict_premises_number_type
(
    id BIGINT PRIMARY KEY,                                    -- Идентификатор
    parent_id BIGINT,                                         -- Ссылка на родителя
    name CHARACTER VARYING,                                   -- Название
    isDeleted BOOLEAN DEFAULT FALSE                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_premises_number_type OWNER to postgres;
COMMENT ON TABLE ehd.dict_premises_number_type IS 'ID 1990::Единый справочник классификаторов ГБУ МосгорБТИ. 122';

-- Table: ehd.dict_building_number_type Dict:1992

CREATE TABLE IF NOT EXISTS ehd.dict_building_number_type
(
    id BIGINT PRIMARY KEY,                                    -- Идентификатор
    parent_id BIGINT,                                         -- Ссылка на родителя
    name CHARACTER VARYING NOT NULL,                          -- Название
    isDeleted BOOLEAN DEFAULT FALSE                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_building_number_type OWNER to postgres;
COMMENT ON TABLE ehd.dict_building_number_type IS 'ID 1992::Единый справочник классификаторов ГБУ МосгорБТИ. 563';

-- Table: ehd.dict_construction_number_type Dict:1994

CREATE TABLE IF NOT EXISTS ehd.dict_construction_number_type
(
    id BIGINT PRIMARY KEY,                                    -- Идентификатор
    parent_id BIGINT,                                         -- Ссылка на родителя
    name CHARACTER VARYING,                                   -- Название
    isDeleted BOOLEAN DEFAULT FALSE                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_construction_number_type OWNER to postgres;
COMMENT ON TABLE ehd.dict_construction_number_type IS 'ID 1994::Единый справочник классификаторов ГБУ МосгорБТИ. 123';

-- Table: ehd.dict_premises_types Dict:1996

CREATE TABLE IF NOT EXISTS ehd.dict_premises_types
(
  id bigint PRIMARY KEY,                                    -- Идентификатор
  parent_id bigint,                                         -- Ссылка на родителя
  name character varying NOT NULL,                           -- Название
  isDeleted boolean DEFAULT false                       -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_premises_types
--   OWNER to postgres;
COMMENT ON TABLE ehd.dict_premises_types IS 'ID 1996::Единый справочник классификаторов ГБУ МосгорБТИ. 595';

-- Table: ehd.dict_administrative_districts Dict:1997

CREATE TABLE IF NOT EXISTS ehd.dict_administrative_districts
(
  id bigint PRIMARY KEY,                                    -- Идентификатор
  parent_id bigint,                                         -- Ссылка на родителя
  name character varying NOT NULL,                           -- Название
  isDeleted boolean DEFAULT false,                       -- Признак удаленной записи
  kod varchar(255)                                   -- Код округа
);

-- ALTER TABLE ehd.dict_administrative_districts
--   OWNER to postgres;
COMMENT ON TABLE ehd.dict_administrative_districts IS 'ID 1997::Единый справочник классификаторов ГБУ МосгорБТИ. 44';

-- Table: ehd.dict_municipal_districts Dict:1999

CREATE TABLE IF NOT EXISTS ehd.dict_municipal_districts
(
  id bigint PRIMARY KEY,                                    -- Идентификатор
  parent_id bigint,                                         -- Ссылка на родителя
  name character varying NOT NULL,                           -- Название
    isDeleted boolean DEFAULT false,                       -- Признак удаленной записи
      kod varchar(255)                                   -- Код района
);

-- ALTER TABLE ehd.dict_municipal_districts
--   OWNER to postgres;
COMMENT ON TABLE ehd.dict_municipal_districts IS 'ID 1999::Единый справочник классификаторов ГБУ МосгорБТИ. 45 и 532';

-- Table: ehd.dict_address_type Dict:2002

CREATE TABLE IF NOT EXISTS ehd.dict_address_type
(
    id bigint PRIMARY KEY,                                    -- Идентификатор
    parent_id bigint,                                         -- Ссылка на родителя
    name character varying NOT NULL,                          -- Название
    isDeleted boolean DEFAULT false                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_address_type OWNER to postgres;
COMMENT ON TABLE ehd.dict_address_type IS 'ID 2002::Единый справочник классификаторов ГБУ МосгорБТИ. 115';

-- Table: ehd.dict_address_status Dict:2006

CREATE TABLE IF NOT EXISTS ehd.dict_address_status
(
    id BIGINT PRIMARY KEY,                                    -- Идентификатор
    parent_id BIGINT,                                         -- Ссылка на родителя
    name CHARACTER VARYING NOT NULL,                          -- Название
    isDeleted BOOLEAN DEFAULT FALSE                           -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_address_status OWNER to postgres;
COMMENT ON TABLE ehd.dict_address_status IS 'ID 2006::Единый справочник классификаторов ГБУ МосгорБТИ. 114';

-- Table: ehd.dict_address_property_status Dict:2008

CREATE TABLE IF NOT EXISTS ehd.dict_address_property_status
(
  id bigint PRIMARY KEY,                                    -- Идентификатор
  parent_id bigint,                                         -- Ссылка на родителя
  name character varying NOT NULL,                           -- Название
  isDeleted boolean DEFAULT false                       -- Признак удаленной записи
);

-- ALTER TABLE ehd.dict_address_property_status
--   OWNER to postgres;
COMMENT ON TABLE ehd.dict_address_property_status IS 'ID 2008::Единый справочник классификаторов ГБУ МосгорБТИ. 588';

-- Table: ehd.metro_stations Catalog ID:6401

CREATE TABLE IF NOT EXISTS ehd.metro_station
(
  global_id        bigint PRIMARY KEY,          -- Глобальный идентификатор родительского объекта.
  system_object_id character varying,           -- Идентификатор родительского объекта в системе интегратора
  id               bigint,                      -- Код
  station          character varying,           -- Наименование станции
  line             character varying,           -- Наименование линии
  admarea          character varying,           -- Административный округ
  district         character varying,           -- Район
  status           character varying            -- Статус
  --   signature        character varying            -- Состояние подписи
);

-- ALTER TABLE ehd.metro_station
--   OWNER to postgres;

COMMENT ON TABLE ehd.metro_station IS 'ID 6401::Станции Московского метрополитена';
COMMENT ON COLUMN ehd.metro_station.global_id        IS 'Глобальный идентификатор родительского объекта.';
COMMENT ON COLUMN ehd.metro_station.system_object_id IS 'Идентификатор родительского объекта в системе интегратора';
COMMENT ON COLUMN ehd.metro_station.id               IS 'Код';
COMMENT ON COLUMN ehd.metro_station.station          IS 'Наименование станции';
COMMENT ON COLUMN ehd.metro_station.line             IS 'Наименование линии';
COMMENT ON COLUMN ehd.metro_station.admarea          IS 'Административный округ';
COMMENT ON COLUMN ehd.metro_station.district         IS 'Район';
COMMENT ON COLUMN ehd.metro_station.status           IS 'Статус';
-- COMMENT ON COLUMN ehd.metro_station.signature        IS 'Состояние подписи';

-- Table: ehd.metro_line Catalog ID:7668

CREATE TABLE IF NOT EXISTS ehd.metro_line
(
  global_id        bigint PRIMARY KEY,          -- Глобальный идентификатор родительского объекта.
  system_object_id character varying,           -- Идентификатор родительского объекта в системе интегратора
  id               bigint,                      -- Код
  line             character varying,           -- Наименование линии
  status           character varying            -- Статус
  --   signature        character varying            -- Состояние подписи
);

-- ALTER TABLE ehd.metro_line
--   OWNER to postgres;

COMMENT ON TABLE ehd.metro_line IS 'ID 7668::Линии Московского метрополитена';
COMMENT ON COLUMN ehd.metro_line.global_id        IS 'Глобальный идентификатор родительского объекта.';
COMMENT ON COLUMN ehd.metro_line.system_object_id IS 'Идентификатор родительского объекта в системе интегратора';
COMMENT ON COLUMN ehd.metro_line.id               IS 'Код';
COMMENT ON COLUMN ehd.metro_line.line             IS 'Наименование линии';
COMMENT ON COLUMN ehd.metro_line.status           IS 'Статус';
-- COMMENT ON COLUMN ehd.metro_line.signature        IS 'Состояние подписи';

-- Table: ehd.address_registry_property_objects Catalog ID:27451

-- DROP TABLE IF EXISTS ehd.address_registry_property_objects;
CREATE TABLE IF NOT EXISTS ehd.address_registry_property_objects
(
    global_id        bigint PRIMARY KEY,          -- Глобальный идентификатор родительского объекта.
    system_object_id character varying,           -- Идентификатор родительского объекта в системе интегратора
    aid              bigint,                      -- Идентификатор адреса
    obj_type         bigint,                      -- Тип объекта адресации dictId:1971
    address          character varying,           -- Полное юридическое написание адреса или описание местоположения
    unom             bigint,                      -- Учётный номер объекта адресации в БД БТИ (кроме помещения и комнаты)
    p1               bigint,                      -- Субъект РФ dictId:1972
    p3               bigint,                      -- Поселение dictId:1974
    p4               bigint,                      -- Город dictId:1976
    p5               bigint,                      -- Муниципальный округ dictId:1978
    p6               bigint,                      -- Населённый пункт dictId:1980
    p7               bigint,        -- Наименование элемента планировочной структуры или улично-дорожной сети dictId:1982
    p90              bigint,                      -- Дополнительный адресообразующий элемент dictId:1984
    p91              bigint,                      -- Уточнение дополнительного адресообразующего элемента dictId:1988
    l1_type          bigint,                      -- Тип номера дома, владения, участка dictId:1990
    l1_value         character varying,           -- Номер дома, владения, участка
    l2_type          bigint,                      -- Тип номера корпуса dictId:1992
    l2_value         character varying,           -- Номер корпуса
    l3_type          bigint,                      -- Тип номера строения, сооружения dictId:1994
    l3_value         character varying,           -- Номер строения, сооружения
    l4_type          bigint,                      -- Тип номера помещения dictId:1996
    l4_value         character varying,           -- Номер помещения
    l5_type          bigint,                      -- Тип номера комнаты dictId:1996
    l5_value         character varying,           -- Номер комнаты
    adm_area         bigint,                      -- Административный округ dictId:1997
    district         bigint,                      -- Муниципальный округ, поселение dictId:1999
    nreg             bigint,                      -- Уникальный номер адреса в Адресном реестре
    dreg             varchar(30),                 -- Дата регистрации адреса в Адресном реестре fieldMask:dd.mm.yyyy
    n_fias           character varying,           -- Уникальный номер адреса в государственном адресном реестре
    d_fias           varchar(30),                 -- Дата регистрации адреса в государственном адресном реестре fieldMask:dd.mm.yyyy
    --   kad_n            bigint,                      -- Кадастровый номер объекта недвижимости (кроме земельного участка refCatalog:27455
    --   kad_zu           bigint,                      -- Кадастровый номер земельного участка (для ОКС) refCatalog:27456
    kladr            character varying,           -- Код КЛАДР для адресообразующего элемента нижнего уровня
    --   tdoc             bigint,                      -- Документ-основание регистрационных действий dictId:2001
    --   ndoc             character varying,           -- Номер документа о регистрации адреса
    --   ddoc             timestamp,                   -- Дата документа о регистрации адреса fieldMask:dd.mm.yyyy
    adr_type         bigint,                      -- Тип адреса dictId:2002
    --   vid              bigint,                      -- Вид адреса dictId:2004
    sostad           bigint,                      -- Состояние адреса dictId:2006
    status           bigint                       -- Статус адреса dictId:2008
    --   signature        character varying            -- Состояние подписи
);

-- ALTER TABLE ehd.address_registry_property_objects
--     OWNER to postgres;

COMMENT ON TABLE ehd.address_registry_property_objects IS 'ID 27451::Адресный реестр объектов недвижимости города Москвы';
COMMENT ON COLUMN ehd.address_registry_property_objects.global_id        IS 'Глобальный идентификатор родительского объекта.';
COMMENT ON COLUMN ehd.address_registry_property_objects.system_object_id IS 'Идентификатор родительского объекта в системе интегратора';
COMMENT ON COLUMN ehd.address_registry_property_objects.aid              IS 'Идентификатор адреса';
COMMENT ON COLUMN ehd.address_registry_property_objects.obj_type         IS 'Тип объекта адресации dictId:1971';
COMMENT ON COLUMN ehd.address_registry_property_objects.address          IS 'Полное юридическое написание адреса или описание местоположения';
COMMENT ON COLUMN ehd.address_registry_property_objects.unom             IS 'Учётный номер объекта адресации в БД БТИ (кроме помещения и комнаты)';
COMMENT ON COLUMN ehd.address_registry_property_objects.p1               IS 'Субъект РФ dictId:1972';
COMMENT ON COLUMN ehd.address_registry_property_objects.p3               IS 'Поселение dictId:1974';
COMMENT ON COLUMN ehd.address_registry_property_objects.p4               IS 'Город dictId:1976';
COMMENT ON COLUMN ehd.address_registry_property_objects.p5               IS 'Муниципальный округ dictId:1978';
COMMENT ON COLUMN ehd.address_registry_property_objects.p6               IS 'Населённый пункт dictId:1980';
COMMENT ON COLUMN ehd.address_registry_property_objects.p7               IS 'Наименование элемента планировочной структуры или улично-дорожной сети dictId:1982';
COMMENT ON COLUMN ehd.address_registry_property_objects.p90              IS 'Дополнительный адресообразующий элемент dictId:1984';
COMMENT ON COLUMN ehd.address_registry_property_objects.p91              IS 'Уточнение дополнительного адресообразующего элемента dictId:1988';
COMMENT ON COLUMN ehd.address_registry_property_objects.l1_type          IS 'Тип номера дома, владения, участка dictId:1990';
COMMENT ON COLUMN ehd.address_registry_property_objects.l1_value         IS 'Номер дома, владения, участка';
COMMENT ON COLUMN ehd.address_registry_property_objects.l2_type          IS 'Тип номера корпуса dictId:1992';
COMMENT ON COLUMN ehd.address_registry_property_objects.l2_value         IS 'Номер корпуса';
COMMENT ON COLUMN ehd.address_registry_property_objects.l3_type          IS 'Тип номера строения, сооружения dictId:1994';
COMMENT ON COLUMN ehd.address_registry_property_objects.l3_value         IS 'Номер строения, сооружения';
COMMENT ON COLUMN ehd.address_registry_property_objects.l4_type          IS 'Тип номера помещения dictId:1996';
COMMENT ON COLUMN ehd.address_registry_property_objects.l4_value         IS 'Номер помещения';
COMMENT ON COLUMN ehd.address_registry_property_objects.l5_type          IS 'Тип номера комнаты dictId:1996';
COMMENT ON COLUMN ehd.address_registry_property_objects.l5_value         IS 'Номер комнаты';
COMMENT ON COLUMN ehd.address_registry_property_objects.adm_area         IS 'Административный округ dictId:1997';
COMMENT ON COLUMN ehd.address_registry_property_objects.district         IS 'Муниципальный округ, поселение dictId:1999';
COMMENT ON COLUMN ehd.address_registry_property_objects.nreg             IS 'Уникальный номер адреса в Адресном реестре';
COMMENT ON COLUMN ehd.address_registry_property_objects.dreg             IS 'Дата регистрации адреса в Адресном реестре fieldMask:dd.mm.yyyy';
COMMENT ON COLUMN ehd.address_registry_property_objects.n_fias           IS 'Уникальный номер адреса в государственном адресном реестре';
COMMENT ON COLUMN ehd.address_registry_property_objects.d_fias           IS 'Дата регистрации адреса в государственном адресном реестре fieldMask:dd.mm.yyyy';
-- COMMENT ON COLUMN ehd.address_registry_property_objects.kad_n            IS 'Кадастровый номер объекта недвижимости (кроме земельного участка refCatalog:27455';
-- COMMENT ON COLUMN ehd.address_registry_property_objects.kad_zu           IS 'Кадастровый номер земельного участка (для ОКС) refCatalog:27456';
COMMENT ON COLUMN ehd.address_registry_property_objects.kladr            IS 'Код КЛАДР для адресообразующего элемента нижнего уровня';
-- COMMENT ON COLUMN ehd.address_registry_property_objects.tdoc             IS 'Документ-основание регистрационных действий dictId:2001';
-- COMMENT ON COLUMN ehd.address_registry_property_objects.ndoc             IS 'Номер документа о регистрации адреса';
-- COMMENT ON COLUMN ehd.address_registry_property_objects.ddoc             IS 'Дата документа о регистрации адреса fieldMask:dd.mm.yyyy';
COMMENT ON COLUMN ehd.address_registry_property_objects.adr_type         IS 'Тип адреса dictId:2002';
-- COMMENT ON COLUMN ehd.address_registry_property_objects.vid              IS 'Вид адреса dictId:2004';
COMMENT ON COLUMN ehd.address_registry_property_objects.sostad           IS 'Состояние адреса dictId:2006';
COMMENT ON COLUMN ehd.address_registry_property_objects.status           IS 'Статус адреса dictId:2008';
-- COMMENT ON COLUMN ehd.address_registry_property_objects.signature        IS 'Состояние подписи';

--+---------------------------------------------------------------------------------------------------------------------
--+ используется для хранения дополнительных адресов из каталогов 28475(доп от  нашего города), 29690(доп реестр госуслуги)
--+---------------------------------------------------------------------------------------------------------------------
create table if not exists ehd.address_registry_property_objects_add
(
    global_id        bigint primary key,          -- Глобальный идентификатор родительского объекта.
    system_object_id character varying,           -- Идентификатор родительского объекта в системе интегратора
    aid              bigint,                      -- Идентификатор адреса
    obj_type         bigint,                      -- Тип объекта адресации dictId:1971
    address          character varying,           -- Полное юридическое написание адреса или описание местоположения
    unom             bigint,                      -- Учётный номер объекта адресации в БД БТИ (кроме помещения и комнаты)
    p1               bigint,                      -- Субъект РФ dictId:1972
    p3               bigint,                      -- Поселение dictId:1974
    p4               bigint,                      -- Город dictId:1976
    p5               bigint,                      -- Муниципальный округ dictId:1978
    p6               bigint,                      -- Населённый пункт dictId:1980
    p7               bigint,        -- Наименование элемента планировочной структуры или улично-дорожной сети dictId:1982
    p90              bigint,                      -- Дополнительный адресообразующий элемент dictId:1984
    p91              bigint,                      -- Уточнение дополнительного адресообразующего элемента dictId:1988
    l1_type          bigint,                      -- Тип номера дома, владения, участка dictId:1990
    l1_value         character varying,           -- Номер дома, владения, участка
    l2_type          bigint,                      -- Тип номера корпуса dictId:1992
    l2_value         character varying,           -- Номер корпуса
    l3_type          bigint,                      -- Тип номера строения, сооружения dictId:1994
    l3_value         character varying,           -- Номер строения, сооружения
    l4_type          bigint,                      -- Тип номера помещения dictId:1996
    l4_value         character varying,           -- Номер помещения
    l5_type          bigint,                      -- Тип номера комнаты dictId:1996
    l5_value         character varying,           -- Номер комнаты
    adm_area         bigint,                      -- Административный округ dictId:1997
    district         bigint,                      -- Муниципальный округ, поселение dictId:1999
    nreg             bigint,                      -- Уникальный номер адреса в Адресном реестре
    dreg             varchar(30),                 -- Дата регистрации адреса в Адресном реестре fieldMask:dd.mm.yyyy
    n_fias           character varying,           -- Уникальный номер адреса в государственном адресном реестре
    d_fias           varchar(30),                 -- Дата регистрации адреса в государственном адресном реестре fieldMask:dd.mm.yyyy
    kladr            character varying,           -- Код КЛАДР для адресообразующего элемента нижнего уровня
    adr_type         bigint,                      -- Тип адреса dictId:2002
    sostad           bigint,                      -- Состояние адреса dictId:2006
    status           bigint                       -- Статус адреса dictId:2008
--     is_deleted       int                          -- Статус удаления: 1 - удален, 0 - не удален
);

-- alter table ehd.address_registry_property_objects_add owner to postgres;

comment on table ehd.address_registry_property_objects_add is 'ID 28475::Дополнение к Адресному реестру объектов недвижимости города Москвы, 29690::Дополнение к Адресному реестру объектов недвижимости города Москвы для оказания государственных услуг в электронном виде';
comment on column ehd.address_registry_property_objects_add.global_id        is 'Глобальный идентификатор родительского объекта.';
comment on column ehd.address_registry_property_objects_add.system_object_id is 'Идентификатор родительского объекта в системе интегратора';
comment on column ehd.address_registry_property_objects_add.aid              is 'Идентификатор адреса';
comment on column ehd.address_registry_property_objects_add.obj_type         is 'Тип объекта адресации dictId:1971';
comment on column ehd.address_registry_property_objects_add.address          is 'Полное юридическое написание адреса или описание местоположения';
comment on column ehd.address_registry_property_objects_add.unom             is 'Учётный номер объекта адресации в БД БТИ (кроме помещения и комнаты)';
comment on column ehd.address_registry_property_objects_add.p1               is 'Субъект РФ dictId:1972';
comment on column ehd.address_registry_property_objects_add.p3               is 'Поселение dictId:1974';
comment on column ehd.address_registry_property_objects_add.p4               is 'Город dictId:1976';
comment on column ehd.address_registry_property_objects_add.p5               is 'Муниципальный округ dictId:1978';
comment on column ehd.address_registry_property_objects_add.p6               is 'Населённый пункт dictId:1980';
comment on column ehd.address_registry_property_objects_add.p7               is 'Наименование элемента планировочной структуры или улично-дорожной сети dictId:1982';
comment on column ehd.address_registry_property_objects_add.p90              is 'Дополнительный адресообразующий элемент dictId:1984';
comment on column ehd.address_registry_property_objects_add.p91              is 'Уточнение дополнительного адресообразующего элемента dictId:1988';
comment on column ehd.address_registry_property_objects_add.l1_type          is 'Тип номера дома, владения, участка dictId:1990';
comment on column ehd.address_registry_property_objects_add.l1_value         is 'Номер дома, владения, участка';
comment on column ehd.address_registry_property_objects_add.l2_type          is 'Тип номера корпуса dictId:1992';
comment on column ehd.address_registry_property_objects_add.l2_value         is 'Номер корпуса';
comment on column ehd.address_registry_property_objects_add.l3_type          is 'Тип номера строения, сооружения dictId:1994';
comment on column ehd.address_registry_property_objects_add.l3_value         is 'Номер строения, сооружения';
comment on column ehd.address_registry_property_objects_add.l4_type          is 'Тип номера помещения dictId:1996';
comment on column ehd.address_registry_property_objects_add.l4_value         is 'Номер помещения';
comment on column ehd.address_registry_property_objects_add.l5_type          is 'Тип номера комнаты dictId:1996';
comment on column ehd.address_registry_property_objects_add.l5_value         is 'Номер комнаты';
comment on column ehd.address_registry_property_objects_add.adm_area         is 'Административный округ dictId:1997';
comment on column ehd.address_registry_property_objects_add.district         is 'Муниципальный округ, поселение dictId:1999';
comment on column ehd.address_registry_property_objects_add.nreg             is 'Уникальный номер адреса в Адресном реестре';
comment on column ehd.address_registry_property_objects_add.dreg             is 'Дата регистрации адреса в Адресном реестре fieldMask:dd.mm.yyyy';
comment on column ehd.address_registry_property_objects_add.n_fias           is 'Уникальный номер адреса в государственном адресном реестре';
comment on column ehd.address_registry_property_objects_add.d_fias           is 'Дата регистрации адреса в государственном адресном реестре fieldMask:dd.mm.yyyy';
comment on column ehd.address_registry_property_objects_add.kladr            is 'Код КЛАДР для адресообразующего элемента нижнего уровня';
comment on column ehd.address_registry_property_objects_add.adr_type         is 'Тип адреса dictId:2002';
comment on column ehd.address_registry_property_objects_add.sostad           is 'Состояние адреса dictId:2006';
comment on column ehd.address_registry_property_objects_add.status           is 'Статус адреса dictId:2008';
-- comment on column ehd.address_registry_property_objects_add.is_deleted           is 'Статус удаления: 1 - удален, 0 - не удален';

create index CONCURRENTLY idx_arpoa_data on ehd.address_registry_property_objects_add
    (
     (p1 is not null),
     (p1 in (645611645, 645608448)),
     (sostad is not null),
     (sostad not in (645607758, 645608660, 645608507)),
     (status is not null),
     (status != 645611001),
     unom
);

/*
-- Table: ehd.tib_address_registry Catalog ID:28439

-- DROP TABLE IF EXISTS ehd.tib_address_registry;
CREATE TABLE IF NOT EXISTS ehd.tib_address_registry
(
  global_id        bigint PRIMARY KEY,                                                      -- Глобальный идентификатор родительского объекта.
  system_object_id character varying,                                                       -- Идентификатор родительского объекта в системе интегратора
  id               character varying,                                                       -- Уникальный идентификатор записи каталога
  id_new           character varying,                                                       -- Идентификатор2
  unom             bigint,                                                                  -- Уникальный номер статкарты
  unad             bigint,                                                                  -- Уникальный номер адреса в статкарте
  ul               bigint REFERENCES ehd.tib_street_classifier (global_id),                 -- Код улицы refCatalog:28506
  dmt              character varying,                                                       -- Дом номер
  vld              bigint,                                                                  -- Признак владения  refCatalog:28641
  krt              character varying,                                                       -- Корпус номер
  strt             character varying,                                                       -- Строение номер
  lit              bigint,                                                                  -- Признак литеры
  soor             bigint,                                                                  -- Признак сооружения refCatalog:28642
  status           character varying,                                                       -- Признак статуса адреса
  sostad           bigint,                                                                  -- SOSTAD
  tdoc             bigint,                                                                  -- Тип документа для регистрации адреса refCatalog:28643
  ndoc             character varying,                                                       -- Номер документа
  ddoc             character varying,                                                       -- Дата документа fieldMask:dd.mm.yyyy
  sdoc             bigint,                                                                  -- Содержание документа refCatalog:28636
  nreg             bigint,                                                                  -- Номер регистрации
  dreg             character varying,                                                       -- Дата регистрации fieldMask:dd.mm.yyyy
  dop_adr          bigint,                                                                  -- Признак наличия дополнительного адреса
  aok              bigint REFERENCES ehd.tib_adminstrative_district_classifier (global_id), -- Код административного округа refCatalog:28507
  mr               bigint REFERENCES ehd.tib_region_classifier (global_id),                 -- Код муниципального района refCatalog:28508
  adres            character varying                                                        -- Адрес
  --   signature        character varying            -- Состояние подписи
);

ALTER TABLE ehd.tib_address_registry
  OWNER to postgres;

COMMENT ON TABLE ehd.tib_address_registry IS 'ID 28439::БТИ. Адресный реестр';
COMMENT ON COLUMN ehd.tib_address_registry.global_id        IS 'Глобальный идентификатор родительского объекта.';
COMMENT ON COLUMN ehd.tib_address_registry.system_object_id IS 'Идентификатор родительского объекта в системе интегратора';
COMMENT ON COLUMN ehd.tib_address_registry.id               IS 'Уникальный идентификатор записи каталога';
COMMENT ON COLUMN ehd.tib_address_registry.id_new           IS 'Идентификатор2';
COMMENT ON COLUMN ehd.tib_address_registry.unom             IS 'Уникальный номер статкарты';
COMMENT ON COLUMN ehd.tib_address_registry.unad             IS 'Уникальный номер адреса в статкарте';
COMMENT ON COLUMN ehd.tib_address_registry.ul               IS 'Код улицы refCatalog:28506';
COMMENT ON COLUMN ehd.tib_address_registry.dmt              IS 'Дом номер';
COMMENT ON COLUMN ehd.tib_address_registry.vld              IS 'Признак владения  refCatalog:28641';
COMMENT ON COLUMN ehd.tib_address_registry.krt              IS 'Корпус номер';
COMMENT ON COLUMN ehd.tib_address_registry.strt             IS 'Строение номер';
COMMENT ON COLUMN ehd.tib_address_registry.lit              IS 'Признак литеры';
COMMENT ON COLUMN ehd.tib_address_registry.soor             IS 'Признак сооружения refCatalog:28642';
COMMENT ON COLUMN ehd.tib_address_registry.status           IS 'Признак статуса адреса';
COMMENT ON COLUMN ehd.tib_address_registry.sostad           IS 'SOSTAD';
COMMENT ON COLUMN ehd.tib_address_registry.tdoc             IS 'Тип документа для регистрации адреса refCatalog:28643';
COMMENT ON COLUMN ehd.tib_address_registry.ndoc             IS 'Номер документа';
COMMENT ON COLUMN ehd.tib_address_registry.ddoc             IS 'Дата документа fieldMask:dd.mm.yyyy';
COMMENT ON COLUMN ehd.tib_address_registry.sdoc             IS 'Содержание документа refCatalog:28636';
COMMENT ON COLUMN ehd.tib_address_registry.nreg             IS 'Номер регистрации';
COMMENT ON COLUMN ehd.tib_address_registry.dreg             IS 'Дата регистрации fieldMask:dd.mm.yyyy';
COMMENT ON COLUMN ehd.tib_address_registry.dop_adr          IS 'Признак наличия дополнительного адреса';
COMMENT ON COLUMN ehd.tib_address_registry.aok              IS 'Код административного округа refCatalog:28507';
COMMENT ON COLUMN ehd.tib_address_registry.mr               IS 'Код муниципального района refCatalog:28508';
COMMENT ON COLUMN ehd.tib_address_registry.adres            IS 'Адрес';
-- COMMENT ON COLUMN ehd.tib_address_registry.signature        IS 'Состояние подписи';

-- Table: ehd.tib_street_classifier Catalog ID:28506

-- DROP TABLE IF EXISTS ehd.tib_street_classifier;
CREATE TABLE IF NOT EXISTS ehd.tib_street_classifier
(
  global_id        bigint PRIMARY KEY, -- Глобальный идентификатор родительского объекта.
  system_object_id character varying,  -- Идентификатор родительского объекта в системе интегратора
  kod_givz         bigint,             -- Уникальный код улицы
  ul_old           bigint,             -- UL_OLD
  nm               character varying,  -- Наименование улицы для поиска, сортировки
  nmdoc1           character varying,  -- Действующее на данный момент наименование улицы для документов
  nmdoc2           character varying,  -- Действующее наименование для документов, приведенное к написанию наименования по ОМК УМ, но с сокращениями географических терминов
  nak              character varying,  -- Короткое наименование улицы МосгорБТИ
  nm_givz          character varying,  -- Наименование  улицы по ОМК УМ
  sostn            bigint,             -- Код состояния наименования
  actsostn         int,                -- Признак действующего наименования (1 — да, 0 — нет)
  terr             character varying,  -- Территориальная принадлежность улицы (коды районов)
  rem              character varying,  -- Примечание
  osn              bigint,             -- Код документа, на основании которого произведен ввод наименования
  n_doc            character varying,  -- Номер документа, на основании которого произведен ввод наименования
  d_osn            character varying,  -- Дата документа, на основании которого произведен ввод наименования
  d_osn_std        character varying,  -- Стандартизованная дата документа, на основании которого произведен ввод наименования fieldMask:dd.mm.yyyy
  ret              character varying,  -- Код «родителей» (ретроспектива)
  pers             character varying,  -- Код «потомков» (перспектива)
  kod_fo           bigint,             -- Код улицы как физического объекта
  d_vv_bd          character varying,  -- Дата ввода в Базу данных fieldMask:dd.mm.yyyy
  main_nm          character varying,  -- Основное наименование (без типа топонима)
  tp_top           bigint,             -- Код типа топонима
  prkl_ul          bigint,             -- Признак принадлежности к ОМК УМ
  zz               bigint,             -- Признак удаления
  dkor             character varying,  -- DKOR fieldMask:dd.mm.yyyy
  ulid             bigint,             -- ULID
  zb1              bigint,             -- ZB1
  zb2              bigint,             -- ZB2
  zl1              bigint,             -- ZL1
  zl2              bigint,             -- ZL2
  zs1              bigint,             -- ZS1
  nak_sostn        character varying,  -- Состояние наименования  улицы
  nak_osn          character varying,  -- Документ, на основании которого произведен ввод наименования
  nak_tp_top       character varying,  -- Наименование типа топонима
  recptr           bigint,             -- RECPTR
  delrec           bigint              -- DELREC
--  signature        character varying   -- Состояние подписи
);

ALTER TABLE ehd.tib_street_classifier
  OWNER to postgres;

COMMENT ON TABLE ehd.tib_street_classifier IS 'ID 28506::БТИ. Классификатор улиц';
COMMENT ON COLUMN ehd.tib_street_classifier.global_id        IS 'Глобальный идентификатор родительского объекта.';
COMMENT ON COLUMN ehd.tib_street_classifier.system_object_id IS 'Идентификатор родительского объекта в системе интегратора';
COMMENT ON COLUMN ehd.tib_street_classifier.kod_givz         IS 'Уникальный код улицы';
COMMENT ON COLUMN ehd.tib_street_classifier.ul_old           IS 'UL_OLD';
COMMENT ON COLUMN ehd.tib_street_classifier.nm               IS 'Наименование улицы для поиска, сортировки';
COMMENT ON COLUMN ehd.tib_street_classifier.nmdoc1           IS 'Действующее на данный момент наименование улицы для документов';
COMMENT ON COLUMN ehd.tib_street_classifier.nmdoc2           IS 'Действующее наименование для документов, приведенное к написанию наименования по ОМК УМ, но с сокращениями географических терминов';
COMMENT ON COLUMN ehd.tib_street_classifier.nak              IS 'Короткое наименование улицы МосгорБТИ';
COMMENT ON COLUMN ehd.tib_street_classifier.nm_givz          IS 'Наименование  улицы по ОМК УМ';
COMMENT ON COLUMN ehd.tib_street_classifier.sostn            IS 'Код состояния наименования';
COMMENT ON COLUMN ehd.tib_street_classifier.actsostn         IS 'Признак действующего наименования (1 — да, 0 — нет)';
COMMENT ON COLUMN ehd.tib_street_classifier.terr             IS 'Территориальная принадлежность улицы (коды районов)';
COMMENT ON COLUMN ehd.tib_street_classifier.rem              IS 'Примечание';
COMMENT ON COLUMN ehd.tib_street_classifier.osn              IS 'Код документа, на основании которого произведен ввод наименования';
COMMENT ON COLUMN ehd.tib_street_classifier.n_doc            IS 'Номер документа, на основании которого произведен ввод наименования';
COMMENT ON COLUMN ehd.tib_street_classifier.d_osn            IS 'Дата документа, на основании которого произведен ввод наименования';
COMMENT ON COLUMN ehd.tib_street_classifier.d_osn_std        IS 'Стандартизованная дата документа, на основании которого произведен ввод наименования fieldMask:dd.mm.yyyy';
COMMENT ON COLUMN ehd.tib_street_classifier.ret              IS 'Код «родителей» (ретроспектива)';
COMMENT ON COLUMN ehd.tib_street_classifier.pers             IS 'Код «потомков» (перспектива)';
COMMENT ON COLUMN ehd.tib_street_classifier.kod_fo           IS 'Код улицы как физического объекта';
COMMENT ON COLUMN ehd.tib_street_classifier.d_vv_bd          IS 'Дата ввода в Базу данных fieldMask:dd.mm.yyyy';
COMMENT ON COLUMN ehd.tib_street_classifier.main_nm          IS 'Основное наименование (без типа топонима)';
COMMENT ON COLUMN ehd.tib_street_classifier.tp_top           IS 'Код типа топонима';
COMMENT ON COLUMN ehd.tib_street_classifier.prkl_ul          IS 'Признак принадлежности к ОМК УМ';
COMMENT ON COLUMN ehd.tib_street_classifier.zz               IS 'Признак удаления';
COMMENT ON COLUMN ehd.tib_street_classifier.dkor             IS 'DKOR fieldMask:dd.mm.yyyy';
COMMENT ON COLUMN ehd.tib_street_classifier.ulid             IS 'ULID';
COMMENT ON COLUMN ehd.tib_street_classifier.zb1              IS 'ZB1';
COMMENT ON COLUMN ehd.tib_street_classifier.zb2              IS 'ZB2';
COMMENT ON COLUMN ehd.tib_street_classifier.zl1              IS 'ZL1';
COMMENT ON COLUMN ehd.tib_street_classifier.zl2              IS 'ZL2';
COMMENT ON COLUMN ehd.tib_street_classifier.zs1              IS 'ZS1';
COMMENT ON COLUMN ehd.tib_street_classifier.nak_sostn        IS 'Состояние наименования  улицы';
COMMENT ON COLUMN ehd.tib_street_classifier.nak_osn          IS 'Документ, на основании которого произведен ввод наименования';
COMMENT ON COLUMN ehd.tib_street_classifier.nak_tp_top       IS 'Наименование типа топонима';
COMMENT ON COLUMN ehd.tib_street_classifier.recptr           IS 'RECPTR';
COMMENT ON COLUMN ehd.tib_street_classifier.delrec           IS 'DELREC';
-- COMMENT ON COLUMN ehd.tib_street_classifier.signature        IS 'Состояние подписи';
*/

-- Table: ehd.tib_adminstrative_district_classifier Catalog ID:28507

CREATE TABLE IF NOT EXISTS ehd.tib_adminstrative_district_classifier
(
  global_id        bigint PRIMARY KEY,          -- Глобальный идентификатор родительского объекта.
  system_object_id character varying,           -- Идентификатор родительского объекта в системе интегратора
  kod              character varying,           -- Код
  nm               character varying,           -- Наименование
  givc             character varying            -- Код ГИВЦ
  --   signature        character varying            -- Состояние подписи
);

-- ALTER TABLE ehd.tib_adminstrative_district_classifier
--   OWNER to postgres;

COMMENT ON TABLE ehd.tib_adminstrative_district_classifier IS 'ID 28507::БТИ. Классификатор административных округов';
COMMENT ON COLUMN ehd.tib_adminstrative_district_classifier.global_id        IS 'Глобальный идентификатор родительского объекта.';
COMMENT ON COLUMN ehd.tib_adminstrative_district_classifier.system_object_id IS 'Идентификатор родительского объекта в системе интегратора';
COMMENT ON COLUMN ehd.tib_adminstrative_district_classifier.kod              IS 'Код';
COMMENT ON COLUMN ehd.tib_adminstrative_district_classifier.nm               IS 'Наименовани';
COMMENT ON COLUMN ehd.tib_adminstrative_district_classifier.givc             IS 'Код ГИВЦ';
-- COMMENT ON COLUMN ehd.tib_adminstrative_district_classifier.signature        IS 'Состояние подписи';

-- Table: ehd.tib_region_classifier Catalog ID:28508

CREATE TABLE IF NOT EXISTS ehd.tib_region_classifier
(
  global_id        bigint PRIMARY KEY,          -- Глобальный идентификатор родительского объекта.
  system_object_id character varying,           -- Идентификатор родительского объекта в системе интегратора
  kod              character varying,           -- Код
  nm               character varying,           -- Наименование
  givz             character varying            -- Код ГИВЗ
  --   signature        character varying            -- Состояние подписи
);

-- ALTER TABLE ehd.tib_region_classifier
--   OWNER to postgres;

COMMENT ON TABLE ehd.tib_region_classifier IS 'ID 28508::БТИ. Классификатор районов';
COMMENT ON COLUMN ehd.tib_region_classifier.global_id        IS 'Глобальный идентификатор родительского объекта.';
COMMENT ON COLUMN ehd.tib_region_classifier.system_object_id IS 'Идентификатор родительского объекта в системе интегратора';
COMMENT ON COLUMN ehd.tib_region_classifier.kod              IS 'Код';
COMMENT ON COLUMN ehd.tib_region_classifier.nm               IS 'Наименовани';
COMMENT ON COLUMN ehd.tib_region_classifier.givz             IS 'Код ГИВЗ';
-- COMMENT ON COLUMN ehd.tib_region_classifier.signature        IS 'Состояние подписи';