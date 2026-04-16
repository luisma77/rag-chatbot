<%@ Language="VBScript" %>
<%
' chat.asp — RAG Chatbot interface for ASP Classic
' Calls the FastAPI backend running on the AI server.
'
' CONFIGURATION: Change AI_SERVER_URL to your AI server IP
Const AI_SERVER_URL = "http://IP_SERVIDOR_IA:8000"

Dim question, answer, sources, confidence, responseTimeMs
question = ""
answer = ""
sources = ""
confidence = ""
responseTimeMs = ""

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    question = Trim(Request.Form("question"))

    If question <> "" Then
        Dim http, requestBody, responseText

        ' Escape the question for JSON
        Dim escaped
        escaped = Replace(question, "\", "\\")
        escaped = Replace(escaped, """", "\""")
        escaped = Replace(escaped, Chr(13), "\n")
        escaped = Replace(escaped, Chr(10), "\n")
        requestBody = "{""question"":""" & escaped & """}"

        Set http = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")

        On Error Resume Next
        http.open "POST", AI_SERVER_URL & "/chat", False
        http.setRequestHeader "Content-Type", "application/json"
        http.setRequestHeader "Accept", "application/json"
        http.send requestBody

        If Err.Number <> 0 Then
            answer = "Error de conexion con el servidor de IA: " & Err.Description
            confidence = "error"
        ElseIf http.status = 200 Then
            responseText = http.responseText
            answer = ExtractJsonField(responseText, "answer")
            confidence = ExtractJsonField(responseText, "confidence")
            responseTimeMs = ExtractJsonField(responseText, "response_time_ms")
        Else
            answer = "Error del servidor: HTTP " & http.status
            confidence = "error"
        End If

        Set http = Nothing
        On Error GoTo 0
    End If
End If

' Extract a string field value from simple JSON
Function ExtractJsonField(jsonStr, fieldName)
    Dim startPos, endPos, search
    search = """" & fieldName & """:"
    startPos = InStr(jsonStr, search)
    If startPos = 0 Then
        ExtractJsonField = ""
        Exit Function
    End If
    startPos = startPos + Len(search)

    ' Check if value is a string (starts with ")
    If Mid(jsonStr, startPos, 1) = """" Then
        startPos = startPos + 1
        endPos = startPos
        Do While endPos <= Len(jsonStr)
            Dim ch
            ch = Mid(jsonStr, endPos, 1)
            If ch = """" And Mid(jsonStr, endPos-1, 1) <> "\" Then Exit Do
            endPos = endPos + 1
        Loop
        Dim val
        val = Mid(jsonStr, startPos, endPos - startPos)
        val = Replace(val, "\n", Chr(13) & Chr(10))
        val = Replace(val, "\"& """", """")
        ExtractJsonField = val
    Else
        ' Numeric or boolean value
        endPos = startPos
        Do While endPos <= Len(jsonStr)
            Dim c
            c = Mid(jsonStr, endPos, 1)
            If c = "," Or c = "}" Or c = "]" Then Exit Do
            endPos = endPos + 1
        Loop
        ExtractJsonField = Trim(Mid(jsonStr, startPos, endPos - startPos))
    End If
End Function
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chatbot Empresarial</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: Arial, sans-serif; background: #f0f2f5; min-height: 100vh; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        h1 { color: #1a237e; margin-bottom: 6px; font-size: 24px; }
        .subtitle { color: #666; font-size: 13px; margin-bottom: 24px; }
        .card { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 1px 4px rgba(0,0,0,.1); margin-bottom: 16px; }
        label { display: block; font-weight: bold; color: #333; margin-bottom: 8px; }
        textarea { width: 100%; min-height: 90px; padding: 10px 12px; border: 1px solid #ddd; border-radius: 6px; font-size: 14px; resize: vertical; font-family: inherit; }
        textarea:focus { outline: none; border-color: #3f51b5; box-shadow: 0 0 0 2px rgba(63,81,181,.15); }
        .btn { background: #3f51b5; color: white; border: none; padding: 10px 28px; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: bold; margin-top: 10px; }
        .btn:hover { background: #303f9f; }
        .q-display { font-size: 13px; color: #888; margin-bottom: 12px; }
        .q-display strong { color: #333; }
        .answer-header { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; font-weight: bold; color: #333; }
        .badge { padding: 2px 10px; border-radius: 20px; font-size: 11px; font-weight: bold; text-transform: uppercase; letter-spacing: .5px; }
        .badge-high { background: #e8f5e9; color: #2e7d32; }
        .badge-low  { background: #fff3e0; color: #e65100; }
        .badge-none { background: #fce4ec; color: #c62828; }
        .answer-text { line-height: 1.7; font-size: 14px; white-space: pre-wrap; color: #333; padding: 14px; border-radius: 6px; background: #fafafa; border-left: 4px solid #3f51b5; }
        .answer-text.none { border-left-color: #ef5350; background: #fff5f5; }
        .answer-text.low  { border-left-color: #ff9800; }
        .warn { color: #e65100; font-size: 12px; margin-top: 8px; }
        .timing { color: #aaa; font-size: 11px; margin-top: 10px; text-align: right; }
        .footer { text-align: center; color: #bbb; font-size: 11px; margin-top: 32px; }
    </style>
</head>
<body>
<div class="container">
    <h1>Chatbot Empresarial</h1>
    <p class="subtitle">Consultas sobre documentacion interna</p>

    <div class="card">
        <form method="post" action="chat.asp">
            <label for="q">¿En qué puedo ayudarte?</label>
            <textarea id="q" name="question" placeholder="Escribe tu pregunta sobre la documentación interna..."><%=Server.HTMLEncode(question)%></textarea>
            <button class="btn" type="submit">Consultar</button>
        </form>
    </div>

    <% If answer <> "" Then %>
    <div class="card">
        <% If question <> "" Then %>
        <p class="q-display">Pregunta: <strong><%=Server.HTMLEncode(question)%></strong></p>
        <% End If %>

        <div class="answer-header">
            Respuesta
            <% If confidence = "high" Then %>
                <span class="badge badge-high">Alta confianza</span>
            <% ElseIf confidence = "low" Then %>
                <span class="badge badge-low">Baja confianza</span>
            <% ElseIf confidence = "none" Then %>
                <span class="badge badge-none">Sin contexto</span>
            <% End If %>
        </div>

        <div class="answer-text <%=confidence%>"><%=Server.HTMLEncode(answer)%></div>

        <% If confidence = "low" Then %>
        <p class="warn">⚠ Confianza baja — verifica la respuesta en los documentos originales.</p>
        <% End If %>

        <% If responseTimeMs <> "" Then %>
        <p class="timing">Tiempo de respuesta: <%=responseTimeMs%> ms</p>
        <% End If %>
    </div>
    <% End If %>

    <div class="footer">Chatbot RAG Empresarial — Solo responde con información de la documentación interna</div>
</div>
</body>
</html>
