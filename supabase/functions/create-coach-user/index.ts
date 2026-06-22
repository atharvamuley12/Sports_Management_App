import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

    // Get the authorization header from the caller
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header provided' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get user from the JWT token
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token)
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid user token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Check if the caller is an active admin
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('role, is_active')
      .eq('id', user.id)
      .single()

    if (profileError || !profile || profile.role !== 'admin' || !profile.is_active) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: Caller is not an active admin' }),
        { status: 403, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Parse the request body
    const { name, phone, email, password } = await req.json()
    if (!name || !email || !password) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: name, email, password' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Create the user in auth.users
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: name, phone },
    })

    if (createError || !newUser.user) {
      return new Response(
        JSON.stringify({ error: createError?.message || 'Failed to create user' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Insert into profiles
    const { error: insertProfileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: newUser.user.id,
        full_name: name,
        phone,
        role: 'coach',
        is_active: true,
        must_change_password: true
      })

    if (insertProfileError) {
      // Clean up the created auth user if profile creation fails
      await supabaseAdmin.auth.admin.deleteUser(newUser.user.id)
      return new Response(
        JSON.stringify({ error: insertProfileError.message || 'Failed to create profile' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ user: newUser.user }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
