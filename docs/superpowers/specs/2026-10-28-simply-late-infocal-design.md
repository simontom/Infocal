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
   - **Left of Date:** Plain, unboxed notification counter showing `1` through `9`, or `9+` when notifications exceed 9 (hidden when `0`). Defaults to subtle secondary gray (`#AAAAAA`), with a user setting (`notifColor`) to customize its color.
   - **Center:** Formatted Date (`WED 28` or user-configured `date_format`).
   - **Right of Date:** Crisp vector **Moon Phase** indicator computed on-device from the current lunar cycle.
3. **Stacked Left & Right Data Slots (Infocal Metrics):**
   - Two configurable metric slots on the Left (`slot_tl`, `slot_bl`) and two on the Right (`slot_tr`, `slot_br`), supporting Infocal's rich data sources: Live Heart Rate, Daily Steps, Battery `%`, Battery in Days (using Infocal's hourly consumption history), Altitude, Barometric Pressure, Calories, Active Minutes (Week), and Floors Climbed.
   - Each slot uses a compact label format (`<= 6` characters in `Rez.Fonts.smadigi`) so side readouts fit cleanly inside the 56 px corridor between the Calendar Event Ring and the center Minute Progress Arc.
4. **Free, Direct `yr.no` Weather & Direct Google Calendar OAuth2:**
   - Fetch 24h hourly weather forecasts directly from **Open-Meteo's MET Norway (`yr.no`) API** (`https://api.open-meteo.com/v1/metno`) with no paid middleware or API key required.
   - Fetch upcoming Google Calendar events directly on-watch via **Google OAuth2 Device Flow** (`https://oauth2.googleapis.com/device/code` & `https://oauth2.googleapis.com/token`), automatically picking up any new events added in the future.

---

## 2. Architecture & Memory Budget

Garmin Fenix 6 devices enforce strict runtime memory limits:
- **WatchFace View process:** ~92 KB RAM
- **Background ServiceDelegate process:** 32 KB RAM

To stay well within these limits and avoid `-403` Out-Of-Memory errors during JSON parsing:
- **View Rendering (`HuwaiiView.mc`):**
  - Remove Infocal's 60 rotated bitmap fonts (`e0`–`e60`), analog tile fonts (`hour_1`–`minu_6`), and their JSON lookup tables across `resources/fonts/fonts.xml`, `resources/jsons/resources.xml`, `resources/layouts/layout.xml`, and all resolution-specific `resources-round-*/` directories.
  - Render the watchface in a single pass onto `Toybox.Graphics.Dc` using only two bitmap fonts from `Rez.Fonts` (`bigdigi` for the center hour and `smadigi` for uppercase/numeric readouts), system `Graphics.FONT_XTINY` for mixed-case calendar text (`google.com/device`, event summaries, locations), and vector `Dc` primitives for arcs, moon phase, sunrise/sunset markers, and the low-battery indicator. This frees ~40–45 KB of runtime RAM.
- **Data Layer (`DataFactory.mc`):**
  - Retain Infocal's sensor/metric calculation helpers and add a compact formatting helper (`getCompactSlotText(slotType)`) that returns `<= 6` uppercase characters suitable for `Rez.Fonts.smadigi`:
    - `0` (Empty): `""`
    - `1` (Heart Rate): `"72"` or `"--"`
    - `2` (Steps): `"8420"` (`<10000`) or `"12.4K"` (`>=10000`)
    - `3` (Battery `%`): `"85%"`
    - `4` (Battery Days): `"12.5D"` (falls back to `"85%"` until 1h consumption sample exists)
    - `5` (Altitude): `"425M"` or `"1394F"`
    - `6` (Barometer): `"1013+"`, `"1013-"`, or `"29.9+"`
    - `7` (Calories): `"2.1K"`
    - `8` (Active Minutes): `"145M"`
    - `9` (Floors Climbed): `"12FL"`
- **Astronomical Layer (`SunMoonCompute.mc`):**
  - **Sunrise / Sunset:** Extract and fix `getSunTimes(lat, lng, tz, tomorrow)` from `DataFactory.mc` (fixing the `Date.info(now, Time.FORMAT_SHORT)` date calculation when `tomorrow == true`) to return `[sunriseHourFloat, sunsetHourFloat]`.
  - **Moon Phase:** Calculate lunar age (`0.0` to `29.530588853` days from New Moon reference epoch `2000-01-06 18:14 UTC`, Unix timestamp `947182440`). Render the moon disc of radius `r = 6` at `(moonX, dateY)` using horizontal scanlines (`dy = -r .. +r`):
    - Half-width at row `dy`: `dx = Math.sqrt(r * r - dy * dy)`
    - Terminator x-offset: `tx = Math.cos(phase * 2.0 * Math.PI) * dx`, where `phase = age / 29.530588853` (`0.0` = New, `0.5` = Full)
    - Waxing (`phase <= 0.5`): lit horizontal segment from `moonX + tx` to `moonX + dx`
    - Waning (`phase > 0.5`): lit horizontal segment from `moonX - dx` to `moonX - tx`
