-- create schema
-- to re-init request module database changes, manually issue the following commands before upgrading to 5.7.1:
-- drop schema implementation CASCADE;
-- drop schema request CASCADE;
-- note: this will delete all ticket data

create schema if not exists request;
create schema if not exists implementation;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rule_field_enum') THEN
    CREATE TYPE rule_field_enum AS ENUM ('source', 'destination', 'service');
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_type_enum') THEN
    CREATE TYPE task_type_enum AS ENUM ('access', 'svc_group', 'obj_group', 'rule_modify');
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'action_enum') THEN
    CREATE TYPE request.action_enum AS ENUM ('create', 'delete', 'modifiy');
    END IF;
END
$$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'state_enum') THEN
    CREATE TYPE request.state_enum AS ENUM ('draft', 'open', 'in progress', 'closed', 'cancelled');
    END IF;
END
$$;

-- create tables
create table if not exists request.task 
(
    id SERIAL PRIMARY KEY,
    title VARCHAR,
    ticket_id int,
    task_number int,
    state request.state_enum NOT NULL,
    task_type task_type_enum NOT NULL,
    request_action request.action_enum NOT NULL,
    rule_action int,
    rule_tracking int,
    start Timestamp,
    stop Timestamp,
    svc_grp_id int,
    nw_obj_grp_id int,
    reason text
);

create table if not exists request.element 
(
    id SERIAL PRIMARY KEY,
    request_action request.action_enum NOT NULL default 'create',
    task_id int,
    ip cidr,
    port int,
    proto int,
    network_object_id bigint,
    service_id bigint,
    field rule_field_enum NOT NULL,
    user_id bigint,
    original_nat_id int
);

create table if not exists request.approval 
(
    id SERIAL PRIMARY KEY,
    task_id int,
    date_opened Timestamp NOT NULL default CURRENT_TIMESTAMP,
    approver_group Varchar,
    approval_date Timestamp,
    approver Varchar,
    tenant_id int,
    comment text
);

create table if not exists request.ticket 
(
    id SERIAL PRIMARY KEY,
    title VARCHAR NOT NULL,
    date_created Timestamp NOT NULL default CURRENT_TIMESTAMP,
    date_completed Timestamp,
    state_id request.state_enum NOT NULL,
    requester_id int,
    requester_dn Varchar,
    requester_group Varchar,
    tenant_id int,
    reason text
);

create table if not exists owner
(
    id SERIAL PRIMARY KEY,
    name Varchar NOT NULL,
    dn Varchar NOT NULL,
    group_dn Varchar NOT NULL,
    is_default boolean default false,
    tenant_id int,
    recert_interval interval
);

create unique index if not exists only_one_default_owner on owner(is_default) 
where is_default = true;

create table if not exists owner_network
(
    id SERIAL PRIMARY KEY,
    owner_id int,
    ip cidr NOT NULL,
    port int,
    ip_proto_id int
);

create table if not exists request_owner
(
    request_task_id int,
    owner_id int
);

create table if not exists rule_owner
(
    owner_id int,
    rule_metadata_id bigint
);

create table if not exists implementation.element
(
    id SERIAL PRIMARY KEY,
    implementation_action request.action_enum NOT NULL default 'create',
    implementation_task_id int,
    ip cidr,
    port int,
    ip_proto_id int,
    network_object_id bigint,
    service_id bigint,
    field rule_field_enum NOT NULL,
    user_id bigint,
    original_nat_id int
);

create table if not exists implementation.task
(
    id SERIAL PRIMARY KEY,
    request_task_id int,
    implementation_task_number int,
    implementation_state request.state_enum NOT NULL default 'open',
    device_id int,
    implementation_action request.action_enum NOT NULL,
    rule_action int,
    rule_tracking int,
    start timestamp,
    stop timestamp,
    svc_grp_id int,
    nw_obj_grp_id int
);

--- FOREIGN KEYS ---

--- Drop ---

