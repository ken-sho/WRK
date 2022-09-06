--delete from idb.foreign_dep_user_profiles_roles dep where dep.entityid in (select userid from idb.foreign_ent_user_profiles where userid > 100000);
--delete from idb.foreign_ent_local_user_profiles lpr where lpr.id > 100000;
--delete from idb.foreign_ent_user_profiles pr where pr.userid > 100000;
--delete from idb.foreign_ent_user_lock l where l.user_id > 100000;
--delete from idb.foreign_ent_users u where u.id > 100000;


insert into idb.foreign_ent_users select * from idb.ent_users;
insert into idb.foreign_ent_user_profiles select * from idb.ent_user_profiles;
insert into idb.foreign_ent_local_user_profiles select * from idb.ent_local_user_profiles;
insert into idb.foreign_ent_user_lock select * from idb.ent_user_lock;
insert into idb.foreign_dep_user_profiles_roles select * from idb.dep_user_profiles_roles;