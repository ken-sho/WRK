drop function if exists public.report_idm_user;
create function public.report_idm_user()
  returns TABLE (
    login         text,
    lastname      text,
    firstname     text,
    middlename    text,
    phone         text,
    email         text,
    creation_date text,
    last_login    text,
    short_title   text,
    full_title    text,
    department    text,
    i_role_id     text,
    i_role_name   text,
    password_expired_date text
  )
  language plpgsql
as $$
begin
  
  return query
    select eup.login::text,
           eu.lastname::text,
           eu.firstname::text,
           eu.middlename::text,
           eu.phone::text,
           eu.email::text,
           to_char(eu.creation_date, 'dd.mm.yyyy HH24:MI:SS'),
           to_char(eu.last_login, 'dd.mm.yyyy HH24:MI:SS'),
           o.short_title::text,
           o.full_title::text,
           d.title::text                                as department,
           string_agg(distinct dupr.roleid::text, ', ') as i_role_id,
           string_agg(distinct er.name, ', ')           as i_role_name,
           to_char(elup.password_expired_date, 'dd.mm.yyyy HH24:MI:SS')
    from public_idm.ent_users eu
           join public_idm.ent_user_profiles eup on eu.id = eup.userid
           left join public_idm.ent_local_user_profiles elup on eup.id = elup.id
           left join public_idm.dep_user_profiles_roles dupr on eup.id = dupr.entityid
           left join public_idm.ent_roles er on dupr.roleid = er.id
           left join md.user_profile up on eup.id = up.id::bigint
           left join md.coworker cw on up.coworker_id = cw.id
           left join md.organization o on cw.organization_id = o.id
           left join reference.department d on o.department_id = d.id
    group by eup.login, eu.creation_date, eu.last_login, o.full_title, o.short_title, d.title,
             eu.lastname, eu.firstname, eu.middlename, eu.phone, eu.email, elup.password_expired_date;
end
$$;