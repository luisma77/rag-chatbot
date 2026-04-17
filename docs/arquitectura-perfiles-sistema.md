# Diseno de arquitectura por perfiles de sistema

## Objetivo

Reorganizar el repositorio para que deje de estar centrado solo en el sistema operativo y pase a estar organizado por perfil de hardware:

- `SISTEMA-BAJO`
- `SISTEMA-MEDIO`
- `SISTEMA-ALTO`

El codigo fuente principal debe seguir siendo comun siempre que sea posible. La variacion entre perfiles debe resolverse principalmente con:

- scripts de instalacion y desinstalacion
- configuraciones `.env`
- paquetes opcionales
- seleccion de herramientas externas
- presets funcionales para OCR, embeddings, LLM y calidad de ingesta

La meta es evitar mantener tres proyectos distintos que hagan lo mismo.

Ademas, la prioridad principal de los perfiles debe ser la velocidad de respuesta. La calidad de OCR, embeddings, parsing y generacion debe subir por perfil, pero sin perder de vista que cada variante tiene que estar optimizada para responder rapido dentro del hardware al que va dirigida.

---

## Estado actual del repositorio

Hoy el repositorio esta organizado principalmente por sistema operativo:

- `scripts-windows/`
- `scripts-linux/`
- `scripts-mac/`
- `scripts/` compartido
- `src/` compartido

Las tres instalaciones actuales hacen casi la misma operativa:

- instalan Python
- instalan dependencias de `requirements.txt`
- instalan Ollama
- descargan `qwen2.5:3b`
- instalan Tesseract OCR
- instalan Poppler
- preparan `.env`
- crean directorios de trabajo

Esto significa que la separacion por perfil no debe empezar duplicando `src/`, sino extrayendo perfiles de configuracion y manifiestos de instalacion.

---

## Principios de diseno

1. Un solo backend base.
2. Variantes por perfil definidas por configuracion y herramientas.
3. Scripts de cada perfil y SO con el mismo contrato de nombres.
4. Cada variante debe tener su propio desinstalador.
5. Los documentos comunes y la arquitectura deben vivir fuera de los perfiles.
6. La seleccion de OCR, embeddings y modelo LLM debe ser declarativa, no hardcodeada en scripts dispersos.
7. El cambio de un perfil a otro debe poder hacerse sin residuos relevantes.
8. La prioridad operativa es tiempo de respuesta rapido, no solo maxima calidad.
9. Si una herramienta no esta instalada, se instala la version mas reciente compatible.
10. Si una herramienta ya esta instalada, el script debe detectar la version y preguntar al usuario si quiere actualizarla antes de seguir.

---

## Estructura objetivo propuesta

```text
rag-chatbot/
├── README.md
├── README.en.md
├── LICENSE
├── .env.example
├── docs/
│   ├── arquitectura-perfiles-sistema.md
│   ├── perfiles/
│   │   ├── sistema-bajo.md
│   │   ├── sistema-medio.md
│   │   └── sistema-alto.md
│   ├── sistemas-operativos/
│   │   ├── windows.md
│   │   ├── linux.md
│   │   └── macos.md
│   └── migracion/
│       └── plan-migracion.md
├── common/
│   ├── env/
│   │   ├── base.env
│   │   ├── sistema-bajo.env
│   │   ├── sistema-medio.env
│   │   └── sistema-alto.env
│   ├── requirements/
│   │   ├── base.txt
│   │   ├── ocr-basic.txt
│   │   ├── ocr-advanced.txt
│   │   ├── embeddings-basic.txt
│   │   ├── embeddings-advanced.txt
│   │   └── quality-extractors.txt
│   ├── manifests/
│   │   ├── sistema-bajo.json
│   │   ├── sistema-medio.json
│   │   └── sistema-alto.json
│   └── scripts/
│       ├── reindex_helper.py
│       ├── profile_helpers.ps1
│       ├── profile_helpers.sh
│       └── uninstall_helpers/
├── SISTEMA-BAJO/
│   ├── README.md
│   ├── windows/
│   ├── linux/
│   └── mac/
├── SISTEMA-MEDIO/
│   ├── README.md
│   ├── windows/
│   ├── linux/
│   └── mac/
├── SISTEMA-ALTO/
│   ├── README.md
│   ├── windows/
│   ├── linux/
│   └── mac/
├── src/
├── tests/
├── data/
├── examples/
└── logs/
```

