insert into T$CC#CITY_HISTORY (ID, ACC_ID, SRV_ID, SUMM, CREDAT, OPDAT, REENOTE, DATE_NOTE, DATEB, DATEE, SRC, REEAPX, UNO, REENOTE2, NOTEREE, CREATED_REC, ACC_PU)
select
S$CC#CITY_HISTORY_ID.nextval,
hh.ACC_ID, SRV_ID, SUMM, CREDAT, OPDAT, REENOTE, DATE_NOTE, DATEB, DATEE,
     S$CC#CITY_HISTORY_SRC.nextval,REEAPX, S$CC#CITY_HISTORY_UNO.nextval, REENOTE2, NOTEREE, CREATED_REC, ACC_PU
from T$CC#CITY_HISTORY_OUT hh;

update T$CC#CITY_HISTORY h
set h.REENOTE=-6
where
h.REENOTE=6
and trunc(h.DATE_NOTE,'mm')>=to_date('01.03.2020','dd.mm.yyyy');