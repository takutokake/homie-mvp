-- Fixed SQL functions with correct return types
-- Run this in your Supabase SQL Editor

-- Drop existing functions
DROP FUNCTION IF EXISTS get_referral_stats();
DROP FUNCTION IF EXISTS get_referral_connections();
DROP FUNCTION IF EXISTS get_top_referrers();
DROP FUNCTION IF EXISTS get_referral_chains();

-- Function to get referral stats (total users with referral codes)
CREATE OR REPLACE FUNCTION get_referral_stats()
RETURNS TABLE (
    user_id UUID,
    email VARCHAR(255),
    display_name VARCHAR(255),
    referral_code VARCHAR(255),
    referred_by_code VARCHAR(255),
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as user_id,
        p.email::VARCHAR(255),
        (p.raw_user_meta_data->>'display_name')::VARCHAR(255) as display_name,
        urc.referral_code::VARCHAR(255),
        urc.referred_by_code::VARCHAR(255),
        urc.created_at
    FROM auth.users p
    JOIN user_referral_codes urc ON urc.user_id = p.id
    ORDER BY urc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get referral connections (who used which codes)
CREATE OR REPLACE FUNCTION get_referral_connections()
RETURNS TABLE (
    new_user_email VARCHAR(255),
    code_used VARCHAR(255),
    code_type VARCHAR(255),
    signup_date TIMESTAMPTZ,
    referrer_email VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.email::VARCHAR(255) as new_user_email,
        urc.referred_by_code::VARCHAR(255) as code_used,
        CASE 
            WHEN rc.code IS NOT NULL THEN 'P0_CODE'::VARCHAR(255)
            ELSE 'USER_CODE'::VARCHAR(255)
        END as code_type,
        urc.created_at as signup_date,
        referrer.email::VARCHAR(255) as referrer_email
    FROM auth.users p
    JOIN user_referral_codes urc ON urc.user_id = p.id
    LEFT JOIN referral_codes rc ON rc.code = urc.referred_by_code
    LEFT JOIN user_referral_codes referrer_urc ON referrer_urc.referral_code = urc.referred_by_code
    LEFT JOIN auth.users referrer ON referrer.id = referrer_urc.user_id
    WHERE urc.referred_by_code IS NOT NULL
    ORDER BY urc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get top referrers (users who have referred the most people)
CREATE OR REPLACE FUNCTION get_top_referrers()
RETURNS TABLE (
    user_id UUID,
    email VARCHAR(255),
    display_name VARCHAR(255),
    referral_code VARCHAR(255),
    people_referred BIGINT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as user_id,
        p.email::VARCHAR(255),
        (p.raw_user_meta_data->>'display_name')::VARCHAR(255) as display_name,
        urc.referral_code::VARCHAR(255),
        (SELECT COUNT(*) 
         FROM user_referral_codes referred 
         WHERE referred.referred_by_code = urc.referral_code) as people_referred,
        urc.created_at
    FROM auth.users p
    JOIN user_referral_codes urc ON urc.user_id = p.id
    ORDER BY people_referred DESC, urc.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get referral chains
CREATE OR REPLACE FUNCTION get_referral_chains()
RETURNS TABLE (
    user_id UUID,
    email VARCHAR(255),
    display_name VARCHAR(255),
    referred_by_code VARCHAR(255),
    chain_level INTEGER,
    referral_chain TEXT,
    root_user_id UUID
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE chain AS (
        -- Base case: users who used P0 codes (start of chains)
        SELECT 
            p.id as user_id,
            p.email::VARCHAR(255),
            (p.raw_user_meta_data->>'display_name')::VARCHAR(255) as display_name,
            urc.referred_by_code::VARCHAR(255),
            0 as chain_level,
            COALESCE(p.raw_user_meta_data->>'display_name', p.email)::TEXT as chain_path,
            p.id as root_user_id
        FROM auth.users p
        JOIN user_referral_codes urc ON urc.user_id = p.id
        JOIN referral_codes rc ON rc.code = urc.referred_by_code
        
        UNION ALL
        
        -- Recursive case: users referred by other users
        SELECT 
            p.id as user_id,
            p.email::VARCHAR(255),
            (p.raw_user_meta_data->>'display_name')::VARCHAR(255) as display_name,
            urc.referred_by_code::VARCHAR(255),
            c.chain_level + 1 as chain_level,
            (c.chain_path || ' → ' || COALESCE(p.raw_user_meta_data->>'display_name', p.email))::TEXT as chain_path,
            c.root_user_id
        FROM auth.users p
        JOIN user_referral_codes urc ON urc.user_id = p.id
        JOIN chain c ON c.user_id IN (
            SELECT referrer_urc.user_id 
            FROM user_referral_codes referrer_urc 
            WHERE referrer_urc.referral_code = urc.referred_by_code
        )
        WHERE c.chain_level < 10  -- Prevent infinite recursion
    )
    SELECT 
        chain.user_id,
        chain.email,
        chain.display_name,
        chain.referred_by_code,
        chain.chain_level,
        chain.chain_path as referral_chain,
        chain.root_user_id
    FROM chain
    ORDER BY chain.root_user_id, chain.chain_level;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_referral_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_referral_connections() TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_referrers() TO authenticated;
GRANT EXECUTE ON FUNCTION get_referral_chains() TO authenticated;

-- Also grant to anon for dashboard access
GRANT EXECUTE ON FUNCTION get_referral_stats() TO anon;
GRANT EXECUTE ON FUNCTION get_referral_connections() TO anon;
GRANT EXECUTE ON FUNCTION get_top_referrers() TO anon;
GRANT EXECUTE ON FUNCTION get_referral_chains() TO anon;
