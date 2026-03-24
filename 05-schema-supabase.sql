-- ============================================================================
-- SCHEMA: ERPI - ERP Inteligente Multi-Industria
-- Base de Datos PostgreSQL en Supabase
-- ============================================================================

-- Habilitar extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TABLA: usuarios
-- ============================================================================

CREATE TABLE usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  nombre_completo VARCHAR(255) NOT NULL,
  empresa_id UUID,
  
  activo BOOLEAN DEFAULT true,
  ultimo_acceso TIMESTAMP,
  
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_email (email),
  INDEX idx_empresa (empresa_id),
  INDEX idx_activo (activo)
);

-- ============================================================================
-- TABLA: empresas (Multi-tenant)
-- ============================================================================

CREATE TABLE empresas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  razon_social VARCHAR(255) NOT NULL,
  rfc VARCHAR(13) UNIQUE NOT NULL,
  nombre_comercial VARCHAR(255),
  
  giro VARCHAR(100) NOT NULL,
  regimen VARCHAR(50) NOT NULL,
  
  email VARCHAR(255),
  telefono VARCHAR(20),
  
  activa BOOLEAN DEFAULT true,
  plan_id VARCHAR(50),
  fecha_suscripcion DATE,
  
  creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  actualizada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_rfc (rfc),
  INDEX idx_giro (giro),
  INDEX idx_activa (activa)
);

-- ============================================================================
-- TABLA: contactos (Clientes, Proveedores, Pacientes)
-- ============================================================================

CREATE TABLE contactos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  
  tipo VARCHAR(50) NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  telefono VARCHAR(20),
  
  rfc VARCHAR(13),
  razon_social VARCHAR(255),
  uso_cfdi VARCHAR(50),
  
  activo BOOLEAN DEFAULT true,
  
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_empresa_tipo (empresa_id, tipo),
  INDEX idx_rfc (rfc)
);

-- ============================================================================
-- TABLA: productos
-- ============================================================================

CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  
  codigo VARCHAR(50) NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  tipo VARCHAR(50),
  
  precio_compra NUMERIC(12, 2),
  precio_venta NUMERIC(12, 2),
  
  stock INTEGER DEFAULT 0,
  unidad VARCHAR(50),
  
  activo BOOLEAN DEFAULT true,
  
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_empresa_codigo (empresa_id, codigo),
  INDEX idx_tipo (tipo)
);

-- ============================================================================
-- TABLA: ventas
-- ============================================================================

CREATE TABLE ventas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  
  numero_factura VARCHAR(50) UNIQUE,
  cliente_id UUID REFERENCES contactos(id),
  
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  subtotal NUMERIC(12, 2),
  iva NUMERIC(12, 2),
  total NUMERIC(12, 2),
  
  forma_pago VARCHAR(50),
  estado VARCHAR(50),
  
  cfdi_id UUID,
  poliza_id UUID,
  
  creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_empresa_fecha (empresa_id, fecha),
  INDEX idx_cliente (cliente_id),
  INDEX idx_estado (estado)
);

-- ============================================================================
-- TABLA: compras
-- ============================================================================

CREATE TABLE compras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  
  numero_orden VARCHAR(50) UNIQUE,
  proveedor_id UUID REFERENCES contactos(id),
  
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  subtotal NUMERIC(12, 2),
  iva NUMERIC(12, 2),
  total NUMERIC(12, 2),
  
  estado VARCHAR(50),
  
  creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_empresa (empresa_id),
  INDEX idx_proveedor (proveedor_id)
);

-- ============================================================================
-- TABLA: cuentas_sat (Catálogo de cuentas contables)
-- ============================================================================

CREATE TABLE cuentas_sat (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  
  codigo VARCHAR(20) UNIQUE NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  tipo VARCHAR(50),
  naturaleza VARCHAR(50),
  
  saldo_normal VARCHAR(50),
  
  activa BOOLEAN DEFAULT true,
  
  creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_empresa_codigo (empresa_id, codigo),
  INDEX idx_tipo (tipo)
);

-- ============================================================================
-- TABLA: polizas (Asientos contables)
-- ============================================================================

