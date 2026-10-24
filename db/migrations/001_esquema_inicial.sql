-- FaltaUno - esquema relacional inicial (PostgreSQL)


CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Función inmutable para búsquedas sin tildes (CU30, RN1)
CREATE OR REPLACE FUNCTION f_normalizar(texto TEXT) RETURNS TEXT
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS
$$ SELECT lower(public.unaccent('public.unaccent', coalesce(texto, ''))) $$;

-- ---------------------------------------------------------------
-- Usuarios y vínculos
-- ---------------------------------------------------------------
CREATE TABLE usuario (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre                    VARCHAR(100) NOT NULL,
  email                     VARCHAR(255) NOT NULL,
  password_hash             VARCHAR(255),
  foto_url                  VARCHAR(500),   -- imagen en Cloudinary
  foto_public_id            VARCHAR(255),   -- para reemplazarla o borrarla
  biografia                 VARCHAR(500),
  proveedor_auth            VARCHAR(10)  NOT NULL DEFAULT 'local'
                              CHECK (proveedor_auth IN ('local', 'google', 'apple')),
  proveedor_id              VARCHAR(255),
  verificado                BOOLEAN      NOT NULL DEFAULT FALSE,
  admite_mensajes_no_amigos BOOLEAN      NOT NULL DEFAULT TRUE,
  intentos_fallidos         SMALLINT     NOT NULL DEFAULT 0,
  bloqueado_hasta           TIMESTAMPTZ,
  estado                    VARCHAR(10)  NOT NULL DEFAULT 'activo'
                              CHECK (estado IN ('activo', 'cierre_pendiente')),
  fecha_creacion            TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uk_usuario_email ON usuario (lower(email));
CREATE INDEX ix_usuario_nombre_norm ON usuario (f_normalizar(nombre));

CREATE TABLE token_usuario (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id        UUID         NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  tipo              VARCHAR(15)  NOT NULL CHECK (tipo IN ('verificacion', 'recuperacion')),
  token_hash        VARCHAR(255) NOT NULL UNIQUE,
  fecha_vencimiento TIMESTAMPTZ  NOT NULL,
  fecha_uso         TIMESTAMPTZ,
  fecha_creacion    TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX ix_token_usuario ON token_usuario (usuario_id, tipo);

CREATE TABLE deporte (
  id     SERIAL PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  activo BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE TABLE usuario_deporte (
  usuario_id UUID    NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  deporte_id INTEGER NOT NULL REFERENCES deporte(id),
  PRIMARY KEY (usuario_id, deporte_id)
);

CREATE TABLE sugerencia_deporte (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id     UUID REFERENCES usuario(id) ON DELETE SET NULL,
  nombre         VARCHAR(50)  NOT NULL,
  descripcion    VARCHAR(300),
  estado         VARCHAR(10)  NOT NULL DEFAULT 'pendiente'
                   CHECK (estado IN ('pendiente', 'aprobada', 'rechazada')),
  fecha_creacion TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE amistad (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  solicitante_id  UUID        NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  destinatario_id UUID        NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  estado          VARCHAR(10) NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'aceptada')),
  fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_respuesta TIMESTAMPTZ,
  CHECK (solicitante_id <> destinatario_id)
);
-- Un único vínculo por par de usuarios, sin importar el orden (CU06, RN2)
CREATE UNIQUE INDEX uk_amistad_par ON amistad (LEAST(solicitante_id, destinatario_id), GREATEST(solicitante_id, destinatario_id));
CREATE INDEX ix_amistad_destinatario ON amistad (destinatario_id);

-- ---------------------------------------------------------------
-- Actividades
-- ---------------------------------------------------------------
CREATE TABLE tipo_vehiculo (
  id               SERIAL PRIMARY KEY,
  nombre           VARCHAR(50)  NOT NULL,
  consumo_km_litro NUMERIC(5,2) NOT NULL,
  tipo_combustible VARCHAR(20)  NOT NULL
);

CREATE TABLE actividad (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizador_id             UUID REFERENCES usuario(id) ON DELETE SET NULL,
  deporte_id                 INTEGER       NOT NULL REFERENCES deporte(id),
  tipo_vehiculo_id           INTEGER REFERENCES tipo_vehiculo(id),
  nombre                     VARCHAR(100)  NOT NULL,
  descripcion                VARCHAR(1000),
  fecha_hora_inicio          TIMESTAMPTZ   NOT NULL,
  cupo_maximo                SMALLINT      NOT NULL CHECK (cupo_maximo >= 2),
  nivel                      VARCHAR(15)   NOT NULL CHECK (nivel IN ('principiante', 'intermedio', 'avanzado')),
  origen_direccion           VARCHAR(255)  NOT NULL,
  origen_lat                 NUMERIC(9,6)  NOT NULL,
  origen_lng                 NUMERIC(9,6)  NOT NULL,
  destino_direccion          VARCHAR(255)  NOT NULL,
  destino_lat                NUMERIC(9,6)  NOT NULL,
  destino_lng                NUMERIC(9,6)  NOT NULL,
  departamento               VARCHAR(30)   NOT NULL,
  organizador_tiene_vehiculo BOOLEAN       NOT NULL DEFAULT FALSE,
  lugares_vehiculo           SMALLINT CHECK (lugares_vehiculo IS NULL OR lugares_vehiculo >= 0),
  requiere_vehiculo          BOOLEAN       NOT NULL DEFAULT FALSE,
  costo_estimado             NUMERIC(12,2) CHECK (costo_estimado IS NULL OR costo_estimado >= 0),
  estado                     VARCHAR(12)   NOT NULL DEFAULT 'programada'
                               CHECK (estado IN ('programada', 'iniciada', 'archivada', 'cancelada')),
  motivo_cancelacion         VARCHAR(300),
  fecha_creacion             TIMESTAMPTZ   NOT NULL DEFAULT now(),
  fecha_cancelacion          TIMESTAMPTZ,
  fecha_archivado            TIMESTAMPTZ
);
CREATE INDEX ix_actividad_estado_fecha ON actividad (estado, fecha_hora_inicio);
CREATE INDEX ix_actividad_deporte ON actividad (deporte_id);

CREATE TABLE participacion (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actividad_id            UUID         NOT NULL REFERENCES actividad(id) ON DELETE CASCADE,
  usuario_id              UUID REFERENCES usuario(id) ON DELETE SET NULL,
  es_organizador          BOOLEAN      NOT NULL DEFAULT FALSE,
  tiene_vehiculo          BOOLEAN      NOT NULL DEFAULT FALSE,
  lugares_vehiculo        SMALLINT CHECK (lugares_vehiculo IS NULL OR lugares_vehiculo >= 0),
  punto_partida_direccion VARCHAR(255),
  punto_partida_lat       NUMERIC(9,6),
  punto_partida_lng       NUMERIC(9,6),
  silenciada              BOOLEAN      NOT NULL DEFAULT FALSE,
  fecha_union             TIMESTAMPTZ  NOT NULL DEFAULT now()
);
-- Un usuario no puede unirse dos veces (CU11, RN2)
CREATE UNIQUE INDEX uk_participacion ON participacion (actividad_id, usuario_id) WHERE usuario_id IS NOT NULL;
CREATE INDEX ix_participacion_usuario ON participacion (usuario_id);

CREATE TABLE invitado_externo (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participacion_id UUID         NOT NULL REFERENCES participacion(id) ON DELETE CASCADE,
  nombre           VARCHAR(100) NOT NULL
);
CREATE INDEX ix_invitado_participacion ON invitado_externo (participacion_id);

CREATE TABLE invitacion (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actividad_id    UUID        NOT NULL REFERENCES actividad(id) ON DELETE CASCADE,
  remitente_id    UUID        NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  invitado_id     UUID        NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  estado          VARCHAR(12) NOT NULL DEFAULT 'pendiente'
                    CHECK (estado IN ('pendiente', 'aceptada', 'rechazada', 'vencida', 'invalidada')),
  fecha_envio     TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_respuesta TIMESTAMPTZ
);
-- Una sola invitación pendiente por usuario y actividad (CU17, RN2)
CREATE UNIQUE INDEX uk_invitacion_pendiente ON invitacion (actividad_id, invitado_id) WHERE estado = 'pendiente';
CREATE INDEX ix_invitacion_invitado ON invitacion (invitado_id, estado);

CREATE TABLE valoracion (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actividad_id UUID        NOT NULL REFERENCES actividad(id) ON DELETE CASCADE,
  evaluador_id UUID REFERENCES usuario(id) ON DELETE SET NULL,
  evaluado_id  UUID        NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
  puntaje      SMALLINT    NOT NULL CHECK (puntaje BETWEEN 1 AND 5),
  comentario   VARCHAR(500),
  fecha        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (evaluador_id IS NULL OR evaluador_id <> evaluado_id)
);
-- Una nueva valoración reemplaza la anterior (CU21, RN2)
CREATE UNIQUE INDEX uk_valoracion ON valoracion (actividad_id, evaluador_id, evaluado_id) WHERE evaluador_id IS NOT NULL;
CREATE INDEX ix_valoracion_evaluado ON valoracion (evaluado_id);

CREATE TABLE informe_pronostico (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actividad_id              UUID UNIQUE REFERENCES actividad(id) ON DELETE CASCADE,
  zona                      VARCHAR(50) NOT NULL,
  fecha                     DATE        NOT NULL,
  nivel_recomendado         VARCHAR(15) CHECK (nivel_recomendado IS NULL OR nivel_recomendado IN ('principiante', 'intermedio', 'avanzado')),
  resumen                   TEXT        NOT NULL,
  datos_ambientales         JSONB       NOT NULL,
  interpretacion_disponible BOOLEAN     NOT NULL DEFAULT TRUE,
  fecha_generacion          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------
-- Gastos, pagos y balances
-- ---------------------------------------------------------------
CREATE TABLE gasto (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actividad_id      UUID          NOT NULL REFERENCES actividad(id) ON DELETE CASCADE,
  registrado_por_id UUID          NOT NULL REFERENCES participacion(id),
  pagado_por_id     UUID          NOT NULL REFERENCES participacion(id),
  concepto          VARCHAR(150)  NOT NULL,
  monto             NUMERIC(12,2) NOT NULL CHECK (monto > 0),
  version           INTEGER       NOT NULL DEFAULT 1,
  fecha_registro    TIMESTAMPTZ   NOT NULL DEFAULT now(),
  fecha_eliminacion TIMESTAMPTZ
);
CREATE INDEX ix_gasto_actividad ON gasto (actividad_id) WHERE fecha_eliminacion IS NULL;

CREATE TABLE parte_gasto (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gasto_id            UUID          NOT NULL REFERENCES gasto(id) ON DELETE CASCADE,
  participacion_id    UUID          NOT NULL REFERENCES participacion(id),
  invitado_externo_id UUID REFERENCES invitado_externo(id) ON DELETE SET NULL,
  monto               NUMERIC(12,2) NOT NULL CHECK (monto >= 0)
);
CREATE INDEX ix_parte_gasto ON parte_gasto (gasto_id);

CREATE TABLE pago (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actividad_id      UUID          NOT NULL REFERENCES actividad(id) ON DELETE CASCADE,
  pagador_id        UUID          NOT NULL REFERENCES participacion(id),
  receptor_id       UUID          NOT NULL REFERENCES participacion(id),
  registrado_por_id UUID          NOT NULL REFERENCES participacion(id),
  monto             NUMERIC(12,2) NOT NULL CHECK (monto > 0),
  version           INTEGER       NOT NULL DEFAULT 1,
  fecha_registro    TIMESTAMPTZ   NOT NULL DEFAULT now(),
  fecha_eliminacion TIMESTAMPTZ,
  CHECK (pagador_id <> receptor_id)
);
CREATE INDEX ix_pago_actividad ON pago (actividad_id) WHERE fecha_eliminacion IS NULL;

CREATE TABLE balance (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actividad_id        UUID          NOT NULL REFERENCES actividad(id) ON DELETE CASCADE,
  deudor_id           UUID          NOT NULL REFERENCES participacion(id),
  acreedor_id         UUID          NOT NULL REFERENCES participacion(id),
  monto               NUMERIC(12,2) NOT NULL CHECK (monto > 0),
  fecha_actualizacion TIMESTAMPTZ   NOT NULL DEFAULT now(),
  UNIQUE (actividad_id, deudor_id, acreedor_id),
  CHECK (deudor_id <> acreedor_id)
);
