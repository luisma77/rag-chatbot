# SISTEMA-BAJO

Perfil orientado a equipos con **16 GB de RAM**, CPU media o modesta y **sin GPU dedicada**. Está diseñado para ofrecer **la menor latencia posible** sin perder soporte multi-formato ni OCR básico.

## Objetivo del perfil

- Responder rápido en CPU
- Reducir consumo de memoria
- Mantener instalación sencilla
- Soportar español e inglés con buen equilibrio
- Evitar dependencias pesadas innecesarias

## Configuración base

| Área | Valor |
|------|-------|
| Modelo chat | `qwen3:1.7b` |
| Embeddings | `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` |
| Provider embeddings | `sentence-transformers` |
| `TOP_K` | `4` |
| `CHUNK_SIZE` | `640` |
| `CHUNK_OVERLAP` | `80` |
| `MAX_CONCURRENT_LLM` | `1` |
| Requirements Python | `common/requirements/profile-low.txt` |

## Cuándo usarlo

Usa `SISTEMA-BAJO` si:

- el equipo no tiene GPU útil para IA local
- quieres un bot rápido para consultas cortas y frecuentes
- la prioridad es operar bien en CPU
- prefieres un stack contenido y más fácil de mantener

## Instalación por sistema operativo

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
- `qwen3:1.7b`
- Tesseract OCR
- Poppler
- watcher nativo del sistema
- requirements de runtime comunes

## Ventajas

- menor tiempo de arranque práctico
- menor presión de RAM
- coste bajo por consulta
- instalación más ligera que los otros perfiles

## Limitaciones

- menos profundidad de respuesta que `SISTEMA-MEDIO` o `SISTEMA-ALTO`
- menor margen en documentos largos o ambiguos
- embeddings correctos pero no tan potentes como la variante alta

## Recomendación operativa

Si el equipo aguanta `SISTEMA-MEDIO`, úsalo. Si notas swapping, lentitud general del sistema o tiempos de primera respuesta demasiado altos, baja a este perfil.
