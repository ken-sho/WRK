select
  max(h.)
from main.t_places p
     join main.t_history h on p.acc_id=h.acc_id
where
p.org_id=9
and h.reenote!=7;


select t.acc_id,t.srv_id,t.summ,t.date2,t.date1,6 as reenote,t.date1,null as dateb
     ,null as datee,
  null as src,
  t.note3,666999666999 as uno,t.note2,t.date1,t.date1,t.accpu
from main.t_810_v2 t
where
--t.date1>=to_date('01.03.2020','dd.mm.yyyy') and
--t.note3!='Кассовый платеж' and
  t.accpu_note isnull



select * from main.t_810_v2 t where t.accpu='638258361'


