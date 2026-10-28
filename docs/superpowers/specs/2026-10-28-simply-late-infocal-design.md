# Simply late! + Infocal Hybrid Watchface Design Specification

**Date:** 2026-10-28  
**Target Platform:** Garmin Connect IQ (Fenix 6 / 6S / 6 Pro / 6X Pro — `240x240`, `260x260`, `280x280`, plus existing round targets in `manifest.xml`)  
**Repository:** `d:\Work\Coding\Infocal`

---

## 1. Overview & Goals

Combine the clean, ultra-glanceable visual design of **Simply late!** (`myneur/late`) with the rich on-device activity/sensor data fields of **Infocal**, adding a live **Moon Phase** indicator and a minimalist **Notification Counter** (`1–9` / `9+`).

Key objectives:
1. **Simply late! Visual Clarity:** Preserve Simply late!'s signature layout — center Hour with radial Minute Progress Arc and orbiting minute number, outer 24h/12h Weather Forecast ring, Calendar Event ring, Sunrise/Sunset/Now markers, upper-left precipitation (`mm`), upper-right temperature with min-max range bar (`12°-16`), and bottom 2-line Next Calendar Event readout.
2. **Top Row Enhancement (`[Notif]  WED 28  [Moon Phase]`):**
   - **Left of Date:** Plain, unboxed notification counter showing `1` through `9`, or `9+` when notifications exceed 9 (hidden when `0`). Defaults to subtle secondary gray (`#AAAAAA`), with a user setting to customize its color.
   - **Center:** Formatted Date (`WED 28` or user-configured date format).
   - **Right of Date:** Crisp vector **Moon Phase** indicator computed on-device from the current lunar cycle.
3. **Stacked Left & Right Data Slots (Infocal Metrics):**
   - Two configurable metric slots on the Left (`topLeftMetric`, `bottomLeftMetric`) and two on the Right (`topRightMetric`, `bottomRightMetric`), supporting Infocal's rich data sources: Live Heart Rate, Daily Steps, Battery `%`, Battery in Days (using Infocal's hourly consumption history), Altitude, Barometric Pressure, Calories, Active Minutes (Day/Week), and Floors Climbed.
4. **Free, Direct `yr.no` Weather & Direct Google Calendar OAuth2:**
   - Fetch 24h hourly weather forecasts directly from **Open-Meteo's MET Norway (`yr.no`) API** (`https://api.open-meteo.com/v1/metno`) with no paid middleware or API key required.
   - Fetch upcoming Google Calendar events directly on-watch via **Google OAuth2 Device Flow** (`https://oauth2.googleapis.com/device/code` & `https://oauth2.googleapis.com/token`), automatically picking up any new events added in the future.

---

## 2. Architecture & Memory Budget

Garmin Fenix 6 devices enforce strict runtime memory limits:
- **WatchFace View process:** ~92 KB RAM
- **Background ServiceDelegate process:** 32 KB RAM

To stay well within these limits and avoid `-403` Out-Of-Memory errors during JSON parsing:
- **View Rendering (`HuwaiiView.mc`):** Replace Infocal's 60 rotated bitmap fonts (`e0`–`e60`) and analog tile tables (`hour_1`–`minu_6`) with direct single-pass `Toybox.Graphics.Dc` rendering (arcs, lines, polygons, and 3 compact bitmap/system fonts: `Hours`, `Small`, `Condensed`, plus `Ico` for icons). This frees ~40–45 KB of runtime RAM.
- **Data Layer (`DataFactory.mc`):** Retain Infocal's lightweight sensor/metric calculation helpers (Heart Rate, Steps, Battery % / Days estimate, Altitude, Barometer, Calories, Active Minutes, Floors) and expose a compact formatting interface for the 4 side slots.
- **Astronomical Layer (`SunMoonCompute.mc`):**
  - **Sunrise / Sunset:** Port `sunrisetCompute.mc` from `myneur/late` to calculate local sunrise and sunset hours from cached GPS coordinates.
  - **Moon Phase:** Calculate lunar age (`0.0` to `29.530588853` days from known New Moon reference epoch `2000-01-06 18:14 UTC`) and render the illuminated crescent/gibbous/full disc directly onto `dc` using arc/chord shading at `(dateRightX, dateY)`.
