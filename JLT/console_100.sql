--insert into main.t_810_v2(date1, date2, type_op, sub_type, note1, note2, note3, accpu, accpu_note, srv_text, summ, acc_id, srv_id)
insert into main.t_history(acc_id, srv_id, summ, credat, opdat, reenote, date_note, dateb, datee, src, reeapx, uno, reenote2, noteree, created_rec, acc_pu)
with L0 as (
  select
    (jsonb_array_elements(d.adate -> 'thead')) ->> 'srv_id' as srv_id,
    d.note as doc_note,
    d.cre_date,
    d.dtype
  from main.t_documents d
  where d.id=:ree
),L1 as (
  select row_number() over () as rn,
         L0.srv_id,
         L0.doc_note,
         L0.cre_date,
         L0.dtype
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
         tdr.doc_id,
         L1.cre_date,
         L1.dtype
  from main.t_document_rec tdr
       cross join L1
  where tdr.doc_id = :ree
    and tdr.status >= 0
)select
L2.acc_id,L2.srv_id::integer,(L2.summ::numeric*-1),L2.date_op,to_date(L2.opdate,'dd.mm.yyyy'),6,
date_trunc('month',L2.cre_date)::date,
null,null,L2.id,L2.note,L2.doc_id,v.note,
to_date(L2.opdate,'dd.mm.yyyy'),L2.created_rec,p.acc_pu
from L2
     left join main.t_places p on L2.acc_id=p.acc_id
     left join main.t_services s on L2.srv_id=s.srv_id::text and s.org_id=9
     left join core.v$athoms v on L2.dtype=v.id
where
L2.summ is not null;

/*
IN ORACLE
select h.acc_id, srv_id, summ, credat, opdat, reenote, date_note, dateb, datee, src, reeapx, uno, reenote2, noteree, created_rec, h.acc_pu
from main.t_history h
    join main.t_places p on p.acc_id=h.acc_id and p.org_id=9
where
date_trunc('month', h.date_note)>='2021-12-01'
and h.reenote=6



1510;24;21;2022-07-04 05:01:45.688574;9;Банк;;26
1509;25;21;2022-07-04 05:01:45.688574;9;Приставы;;26











select
d.id, dtype, status, cre_date, org_id, note, owner_id, user_id, summ
from main.t_documents d
where d.org_id=9 --and status=23
order by id desc;

note2
банк
Кассовый платеж
приставы
перебросы

select *
from main.t_810_v2 v

order by v.id desc;


select *
from main.t_documents d where d.org_id=9
--and id in (178,179,180)
and status=23
order by id desc
id|dtype|status|cre_date|org_id|note
220|29|23|2020-05-13 10:35:53.240796|9|Перебросы
219|29|23|2020-05-13 10:35:25.588396|9|Перебросы
218|24|23|2020-05-13 10:34:27.007688|9|Банки
216|25|23|2020-05-13 05:18:34.113543|9|Судебные приставы ( Приставы


select
*
from main.t_documents d
where d.org_id=9 --and status=23
order by id desc
limit 5;

 */
