
INSERT INTO language ("name", "culture_info") VALUES('German', 'de-DE');
INSERT INTO language ("name", "culture_info") VALUES('English', 'en-US');

insert into uiuser (uiuser_id, uiuser_username, uuid) VALUES (0,'default', 'default');

insert into config (config_key, config_value, config_user) VALUES ('DefaultLanguage', 'English', 0);
insert into config (config_key, config_value, config_user) VALUES ('sessionTimeout', '720', 0);
insert into config (config_key, config_value, config_user) VALUES ('sessionTimeoutNoticePeriod', '60', 0); -- in minutes before expiry
-- insert into config (config_key, config_value, config_user) VALUES ('maxMessages', '3', 0);
insert into config (config_key, config_value, config_user) VALUES ('elementsPerFetch', '100', 0);

insert into config (config_key, config_value, config_user) VALUES ('commentRequired', 'False', 0);
insert into config (config_key, config_value, config_user) VALUES ('messageViewTime', '7', 0);
insert into config (config_key, config_value, config_user) VALUES ('dailyCheckStartAt', '00:00:00', 0);
insert into config (config_key, config_value, config_user) VALUES ('minCollapseAllDevices', '15', 0);
insert into config (config_key, config_value, config_user) VALUES ('pwMinLength', '5', 0);
insert into config (config_key, config_value, config_user) VALUES ('pwUpperCaseRequired', 'False', 0);
insert into config (config_key, config_value, config_user) VALUES ('pwLowerCaseRequired', 'False', 0);
insert into config (config_key, config_value, config_user) VALUES ('pwNumberRequired', 'False', 0);
insert into config (config_key, config_value, config_user) VALUES ('pwSpecialCharactersRequired', 'False', 0);

INSERT INTO "report_format" ("report_format_name") VALUES ('json');
INSERT INTO "report_format" ("report_format_name") VALUES ('pdf');
INSERT INTO "report_format" ("report_format_name") VALUES ('csv');
INSERT INTO "report_format" ("report_format_name") VALUES ('html');

-- -- default report templates belong to user 0 
-- INSERT INTO "report_template" ("report_filter","report_template_name","report_template_comment","report_template_owner", "report_parameters") 
--     VALUES ('','Current Rules','T0101', 0,
--         '{"report_type":1,"device_filter":{"management":[]},
--             "time_filter": {
--                 "is_shortcut": true,
--                 "shortcut": "now",
--                 "report_time": "2022-01-01T00:00:00.0000000+01:00",
--                 "timerange_type": "SHORTCUT",
--                 "shortcut_range": "this year",
--                 "offset": 0,
--                 "interval": "DAYS",
--                 "start_time": "2022-01-01T00:00:00.0000000+01:00",
--                 "end_time": "2022-01-01T00:00:00.0000000+01:00",
--                 "open_start": false,
--                 "open_end": false}}');