- **Background Service (`BackgroundService.mc`):**
  - Alternates between **Google Calendar** and **yr.no Weather** requests on 5-minute retry / 30–60 minute steady-state intervals.
  - Flattens responses inside `BackgroundService` before calling `Background.exit(...)` so the payload crossing into the main app is `< 1.5 KB`.

---

## 3. Visual Layout & Component Geometry

All coordinates scale proportionally from `centerX` (`dc.getWidth() / 2`), `centerY` (`dc.getHeight() / 2`), and `height` (`dc.getHeight()`), supporting `240x240` (Fenix 6S), `260x260` (Fenix 6 / 6 Pro), and `280x280` (Fenix 6X Pro):

| Zone | Element | Position & Rendering Details |
|------|---------|------------------------------|
| **Bezel Edge (`r = centerY - 2`)** | **24h / 12h Weather Forecast Ring** | Pen width `5` (`8` on `390x390`). Draws hourly arc segments `450 - h*step` to `450 - (h+1)*step` (`step = 15°` in 24h mode, `30°` in 12h mode) colored by `meteoColors` (`0`: Clear `#FFAA00`, `1`: Partly Cloudy `#AA5500`, `2`: Light Rain `#005555`, `3`: Heavy Rain `#00AAFF`, `4`: Light Snow `#AAAAAA`, `5`: Heavy Snow `#FFFFFF`, `6`: Clear Night `#555500`). |
| **Inner Bezel (`r = centerY - 8`)** | **Calendar Event Ring** | Pen width `8`. Draws arcs from `450 - fromAngle` to `450 - toAngle` for each upcoming event within the 12h/24h window, colored by `calendarColors` per calendar index with a `1°` background separator gap at event start. |
| **Ring Markers (`r = sunR`)** | **Sunrise, Sunset & Now Circle** | Sunrise (`*`) and Sunset (`(`) icons drawn at their computed angles; current time drawn as a `4px` filled circle with a `5px` background halo at the current hour+minute angle on the 12h/24h ring. |
| **Top Row (`y = dateY`)** | **Notification Count, Date & Moon Phase** | - **Center (`centerX`):** Formatted Date string (e.g., `WED 28`) in `fontSmall` (`#FFFFFF`).<br>- **Left (`centerX - dateWidth/2 - 8`):** Notification count (`1`..`9` or `9+` when `notificationCount > 9`; omitted when `0`) right-justified in `notifColor` (default `#AAAAAA`, configurable in settings).<br>- **Right (`centerX + dateWidth/2 + 12`):** Live **Moon Phase** disc (`r = 6px`), with dark lunar disc outline and lit phase region corresponding to current lunar age. |
| **Upper Left (`x = 0.22 * width, y = 0.27 * height`)** | **Precipitation (`mm`)** | Shown when 24h precipitation sum `> 0.5 mm`: rounded `mm` integer in `activityColor` (`#AAAAAA`) with `"mm"` label in `dimmedColor` (`#555555`) below it. |
| **Upper Right (`x = 0.76 * width, y = 0.27 * height`)** | **Temperature & Min-Max Range Bar** | Current temperature (`12°`) paired with daily min or max (`-16`), plus a horizontal range line underneath and a `3px` indicator dot marking where current temperature sits between `min` and `max`. |
| **Center (`centerX, centerY`)** | **Hybrid Hour + Minute Progress Arc** | - **Center Hour:** Current hour (`00`–`23` or `1`–`12`) in `fontHours` centered at `(centerX, centerY)`.<br>- **Minute Arc (`r = radius`):** Colored arc (`mainColor`) from `90°` clockwise to `90° - minutes * 6° + kerningOffset`.<br>- **Orbiting Minute Number:** Current minute (`0`–`59`) in `fontSmall` positioned along `radius` at angle `minutes / 60 * 2π`. |
| **Left & Right Sides (`x = 0.17 * width` & `0.83 * width`)** | **Stacked Data Slots (2 Left, 2 Right)** | Upper line (`centerY - 6`) and lower line (`centerY + 12`) on each side. Each slot is independently configurable (`Empty`, `Heart Rate`, `Steps`, `Battery %`, `Battery Days`, `Altitude`, `Barometer`, `Calories`, `Active Min`, `Floors`). |
| **Bottom (`y = messageY`)** | **Next Calendar Event & Low Battery** | - **Line 1:** Event summary (truncated to 21 chars on `<=260px` screens) or OAuth login prompt (`google.com/device`).<br>- **Line 2:** Relative countdown (`now!`, `22m`, `1h15`, or `HH:MM`) in `dateColor` + `: Location` in `activityColor` (or OAuth `user_code`).<br>- **Low Battery Icon (`batteryY`):** Drawn when battery `<= batThreshold` (default `33%`). |

