with E as (
    select id, class_record_id from md.class_record_status_registry s1
    where s1.class_record_status_id = 5
      and end_date is not null
      and s1.class_record_id in (select s2.class_record_id from md.class_record_status_registry s2 where end_date is null)
    order by class_record_id desc
),
 S as (
     select id, class_record_id from md.class_record_status_registry s1
     where s1.class_record_status_id = 5
       and end_date is not null
         except
     select * from E
 ),
 W as (
     select id, rank() over (partition by class_record_id order by end_date desc) as rank from md.class_record_status_registry
     where id in (select id from S)
 )
update md.class_record_status_registry
set start_date = end_date
where id in (select id from W where rank = 1)
returning *;

with E as (
    select id, class_record_id from md.class_record_status_registry s1
    where s1.class_record_status_id = 5
      and end_date is not null
      and s1.class_record_id in (select s2.class_record_id from md.class_record_status_registry s2 where end_date is null)
    order by class_record_id desc
),
 S as (
     select id, class_record_id from md.class_record_status_registry s1
     where s1.class_record_status_id = 5
       and end_date is not null
         except
     select * from E
 ),
 W as (
     select id, rank() over (partition by class_record_id order by end_date desc) as rank from md.class_record_status_registry
     where id in (select id from S)
 )
update md.class_record_status_registry
set end_date = null
where id in (select id from W where rank = 1)
returning *;