DO
$$
    BEGIN
        CREATE TYPE "notification_type" AS ENUM ('REMINDER', 'OTHER');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;

CREATE TABLE IF NOT EXISTS "bookings"
(
    "id"          serial PRIMARY KEY                     NOT NULL,
    "created_at"  timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at"  timestamp with time zone DEFAULT now() NOT NULL,
    "user_id"     integer                                NOT NULL,
    "start"       timestamp                              NOT NULL,
    "end"         timestamp                              NOT NULL,
    "room_id"     integer                                NOT NULL,
    "title"       text                                   NOT NULL,
    "description" text
);

CREATE TABLE IF NOT EXISTS "notification"
(
    "id"         serial PRIMARY KEY                       NOT NULL,
    "created_at" timestamp with time zone DEFAULT now()   NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now()   NOT NULL,
    "booking_id" integer                                  NOT NULL,
    "user_id"    integer                                  NOT NULL,
    "is_read"    boolean                  DEFAULT false   NOT NULL,
    "title"      text                                     NOT NULL,
    "message"    text                                     NOT NULL,
    "type"       notification_type        DEFAULT 'OTHER' NOT NULL
);

DROP TABLE IF EXISTS "posts";
DROP TABLE IF EXISTS "users";
DO
$$
    BEGIN
        ALTER TABLE "notification"
            ADD CONSTRAINT "notification_booking_id_bookings_id_fk" FOREIGN KEY ("booking_id") REFERENCES "bookings" ("id") ON DELETE cascade ON UPDATE cascade;
    EXCEPTION
        WHEN duplicate_object THEN null;
    END
$$;
