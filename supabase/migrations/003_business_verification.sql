-- Business verification documents (storage + venue fields)

ALTER TABLE public.venues
  ADD COLUMN IF NOT EXISTS verification_document_path TEXT,
  ADD COLUMN IF NOT EXISTS verification_status TEXT NOT NULL DEFAULT 'none'
    CHECK (verification_status IN ('none', 'pending', 'approved', 'rejected'));

-- Storage bucket (private — owners upload, admins review later)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'business-verification',
  'business-verification',
  false,
  10485760,
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- Owners upload into their own folder: {user_id}/filename
DROP POLICY IF EXISTS "verification_upload_own" ON storage.objects;
CREATE POLICY "verification_upload_own"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'business-verification'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "verification_read_own" ON storage.objects;
CREATE POLICY "verification_read_own"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'business-verification'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "verification_update_own" ON storage.objects;
CREATE POLICY "verification_update_own"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'business-verification'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "verification_delete_own" ON storage.objects;
CREATE POLICY "verification_delete_own"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'business-verification'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
