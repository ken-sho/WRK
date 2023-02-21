drop function if exists public.report_pab_8_user_statistics_weekly;
create function public.report_pab_8_user_statistics_weekly()
  returns TABLE(i_rownum integer, i_title text, i_value integer)
  security definer
  language plpgsql
as $$
declare
  p_cnt_1 integer;
  p_cnt_2 integer;
  p_cnt_3 integer;
begin
  select count(*),
         sum(
           case
             when eu.creation_date between (date_trunc('WEEK', now()) - interval '7 DAY') and
               (date_trunc('WEEK', now()) - interval '1 DAY')
               then 1
             else 0 end)
  into p_cnt_1,p_cnt_2
  from public.ent_users eu
  where eu.removal_date isnull;
  i_rownum := 1;
  i_title := 'Количество пользователей в Системе (всего на конец отчётного периода).';
  i_value := p_cnt_1;
  return next;
  i_rownum := 2;
  i_title := 'Количество пользователей, заведённых в Систему за отчётный период.';
  i_value := p_cnt_2;
  return next;
  select count(*),
         count(distinct aa.user_id)
  into p_cnt_1,p_cnt_2
  from public.ent_users eu
         join public.audit_abstract aa on eu.id = aa.user_id
  where eu.removal_date isnull
    and aa.date between (date_trunc('WEEK', now()) - interval '7 DAY') and
    (date_trunc('WEEK', now()) - interval '1 DAY')
    and aa.type = 'LOGIN';
  i_rownum := 3;
  i_title := 'Количество пользователей, заходивших в Систему в течении отчётного периода.';
  i_value := p_cnt_1;
  return next;
  i_rownum := 4;
  i_title := 'Количество сессий в отчётном периоде.';
  i_value := p_cnt_2;
  return next;
  i_rownum := 5;
  i_title := 'Количество сессий в отчётном периоде с длительностью до 30 минут (Нет данных).';
  i_value := null;
  return next;
  i_rownum := 6;
  i_title := 'Количество сессий в отчётном периоде с длительностью более 30 минут до 1 часа (Нет данных).';
  i_value := null;
  return next;
  i_rownum := 7;
  i_title := 'Количество сессий в отчётном периоде с длительностью более 1 часа до 8 часов (Нет данных).';
  i_value := null;
  return next;
  i_rownum := 8;
  i_title := 'Количество сессий в отчётном периоде с длительностью более 8 часов (Нет данных).';
  i_value := null;
  return next;
  with
    L0 as (
      select distinct
             eu.id
      from public.ent_users eu
             join public.audit_abstract aa on eu.id = aa.user_id
      where eu.removal_date isnull
        and aa.date between (date_trunc('WEEK', now()) - interval '7 DAY') and
        (date_trunc('WEEK', now()) - interval '1 DAY')
        and aa.type = 'LOGIN'
    )
  select count(*)
  into p_cnt_1
  from public.ent_users eu2
         left join L0 on eu2.id = L0.id
  where eu2.removal_date isnull
    and L0.id isnull;
  i_rownum := 9;
  i_title := 'Количество пользователей, у которых не было сессий в отчётном периоде.';
  i_value := p_cnt_1;
  return next;
  with
    L0 as (
      select eu.id,
             count(*) as cnt
      from public.ent_users eu
             join public.audit_abstract aa on eu.id = aa.user_id
      where eu.removal_date isnull
        and aa.date between (date_trunc('WEEK', now()) - interval '7 DAY') and
        (date_trunc('WEEK', now()) - interval '1 DAY')
        and aa.type = 'LOGIN'
      group by eu.id
    )
  select sum(case when L0.cnt <= 3 then 1 else 0 end),
         sum(case when L0.cnt between 3 and 6 then 1 else 0 end),
         sum(case when L0.cnt > 6 then 1 else 0 end)
  into p_cnt_1,p_cnt_2,p_cnt_3
  from L0;
  i_rownum := 10;
  i_title := 'Количество пользователей у которых в отчётном периоде была 1-3 сессии.';
  i_value := p_cnt_1;
  return next;
  i_rownum := 11;
  i_title := 'Количество пользователей у которых в отчётном периоде была 4-6 сессий.';
  i_value := p_cnt_2;
  return next;
  i_rownum := 12;
  i_title := 'Количество пользователей у которых в отчётном периоде было более 6 сессий.';
  i_value := p_cnt_3;
  return next;
end;

$$;
