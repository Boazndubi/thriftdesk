-- ============================================================
-- ThriftDesk Database Schema
-- ============================================================

-- Create auth schema (for user accounts)
CREATE SCHEMA IF NOT EXISTS auth;

-- Create users table (sellers will have accounts)
CREATE TABLE auth.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  encrypted_password text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- SELLERS (shop owners)
-- ============================================================
CREATE TABLE public.sellers (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  shop_name   text NOT NULL,
  slug        text NOT NULL UNIQUE,
  bio         text,
  phone       text NOT NULL,
  avatar_url  text,
  banner_url  text,
  location    text,
  plan        text NOT NULL DEFAULT 'free'
                CHECK (plan IN ('free','starter','pro','business')),
  plan_expires_at timestamptz,
  is_active   boolean NOT NULL DEFAULT true,
  tiktok_url  text,
  instagram_url text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- PRODUCTS (clothes/items for sale)
-- ============================================================
CREATE TABLE public.products (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id    uuid REFERENCES public.sellers(id) ON DELETE CASCADE NOT NULL,
  title        text NOT NULL,
  description  text,
  price        integer NOT NULL,
  original_price integer,
  category     text NOT NULL
                CHECK (category IN (
                  'tops','bottoms','dresses','outerwear','shoes',
                  'bags','accessories','kids','bedding','other'
                )),
  condition    text NOT NULL DEFAULT 'good'
                CHECK (condition IN ('new_with_tags','excellent','good','fair')),
  size         jsonb,
  colors       text[] NOT NULL DEFAULT '{}',
  photos       text[] NOT NULL DEFAULT '{}',
  stock_qty    integer NOT NULL DEFAULT 1,
  is_available boolean NOT NULL DEFAULT true,
  views        integer NOT NULL DEFAULT 0,
  is_featured  boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- ORDERS (buyer orders)
-- ============================================================
CREATE TABLE public.orders (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id       uuid REFERENCES public.sellers(id) ON DELETE CASCADE NOT NULL,
  buyer_name      text NOT NULL,
  buyer_phone     text NOT NULL,
  buyer_location  text,
  items           jsonb NOT NULL,
  subtotal        integer NOT NULL,
  delivery_fee    integer NOT NULL DEFAULT 0,
  total           integer NOT NULL,
  status          text NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','confirmed','paid','dispatched','delivered','cancelled')),
  notes           text,
  delivery_method text NOT NULL DEFAULT 'pickup'
                  CHECK (delivery_method IN ('pickup','delivery')),
  whatsapp_sent   boolean NOT NULL DEFAULT false,
  sms_sent        boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- PAYMENTS (M-Pesa transactions)
-- ============================================================
CREATE TABLE public.payments (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          uuid REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  seller_id         uuid REFERENCES public.sellers(id) NOT NULL,
  amount            integer NOT NULL,
  method            text NOT NULL DEFAULT 'mpesa'
                    CHECK (method IN ('mpesa','cash')),
  status            text NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','processing','completed','failed')),
  mpesa_checkout_id text,
  mpesa_receipt     text,
  mpesa_phone       text,
  platform_fee      integer NOT NULL DEFAULT 0,
  settled_at        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- INDEXES (makes searches faster)
-- ============================================================
CREATE INDEX idx_products_seller_available ON public.products (seller_id, is_available);
CREATE INDEX idx_products_seller_category ON public.products (seller_id, category);
CREATE INDEX idx_orders_seller_status ON public.orders (seller_id, status);
CREATE INDEX idx_orders_seller_created ON public.orders (seller_id, created_at DESC);
CREATE INDEX idx_payments_order ON public.payments (order_id);
CREATE INDEX idx_sellers_slug ON public.sellers (slug);

-- ============================================================
-- AUTO-UPDATE TIMESTAMPS
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER sellers_updated_at
  BEFORE UPDATE ON public.sellers
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
