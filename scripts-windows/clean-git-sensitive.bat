@echo off
chcp 65001 > nul
cd /d "%~dp0.."
echo.
echo === Eliminando archivos privados del seguimiento de git ===
echo.

echo [1/4] Quitando documentos PDF del indice de git...
git rm -r --cached "data/documents/" 2>nul
if %errorlevel%==0 (echo    OK: documentos eliminados del indice) else (echo    INFO: data/documents no estaba en el indice)

echo [2/4] Quitando embeddings ChromaDB del indice de git...
git rm -r --cached "chroma_db/" 2>nul
if %errorlevel%==0 (echo    OK: chroma_db eliminado del indice) else (echo    INFO: chroma_db no estaba en el indice)

echo [3/4] Quitando .env del indice de git...
git rm --cached ".env" 2>nul
if %errorlevel%==0 (echo    OK: .env eliminado del indice) else (echo    INFO: .env no estaba en el indice)

echo [4/4] Quitando __pycache__ del indice de git...
for /d /r . %%d in (__pycache__) do (
    git rm -r --cached "%%d" 2>nul
)
echo    OK: pycache procesado

echo.
echo === Creando commit de limpieza ===
git add .gitignore
git add data/documents/.gitkeep
git add chroma_db/.gitkeep
git commit -m "security: remove private docs and embeddings from git tracking

- Added .gitignore to exclude data/documents/, chroma_db/, .env
- Added .gitkeep placeholders to preserve directory structure
- PDFs and vector embeddings stay local only"

echo.
echo === Listo ===
echo Los archivos privados ya NO se subiran al repositorio.
echo Tus PDFs y embeddings siguen en disco, solo se han excluido del git.
echo.
pause
