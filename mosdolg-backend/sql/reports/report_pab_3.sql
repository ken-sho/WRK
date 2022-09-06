drop function if exists public.report_pab_3;
CREATE OR REPLACE FUNCTION public.report_pab_3()
  returns TABLE (
    field character varying,
    value bigint
  )
  language plpgsql
as $$
begin
  
  return query
    with
      L1 as ( -- последний статус группы
        select distinct on (group_id)
               group_id,
               first_value(status_id) over (partition by group_id order by id desc) as last_status
        from md.group_status_registry
      ),
      G0 as (
        select 'groups total' as field,
               count(1)       as value
        from L1
      ),
      G1 as (
        select last_status::varchar as field,
               count(1)             as value
        from L1
        group by last_status
      ),
      G2 as (
        select 'groups without schedule' as field,
               count(g.id)               as value
        from md.groups g
               left join md.schedule on g.id = schedule.group_id
        where schedule.id is null
      ),
      L3 as ( -- последний статус записи в группу
        select distinct on (class_record_id)
               class_record_id,
               first_value(class_record_status_id) over (partition by class_record_id order by id desc) as last_status
        from md.class_record_status_registry
      ),
      G3_1 as (
        select 'occupied_group_places' as field,
               count(1)                as value
        from md.class_record cr
               join L3 crsr on cr.id = crsr.class_record_id
            and crsr.last_status in (1, 3, 6, 7)
      ),
      L2 as ( -- последний статус участника
        select distinct on (participant_id)
               participant_id,
               first_value(status_id) over (partition by participant_id order by id desc) as last_status
        from reference.participant_status_log
      ),
      G3_2 as (
        -- число участников в группах
        select 'unique participants in group' as field,
               count(p.id)                    as value
        from md.participant p
               join L2 on p.id = L2.participant_id
        where L2.last_status = 7
        group by L2.last_status
      ),
      G4 as ( -- количество уникальных участников, разбитых по статусам, включая сумму
        select L2.last_status::varchar as field,
               count(p.id)             as value
        from md.participant p
               left join L2 on p.id = L2.participant_id
        group by last_status
        order by last_status
      ),
      G4_2 as ( -- ... сумма - из статусов
        select 'participants total (with statuses)' as field,
               count(1)                             as value
        from L2
      ),
      G4_3 as ( -- ... сумма - из участников
        select 'participants total (any)' as field,
               count(1)                   as value
        from md.participant
      ),
      G5 as ( -- Количество поставщиков
        select 'providers total' as field,
               count(1)          as value
        from md.organization
        where is_provider = true
      )
        
        (select '== groups by status' as field, 0 as value)
    union all
    (select * from G1 order by field)
    union all
    (select * from G0)
    union all
    (select * from G2)
    union all
    (select * from G3_1)
    union all
    (select * from G3_2)
    union all
    (select '== participants by status' as field, 0 as value)
    union all
    (select * from G4)
    union all
    (select * from G4_2)
    union all
    (select * from G4_3)
    union all
    (select * from G5);

end;
$$;