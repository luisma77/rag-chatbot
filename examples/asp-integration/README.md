# Integración ASP Classic — RAG Chatbot en Servidor A + Intranet en Servidor B

Guía paso a paso para conectar el RAG Chatbot (alojado en una máquina dedicada)
con una intranet o aplicación web alojada en un servidor IIS distinto.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│  NAVEGADOR DEL USUARIO                                       │
│  (empleado conectado a la intranet)                          │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS · Puerto 443
┌──────────────────────────▼──────────────────────────────────┐
│  SERVIDOR B — IIS / ASP Classic                             │
│  intranet.tuempresa.com                                      │
│                                                              │
│  default.asp          ← página principal, SIN TOCAR         │
│    └─ JS fetch() ──────────────────────────────────┐        │
│                                                    │        │
│  chat_api.ASP  ← SOLO ESTE ARCHIVO SE MODIFICA     │        │
│    └─ HTTP POST (red interna) ──────────────────────┘       │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP · Puerto 8000
                           │ (red interna / VPN — NO internet)
┌──────────────────────────▼──────────────────────────────────┐
│  SERVIDOR A — RAG Chatbot                                   │
│  IP interna: 172.18.x.x  (o hostname interno)               │
│                                                              │
│  Python + FastAPI + ChromaDB + Ollama                        │
│  Endpoint: POST /chat                                        │
│  Puerto: 8000                                                │
└─────────────────────────────────────────────────────────────┘
```

> **Servidor A nunca queda expuesto a internet.** Solo acepta conexiones
> desde la IP del Servidor B. El usuario siempre habla con su intranet de
> confianza; el chatbot es un servicio interno.

---

## Flujo de datos

```
1. Usuario escribe en default.asp
2. JS llama a:  POST /intranet/p7consul/ia/chat_api.ASP
                body: mensaje=¿Cuál es la política de vacaciones?
3. chat_api.ASP llama a Servidor A:
                POST http://172.18.x.x:8000/chat
                {"question": "¿Cuál es la política de vacaciones?",
                 "session_id": "abc123"}
4. Servidor A busca en ChromaDB, genera respuesta con Ollama
5. Devuelve: {"answer": "Según el manual de empleados...", ...}
6. chat_api.ASP extrae el campo "answer" y lo devuelve como texto plano
7. JS de default.asp muestra el texto en la burbuja del chat
```

---

## SERVIDOR A — Instalación y configuración

### Paso 1 — Clonar el repositorio

```powershell
git clone https://github.com/luisma77/rag-chatbot.git
cd rag-chatbot
```

### Paso 2 — Instalar todo

Usa la variante Windows del perfil que vayas a desplegar. Si no tienes claro cuál elegir, empieza por `SISTEMA-MEDIO`:

```powershell
.\SISTEMA-MEDIO\windows\run-install.bat
```

Instala Python, Ollama, `qwen3:4b`, OCR, Poppler y dependencias del backend para esa variante.

### Paso 3 — Configurar .env

```env
# .env en la raíz del proyecto

# Puerto de escucha (debe coincidir con lo que pones en chat_api.ASP)
API_PORT=8000

# Clave API — si la defines aquí, debes ponerla también en chat_api.ASP
# Dejar vacío en entornos de red privada si no necesitas autenticación
API_KEY=mi_clave_secreta_aqui

# Orígenes permitidos — IP o dominio del Servidor B
ALLOWED_ORIGINS=https://intranet.tuempresa.com
```

### Paso 4 — Abrir el puerto 8000 en el firewall de Servidor A

**Solo para la IP de Servidor B** (no abrir a internet):

```powershell
# Ejecutar como Administrador en Servidor A
New-NetFirewallRule `
    -DisplayName "RAG Chatbot - Servidor B" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 8000 `
    -RemoteAddress "172.18.x.x" `   # <-- IP de Servidor B
    -Action Allow
```

> Si ambos servidores están en la misma LAN/VLAN sin firewall entre ellos,
> este paso puede no ser necesario.

### Paso 5 — Arrancar el chatbot

```powershell
# Arrancar y dejar corriendo (o configurar como servicio Windows)
.\SISTEMA-MEDIO\windows\run-chatbot.bat
```

Para que arranque automáticamente con Windows, crear una tarea programada:

```powershell
$action  = New-ScheduledTaskAction -Execute "pwsh.exe" `
    -Argument "-NonInteractive -ExecutionPolicy Bypass -File C:\rag-chatbot\SISTEMA-MEDIO\windows\watch-and-serve.ps1" `
    -WorkingDirectory "C:\rag-chatbot"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "RAG Chatbot" -Action $action -Trigger $trigger `
    -RunLevel Highest -User "SYSTEM"
```

### Verificar que funciona

```powershell
# Desde Servidor B o cualquier máquina de la red interna:
Invoke-RestMethod -Uri "http://172.18.x.x:8000/health"

# Respuesta esperada:
# {"status":"ok","version":"1.0.0", ...}
```

---

## SERVIDOR B — Cambios necesarios

### Archivos a modificar / añadir

| Archivo | Acción |
|---------|--------|
| `chat_api.ASP` | **Sustituir** por la versión de este directorio |
| `default.asp` | **Sin cambios** — el JavaScript ya funciona |

### Los únicos cambios respecto al chat_api.ASP original

```vbscript
' ── LÍNEA 1: URL del servidor ──────────────────────────────
' ANTES (servidor anterior):
url = "http://172.18.130.153:3000/ask"

' DESPUÉS (RAG Chatbot):
Const CHATBOT_URL = "http://172.18.x.x:8000/chat"   ' <-- IP de Servidor A


' ── LÍNEA 2: Payload JSON ──────────────────────────────────
' ANTES:
payload = "{""pregunta"":""" & JsonEscape(mensaje) & """}"

' DESPUÉS (campo "question" + session_id para memoria):
sessionId = Session.SessionID
payload = "{""question"":"""    & JsonEscape(mensaje)   & """," & _
          """session_id"":""" & JsonEscape(sessionId) & """}"


' ── LÍNEA 3: Parseo de respuesta ───────────────────────────
' ANTES:
re.Pattern = """respuesta""\s*:\s*""([\s\S]*?)"""

' DESPUÉS:
re.Pattern = """answer""\s*:\s*""([\s\S]*?)(?<!\\)"""


' ── LÍNEA 4 (opcional): API Key ────────────────────────────
' Añadir antes del http.Send si API_KEY está configurado en .env:
http.setRequestHeader "X-API-Key", "mi_clave_secreta_aqui"
```

### Copiar el archivo

Copiar `examples/asp-integration/chat_api.ASP` a la misma ruta donde está
el `chat_api.ASP` actual del Servidor B. Editar las constantes de configuración:

```vbscript
' En la sección CONFIGURACION del archivo:
Const CHATBOT_URL = "http://172.18.x.x:8000/chat"   ' IP real de Servidor A
Const API_KEY     = "mi_clave_secreta_aqui"           ' o "" si no se usa
```

---

## Puertos de referencia

| Puerto | Servidor | Descripción |
|--------|----------|-------------|
| `443` | B (IIS) | HTTPS intranet → usuarios |
| `80` | B (IIS) | HTTP intranet (redirige a 443) |
| `8000` | A (FastAPI) | API del chatbot → solo desde Servidor B |
| `11434` | A (Ollama) | Servicio LLM → solo uso local en Servidor A |

> El puerto `11434` de Ollama **no debe abrirse** al exterior ni a Servidor B.
> Solo lo usa FastAPI internamente en la misma máquina.

---

## Verificación de la integración

### 1. Test básico desde Servidor B (PowerShell)

```powershell
# Ejecutar desde Servidor B para verificar que llega a Servidor A
$body = '{"question":"hola","session_id":"test"}'
$headers = @{"Content-Type"="application/json"; "X-API-Key"="mi_clave"}
Invoke-RestMethod -Uri "http://172.18.x.x:8000/chat" -Method POST `
    -Body $body -Headers $headers
```

### 2. Test del proxy ASP

Abrir en el navegador (desde la intranet):
```
https://intranet.tuempresa.com/intranet/p7consul/ia/chat_api.ASP
```
Debe devolver: `Mensaje vacío` (porque no se envió formulario — eso es correcto)

### 3. Test completo

Abrir `default.asp` y escribir en el chat. Si responde → integración completa ✅

---

