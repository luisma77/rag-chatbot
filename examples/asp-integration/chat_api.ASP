<%@ Language="VBScript" %>
<%
'
' chat_api.ASP — Proxy entre la intranet (Servidor B) y el RAG Chatbot (Servidor A)
'
' INSTALACION:
'   Copiar este archivo al Servidor B (IIS), en la misma ruta que lo llama default.asp
'   Ejemplo: C:\Inetpub\wwwroot\intranet\p7consul\ia\chat_api.ASP
'
' CONFIGURACION:
'   Edita las constantes de la seccion "CONFIGURACION" abajo.
'
' PREREQUISITOS SERVIDOR A:
'   - RAG Chatbot corriendo: python -m uvicorn src.main:app --host 0.0.0.0 --port 8000
'   - Puerto 8000 abierto en el firewall de Servidor A para la IP de Servidor B
'   - Opcionalmente: API_KEY configurada en el .env del chatbot
'
Option Explicit

Response.CodePage   = 65001
Response.Charset    = "utf-8"
Response.ContentType = "text/plain"

' ============================================================
' CONFIGURACION — editar segun tu entorno
' ============================================================

' IP o hostname del Servidor A donde corre el RAG Chatbot
' Debe ser accesible desde Servidor B por la red interna
Const CHATBOT_URL = "http://172.18.130.153:8000/chat"

' Clave API (dejar vacia si no se ha configurado API_KEY en el .env del chatbot)
' Si se configura, debe coincidir con API_KEY= en el .env del Servidor A
Const API_KEY = ""

' Timeout en milisegundos (resolve, connect, send, receive)
Const TIMEOUT_MS = 60000

' ============================================================

Dim mensaje, sessionId, payload, http, raw, respuesta

mensaje   = Trim(Request.Form("mensaje"))
sessionId = Session.SessionID   ' Identificador unico de sesion por usuario

If mensaje = "" Then
    Response.Write "Mensaje vacío"
    Response.End
End If

' ── Escape JSON seguro ──────────────────────────────────────
Function JsonEscape(txt)
    txt = Replace(txt, "\",    "\\")
    txt = Replace(txt, """",   "\""")
    txt = Replace(txt, vbCrLf, "\n")
    txt = Replace(txt, vbCr,   "\n")
    txt = Replace(txt, vbLf,   "\n")
    txt = Replace(txt, Chr(9), "\t")
    JsonEscape = txt
End Function

' ── Construir payload JSON ──────────────────────────────────
' El chatbot espera: {"question": "...", "session_id": "..."}
' session_id permite memoria de conversacion por usuario
payload = "{" & _
    """question"":"""    & JsonEscape(mensaje)   & """," & _
    """session_id"":""" & JsonEscape(sessionId) & """" & _
"}"

' ── Llamada HTTP al chatbot ─────────────────────────────────
Set http = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")
http.setTimeouts TIMEOUT_MS, TIMEOUT_MS, TIMEOUT_MS, TIMEOUT_MS

On Error Resume Next
http.Open "POST", CHATBOT_URL, False
http.setRequestHeader "Content-Type", "application/json; charset=utf-8"
http.setRequestHeader "Accept",       "application/json"

' Añadir API key si esta configurada
If API_KEY <> "" Then
    http.setRequestHeader "X-API-Key", API_KEY
End If

http.Send payload

If Err.Number <> 0 Then
    Response.Write "Error de conexión con el asistente IA: " & Err.Description & _
                   ". Comprueba que el Servidor A está activo en " & CHATBOT_URL
    Response.End
End If
On Error GoTo 0

If http.Status = 401 Then
    Response.Write "Error de autenticación: API key incorrecta o no configurada."
    Response.End
End If

If http.Status <> 200 Then
    Response.Write "Error HTTP " & http.Status & " al conectar con el asistente IA."
    Response.End
End If

raw = http.responseText

' ── Parsear JSON — extraer campo "answer" ──────────────────
' El chatbot devuelve: {"answer": "...", "sources": [...], "confidence": "...", ...}
Dim re, matches

Set re = New RegExp
re.Pattern = """answer""\s*:\s*""([\s\S]*?)(?<!\\)"""
re.Global  = False

If re.Test(raw) Then
    Set matches = re.Execute(raw)
    respuesta = matches(0).SubMatches(0)
Else
    ' Fallback: intentar con regex mas permisivo
    re.Pattern = """answer"":""\s*(.*?)\s*"""
    If re.Test(raw) Then
        Set matches = re.Execute(raw)
        respuesta = matches(0).SubMatches(0)
    Else
        respuesta = "El asistente respondió pero no se pudo procesar la respuesta."
    End If
End If

' ── Limpieza de escapes JSON ────────────────────────────────
respuesta = Replace(respuesta, "\n",  vbCrLf)
respuesta = Replace(respuesta, "\r",  "")
respuesta = Replace(respuesta, "\t",  Chr(9))
respuesta = Replace(respuesta, "\""", """")
respuesta = Replace(respuesta, "\\",  "\")

Response.Write respuesta

Set http = Nothing
Set re   = Nothing
%>
