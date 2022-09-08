#DataSourceSettings#
#LocalDataSource: ClearOs
#BEGIN#
<data-source source="LOCAL" name="ClearOs" group="MyProject" uuid="812a5ce5-2c04-418f-b1ac-6f5002f17072"><database-info product="PostgreSQL" version="10.19" jdbc-version="4.2" driver-name="PostgreSQL JDBC Driver" driver-version="42.2.22" dbms="POSTGRES" exact-version="10.19" exact-driver-version="42.2"><identifier-quote-string>&quot;</identifier-quote-string></database-info><case-sensitivity plain-identifiers="lower" quoted-identifiers="exact"/><driver-ref>postgresql</driver-ref><synchronize>true</synchronize><jdbc-driver>org.postgresql.Driver</jdbc-driver><jdbc-url>jdbc:postgresql://localhost:5429/postgres</jdbc-url><secret-storage>master_key</secret-storage><user-name>developer</user-name><schema-mapping><introspection-scope><node negative="1"><node kind="database" qname="redmine"><node kind="schema" negative="1"/></node><node kind="database" qname="web_receivables"><node kind="schema"><name qname="access"/><name qname="admin"/><name qname="core"/><name qname="loader"/><name qname="log"/><name qname="main"/><name qname="public"/><name qname="report"/><name qname="saldo"/><name qname="secondary"/><name qname="utl"/><name qname="filter"/></node></node></node></introspection-scope></schema-mapping></data-source>
#END#

#LocalDataSource: ENT.FTC
#BEGIN#
<data-source source="LOCAL" name="ENT.FTC" group="MyProject" uuid="60f6a9c3-3b54-4e05-b870-c2eb63c53865"><database-info product="Oracle" version="Oracle Database 10g Enterprise Edition Release 10.2.0.4.0 - 64bit Production&#xa;With the Partitioning, OLAP, Data Mining and Real Application Testing options" jdbc-version="4.2" driver-name="Oracle JDBC driver" driver-version="12.2.0.1.0" dbms="ORACLE" exact-version="10.2.0.4.0" exact-driver-version="12.2"><extra-name-characters>$#</extra-name-characters><identifier-quote-string>&quot;</identifier-quote-string></database-info><case-sensitivity plain-identifiers="upper" quoted-identifiers="exact"/><driver-ref>oracle</driver-ref><synchronize>true</synchronize><auto-commit>false</auto-commit><jdbc-driver>oracle.jdbc.OracleDriver</jdbc-driver><jdbc-url>jdbc:oracle:thin:@192.168.1.101:1521:pkn</jdbc-url><secret-storage>master_key</secret-storage><user-name>kp</user-name><schema-mapping><introspection-scope><node kind="schema" qname="KP"/></introspection-scope></schema-mapping><introspection-level>3</introspection-level></data-source>
#END#

#LocalDataSource: JLT.FTC
#BEGIN#
<data-source source="LOCAL" name="JLT.FTC" group="MyProject" uuid="f9782c93-fe84-4eef-8a50-3bf6688bebdb"><database-info product="Oracle" version="Oracle Database 10g Enterprise Edition Release 10.2.0.4.0 - 64bit Production&#xa;With the Partitioning, OLAP, Data Mining and Real Application Testing options" jdbc-version="11.2" driver-name="Oracle JDBC driver" driver-version="11.2.0.3.0" dbms="ORACLE" exact-version="10.2.0.4.0" exact-driver-version="11.2"><extra-name-characters>$#</extra-name-characters><identifier-quote-string>&quot;</identifier-quote-string></database-info><case-sensitivity plain-identifiers="upper" quoted-identifiers="exact"/><driver-ref>oracle</driver-ref><synchronize>true</synchronize><auto-commit>false</auto-commit><jdbc-driver>oracle.jdbc.OracleDriver</jdbc-driver><jdbc-url>jdbc:oracle:thin:@95.129.150.146:60011:pkn</jdbc-url><secret-storage>master_key</secret-storage><user-name>kp</user-name><schema-mapping><introspection-scope><node kind="schema" qname="KP"/></introspection-scope></schema-mapping><introspection-level>3</introspection-level></data-source>
#END#

#LocalDataSource: OGK.FTC
#BEGIN#
<data-source source="LOCAL" name="OGK.FTC" group="MyProject" uuid="561dcc60-ad8e-452c-acc8-383a7b31d46f"><database-info product="Oracle" version="Oracle Database 10g Enterprise Edition Release 10.2.0.4.0 - 64bit Production&#xa;With the Partitioning, OLAP, Data Mining and Real Application Testing options" jdbc-version="4.2" driver-name="Oracle JDBC driver" driver-version="12.2.0.1.0" dbms="ORACLE" exact-version="10.2.0.4.0" exact-driver-version="12.2"><extra-name-characters>$#</extra-name-characters><identifier-quote-string>&quot;</identifier-quote-string></database-info><case-sensitivity plain-identifiers="upper" quoted-identifiers="exact"/><driver-ref>oracle</driver-ref><synchronize>true</synchronize><auto-commit>false</auto-commit><jdbc-driver>oracle.jdbc.OracleDriver</jdbc-driver><jdbc-url>jdbc:oracle:thin:@95.129.150.146:60010:pkn</jdbc-url><secret-storage>master_key</secret-storage><user-name>kp</user-name><schema-mapping><introspection-scope><node kind="schema" qname="KP"/></introspection-scope></schema-mapping><introspection-level>3</introspection-level></data-source>
#END#