---

## Contrato interno de cada variante

Cada carpeta de variante debe tener la misma estructura para reducir confusion:

```text
SISTEMA-MEDIO/
└── windows/
    ├── install.ps1
    ├── uninstall.ps1
    ├── watch-and-serve.ps1
    ├── check-requirements.ps1
    ├── run-install.bat
    ├── run-chatbot.bat
    ├── run-uninstall.bat
    ├── templates/
    │   └── .env
    └── manifest.json
```

Equivalente en Linux/macOS:

- `install.sh`
- `uninstall.sh`
- `watch-and-serve.sh`
- `check-requirements.sh`
- `run-install.sh`
- `run-chatbot.sh`
- `run-uninstall.sh`
- `templates/.env`
- `manifest.json`

---

## Reparto de responsabilidades

### 1. Contenido comun del repositorio

Debe seguir siendo compartido:

- `src/`
- `tests/`
- `examples/`
- documentacion general
- utilidades de reindexado
- definicion de variables de entorno comunes

### 2. Contenido especifico por perfil

Debe variar por `SISTEMA-BAJO`, `SISTEMA-MEDIO`, `SISTEMA-ALTO`:

- modelo LLM por defecto
- limites de concurrencia
- configuracion de chunking
- estrategia OCR
- embeddings por defecto
- dependencias opcionales
- herramientas avanzadas de parsing
- comportamiento del desinstalador

### 3. Contenido especifico por sistema operativo

Debe variar por SO:

- gestor de paquetes
- rutas de binarios
- PATH
- instalacion de dependencias nativas
- watcher de ficheros
- formato del lanzador (`.bat`, `.ps1`, `.sh`)

---

## Matriz funcional por perfil

Esta matriz es inicial y puede ajustarse antes de implementar.

| Area | SISTEMA-BAJO | SISTEMA-MEDIO | SISTEMA-ALTO |
|------|--------------|---------------|--------------|
| Prioridad | Latencia baja con poco consumo | Latencia baja equilibrada | Latencia baja con maxima calidad posible |
| Modelo Ollama por defecto | Pequeno | Equilibrado | Grande o doble opcion |
| Embeddings | Ligeros | Multilingues equilibrados | Multilingues de mayor calidad |
| OCR | Basico | Tesseract completo | Tesseract + opciones avanzadas |
| Extraccion PDF | pdfplumber + OCR basico | pipeline actual balanceado | pipeline de mayor calidad, posible Docling |
| Concurrencia | Baja | Media | Alta |
| Chunking | Conservador | Balanceado | Ajustado a calidad y contexto |
| Requisitos de RAM | 16 GB | 32 GB | 32 GB o mas |
| GPU | No requerida | No requerida | Requerida y potente |
| Calidad de respuesta | Correcta | Buena | Mejor posible en local |
| Tiempo de instalacion | Bajo | Medio | Alto |

---

## Perfil propuesto: SISTEMA-BAJO

Pensado para equipos con recursos limitados, portatiles antiguos o despliegues donde importa mas la ligereza que la maxima calidad.

### Objetivos

- respuesta rapida en CPU
- reducir consumo de RAM
- reducir peso de modelos
- mantener compatibilidad aceptable
- evitar dependencias pesadas no imprescindibles

### Hardware objetivo

- 16 GB de RAM
- CPU media o modesta
- sin GPU dedicada necesaria

### Lineas base sugeridas

- modelo Ollama pequeno
- embeddings ligeros
- OCR con Tesseract solo cuando realmente se necesite
- sin extractores avanzados pesados
- `MAX_CONCURRENT_LLM` bajo
- chunks moderados para reducir coste

### Herramientas a instalar

- Python en version estable reciente
- dependencias Python base del proyecto
- Ollama en su version mas reciente compatible
- modelo LLM pequeno orientado a CPU
- Tesseract OCR
- Poppler
- watcher del sistema operativo

