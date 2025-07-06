/*
  # Initial Schema for Customer Portal - Revised (FK Fix)

  This migration fixes a foreign key constraint error encountered during the initial schema setup.
  It revises the approach to add foreign key constraints using ALTER TABLE after table creation
  to avoid potential dependency issues where the referenced column's unique constraint
  (from the PRIMARY KEY) was not recognized during inline constraint definition.
  It also wraps RLS enabling and policy creation in idempotent blocks.

  1. New Tables (Structure remains the same, constraints added differently)
    - `users`: Stores customer and admin profiles, linked to Supabase Auth.
      - `id` (uuid, primary key, linked to auth.users)
      - `email` (text, unique, not null)
      - `role` (text, 'customer' or 'admin', default 'customer')
      - `created_at` (timestamptz, default now())
    - `orders`: Stores order details, intended to be synced with Odoo.
      - `id` (uuid, primary key, default gen_random_uuid())
      - `user_id` (uuid, foreign key to users.id, not null)
      - `odoo_order_id` (integer, unique, not null) - Link to Odoo's internal ID
      - `order_date` (timestamptz, not null)
      - `total_amount` (numeric, not null, default 0)
      - `status` (text, not null, default 'pending')
      - `created_at` (timestamptz, default now())
    - `feedback`: Stores customer feedback on orders or general.
      - `id` (uuid, primary key, default gen_random_uuid())
      - `user_id` (uuid, foreign key to users.id, not null)
      - `order_id` (uuid, foreign key to orders.id, nullable)
      - `rating` (integer, not null, check between 1 and 5)
      - `comment` (text, nullable)
      - `created_at` timestamptz, default now())
    - `rewards`: Tracks customer reward points.
      - `id` (uuid, primary key, default gen_random_uuid())
      - `user_id` (uuid, foreign key to users.id, unique, not null)
      - `points` (integer, not null, default 0)
      - `last_updated` (timestamptz, default now())
      - `odoo_crm_link` (text, nullable) - Optional link/identifier in Odoo CRM
      - `created_at` (timestamptz, default now())

  2. Security
    - Enable RLS on all new tables (`users`, `orders`, `feedback`, `rewards`).
    - Add RLS policies (same as before, wrapped in idempotent blocks).

  3. Changes
    - Foreign key constraints are now added using ALTER TABLE statements after table creation.
    - RLS enabling and policy creation are wrapped in idempotent DO blocks.
*/

-- Create tables first without foreign key constraints
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY, -- Define as PK, add FK to auth.users later
  email text UNIQUE NOT NULL,
  role text NOT NULL DEFAULT 'customer',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL, -- Add FK to users later
  odoo_order_id integer UNIQUE NOT NULL,
  order_date timestamptz NOT NULL,
  total_amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL, -- Add FK to users later
  order_id uuid, -- Add FK to orders later, nullable
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE NOT NULL, -- Add FK to users later, keep UNIQUE here
  points integer NOT NULL DEFAULT 0,
  last_updated timestamptz DEFAULT now(),
  odoo_crm_link text,
  created_at timestamptz DEFAULT now()
);

-- Add foreign key constraints using ALTER TABLE within idempotent blocks
DO $$
BEGIN
  -- Add FK from users.id to auth.users.id
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_id_fkey') THEN
    ALTER TABLE users
    ADD CONSTRAINT users_id_fkey
    FOREIGN KEY (id)
    REFERENCES auth.users(id)
    ON DELETE CASCADE;
  END IF;

  -- Add FK from orders.user_id to public.users.id
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'orders_user_id_fkey') THEN
    ALTER TABLE orders
    ADD CONSTRAINT orders_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;
  END IF;

  -- Add FK from feedback.user_id to public.users.id
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'feedback_user_id_fkey') THEN
    ALTER TABLE feedback
    ADD CONSTRAINT feedback_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;
  END IF;

  -- Add FK from feedback.order_id to public.orders.id
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'feedback_order_id_fkey') THEN
    ALTER TABLE feedback
    ADD CONSTRAINT feedback_order_id_fkey
    FOREIGN KEY (order_id)
    REFERENCES public.orders(id)
    ON DELETE SET NULL;
  END IF;

  -- Add FK from rewards.user_id to public.users.id
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'rewards_user_id_fkey') THEN
    ALTER TABLE rewards
    ADD CONSTRAINT rewards_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES public.users(id)
    ON DELETE CASCADE;
  END IF;
END $$;


-- Enable RLS within idempotent blocks
DO $$
BEGIN
  -- Check if RLS is already enabled by looking for any policy on the table
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users') THEN
    ALTER TABLE users ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'orders') THEN
    ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'feedback') THEN
    ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'rewards') THEN
    ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;


-- Create Policies within idempotent blocks
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Authenticated users can read own user profile') THEN
    CREATE POLICY "Authenticated users can read own user profile"
      ON users FOR SELECT
      TO authenticated
      USING (auth.uid() = id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'orders' AND policyname = 'Authenticated users can read their own orders') THEN
    CREATE POLICY "Authenticated users can read their own orders"
      ON orders FOR SELECT
      TO authenticated
      USING (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'feedback' AND policyname = 'Authenticated users can insert feedback') THEN
    CREATE POLICY "Authenticated users can insert feedback"
      ON feedback FOR INSERT
      TO authenticated
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'feedback' AND policyname = 'Authenticated users can read their own feedback') THEN
    CREATE POLICY "Authenticated users can read their own feedback"
      ON feedback FOR SELECT
      TO authenticated
      USING (user_id = auth.uid());
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'rewards' AND policyname = 'Authenticated users can read their own rewards') THEN
    CREATE POLICY "Authenticated users can read their own rewards"
      ON rewards FOR SELECT
      TO authenticated
      USING (user_id = auth.uid());
  END IF;
END $$;

-- Note: Admin policies would typically be handled via custom functions or roles,
-- but for simplicity here, we'll assume admin access is managed outside RLS
-- or via specific functions called by admin roles.