- **Background Service (`BackgroundService.mc`) & Storage Persistence:**
  - Connect IQ `ServiceDelegate` background processes cannot persist changes via `App.getApp().setProperty()` directly. All tokens (`refresh_token`, `device_code`, `user_code`), weather arrays, and calendar events are returned in the `Background.exit(payload)` dictionary and persisted to the Object Store inside `HuwaiiApp.onBackgroundData(data)` in the main process.
  - Alternates between **Google Calendar** and **yr.no Weather** requests on 5-minute retry / 30-minute steady-state intervals.
  - Supports both `HTTP_REQUEST_METHOD_GET` (weather & calendar events) and `HTTP_REQUEST_METHOD_POST` (Google OAuth2 device/token endpoints).

---

## 3. Visual Layout & Component Geometry

All coordinates scale proportionally from `width = dc.getWidth()`, `height = dc.getHeight()`, `centerX = width / 2`, and `centerY = height / 2`, supporting `218x218`, `240x240`, `260x260`, `280x280`, and `390x390`:

- **Key Proportional Constants:**
  - `weatherArcR = centerY - 3` (pen width `5`, or `8` on `390x390`)
  - `calArcR = centerY - 10` (pen width `6`, or `9` on `390x390`)
  - `sunR = centerY - 10`
  - `dateY = (0.14 * height).toNumber()`
  - `upperMetricY = (0.26 * height).toNumber()`
  - `minuteArcR = (0.21 * height).toNumber()`
  - `slotLeftX = (0.17 * width).toNumber()`, `slotRightX = (0.83 * width).toNumber()`
  - `slotTopY = centerY - (0.05 * height).toNumber()`, `slotBottomY = centerY + (0.05 * height).toNumber()`
  - `messageY = (0.71 * height).toNumber()`
  - `batteryY = (0.88 * height).toNumber()`

