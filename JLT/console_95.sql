update main.t_810_v2 ---меняем знак чтобы соответствовало логике
set summ=summ*-1
where
note2='перебросы' and
date_trunc('month',date1)='01.11.2021'::date;
--date_trunc('month',date1)='01.08.2022'::date;

select
--sum(v.summ)
*
from main.t_810_v2 v where
--note2='перебросы' and
--srv_id in (10,14) and
date_trunc('month',date1)='01.05.2022'::date;

update main.t_810_v2
set note1='внешние данные'
where date_trunc('month',date1)='01.07.2022'::date;


update main.temp_810
set acc_pu=
  case when length(name)=3 then name
       when length(regexp_replace(name,'[^0-9]','','g'))=9 then regexp_replace(name,'[^0-9]','','g')
       when length(regexp_replace(substr(name,1,9),'[^0-9]','','g'))=9 then regexp_replace(substr(name,1,9),'[^0-9]','','g')
      else null end;
------------перебросы
/*
если в реестре минус то идёт возврат средст или доначисление уменьшение оплаты по итогу
плюс то списание увиличение оплаты по итогу
 */
------------не должно быть дублей!!!!
  select t.accpu, array_agg(distinct coalesce(t.accpu_note,t.accpu))
  from main.t_810_v2 t
  group by t.accpu
  having array_length(array_agg(distinct coalesce(t.accpu_note,t.accpu)),1)>1;
------------не должно быть NULL
select--639053371
      --639327061
*
from main.t_810_v2 v where v.accpu_note is null;
-----------исправление дублей
with L0 as
  (  select t.accpu
  from main.t_810_v2 t
  group by t.accpu
  having array_length(array_agg(distinct t.accpu_note),1)>1
),L1 as (
  select t.accpu,
         t.accpu_note,
         coalesce(length(t.accpu_note), 0) lngth
  from L0
         join main.t_810_v2 t on L0.accpu = t.accpu
  group by t.accpu,t.accpu_note
),L2 as (
  select L1.accpu as vaccpu,
                array_agg(L1.accpu_note order by L1.lngth desc) as vnote,
                array_agg(L1.lngth order by L1.lngth desc) as lngth
         from L1
         group by L1.accpu
)update main.t_810_v2
set accpu_note=L2.vnote[1]
from L2
where accpu=L2.vaccpu
and coalesce(length(accpu_note),0)<L2.lngth[1];
-----------
select
      case when
      (case when length(col_name)=5 then (select concat('***',h.street,', ',h.hnum,'***') from main.t_houses h where h.orgid=9 and h.adate ->> 'house_code'=col_name) else col_name end) isnull
        then 'Адрес дома неизвестен, код дома '||col_name  else
          (case when length(col_name)=5 then (select concat('***',h.street,', ',h.hnum,'***') from main.t_houses h where h.orgid=9 and h.adate ->> 'house_code'=col_name) else col_name end)
          end,
  itog_begin, dolg_in_srv_15, dolg_in_srv_31, dolg_in_srv_25, dolg_in_srv_24, dolg_in_srv_23, dolg_in_srv_14, dolg_in_srv_4, dolg_in_srv_3, dolg_in_srv_22, dolg_in_srv_21, dolg_in_srv_2, dolg_in_srv_1, dolg_in_srv_5, dolg_in_srv_33, dolg_in_srv_34, dolg_in_srv_35, dolg_in_srv_36, itogo_opl, opl_srv_15, opl_srv_31, opl_srv_25, opl_srv_24, opl_srv_23, opl_srv_14, opl_srv_4, opl_srv_3, opl_srv_22, opl_srv_21, opl_srv_2, opl_srv_1, opl_srv_5, opl_srv_33, opl_srv_34, opl_srv_35, opl_srv_36, itog_out, dolg_out_srv_15, dolg_out_srv_31, dolg_out_srv_25, dolg_out_srv_24, dolg_out_srv_23, dolg_out_srv_14, dolg_out_srv_4, dolg_out_srv_3, dolg_out_srv_22, dolg_out_srv_21, dolg_out_srv_2, dolg_out_srv_1, dolg_out_srv_5, dolg_out_srv_33, dolg_out_srv_34, dolg_out_srv_35, dolg_out_srv_36