--- request.task ---
ALTER TABLE request.task DROP CONSTRAINT IF EXISTS request_task_request_ticket_foreign_key;
ALTER TABLE request.task DROP CONSTRAINT IF EXISTS request_task_stm_action_foreign_key;
ALTER TABLE request.task DROP CONSTRAINT IF EXISTS request_task_stm_track_foreign_key;
ALTER TABLE request.task DROP CONSTRAINT IF EXISTS request_task_service_foreign_key;
ALTER TABLE request.task DROP CONSTRAINT IF EXISTS request_task_object_foreign_key;
--- request.element ---
ALTER TABLE request.element DROP CONSTRAINT IF EXISTS request_element_request_task_foreign_key;
ALTER TABLE request.element DROP CONSTRAINT IF EXISTS request_element_service_foreign_key;
ALTER TABLE request.element DROP CONSTRAINT IF EXISTS request_element_object_foreign_key;
ALTER TABLE request.element DROP CONSTRAINT IF EXISTS request_element_request_element_foreign_key;
ALTER TABLE request.element DROP CONSTRAINT IF EXISTS request_element_usr_foreign_key;
--- request.approval ---
ALTER TABLE request.approval DROP CONSTRAINT IF EXISTS request_approval_request_task_foreign_key;
ALTER TABLE request.approval DROP CONSTRAINT IF EXISTS request_approval_tenant_foreign_key;
--- request.ticket ---
ALTER TABLE request.ticket DROP CONSTRAINT IF EXISTS request_ticket_tenant_foreign_key;
ALTER TABLE request.ticket DROP CONSTRAINT IF EXISTS request_ticket_uiuser_foreign_key;
--- owner ---
ALTER TABLE owner DROP CONSTRAINT IF EXISTS owner_tenant_foreign_key;
--- owner_network ---
ALTER TABLE owner_network DROP CONSTRAINT IF EXISTS owner_network_proto_foreign_key;
ALTER TABLE owner_network DROP CONSTRAINT IF EXISTS owner_network_owner_foreign_key;
--- rule_owner ---
ALTER TABLE rule_owner DROP CONSTRAINT IF EXISTS rule_owner_rule_metadata_foreign_key;
ALTER TABLE rule_owner DROP CONSTRAINT IF EXISTS rule_owner_owner_foreign_key;
--- request_owner ---
ALTER TABLE request_owner DROP CONSTRAINT IF EXISTS request_owner_request_task_foreign_key;
ALTER TABLE request_owner DROP CONSTRAINT IF EXISTS request_owner_owner_foreign_key;
--- implemantation.element ---
ALTER TABLE implementation.element DROP CONSTRAINT IF EXISTS implementation_element_implementation_element_foreign_key;
ALTER TABLE implementation.element DROP CONSTRAINT IF EXISTS implementation_element_service_foreign_key;
ALTER TABLE implementation.element DROP CONSTRAINT IF EXISTS implementation_element_object_foreign_key;
ALTER TABLE implementation.element DROP CONSTRAINT IF EXISTS implementation_element_proto_foreign_key;
ALTER TABLE implementation.element DROP CONSTRAINT IF EXISTS implementation_element_implementation_task_foreign_key;
ALTER TABLE implementation.element DROP CONSTRAINT IF EXISTS implementation_element_usr_foreign_key;
--- implementation.task
ALTER TABLE implementation.task DROP CONSTRAINT IF EXISTS implementation_task_request_task_foreign_key;
ALTER TABLE implementation.task DROP CONSTRAINT IF EXISTS implementation_task_device_foreign_key;
ALTER TABLE implementation.task DROP CONSTRAINT IF EXISTS implementation_task_stm_action_foreign_key;
ALTER TABLE implementation.task DROP CONSTRAINT IF EXISTS implementation_task_stm_tracking_foreign_key;
ALTER TABLE implementation.task DROP CONSTRAINT IF EXISTS implementation_task_service_foreign_key;
ALTER TABLE implementation.task DROP CONSTRAINT IF EXISTS implementation_task_object_foreign_key;