### Herramientas a evitar por defecto

- Docling
- extractores avanzados pesados
- modelos grandes pensados para GPU
- embeddings muy pesados

### Riesgos

- menor calidad semantica
- OCR mas lento o menos robusto
- peor respuesta en documentos complejos

---

## Perfil propuesto: SISTEMA-MEDIO

Debe convertirse en el perfil de referencia del proyecto porque es el que mas se parece al estado actual.

### Objetivos

- respuesta rapida en CPU sin GPU
- equilibrio entre facilidad, calidad y consumo
- multilenguaje correcto
- OCR y parsing fiables para la mayoria de documentos
- experiencia local estable

### Hardware objetivo

- 32 GB de RAM
- CPU media
- sin GPU dedicada

### Lineas base sugeridas

- mantener una variante equivalente a la actual
- embeddings multilingues equilibrados
- Tesseract + Poppler
- pipeline PDF mixto actual
- concurrencia moderada
- chunks y thresholds ya probados

### Herramientas a instalar

- todo lo actual del proyecto
- Python en version estable reciente
- dependencias Python base actuales
- Ollama en version reciente
- modelo equilibrado para CPU
- Tesseract OCR
- Poppler
- watcher del SO

### Restriccion

Este perfil debe conservar las herramientas actuales como base de compatibilidad. Si se anaden mejoras, no deben penalizar claramente la velocidad de respuesta en una maquina de 32 GB RAM sin GPU.

### Observacion

Este perfil deberia ser la fuente de verdad inicial durante la migracion. Primero se estabiliza `SISTEMA-MEDIO` y despues se derivan `BAJO` y `ALTO`.

---

## Perfil propuesto: SISTEMA-ALTO

Pensado para equipos con RAM abundante, CPU/GPU mejores o entornos donde la prioridad es exprimir calidad.

### Objetivos

- respuesta rapida aprovechando GPU
- mejor OCR y parsing
- mayor calidad semantica
- modelos LLM mas capaces
- mejor tratamiento de documentos complejos y multiformato

### Hardware objetivo

- minimo 32 GB de RAM
- GPU buena, por ejemplo RTX 3060 Ti o superior
- CPU muy potente, por ejemplo gama i7 alta moderna

### Lineas base sugeridas

- modelos LLM superiores o perfiles alternables
- embeddings de mayor calidad
- opcion de Docling u otros extractores avanzados
- OCR mas robusto
- mas concurrencia
- parametros de generacion mas afinados

### Herramientas a instalar

- Python en version estable reciente
- dependencias Python base
- dependencias Python avanzadas
- Ollama en version reciente
- uno o varios modelos optimizados para GPU
- Tesseract OCR
- Poppler
- Docling u otro pipeline avanzado para documentos complejos
- watcher del SO

### Enfoque operativo

Este perfil no debe usar la GPU solo para "poner mas cosas", sino para bajar latencia y mejorar calidad al mismo tiempo. Si una herramienta avanzada degrada claramente el tiempo de respuesta, debe ser opcional o activarse solo en flujos concretos de ingesta.

### Riesgos

- instalacion mas lenta
- mas dependencias externas
- mayor complejidad operativa
- mayor coste de mantenimiento si no se abstrae bien

---

## Modelo de configuracion recomendado

La reorganizacion debe apoyarse en perfiles declarativos. Se propone introducir estas variables:

```env
SYSTEM_PROFILE=medium
OCR_BACKEND=tesseract
PDF_PIPELINE=balanced
EMBEDDING_PROFILE=balanced
LLM_PROFILE=balanced
INGESTION_PRESET=balanced
```

Variables mas concretas:

```env
OLLAMA_MODEL=qwen2.5:3b
EMBEDDING_MODEL=paraphrase-multilingual-MiniLM-L12-v2
MAX_CONCURRENT_LLM=3
CHUNK_SIZE=800
CHUNK_OVERLAP=100
TESSERACT_LANG=spa+eng
```

La idea es que:

- el script de cada perfil copie su `.env`
- el backend lea ese `.env`
- las decisiones funcionales esten concentradas en configuracion y no repartidas en varios scripts