from report.rep_810('01.08.2022','main') m;
--where col_name in ('ООО "Заполярный жилищный трест"','619','618','613','638','639');

select
      case when
      (case when length(col_name)=5 then (select concat('***',h.street,', ',h.hnum,'***') from main.t_houses h where h.orgid=9 and h.adate ->> 'house_code'=col_name) else col_name end) isnull
        then 'Адрес дома неизвестен, код дома '||col_name  else
          (case when length(col_name)=5 then (select concat('***',h.street,', ',h.hnum,'***') from main.t_houses h where h.orgid=9 and h.adate ->> 'house_code'=col_name) else col_name end)
          end,m.vsumm,m.collspan
from report.rep_837_byhs('01.07.2022','main') m;

select m.col_name,h.street,h.hnum,p.num,p.acc_pu,
  itog_begin, itogo_opl, itog_out, dolg_out_srv_22, dolg_out_srv_21, dolg_out_srv_15, dolg_out_srv_24, dolg_out_srv_14, dolg_out_srv_4, dolg_out_srv_25, dolg_out_srv_23, dolg_out_srv_3, dolg_out_srv_2, dolg_out_srv_1, dolg_out_srv_31, dolg_out_srv_5, dolg_out_srv_33, dolg_out_srv_34, dolg_out_srv_35, dolg_out_srv_36
from report.rep_810_client('01.08.2022','main') m
     left join main.t_places p on regexp_replace(m.col_name,'[^0-9]','','g')=p.acc_pu and p.org_id=9
     left join main.t_houses h on p.hid = h.houseid;

--5907


select * from report.rep_807('01.08.2022','main');
select * from report.rep_837('01.08.2022','main');
--select * from report.rep_837_byhs('01.09.2020','main');
--select * from report.rep_810('01.10.2020','612'); --where col_name = '638326101, Отсутствует';
--select * from report.rep_810_client('01.09.2020','main');
--alter table main.temp_810 rename to temp_810_0120;

/*618171171
-- */
select sum(tb.srv_1) from main.temp_bank tb where tb.optype='приставы'

select * from main.t_810_v2 t8 where date_trunc('month',t8.date1)>='01.06.2020'::date
and t8.note2='приставы'
---
select sum(summ) from main.t_810_v2_foropl f where f.srv_id=2
---
select
    *
from main.temp_bank b
     join main.t_places p on b.ls=p.acc_pu
     join main.t_services s on s.org_id=9 and s.srv_id=1
     left join main.temp_810_1219 t8 on b.ls=t8.acc_pu
where b.srv_1 is not null

select
*
from main.t_810_v2 tt
     left join main.temp_810 t on tt.accpu=tt.accpu
where
t.id isnull
and tt.note2='Кассовый платеж' and
--srv_id in (10,14) and
date_trunc('month',tt.date1)='01.09.2020'::date;



619050441
639436322

truncate table main.temp_810;
insert into main.temp_810(name, saldo, srv_22, srv_21, srv_15, srv_24, srv_14, srv_4, srv_25, srv_23, srv_3, srv_2, srv_1, srv_31, srv_5,
                          srv_33, srv_34, srv_35, srv_36, acc_pu)
select m.col_name,
   itog_out, dolg_out_srv_22, dolg_out_srv_21, dolg_out_srv_15, dolg_out_srv_24, dolg_out_srv_14, dolg_out_srv_4, dolg_out_srv_25, dolg_out_srv_23, dolg_out_srv_3,
  dolg_out_srv_2, dolg_out_srv_1, dolg_out_srv_31, dolg_out_srv_5, dolg_out_srv_33, dolg_out_srv_34, dolg_out_srv_35, dolg_out_srv_36,p.acc_pu
from report.rep_810_client('01.04.2021','main') m
     left join main.t_places p on regexp_replace(m.col_name,'[^0-9]','','g')=p.acc_pu and p.org_id=9
     left join main.t_houses h on p.hid = h.houseid
offset 2

--11816.92
--select 6829215.38-6841032.3

select
--sum(v.summ)
*
from main.t_810_v2 v where
--note2='перебросы' and
--srv_id in (1) and
accpu='639379121' and

date_trunc('month',date1)='01.02.2022'::date;