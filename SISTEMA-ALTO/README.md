# SISTEMA-ALTO

Perfil orientado a equipos con **32 GB o más de RAM**, CPU potente y preferiblemente **GPU dedicada**. Prioriza **calidad de respuesta y calidad de recuperación** sin renunciar a una latencia competitiva.

## Objetivo del perfil

- Mejorar la calidad final de la respuesta
- Subir la precisión de recuperación documental
- Aprovechar hardware superior
- Añadir extras de ingesta avanzados solo en el perfil que puede soportarlos

## Configuración base

| Área | Valor |
|------|-------|
| Modelo chat | `qwen3:8b` |
| Embeddings | `qwen3-embedding:4b` |
| Provider embeddings | `ollama` |
| `TOP_K` | `6` |
| `CHUNK_SIZE` | `960` |
| `CHUNK_OVERLAP` | `120` |
| `MAX_CONCURRENT_LLM` | `4` |
| Requirements Python | `common/requirements/profile-high.txt` |
| Extra principal | `docling` |

## Cuándo usarlo

Usa `SISTEMA-ALTO` si:

- tienes GPU y quieres exprimir calidad local
- trabajas con documentos complejos o más variados
- valoras especialmente la precisión semántica
- aceptas una instalación más pesada a cambio de un mejor resultado

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
- `qwen3:8b`
- `qwen3-embedding:4b`
- Tesseract OCR
- Poppler
- watcher nativo por sistema
- `docling` y extras avanzados de ingesta

## Ventajas

- mejor calidad de respuesta
- embeddings más potentes para recuperación
- mejor tolerancia a consultas ambiguas
- preparado para sacar partido de hardware superior

## Limitaciones

- instalación más lenta
- mayor consumo de disco y memoria
- no es el mejor perfil para CPU modesta

## Recomendación operativa

Si el objetivo principal es montar un chatbot local serio para documentación corporativa y la máquina acompaña, este es el perfil más interesante. Si la latencia absoluta manda por encima de todo, `SISTEMA-MEDIO` puede seguir siendo más conveniente.