--- ADD ---

--- request.task ---
ALTER TABLE request.task ADD CONSTRAINT request_task_request_ticket_foreign_key FOREIGN KEY (ticket_id) REFERENCES request.ticket(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.task ADD CONSTRAINT request_task_stm_action_foreign_key FOREIGN KEY (rule_action) REFERENCES stm_action(action_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.task ADD CONSTRAINT request_task_stm_track_foreign_key FOREIGN KEY (rule_tracking) REFERENCES stm_track(track_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.task ADD CONSTRAINT request_task_service_foreign_key FOREIGN KEY (svc_grp_id) REFERENCES service(svc_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.task ADD CONSTRAINT request_task_object_foreign_key FOREIGN KEY (nw_obj_grp_id) REFERENCES object(obj_id) ON UPDATE RESTRICT ON DELETE CASCADE;
--- request.element ---
ALTER TABLE request.element ADD CONSTRAINT request_element_request_task_foreign_key FOREIGN KEY (task_id) REFERENCES request.task(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.element ADD CONSTRAINT request_element_service_foreign_key FOREIGN KEY (service_id) REFERENCES service(svc_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.element ADD CONSTRAINT request_element_object_foreign_key FOREIGN KEY (network_object_id) REFERENCES object(obj_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.element ADD CONSTRAINT request_element_request_element_foreign_key FOREIGN KEY (original_nat_id) REFERENCES request.element(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.element ADD CONSTRAINT request_element_usr_foreign_key FOREIGN KEY (user_id) REFERENCES usr(user_id) ON UPDATE RESTRICT ON DELETE CASCADE;
--- request.approval ---
ALTER TABLE request.approval ADD CONSTRAINT request_approval_request_task_foreign_key FOREIGN KEY (task_id) REFERENCES request.task(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.approval ADD CONSTRAINT request_approval_tenant_foreign_key FOREIGN KEY (tenant_id) REFERENCES tenant(tenant_id) ON UPDATE RESTRICT ON DELETE CASCADE;
--- request.ticket ---
ALTER TABLE request.ticket ADD CONSTRAINT request_ticket_tenant_foreign_key FOREIGN KEY (tenant_id) REFERENCES tenant(tenant_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request.ticket ADD CONSTRAINT request_ticket_uiuser_foreign_key FOREIGN KEY (requester_id) REFERENCES uiuser(uiuser_id) ON UPDATE RESTRICT ON DELETE CASCADE;
--- owner ---
ALTER TABLE owner ADD CONSTRAINT owner_tenant_foreign_key FOREIGN KEY (tenant_id) REFERENCES tenant(tenant_id) ON UPDATE RESTRICT ON DELETE CASCADE;
--- owner_network ---
ALTER TABLE owner_network ADD CONSTRAINT owner_network_proto_foreign_key FOREIGN KEY (ip_proto_id) REFERENCES stm_ip_proto(ip_proto_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE owner_network ADD CONSTRAINT owner_network_owner_foreign_key FOREIGN KEY (owner_id) REFERENCES owner(id) ON UPDATE RESTRICT ON DELETE CASCADE;
--- rule_owner ---
ALTER TABLE rule_owner ADD CONSTRAINT rule_owner_rule_metadata_foreign_key FOREIGN KEY (rule_metadata_id) REFERENCES rule_metadata(rule_metadata_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE rule_owner ADD CONSTRAINT rule_owner_owner_foreign_key FOREIGN KEY (owner_id) REFERENCES owner(id) ON UPDATE RESTRICT ON DELETE CASCADE;
--- request_owner ---
ALTER TABLE request_owner ADD CONSTRAINT request_owner_request_task_foreign_key FOREIGN KEY (request_task_id) REFERENCES request.task(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE request_owner ADD CONSTRAINT request_owner_owner_foreign_key FOREIGN KEY (owner_id) REFERENCES owner(id) ON UPDATE RESTRICT ON DELETE CASCADE;
--- implemantation.element ---
ALTER TABLE implementation.element ADD CONSTRAINT implementation_element_implementation_element_foreign_key FOREIGN KEY (original_nat_id) REFERENCES implementation.element(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.element ADD CONSTRAINT implementation_element_service_foreign_key FOREIGN KEY (service_id) REFERENCES service(svc_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.element ADD CONSTRAINT implementation_element_object_foreign_key FOREIGN KEY (network_object_id) REFERENCES object(obj_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.element ADD CONSTRAINT implementation_element_proto_foreign_key FOREIGN KEY (ip_proto_id) REFERENCES stm_ip_proto(ip_proto_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.element ADD CONSTRAINT implementation_element_implementation_task_foreign_key FOREIGN KEY (implementation_task_id) REFERENCES implementation.task(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.element ADD CONSTRAINT implementation_element_usr_foreign_key FOREIGN KEY (user_id) REFERENCES usr(user_id) ON UPDATE RESTRICT ON DELETE CASCADE;
--- implementation.task
ALTER TABLE implementation.task ADD CONSTRAINT implementation_task_request_task_foreign_key FOREIGN KEY (request_task_id) REFERENCES request.task(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.task ADD CONSTRAINT implementation_task_device_foreign_key FOREIGN KEY (device_id) REFERENCES device(dev_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.task ADD CONSTRAINT implementation_task_stm_action_foreign_key FOREIGN KEY (rule_action) REFERENCES stm_action(action_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.task ADD CONSTRAINT implementation_task_stm_tracking_foreign_key FOREIGN KEY (rule_tracking) REFERENCES stm_track(track_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.task ADD CONSTRAINT implementation_task_service_foreign_key FOREIGN KEY (svc_grp_id) REFERENCES service(svc_id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE implementation.task ADD CONSTRAINT implementation_task_object_foreign_key FOREIGN KEY (nw_obj_grp_id) REFERENCES object(obj_id) ON UPDATE RESTRICT ON DELETE CASCADE;

--- OTHER CONSTRAINTS ---

--- DELETE ---

--- owner_network ---
ALTER TABLE owner_network DROP CONSTRAINT IF EXISTS port_in_valid_range;
--- request.element ---
ALTER TABLE request.element DROP CONSTRAINT IF EXISTS port_in_valid_range;
--- implementation.element ---
ALTER TABLE implementation.element DROP CONSTRAINT IF EXISTS port_in_valid_range;

--- ADD ---

--- owner_network ---
ALTER TABLE owner_network ADD CONSTRAINT port_in_valid_range CHECK (port > 0 and port <= 65535);
--- request.element ---
ALTER TABLE request.element ADD CONSTRAINT port_in_valid_range CHECK (port > 0 and port <= 65535);
--- implementation.element ---
ALTER TABLE implementation.element ADD CONSTRAINT port_in_valid_range CHECK (port > 0 and port <= 65535);


-- setting indices on view_rule_change to improve performance
-- DROP index if exists idx_changelog_rule04;
-- Create index IF NOT EXISTS idx_changelog_rule04 on changelog_rule (change_action);

-- DROP index if exists idx_changelog_rule05;
-- Create index IF NOT EXISTS idx_changelog_rule05 on changelog_rule (new_rule_id);

-- DROP index if exists idx_changelog_rule06;
-- Create index IF NOT EXISTS idx_changelog_rule06 on changelog_rule (old_rule_id);

-- DROP index if exists idx_rule04;
-- Create index IF NOT EXISTS idx_rule04 on rule (access_rule);


-- alter table report add column if not exists report_schedule_id bigint;
-- ALTER TABLE report DROP CONSTRAINT IF EXISTS "report_report_schedule_report_schedule_id_fkey" CASCADE;
-- Alter table report add CONSTRAINT report_report_schedule_report_schedule_id_fkey foreign key (report_schedule_id) references report_schedule (report_schedule_id) on update restrict on delete cascade;

insert into config (config_key, config_value, config_user) VALUES ('importCheckCertificates', 'False', 0) ON CONFLICT DO NOTHING;
insert into config (config_key, config_value, config_user) VALUES ('importSuppressCertificateWarnings', 'True', 0) ON CONFLICT DO NOTHING;
insert into config (config_key, config_value, config_user) VALUES ('sessionTimeout', '240', 0) ON CONFLICT DO NOTHING;
-- insert into config (config_key, config_value, config_user) VALUES ('maxMessages', '3', 0) ON CONFLICT DO NOTHING;
insert into config (config_key, config_value, config_user) VALUES ('sessionTimeoutNoticePeriod', '60', 0) ON CONFLICT DO NOTHING;

-- add tenant_network demo data
DO $do$ BEGIN
    IF EXISTS (SELECT tenant_id FROM tenant WHERE tenant_name='tenant1_demo') THEN
        IF NOT EXISTS (SELECT * FROM tenant_network LEFT JOIN tenant USING (tenant_id) WHERE tenant_name='tenant1_demo' and tenant_net_ip='10.222.0.32/27') THEN
            insert into tenant_network (tenant_id, tenant_net_ip, tenant_net_comment) 
            VALUES ((SELECT tenant_id FROM tenant WHERE tenant_name='tenant1_demo'), '10.222.0.32/27', 'demo network for tenant 1') ON CONFLICT DO NOTHING;
        END IF;
    END IF;
    IF EXISTS (SELECT tenant_id FROM tenant WHERE tenant_name='tenant2_demo') THEN
        IF NOT EXISTS (SELECT * FROM tenant_network LEFT JOIN tenant USING (tenant_id) WHERE tenant_name='tenant2_demo' and tenant_net_ip='10.0.0.48/29') THEN
            insert into tenant_network (tenant_id, tenant_net_ip, tenant_net_comment) 
            VALUES ((SELECT tenant_id FROM tenant WHERE tenant_name='tenant2_demo'), '10.0.0.48/29', 'demo network for tenant 2') ON CONFLICT DO NOTHING;
        END IF;
    END IF;
END $do$;

---------------------------------------------------------------------------------------
-- adding import_credential table

-- drop table if exists import_credential;

create table if not exists import_credential
(
    id SERIAL PRIMARY KEY,
    credential_name varchar NOT NULL,
    is_key_pair BOOLEAN default FALSE,
    username varchar NOT NULL,
    secret text NOT NULL,
	public_key Text
);

ALTER TABLE management ADD COLUMN IF NOT EXISTS import_credential_id int;

-- during first upgrade to 5.7.1 -- migrate credentials from management to import_credential 

DO $do$ 
DECLARE
    i_cred_number INT;
    v_cred_number_string VARCHAR;
    r_cred RECORD;
    i_cred_id INT;
BEGIN
    SELECT INTO r_cred column_name FROM information_schema.columns WHERE table_name='management' and column_name='secret';
    -- only migrate credentials if management table still contains "secret" column 
    IF FOUND THEN
        SELECT INTO i_cred_number COUNT(*) FROM import_credential;

        IF i_cred_number=0 THEN
            i_cred_number := 1;
            FOR r_cred IN SELECT DISTINCT secret, ssh_user, ssh_public_key FROM management
            LOOP
                v_cred_number_string := 'credential' || CAST (i_cred_number AS VARCHAR);
                IF NOT r_cred.secret LIKE '%BEGIN OPENSSH PRIVATE KEY%' THEN
                    INSERT INTO import_credential 
                        (credential_name, is_key_pair, username, secret) 
                        VALUES (v_cred_number_string, FALSE, r_cred.ssh_user, r_cred.secret)
                        RETURNING id INTO i_cred_id;
                    UPDATE management 
                        SET import_credential_id=i_cred_id
                        WHERE secret=r_cred.secret AND ssh_user=r_cred.ssh_user;
                ELSE
                    INSERT INTO import_credential
                        (credential_name, is_key_pair, username, secret, public_key) 
                        VALUES (v_cred_number_string, TRUE, r_cred.ssh_user, r_cred.secret, r_cred.ssh_public_key)
                        RETURNING id INTO i_cred_id;
                    UPDATE management 
                        SET import_credential_id=i_cred_id
                        WHERE secret=r_cred.secret AND ssh_user=r_cred.ssh_user; -- AND ssh_public_key=r_cred.ssh_public_key;
                END IF;
                i_cred_number := i_cred_number + 1;
            END LOOP;
        END IF;
        ALTER TABLE management DROP CONSTRAINT IF EXISTS management_import_credential_id_foreign_key;
        ALTER TABLE management ADD CONSTRAINT management_import_credential_id_foreign_key FOREIGN KEY (import_credential_id) REFERENCES import_credential(id) ON UPDATE RESTRICT ON DELETE CASCADE;
        -- and delete management columns afterwards
        -- need to remove all refs (API, etc.) first 
        ALTER TABLE management DROP COLUMN IF EXISTS ssh_public_key;
        ALTER TABLE management DROP COLUMN IF EXISTS secret;
        ALTER TABLE management DROP COLUMN IF EXISTS ssh_user;
    END IF;
END $do$;

-- Cisco Firepower Devices
insert into stm_dev_typ (dev_typ_id,dev_typ_name,dev_typ_version,dev_typ_manufacturer,dev_typ_predef_svc,dev_typ_is_multi_mgmt)
 VALUES (14,'Cisco Firepower Management Center','7ff','Cisco','',true) ON CONFLICT DO NOTHING;
insert into stm_dev_typ (dev_typ_id,dev_typ_name,dev_typ_version,dev_typ_manufacturer,dev_typ_predef_svc,dev_typ_is_multi_mgmt) 
 VALUES (15,'Cisco Firepower Domain','7ff','Cisco','',false) ON CONFLICT DO NOTHING;
insert into stm_dev_typ (dev_typ_id,dev_typ_name,dev_typ_version,dev_typ_manufacturer,dev_typ_predef_svc,dev_typ_is_multi_mgmt) 
 VALUES (16,'Cisco Firepower Gateway','7ff','Cisco','',false) ON CONFLICT DO NOTHING;
 

---------------------------------------------------------------------------------------
-- adding routing to start path analysis

-- drop table if exists gw_route;
-- drop table if exists gw_interface;

create table if not exists gw_interface
(
    id SERIAL PRIMARY KEY,
    routing_device INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    ip CIDR,
    state_up BOOLEAN DEFAULT TRUE,
    ip_version INTEGER NOT NULL DEFAULT 4,
    netmask_bits INTEGER NOT NULL
);

create table if not exists gw_route
(
    id SERIAL PRIMARY KEY,
    routing_device INT NOT NULL,
    target_gateway CIDR NOT NULL,
    destination CIDR NOT NULL,
    source CIDR,
    interface_id INT,
    interface VARCHAR,
    static BOOLEAN DEFAULT TRUE,
    metric INT,
    distance INT,
    ip_version INTEGER NOT NULL DEFAULT 4
);

ALTER TABLE gw_route DROP CONSTRAINT IF EXISTS gw_route_routing_device_foreign_key;
ALTER TABLE gw_route ADD CONSTRAINT gw_route_routing_device_foreign_key FOREIGN KEY (routing_device) REFERENCES device(dev_id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE gw_route DROP CONSTRAINT IF EXISTS gw_route_interface_foreign_key;
ALTER TABLE gw_route ADD CONSTRAINT gw_route_interface_foreign_key FOREIGN KEY (interface_id) REFERENCES gw_interface(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE gw_interface DROP CONSTRAINT IF EXISTS gw_interface_routing_device_foreign_key;
ALTER TABLE gw_interface ADD CONSTRAINT gw_interface_routing_device_foreign_key FOREIGN KEY (routing_device) REFERENCES device(dev_id) ON UPDATE RESTRICT ON DELETE CASCADE;

-- decision: we are not enforcing (at DB level) that the interface of a route belongs to the same device

CREATE OR REPLACE FUNCTION gw_interface_id_seq() RETURNS TRIGGER AS $$
BEGIN
  NEW.id = coalesce(NEW.id, nextval('gw_interface_id_seq'));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS gw_interface_id_seq ON gw_interface CASCADE;
CREATE TRIGGER gw_interface_id_seq BEFORE INSERT ON gw_interface FOR EACH ROW EXECUTE PROCEDURE gw_interface_id_seq();

CREATE OR REPLACE FUNCTION gw_route_add() RETURNS TRIGGER AS $$
BEGIN
  NEW.id = coalesce(NEW.id, nextval('gw_route_id_seq'));
  SELECT INTO NEW.interface_id id FROM gw_interface 
    WHERE gw_interface.routing_device=NEW.routing_device AND gw_interface.name=NEW.interface AND gw_interface.ip_version=NEW.ip_version;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION import_config_from_json ()
    RETURNS TRIGGER
    AS $BODY$
DECLARE
    import_id BIGINT;
    r_import_result RECORD;
    i_mgm_id INTEGER;
BEGIN
	SELECT INTO i_mgm_id mgm_id FROM import_control WHERE control_id=import_id;

	-- first delete all old interfaces belonging to the current management:
	DELETE FROM gw_interface WHERE routing_device IN 
        (SELECT dev_id FROM device LEFT JOIN management ON (device.mgm_id=management.mgm_id AND management.mgm_id=i_mgm_id));

	-- first delete all old routes belonging to the current management:
	DELETE FROM gw_route WHERE routing_device IN 
        (SELECT dev_id FROM device LEFT JOIN management ON (device.mgm_id=management.mgm_id AND management.mgm_id=i_mgm_id));

	-- now re-insert the currently found interfaces: 
    INSERT INTO gw_interface SELECT * FROM jsonb_populate_recordset(NULL::gw_interface, NEW.config -> 'interfaces');

	-- now re-insert the currently found routes: 
    INSERT INTO gw_route SELECT * FROM jsonb_populate_recordset(NULL::gw_route, NEW.config -> 'routing');

    INSERT INTO import_object
    SELECT
        *
    FROM
        jsonb_populate_recordset(NULL::import_object, NEW.config -> 'network_objects');

    INSERT INTO import_service
    SELECT
        *
    FROM
        jsonb_populate_recordset(NULL::import_service, NEW.config -> 'service_objects');

    INSERT INTO import_user
    SELECT
        *
    FROM
        jsonb_populate_recordset(NULL::import_user, NEW.config -> 'user_objects');

    INSERT INTO import_zone
    SELECT
        *
    FROM
        jsonb_populate_recordset(NULL::import_zone, NEW.config -> 'zone_objects');

    INSERT INTO import_rule
    SELECT
        *
    FROM
        jsonb_populate_recordset(NULL::import_rule, NEW.config -> 'rules');

    IF NEW.start_import_flag THEN
        -- finally start the stored procedure import
        PERFORM import_all_main(NEW.import_id, NEW.debug_mode);        
    END IF;
    RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
COST 100;
ALTER FUNCTION public.import_config_from_json () OWNER TO fworch;

DROP TRIGGER IF EXISTS import_config_insert ON import_config CASCADE;

CREATE TRIGGER import_config_insert
    BEFORE INSERT ON import_config
    FOR EACH ROW
    EXECUTE PROCEDURE import_config_from_json ();


DROP TRIGGER IF EXISTS gw_route_add ON gw_route CASCADE;
CREATE TRIGGER gw_route_add BEFORE INSERT ON gw_route FOR EACH ROW EXECUTE PROCEDURE gw_route_add();
