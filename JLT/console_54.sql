--insert into main.t_810_v2(date1, date2, type_op, sub_type, note1, note2, note3, accpu, accpu_note, srv_text, summ, acc_id, srv_id)
insert into main.t_history(acc_id, srv_id, summ, credat, opdat, reenote, date_note, dateb, datee, src, reeapx, uno, reenote2, noteree, created_rec, acc_pu)
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
  --'2020-04-01'::date,'2020-04-01'::date,'Расход','Оплата','Основное','перебросы',L2.note,p.acc_pu,p.acc_pu,s.note,
   --L2.summ::numeric,L2.acc_id,L2.srv_id::integer
---------
L2.acc_id,L2.srv_id::integer,(L2.summ::numeric*-1),L2.date_op,to_date(L2.opdate,'dd.mm.yyyy'),6,
'2020-12-01'::date,
null,null,L2.id,L2.note,L2.doc_id,a.note,
to_date(L2.opdate,'dd.mm.yyyy'),L2.created_rec,p.acc_pu
from L2
     left join main.t_places p on L2.acc_id=p.acc_id
     left join main.t_services s on L2.srv_id=s.srv_id::text and s.org_id=9
     left join main.t_documents d on L2.doc_id=d.id
     left join core.v$athoms a on d.dtype=a.id
where
L2.summ is not null;


/*
банк
перебросы

id|dtype|status|cre_date|org_id|note
616|24|21|2020-12-06 20:58:18.132420|9|Банк
615|25|21|2020-12-06 20:58:18.132420|9|Приставы
614|29|21|2020-12-06 20:58:18.132420|9|Перебросы



select *
from main.t_documents d where d.org_id=9
--and id in (178,179,180)
--and status=21
order by id desc

 */