## Solución de problemas

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| `Error de conexión con el asistente IA` | Servidor A no accesible desde B | Verificar IP, puerto y firewall |
| `Error HTTP 401` | API key incorrecta | Verificar que coincide en `.env` y `chat_api.ASP` |
| `No se pudo interpretar la respuesta` | Chatbot devolvió error JSON | Ver logs en `logs/chatbot.log` de Servidor A |
| `El asistente no arranca` | Ollama no iniciado | Ejecutar `ollama serve` en Servidor A |
| Respuestas lentas (>30s) | Modelo cargándose | Normal en el primer arranque; después ~5s |

---

## Otros lenguajes (próximamente)

La misma arquitectura funciona con cualquier lenguaje que pueda hacer HTTP POST.
Solo cambia el proxy en Servidor B:

| Lenguaje | Estado |
|----------|--------|
| **ASP Classic (VBScript)** | ✅ Implementado — ver `chat_api.ASP` |
| PHP | 🔜 Próximamente |
| HTML + JS puro | 🔜 Próximamente (requiere CORS configurado) |
| ASP.NET (C#) | 🔜 Próximamente |
| Node.js | 🔜 Próximamente |

> Para HTML puro (sin proxy server-side), el navegador llamaría directamente
> a Servidor A — esto requiere que `ALLOWED_ORIGINS` en `.env` incluya el
> dominio de la página, y que Servidor A sea accesible desde los navegadores
> (no solo desde Servidor B).

---

## 💬 Widget de chat embebible

Para integrar el chat **dentro de una página existente** usa `chat_widget.js` — un widget autocontenido que inyecta su propio HTML y CSS sin afectar al resto de la página.

### Archivos de esta integración

| Archivo | Descripción |
|---------|-------------|
| `chat_api.ASP` | Proxy server-side entre tu intranet y el RAG Chatbot |
| `chat_widget.js` | Widget JS embebible — el chat visual completo |
| `demo_integracion.asp` | Demo completa: intranet con el widget integrado |

### Modo 1 — Flotante (botón en esquina)

Añade esto antes del `</body>` de cualquier página:

```html
<script>
window.RAGChatConfig = {
  apiUrl:       '/intranet/ia/chat_api.ASP',
  title:        'Asistente IA',
  primaryColor: '#5b7cf7',
  mode:         'floating',
  position:     'bottom-right',
  greeting:     'Hola, ¿en qué puedo ayudarte?',
};
</script>
<script src="/intranet/ia/chat_widget.js"></script>
```

Resultado: botón circular en la esquina → clic → abre panel de chat.

### Modo 2 — Embebido en la página

```html
<!-- Coloca este div donde quieras el chat -->
<div id="rag-chat-widget" style="width:100%;max-width:700px;height:550px;"></div>

<script>
window.RAGChatConfig = {
  apiUrl:  'chat_api.ASP',
  title:   'Asistente Documental',
  mode:    'embedded',
  greeting: 'Hola, ¿en qué puedo ayudarte?',
};
</script>
<script src="chat_widget.js"></script>
```

### Opciones de configuración

| Opción | Tipo | Por defecto | Descripción |
|--------|------|-------------|-------------|
| `apiUrl` | string | **obligatorio** | Ruta al proxy `chat_api.ASP` |
| `title` | string | `'Asistente IA'` | Título del panel |
| `subtitle` | string | `''` | Subtítulo |
| `placeholder` | string | `'Escribe tu pregunta...'` | Placeholder del input |
| `primaryColor` | string | `'#5b7cf7'` | Color principal |
| `mode` | string | `'floating'` | `'floating'` o `'embedded'` |
| `position` | string | `'bottom-right'` | Posición flotante: `'bottom-right'` / `'bottom-left'` |
| `width` | string | `'380px'` | Ancho (solo floating) |
| `height` | string | `'520px'` | Alto del panel |
| `greeting` | string | `''` | Mensaje inicial del bot |
| `logoText` | string | `'IA'` | Letras en el avatar |
| `containerId` | string | `'rag-chat-widget'` | ID del div contenedor (embedded) |

### Personalización CSS

```css
/* Sobreescribe en tu hoja de estilos */
:root {
  --rag-primary:     #5b7cf7;
  --rag-bg:          #ffffff;
  --rag-bot-bubble:  #f1f3f9;
  --rag-user-bubble: #5b7cf7;
  --rag-text:        #1a1a2e;
  --rag-border:      #e2e8f0;
  --rag-radius:      14px;
}
```

Tema oscuro: añade clase `rag-dark` al div contenedor.

### Ver la demo

Abre `demo_integracion.asp` en Servidor B para ver el widget integrado en una página de intranet real.
