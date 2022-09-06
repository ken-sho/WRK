CREATE OR REPLACE FUNCTION idb.validate_activity_profile(var_session_id varchar) RETURNS VOID
AS
$body$
DECLARE
    i_query varchar;
    val_row record;
BEGIN
    -- IDB.PARTICIPANT_ACTIVITY_PROFILE

    -- FOREIGN_KEY_CONSTRAINT
    -- ACTIVITY_ID
    i_query := 'select pap.id, pap.activity_id from idb.participant_activity_profile pap where pap.activity_id in (' ||
               'select ram.id from idb.ref_activity_map ram left join idb.ref_activity ra on (ram.id = ra.id) where ra.id is null)';
    FOR val_row in EXECUTE i_query
    LOOP
            insert into idb.fallout_report(session_id, rule_id, table_name, column_name, record_id, value)
            values (var_session_id::uuid,
                    2, -- foreign key
                    'participant_activity_profile',
                    'activity_id',
                    val_row.id,
                    val_row.activity_id::text);
            delete from idb.participant_activity_profile where id = val_row.id;
    END LOOP;
    -- IDB.PARTICIPANT_ACTIVITY_PROFILE_PREFERRED_DAYTIME

    -- IDB.PARTICIPANT_ACTIVITY_PROFILE_WEEKDAY
END
$body$
LANGUAGE plpgsql;

DO $$ BEGIN
    PERFORM idb.validate_activity_profile('3ea27ecb-fbe7-3a91-72a9-d610680f76df');
END $$;