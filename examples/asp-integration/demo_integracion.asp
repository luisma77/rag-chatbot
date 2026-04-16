<%@ Language="VBScript" %>
<%
'
' demo_integracion.asp — Demo completa: intranet con el widget de chat embebido
'
' COMO INTEGRAR EN UNA PAGINA REAL (3 pasos):
'
'   PASO 1 — Copiar archivos
'     Copia chat_api.ASP y chat_widget.js a la misma carpeta de tu pagina ASP.
'     Edita las constantes CHATBOT_URL y API_KEY en chat_api.ASP.
'
'   PASO 2 — Añadir el div contenedor
'     Pega el div #rag-chat-aqui donde quieras que aparezca el chat en tu pagina.
'
'   PASO 3 — Cargar el widget
'     Copia el bloque <script>window.RAGChatConfig...</script> + <script src="chat_widget.js">
'     justo antes del </body> de tu pagina (o justo despues del div contenedor).
'
' Para usar modo flotante (boton en esquina) en lugar de embebido:
'     Cambia mode:'embedded' por mode:'floating' y elimina el div contenedor.
'     El boton aparecera en la esquina inferior derecha de todas las paginas donde
'     cargues el script.
'
Option Explicit
Response.CodePage  = 65001
Response.Charset   = "utf-8"
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Portal Intranet — Consulta Documental IA</title>
  <style>
    /* ── Reset y base ── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: "Segoe UI", Arial, sans-serif;
      font-size: 14px;
      color: #333;
      background: #f0f2f7;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }
    a { color: #1e3a5f; text-decoration: none; }
    a:hover { text-decoration: underline; }

    /* ── Header ── */
    .site-header {
      background: #1e3a5f;
      color: #fff;
      padding: 0 28px;
      height: 58px;
      display: flex;
      align-items: center;
      gap: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.18);
      flex-shrink: 0;
    }
    .site-header .logo {
      font-size: 20px;
      font-weight: 800;
      letter-spacing: 2px;
      color: #fff;
      white-space: nowrap;
    }
    .site-header .portal-name {
      font-size: 13px;
      opacity: 0.75;
      border-left: 1px solid rgba(255,255,255,0.3);
      padding-left: 16px;
      white-space: nowrap;
    }
    .site-header nav {
      margin-left: auto;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .site-header nav a {
      color: rgba(255,255,255,0.82);
      font-size: 13px;
      padding: 5px 11px;
      border-radius: 5px;
      transition: background 0.15s;
    }
    .site-header nav a:hover { background: rgba(255,255,255,0.12); text-decoration: none; }
    .site-header .user-pill {
      background: rgba(255,255,255,0.15);
      color: #fff;
      font-size: 12px;
      padding: 5px 12px;
      border-radius: 20px;
      white-space: nowrap;
      margin-left: 10px;
    }

    /* ── Layout principal ── */
    .site-body {
      display: flex;
      flex: 1;
      max-width: 1300px;
      width: 100%;
      margin: 0 auto;
      padding: 0;
    }

    /* ── Sidebar ── */
    .sidebar {
      width: 210px;
      flex-shrink: 0;
      background: #1e3a5f;
      padding: 24px 0;
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    .sidebar-section {
      padding: 7px 22px 4px;
      font-size: 10px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: rgba(255,255,255,0.45);
    }
    .sidebar a {
      display: flex;
      align-items: center;
      gap: 9px;
      color: rgba(255,255,255,0.78);
      padding: 9px 22px;
      font-size: 13px;
      transition: background 0.15s, color 0.15s;
      border-left: 3px solid transparent;
    }
    .sidebar a:hover {
      background: rgba(255,255,255,0.08);
      color: #fff;
      text-decoration: none;
    }
    .sidebar a.active {
      background: rgba(255,255,255,0.12);
      color: #fff;
      border-left-color: #7fa8d8;
      font-weight: 600;
    }
    .sidebar .nav-icon { font-size: 15px; width: 18px; text-align: center; }

    /* ── Contenido principal ── */
    .main-content {
      flex: 1;
      padding: 28px 32px;
      overflow-y: auto;
      min-width: 0;
    }

    /* Breadcrumb */
    .breadcrumb {
      font-size: 12px;
      color: #7a8599;
      margin-bottom: 18px;
    }
    .breadcrumb span { color: #999; margin: 0 5px; }

    /* Título de sección */
    .page-title {
      font-size: 22px;
      font-weight: 700;
      color: #1e3a5f;
      margin-bottom: 6px;
    }
    .page-desc {
      font-size: 14px;
      color: #5a6480;
      margin-bottom: 24px;
      line-height: 1.55;
      max-width: 660px;
    }

    /* ── Sección del chat ── */
    .chat-section {
      background: #fff;
      border-radius: 14px;
      padding: 24px;
      margin-bottom: 30px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.06);
    }
    .chat-section-title {
      font-size: 15px;
      font-weight: 600;
      color: #1e3a5f;
      margin-bottom: 16px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .chat-section-title::before {
      content: '';
      display: inline-block;
      width: 4px; height: 18px;
      background: #1e3a5f;
      border-radius: 2px;
    }

    /* ── Cards de documentos ── */
    .docs-section-title {
      font-size: 15px;
      font-weight: 600;
      color: #1e3a5f;
      margin-bottom: 16px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .docs-section-title::before {
      content: '';
      display: inline-block;
      width: 4px; height: 18px;
      background: #4a7fb5;
      border-radius: 2px;
    }
    .docs-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
    }
    .doc-card {
      background: #fff;
      border: 1px solid #dce3f0;
      border-radius: 10px;
      padding: 18px 20px;
      width: calc(50% - 8px);
      min-width: 220px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.05);
      transition: box-shadow 0.18s, transform 0.18s;
      cursor: default;
    }
    .doc-card:hover {
      box-shadow: 0 4px 14px rgba(30,58,95,0.12);
      transform: translateY(-2px);
    }
    .doc-card-icon { font-size: 26px; margin-bottom: 8px; display: block; }
    .doc-card-title {
      font-size: 14px;
      font-weight: 600;
      color: #1e3a5f;
      margin-bottom: 4px;
    }
    .doc-card-desc {
      font-size: 12px;
      color: #6b778c;
      line-height: 1.45;
    }

    /* ── Footer ── */
    .site-footer {
      background: #1e3a5f;
      color: rgba(255,255,255,0.55);
      text-align: center;
      font-size: 12px;
      padding: 14px 20px;
      flex-shrink: 0;
    }
  </style>
</head>
<body>

  <!-- ══ HEADER ══ -->
  <header class="site-header">
    <div class="logo">EMPRESA</div>
    <div class="portal-name">Portal del Empleado</div>
    <nav>
      <a href="#">Inicio</a>
      <a href="#">Noticias</a>
      <a href="#">Formación</a>
      <a href="#">Soporte</a>
    </nav>
    <div class="user-pill">&#128100; Juan García</div>
  </header>

  <!-- ══ CUERPO ══ -->
  <div class="site-body">

    <!-- ── Sidebar ── -->
    <nav class="sidebar">
      <div class="sidebar-section">Menú principal</div>
      <a href="#"><span class="nav-icon">&#127968;</span> Inicio</a>
      <a href="#" class="active"><span class="nav-icon">&#128196;</span> Documentación</a>
      <a href="#"><span class="nav-icon">&#128101;</span> RRHH</a>
      <a href="#"><span class="nav-icon">&#128227;</span> Comunicación</a>
      <div class="sidebar-section" style="margin-top:10px;">Soporte</div>
      <a href="#"><span class="nav-icon">&#10067;</span> Ayuda</a>
    </nav>

    <!-- ── Contenido principal ── -->
    <main class="main-content">

      <div class="breadcrumb">
        Inicio <span>&rsaquo;</span> Documentación <span>&rsaquo;</span> Consulta Documental IA
      </div>

      <h1 class="page-title">Consulta Documental</h1>
      <p class="page-desc">
        Utiliza el asistente de inteligencia artificial para consultar la documentación interna de la empresa:
        manuales, políticas, procedimientos y normativa vigente. Las respuestas se generan a partir de los
        documentos oficiales indexados.
      </p>

      <!-- ── Sección del chat ── -->
      <div class="chat-section">
        <div class="chat-section-title">Asistente Documental IA</div>

        <!--
          INTEGRACION DEL CHAT WIDGET
          ===========================
          1. Este div es el contenedor donde se renderiza el widget.
             Puedes cambiar el ancho, alto y estilos según tu diseño.
          2. El bloque <script>window.RAGChatConfig...</script> configura el widget.
          3. El <script src="chat_widget.js"> carga e inicializa el widget.
        -->
        <div id="rag-chat-aqui" style="width:100%;max-width:700px;height:550px;margin:0 auto;border:1px solid #dce3f0;border-radius:12px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)"></div>

        <script>
          window.RAGChatConfig = {
            apiUrl:       'chat_api.ASP',
            title:        'Asistente Documental',
            subtitle:     'IA local \u00b7 Documentaci\u00f3n interna',
            primaryColor: '#1e3a5f',
            mode:         'embedded',
            containerId:  'rag-chat-aqui',
            greeting:     'Hola, soy el asistente de documentaci\u00f3n interna. Puedo responder preguntas sobre manuales, pol\u00edticas y procedimientos. \u00bfEn qu\u00e9 te ayudo?',
            logoText:     'IA',
          };
        </script>
        <script src="chat_widget.js"></script>

      </div>

      <!-- ── Cards de documentos ── -->
      <div class="docs-section-title">Documentos disponibles</div>
      <div class="docs-grid">

        <div class="doc-card">
          <span class="doc-card-icon">&#128196;</span>
          <div class="doc-card-title">Manual del Empleado</div>
          <div class="doc-card-desc">Normativa interna, procedimientos y beneficios para todos los trabajadores de la empresa.</div>
        </div>

        <div class="doc-card">
          <span class="doc-card-icon">&#128202;</span>
          <div class="doc-card-title">Política de Teletrabajo</div>
          <div class="doc-card-desc">Normativa y procedimientos sobre trabajo remoto y flexibilidad horaria.</div>
        </div>

        <div class="doc-card">
          <span class="doc-card-icon">&#128203;</span>
          <div class="doc-card-title">Manual del Empleado</div>
          <div class="doc-card-desc">Guía para nuevos empleados: primeros pasos, recursos disponibles y contactos clave.</div>
        </div>

        <div class="doc-card">
          <span class="doc-card-icon">&#128209;</span>
          <div class="doc-card-title">Política Integrada</div>
          <div class="doc-card-desc">Calidad, medioambiente y seguridad. Compromisos y objetivos estratégicos de la organización.</div>
        </div>

      </div>

    </main>
  </div>

  <!-- ══ FOOTER ══ -->
  <footer class="site-footer">
    &copy; <%= Year(Now()) %> Empresa S.A. &mdash; Portal del Empleado &mdash; Todos los derechos reservados
  </footer>

</body>
</html>

