-- DRAFT ONLY: review with university IT/administration before running.
-- Designed to keep ballot choice separate from student identity.

CREATE TABLE elections (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'open', 'closed', 'published')),
  opens_at TIMESTAMPTZ,
  closes_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (closes_at IS NULL OR opens_at IS NULL OR closes_at > opens_at)
);

CREATE TABLE candidates (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  election_id BIGINT NOT NULL REFERENCES elections(id) ON DELETE RESTRICT,
  display_name TEXT NOT NULL,
  manifesto TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (id, election_id)
);

-- Identity/eligibility is separate from ballots. auth_user_id should be a verified
-- university-approved identity provider subject, not a user-entered roll number.
CREATE TABLE voter_eligibility (
  election_id BIGINT NOT NULL REFERENCES elections(id) ON DELETE RESTRICT,
  auth_user_id UUID NOT NULL,
  eligible BOOLEAN NOT NULL DEFAULT TRUE,
  has_voted BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (election_id, auth_user_id)
);

-- Intentionally has no student/auth user identifier, to reduce ballot linkage.
CREATE TABLE votes (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  election_id BIGINT NOT NULL REFERENCES elections(id) ON DELETE RESTRICT,
  candidate_id BIGINT NOT NULL,
  cast_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  FOREIGN KEY (candidate_id, election_id) REFERENCES candidates(id, election_id) ON DELETE RESTRICT
);

CREATE TABLE admin_users (
  auth_user_id UUID PRIMARY KEY,
  role TEXT NOT NULL CHECK (role IN ('election_admin', 'auditor', 'read_only')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor_auth_user_id UUID,
  action TEXT NOT NULL,
  election_id BIGINT REFERENCES elections(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX votes_election_idx ON votes(election_id);
CREATE INDEX candidates_election_active_idx ON candidates(election_id, active);

-- Do not expose direct table writes to browser clients. In a later step we will add
-- a reviewed transaction/RPC or server-side transaction that atomically marks
-- eligibility as voted and inserts a ballot, then restrict DB grants accordingly.
-- Do not use this draft for a real election until permissions, backups, audit policy,
-- identity verification, accessibility, and security testing are reviewed.
