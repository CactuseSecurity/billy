Alter table "invoice" add CONSTRAINT invoice_company_id_fkey 
  foreign key ("company_id") references "company" ("id") on update restrict on delete cascade;
