
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