Variables adicionales recomendadas:

```env
USE_GPU=false
GPU_BACKEND=none
INSTALL_QUALITY_EXTRAS=false
PROMPT_FOR_UPDATES=true
```

---

## Manifiesto por variante

Cada variante deberia tener un `manifest.json` o fichero equivalente con informacion declarativa.

Ejemplo conceptual:

```json
{
  "profile": "sistema-medio",
  "os": "windows",
  "python": "3.12",
  "ollama_model": "qwen2.5:3b",
  "pip_requirement_sets": [
    "base.txt"
  ],
  "external_tools": [
    "ollama",
    "tesseract",
    "poppler"
  ],
  "watcher": "filesystemwatcher",
  "env_template": "templates/.env"
}
```

Ventajas:

- facilita instalar
- facilita desinstalar
- reduce logica duplicada
- hace visible que instala cada variante

---

## Estrategia de desinstalacion

Cada variante debe incluir su propio desinstalador para limpiar:

- paquetes Python instalados por esa variante
- modelos Ollama descargados por esa variante
- herramientas externas instaladas por esa variante cuando sea seguro desinstalarlas
- variables PATH agregadas por esa variante
- ficheros temporales, logs y caches opcionales

### Regla importante

El desinstalador no debe borrar datos del usuario por defecto:

- `data/documents/` no se borra
- `chroma_db/` se pregunta o se ofrece opcion
- `.env` se respalda o se pregunta

### Recomendacion tecnica

Cada instalador debe escribir un registro de instalacion:

```text
install-state/
└── sistema-medio-windows.json
```

Ese registro debe guardar:

- rutas modificadas
- herramientas instaladas
- modelos descargados
- paquetes opcionales instalados
- archivos generados

Sin eso, el desinstalador sera poco fiable.

---

## Politica de instalacion y actualizacion

Todos los instaladores deben seguir la misma politica:

### Si la herramienta no existe

- instalar la version mas reciente compatible en ese momento
- registrar la version instalada en `install-state/`

### Si la herramienta ya existe

- detectar la version actual
- detectar si hay una version mas reciente disponible
- preguntar al usuario si desea actualizarla
- si el usuario responde que no, conservar la actual y continuar con la siguiente herramienta
- si el usuario responde que si, actualizar y continuar

### Herramientas a las que aplica esta politica

- Python
- Ollama
- Tesseract
- Poppler
- watchers del sistema si se instalan explicitamente
- dependencias opcionales avanzadas del perfil
- modelos Ollama del perfil

### Regla de UX del instalador

El instalador debe preguntar herramienta por herramienta de forma clara, por ejemplo:

```text
Ollama ya esta instalado: 0.x.y
Hay una version mas reciente disponible: 0.a.b
Deseas actualizar? [S/n]
```

Si no se puede detectar la ultima version de forma fiable, el script debe:

- avisar de que no pudo comprobar actualizaciones
- conservar la instalacion actual
- continuar con la siguiente dependencia

---

## Herramientas recomendadas por perfil

La siguiente propuesta prioriza velocidad de respuesta para el hardware indicado.

| Componente | SISTEMA-BAJO | SISTEMA-MEDIO | SISTEMA-ALTO |
|-----------|--------------|---------------|--------------|
| Python | estable reciente | estable reciente | estable reciente |
| Ollama | si | si | si |
| Modelo principal | pequeno y rapido en CPU | equilibrado para CPU | mayor calidad, idealmente acelerado por GPU |
| Embeddings | ligeros | multilingues equilibrados | multilingues de mayor calidad |
| Tesseract | si | si | si |
| Poppler | si | si | si |
| Docling | no | no por defecto | si o opcional recomendado |
| Watcher SO | si | si | si |
| Extras de parsing | minimos | actuales | avanzados |

### Criterio de seleccion

- `SISTEMA-BAJO`: lo minimo viable para responder rapido con 16 GB RAM.
- `SISTEMA-MEDIO`: conservar el stack actual porque ya esta equilibrado para CPU sin GPU.
- `SISTEMA-ALTO`: sumar herramientas avanzadas solo cuando aporten calidad sin romper la latencia objetivo.

---

