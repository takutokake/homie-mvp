-- Drop existing policies
DROP POLICY IF EXISTS users_read_own ON users;
DROP POLICY IF EXISTS users_update_own ON users;
DROP POLICY IF EXISTS users_read_public ON users;
DROP POLICY IF EXISTS users_insert_self ON users;
DROP POLICY IF EXISTS admin_all ON users;
DROP POLICY IF EXISTS invites_read_own ON invites;
DROP POLICY IF EXISTS invites_insert_own ON invites;
DROP POLICY IF EXISTS invites_read_school ON invites;
DROP POLICY IF EXISTS invites_admin_all ON invites;

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;

-- User policies
CREATE POLICY users_read_own ON users
  FOR SELECT
  USING (auth.uid()::uuid = id);

CREATE POLICY users_update_own ON users
  FOR UPDATE
  USING (auth.uid()::uuid = id);

CREATE POLICY users_read_public ON users
  FOR SELECT
  USING (
    profile_completed = true AND
    id != auth.uid()::uuid
  );

CREATE POLICY users_insert_self ON users
  FOR INSERT
  WITH CHECK (auth.uid()::uuid = id);

CREATE POLICY admin_all ON users
  FOR ALL
  USING (auth.role() = 'service_role');

-- Invite policies
CREATE POLICY invites_read_own ON invites
  FOR SELECT
  USING ("createdBy" = auth.uid()::uuid);

CREATE POLICY invites_insert_own ON invites
  FOR INSERT
  WITH CHECK ("createdBy" = auth.uid()::uuid);

CREATE POLICY invites_read_school ON invites
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()::uuid
      AND users.school = invites.school_restriction
    )
  );

CREATE POLICY invites_admin_all ON invites
  FOR ALL
  USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT, UPDATE ON users TO authenticated;
GRANT INSERT ON users TO authenticated;
GRANT SELECT, INSERT ON invites TO authenticated;
GRANT USAGE ON TYPE user_interest TO authenticated;
GRANT USAGE ON TYPE user_vibe TO authenticated;