| Zone | Element | Position & Rendering Details |
|------|---------|------------------------------|
| **Bezel Edge (`r = weatherArcR`)** | **24h / 12h Weather Forecast Ring** | Draws hourly arc segments clockwise from `(450 - h*step) % 360` to `(450 - (h+1)*step) % 360` (`step = 15°` in 24h mode, `30°` in 12h mode) colored by `meteoColors` (`0`: Clear Day `#FFAA00`, `1`: Partly Cloudy `#AA5500`, `2`: Light Rain `#005555`, `3`: Heavy Rain `#00AAFF`, `4`: Light Snow `#AAAAAA`, `5`: Heavy Snow `#FFFFFF`, `6`: Clear Night `#555500`; `-1`: Overcast/Fog left uncolored). |
| **Inner Bezel (`r = calArcR`)** | **Calendar Event Ring** | Draws arcs clockwise from `(450 - fromAngle) % 360` to `(450 - toAngle) % 360` for each upcoming timed event within the 12h/24h window, colored by `mainColor` (or secondary palette) with a `1°` background separator gap at event start. |
| **Ring Markers (`r = sunR`)** | **Sunrise, Sunset & Now Circle** | Vector Sunrise (half-disc above horizon line) and Sunset (half-disc below horizon line) markers drawn at their computed angles; current time drawn as a `4px` filled circle with a `5px` background halo at the current hour+minute angle on the 12h/24h ring. |
| **Top Row (`y = dateY`)** | **Notification Count, Date & Moon Phase** | - **Center (`centerX`):** Formatted Date string (e.g., `WED 28`) in `smadigi` (`#FFFFFF`, `TEXT_JUSTIFY_CENTER \| TEXT_JUSTIFY_VCENTER`).<br>- **Left (`centerX - dateWidth/2 - 8`):** Notification count (`1`..`9` or `9+` when `notificationCount > 9`; omitted when `0`) in `smadigi` (`TEXT_JUSTIFY_RIGHT \| TEXT_JUSTIFY_VCENTER`) using `notifColor` (default `#AAAAAA`).<br>- **Right (`centerX + dateWidth/2 + 12`):** Live **Moon Phase** disc (`r = 6px`), with dark lunar disc outline (`#555555`) and scanline-shaded lit phase region (`#FFFFFF`) corresponding to current lunar age. |
| **Upper Left (`x = 0.23 * width, y = upperMetricY`)** | **Precipitation (`mm`)** | Shown when 24h precipitation sum `> 0.5 mm`: rounded `mm` integer in `smadigi` (`#AAAAAA`) with `"MM"` label in dimmed gray (`#555555`) below it. |
| **Upper Right (`x = 0.77 * width, y = upperMetricY`)** | **Temperature & Min-Max Range Bar** | Current temperature paired with 16h min/max (e.g. `12°-16`) in `smadigi`, plus a `28px` horizontal range line (`#555555`) underneath and a `3px` indicator dot (`#FFFFFF`) marking where current temperature sits between `minTemp` and `maxTemp`. |
| **Center (`centerX, centerY`)** | **Hybrid Hour + Minute Progress Arc** | - **Center Hour:** Current hour (`00`–`23` or `1`–`12`) in `bigdigi` centered at `(centerX, centerY)`.<br>- **Minute Arc (`r = minuteArcR`):** Colored arc (`mainColor`, pen width `boldness * 2`) from `90°` clockwise to `(450 - minutes * 6) % 360`.<br>- **Orbiting Minute Number:** Current minute (`00`–`59`) in `smadigi` positioned along `minuteArcR` at angle `minutes * 6°` with a background halo circle (`r = 9px`) so the arc never strikes through the digits. |
| **Left & Right Sides (`slotLeftX` & `slotRightX`)** | **Stacked Data Slots (2 Left, 2 Right)** | Upper line (`slotTopY`) and lower line (`slotBottomY`) on each side, rendered in `smadigi` (`TEXT_JUSTIFY_CENTER \| TEXT_JUSTIFY_VCENTER`). Each slot is independently configurable (`0`: Empty, `1`: Heart Rate, `2`: Steps, `3`: Battery %, `4`: Battery Days, `5`: Altitude, `6`: Barometer, `7`: Calories, `8`: Active Min, `9`: Floors). |
| **Bottom (`y = messageY`)** | **Next Calendar Event & Low Battery** | - **Line 1 (`messageY`):** Event summary (truncated to 20 chars) in `Graphics.FONT_XTINY` (`#FFFFFF`), or OAuth login prompt (`google.com/device`).<br>- **Line 2 (`messageY + 14`):** Relative countdown (`now!`, `22m`, `1h15`, or `HH:MM`) + `: Location` in `Graphics.FONT_XTINY` (`#AAAAAA`), or OAuth `user_code`.<br>- **Low Battery Icon (`batteryY`):** Vector battery outline (`16x8 px`) drawn at `(centerX, batteryY)` when battery `<= batThreshold` (default `33%`). |

---

## 4. External APIs & Background Data Pipeline

### 4.1 Weather Forecast: Open-Meteo `metno` (`yr.no`)
- **Endpoint:** `https://api.open-meteo.com/v1/metno` (`HTTP_REQUEST_METHOD_GET`)
- **Query Parameters:**
  - `latitude`: `LastLocationLat`
  - `longitude`: `LastLocationLng`
  - `hourly`: `"temperature_2m,precipitation,weather_code"`
  - `forecast_hours`: `24`
  - `timezone`: `"auto"`
  - `timeformat`: `"unixtime"` (avoids allocating 24 ISO-8601 strings in the 32 KB background heap)
  - `temperature_unit`: `"celsius"` or `"fahrenheit"` (resolved from `temp_unit` setting and `System.getDeviceSettings().temperatureUnits`)
- **Background Transformation (`onReceiveWeather`):**
  - Extracts `hourly["temperature_2m"]` (24 floats), `hourly["precipitation"]` (24 floats), and `hourly["weather_code"]` (24 WMO codes).
  - Computes:
    - `currentHour = System.getClockTime().hour`
    - `currentTemp = Math.round(temps[0]).toNumber()`
    - `minTemp = Math.round(min(temps[0..15])).toNumber()`
    - `maxTemp = Math.round(max(temps[0..15])).toNumber()`
    - `totalPrecip = Math.round(sum(precip[0..23])).toNumber()`
  - Maps each hourly WMO `weather_code` at index `i` (`hourOfDay = (currentHour + i) % 24`) to Simply late!'s condition codes (`-1..6`):
    - `0, 1` → `0` (Clear Day) if `hourOfDay` is between sunrise and sunset, or `6` (Clear Night) if nighttime
    - `2` → `1` (Partly cloudy)
    - `3, 45, 48` → `-1` (Overcast / Fog — uncolored gap on ring)
    - `51, 53, 55, 56, 57, 61, 80` → `2` (Light rain / drizzle / showers)
    - `63, 65, 66, 67, 81, 82, 95, 96, 99` → `3` (Rain / heavy rain / thunderstorm)
    - `71, 77, 85` → `4` (Light snow)
    - `73, 75, 86` → `5` (Snow / heavy snow)
  - Calls `Background.exit({"WeatherData" => [Time.now().value(), currentHour, currentTemp, minTemp, maxTemp, totalPrecip, code0, code1, ..., code23]})`.

