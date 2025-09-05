-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own profile
CREATE POLICY users_read_own ON users
  FOR SELECT
  USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY users_update_own ON users
  FOR UPDATE
  USING (auth.uid() = id);

-- Allow users to read other users' public profile info
CREATE POLICY users_read_public ON users
  FOR SELECT
  USING (
    "profileCompleted" = true AND
    id != auth.uid()
  );

-- Allow new user creation during signup
CREATE POLICY users_insert_self ON users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Allow the Supabase Dashboard SQL editor to access all user data
CREATE POLICY admin_all ON users
  FOR ALL
  USING (auth.role() = 'service_role');

-- Enable RLS on invites table
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;

-- Allow users to read invites they created
CREATE POLICY invites_read_own ON invites
  FOR SELECT
  USING ("createdBy" = auth.uid());

-- Allow users to create invites
CREATE POLICY invites_insert_own ON invites
  FOR INSERT
  WITH CHECK ("createdBy" = auth.uid());

-- Allow users to read invites for their school
CREATE POLICY invites_read_school ON invites
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users."schoolArea" = invites."schoolRestriction"
    )
  );

-- Allow admin access to all invites
CREATE POLICY invites_admin_all ON invites
  FOR ALL
  USING (auth.role() = 'service_role');

-- Grant necessary permissions to authenticated users
GRANT SELECT, UPDATE ON users TO authenticated;
GRANT INSERT ON users TO authenticated;
GRANT SELECT, INSERT ON invites TO authenticated;

-- Grant permissions for using the new ENUMs
GRANT USAGE ON TYPE user_interest TO authenticated;
GRANT USAGE ON TYPE user_vibe TO authenticated;
