-- =================================================================
-- Migration 04: Repair auth.users NULL values
-- =================================================================
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- This fixes the 'unexpected_failure: Database error querying schema' 
-- caused by manual SQL inserts into auth.users that left fields as NULL.

-- 1. Update text fields to empty strings instead of NULL where required by GoTrue
UPDATE auth.users SET confirmation_token = '' WHERE confirmation_token IS NULL;
UPDATE auth.users SET email_change = '' WHERE email_change IS NULL;
UPDATE auth.users SET email_change_token_new = '' WHERE email_change_token_new IS NULL;
UPDATE auth.users SET recovery_token = '' WHERE recovery_token IS NULL;
UPDATE auth.users SET phone_change_token = '' WHERE phone_change_token IS NULL;
UPDATE auth.users SET email_change_token_current = '' WHERE email_change_token_current IS NULL;

-- 2. Update is_sso_user safely (only if column exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_sso_user'
  ) THEN
    UPDATE auth.users SET is_sso_user = false WHERE is_sso_user IS NULL;
  END IF;
END $$;

-- 3. Update is_anonymous safely (only if column exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'is_anonymous'
  ) THEN
    UPDATE auth.users SET is_anonymous = false WHERE is_anonymous IS NULL;
  END IF;
END $$;
