# FaltaUno

Plataforma web y móvil para organizar actividades deportivas al aire libre y encontrar compañeros.
Proyecto final de la carrera Analista en Tecnologías de la Información (Universidad ORT Uruguay).

## Estructura

```
FaltaUno/
├── api/             API REST (Node.js + TypeScript)
├── web/             Cliente web (React)
├── mobile/          App móvil (React Native + Expo)
├── db/migrations/   Scripts SQL del esquema de PostgreSQL
├── n8n/             Flujos de n8n exportados (JSON)
├── pgadmin/         Conexión preconfigurada de pgAdmin
└── docker-compose.yml   Bases de datos y servicios de desarrollo
```

## Requisitos

- [Node.js 22](https://nodejs.org) (la versión está fijada en `.nvmrc`)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Git
- VS Code con las extensiones **ESLint** y **Prettier** (VS Code las sugiere al abrir la carpeta)

## Primera vez

```bash
# 1. Clonar e instalar las herramientas del repositorio (ESLint, Prettier, Husky)
git clone <url-del-repositorio>
cd FaltaUno
npm install

# 2. Levantar las bases de datos y servicios (Docker Desktop tiene que estar abierto)
docker compose up -d

# 3. Variables de entorno de la API (los valores de ejemplo ya apuntan a Docker)
cp api/.env.example api/.env          # en PowerShell: Copy-Item api/.env.example api/.env
```

### Crear las tablas

Con los servicios levantados, desde la raíz del repositorio (funciona igual en PowerShell):

```bash
docker cp db/migrations/001_esquema_inicial.sql faltauno-postgres:/tmp/001.sql
docker cp db/migrations/002_catalogos.sql faltauno-postgres:/tmp/002.sql
docker exec faltauno-postgres psql -U faltauno -d faltauno -v ON_ERROR_STOP=1 -f /tmp/001.sql
docker exec faltauno-postgres psql -U faltauno -d faltauno -v ON_ERROR_STOP=1 -f /tmp/002.sql
```

> Los scripts se copian al contenedor en lugar de pasarlos por la tubería de PowerShell para no romper las tildes.

## Servicios de desarrollo

| Servicio                    | Dirección                                                           | Credenciales                                         |
| --------------------------- | ------------------------------------------------------------------- | ---------------------------------------------------- |
| PostgreSQL                  | `localhost:5432`, base `faltauno`                                   | `faltauno` / `faltauno_dev`                          |
| pgAdmin                     | http://localhost:5050                                               | entra directo; contraseña de la base: `faltauno_dev` |
| MongoDB                     | `mongodb://faltauno:faltauno_dev@localhost:27017/?authSource=admin` | (en la URL)                                          |
| Redis                       | `localhost:6379`                                                    | sin contraseña                                       |
| Mailpit (correos de prueba) | http://localhost:8025                                               | —                                                    |
| n8n                         | http://localhost:5678                                               | la primera vez se crea la cuenta de dueño (local)    |

Comandos útiles:

```bash
docker compose up -d       # levantar
docker compose down        # apagar (los datos se conservan)
docker compose down -v     # apagar y BORRAR todos los datos (empezar de cero)
docker ps                  # ver qué contenedores están corriendo
```

## Variables de entorno

| Archivo                | Uso                                                         | ¿Se sube? |
| ---------------------- | ----------------------------------------------------------- | --------- |
| `api/.env.example`     | Plantilla con todas las variables                           | Sí        |
| `api/.env`             | Desarrollo local contra Docker                              | No        |
| `api/.env.integracion` | Bases compartidas en la nube (Neon, MongoDB Atlas, Upstash) | No        |

Las contraseñas de la nube se comparten por un canal privado, nunca en el repositorio.

## Calidad de código

- **Prettier** da el formato (`.prettierrc`) y **ESLint** revisa el código (`eslint.config.mjs`), con una única configuración en la raíz para `api`, `web` y `mobile`.
- **Husky** ejecuta ambos automáticamente sobre los archivos de cada commit (`lint-staged`). Si ESLint encuentra un error, el commit se cancela.
- VS Code formatea al guardar (`.vscode/settings.json`).

```bash
npm run lint           # revisar todo el repositorio
npm run lint:fix       # corregir lo que se pueda automáticamente
npm run format         # formatear todo
npm run format:check   # verificar el formato sin modificar
```

> Al crear `web` (Vite) o `mobile` (Expo), las plantillas pueden traer su propio ESLint: borren su `eslint.config.*` y quiten ESLint de su `package.json`, para que se use la configuración de la raíz.

## n8n

Los flujos se versionan en la carpeta `n8n/` (ver `n8n/README.md`):

```bash
npm run n8n:exportar   # tu n8n -> carpeta n8n/
npm run n8n:importar   # carpeta n8n/ -> tu n8n
```

## Forma de trabajo

- Cada cambio en una rama propia y entra a `main` por pull request.
- **Migraciones:** nunca modificar un script que ya se aplicó; los cambios van siempre en un archivo nuevo con el número siguiente (`003_...sql`).
- Las pruebas automáticas se ejecutan siempre contra la base local, nunca contra la compartida.
