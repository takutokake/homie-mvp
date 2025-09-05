-- Drop existing policies to recreate them
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

-- User policies with correct column names
CREATE POLICY users_read_own ON users
  FOR SELECT
  USING (auth.uid()::text = id);

CREATE POLICY users_update_own ON users
  FOR UPDATE
  USING (auth.uid()::text = id);

CREATE POLICY users_read_public ON users
  FOR SELECT
  USING (
    profile_completed = true AND
    id != auth.uid()::text
  );

CREATE POLICY users_insert_self ON users
  FOR INSERT
  WITH CHECK (auth.uid()::text = id);

CREATE POLICY admin_all ON users
  FOR ALL
  USING (auth.role() = 'service_role');

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Invite policies with correct column names
CREATE POLICY invites_read_own ON invites
  FOR SELECT
  USING (created_by = auth.uid()::text);

CREATE POLICY invites_insert_own ON invites
  FOR INSERT
  WITH CHECK (created_by = auth.uid()::text);

CREATE POLICY invites_read_school ON invites
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()::text
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
