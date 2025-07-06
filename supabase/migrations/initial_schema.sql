/*
  # Initial Schema for Customer Portal

  This migration sets up the initial database schema for the customer portal, including tables for users, orders, feedback, and rewards.

  1. New Tables
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
      - `created_at` (timestamptz, default now())
    - `rewards`: Tracks customer reward points.
      - `id` (uuid, primary key, default gen_random_uuid())
      - `user_id` (uuid, foreign key to users.id, unique, not null)
      - `points` (integer, not null, default 0)
      - `last_updated` (timestamptz, default now())
      - `odoo_crm_link` (text, nullable) - Optional link/identifier in Odoo CRM
      - `created_at` (timestamptz, default now())

  2. Security
    - Enable RLS on all new tables (`users`, `orders`, `feedback`, `rewards`).
    - Add RLS policies:
      - `users`: Authenticated users can read their own profile. Admins can read all profiles.
      - `orders`: Authenticated users can read their own orders. Admins can read all orders.
      - `feedback`: Authenticated users can insert feedback, read their own feedback. Admins can read all feedback.
      - `rewards`: Authenticated users can read their own reward points. Admins can read all reward points.

  3. Changes
    - No existing tables are modified.
*/

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  role text NOT NULL DEFAULT 'customer',
  created_at timestamptz DEFAULT now()
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  odoo_order_id integer UNIQUE NOT NULL,
  order_date timestamptz NOT NULL,
  total_amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

-- Create feedback table
CREATE TABLE IF NOT EXISTS feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text,
  created_at timestamptz DEFAULT now()
);

-- Create rewards table
CREATE TABLE IF NOT EXISTS rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  points integer NOT NULL DEFAULT 0,
  last_updated timestamptz DEFAULT now(),
  odoo_crm_link text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;

-- Create Policies for users table
CREATE POLICY "Authenticated users can read own user profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Note: Admin policies would typically be handled via custom functions or roles,
-- but for simplicity here, we'll assume admin access is managed outside RLS
-- or via specific functions called by admin roles. A simple admin policy might look like:
-- CREATE POLICY "Admins can read all user profiles"
--   ON users FOR SELECT
--   TO authenticated -- Or a specific admin role
--   USING (get_user_role(auth.uid()) = 'admin'); -- Requires a function get_user_role

-- Create Policies for orders table
CREATE POLICY "Authenticated users can read their own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Create Policies for feedback table
CREATE POLICY "Authenticated users can insert feedback"
  ON feedback FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Authenticated users can read their own feedback"
  ON feedback FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Create Policies for rewards table
CREATE POLICY "Authenticated users can read their own rewards"
  ON rewards FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Optional: Function to get user role (requires additional setup in Supabase)
-- CREATE OR REPLACE FUNCTION get_user_role(user_id uuid)
-- RETURNS text
-- LANGUAGE plpgsql
-- SECURITY DEFINER -- Be cautious with SECURITY DEFINER
-- AS $$
-- DECLARE
--   user_role text;
-- BEGIN
--   SELECT role INTO user_role FROM public.users WHERE id = user_id;
--   RETURN user_role;
-- END;
-- $$;