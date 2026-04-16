<%@ Language="VBScript" %>
<%
' ingest.asp — Admin page to trigger document re-indexing from ASP
' IMPORTANT: Restrict access to admin users in IIS (Windows Authentication or IP restriction)
'
' CONFIGURATION: Change AI_SERVER_URL to your AI server IP
Const AI_SERVER_URL = "http://IP_SERVIDOR_IA:8000"

Dim action, result, statusClass
action = Request.QueryString("action")
result = ""
statusClass = ""

If action = "ingest" Or action = "reindex" Then
    Dim http, endpoint
    endpoint = "/ingest"
    If action = "reindex" Then endpoint = "/reindex"

    Set http = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")
    On Error Resume Next

    http.open "POST", AI_SERVER_URL & endpoint, False
    http.setRequestHeader "Content-Type", "application/json"
    http.send "{}"

    If Err.Number <> 0 Then
        result = "Error de conexion: " & Err.Description
        statusClass = "error"
    ElseIf http.status = 200 Then
        result = http.responseText
        statusClass = "success"
    Else
        result = "Error HTTP " & http.status & ": " & http.responseText
        statusClass = "error"
    End If

    Set http = Nothing
    On Error GoTo 0
End If

' Get current stats
Dim statsHttp, vectorCount
vectorCount = "?"
Set statsHttp = Server.CreateObject("MSXML2.ServerXMLHTTP.6.0")
On Error Resume Next
statsHttp.open "GET", AI_SERVER_URL & "/stats", False
statsHttp.send
If statsHttp.status = 200 Then
    Dim statsJson
    statsJson = statsHttp.responseText
    Dim startPos, endPos
    startPos = InStr(statsJson, """chromadb_vectors"":") + Len("""chromadb_vectors"":")
    If startPos > Len("""chromadb_vectors"":") Then
        endPos = startPos
        Do While endPos <= Len(statsJson)
            Dim c : c = Mid(statsJson, endPos, 1)
            If c = "," Or c = "}" Then Exit Do
            endPos = endPos + 1
        Loop
        vectorCount = Trim(Mid(statsJson, startPos, endPos - startPos))
    End If
End If
Set statsHttp = Nothing
On Error GoTo 0
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Administracion — Indexacion</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 700px; margin: 40px auto; padding: 0 20px; background: #f5f5f5; }
        h1 { color: #1a237e; }
        .card { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 1px 4px rgba(0,0,0,.1); margin-bottom: 16px; }
        .stats { display: flex; gap: 20px; margin-bottom: 20px; }
        .stat-box { background: #e8eaf6; border-radius: 8px; padding: 14px 20px; text-align: center; }
        .stat-num { font-size: 28px; font-weight: bold; color: #3f51b5; }
        .stat-label { font-size: 12px; color: #666; }
        .btn { display: inline-block; padding: 10px 22px; margin: 6px 4px; border-radius: 6px; text-decoration: none; color: white; font-weight: bold; font-size: 14px; cursor: pointer; }
        .btn-blue { background: #3f51b5; }
        .btn-blue:hover { background: #303f9f; }
        .btn-orange { background: #e65100; }
        .btn-orange:hover { background: #bf360c; }
        .result-box { padding: 14px; border-radius: 6px; margin-top: 16px; font-family: monospace; font-size: 12px; white-space: pre-wrap; overflow-x: auto; }
        .success { background: #e8f5e9; border-left: 4px solid #4caf50; color: #1b5e20; }
        .error { background: #fce4ec; border-left: 4px solid #ef5350; color: #b71c1c; }
        .warn { background: #fff3e0; border: 1px solid #ffb74d; border-radius: 6px; padding: 12px; color: #e65100; font-size: 13px; margin-top: 12px; }
    </style>
</head>
<body>
    <h1>Administracion — Indexacion</h1>

    <div class="card">
        <div class="stats">
            <div class="stat-box">
                <div class="stat-num"><%=vectorCount%></div>
                <div class="stat-label">Vectores indexados</div>
            </div>
        </div>

        <a href="ingest.asp?action=ingest" class="btn btn-blue">Indexar nuevos documentos</a>
        <a href="ingest.asp?action=reindex" class="btn btn-orange"
           onclick="return confirm('¿Confirmas que deseas borrar y regenerar todo el indice?\n\nEsto puede tardar varios minutos.')">
            Reindexar todo (desde cero)
        </a>

        <div class="warn">
            <strong>Nota:</strong> El reindexado completo borra todos los embeddings y los regenera.
            El chatbot sigue disponible durante el proceso. Los nuevos documentos aparecen al finalizar.
        </div>

        <% If result <> "" Then %>
        <div class="result-box <%=statusClass%>"><%=Server.HTMLEncode(result)%></div>
        <% End If %>
    </div>

    <p style="text-align:center;color:#aaa;font-size:11px">
        Servidor IA: <%=AI_SERVER_URL%>
    </p>
</body>
</html>
