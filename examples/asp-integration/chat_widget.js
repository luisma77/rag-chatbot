/**
 * chat_widget.js — Widget de chat embebible para RAG Chatbot
 *
 * Uso (modo flotante):
 *   <script>
 *     window.RAGChatConfig = { apiUrl: 'chat_api.ASP', mode: 'floating' };
 *   </script>
 *   <script src="chat_widget.js"></script>
 *
 * Uso (modo embebido):
 *   <div id="rag-chat-widget" style="width:100%;height:520px;"></div>
 *   <script>
 *     window.RAGChatConfig = { apiUrl: 'chat_api.ASP', mode: 'embedded' };
 *   </script>
 *   <script src="chat_widget.js"></script>
 *
 * Compatible IE11+. No dependencias externas.
 */
(function () {
  'use strict';

  // ──────────────────────────────────────────────────────────
  // 1. CONFIGURACION
  // ──────────────────────────────────────────────────────────
  var userCfg = window.RAGChatConfig || {};

  var cfg = {
    apiUrl:       userCfg.apiUrl       !== undefined ? userCfg.apiUrl       : '',
    title:        userCfg.title        !== undefined ? userCfg.title        : 'Asistente IA',
    subtitle:     userCfg.subtitle     !== undefined ? userCfg.subtitle     : '',
    placeholder:  userCfg.placeholder  !== undefined ? userCfg.placeholder  : 'Escribe tu pregunta...',
    primaryColor: userCfg.primaryColor !== undefined ? userCfg.primaryColor : '#5b7cf7',
    mode:         userCfg.mode         !== undefined ? userCfg.mode         : 'floating',
    position:     userCfg.position     !== undefined ? userCfg.position     : 'bottom-right',
    width:        userCfg.width        !== undefined ? userCfg.width        : '380px',
    height:       userCfg.height       !== undefined ? userCfg.height       : '520px',
    greeting:     userCfg.greeting     !== undefined ? userCfg.greeting     : '',
    logoText:     userCfg.logoText     !== undefined ? userCfg.logoText     : 'IA',
    containerId:  userCfg.containerId  !== undefined ? userCfg.containerId  : 'rag-chat-widget'
  };

  // ──────────────────────────────────────────────────────────
  // 2. SESSION ID
  // ──────────────────────────────────────────────────────────
  var sessionId;
  try {
    sessionId = sessionStorage.getItem('rag_session_id');
    if (!sessionId) {
      sessionId = 'rag_' + Math.random().toString(36).substr(2, 9) + '_' + Date.now();
      sessionStorage.setItem('rag_session_id', sessionId);
    }
  } catch (e) {
    sessionId = 'rag_' + Math.random().toString(36).substr(2, 9);
  }

  // ──────────────────────────────────────────────────────────
  // 3. INYECTAR CSS
  // ──────────────────────────────────────────────────────────
  var css = [
    ':root {',
    '  --rag-primary:     ' + cfg.primaryColor + ';',
    '  --rag-bg:          #ffffff;',
    '  --rag-bot-bubble:  #f1f3f9;',
    '  --rag-user-bubble: ' + cfg.primaryColor + ';',
    '  --rag-text:        #1a1a2e;',
    '  --rag-border:      #e2e8f0;',
    '  --rag-radius:      14px;',
    '}',

    /* Tema oscuro */
    '.rag-dark {',
    '  --rag-bg:         #1a1d2e;',
    '  --rag-bot-bubble: #252840;',
    '  --rag-text:       #e8eaf6;',
    '  --rag-border:     #363a52;',
    '}',

    /* Botón flotante */
    '.rag-fab {',
    '  position: fixed;',
    '  width: 56px;',
    '  height: 56px;',
    '  border-radius: 50%;',
    '  background: var(--rag-primary);',
    '  border: none;',
    '  cursor: pointer;',
    '  box-shadow: 0 4px 16px rgba(0,0,0,0.22);',
    '  display: flex;',
    '  align-items: center;',
    '  justify-content: center;',
    '  z-index: 99998;',
    '  transition: transform 0.2s, box-shadow 0.2s;',
    '  color: #fff;',
    '  font-size: 22px;',
    '  font-family: Arial, sans-serif;',
    '  outline: none;',
    '}',
    '.rag-fab:hover { transform: scale(1.08); box-shadow: 0 6px 22px rgba(0,0,0,0.28); }',
    '.rag-fab-br { bottom: 24px; right: 24px; }',
    '.rag-fab-bl { bottom: 24px; left: 24px; }',

    /* Panel flotante */
    '.rag-panel-floating {',
    '  position: fixed;',
    '  z-index: 99999;',
    '  width: ' + cfg.width + ';',
    '  height: ' + cfg.height + ';',
    '  display: flex;',
    '  flex-direction: column;',
    '  border-radius: 16px;',
    '  overflow: hidden;',
    '  box-shadow: 0 8px 40px rgba(0,0,0,0.22);',
    '  background: var(--rag-bg);',
    '  border: 1px solid var(--rag-border);',
    '  transform: translateY(20px);',
    '  opacity: 0;',
    '  pointer-events: none;',
    '  transition: transform 0.28s cubic-bezier(.4,0,.2,1), opacity 0.28s;',
    '}',
    '.rag-panel-floating.rag-open {',
    '  transform: translateY(0);',
    '  opacity: 1;',
    '  pointer-events: auto;',
    '}',
    '.rag-panel-floating.rag-pos-br { bottom: 92px; right: 24px; }',
    '.rag-panel-floating.rag-pos-bl { bottom: 92px; left: 24px; }',

    /* Panel embebido */
    '.rag-panel-embedded {',
    '  display: flex;',
    '  flex-direction: column;',
    '  width: 100%;',
    '  height: 100%;',
    '  background: var(--rag-bg);',
    '  border-radius: inherit;',
    '  overflow: hidden;',
    '}',

    /* Header */
    '.rag-header {',
    '  display: flex;',
    '  align-items: center;',
    '  gap: 10px;',
    '  padding: 12px 14px;',
    '  background: var(--rag-primary);',
    '  color: #fff;',
    '  flex-shrink: 0;',
    '}',
    '.rag-logo {',
    '  width: 36px; height: 36px;',
    '  border-radius: 50%;',
    '  background: rgba(255,255,255,0.22);',
    '  display: flex; align-items: center; justify-content: center;',
    '  font-weight: 700; font-size: 13px;',
    '  flex-shrink: 0;',
    '  font-family: Arial, sans-serif;',
    '}',
    '.rag-header-info { flex: 1; min-width: 0; }',
    '.rag-title {',
    '  font-size: 15px; font-weight: 700;',
    '  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;',
    '  font-family: "Segoe UI", Arial, sans-serif;',
    '}',
    '.rag-subtitle {',
    '  font-size: 11px; opacity: 0.82;',
    '  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;',
    '  font-family: "Segoe UI", Arial, sans-serif;',
    '}',
    '.rag-btn-icon {',
    '  background: none; border: none; cursor: pointer;',
    '  color: #fff; font-size: 18px;',
    '  width: 30px; height: 30px;',
    '  display: flex; align-items: center; justify-content: center;',
    '  border-radius: 6px; opacity: 0.82;',
    '  transition: opacity 0.15s, background 0.15s;',
    '  flex-shrink: 0; outline: none;',
    '}',
    '.rag-btn-icon:hover { opacity: 1; background: rgba(255,255,255,0.15); }',

    /* Area de mensajes */
    '.rag-messages {',
    '  flex: 1;',
    '  overflow-y: auto;',
    '  padding: 14px 12px;',
    '  display: flex;',
    '  flex-direction: column;',
    '  gap: 10px;',
    '  background: var(--rag-bg);',
    '  color: var(--rag-text);',
    '}',
    '.rag-messages::-webkit-scrollbar { width: 5px; }',
    '.rag-messages::-webkit-scrollbar-track { background: transparent; }',
    '.rag-messages::-webkit-scrollbar-thumb { background: var(--rag-border); border-radius: 3px; }',

    /* Burbujas */
    '.rag-msg {',
    '  display: flex;',
    '  align-items: flex-end;',
    '  gap: 7px;',
    '  max-width: 88%;',
    '  animation: ragFadeIn 0.22s ease;',
    '}',
    '@keyframes ragFadeIn { from { opacity:0; transform:translateY(6px); } to { opacity:1; transform:translateY(0); } }',
    '.rag-msg-bot { align-self: flex-start; }',
    '.rag-msg-user { align-self: flex-end; flex-direction: row-reverse; }',
    '.rag-avatar {',
    '  width: 28px; height: 28px;',
    '  border-radius: 50%;',
    '  background: var(--rag-primary);',
    '  color: #fff;',
    '  display: flex; align-items: center; justify-content: center;',
    '  font-size: 11px; font-weight: 700;',
    '  flex-shrink: 0;',
    '  font-family: Arial, sans-serif;',
    '}',
    '.rag-bubble {',
    '  padding: 9px 13px;',
    '  border-radius: var(--rag-radius);',
    '  font-size: 14px;',
    '  line-height: 1.55;',
    '  word-break: break-word;',
    '  font-family: "Segoe UI", Arial, sans-serif;',
    '}',
    '.rag-bubble-bot {',
    '  background: var(--rag-bot-bubble);',
    '  color: var(--rag-text);',
    '  border-bottom-left-radius: 4px;',
    '}',
    '.rag-bubble-user {',
    '  background: var(--rag-user-bubble);',
    '  color: #fff;',
    '  border-bottom-right-radius: 4px;',
    '}',

    /* Typing indicator */
    '.rag-typing {',
    '  display: flex;',
    '  align-items: center;',
    '  gap: 4px;',
    '  padding: 10px 13px;',
    '}',
    '.rag-typing span {',
    '  width: 7px; height: 7px;',
    '  border-radius: 50%;',
    '  background: var(--rag-primary);',
    '  opacity: 0.6;',
    '  display: inline-block;',
    '  animation: ragBounce 1.1s infinite;',
    '}',
    '.rag-typing span:nth-child(2) { animation-delay: 0.18s; }',
    '.rag-typing span:nth-child(3) { animation-delay: 0.36s; }',
    '@keyframes ragBounce {',
    '  0%, 80%, 100% { transform: translateY(0); opacity: 0.5; }',
    '  40%           { transform: translateY(-7px); opacity: 1; }',
    '}',

    /* Input area */
    '.rag-input-area {',
    '  display: flex;',
    '  align-items: flex-end;',
    '  gap: 8px;',
    '  padding: 10px 12px;',
    '  border-top: 1px solid var(--rag-border);',
    '  background: var(--rag-bg);',
    '  flex-shrink: 0;',
    '}',
    '.rag-textarea {',
    '  flex: 1;',
    '  resize: none;',
    '  border: 1px solid var(--rag-border);',
    '  border-radius: 10px;',
    '  padding: 8px 11px;',
    '  font-size: 14px;',
    '  font-family: "Segoe UI", Arial, sans-serif;',
    '  background: var(--rag-bg);',
    '  color: var(--rag-text);',
    '  outline: none;',
    '  line-height: 1.45;',
    '  max-height: 100px;',
    '  overflow-y: auto;',
    '  transition: border-color 0.15s;',
    '}',
    '.rag-textarea:focus { border-color: var(--rag-primary); }',
    '.rag-btn-send {',
    '  width: 38px; height: 38px;',
    '  border-radius: 10px;',
    '  background: var(--rag-primary);',
    '  border: none;',
    '  cursor: pointer;',
    '  color: #fff;',
    '  display: flex; align-items: center; justify-content: center;',
    '  flex-shrink: 0;',
    '  font-size: 17px;',
    '  transition: opacity 0.15s, transform 0.15s;',
    '  outline: none;',
    '}',
    '.rag-btn-send:hover { opacity: 0.88; transform: scale(1.06); }',
    '.rag-btn-send:disabled { opacity: 0.45; cursor: default; transform: none; }'
  ].join('\n');

  var styleEl = document.createElement('style');
  styleEl.setAttribute('type', 'text/css');
  if (styleEl.styleSheet) {
    styleEl.styleSheet.cssText = css; // IE
  } else {
    styleEl.appendChild(document.createTextNode(css));
  }
  document.head.appendChild(styleEl);

  // ──────────────────────────────────────────────────────────
  // 4. CONSTRUIR HTML
  // ──────────────────────────────────────────────────────────

  function buildPanel(panelClass) {
    var panel = document.createElement('div');
    panel.className = panelClass;

    /* Header */
    var header = document.createElement('div');
    header.className = 'rag-header';

    var logo = document.createElement('div');
    logo.className = 'rag-logo';
    logo.textContent = cfg.logoText;

    var info = document.createElement('div');
    info.className = 'rag-header-info';

    var titleEl = document.createElement('div');
    titleEl.className = 'rag-title';
    titleEl.textContent = cfg.title;

    info.appendChild(titleEl);

    if (cfg.subtitle) {
      var subtitleEl = document.createElement('div');
      subtitleEl.className = 'rag-subtitle';
      subtitleEl.textContent = cfg.subtitle;
      info.appendChild(subtitleEl);
    }

    var btnClear = document.createElement('button');
    btnClear.className = 'rag-btn-icon';
    btnClear.title = 'Limpiar historial';
    btnClear.innerHTML = '&#128465;'; // 🗑

    header.appendChild(logo);
    header.appendChild(info);
    header.appendChild(btnClear);

    /* Si es flotante, añadir botón cerrar */
    var btnClose = null;
    if (panelClass.indexOf('floating') !== -1) {
      btnClose = document.createElement('button');
      btnClose.className = 'rag-btn-icon';
      btnClose.title = 'Cerrar';
      btnClose.innerHTML = '&#10005;'; // ×
      header.appendChild(btnClose);
    }

    /* Mensajes */
    var messagesEl = document.createElement('div');
    messagesEl.className = 'rag-messages';

    /* Input area */
    var inputArea = document.createElement('div');
    inputArea.className = 'rag-input-area';

    var textarea = document.createElement('textarea');
    textarea.className = 'rag-textarea';
    textarea.rows = 1;
    textarea.placeholder = cfg.placeholder;

    var btnSend = document.createElement('button');
    btnSend.className = 'rag-btn-send';
    btnSend.title = 'Enviar';
    btnSend.innerHTML = '&#10148;'; // ➤

    inputArea.appendChild(textarea);
    inputArea.appendChild(btnSend);

    panel.appendChild(header);
    panel.appendChild(messagesEl);
    panel.appendChild(inputArea);

    return {
      panel:      panel,
      messages:   messagesEl,
      textarea:   textarea,
      btnSend:    btnSend,
      btnClear:   btnClear,
      btnClose:   btnClose
    };
  }

  // ──────────────────────────────────────────────────────────
  // 5. FORMATEO BASICO
  // ──────────────────────────────────────────────────────────

  function formatText(text) {
    /* Escapar HTML primero para evitar XSS */
    text = text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
    /* **negrita** */
    text = text.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    /* Saltos de línea */
    text = text.replace(/\n/g, '<br>');
    return text;
  }

  // ──────────────────────────────────────────────────────────
  // 6. LOGICA DE MENSAJES
  // ──────────────────────────────────────────────────────────

  function initChat(elements) {
    var messagesEl = elements.messages;
    var textarea   = elements.textarea;
    var btnSend    = elements.btnSend;
    var btnClear   = elements.btnClear;
    var waiting    = false;

    function scrollToBottom() {
      messagesEl.scrollTop = messagesEl.scrollHeight;
    }

    function addMessage(text, type) {
      var msgDiv = document.createElement('div');
      msgDiv.className = 'rag-msg rag-msg-' + type;

      var avatar = document.createElement('div');
      avatar.className = 'rag-avatar';
      avatar.textContent = type === 'bot' ? cfg.logoText : 'Tú';

      var bubble = document.createElement('div');
      bubble.className = 'rag-bubble rag-bubble-' + type;
      bubble.innerHTML = formatText(text);

      msgDiv.appendChild(avatar);
      msgDiv.appendChild(bubble);
      messagesEl.appendChild(msgDiv);
      scrollToBottom();
      return bubble;
    }

    function showTyping() {
      var msgDiv = document.createElement('div');
      msgDiv.className = 'rag-msg rag-msg-bot';
      msgDiv.id = 'rag-typing-' + sessionId;

      var avatar = document.createElement('div');
      avatar.className = 'rag-avatar';
      avatar.textContent = cfg.logoText;

      var bubble = document.createElement('div');
      bubble.className = 'rag-bubble rag-bubble-bot rag-typing';
      bubble.innerHTML = '<span></span><span></span><span></span>';

      msgDiv.appendChild(avatar);
      msgDiv.appendChild(bubble);
      messagesEl.appendChild(msgDiv);
      scrollToBottom();
    }

    function hideTyping() {
      var el = document.getElementById('rag-typing-' + sessionId);
      if (el && el.parentNode) {
        el.parentNode.removeChild(el);
      }
    }

    /* Fetch con fallback XHR para IE11 */
    function postMensaje(mensaje, callback) {
      var body = 'mensaje=' + encodeURIComponent(mensaje);
      var url  = cfg.apiUrl;

      if (typeof window.fetch === 'function') {
        window.fetch(url, {
          method:  'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body:    body
        })
        .then(function (res) { return res.text(); })
        .then(function (text) { callback(null, text); })
        .catch(function (err) { callback(err, null); });
      } else {
        /* Fallback XMLHttpRequest (IE11) */
        var xhr = new XMLHttpRequest();
        xhr.open('POST', url, true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onreadystatechange = function () {
          if (xhr.readyState === 4) {
            if (xhr.status === 200) {
              callback(null, xhr.responseText);
            } else {
              callback(new Error('HTTP ' + xhr.status), null);
            }
          }
        };
        xhr.onerror = function () { callback(new Error('Error de red'), null); };
        xhr.send(body);
      }
    }

    function sendMessage() {
      if (waiting) return;
      var text = textarea.value.replace(/^\s+|\s+$/g, '');
      if (!text) return;

      addMessage(text, 'user');
      textarea.value = '';
      textarea.style.height = 'auto';

      waiting = true;
      btnSend.disabled = true;
      showTyping();

      postMensaje(text, function (err, respuesta) {
        hideTyping();
        waiting = false;
        btnSend.disabled = false;

        if (err || !respuesta) {
          addMessage('Error al conectar con el asistente. Por favor, inténtalo de nuevo.', 'bot');
        } else {
          addMessage(respuesta.replace(/^\s+|\s+$/g, ''), 'bot');
        }
      });
    }

    /* Evento enviar botón */
    btnSend.addEventListener('click', sendMessage);

    /* Enter envía, Shift+Enter nueva línea */
    textarea.addEventListener('keydown', function (e) {
      if (e.keyCode === 13 && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });

    /* Auto-resize textarea */
    textarea.addEventListener('input', function () {
      this.style.height = 'auto';
      this.style.height = Math.min(this.scrollHeight, 100) + 'px';
    });

    /* Botón limpiar */
    btnClear.addEventListener('click', function () {
      while (messagesEl.firstChild) {
        messagesEl.removeChild(messagesEl.firstChild);
      }
      if (cfg.greeting) {
        addMessage(cfg.greeting, 'bot');
      }
    });

    /* Mensaje de bienvenida */
    if (cfg.greeting) {
      addMessage(cfg.greeting, 'bot');
    }
  }

  // ──────────────────────────────────────────────────────────
  // 7. MONTAR EL WIDGET
  // ──────────────────────────────────────────────────────────

  function mount() {
    if (cfg.mode === 'embedded') {
      /* ── MODO EMBEBIDO ── */
      var container = document.getElementById(cfg.containerId);
      if (!container) {
        return; // contenedor no existe todavía — no hacer nada
      }

      var elements = buildPanel('rag-panel-embedded');
      container.appendChild(elements.panel);
      initChat(elements);

    } else {
      /* ── MODO FLOTANTE ── */
      var posClass = cfg.position === 'bottom-left' ? 'rag-pos-bl' : 'rag-pos-br';
      var fabPosClass = cfg.position === 'bottom-left' ? 'rag-fab-bl' : 'rag-fab-br';

      var elements = buildPanel('rag-panel-floating ' + posClass);
      document.body.appendChild(elements.panel);

      var fab = document.createElement('button');
      fab.className = 'rag-fab ' + fabPosClass;
      fab.title = cfg.title;
      fab.setAttribute('aria-label', 'Abrir chat');
      fab.innerHTML = '&#128172;'; // 💬
      document.body.appendChild(fab);

      var isOpen = false;

      function openPanel() {
        isOpen = true;
        elements.panel.classList.add('rag-open');
        fab.innerHTML = '&#8722;'; // −
        fab.setAttribute('aria-label', 'Cerrar chat');
        elements.textarea.focus();
      }

      function closePanel() {
        isOpen = false;
        elements.panel.classList.remove('rag-open');
        fab.innerHTML = '&#128172;';
        fab.setAttribute('aria-label', 'Abrir chat');
      }

      fab.addEventListener('click', function () {
        if (isOpen) { closePanel(); } else { openPanel(); }
      });

      if (elements.btnClose) {
        elements.btnClose.addEventListener('click', closePanel);
      }

      initChat(elements);
    }
  }

  /* Esperar a que el DOM esté listo */
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', mount);
  } else {
    mount();
  }

})();
