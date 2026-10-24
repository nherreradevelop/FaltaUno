-- Catálogo de deportes (RNF-07) y tipos de vehículo (reservado para CU22)
INSERT INTO deporte (nombre) VALUES
  ('Surf'), ('Trekking'), ('Ciclismo'), ('Básquetbol'), ('Vóley playa'), ('Fútbol'), ('Running')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO tipo_vehiculo (nombre, consumo_km_litro, tipo_combustible) VALUES
  ('Auto chico', 15.00, 'nafta'),
  ('Auto mediano', 12.00, 'nafta'),
  ('Camioneta', 9.00, 'nafta');
