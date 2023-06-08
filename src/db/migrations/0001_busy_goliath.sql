CREATE SEQUENCE posts_id AS integer START 1 OWNED BY posts.id;
CREATE SEQUENCE users_id AS integer START 1 OWNED BY users.id;

ALTER TABLE posts ALTER COLUMN id SET DEFAULT nextval('posts_id');

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id');