---

## 4. External APIs & Background Data Pipeline

### 4.1 Weather Forecast: Open-Meteo `metno` (`yr.no`)
- **Endpoint:** `https://api.open-meteo.com/v1/metno`
- **Query Parameters:**
  - `latitude`: `gLocationLat` (from `Position.getInfo()` / `Activity.getActivityInfo().currentLocation` / stored property)
  - `longitude`: `gLocationLng`
  - `hourly`: `"temperature_2m,precipitation,weather_code"`
  - `forecast_hours`: `24`
  - `temperature_unit`: `"celsius"` or `"fahrenheit"` (based on user setting / device units)
- **Background Transformation (`onReceiveWeather`):**
  - Extracts `hourly["temperature_2m"]` (24 floats), `hourly["precipitation"]` (24 floats), and `hourly["weather_code"]` (24 WMO codes).
  - Computes:
    - `currentTemp = Math.round(temps[0]).toNumber()`
    - `minTemp = Math.round(min(temps[0..15])).toNumber()`
    - `maxTemp = Math.round(max(temps[0..15])).toNumber()`
    - `totalPrecip = sum(precip[0..hours-1])`
  - Maps each hourly WMO `weather_code` to Simply late!'s `0..5` condition codes:
    - `0, 1` → `0` (Clear)
    - `2` → `1` (Partly cloudy)
    - `3, 45, 48` → `-1` (Overcast / Fog — uncolored gap on ring, matching Simply late!)
    - `51, 53, 55, 56, 57, 61, 80` → `2` (Light rain / drizzle / showers)
    - `63, 65, 66, 67, 81, 82, 95, 96, 99` → `3` (Rain / heavy rain / thunderstorm)
    - `71, 77, 85` → `4` (Light snow)
    - `73, 75, 86` → `5` (Snow / heavy snow)
  - Returns `{"weather" => [currentHour, currentTemp, minTemp, maxTemp, totalPrecip, code0, code1, ..., code23]}`.

