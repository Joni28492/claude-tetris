---
name: clima
description: >
  Consulta la temperatura y el estado del tiempo actual de una ciudad
  ejecutando localmente un script Python (sin API key, usa la API pública
  de Open-Meteo). Ciudad por defecto: Avilés, Asturias. Usar cuando el
  usuario pida "el tiempo", "clima", "temperatura en...", "qué tiempo hace
  en...", o pida comprobar/monitorizar el clima de una ciudad.
---

Esta skill obtiene el clima actual ejecutando un script local en lugar de
usar búsqueda web — es rápido, no gasta llamadas de WebSearch/WebFetch y no
requiere API key.

## Uso

Ejecuta el script con Bash pasando la ciudad como argumento:

```bash
python .claude/skills/clima/scripts/clima.py "Aviles, Asturias"
```

Si el usuario no especifica ciudad, ejecútalo sin argumentos — usa por
defecto "Aviles, Asturias, Espana":

```bash
python .claude/skills/clima/scripts/clima.py
```

El script:
1. Geocodifica el nombre de la ciudad con la API de geocoding de Open-Meteo.
2. Pide el tiempo actual (temperatura, sensación térmica, humedad, viento,
   precipitación y estado del cielo) a la API de forecast de Open-Meteo.
3. Imprime un resumen legible en español.

Si la ciudad no se encuentra, el script termina con el mensaje
`No se encontro la ciudad: <nombre>` — pide al usuario que aclare o
prueba con un nombre más específico (añadiendo provincia/país).

## Presentación al usuario

Resume la salida del script en una frase o pocas líneas (temperatura,
sensación, estado del cielo); no hace falta pegar la salida completa del
script salvo que el usuario pida el detalle (humedad, viento, etc.).

## Uso recurrente / monitorización

Si el usuario pide vigilar el clima periódicamente (p. ej. con `/loop`),
esta skill es el paso a ejecutar en cada iteración — sigue siendo una
llamada local rápida, así que es apta para intervalos frecuentes.
