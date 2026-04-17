# SISTEMA-MEDIO

Perfil de referencia del proyecto. Está pensado para equipos con **24-32 GB de RAM**, CPU media y **sin necesidad de GPU**. Prioriza **latencia baja con una calidad claramente superior al perfil bajo**.

## Objetivo del perfil

- Ser la opción recomendada por defecto
- Mantener muy buen equilibrio entre calidad y velocidad
- Conservar un stack robusto sin añadir complejidad innecesaria
- Dar una experiencia consistente en Windows, Linux y macOS

## Configuración base

| Área | Valor |
|------|-------|
| Modelo chat | `qwen3:4b` |
| Embeddings | `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` |
| Provider embeddings | `sentence-transformers` |
| `TOP_K` | `5` |
| `CHUNK_SIZE` | `800` |
| `CHUNK_OVERLAP` | `100` |
| `MAX_CONCURRENT_LLM` | `2` |
| Requirements Python | `common/requirements/profile-medium.txt` |

## Cuándo usarlo

Usa `SISTEMA-MEDIO` si:

- quieres el mejor equilibrio general
- trabajas en CPU pero con memoria suficiente
- necesitas un perfil fiable para uso diario
- no quieres gestionar embeddings avanzados ni extras pesados

## Instalación por sistema operativo

Las instalaciones y desinstalaciones de este perfil se hacen sobre el **entorno de sistema**. Solo `Python` y `Ollama` pueden pedir confirmación; el resto se resuelve automáticamente.

### Windows

```powershell
.\windows\run-install.bat
.\windows\run-chatbot.bat
.\windows\run-uninstall.bat
```

### Linux

```bash
bash linux/run-install.sh
bash linux/run-chatbot.sh
bash linux/run-uninstall.sh
```

### macOS

```bash
bash mac/run-install.sh
bash mac/run-chatbot.sh
bash mac/run-uninstall.sh
```

## Qué instala

- Python 3.10+
- Ollama
- `qwen3:4b`
- Tesseract OCR
- Poppler
- watcher nativo por sistema
- requirements de runtime comunes

## Ventajas

- mejor calidad conversacional que `SISTEMA-BAJO`
- recuperación semántica estable
- buen rendimiento en CPU moderna
- suele ser la mejor primera opción en la mayoría de equipos

## Limitaciones

- más consumo que `SISTEMA-BAJO`
- no exprime GPU ni embeddings avanzados
- en hardware muy justo puede sentirse más pesado

## Recomendación operativa

Es el perfil que conviene probar primero. Si necesitas más calidad y tienes GPU, sube a `SISTEMA-ALTO`. Si necesitas más ligereza, baja a `SISTEMA-BAJO`.