## Que no conviene hacer

No conviene:

- duplicar `src/` en cada perfil
- copiar `tests/` tres veces
- mantener tres `requirements.txt` completos y desalineados
- poner logica de negocio distinta dentro de los scripts de SO si puede resolverse con presets
- mezclar documentacion comun dentro de cada perfil

Eso haria muy caro mantener el proyecto.

---

## Refactor minimo necesario en el backend

Antes o durante la migracion conviene hacer pequenos cambios en `src/`:

1. Permitir presets de perfil via variables de entorno.
2. Separar configuracion base de configuracion derivada.
3. Preparar extractores opcionales para backends futuros.
4. Evitar rutas por defecto demasiado centradas en Windows.

### Cambios concretos sugeridos

- ampliar `src/config.py` para incluir `system_profile`, `ocr_backend`, `pdf_pipeline`
- mover defaults Windows a plantillas `.env`, no al codigo
- preparar una capa de seleccion de extractor si entra Docling u otra opcion

---

## Propuesta de nombres estables

Para evitar mezcla de estilos:

- carpetas: `SISTEMA-BAJO`, `SISTEMA-MEDIO`, `SISTEMA-ALTO`
- SO: `windows`, `linux`, `mac`
- docs internas: minusculas con guiones
- manifests: `manifest.json`
- estado de instalacion: `install-state/<perfil>-<so>.json`

---

## Orden recomendado de migracion

### Fase 1. Documentacion y contrato

- crear `docs/`
- aprobar estructura objetivo
- definir oficialmente que significa cada perfil
- definir matriz perfil x sistema operativo

### Fase 2. Configuracion comun

- dividir `requirements.txt` en conjuntos reutilizables
- crear `common/env/`
- crear manifiestos por perfil
- anadir nuevas variables de configuracion en backend

### Fase 3. Migracion del perfil medio

- mover el estado actual a `SISTEMA-MEDIO/`
- mantener compatibilidad con los lanzadores actuales temporalmente
- validar que `SISTEMA-MEDIO` funciona igual que hoy

### Fase 4. Crear perfil bajo

- recortar herramientas y pesos
- ajustar `.env`
- ajustar instalacion y desinstalacion

### Fase 5. Crear perfil alto

- incorporar opciones avanzadas
- introducir dependencias opcionales
- validar comportamiento en equipos potentes

### Fase 6. Limpieza final

- retirar scripts legacy del raiz
- actualizar `README`
- actualizar `README.en.md`
- documentar caminos de migracion entre perfiles

---

## Compatibilidad temporal durante la migracion

Para no romper a usuarios actuales, durante una etapa intermedia el raiz podria mantener wrappers:

- `run-install.bat`
- `run-install.sh`
- `run-install-mac.sh`
- `run-chatbot.bat`
- `run-chatbot.sh`
- `run-chatbot-mac.sh`

Esos wrappers podrian redirigir temporalmente a `SISTEMA-MEDIO`, que sera la continuacion natural del proyecto actual.

---

## Preguntas de diseno que conviene cerrar antes de implementar

1. Que modelos LLM exactos representaran `BAJO`, `MEDIO` y `ALTO` con foco en latencia.
2. Que modelo de embeddings corresponde a cada perfil.
3. Si `SISTEMA-ALTO` debe incluir Docling desde el inicio o dejarlo como opcion.
4. Si los paquetes Python se instalaran globalmente, en venv o en ambos escenarios.
5. Si la desinstalacion debe ser totalmente automatica o semiasistida.
6. Si `mac` va a mantenerse al mismo nivel que Windows y Linux en esta primera fase.

---

## Recomendacion final

La mejor ruta no es mover carpetas primero, sino convertir el proyecto actual en un sistema basado en perfiles.

Resumen practico:

- `src/` comun
- `docs/` comun
- `common/` para configuracion y paquetes reutilizables
- `SISTEMA-MEDIO` como primera migracion real
- `SISTEMA-BAJO` y `SISTEMA-ALTO` derivados de esa base
- desinstalacion obligatoria por variante

Con este enfoque, la nueva estructura soporta perfiles distintos sin multiplicar el coste de mantenimiento.
