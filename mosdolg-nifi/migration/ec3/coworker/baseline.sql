-- 12.08
--COWORKER
--+---------------------------------------------------------------------------------------------------------------------
--+ Сотрудники
--+---------------------------------------------------------------------------------------------------------------------


--+---------------------------------------------------------------------------------------------------------------------
--+ Создаем миграционную таблицу migration.coworker_teacher;
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.coworker_teacher;
create table if not exists sdb.coworker_teacher(
    aid bigint primary key,
    first_name character varying,
    second_name character varying,
    middle_name character varying,
    organization_id bigint,
    phone character varying,
    email character varying
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Создаем миграционную таблицу migration.coworker_user
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.coworker_user;
create table if not exists sdb.coworker_user(
    aid bigint primary key,
    name character varying,
    organization_id bigint,
    position character varying,
    login character varying,
    phone character varying,
    email character varying
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Создаем для предварительного анализа данных таблицу migration.coworkers (аналогичную основной)
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.coworkers;
create table if not exists sdb.coworkers(
    id bigint primary key,
    first_name varchar(255),
    second_name varchar(255),
    middle_name varchar(255),
    organization_id bigint,
    manager_id bigint,
    position varchar(800),
    fired_date date,
    is_teacher boolean,
    is_deputy boolean,
    is_director boolean,
    is_coordinator boolean,
    idm_sid varchar(255)
);


--+---------------------------------------------------------------------------------------------------------------------
--+ Создаем для предварительного анализа данных таблицу idb.coworkers (аналогичную основной)
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.coworkers;
create table if not exists idb.coworkers(
    id bigint primary key,
    first_name varchar(255),
    second_name varchar(255),
    middle_name varchar(255),
    organization_id bigint,
    manager_id bigint,
    position varchar(800),
    fired_date date,
    is_teacher boolean,
    is_deputy boolean,
    is_director boolean,
    is_coordinator boolean,
    idm_sid varchar(255)
);