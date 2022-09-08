select
d.id, v.note, dtype, status, cre_date, org_id, d.note, owner_id, user_id, summ
from main.t_documents d
     join core.v$athoms v on d.dtype=v.id
where
d.org_id=9
order by d.id desc

select
  h.*
  from main.t_history h
       join main.t_places p on h.acc_id=p.acc_id and p.org_id=9
  where h.reenote=7
order by id desc
  
id|dtype|status|cre_date|org_id|note|owner_id|user_id|summ
1101|24|21|2021-10-06 21:15:42.301285|9|Банк||26|0
1100|25|21|2021-10-06 21:15:42.301285|9|Приставы||26|0

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




