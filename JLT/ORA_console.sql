select
			r.*
     ,SGRAD.DAY_CLOSE(to_char(r.CREATED,'dd.mm.yyyy'))
from T$PAY#REESTRS r  where r.STATUS=0  order by id desc;

select
			r.*
from T$PAY#REESTRS r order by id desc;

select
sum(rr.SUMM)
from T$PAY#RECORDS rr where rr.REEID=1272

select SGRAD.DAY_CLOSE('10.01.2020') from dual;
 --EXPLAIN PLAN set statement_id = 'demo1' for
select
			to_char(trunc(h.OPDAT,'mm'),'yyyy-mm-dd hh24:mi:ss'),
			to_char(h.OPDAT,'yyyy-mm-dd hh24:mi:ss'),
      'Расход','Оплата','Основное','Кассовый платеж','Кассовый платеж',
       h.ACC_PU,'',s.NOTE,(h.SUMM*-1),'',h.ACC_ID,h.SRV_ID
from T$CC#CITY_HISTORY h,V$CC#SERVICES s
where
h.REENOTE=7
and trunc(h.OPDAT,'mm')=to_date('01.08.2022','dd/mm/yyyy')
  --and trunc(h.OPDAT)=to_date('28.05.2020','dd/mm/yyyy')
and h.SRV_ID=s.TAG
--and h.ACC_PU='639507321'

select * from PLAN_TABLE
select * from V$SQL_PLAN
select
*
from T$CC#CITY_HISTORY h,V$CC#SERVICES s
where
h.REENOTE=7
and trunc(h.OPDAT,'mm')=to_date('01.12.2020','dd/mm/yyyy')
  --and trunc(h.OPDAT)=to_date('28.05.2020','dd/mm/yyyy')
and h.SRV_ID=s.TAG

select utl.GETD_KVADR('613324111') from dual;

select * from T$CC#PLACES p where p.GACC='613432231'

select
* from T$CC#CITY_HISTORY_CLIENT h
where
h.ACC_ID in (
97430,
104895
		)
and h.SRV_ID=25

select
			sum(h.SUMM),count(*)
from T$CC#CITY_HISTORY h
where
h.REENOTE=7
and trunc(h.DATE_NOTE,'mm')=to_date('01.02.2021','dd/mm/yyyy')


--and h.OPDAT=to_date('31.08.2020','dd/mm/yyyy')

select
			*
from T$CC#CITY_HISTORY h
where
h.REENOTE=7
and trunc(h.OPDAT,'mm')=to_date('01.01.2022','dd/mm/yyyy')
order by id



select
			max(h.DATE_NOTE)
from T$CC#CITY_HISTORY h
where
h.REENOTE=6



select
*
from T$CC#CITY_HISTORY h
where
h.REENOTE=6
--and trunc(h.DATE_NOTE)=to_date('04.06.2020','dd.mm.yyyy')
order by id desc


select
rr.*
from T$PAY#REESTRS r
		 join T$PAY#RECORDS rr on r.ID = rr.REEID
where
trunc(r.CREATED,'mm')=to_date('01.01.2021','dd/mm/yyyy')