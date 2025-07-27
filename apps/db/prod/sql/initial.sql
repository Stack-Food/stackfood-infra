CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;
CREATE TABLE customer (
    "Id" uuid NOT NULL,
    "Name" character varying(100) NOT NULL,
    "Email" character varying(100) NOT NULL,
    "Cpf" character varying(14) NOT NULL,
    CONSTRAINT "PK_customer" PRIMARY KEY ("Id")
);

CREATE TABLE products (
    "Id" uuid NOT NULL,
    "Name" character varying(100) NOT NULL,
    "Description" character varying(255) NOT NULL,
    "Price" numeric(10,2) NOT NULL,
    "ImageUrl" character varying(255) NOT NULL,
    "Category" text NOT NULL,
    CONSTRAINT "PK_products" PRIMARY KEY ("Id")
);

CREATE TABLE orders (
    "Id" uuid NOT NULL,
    "CustomerId" uuid,
    "Status" text NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "PreparationStartedAt" timestamp with time zone,
    CONSTRAINT "PK_orders" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_orders_customer_CustomerId" FOREIGN KEY ("CustomerId") REFERENCES customer ("Id") ON DELETE SET NULL
);

CREATE TABLE payments (
    "Id" uuid NOT NULL,
    "PaymentExternalId" bigint NOT NULL,
    "QrCodeUrl" character varying(2000) NOT NULL,
    "Status" text NOT NULL,
    "PaymentDate" timestamp with time zone NOT NULL,
    "Type" text NOT NULL,
    "OrderId" uuid NOT NULL,
    CONSTRAINT "PK_payments" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_payments_orders_OrderId" FOREIGN KEY ("OrderId") REFERENCES orders ("Id") ON DELETE CASCADE
);

CREATE TABLE product_orders (
    "Id" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "Name" character varying(100) NOT NULL,
    "Description" character varying(255) NOT NULL,
    "ImageUrl" character varying(255) NOT NULL,
    "Category" text NOT NULL,
    "Quantity" integer NOT NULL,
    "UnitPrice" numeric(10,2) NOT NULL,
    "OrderId" uuid NOT NULL,
    CONSTRAINT "PK_product_orders" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_product_orders_orders_OrderId" FOREIGN KEY ("OrderId") REFERENCES orders ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_customer_Cpf" ON customer ("Cpf");

CREATE INDEX "IX_orders_CustomerId" ON orders ("CustomerId");

CREATE UNIQUE INDEX "IX_payments_OrderId" ON payments ("OrderId");

CREATE INDEX "IX_product_orders_OrderId" ON product_orders ("OrderId");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20250531141657_inicial', '9.0.4');

COMMIT;
