INSERT INTO public.ent_roles (id, name, displayname, resourceid, removal_date, description, attributes) VALUES (44, 'Оператор организации-поставщика программам АД', 'Оператор организации-поставщика', 1, null, 'Оператор организации-поставщика культурных, образовательных, физкультурных, оздоровительных и иных досуговых мероприятиях', '{"groups": ["view", "full_view", "create"], "participants": ["view"], "organizations": ["view"]}');
INSERT INTO public.ent_roles (id, name, displayname, resourceid, removal_date, description, attributes) VALUES (45, 'Оператор ОИВ организации-поставщика программ АД', 'Оператор ОИВ организации-поставщика', 1, null, 'Оператор ОИВ организации-поставщика культурных, образовательных, физкультурных, оздоровительных и иных досуговых мероприятиях', '{"participants": ["view"], "organizations": ["view"]}');
INSERT INTO public.ent_roles (id, name, displayname, resourceid, removal_date, description, attributes) VALUES (46, 'Оператор ОИВ ДТСЗН', 'Оператор ОИВ ДТСЗН', 1, null, 'Оператор Департамента труда и социальной защиты населения города Москвы', '{"participants": ["view", "create"], "organizations": ["view", "create"]}');
INSERT INTO public.ent_roles (id, name, displayname, resourceid, removal_date, description, attributes) VALUES (47, 'Оператор УСЗН', 'Оператор УСЗН', 1, null, 'Оператор Управления социальной защиты населения административного округа города Москвы', '{"contracts": ["view"], "organizations": ["view", "create"]}');
INSERT INTO public.ent_roles (id, name, displayname, resourceid, removal_date, description, attributes) VALUES (48, 'Оператор ЦСО', 'Оператор ЦСО', 1, null, 'Оператор территориального центра социального обслуживания населения', '{"groups": ["view", "create"], "contracts": ["view", "create", "edit"], "participants": ["view"], "organizations": ["view"]}');
INSERT INTO public.ent_roles (id, name, displayname, resourceid, removal_date, description, attributes) VALUES (49, 'Оператор ЦСО-филиал', 'Оператор ЦСО-филиал', 1, null, ' Оператор филиала территориального центра социального обслуживания населения', '{"groups": ["view", "create"], "places": ["view"], "management": ["view"], "participants": ["view", "create"], "organizations": ["view", "create"]}');



CREATE EXTENSION if not exists postgres_fdw;

CREATE server if not exists idm_server
        FOREIGN DATA WRAPPER postgres_fdw
        OPTIONS (host '<IDM SERVER HOST>', port '5432', dbname 'idm');
        
CREATE USER mapping if not exists FOR idm_user
        SERVER idm_server
        OPTIONS (user 'idm_user', password '<PASSWORD>');

CREATE USER mapping if not exists FOR postgres
        SERVER idm_server
        OPTIONS (user 'idm_user', password '<PASSWORD>');
