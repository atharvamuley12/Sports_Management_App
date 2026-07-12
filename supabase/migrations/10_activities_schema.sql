-- Create activities table
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coach_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'planned', -- 'planned', 'completed', 'cancelled'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Policies
-- Admins can do everything
CREATE POLICY "Admins have full access to activities" ON public.activities
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Coaches can view all activities (so they can see what others are doing, or maybe only thier own?)
-- User said "admin can track and see", implying admin sees all.
-- Usually coaches can see all planned activities to avoid clashes.
CREATE POLICY "Coaches can view all activities" ON public.activities
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'coach'
        )
    );

-- Coaches can manage their own activities
CREATE POLICY "Coaches can manage their own activities" ON public.activities
    FOR ALL USING (
        coach_id = auth.uid()
    );

-- Index for performance
CREATE INDEX IF NOT EXISTS activities_coach_id_idx ON public.activities(coach_id);
CREATE INDEX IF NOT EXISTS activities_date_idx ON public.activities(date);
