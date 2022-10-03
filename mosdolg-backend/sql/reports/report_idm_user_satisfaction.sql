drop function if exists public.report_idm_user_satisfaction;
create function public.report_idm_user_satisfaction()
  returns TABLE (
    login                 text,
    creation_date         text,
    last_login            text,
    short_title           text,
    full_title            text,
    department            text,
    i_role_id             text,
    i_role_name           text,
    password_expired_date text
  )
  language plpgsql
as $$
begin
  
  return query
    select eup.login,
           eu.creation_date::text,
           eu.last_login::text,
           o.short_title,
           o.full_title,
           d.title                                      as department,
           string_agg(distinct dupr.roleid::text, ', ') as i_role_id,
           string_agg(distinct er.name, ', ')           as i_role_name,
           elup.password_expired_date::text
    from public_idm.ent_users eu
           join public_idm.ent_user_profiles eup on eu.id = eup.userid
           left join public_idm.ent_local_user_profiles elup on eup.id = elup.id
           left join public_idm.dep_user_profiles_roles dupr on eup.id = dupr.entityid and dupr.dateto is null
           left join public_idm.ent_roles er on dupr.roleid = er.id
           left join md.user_profile up on eup.id = up.id::bigint
           left join md.coworker cw on up.coworker_id = cw.id
           left join md.organization o on cw.organization_id = o.id
           left join reference.department d on o.department_id = d.id
    where eu.removal_date is null
      and eup.removal_date is null
      and dupr.dateto is null
    group by eup.login, eu.creation_date, eu.last_login, o.full_title, o.short_title, d.title,
             elup.password_expired_date;
end
$$;