/*
  pg-ledger: A ledger-like accounting app for PostgreSQL
  Copyright (C) 2018  Tobias Bengtsson

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

CREATE TABLE internal.account_tag (
  tag_key VARCHAR(50) NOT NULL CHECK (LENGTH(tag_key) > 0),
  tag_value TEXT,
  account_id uuid NOT NULL REFERENCES internal.account ON DELETE CASCADE,
  PRIMARY KEY (tag_key, account_id)
);

COMMENT ON TABLE internal.account_tag IS
'Stores key-value tags for accounts. Each account can have zero or one tag keys,
containing a nullable value. It is up to the user of the system to decide what
the tags mean, and consideration should also be taken to the querying
possibilities offered based on tags.';

CREATE VIEW public.account_tag AS
  SELECT at.tag_key, at.tag_value, amv.full_name AS account_name
  FROM internal.account_tag at
  JOIN internal.account_materialized_view amv
  ON at.account_id = amv.id;

COMMENT ON VIEW public.account_tag IS
'Shows key-value tags for accounts. Each account can have zero or one tag keys,
containing a nullable value. It is up to the user of the system to decide what
the tags mean, and consideration should also be taken to the querying
possibilities offered based on tags.';

CREATE FUNCTION public.tag_account (
  IN account_name TEXT,
  IN tag_key VARCHAR(50),
  IN tag_value TEXT)
  RETURNS void
  LANGUAGE 'sql'
AS $$
  INSERT INTO internal.account_tag ("tag_key", "tag_value", "account_id")
  VALUES (tag_key, tag_value, internal.get_account_id(account_name));
$$;

COMMENT ON FUNCTION public.tag_account IS
'Tags an account with the specified key and value.';

CREATE VIEW public.account_tag_balance AS
  SELECT at.tag_key, at.tag_value, SUM(ab.balance), ab.commodity
  FROM public.account_tag at
  JOIN public.account_balance ab
  ON at.account_name = ab.account_name
  GROUP BY at.tag_key, at.tag_value, ab.commodity;

COMMENT ON VIEW public.account_tag_balance IS
'Shows balance per tag key/value combination, also grouped by commodity.';

INSERT INTO internal.migrations (id) VALUES (15);