CREATE TABLE polizas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  
  numero INTEGER NOT NULL,
  tipo VARCHAR(50),
  
  fecha DATE NOT NULL,
  descripcion TEXT,
  referencia VARCHAR(255),
  
  asientos JSONB NOT NULL,
  
  total_debe NUMERIC(15, 2),
  total_haber NUMERIC(15, 2),
  balanceada BOOLEAN,
  
  estado VARCHAR(50),
  
  creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_empresa_fecha (empresa_id, fecha),
  INDEX idx_numero (numero)
);

-- ============================================================================
-- TABLA: cfdi (Comprobante Fiscal Digital)
-- ============================================================================

CREATE TABLE cfdi (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  
  uuid VARCHAR(36) UNIQUE,
  serie VARCHAR(10),
  folio INTEGER,
  
  fecha TIMESTAMP,
  
  emisor_rfc VARCHAR(13),
  receptor_rfc VARCHAR(13),
  
  conceptos JSONB NOT NULL,
  
  subtotal NUMERIC(12, 2),
  total_impuestos NUMERIC(12, 2),
  total NUMERIC(12, 2),
  
  estado VARCHAR(50),
  xml_content TEXT,
  
  creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_empresa (empresa_id),
  INDEX idx_uuid (uuid),
  INDEX idx_estado (estado)
);

-- ============================================================================
-- TABLA: audit_logs (Auditoría)
-- ============================================================================

CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  
  usuario_id UUID REFERENCES usuarios(id),
  
  entidad VARCHAR(100),
  entidad_id UUID,
  
  accion VARCHAR(50),
  
  datos_anteriores JSONB,
  datos_nuevos JSONB,
  
  ip_address INET,
  user_agent TEXT,
  
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_empresa_entidad (empresa_id, entidad),
  INDEX idx_usuario (usuario_id),
  INDEX idx_fecha (creado_en)
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - Seguridad
-- ============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE contactos ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE compras ENABLE ROW LEVEL SECURITY;
ALTER TABLE polizas ENABLE ROW LEVEL SECURITY;
ALTER TABLE cfdi ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Política: Usuarios solo ven su propia empresa
CREATE POLICY usuarios_isolate_empresa ON usuarios
  USING (empresa_id = current_setting('app.current_empresa_id')::uuid)
  WITH CHECK (empresa_id = current_setting('app.current_empresa_id')::uuid);

-- Política: Contactos solo de la empresa
CREATE POLICY contactos_isolate_empresa ON contactos
  USING (empresa_id = current_setting('app.current_empresa_id')::uuid)
  WITH CHECK (empresa_id = current_setting('app.current_empresa_id')::uuid);

-- Política: Ventas solo de la empresa
CREATE POLICY ventas_isolate_empresa ON ventas
  USING (empresa_id = current_setting('app.current_empresa_id')::uuid)
  WITH CHECK (empresa_id = current_setting('app.current_empresa_id')::uuid);

-- [Continuar con más políticas...]

-- ============================================================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================================================

CREATE INDEX idx_ventas_fecha ON ventas(empresa_id, fecha DESC);
CREATE INDEX idx_polizas_numero ON polizas(empresa_id, numero DESC);
CREATE INDEX idx_cfdi_estado ON cfdi(empresa_id, estado);
CREATE INDEX idx_audit_creado ON audit_logs(empresa_id, creado_en DESC);

-- ============================================================================
-- DATOS DE PRUEBA
-- ============================================================================

-- Insertar usuario demo
INSERT INTO usuarios (email, password_hash, nombre_completo)
VALUES (
  'demo@erpi.cloud',
  crypt('Demo2026*', gen_salt('bf')),
  'Usuario Demo'
);

-- Insertar empresa demo (restaurante)
INSERT INTO empresas (razon_social, rfc, nombre_comercial, giro, regimen)
VALUES (
  'Restaurante Demo S.A. de C.V.',
  'DEMO000000XXX',
  'El Buen Comer',
  'restaurante',
  'RESICO'
);

-- Insertar cuentas SAT básicas
INSERT INTO cuentas_sat (codigo, nombre, tipo, naturaleza, saldo_normal)
VALUES
  ('1010001', 'Bancos', 'activo', 'deudora', 'deudor'),
  ('4010001', 'Ventas', 'ingresos', 'acreedora', 'acreedor'),
  ('2010100', 'IVA por Pagar', 'pasivo', 'acreedora', 'acreedor'),
  ('5010001', 'Costo de Ventas', 'costo', 'deudora', 'deudor');

-- ============================================================================
-- FIN SCHEMA
-- ============================================================================