### 4.2 Google Calendar: Direct OAuth2 Device Flow
- **Settings Properties:**
  - `google_client_id` (String): User's Google Cloud OAuth 2.0 Client ID (TV and Limited-Input devices type).
  - `google_client_secret` (String): User's Google Cloud OAuth 2.0 Client Secret.
  - `calendar_ids` (String): Calendar ID (optional; defaults to `"primary"` if blank; if comma-separated, uses the first non-empty ID per background cycle to stay within the 32 KB background heap).
- **Authentication & Polling Flow in `BackgroundService`:**
  1. **Step 1 — Request Device Code:** If `google_refresh_token` is empty and `google_device_code` is empty, `POST` (`REQUEST_CONTENT_TYPE_URL_ENCODED`) to `https://oauth2.googleapis.com/device/code` with `client_id` and `scope=https://www.googleapis.com/auth/calendar.readonly`.
     - Exit with `{"CalendarAuth" => {"device_code" => ..., "user_code" => ..., "verification_url" => "google.com/device"}}`.
  2. **Step 2 — Poll for User Approval:** If `google_refresh_token` is empty and `google_device_code` is present, `POST` to `https://oauth2.googleapis.com/token` with `client_id`, `client_secret`, `device_code`, and `grant_type=urn:ietf:params:oauth:grant-type:device_code`.
     - When HTTP 200 is returned with `refresh_token` and `access_token`, hold `refresh_token` in a member variable `mNewRefreshToken` and immediately invoke `fetchCalendarEvents(access_token)` in the same background run (or exit with `{"CalendarTokens" => {"refresh_token" => refresh_token}}` if memory is tight).
     - If HTTP 400/428 (`authorization_pending`), keep existing `device_code` and `user_code` active. If `expired_token`, clear `device_code` so Step 1 restarts on the next tick.
  3. **Step 3 — Refresh Token & Fetch Events:** When `google_refresh_token` is stored, `POST` to `https://oauth2.googleapis.com/token` with `client_id`, `client_secret`, `refresh_token`, and `grant_type=refresh_token`.
     - On HTTP 200, use `access_token` to `GET` `https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events` with:
       - `singleEvents`: `"true"`
       - `orderBy`: `"startTime"`
       - `timeMin`: current UTC time formatted as `"YYYY-MM-DDTHH:MM:00Z"`
       - `timeMax`: `now + 24h` formatted as `"YYYY-MM-DDTHH:MM:00Z"`
       - `maxResults`: `"6"`
       - `fields`: `"items(summary,location,start/dateTime,end/dateTime)"`
  4. **Step 4 — Event Parsing & Flattening:**
     - Skip any item where `item["start"] == null` or `item["start"]["dateTime"] == null` (safely ignoring all-day events that only have `start.date`).
     - Parse ISO-8601 `dateTime` (`"YYYY-MM-DDTHH:MM:SS±HH:MM"` or `"Z"`) into Unix epoch seconds using `Time.Gregorian.moment({...}).value() - tzOffsetSeconds`.
     - Trim `summary` to 20 chars and `location` to 12 chars (up to the first comma).
     - Return `{"CalendarData" => {"ts" => Time.now().value(), "refresh_token" => mNewRefreshToken, "events" => [[startEpoch, endEpoch, summary, location], ...]}}`.

---

## 5. User Settings (`properties.xml` & `settings.xml`)

All `resources*/settings/properties.xml` files will be unified (removing stale device-specific `properties.xml` overrides that lack the new keys) and configured with:

1. **Main Accent Color (`mainColor`):** `0` Red (`#FF0000`), `1` Orange/Yellow (`#FFAA00` — default), `2` Green (`#00FF00`), `3` Blue (`#00AAFF`), `4` Violet (`#AA00FF`), `5` White (`#FFFFFF`).
2. **Color Tone / Theme (`tone`):** `0` Dark (Black BG — default), `1` High-Contrast Dark, `2` Light (White BG).
3. **Notification Counter Color (`notifColor`):** `0` Subtle Gray (`#AAAAAA` — default), `1` Accent Color, `2` White (`#FFFFFF`), `3` Yellow (`#FFAA00`), `4` Red (`#FF5555`).
4. **Show Moon Phase (`showMoon`):** Boolean (default `true`).
5. **Dial Mode (`d24`):** `0` 24-Hour Ring (default), `1` 12-Hour Ring.
6. **Minute Circle Thickness (`boldness`):** `1`–`5` (default `2`).
7. **Show Weather Forecast (`weather`):** Boolean (default `true`).
8. **Temperature Units (`temp_unit`):** `0` Auto (Device — default), `1` Celsius, `2` Fahrenheit.
9. **Show Sunrise / Sunset (`sunriset`):** Boolean (default `true`).
10. **Left Upper Slot (`slot_tl`), Left Lower Slot (`slot_bl`), Right Upper Slot (`slot_tr`), Right Lower Slot (`slot_br`):**
    - `0`: Empty
    - `1`: Heart Rate (default for `slot_tl`)
    - `2`: Steps (default for `slot_bl`)
    - `3`: Battery `%` (default for `slot_tr`)
    - `4`: Battery Days (default for `slot_br`)
    - `5`: Altitude
    - `6`: Barometer
    - `7`: Calories
    - `8`: Active Minutes
    - `9`: Floors Climbed
11. **Date Format (`date_format`):** `0` `DAY DD` (`WED 28` — default), `1` `DD.MM`, `2` `MM.DD`, `5` `DD MON`, `6` `MON DD`.
12. **Force English Date (`force_date_english`):** Boolean (default `true`).
13. **Barometer Unit (`barometer_unit`):** `0` hPa (default), `1` inHg.
14. **Low Battery Threshold (`batThreshold`):** Number `10`–`50` (default `33`).
15. **Calendar Enable (`enable_calendar`):** Boolean (default `true`).
16. **Google OAuth Client ID (`google_client_id`), Client Secret (`google_client_secret`), and Calendar IDs (`calendar_ids`).**

---

## 6. Error Handling & Edge Cases

- **No GPS Fix Yet:** Falls back to last saved `LastLocationLat`/`LastLocationLng` in properties; if never acquired, displays a subtle `"No GPS"` hint in the bottom message area when weather/sun is enabled.
- **OAuth / Network Errors:**
  - During initial Google login (`google_refresh_token == ""`), shows `"google.com/device"` on Line 1 and `user_code` on Line 2 once device code is acquired.
  - Once authenticated (`google_refresh_token != ""`), transient Bluetooth or HTTP errors silently retain the last cached `CalendarData` and `WeatherData` so the watchface stays clean and uninterrupted.
- **All-Day Calendar Events:** Events without `start.dateTime` are skipped during background parsing so they never cause null-reference errors or clutter the 12h/24h radial clock ring.
- **Zero Notifications:** When `System.getDeviceSettings().notificationCount == 0`, nothing is drawn to the left of the date; when `1..9`, the digit is drawn; when `>= 10`, `"9+"` is drawn.

---

## 7. Verification & Testing Plan

1. **Unit & Self-Test Verification:** Include `:test` unit tests in `source/HybridTests.mc` verifying:
   - Lunar age & terminator calculation across New Moon (`0.0d`), First Quarter (`7.38d`), Full Moon (`14.77d`), and Third Quarter (`22.15d`).
   - Sunrise / Sunset calculation for known coordinates and dates (including `tomorrow == true`).
   - Notification counter formatting (`0` -> `""`, `1` -> `"1"`, `9` -> `"9"`, `10` -> `"9+"`).
   - WMO weather code to Simply late! condition code (`-1..6`) mapping for both day and night hours.
   - ISO-8601 `dateTime` parsing into Unix epoch seconds with positive, negative, and `Z` timezone offsets.
   - Compact side-slot metric formatting (`getCompactSlotText`).
2. **Build Verification:** Compile the Connect IQ project for `fenix6pro` (`260x260`, using the installed Connect IQ SDK 9.2.0 compiler `monkeyc.bat -d fenix6pro -l 0`) with zero errors, including resolving legacy Monkey C syntax incompatibilities (top-level `hidden` functions in `HuwaiiApp.mc` and parameter-shadowing `var value` declarations in `DataFactory.mc`).
3. **Memory & Layout Verification:**
   - Verify no references remain to `e0`–`e60` or `hour_1`–`minu_6` in compiled resources.
   - Verify rendering of all 6 zones across `240x240`, `260x260`, and `280x280` resolutions.
