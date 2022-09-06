--insert into idb.foreign_ent_users select * from idb.ent_users;
--insert into idb.foreign_ent_user_profiles select * from idb.ent_user_profiles;
--insert into idb.foreign_ent_local_user_profiles select * from idb.ent_local_user_profiles;
--insert into idb.foreign_ent_user_lock select * from idb.ent_user_lock;
--insert into idb.foreign_dep_user_profiles_roles select * from idb.dep_user_profiles_roles;

-- select * from idb.foreign_ent_users;

-- Новые пользаки
insert into idb.foreign_ent_users
select * from idb.ent_users where email not in (select email from idb.foreign_ent_users) and id not in (select id from idb.foreign_ent_users);

select * from idb.ent_users where creation_date > to_date('2019-08-01', 'YYYY-MM-DD')

select * from idb.ent_local_user_profiles where id in (select p.id from idb.foreign_ent_users u left join idb.foreign_ent_local_user_profiles p on p.id=u.id where p.id is null);

select * from idb.foreign_ent_users u left join idb.foreign_ent_local_user_profiles p on p.id=u.id where p.id is null

-- Новые профайлы
insert into idb.foreign_ent_user_profiles
select * from idb.ent_user_profiles where userid in (select u.id from idb.foreign_ent_users u left join idb.fore p on p.userid=u.id where p.id is null);

-- Новые локал профайлы
insert into idb.foreign_ent_local_user_profiles

select id from idb.ent_user_profiles where userid in (select u.id from idb.foreign_ent_users u left join idb.foreign_ent_local_user_profiles p on p.id=u.id where p.id is null)

select u.id from idb.foreign_ent_users u
left join idb.foreign_ent_user_profiles up on up.userid=u.id
left join idb.foreign_ent_local_user_profiles p on p.id=up.id where p.id is null;

select u.id from idb.foreign_ent_users u left join idb.foreign_ent_local_user_profiles p on p.id=u.id where p.id is null order by u.id;

insert into idb.foreign_ent_local_user_profiles
select * from idb.ent_local_user_profiles where id in (select id from idb.ent_user_profiles where userid in (select u.id from idb.foreign_ent_users u left join idb.foreign_ent_local_user_profiles p on p.id=u.id where p.id is null));

select id from idb.ent_user_profiles where userid in (select u.id from idb.foreign_ent_users u left join idb.foreign_ent_local_user_profiles p on p.id=u.id where p.id is null)

select u.id from idb.foreign_ent_users u left join idb.foreign_ent_local_user_profiles p on p.id=u.id where p.id is null

-- Новые dep_user_profiles_roles
insert into idb.foreign_dep_user_profiles_roles
select * from idb.dep_user_profiles_roles where entityid in (select id from idb.ent_user_profiles where userid in (select u.id from idb.foreign_ent_users u left join idb.foreign_ent_local_user_profiles p on p.id=u.id where p.id is null));