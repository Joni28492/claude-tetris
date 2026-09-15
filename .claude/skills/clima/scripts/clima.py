#!/usr/bin/env python3
"""Consulta el tiempo actual de una ciudad usando la API pública de Open-Meteo.

No requiere API key. Uso:
    python clima.py ["Ciudad, Pais"]

Sin argumentos usa "Aviles, Asturias, Espana" por defecto.
"""

import json
import sys
import urllib.parse
import urllib.request

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

DEFAULT_CITY = "Aviles, Asturias, Espana"

WEATHER_CODES = {
    0: "despejado",
    1: "principalmente despejado",
    2: "parcialmente nublado",
    3: "nublado",
    45: "niebla",
    48: "niebla con escarcha",
    51: "llovizna ligera",
    53: "llovizna moderada",
    55: "llovizna intensa",
    56: "llovizna helada ligera",
    57: "llovizna helada intensa",
    61: "lluvia ligera",
    63: "lluvia moderada",
    65: "lluvia intensa",
    66: "lluvia helada ligera",
    67: "lluvia helada intensa",
    71: "nevada ligera",
    73: "nevada moderada",
    75: "nevada intensa",
    77: "granos de nieve",
    80: "chubascos ligeros",
    81: "chubascos moderados",
    82: "chubascos violentos",
    85: "chubascos de nieve ligeros",
    86: "chubascos de nieve intensos",
    95: "tormenta",
    96: "tormenta con granizo ligero",
    99: "tormenta con granizo intenso",
}


def fetch_json(url):
    with urllib.request.urlopen(url, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))


def geocode(city):
    url = (
        "https://geocoding-api.open-meteo.com/v1/search?"
        + urllib.parse.urlencode({"name": city, "count": 1, "language": "es"})
    )
    data = fetch_json(url)
    results = data.get("results") or []
    if not results:
        raise SystemExit(f"No se encontro la ciudad: {city}")
    r = results[0]
    return r["latitude"], r["longitude"], r.get("name", city), r.get("admin1", ""), r.get("country", "")


def current_weather(lat, lon):
    url = (
        "https://api.open-meteo.com/v1/forecast?"
        + urllib.parse.urlencode(
            {
                "latitude": lat,
                "longitude": lon,
                "current": ",".join(
                    [
                        "temperature_2m",
                        "apparent_temperature",
                        "relative_humidity_2m",
                        "weather_code",
                        "wind_speed_10m",
                        "wind_direction_10m",
                        "precipitation",
                    ]
                ),
                "timezone": "auto",
            }
        )
    )
    return fetch_json(url)


def main():
    city = " ".join(sys.argv[1:]).strip() or DEFAULT_CITY
    lat, lon, name, admin1, country = geocode(city)
    data = current_weather(lat, lon)
    cur = data["current"]

    code = cur.get("weather_code")
    condition = WEATHER_CODES.get(code, f"codigo desconocido ({code})")

    lugar = ", ".join(p for p in [name, admin1, country] if p)

    print(f"Tiempo en {lugar}")
    print(f"  Temperatura:      {cur['temperature_2m']} C (sensacion {cur['apparent_temperature']} C)")
    print(f"  Estado:           {condition}")
    print(f"  Humedad relativa: {cur['relative_humidity_2m']}%")
    print(f"  Viento:           {cur['wind_speed_10m']} km/h, direccion {cur['wind_direction_10m']} grados")
    print(f"  Precipitacion:    {cur['precipitation']} mm")
    print(f"  Hora local datos: {cur['time']}")


if __name__ == "__main__":
    main()
