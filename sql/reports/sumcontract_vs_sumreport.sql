drop function if exists public.sumcontract_vs_sumreport();
create or replace function public.sumcontract_vs_sumreport(dateb date, datee date)
  returns
    table (
      id                       bigint,
      contract_id              bigint,
      sum_report               numeric(20, 4),
      m                        double precision,
      report_period_start_date date,
      report_period_end_date   date,
      report_date              date,
      sum_les                  double precision,
      delta                    double precision
    )
  language plpgsql
as $$
declare

begin
--raise notice '1';
----L0
create temporary table temp_L0 on commit drop as
select cp.id                                                                             as contract_id,
       c.id                                                                              as current_id,
       r.rate_value,
       r.fix,
       extract(month from ad.lesson_date)                                                   m,
       g.id                                                                              as group_id,
       g.teachers_amount,
       a.parent_id                                                                       as activity_id,
       ad.lesson_date,
       ad.lesson_id,
       ad.start_time,
       ad.id                                                                             as ad_id,
       g.max_count,
       (extract(hour from ad.end_time - ad.start_time) +
        (extract(minute from ad.end_time - ad.start_time) - coalesce(ad.pause, 0)) / 60) as t_fact,
       (extract(hour from l.end_time - l.start_time) +
        (extract(minute from l.end_time - l.start_time) - coalesce(l.pause, 0)) / 60)    as t_lesson,
       to_timestamp(concat(ad.lesson_date, ' ', ad.start_time), 'yyyy-mm-dd HH24:MI:ss') as dt_start,
       to_timestamp(concat(ad.lesson_date, ' ', ad.end_time), 'yyyy-mm-dd HH24:MI:ss')   as dt_end
from md.contract_parent cp
       join md.contract c on cp.current_id = c.id
       join md."groups" g on g.contract_id = cp.id and g.edition_id <= c.id
       join reference.activity a on g.activity_id = a.id
       join md.attendance_data ad
            on g.id = ad.group_id and ad.attendance_data_type = 'CONFIRMED' and ad.lesson_date >= dateb and
               ad.lesson_date < datee
       join md.lesson l on l.id = ad.lesson_id and l.lesson_type in ('GENERATED', 'GROUP', 'MODIFIED')
       left join reference.rate r on a.parent_id = r.activity_id and g.teachers_amount = r.teachers_amount
    and ((r.fix and r.hours_amount = extract(hour from ad.end_time - ad.start_time) +
                                     (extract(minute from ad.end_time - ad.start_time) - coalesce(ad.pause, 0)) / 60)
      or not r.fix) and r.date_to is null;
--raise notice '2';
----L1
create temporary table temp_L1 ON COMMIT DROP as
select t.ad_id, count(*) as count
from temp_L0 t
       left join md.lesson_attendance_list lal
                 on t.ad_id = lal.attendance_data_id and lal.presence_mark and lal.participant_id is not null
group by t.ad_id;
--raise notice '3';
----temp_upp
create temporary table temp_upp ON COMMIT DROP as
select a.*,
       c."version",
       coalesce(b.count, 0)                                                                        as count,
       case when a.max_count < coalesce(b.count, 0) then a.max_count else coalesce(b.count, 0) end as p_count
from temp_L0 a
       join md.contract c on a.current_id = c.id and c.version=1
       left join temp_L1 b
                 on a.ad_id = b.ad_id;
--raise notice '4';
----temp_rp
create temporary table temp_rp ON COMMIT DROP as
select rvl.id,
       rvl.contract_id,
       rvl.summ                                           as sum_report,
       extract('month' from rvl.report_period_start_date) as m,
       rvl.report_period_start_date,
       rvl.report_period_end_date,
       ar.group_id,
       ars.lesson_id,
       ars.lesson_date,
       count(*)                                           as r_count
from md.report_volume_lessons rvl
       join md.attendance_record ar on rvl.id = ar.report_id
       join md.attendance_record_sheet ars on ar.id = ars.attendance_record_id
where ars.presence_mark = 'PRESENCE'
  and ars.lesson_date >= dateb
  and ars.lesson_date < datee
group by rvl.id, rvl.contract_id, rvl.summ, rvl.report_period_start_date, rvl.report_period_end_date, ar.group_id,
         ars.lesson_id, ars.lesson_date
order by rvl.id;
--raise notice '5';
----temp_report_period
create temporary table temp_report_period ON COMMIT DROP as
with
  L0 as (select rvl.id,
                rvl.contract_id,
                rvl.summ  as sum_report,
                extract('month' from rvl.report_period_start_date) as m,
                rvl.report_period_start_date,
                rvl.report_period_end_date,
                rvl.report_date,
                (case
                   when extract('day' from rvl.report_period_start_date) = 1 and
                        extract('day' from rvl.report_period_end_date) =
                        extract('day' from
                                (date_trunc('month', (rvl.report_period_start_date + '1 months'::interval)) -
                                 '1 day'::interval))
                     then true
                   else false end)                                 as is_full_mnts
         from md.report_volume_lessons rvl
         where rvl.report_period_start_date >= dateb
           and rvl.report_period_start_date < datee
  ),
  L1 as (select L0.contract_id,
                L0.m,
                (case
                   when false = all (array_agg(L0.is_full_mnts)) then 'several_parts'
                   when true = all (array_agg(L0.is_full_mnts)) then 'one_part'
                   else 'mix' end) as "mnt_composition"
         from L0
         group by L0.contract_id, L0.m),
  L2 as (select distinct
                L0.*,
                (case
                   when L1.mnt_composition = 'several_parts' and L0.is_full_mnts = false then 'true'
                   when L1.mnt_composition = 'one_part' and L0.is_full_mnts = true then 'true'
                   when L1.mnt_composition = 'mix' and L0.is_full_mnts = true then 'true'
                   else false end) as "visible_record"
         from L0
                join L1 on L0.contract_id = L1.contract_id),
  L3 as (select array_agg(L2.id order by L2.id desc) as arr_id,
                L2.contract_id,
                L2.sum_report,
                L2.m,
                L2.report_period_start_date,
                L2.report_period_end_date,
                L2.report_date
         from L2
         where L2.visible_record = true
         group by L2.contract_id, L2.sum_report, L2.m, L2.report_period_start_date, L2.report_period_end_date, L2.report_date)
select (L3.arr_id[1])::bigint as id,
       L3.contract_id,
       L3.sum_report,
       L3.m,
       L3.report_period_start_date,
       L3.report_period_end_date,
       L3.report_date
from L3;
--raise notice '6';
----temp_inner_sum_dif
create temporary table temp_inner_sum_dif ON COMMIT DROP as
with
  v as (select a.id,
               (case when b.fix then 1 else b.t_fact end) * b.rate_value * b.p_count   as sum_fact_les,
               (case when b.fix then 1 else b.t_lesson end) * b.rate_value * a.r_count as sum_plan_les
        from temp_rp a
               join temp_upp b
                          on a.lesson_id = b.lesson_id),
  vs as (select v.id, sum(v.sum_fact_les) sum_les
         from v
         group by v.id)
select tr.*, vs.sum_les, vs.sum_les - tr.sum_report as delta
from vs
       join temp_report_period tr
                  on tr.id = vs.id
where tr.sum_report <> vs.sum_les
order by tr.contract_id, tr.m;

  return query
    select t.id::bigint,
           t.contract_id,
           t.sum_report,
           t.m,
           t.report_period_start_date,
           t.report_period_end_date,
           t.report_date,
           t.sum_les,
           t.delta
    from temp_inner_sum_dif t;
end;
$$;