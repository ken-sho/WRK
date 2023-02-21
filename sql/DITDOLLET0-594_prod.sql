with P as (
    select id
    from md.participant
    where organization_id is null
),
A as (
    select aud.id as participant_id, o.id as organization_id
    from audit.participant_aud aud
        join P on aud.id = P.id
        join audit.revision rev on aud.rev = rev.id
        join md.user_profile up on rev.user_id = up.id
        join md.coworker co on co.id = up.coworker_id
        join md.organization o on o.id = co.organization_id
    where aud.revtype = 0
        and o.level_id = 3
)
update md.participant
set organization_id = (select organization_id from A where participant_id = id limit 1)
where id in (select participant_id from A);