truncate table idb.ent_users;
truncate table idb.ent_user_profiles_map;
truncate table idb.ent_user_profiles;
truncate table idb.ent_local_user_profiles;
truncate table idb.ent_user_lock;
truncate table idb.dep_user_profiles_roles;

create or replace function idb.get_role(role_aid bigint) returns int as
$body$
begin
	case
		when role_aid = 217 then return 44;
		when role_aid = 221 then return 45;
		when role_aid = 225 then return 46;
		when role_aid = 227 then return 47;
		when role_aid = 230 then return 48;
		when role_aid = 233 then return 49;
	else return null;
	end case;
end;
$body$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Переносим данные в целевую таблицу ent_users
--+---------------------------------------------------------------------------------------------------------------------
insert into idb.ent_users(id, lastname, firstname, middlename, email, organizationid, creation_date, phone, locale, last_login)
select
    idb.get_user_id_by_ec3_id(iu.id),
    iu.lastname,
    iu.firstname,
    iu.middlename,
    iu.email,
    1,
    to_timestamp((iu.creation_date::bigint)/1000),
    iu.phone,
    'en-US',
    to_timestamp((iu.last_login::bigint)/1000)
from sdb.ent_users iu
on conflict (id) do update set lastname=excluded.lastname, firstname=excluded.firstname, middlename=excluded.middlename, email=excluded.email,
    organizationid=excluded.organizationid, creation_date=excluded.creation_date, phone=excluded.phone, locale=excluded.locale, last_login=excluded.last_login;

--+---------------------------------------------------------------------------------------------------------------------
--+ Переносим данные в две целевые таблицы: idb.ent_user_profiles, idb.ent_local_user_profiles - из idb.ent_user_profile
--+---------------------------------------------------------------------------------------------------------------------
do $$
declare
    prf_id bigint;
    cur cursor for (select
   		userid,
   		login,
		concat('{DITDOLLET}', password) as password,
   		to_timestamp((password_last_change_date::bigint)/1000) as password_last_change_date
   	from sdb.ent_user_profile);
begin
    for row in cur loop
        select nextval('idb.ent_user_profiles_id_seq') into prf_id;
        insert into idb.ent_user_profiles(id, userid, login, resourceid) values (prf_id, idb.get_user_id_by_ec3_id(row.userid), row.login, 1);
        insert into idb.ent_user_profiles_map(user_aid, profile_id) values (row.userid, prf_id);
        insert into idb.ent_local_user_profiles(id, password, password_last_change_date)
       	values (
       		prf_id,
       		row.password,
       		(case when row.password_last_change_date is not null then row.password_last_change_date else now() end)
       	);
    end loop;
end;
$$ language plpgsql;

--+---------------------------------------------------------------------------------------------------------------------
--+ Переносим данные в idb.ent_user_lock
--+---------------------------------------------------------------------------------------------------------------------
insert into idb.ent_user_lock(id, user_id, lock_from, type)
select
	nextval('idb.ent_user_lock_id_seq'),
	idb.get_user_id_by_ec3_id(user_id),
	to_timestamp((lock_from::bigint)/1000),
	'AUTH_MAX_ATTEMPT'
from sdb.ent_user_lock where lock_from is not null;


insert into idb.dep_user_profiles_roles(
    id,
    entityid,
    roleid,
    datefrom
) select
    nextval('idb.dep_user_profiles_roles_id_seq'),
    m.profile_id,
    idb.get_role(d.role_id),
    now()
from sdb.dep_user_profiles_roles d
join idb.ent_user_profiles_map m on d.aid=m.user_aid;