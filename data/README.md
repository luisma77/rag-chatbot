# Organización de `data/`

Esta carpeta contiene los documentos que quieras indexar para tus bots RAG.

## Idea importante

La carpeta física puede ser compartida, pero **la forma de organizarla afecta a cómo te aclaras tú** y a cómo podremos mejorar el routing documental en futuras versiones.

No es obligatorio usar una estructura concreta. Puedes:

- dejar todos los documentos juntos
- separarlos por tipo
- separarlos por cliente
- separarlos por departamento
- separarlos por proyecto
- combinar varios criterios

## Estructura sugerida

```text
data/
├── README.md
├── documents/
│   ├── documentacion/
│   ├── manuales/
│   ├── facturas/
│   ├── clientes/
│   └── otros/
```

## Recomendación práctica

Si es para empresa, suele funcionar mejor separar como mínimo por grandes dominios:

- `documentacion/`
- `manuales/`
- `facturas/`
- `clientes/`
- `otros/`

Dentro de cada carpeta puedes crear más subcarpetas libremente.

Ejemplos:

- `documents/clientes/cliente-a/contratos/`
- `documents/facturas/2026/`
- `documents/manuales/maquinaria/`
- `documents/documentacion/procedimientos/`

## Qué debe hacer el usuario

- crear las carpetas que le resulten útiles para organizarse
- copiar ahí los documentos que quiere que el bot lea e indexe
- mantener nombres y rutas que tengan sentido para su negocio

## Nota sobre variantes

Aunque la documentación física pueda compartirse, **cada variante del proyecto puede indexar con embeddings, chunking o pipelines distintos**.

Por eso:

- cada perfil tiene ya su propio helper de reindexado
- cada perfil usa su propia colección Chroma por defecto
- en futuras sesiones podremos evolucionar a varios bots y varios índices por dominio documental
