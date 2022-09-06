--insert into idb.foreign_ent_users select * from idb.ent_users;
--insert into idb.foreign_ent_user_profiles select * from idb.ent_user_profiles;
--insert into idb.foreign_ent_local_user_profiles select * from idb.ent_local_user_profiles;
--insert into idb.foreign_ent_user_lock select * from idb.ent_user_lock;
--insert into idb.foreign_dep_user_profiles_roles select * from idb.dep_user_profiles_roles;

-- select * from idb.foreign_ent_users;

-- Чтобы накатить новых пользаков, необходимо провести фазы миграции transform вручную, предварительно увеличив sequence для этих сущностей на 100000;

insert into idb.new_users select * from idb.ent_users where email not in (select email from idb.foreign_ent_users) and id not in (select id from idb.foreign_ent_users);

-- Новые пользаки
insert into idb.foreign_ent_users
select * from idb.new_users where email not in (select email from idb.foreign_ent_users) and id not in (select id from idb.foreign_ent_users);

-- insert into idb.new_user_profiles select * from idb.ent_user_profiles where userid in (select id from idb.new_users);

-- Новые профайлы
insert into idb.foreign_ent_user_profiles
select * from idb.ent_user_profiles where userid in (select id from idb.new_users);

-- Новые локал профайлы
insert into idb.foreign_ent_local_user_profiles
select * from idb.ent_local_user_profiles where id in (select id from idb.ent_user_profiles where userid in (select id from idb.new_users));

-- Новые dep_user_profiles_roles
insert into idb.foreign_dep_user_profiles_roles
select * from idb.dep_user_profiles_roles where entityid in (select id from idb.ent_user_profiles where userid in (select id from idb.new_users));


-- select u.id from idb.foreign_ent_users u left join idb.foreign_ent_local_user_profiles p on p.id=u.id where p.id is null какое-то чудо