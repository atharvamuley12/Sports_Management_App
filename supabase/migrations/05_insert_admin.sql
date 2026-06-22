-- =================================================================
-- Migration 05: Safe Admin Account Creation Script
-- =================================================================
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- This creates/re-creates the initial admin user with password 'admin123'
-- and ensures it bypasses email verification and RLS errors.

DO $$
DECLARE
  new_user_id UUID := gen_random_uuid();
  admin_email TEXT := 'admin@academy.com';
  admin_pass TEXT := 'Dhoke@11';
BEGIN
  -- 1. Clean up existing admin to allow re-running this script
  DELETE FROM public.profiles WHERE id IN (SELECT id FROM auth.users WHERE email = admin_email);
  DELETE FROM auth.users WHERE email = admin_email;

  -- 2. Create the user in Supabase Auth (pre-confirmed)
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    role,
    aud,
    confirmation_token
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    admin_email,
    crypt(admin_pass, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Academy Admin","role":"admin"}',
    now(),
    now(),
    'authenticated',
    'authenticated',
    ''
  );

  -- 3. Create the profile row with 'admin' role
  INSERT INTO public.profiles (
    id,
    full_name,
    role,
    is_active,
    must_change_password
  ) VALUES (
    new_user_id,
    'Academy Admin',
    'admin',
    true,
    false
  );
END $$;

-- 4. Clean up any NULL columns in auth.users to prevent GoTrue database schema errors
UPDATE auth.users SET confirmation_token = '' WHERE confirmation_token IS NULL;
UPDATE auth.users SET email_change = '' WHERE email_change IS NULL;
UPDATE auth.users SET email_change_token_new = '' WHERE email_change_token_new IS NULL;
UPDATE auth.users SET recovery_token = '' WHERE recovery_token IS NULL;
UPDATE auth.users SET phone_change_token = '' WHERE phone_change_token IS NULL;
UPDATE auth.users SET email_change_token_current = '' WHERE email_change_token_current IS NULL;

-- 5. Safe conditional updates for optional columns depending on Supabase version
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_sso_user') THEN
    UPDATE auth.users SET is_sso_user = false WHERE is_sso_user IS NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_anonymous') THEN
    UPDATE auth.users SET is_anonymous = false WHERE is_anonymous IS NULL;
  END IF;
END $$;
