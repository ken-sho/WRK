select max(h.OPDAT) from T$CC#CITY_HISTORY h
where
h.OPDAT<to_date('01.09.2019','dd/mm/yyyy')


select * from T$CC#CITY_HISTORY h
where
trunc(h.OPDAT)=to_date('29.05.2020','dd/mm/yyyy')


insert into T$CC#CITY_HISTORY (T$CC#CITY_HISTORY.ID, T$CC#CITY_HISTORY.ACC_ID, T$CC#CITY_HISTORY.SRV_ID, T$CC#CITY_HISTORY.SUMM, T$CC#CITY_HISTORY.CREDAT, T$CC#CITY_HISTORY.OPDAT, T$CC#CITY_HISTORY.REENOTE, T$CC#CITY_HISTORY.DATE_NOTE, T$CC#CITY_HISTORY.DATEB, T$CC#CITY_HISTORY.DATEE, T$CC#CITY_HISTORY.SRC, T$CC#CITY_HISTORY.REEAPX, T$CC#CITY_HISTORY.UNO, T$CC#CITY_HISTORY.REENOTE2, T$CC#CITY_HISTORY.NOTEREE, T$CC#CITY_HISTORY.CREATED_REC, T$CC#CITY_HISTORY.ACC_PU)
select
    S$CC#CITY_HISTORY_ID.nextval,
		ACC_ID, SRV_ID, SUMM, CREDAT, OPDAT, 6, DATE_NOTE, '', '', null, REEAPX, 666999666999, REENOTE2, NOTEREE, CREATED_REC, ACC_PU
from T$CC#CITY_HISTORY_OUT h;

select count(*) from T$CC#CITY_HISTORY h
where
h.UNO=666999666999;


select			*
--delete
from T$CC#CITY_HISTORY h
where
h.REENOTE=6--7
and trunc(h.DATE_NOTE,'mm')=to_date('01.09.2020','dd/mm/yyyy')
and h.REENOTE2='Платежный документ Банка Открытие "Точка"'
--and h.OPDAT=to_date('31.08.2020','dd/mm/yyyy')


--Платежный документ Банка Открытие
Платежный документ Банка Открытие "Точка"


select
*
from T$CC#CITY_HISTORY_OUT h