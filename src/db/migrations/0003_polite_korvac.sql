BEGIN TRANSACTION;
CREATE TABLE `users_temp`
(
    `id`         integer PRIMARY KEY NOT NULL,
    `full_name`  text                NOT NULL,
    `phone`      text(256)           NOT NULL,
    `created_at` integer DEFAULT CURRENT_TIMESTAMP
);
insert into users_temp(id, full_name, phone)
select id, full_name, phone
from users;

drop table users;
alter table users_temp rename to users;

END TRANSACTION;