### 4.2 Google Calendar: Direct OAuth2 Device Flow
- **Settings Properties:**
  - `google_client_id` (String): User's Google Cloud OAuth 2.0 Client ID (TV and Limited-Input devices type).
  - `google_client_secret` (String): User's Google Cloud OAuth 2.0 Client Secret.
  - `calendar_ids` (String): Comma-separated calendar IDs (optional; defaults to the user's `primary` calendar if left blank).
- **Authentication & Polling Flow in `BackgroundService`:**
  1. If `refresh_token` is not stored and `user_code` is not active, POST to `https://oauth2.googleapis.com/device/code` with `client_id` and `scope=https://www.googleapis.com/auth/calendar.readonly`.
  2. Return `{"user_code" => ..., "verification_url" => ..., "device_code" => ...}` to the watchface so the bottom text displays `google.com/device` and the `user_code`.
  3. On subsequent 5-minute background ticks, POST to `https://oauth2.googleapis.com/token` with `device_code` and `grant_type=urn:ietf:params:oauth:grant-type:device_code` until the user approves access, yielding `access_token` and `refresh_token`.
  4. Persist `refresh_token` in properties/storage. On future background runs, exchange `refresh_token` for a fresh `access_token` and GET `https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events` with `singleEvents=true`, `orderBy=startTime`, `timeMin=now`, `timeMax=now+24h`, `maxResults=6`, and `fields=items(summary,location,start/dateTime,end/dateTime)`.
  5. Trim event strings (`summary` up to 23 chars, `location` up to 10 chars before comma) in `BackgroundService` and return the compact `events` array to the watchface.

---

## 5. User Settings (`properties.xml` & `settings.xml`)

Clean, intuitive settings in Garmin Connect Mobile:
1. **Main Accent Color (`mainColor`):** Red, Yellow/Orange, Green, Blue, Violet, Gray.
2. **Color Tone / Theme (`tone`):** Dark (Black BG), Dimmed Dark, High-Contrast Dark, White BG, Colored BG.
3. **Notification Counter Color (`notifColor`):** Subtle Gray (`#AAAAAA` — default), Accent Color, White, Yellow, Red.
4. **Show Moon Phase (`showMoon`):** Boolean (default `true`).
5. **Dial Mode (`d24`):** 12-Hour Ring vs 24-Hour Ring for Weather/Calendar arcs.
6. **Minute Circle Thickness (`boldness`):** 1–5 (default `2`).
7. **Show Weather Forecast (`weather`):** Boolean (default `true`).
8. **Temperature Units (`temp_unit`):** Auto (Device), Celsius, Fahrenheit.
9. **Show Sunrise / Sunset (`sunriset`):** Boolean (default `true`).
10. **Left Upper Slot (`slot_tl`), Left Lower Slot (`slot_bl`), Right Upper Slot (`slot_tr`), Right Lower Slot (`slot_br`):** Empty, Heart Rate, Steps, Battery %, Battery Days, Altitude, Barometer, Calories, Active Minutes, Floors.
11. **Calendar Enable (`enable_calendar`):** Boolean (default `true`).
12. **Google OAuth Client ID (`google_client_id`), Client Secret (`google_client_secret`), and Calendar IDs (`calendar_ids`).**

---

## 6. Error Handling & Edge Cases

- **No GPS Fix Yet:** Falls back to last saved `LastLocationLat`/`LastLocationLng` in properties; if never acquired, displays a subtle `"No GPS"` hint in the bottom message area when weather/sun is enabled.
- **OAuth / Network Errors:**
  - During initial Google login (`refresh_token == null`), shows `"Wait4login"` / `"NoInternet"` / `"google.com/device + code"`.
  - Once authenticated (`refresh_token != null`), transient Bluetooth or HTTP errors silently retain the last cached `events_list` and `weatherHourly` so the watchface stays clean and uninterrupted.
- **Background Payload Overflow (`-403` / `-402`):** If a calendar response exceeds background memory, `BackgroundService` automatically reduces `maxResults` and retries on the next temporal event.
- **Zero Notifications:** When `System.getDeviceSettings().notificationCount == 0`, nothing is drawn to the left of the date; when `1..9`, the digit is drawn; when `>= 10`, `"9+"` is drawn.

---

## 7. Verification & Testing Plan

1. **Build Verification:** Compile the Connect IQ project for `fenix6` (`260x260`), `fenix6s` (`240x240`), and `fenix6xpro` (`280x280`) using the Connect IQ SDK compiler (`monkeyc`) with zero errors.
2. **Memory & Layout Verification:**
   - Verify runtime memory usage stays well below the Fenix 6 watchface limit (~92 KB) and background service limit (32 KB).
   - Verify rendering of:
     - Top row: `1–9` and `9+` notification counts, Date (`WED 28`), and Moon Phase across lunar ages (`0`, `7.4`, `14.8`, `22.1` days).
     - Outer rings: 24h/12h Weather Forecast arcs, Calendar Event arcs, Sunrise/Sunset markers, and Now dot.
     - Upper readouts: `mm` precipitation and `12°-16` temperature range bar.
     - Center & Sides: Hour + Minute Progress Arc + 4 configurable Infocal metric slots.
     - Bottom: Next Calendar Event countdown + location and OAuth device login prompt.
