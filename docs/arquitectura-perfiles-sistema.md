# Arquitectura por perfiles

## Resumen

El proyecto ya no se organiza alrededor de carpetas duplicadas por sistema operativo en la raíz. La arquitectura actual separa claramente:

- **backend compartido** en `src/`
- **instalación compartida** en `common/scripts/`
- **configuración declarativa** en `common/env/`
- **selección funcional por perfil** en `SISTEMA-BAJO`, `SISTEMA-MEDIO` y `SISTEMA-ALTO`

## Principios

1. Un solo backend para todos los perfiles.
2. Los perfiles deben cambiar por configuración, no por copiar código.
3. Cada sistema operativo reutiliza la misma lógica de instalación y arranque.
4. Los launchers de usuario deben ser simples.
5. La latencia es prioritaria, pero sin degradar innecesariamente la calidad.

## Estructura objetivo aplicada

```text
rag-chatbot/
├── SISTEMA-BAJO/
├── SISTEMA-MEDIO/
├── SISTEMA-ALTO/
├── common/
│   ├── env/
│   │   ├── base.env
│   │   ├── profiles/
│   │   └── os/
│   ├── manifests/
│   ├── requirements/
│   └── scripts/
├── scripts/
│   └── reindex_helper.py
├── src/
├── tests/
└── docs/
```

## Capas de configuración

Cada instalación genera `.env` uniendo:

1. `common/env/base.env`
2. `common/env/profiles/<perfil>.env`
3. `common/env/os/<sistema>.env`

Esto permite cambiar:

- modelo de chat
- provider de embeddings
- chunking
- thresholds de recuperación
- concurrencia
- rutas del sistema

sin tocar `src/`.

## Requirements

La instalación Python se divide así:

- `requirements.txt`: runtime base común
- `requirements-dev.txt`: runtime + tests
- `common/requirements/profile-low.txt`
- `common/requirements/profile-medium.txt`
- `common/requirements/profile-high.txt`

El perfil alto añade `docling` mediante `common/requirements/profile-high.txt`.

## Perfiles aplicados

| Perfil | Chat | Embeddings | Enfoque |
|--------|------|------------|---------|
| Bajo | `qwen3:1.7b` | MiniLM multilingüe | CPU ligera |
| Medio | `qwen3:4b` | MiniLM multilingüe | equilibrio |
| Alto | `qwen3:8b` | `qwen3-embedding:4b` | calidad + hardware alto |

## Mejoras introducidas en la refactorización

- Se eliminaron los wrappers redundantes `scripts-linux/` y `scripts-mac/` del raíz.
- Los launchers raíz siguen existiendo solo como acceso rápido al perfil medio.
- Los scripts de arranque ya no ejecutan `pip install` en cada inicio.
- Los instaladores preparan también el modelo de embeddings cuando el provider es `ollama`.
- La API `/chat` devuelve `sources` y `confidence`, alineada con la documentación.
- El frontend muestra fuentes, confianza y latencia de la respuesta.

## Lógica compartida por SO

### Windows

- `common/scripts/windows/install.ps1`
- `common/scripts/windows/check-requirements.ps1`
- `common/scripts/windows/watch-and-serve.ps1`
- `common/scripts/windows/uninstall.ps1`

### Linux

- `common/scripts/linux/install.sh`
- `common/scripts/linux/check-requirements.sh`
- `common/scripts/linux/watch-and-serve.sh`
- `common/scripts/linux/uninstall.sh`

### macOS

- `common/scripts/mac/install.sh`
- `common/scripts/mac/check-requirements.sh`
- `common/scripts/mac/watch-and-serve.sh`
- `common/scripts/mac/uninstall.sh`

## Backend compartido

### `src/main.py`

Levanta FastAPI, monta CORS, sirve la UI y dispara la indexación inicial.

### `src/api/chat.py`

Gestiona:

- caché
- búsqueda semántica
- memoria de conversación
- selección entre respuesta RAG y conversacional
- respuesta final con `sources`, `confidence` y `response_time_ms`

### `src/embeddings/encoder.py`

Soporta dos modos:

- `sentence-transformers`
- `ollama`

### `src/llm/ollama_client.py`

Reutiliza cliente HTTP y usa `keep_alive` para reducir latencia entre peticiones.

### `src/ingestion/*`

Gestiona extractores por formato, limpieza, chunking y envío a ChromaDB.

## Decisión sobre latencia y calidad

La refactorización busca que:

- el perfil bajo responda rápido en CPU
- el perfil medio sea la opción general
- el perfil alto suba calidad con mejores modelos y embeddings

No se ha duplicado `src/` porque eso dispararía el coste de mantenimiento sin aportar valor real.
