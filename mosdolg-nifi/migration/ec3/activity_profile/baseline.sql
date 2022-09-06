-- ACTIVITY PROFILE
--+---------------------------------------------------------------------------------------------------------------------
--+ Профиль активности
--+---------------------------------------------------------------------------------------------------------------------

--+---------------------------------------------------------------------------------------------------------------------
--+ создание migration.participant_activity_profile
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.participant_activity_profile;
create table if not exists sdb.participant_activity_profile(
    aid bigint primary key,
    participant_id bigint,
    activity_id int,
    first_classificator int,
    second_classificator int,
    third_classificator int,
    schedule_type_id int,
    week_days_type_id int,
    date_from character varying,
    comment character varying
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Справочник Направление (SDB)
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists sdb.ref_activity;
create table if not exists sdb.ref_activity(
    aid bigint primary key,
    title character varying,
    parent_id bigint
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Справочник Направление (IDB) аналог reference.activity
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.ref_activity;
create table if not exists idb.ref_activity(
    id bigint primary key,
    title character varying,
    parent_id bigint
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Сущность Профиль активности (IDB) аналог md.participant_activity_profile
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.participant_activity_profile;
CREATE TABLE if not exists idb.participant_activity_profile (
	id bigserial NOT NULL,
	participant_id int8 NULL,
	activity_id int8 NULL,
	date_from date NULL,
	date_to date NULL,
	"comment" varchar(1000) NULL,
	-- satisfaction bool NOT NULL DEFAULT false,
	status_id int8 NULL,
    CONSTRAINT pk_participant_activity_profile_id PRIMARY KEY (id)
--	CONSTRAINT fk_participant_activity_profile FOREIGN KEY (participant_id) REFERENCES md.participant(id),
--	CONSTRAINT fk_participant_activity_profile_activity FOREIGN KEY (activity_id) REFERENCES reference.activity(id),
--	CONSTRAINT participant_activity_profile_participant_activity_profile_statu FOREIGN KEY (status_id) REFERENCES reference.participant_activity_profile_status(id)
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Сущность Профиль активности (предпочитаемое время) (IDB) аналог md.participant_activity_profile_preferred_daytime
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.participant_activity_profile_preferred_daytime;
CREATE TABLE if not exists idb.participant_activity_profile_preferred_daytime(
	activity_id int8 NOT NULL,
	preferred_daytime_id int8 NOT NULL,
    CONSTRAINT pk__participant_activity_profile_preferred_daytime_id PRIMARY KEY (activity_id, preferred_daytime_id)
--	CONSTRAINT fk__participant_activity_profile_preferred_daytime_1 FOREIGN KEY (activity_id) REFERENCES md.participant_activity_profile(id),
--	CONSTRAINT fk__participant_activity_profile_preferred_daytime_2 FOREIGN KEY (preferred_daytime_id) REFERENCES reference.daytime(id)
);

--+---------------------------------------------------------------------------------------------------------------------
--+ Сущность Профиль активности (предпочитаемые дни) (IDB) аналог md.participant_activity_profile_weekday
--+---------------------------------------------------------------------------------------------------------------------
drop table if exists idb.participant_activity_profile_weekday;
CREATE TABLE if not exists idb.participant_activity_profile_weekday(
	activity_id int8 NOT NULL,
	weekday varchar(25) NOT NULL,
    CONSTRAINT pk__participant_activity_profile_weekday_id PRIMARY KEY (activity_id, weekday)
--	CONSTRAINT fk__participant_activity_profile_weekday_1 FOREIGN KEY (activity_id) REFERENCES md.participant_activity_profile(id)
);
