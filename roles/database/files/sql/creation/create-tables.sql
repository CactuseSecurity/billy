
Create table "invoice"
(
	"id" SERIAL,
	"company_id" Integer NOT NULL,
	"is_invoice" BOOLEAN,
	"number" Varchar,
 primary key ("id")
);

Create table "company"
(
	"id" SERIAL,
	"name" VARCHAR NOT NULL,
	"payment_plan" INTEGER NOT NULL DEFAULT 30,	-- days allowed for payment
 primary key ("id")
);



-- uiuser - change metadata -------------------------------------

Create table "uiuser"
(
	"uiuser_id" SERIAL NOT NULL,
	"uiuser_username" Varchar,
	"uuid" Varchar NOT NULL UNIQUE,
	"uiuser_first_name" Varchar,
	"uiuser_last_name" Varchar,
	"uiuser_start_date" Date Default now(),
	"uiuser_end_date" Date,
	"uiuser_email" Varchar,
	"tenant_id" Integer,
	"uiuser_language" Varchar,
	"uiuser_password_must_be_changed" Boolean NOT NULL Default TRUE,
	"uiuser_last_login" Timestamp with time zone,
	"uiuser_last_password_change" Timestamp with time zone,
	"uiuser_pwd_history" Text,
	"ldap_connection_id" BIGINT,
 primary key ("uiuser_id")
);

-- text tables ----------------------------------------

Create table "language"
(
	"name" Varchar NOT NULL UNIQUE,
	"culture_info" Varchar NOT NULL,
	primary key ("name")
);

Create table "txt"
(
	"id" Varchar NOT NULL,
	"language" Varchar NOT NULL,
	"txt" Varchar NOT NULL,
 primary key ("id", "language")
);

-- configuration

Create table "ldap_connection"
(
	"ldap_connection_id" BIGSERIAL,
	"ldap_server" Varchar NOT NULL,
	"ldap_port" Integer NOT NULL Default 636,
	"ldap_tls" Boolean NOT NULL Default TRUE,
	"ldap_searchpath_for_users" Varchar NOT NULL,
	"ldap_searchpath_for_roles" Varchar,
	"ldap_tenant_level" Integer NOT NULL Default 1,
	"ldap_search_user" Varchar NOT NULL,
	"ldap_search_user_pwd" Varchar NOT NULL,
	"ldap_write_user" Varchar,
	"tenant_id" Integer,
	"ldap_write_user_pwd" Varchar,
	"ldap_searchpath_for_groups" Varchar,
	"ldap_type" Integer NOT NULL Default 0,
	"ldap_pattern_length" Integer NOT NULL Default 0,
	"ldap_name" Varchar,
	"ldap_global_tenant_name" Varchar,
	"active" Boolean NOT NULL Default TRUE,
	primary key ("ldap_connection_id")
);

Create table "config"
(
	"config_key" VARCHAR NOT NULL,
	"config_value" VARCHAR,
	"config_user" Integer,
	primary key ("config_key","config_user")
);

-- tenant -------------------------------------
Create table "tenant"
(
	"tenant_id" SERIAL,
	"tenant_name" Varchar NOT NULL UNIQUE,
	"tenant_projekt" Varchar,
	"tenant_comment" Text,
	"tenant_report" Boolean Default true,
	"tenant_can_view_all_devices" Boolean NOT NULL Default false,
	"tenant_is_superadmin" Boolean NOT NULL default false,	
	"tenant_create" Timestamp NOT NULL Default now(),
 primary key ("tenant_id")
);

Create table "report_format"
(
	"report_format_name" varchar not null,
 	primary key ("report_format_name")
);

Create table "report_schedule_format"
(
	"report_schedule_format_name" VARCHAR not null,
	"report_schedule_id" BIGSERIAL,
 	primary key ("report_schedule_format_name","report_schedule_id")
);

Create table "report"
(
	"report_id" BIGSERIAL,
	"report_template_id" Integer,
	"report_start_time" Timestamp,
	"report_end_time" Timestamp,
	"report_json" json NOT NULL,
	"report_pdf" text,
	"report_csv" text,
	"report_html" text,
	"report_name" varchar NOT NULL,
	"report_owner_id" Integer NOT NULL, --FK to uiuser
	"tenant_wide_visible" Integer,
	"report_type" Integer,
	"description" varchar,
 	primary key ("report_id")
);

Create table "report_schedule"
(
	"report_schedule_id" BIGSERIAL,
	"report_schedule_name" Varchar, --  NOT NULL Default "Report_"|"report_id"::VARCHAR,  -- user given name of a report
	"report_template_id" Integer, --FK
	"report_schedule_owner" Integer NOT NULL, --FK
	"report_schedule_start_time" Timestamp NOT NULL,  -- if day is bigger than 28, simply use the 1st of the next month, 00:00 am
	"report_schedule_repeat" Integer Not NULL Default 0, -- 0 do not repeat, 1 daily, 2 weekly, 3 monthly, 4 yearly 
	"report_schedule_every" Integer Not NULL Default 1, -- x - every x days/weeks/months/years
	"report_schedule_active" Boolean Default TRUE,
	"report_schedule_repetitions" Integer,
	"report_schedule_counter" Integer Not NULL Default 0,
 	primary key ("report_schedule_id")
);

Create table "report_template_viewable_by_user"
(
	"report_template_id" Integer NOT NULL,
	"uiuser_id" Integer NOT NULL,
 	primary key ("uiuser_id","report_template_id")
);