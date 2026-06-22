-- =================================================================
-- Migration 06: Create Coach User RPC Function
-- =================================================================
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- This allows Admins to create new Coach accounts securely from the App UI
-- without needing to deploy a Deno Edge Function.

CREATE OR REPLACE FUNCTION public.create_coach_user(
  coach_email TEXT,
  coach_password TEXT,
  coach_name TEXT,
  coach_phone TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_user_id UUID := gen_random_uuid();
BEGIN
  -- 1. Check if the caller is an active admin
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin' AND is_active
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Only active admins can create coach accounts.';
  END IF;

  -- 2. Check if email already exists in auth.users
  IF EXISTS (
    SELECT 1 FROM auth.users WHERE email = coach_email
  ) THEN
    RAISE EXCEPTION 'Email already registered.';
  END IF;

  -- 3. Insert into auth.users (with empty-string fallbacks for schema columns to prevent database schema errors)
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
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token,
    phone_change_token,
    email_change_token_current
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    coach_email,
    crypt(coach_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', coach_name, 'phone', coach_phone, 'role', 'coach'),
    now(),
    now(),
    'authenticated',
    'authenticated',
    '',
    '',
    '',
    '',
    '',
    ''
  );

  -- 4. Check if profile exists (might be auto-created by handle_new_user trigger), else create it
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = new_user_id) THEN
    INSERT INTO public.profiles (
      id,
      full_name,
      phone,
      role,
      is_active,
      must_change_password
    ) VALUES (
      new_user_id,
      coach_name,
      coach_phone,
      'coach',
      true,
      true
    );
  ELSE
    -- If it was inserted by the trigger, update must_change_password to true for admin-created coach
    UPDATE public.profiles
    SET must_change_password = true
    WHERE id = new_user_id;
  END IF;

  RETURN new_user_id;
END;
$$;
