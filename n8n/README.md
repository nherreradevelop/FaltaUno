# Flujos de n8n

Acá se guardan los flujos de n8n exportados en JSON, para versionarlos en Git y compartirlos con el equipo.
La carpeta está montada en el contenedor de n8n como `/home/node/flujos` (ver `docker-compose.yml`).

## Exportar (después de modificar un flujo en tu n8n)

```bash
npm run n8n:exportar
```

Escribe un archivo `.json` por flujo en esta carpeta. Revisá los cambios con `git diff` y hacé commit.

## Importar (después de un `git pull` con flujos nuevos o modificados)

```bash
npm run n8n:importar
```

Carga en tu n8n los flujos de esta carpeta. Si un flujo ya existe (mismo id), se reemplaza.

## Reglas

- **Un responsable por flujo.** n8n no permite editar un mismo flujo entre varios a la vez, y unir dos versiones del mismo JSON a mano es muy incómodo.
- **Las credenciales no se exportan** (claves de APIs de clima, del modelo de IA, etc.). Cada integrante las crea en su n8n con el mismo nombre que usa el flujo.
- Exportá siempre antes de hacer commit, para que el JSON del repositorio coincida con lo que probaste.