#LocalDataSource: RGSTAT
#BEGIN#
<data-source source="LOCAL" name="RGSTAT" group="MyProject" uuid="6130ed41-300d-40be-a1e4-4634fed529a0"><database-info product="PostgreSQL" version="10.12" jdbc-version="4.2" driver-name="PostgreSQL JDBC Driver" driver-version="42.2.22" dbms="POSTGRES" exact-version="10.12" exact-driver-version="42.2"><identifier-quote-string>&quot;</identifier-quote-string></database-info><case-sensitivity plain-identifiers="lower" quoted-identifiers="exact"/><driver-ref>postgresql</driver-ref><synchronize>true</synchronize><jdbc-driver>org.postgresql.Driver</jdbc-driver><jdbc-url>jdbc:postgresql://localhost:5418/postgres</jdbc-url><secret-storage>master_key</secret-storage><user-name>kp30</user-name><schema-mapping><introspection-scope><node kind="database" qname="web_station"><node kind="schema" negative="1"/></node></introspection-scope></schema-mapping></data-source>
#END#

#LocalDataSource: WEB_DEB
#BEGIN#
<data-source source="LOCAL" name="WEB_DEB" group="MyProject" uuid="b75777a0-187e-4343-af22-eb832e1f9e6c"><database-info product="PostgreSQL" version="10.12" jdbc-version="4.2" driver-name="PostgreSQL JDBC Driver" driver-version="42.3.3" dbms="POSTGRES" exact-version="10.12" exact-driver-version="42.3"><identifier-quote-string>&quot;</identifier-quote-string></database-info><case-sensitivity plain-identifiers="lower" quoted-identifiers="exact"/><driver-ref>postgresql</driver-ref><synchronize>true</synchronize><jdbc-driver>org.postgresql.Driver</jdbc-driver><jdbc-url>jdbc:postgresql://localhost:5420/postgres</jdbc-url><secret-storage>master_key</secret-storage><user-name>kp30</user-name><schema-mapping><introspection-scope><node kind="database"><name qname="redmine"/><name qname="web_receivables"/><node kind="schema" negative="1"/></node></introspection-scope></schema-mapping></data-source>
#END#


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
and trunc(h.OPDAT,'mm')=to_date('01.07.2022','dd/mm/yyyy')
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




























insert into main.t_810_v2(date1, date2, type_op, sub_type, note1, note2, note3, accpu, accpu_note, srv_text, summ, acc_id, srv_id)
--insert into main.t_history(acc_id, srv_id, summ, credat, opdat, reenote, date_note, dateb, datee, src, reeapx, uno, reenote2, noteree, created_rec, acc_pu)
with L0 as (
  select
    (jsonb_array_elements(d.adate -> 'thead')) ->> 'srv_id' as srv_id,
    d.note as doc_note
  from main.t_documents d
  where d.id=:ree
),L1 as (
  select row_number() over () as rn,
         L0.srv_id,
         L0.doc_note
  from L0
    where L0.srv_id is not null
),L2 as (
  select tdr.acc_id,
         tdr.date_op,
         tdr.note,
         tdr.json_adate ->> 'doc_date' as opdate,
         tdr.json_adate ->> 'num_doc'  as num_doc,
         tdr.ar_adate[L1.rn] as summ,
         L1.srv_id,
         tdr.created as created_rec,
         tdr.id,
         L1.doc_note,
         tdr.doc_id
  from main.t_document_rec tdr
       cross join L1
  where tdr.doc_id = :ree
    and tdr.status >= 0
)select
  '2022-07-01'::date,'2022-07-01'::date,'Расход','Оплата','Основное','банк',L2.note,p.acc_pu,p.acc_pu,s.note,
   (L2.summ::numeric),L2.acc_id,L2.srv_id::integer
---------
--L2.acc_id,L2.srv_id::integer,(L2.summ::numeric*-1),L2.date_op,to_date(L2.opdate,'dd.mm.yyyy'),6,
--'2020-04-01'::date,
--null,null,L2.id,L2.note,L2.doc_id,'Оплата Банк',
--to_date(L2.opdate,'dd.mm.yyyy'),L2.created_rec,p.acc_pu
---------
from L2
     left join main.t_places p on L2.acc_id=p.acc_id
     left join main.t_services s on L2.srv_id=s.srv_id::text and s.org_id=9
where
L2.summ is not null;



/*
1510;24;21;2022-07-04 05:01:45.688574;9;Банк;;26;0
1509;25;21;2022-07-04 05:01:45.688574;9;Приставы;;26;0






Возврат

note2
банк 374
Кассовый платеж
приставы 369
перебросы 405

select *
from main.t_810_v2 v

order by v.id desc;


select d.id, dtype, status, cre_date, org_id, note, owner_id, user_id, summ
from main.t_documents d where d.org_id=9
--and id in (178,179,180)
--and status=21
order by id desc

id|dtype|status|cre_date|org_id|note
405|29|23|2020-06-18 10:25:53.062344|9|перебросы
374|24|23|2020-06-04 11:42:55.597690|9|ИЛ БАНК
369|25|23|2020-06-04 07:35:42.419759|9|Судебные приставы

select *
from main.t_documents d where d.org_id=9
and d.id>=614
order by id desc

 */

