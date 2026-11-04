# Simply late! + Infocal Hybrid Watchface Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Simply late! + Infocal hybrid Garmin Connect IQ watchface combining Simply late!'s radial time/weather/calendar ring layout with 4 configurable Infocal activity/sensor slots, a top-row `1–9`/`9+` notification counter, a live vector Moon Phase indicator, direct `yr.no` (Open-Meteo `metno`) weather, and direct Google Calendar OAuth2 Device Flow.

**Architecture:** Single-pass `Toybox.Graphics.Dc` rendering in `HuwaiiView.mc` using two compact bitmap fonts (`Rez.Fonts.bigdigi` and `Rez.Fonts.smadigi`), system `Graphics.FONT_XTINY` for mixed-case calendar text, and vector graphics for arcs, moon phase scanlines, and sun/battery icons. Background web requests run in `BackgroundService.mc` (32 KB RAM limit), flattening Open-Meteo `metno` hourly forecasts and Google Calendar OAuth2 responses before passing them via `Background.exit()` to `HuwaiiApp.onBackgroundData()` for persistence in the main process.

**Tech Stack:** Monkey C (Garmin Connect IQ SDK 9.2.0, `monkeyc.bat -d fenix6pro -l 0`), `Toybox.Graphics`, `Toybox.Communications`, `Toybox.Background`, `Toybox.ActivityMonitor`, `Toybox.SensorHistory`, `Toybox.Test`.

**Spec:** `d:\Work\Coding\Infocal\docs\superpowers\specs\2026-10-28-simply-late-infocal-design.md`

## Global Constraints

- **Compiler Command:** `& "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin\monkeyc.bat" -d fenix6pro -f monkey.jungle -o bin\Infocal.prg -y "d:\Work\Coding\garmin_developer_key.der" -l 0`
- **Memory Limits:** Fenix 6 WatchFace ~92 KB RAM; Background `ServiceDelegate` 32 KB RAM. All 60 rotated arc fonts (`e0`–`e60`) and analog tile tables (`hour_1`–`minu_6`) must be stripped from `resources*/`.
- **Monkey C SDK 9.2.0 Rules:** Do not use `hidden` on top-level functions outside a class/module; do not redeclare a function parameter name with `var` inside the function body.
- **Background Persistence Rule:** Never rely on `App.getApp().setProperty()` inside `BackgroundService` to persist across process exit; return all state updates in `Background.exit(payload)` and persist them in `HuwaiiApp.onBackgroundData(data)`.

---

## File Structure

- **Modify:**
  - `resources/fonts/fonts.xml`, `resources-round-218x218/fonts/fonts.xml`, `resources-round-260x260/fonts/fonts.xml`, `resources-round-280x280/fonts/fonts.xml`, `resources-round-390x390/fonts/fonts.xml` — Keep only `bigdigi` and `smadigi` bitmap fonts.
  - `resources/jsons/resources.xml`, `resources-round-218x218/jsons/resources.xml`, `resources-round-260x260/jsons/resources.xml`, `resources-round-280x280/jsons/resources.xml`, `resources-round-390x390/jsons/resources.xml` — Remove `hour_1..6`, `minu_1..6`, and `bar_*` JSON tables.
  - `resources/layouts/layout.xml` — Minimal `<layout id="WatchFace" />` container.
  - `resources/settings/properties.xml`, `resources/settings/settings.xml`, `resources/strings/strings.xml` — Define all hybrid watchface settings and default properties.
  - `source/datafield/DataFactory.mc` — Fix SDK 9.2.0 `var value` parameter redefinitions and add `getCompactSlotText(slotType, batteryDaysStr)`.
  - `source/HuwaiiApp.mc` — Manage location caching, background scheduling, `onBackgroundData` persistence for weather and Google OAuth2/Calendar data, and `getFormatedDate()`.
  - `source/BackgroundService.mc` — Fetch Open-Meteo `metno` 24h weather and execute Google OAuth2 Device Flow + Calendar Events API requests.
  - `source/HuwaiiView.mc` — Render all 6 visual zones on `Dc` and track hourly battery consumption.
- **Create:**
  - `source/SunMoonCompute.mc` — Pure functions for sunrise/sunset, lunar age & Moon Phase scanline rendering, notification badge formatting (`1–9` / `9+`), WMO weather code mapping (`-1..6`), and ISO-8601 timestamp parsing.
  - `source/HybridTests.mc` — `:test` unit test suite for all pure calculation and formatting helpers.
- **Delete:**
  - `source/complication/ArcTextComplication.mc`, `source/complication/BarComplication.mc`, `source/complication/BarDataComplication.mc`, `source/complication/Complication.mc`, `source/complication/GraphComplication.mc`
  - `source/mainface/AnalogDial.mc`, `source/mainface/BackgroundView.mc`, `source/mainface/MainDialHand.mc`
  - `resources-vivoactive4/settings/properties.xml`, `resources-vivoactive4s/settings/properties.xml`, `resources-legacyherocaptainmarvel/settings/properties.xml`, `resources-legacyherofirstavenger/settings/properties.xml`, `resources-legacysagadarthvader/settings/properties.xml`, `resources-legacysagarey/settings/properties.xml`

---

### Task 1: Resource Cleanup, Unified Settings & SDK 9.2.0 Build Baseline

**Files:**
- Delete: `source/complication/ArcTextComplication.mc`, `source/complication/BarComplication.mc`, `source/complication/BarDataComplication.mc`, `source/complication/Complication.mc`, `source/complication/GraphComplication.mc`, `source/mainface/AnalogDial.mc`, `source/mainface/BackgroundView.mc`, `source/mainface/MainDialHand.mc`
- Delete: `resources-vivoactive4/settings/properties.xml`, `resources-vivoactive4s/settings/properties.xml`, `resources-legacyherocaptainmarvel/settings/properties.xml`, `resources-legacyherofirstavenger/settings/properties.xml`, `resources-legacysagadarthvader/settings/properties.xml`, `resources-legacysagarey/settings/properties.xml`
- Modify: `resources/fonts/fonts.xml`, `resources-round-218x218/fonts/fonts.xml`, `resources-round-260x260/fonts/fonts.xml`, `resources-round-280x280/fonts/fonts.xml`, `resources-round-390x390/fonts/fonts.xml`
- Modify: `resources/jsons/resources.xml`, `resources-round-218x218/jsons/resources.xml`, `resources-round-260x260/jsons/resources.xml`, `resources-round-280x280/jsons/resources.xml`, `resources-round-390x390/jsons/resources.xml`
- Modify: `resources/layouts/layout.xml`
- Modify: `resources/settings/properties.xml`, `resources/settings/settings.xml`, `resources/strings/strings.xml`
- Modify: `source/HuwaiiApp.mc:21-35`
- Modify: `source/datafield/DataFactory.mc`

**Interfaces:**
- Produces:
  - `Rez.Fonts.bigdigi` and `Rez.Fonts.smadigi` across all screen resolutions
  - Unified application properties (`mainColor`, `tone`, `notifColor`, `showMoon`, `d24`, `boldness`, `weather`, `temp_unit`, `sunriset`, `slot_tl`, `slot_bl`, `slot_tr`, `slot_br`, `date_format`, `force_date_english`, `barometer_unit`, `batThreshold`, `enable_calendar`, `google_client_id`, `google_client_secret`, `calendar_ids`, `google_refresh_token`, `google_device_code`, `google_user_code`, `WeatherData`, `CalendarData`, `LastLocationLat`, `LastLocationLng`, `PendingWebRequests`, `last_hour_consumtion`, `consumtion_history`, `power_save_mode`, `minimal_data`, `battery_format`)
  - Clean `DataFactory.mc` with `getCompactSlotText(slotType, batteryDaysStr)`

- [ ] **Step 1: Delete obsolete complication/analog source files and stale per-device `properties.xml` overrides**

Run:
```powershell
git rm source/complication/ArcTextComplication.mc source/complication/BarComplication.mc source/complication/BarDataComplication.mc source/complication/Complication.mc source/complication/GraphComplication.mc source/mainface/AnalogDial.mc source/mainface/BackgroundView.mc source/mainface/MainDialHand.mc
git rm resources-vivoactive4/settings/properties.xml resources-vivoactive4s/settings/properties.xml resources-legacyherocaptainmarvel/settings/properties.xml resources-legacyherofirstavenger/settings/properties.xml resources-legacysagadarthvader/settings/properties.xml resources-legacysagarey/settings/properties.xml
```

- [ ] **Step 2: Strip `e0..e60` and `hour_1..minu_6` from all `fonts.xml`, `jsons/resources.xml`, and `layouts/layout.xml`**

Write the following content to `resources/fonts/fonts.xml`, `resources-round-218x218/fonts/fonts.xml`, `resources-round-260x260/fonts/fonts.xml`, `resources-round-280x280/fonts/fonts.xml`, and `resources-round-390x390/fonts/fonts.xml`:
```xml
<fonts>
	<font id="smadigi" filename="smadigi2.fntc" antialias="true" filter=" -+%,.:0123456789QWERTYUIJOPASDFGHJKLZXCVBNM°"/>
	<font id="bigdigi" filename="bigdigigarmin.fntc" antialias="true" filter="0123456789"/>
</fonts>
```

Write the following content to `resources/jsons/resources.xml`, `resources-round-218x218/jsons/resources.xml`, `resources-round-260x260/jsons/resources.xml`, `resources-round-280x280/jsons/resources.xml`, and `resources-round-390x390/jsons/resources.xml`:
```xml
<resources>
</resources>
```

Write the following content to `resources/layouts/layout.xml`:
```xml
<layout id="WatchFace">
</layout>
```

- [ ] **Step 3: Update `resources/settings/properties.xml`, `resources/settings/settings.xml`, and `resources/strings/strings.xml`**

Write `resources/settings/properties.xml`:
```xml
<properties>
    <property id="mainColor" type="number">1</property>
    <property id="tone" type="number">0</property>
    <property id="notifColor" type="number">0</property>
    <property id="showMoon" type="boolean">true</property>
    <property id="d24" type="number">0</property>
    <property id="boldness" type="number">2</property>
    <property id="weather" type="boolean">true</property>
    <property id="temp_unit" type="number">0</property>
    <property id="sunriset" type="boolean">true</property>

    <property id="slot_tl" type="number">1</property>
    <property id="slot_bl" type="number">2</property>
    <property id="slot_tr" type="number">3</property>
    <property id="slot_br" type="number">4</property>

    <property id="date_format" type="number">0</property>
    <property id="force_date_english" type="boolean">true</property>
    <property id="barometer_unit" type="number">0</property>
    <property id="batThreshold" type="number">33</property>
    <property id="power_save_mode" type="boolean">true</property>
    <property id="minimal_data" type="boolean">false</property>
    <property id="battery_format" type="number">0</property>

    <property id="enable_calendar" type="boolean">true</property>
    <property id="google_client_id" type="string"></property>
    <property id="google_client_secret" type="string"></property>
    <property id="calendar_ids" type="string">primary</property>

    <property id="google_refresh_token" type="string"></property>
    <property id="google_device_code" type="string"></property>
    <property id="google_user_code" type="string"></property>
</properties>
```

Write `resources/strings/strings.xml`:
```xml
<strings>
    <string id="AppName">Simply Infocal</string>

    <string id="mainColor">Main Accent Color</string>
    <string id="color_red">Red</string>
    <string id="color_orange">Orange / Yellow</string>
    <string id="color_green">Green</string>
    <string id="color_blue">Blue</string>
    <string id="color_violet">Violet</string>
    <string id="color_white">White</string>
    <string id="color_gray">Subtle Gray</string>
    <string id="color_accent">Match Accent Color</string>

    <string id="tone">Color Theme</string>
    <string id="tone_dark">Dark (Black BG)</string>
    <string id="tone_contrast">High-Contrast Dark</string>
    <string id="tone_light">Light (White BG)</string>

    <string id="notifColor">Notification Counter Color</string>
    <string id="showMoon">Show Moon Phase</string>

    <string id="d24">Outer Ring Mode</string>
    <string id="d24_24">24-Hour Ring</string>
    <string id="d24_12">12-Hour Ring</string>

    <string id="boldness">Minute Arc Thickness (1-5)</string>
    <string id="weather">Show Weather Forecast (yr.no)</string>
    <string id="temp_unit">Temperature Units</string>
    <string id="temp_auto">Auto (Device)</string>
    <string id="temp_c">Celsius</string>
    <string id="temp_f">Fahrenheit</string>
    <string id="sunriset">Show Sunrise / Sunset</string>

    <string id="slot_tl">Left Upper Metric</string>
    <string id="slot_bl">Left Lower Metric</string>
    <string id="slot_tr">Right Upper Metric</string>
    <string id="slot_br">Right Lower Metric</string>

    <string id="empty">Empty</string>
    <string id="heartrate">Heart Rate</string>
    <string id="steps">Steps</string>
    <string id="battery">Battery %</string>
    <string id="battery_days">Battery Days</string>
    <string id="altitude">Altitude</string>
    <string id="barometer">Barometer</string>
    <string id="calories">Calories</string>
    <string id="active">Active Minutes (Week)</string>
    <string id="floorclimbed">Floors Climbed</string>

    <string id="date_format">Date Format</string>
    <string id="datef1">DAY D (WED 28)</string>
    <string id="datef2">DD.MM (28.10)</string>
    <string id="datef21">MM.DD (10.28)</string>
    <string id="datef4">DD MON (28 OCT)</string>
    <string id="datef41">MON DD (OCT 28)</string>
    <string id="force_date_english">Force English Date</string>

    <string id="barometer_unit">Barometer Unit</string>
    <string id="barometer_unit_0">Hectopascal (hPa)</string>
    <string id="barometer_unit_1">Inches of Mercury (inHg)</string>
    <string id="batThreshold">Low Battery Icon Threshold (%)</string>

    <string id="enable_calendar">Show Google Calendar Events</string>
    <string id="google_client_id">Google OAuth Client ID (TV/Device)</string>
    <string id="google_client_secret">Google OAuth Client Secret</string>
    <string id="calendar_ids">Calendar ID (default: primary)</string>
</strings>
```

Write `resources/settings/settings.xml`:
```xml
<settings>
    <setting propertyKey="@Properties.mainColor" title="@Strings.mainColor">
        <settingConfig type="list">
            <listEntry value="0">@Strings.color_red</listEntry>
            <listEntry value="1">@Strings.color_orange</listEntry>
            <listEntry value="2">@Strings.color_green</listEntry>
            <listEntry value="3">@Strings.color_blue</listEntry>
            <listEntry value="4">@Strings.color_violet</listEntry>
            <listEntry value="5">@Strings.color_white</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.tone" title="@Strings.tone">
        <settingConfig type="list">
            <listEntry value="0">@Strings.tone_dark</listEntry>
            <listEntry value="1">@Strings.tone_contrast</listEntry>
            <listEntry value="2">@Strings.tone_light</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.notifColor" title="@Strings.notifColor">
        <settingConfig type="list">
            <listEntry value="0">@Strings.color_gray</listEntry>
            <listEntry value="1">@Strings.color_accent</listEntry>
            <listEntry value="2">@Strings.color_white</listEntry>
            <listEntry value="3">@Strings.color_orange</listEntry>
            <listEntry value="4">@Strings.color_red</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.showMoon" title="@Strings.showMoon">
        <settingConfig type="boolean" />
    </setting>

    <setting propertyKey="@Properties.d24" title="@Strings.d24">
        <settingConfig type="list">
            <listEntry value="0">@Strings.d24_24</listEntry>
            <listEntry value="1">@Strings.d24_12</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.boldness" title="@Strings.boldness">
        <settingConfig type="numeric" min="1" max="5" />
    </setting>

    <setting propertyKey="@Properties.weather" title="@Strings.weather">
        <settingConfig type="boolean" />
    </setting>

    <setting propertyKey="@Properties.temp_unit" title="@Strings.temp_unit">
        <settingConfig type="list">
            <listEntry value="0">@Strings.temp_auto</listEntry>
            <listEntry value="1">@Strings.temp_c</listEntry>
            <listEntry value="2">@Strings.temp_f</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.sunriset" title="@Strings.sunriset">
        <settingConfig type="boolean" />
    </setting>

    <setting propertyKey="@Properties.slot_tl" title="@Strings.slot_tl">
        <settingConfig type="list">
            <listEntry value="0">@Strings.empty</listEntry>
            <listEntry value="1">@Strings.heartrate</listEntry>
            <listEntry value="2">@Strings.steps</listEntry>
            <listEntry value="3">@Strings.battery</listEntry>
            <listEntry value="4">@Strings.battery_days</listEntry>
            <listEntry value="5">@Strings.altitude</listEntry>
            <listEntry value="6">@Strings.barometer</listEntry>
            <listEntry value="7">@Strings.calories</listEntry>
            <listEntry value="8">@Strings.active</listEntry>
            <listEntry value="9">@Strings.floorclimbed</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.slot_bl" title="@Strings.slot_bl">
        <settingConfig type="list">
            <listEntry value="0">@Strings.empty</listEntry>
            <listEntry value="1">@Strings.heartrate</listEntry>
            <listEntry value="2">@Strings.steps</listEntry>
            <listEntry value="3">@Strings.battery</listEntry>
            <listEntry value="4">@Strings.battery_days</listEntry>
            <listEntry value="5">@Strings.altitude</listEntry>
            <listEntry value="6">@Strings.barometer</listEntry>
            <listEntry value="7">@Strings.calories</listEntry>
            <listEntry value="8">@Strings.active</listEntry>
            <listEntry value="9">@Strings.floorclimbed</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.slot_tr" title="@Strings.slot_tr">
        <settingConfig type="list">
            <listEntry value="0">@Strings.empty</listEntry>
            <listEntry value="1">@Strings.heartrate</listEntry>
            <listEntry value="2">@Strings.steps</listEntry>
            <listEntry value="3">@Strings.battery</listEntry>
            <listEntry value="4">@Strings.battery_days</listEntry>
            <listEntry value="5">@Strings.altitude</listEntry>
            <listEntry value="6">@Strings.barometer</listEntry>
            <listEntry value="7">@Strings.calories</listEntry>
            <listEntry value="8">@Strings.active</listEntry>
            <listEntry value="9">@Strings.floorclimbed</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.slot_br" title="@Strings.slot_br">
        <settingConfig type="list">
            <listEntry value="0">@Strings.empty</listEntry>
            <listEntry value="1">@Strings.heartrate</listEntry>
            <listEntry value="2">@Strings.steps</listEntry>
            <listEntry value="3">@Strings.battery</listEntry>
            <listEntry value="4">@Strings.battery_days</listEntry>
            <listEntry value="5">@Strings.altitude</listEntry>
            <listEntry value="6">@Strings.barometer</listEntry>
            <listEntry value="7">@Strings.calories</listEntry>
            <listEntry value="8">@Strings.active</listEntry>
            <listEntry value="9">@Strings.floorclimbed</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.date_format" title="@Strings.date_format">
        <settingConfig type="list">
            <listEntry value="0">@Strings.datef1</listEntry>
            <listEntry value="1">@Strings.datef2</listEntry>
            <listEntry value="2">@Strings.datef21</listEntry>
            <listEntry value="5">@Strings.datef4</listEntry>
            <listEntry value="6">@Strings.datef41</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.force_date_english" title="@Strings.force_date_english">
        <settingConfig type="boolean" />
    </setting>

    <setting propertyKey="@Properties.barometer_unit" title="@Strings.barometer_unit">
        <settingConfig type="list">
            <listEntry value="0">@Strings.barometer_unit_0</listEntry>
            <listEntry value="1">@Strings.barometer_unit_1</listEntry>
        </settingConfig>
    </setting>

    <setting propertyKey="@Properties.batThreshold" title="@Strings.batThreshold">
        <settingConfig type="numeric" min="10" max="50" />
    </setting>

    <setting propertyKey="@Properties.enable_calendar" title="@Strings.enable_calendar">
        <settingConfig type="boolean" />
    </setting>

    <setting propertyKey="@Properties.google_client_id" title="@Strings.google_client_id">
        <settingConfig type="alphaNumeric" />
    </setting>

    <setting propertyKey="@Properties.google_client_secret" title="@Strings.google_client_secret">
        <settingConfig type="alphaNumeric" />
    </setting>

    <setting propertyKey="@Properties.calendar_ids" title="@Strings.calendar_ids">
        <settingConfig type="alphaNumeric" />
    </setting>
</settings>
```

- [ ] **Step 4: Fix SDK 9.2.0 variable redefinitions in `source/datafield/DataFactory.mc` and add `getCompactSlotText(slotType, batteryDaysStr)`**

In `source/datafield/DataFactory.mc`:
1. Fix the 7 local `var value` parameter redefinitions in `GroupNotiField.cur_label` (line 792), `SunField.cur_label` (line 869), `TemparatureField.cur_label` (line 1100), `AltitudeField.cur_label` (line 1148), `AlarmField.cur_label` (line 1210), `NotifyField.cur_label` (line 1231), and `DistanceField.max_label` (line 1354).
2. Add the compact slot formatter `getCompactSlotText(slotType, batteryDaysStr)` at the bottom of `source/datafield/DataFactory.mc`:

```monkeyc
function getCompactSlotText(slotType, batteryDaysStr) {
    if (slotType == null || slotType == 0) {
        return "";
    } else if (slotType == 1) {
        // Heart Rate
        var hr = _retrieveHeartrate().toNumber();
        if (hr <= 1) {
            return "--";
        }
        return hr.format("%d");
    } else if (slotType == 2) {
        // Steps
        var info = ActivityMonitor.getInfo();
        var steps = (info != null && info.steps != null) ? info.steps : 0;
        if (steps >= 10000) {
            return (steps / 1000.0).format("%0.1f") + "K";
        }
        return steps.format("%d");
    } else if (slotType == 3) {
        // Battery %
        var bat = Math.round(Sys.getSystemStats().battery).toNumber();
        return bat.format("%d") + "%";
    } else if (slotType == 4) {
        // Battery Days
        if (batteryDaysStr != null && batteryDaysStr.length() > 0) {
            return batteryDaysStr;
        }
        var batFallback = Math.round(Sys.getSystemStats().battery).toNumber();
        return batFallback.format("%d") + "%";
    } else if (slotType == 5) {
        // Altitude
        var altField = new AltitudeField(FIELD_TYPE_ALTITUDE);
        var settings = Sys.getDeviceSettings();
        var actInfo = Activity.getActivityInfo();
        var alt = (actInfo != null) ? actInfo.altitude : null;
        if ((alt == null) && (Toybox has :SensorHistory) && (Toybox.SensorHistory has :getElevationHistory)) {
            var sample = SensorHistory.getElevationHistory({ :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST }).next();
            if ((sample != null) && (sample.data != null)) {
                alt = sample.data;
            }
        }
        if (alt == null) {
            return "--";
        }
        if (settings.elevationUnits == Sys.UNIT_METRIC) {
            return alt.format("%d") + "M";
        } else {
            return (alt * 3.28084).format("%d") + "F";
        }
    } else if (slotType == 6) {
        // Barometer
        var baroField = new BarometerField(FIELD_TYPE_BAROMETER);
        var pData = baroField.cur_val();
        if (pData == null || pData[0] == null) {
            return "--";
        }
        var hpa = pData[0] / 100.0;
        var sig = (pData[1] == 1) ? "+" : ((pData[1] == -1) ? "-" : "");
        if (App.getApp().getProperty("barometer_unit") == 1) {
            return (hpa * 0.0295301).format("%0.1f") + sig;
        }
        return hpa.format("%d") + sig;
    } else if (slotType == 7) {
        // Calories
        var calInfo = ActivityMonitor.getInfo();
        var cals = (calInfo != null && calInfo.calories != null) ? calInfo.calories : 0;
        if (cals >= 1000) {
            return (cals / 1000.0).format("%0.1f") + "K";
        }
        return cals.format("%d");
    } else if (slotType == 8) {
        // Active Minutes (Week)
        var actMinInfo = ActivityMonitor.getInfo();
        var mins = (actMinInfo != null && actMinInfo.activeMinutesWeek != null) ? actMinInfo.activeMinutesWeek.total : 0;
        return mins.format("%d") + "M";
    } else if (slotType == 9) {
        // Floors Climbed
        var flrInfo = ActivityMonitor.getInfo();
        if (flrInfo != null && (flrInfo has :floorsClimbed) && flrInfo.floorsClimbed != null) {
            return flrInfo.floorsClimbed.format("%d") + "FL";
        }
        return "--";
    }
    return "";
}
```

- [ ] **Step 5: Remove `hidden` from top-level helper functions in `source/HuwaiiApp.mc` and temporarily stub `mainDrawComponents` in `source/HuwaiiView.mc` to verify baseline compilation**

In `source/HuwaiiApp.mc` (lines 21–35), replace `hidden function` with `function`.
In `source/HuwaiiView.mc`, remove references to deleted drawables (`analog`, `digital`, `aBarDisplay`..`fBarDisplay`, `Rez.JsonData.theme_pallete`, `Rez.Fonts.secodigi`, `Rez.Fonts.xsecodigi`) so the baseline compiles cleanly.

Run:
```powershell
& "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin\monkeyc.bat" -d fenix6pro -f monkey.jungle -o "$env:TEMP\infocal_task1.prg" -y "d:\Work\Coding\garmin_developer_key.der" -l 0
```
Expected: Compiles with exit code 0 and zero errors.

- [ ] **Step 6: Commit Task 1**

```powershell
git add -A
git commit -m "chore: strip legacy arc fonts/drawables and configure hybrid settings"
```

---

### Task 2: Astronomical & Formatting Helpers (`SunMoonCompute.mc`) + Unit Tests (`HybridTests.mc`)

**Files:**
- Create: `source/SunMoonCompute.mc`
- Create: `source/HybridTests.mc`

**Interfaces:**
- Consumes: `Toybox.Math`, `Toybox.Time`, `Toybox.Time.Gregorian`, `Toybox.Graphics`
- Produces:
  - `computeSunTimes(lat, lng, tz, tomorrow)` -> `[sunriseHourFloat, sunsetHourFloat]`
  - `computeLunarAgeDays(unixEpochSeconds)` -> `Float` (`0.0` .. `29.530588853`)
  - `computeMoonTerminatorOffset(lunarAgeDays, dy, radius)` -> `[leftXOffset, rightXOffset]`
  - `drawMoonPhase(dc, cx, cy, radius, lunarAgeDays, outlineColor, litColor)`
  - `formatNotificationCount(count)` -> `String` (`""`, `"1"`..`"9"`, `"9+"`)
  - `mapWmoToMeteoCode(wmoCode, isDaytime)` -> `Number` (`-1`..`6`)
  - `parseIso8601ToEpoch(isoStr)` -> `Number` (Unix epoch seconds) or `null`

- [ ] **Step 1: Create `source/HybridTests.mc` with failing unit tests for all pure calculation functions**

Write `source/HybridTests.mc`:
```monkeyc
using Toybox.Test;
using Toybox.Math;

(:test)
function testNotificationFormatting(logger) {
    Test.assertEqual("", formatNotificationCount(0));
    Test.assertEqual("", formatNotificationCount(-1));
    Test.assertEqual("1", formatNotificationCount(1));
    Test.assertEqual("9", formatNotificationCount(9));
    Test.assertEqual("9+", formatNotificationCount(10));
    Test.assertEqual("9+", formatNotificationCount(42));
    return true;
}

(:test)
function testLunarAgeAndTerminator(logger) {
    // Reference new moon: 2000-01-06 18:14:00 UTC = 947182440
    var ageNew = computeLunarAgeDays(947182440);
    Test.assert(ageNew >= 0.0 && ageNew < 0.01);

    // Half synodic month (~14.765 days = Full Moon)
    var fullEpoch = 947182440 + Math.round(14.765294 * 86400).toNumber();
    var ageFull = computeLunarAgeDays(fullEpoch);
    Test.assert(ageFull > 14.7 && ageFull < 14.8);

    // At Full Moon (age ~14.765) and dy = 0, radius = 6, lit span should cover [-6, +6]
    var spanFull = computeMoonTerminatorOffset(ageFull, 0, 6);
    Test.assertEqual(-6, spanFull[0]);
    Test.assertEqual(6, spanFull[1]);

    // At First Quarter (age ~7.3826) and dy = 0, radius = 6, waxing right half [0, +6] is lit
    var spanFirstQ = computeMoonTerminatorOffset(7.382647, 0, 6);
    Test.assertEqual(0, spanFirstQ[0]);
    Test.assertEqual(6, spanFirstQ[1]);
    return true;
}

(:test)
function testWmoWeatherMapping(logger) {
    Test.assertEqual(0, mapWmoToMeteoCode(0, true));   // Clear day
    Test.assertEqual(6, mapWmoToMeteoCode(0, false));  // Clear night
    Test.assertEqual(1, mapWmoToMeteoCode(2, true));   // Partly cloudy
    Test.assertEqual(-1, mapWmoToMeteoCode(3, true));  // Overcast -> gap
    Test.assertEqual(-1, mapWmoToMeteoCode(45, false));// Fog -> gap
    Test.assertEqual(2, mapWmoToMeteoCode(61, true));  // Light rain
    Test.assertEqual(3, mapWmoToMeteoCode(65, true));  // Heavy rain
    Test.assertEqual(3, mapWmoToMeteoCode(95, false)); // Thunderstorm
    Test.assertEqual(4, mapWmoToMeteoCode(71, true));  // Light snow
    Test.assertEqual(5, mapWmoToMeteoCode(75, true));  // Heavy snow
    return true;
}

(:test)
function testIso8601Parsing(logger) {
    // 2026-10-28T14:30:00Z
    var epochUtc = parseIso8601ToEpoch("2026-10-28T14:30:00Z");
    Test.assert(epochUtc != null);

    // 2026-10-28T15:30:00+01:00 represents the exact same instant as 14:30:00Z
    var epochPlus1 = parseIso8601ToEpoch("2026-10-28T15:30:00+01:00");
    Test.assertEqual(epochUtc, epochPlus1);

    // 2026-10-28T10:30:00-04:00 also represents the exact same instant
    var epochMinus4 = parseIso8601ToEpoch("2026-10-28T10:30:00-04:00");
    Test.assertEqual(epochUtc, epochMinus4);

    // All-day date only (no time) should return null
    Test.assertEqual(null, parseIso8601ToEpoch("2026-10-28"));
    return true;
}
```

- [ ] **Step 2: Run unit test build to verify it fails before `SunMoonCompute.mc` exists**

Run:
```powershell
& "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin\monkeyc.bat" -d fenix6pro -f monkey.jungle -o "$env:TEMP\infocal_test.prg" -y "d:\Work\Coding\garmin_developer_key.der" -l 0 -t
```
Expected: Fails with undefined symbol errors for `formatNotificationCount`, `computeLunarAgeDays`, `computeMoonTerminatorOffset`, `mapWmoToMeteoCode`, `parseIso8601ToEpoch`.

- [ ] **Step 3: Implement `source/SunMoonCompute.mc`**

Write `source/SunMoonCompute.mc`:
```monkeyc
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian as Date;
using Toybox.Graphics;
using Toybox.System as Sys;

const SYNODIC_MONTH_DAYS = 29.530588853;
const NEW_MOON_EPOCH_2000 = 947182440; // 2000-01-06 18:14:00 UTC

function formatNotificationCount(count) {
    if (count == null || count <= 0) {
        return "";
    }
    if (count > 9) {
        return "9+";
    }
    return count.format("%d");
}

function computeLunarAgeDays(unixEpochSeconds) {
    var diffSec = unixEpochSeconds - NEW_MOON_EPOCH_2000;
    var synodicSec = SYNODIC_MONTH_DAYS * 86400.0;
    var cycles = diffSec / synodicSec;
    var frac = cycles - Math.floor(cycles);
    if (frac < 0.0) {
        frac += 1.0;
    }
    return frac * SYNODIC_MONTH_DAYS;
}

// Returns [xStartOffset, xEndOffset] for scanline dy (-radius..+radius).
// If nothing is lit on this row, returns null.
function computeMoonTerminatorOffset(lunarAgeDays, dy, radius) {
    var phase = lunarAgeDays / SYNODIC_MONTH_DAYS;
    if (phase < 0.0) {
        phase += 1.0;
    }
    if (phase >= 1.0) {
        phase -= Math.floor(phase);
    }
    // Very close to New Moon (< 2% illumination): unlit
    if (phase < 0.02 || phase > 0.98) {
        return null;
    }
    var r2 = radius * radius - dy * dy;
    if (r2 < 0) {
        return null;
    }
    var dx = Math.sqrt(r2.toFloat());
    var tx = Math.cos(phase * 2.0 * Math.PI) * dx;
    if (phase <= 0.5) {
        // Waxing: right side is illuminated from terminator tx to +dx
        return [Math.round(tx).toNumber(), Math.round(dx).toNumber()];
    } else {
        // Waning: left side is illuminated from -dx to -tx
        return [Math.round(-dx).toNumber(), Math.round(-tx).toNumber()];
    }
}

function drawMoonPhase(dc, cx, cy, radius, lunarAgeDays, outlineColor, litColor) {
    dc.setPenWidth(1);
    dc.setColor(outlineColor, Graphics.COLOR_TRANSPARENT);
    dc.drawCircle(cx, cy, radius);

    dc.setColor(litColor, Graphics.COLOR_TRANSPARENT);
    for (var dy = -radius + 1; dy <= radius - 1; dy += 1) {
        var span = computeMoonTerminatorOffset(lunarAgeDays, dy, radius - 1);
        if (span != null && span[1] >= span[0]) {
            dc.drawLine(cx + span[0], cy + dy, cx + span[1], cy + dy);
        }
    }
}

function computeSunTimes(lat, lng, tz, tomorrow) {
    if (lat == null || lng == null) {
        return [null, null];
    }
    var latD = lat.toDouble();
    var lngD = lng.toDouble();

    var moment = Time.now();
    if (tomorrow) {
        moment = moment.add(new Time.Duration(24 * 60 * 60));
    }
    var d = Date.info(moment, Time.FORMAT_SHORT);
    var rad = Math.PI / 180.0d;
    var deg = 180.0d / Math.PI;

    var a = Math.floor((14 - d.month) / 12);
    var y = d.year + 4800 - a;
    var m = d.month + (12 * a) - 3;
    var jDate = d.day
        + Math.floor(((153 * m) + 2) / 5)
        + (365 * y)
        + Math.floor(y / 4)
        - Math.floor(y / 100)
        + Math.floor(y / 400)
        - 32045;

    var n = jDate - 2451545.0d + 0.0008d;
    var jStar = n - (lngD / 360.0d);

    var M = 357.5291d + (0.98560028d * jStar);
    var MFloor = Math.floor(M);
    var MFrac = M - MFloor;
    M = (MFloor.toLong() % 360) + MFrac;

    var C = 1.9148d * Math.sin(M * rad)
        + 0.02d * Math.sin(2 * M * rad)
        + 0.0003d * Math.sin(3 * M * rad);

    var lambda = (M + C + 180 + 102.9372d);
    var lambdaFloor = Math.floor(lambda);
    var lambdaFrac = lambda - lambdaFloor;
    lambda = (lambdaFloor.toLong() % 360) + lambdaFrac;

    var jTransit = 2451545.5d + jStar
        + 0.0053d * Math.sin(M * rad)
        - 0.0069d * Math.sin(2 * lambda * rad);

    var delta = Math.asin(Math.sin(lambda * rad) * Math.sin(23.44d * rad));
    var cosOmega = (Math.sin(-0.83d * rad) - Math.sin(latD * rad) * Math.sin(delta))
        / (Math.cos(latD * rad) * Math.cos(delta));

    if (cosOmega > 1.0d) {
        return [null, -1];
    }
    if (cosOmega < -1.0d) {
        return [-1, null];
    }

    var omega = Math.acos(cosOmega) * deg;
    var jSet = jTransit + (omega / 360.0d);
    var jRise = jTransit - (omega / 360.0d);
    var deltaJSet = jSet - jDate;
    var deltaJRise = jRise - jDate;

    var tzOffset = (tz == null) ? (Sys.getClockTime().timeZoneOffset / 3600.0) : tz;
    var localRise = (deltaJRise * 24.0) + tzOffset;
    var localSet = (deltaJSet * 24.0) + tzOffset;
    if (localRise < 0) { localRise += 24.0; }
    if (localRise >= 24.0) { localRise -= 24.0; }
    if (localSet < 0) { localSet += 24.0; }
    if (localSet >= 24.0) { localSet -= 24.0; }
    return [localRise.toFloat(), localSet.toFloat()];
}

(:background_method)
function mapWmoToMeteoCode(wmoCode, isDaytime) {
    if (wmoCode == null) {
        return -1;
    }
    if (wmoCode == 0 || wmoCode == 1) {
        return isDaytime ? 0 : 6;
    }
    if (wmoCode == 2) {
        return 1;
    }
    if (wmoCode == 3 || wmoCode == 45 || wmoCode == 48) {
        return -1;
    }
    if ((wmoCode >= 51 && wmoCode <= 57) || wmoCode == 61 || wmoCode == 80) {
        return 2;
    }
    if ((wmoCode >= 63 && wmoCode <= 67) || wmoCode == 81 || wmoCode == 82 || wmoCode >= 95) {
        return 3;
    }
    if (wmoCode == 71 || wmoCode == 77 || wmoCode == 85) {
        return 4;
    }
    if (wmoCode == 73 || wmoCode == 75 || wmoCode == 86) {
        return 5;
    }
    return -1;
}

// Parses "YYYY-MM-DDTHH:MM:SSZ" or "YYYY-MM-DDTHH:MM:SS+HH:MM" into Unix epoch seconds.
(:background_method)
function parseIso8601ToEpoch(isoStr) {
    if (isoStr == null || isoStr.length() < 19) {
        return null;
    }
    if (isoStr.substring(10, 11).equals("T") == false) {
        return null;
    }
    var year = isoStr.substring(0, 4).toNumber();
    var month = isoStr.substring(5, 7).toNumber();
    var day = isoStr.substring(8, 10).toNumber();
    var hour = isoStr.substring(11, 13).toNumber();
    var min = isoStr.substring(14, 16).toNumber();
    var sec = isoStr.substring(17, 19).toNumber();
    if (year == null || month == null || day == null || hour == null || min == null || sec == null) {
        return null;
    }

    var moment = Date.moment({
        :year => year,
        :month => month,
        :day => day,
        :hour => hour,
        :minute => min,
        :second => sec
    });
    var utcSeconds = moment.value();

    var tzPart = isoStr.substring(19, isoStr.length());
    if (tzPart.length() >= 6) {
        var signChar = tzPart.substring(0, 1);
        var tzH = tzPart.substring(1, 3).toNumber();
        var tzM = tzPart.substring(4, 6).toNumber();
        if (tzH != null && tzM != null) {
            var offsetSec = (tzH * 3600) + (tzM * 60);
            if (signChar.equals("+")) {
                utcSeconds -= offsetSec;
            } else if (signChar.equals("-")) {
                utcSeconds += offsetSec;
            }
        }
    }
    return utcSeconds;
}
```

- [ ] **Step 4: Compile with `-t` to verify all unit tests and helper functions compile cleanly**

Run:
```powershell
& "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin\monkeyc.bat" -d fenix6pro -f monkey.jungle -o "$env:TEMP\infocal_test.prg" -y "d:\Work\Coding\garmin_developer_key.der" -l 0 -t; Remove-Item "$env:TEMP\infocal_test*" -ErrorAction SilentlyContinue
```
Expected: Compiles with exit code 0 and zero errors.

- [ ] **Step 5: Commit Task 2**

```powershell
git add source/SunMoonCompute.mc source/HybridTests.mc
git commit -m "feat: add astronomical, weather mapping, ISO-8601, and notification helpers with tests"
```

---

### Task 3: Background Service (`yr.no` Open-Meteo Weather & Google Calendar OAuth2 Device Flow)

**Files:**
- Modify: `source/BackgroundService.mc`
- Modify: `source/HuwaiiApp.mc`

**Interfaces:**
- Consumes: `mapWmoToMeteoCode`, `parseIso8601ToEpoch` from `source/SunMoonCompute.mc`
- Produces:
  - `WeatherData` property stored in main process: `[timestampEpoch, baseHour, currentTemp, minTemp, maxTemp, totalPrecipMm, code0, code1, ..., code23]`
  - `CalendarData` property stored in main process: `{"ts" => epoch, "events" => [[startEpoch, endEpoch, summary, location], ...]}`
  - `google_refresh_token`, `google_device_code`, `google_user_code` properties persisted by `HuwaiiApp.onBackgroundData(data)`

- [ ] **Step 1: Update `source/HuwaiiApp.mc` to schedule and persist `WeatherData`, `CalendarAuth`, and `CalendarData`**

Write `source/HuwaiiApp.mc`:
```monkeyc
using Toybox.Application;
using Toybox.Activity as Activity;
using Toybox.System as Sys;
using Toybox.Background as Bg;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Math;
using Toybox.Lang;
using Toybox.Time.Gregorian as Date;

var gLocationLat = null;
var gLocationLng = null;

var centerX;
var centerY;

function degreesToRadians(degrees) {
    return degrees * Math.PI / 180.0;
}

function radiansToDegrees(radians) {
    return radians * 180.0 / Math.PI;
}

function convertCoorX(radians, radius) {
    return centerX + radius * Math.cos(radians);
}

function convertCoorY(radians, radius) {
    return centerY + radius * Math.sin(radians);
}

(:background)
class HuwaiiApp extends Application.AppBase {

    var mView;
    var days;
    var months;

    function initialize() {
        AppBase.initialize();
        days = {
            Date.DAY_MONDAY => "MON",
            Date.DAY_TUESDAY => "TUE",
            Date.DAY_WEDNESDAY => "WED",
            Date.DAY_THURSDAY => "THU",
            Date.DAY_FRIDAY => "FRI",
            Date.DAY_SATURDAY => "SAT",
            Date.DAY_SUNDAY => "SUN"
        };
        months = {
            Date.MONTH_JANUARY => "JAN",
            Date.MONTH_FEBRUARY => "FEB",
            Date.MONTH_MARCH => "MAR",
            Date.MONTH_APRIL => "APR",
            Date.MONTH_MAY => "MAY",
            Date.MONTH_JUNE => "JUN",
            Date.MONTH_JULY => "JUL",
            Date.MONTH_AUGUST => "AUG",
            Date.MONTH_SEPTEMBER => "SEP",
            Date.MONTH_OCTOBER => "OCT",
            Date.MONTH_NOVEMBER => "NOV",
            Date.MONTH_DECEMBER => "DEC"
        };
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        mView = new HuwaiiView();
        return [mView];
    }

    function getView() {
        return mView;
    }

    function onSettingsChanged() {
        if (HuwaiiApp has :checkPendingWebRequests) {
            checkPendingWebRequests();
        }
        if (mView != null) {
            mView.last_draw_minute = -1;
        }
        Ui.requestUpdate();
    }

    (:background_method)
    function checkPendingWebRequests() {
        var actInfo = Activity.getActivityInfo();
        var location = (actInfo != null) ? actInfo.currentLocation : null;
        if (location != null) {
            location = location.toDegrees();
            gLocationLat = location[0].toFloat();
            gLocationLng = location[1].toFloat();
            setProperty("LastLocationLat", gLocationLat);
            setProperty("LastLocationLng", gLocationLng);
        } else {
            var lat = getProperty("LastLocationLat");
            var lng = getProperty("LastLocationLng");
            if (lat != null && lng != null) {
                gLocationLat = lat;
                gLocationLng = lng;
            }
        }

        if (!(Sys has :ServiceDelegate)) {
            return;
        }

        var pending = getProperty("PendingWebRequests");
        if (pending == null) {
            pending = {};
        }

        var nowVal = Time.now().value();

        // 1. Weather (yr.no via Open-Meteo metno)
        if (getProperty("weather") == true && gLocationLat != null) {
            var wData = getProperty("WeatherData");
            if (wData == null || !(wData instanceof Toybox.Lang.Array) || wData.size() < 6 || (nowVal - wData[0]) > 1800) {
                pending["Weather"] = true;
            }
        }

        // 2. Google Calendar
        var clientId = getProperty("google_client_id");
        if (getProperty("enable_calendar") == true && clientId != null && clientId.length() > 0) {
            var refreshToken = getProperty("google_refresh_token");
            var calData = getProperty("CalendarData");
            if (refreshToken == null || refreshToken.length() == 0) {
                // Poll every 5 minutes while waiting for device flow login
                pending["Calendar"] = true;
            } else if (calData == null || (calData["ts"] != null && (nowVal - calData["ts"]) > 1800)) {
                pending["Calendar"] = true;
            }
        }

        setProperty("PendingWebRequests", pending);

        if (pending.keys().size() > 0) {
            var lastTime = Bg.getLastTemporalEventTime();
            if (lastTime != null) {
                var nextTime = lastTime.add(new Time.Duration(5 * 60));
                Bg.registerForTemporalEvent(nextTime);
            } else {
                Bg.registerForTemporalEvent(Time.now());
            }
        }
    }

    (:background_method)
    function getServiceDelegate() {
        return [new BackgroundService()];
    }

    (:background_method)
    function onBackgroundData(data) {
        if (data == null || !(data instanceof Toybox.Lang.Dictionary)) {
            return;
        }
        var pending = getProperty("PendingWebRequests");
        if (pending == null) {
            pending = {};
        }

        if (data["WeatherData"] != null) {
            var w = data["WeatherData"];
            if (w instanceof Toybox.Lang.Array) {
                setProperty("WeatherData", w);
                pending.remove("Weather");
            }
        }

        if (data["CalendarAuth"] != null) {
            var auth = data["CalendarAuth"];
            if (auth["device_code"] != null) {
                setProperty("google_device_code", auth["device_code"]);
            }
            if (auth["user_code"] != null) {
                setProperty("google_user_code", auth["user_code"]);
            }
        }

        if (data["CalendarData"] != null) {
            var cal = data["CalendarData"];
            if (cal["refresh_token"] != null && cal["refresh_token"].length() > 0) {
                setProperty("google_refresh_token", cal["refresh_token"]);
                setProperty("google_device_code", "");
                setProperty("google_user_code", "");
            }
            if (cal["events"] != null) {
                setProperty("CalendarData", {
                    "ts" => cal["ts"],
                    "events" => cal["events"]
                });
                pending.remove("Calendar");
            }
        }

        setProperty("PendingWebRequests", pending);
        Ui.requestUpdate();
    }

    function getFormatedDate() {
        var now = Time.now();
        var date = Date.info(now, Time.FORMAT_SHORT);
        var date_formater = getProperty("date_format");
        if (date_formater == null) {
            date_formater = 0;
        }
        if (date_formater == 0) {
            if (getProperty("force_date_english")) {
                return Lang.format("$1$ $2$", [days[date.day_of_week], date.day.format("%d")]);
            } else {
                var dateLong = Date.info(now, Time.FORMAT_LONG);
                return Lang.format("$1$ $2$", [dateLong.day_of_week.toUpper(), dateLong.day.format("%d")]);
            }
        } else if (date_formater == 1) {
            return Lang.format("$1$.$2$", [date.day.format("%d"), date.month.format("%d")]);
        } else if (date_formater == 2) {
            return Lang.format("$1$.$2$", [date.month.format("%d"), date.day.format("%d")]);
        } else if (date_formater == 5) {
            return Lang.format("$1$ $2$", [date.day.format("%d"), months[date.month]]);
        } else if (date_formater == 6) {
            return Lang.format("$1$ $2$", [months[date.month], date.day.format("%d")]);
        }
        return Lang.format("$1$ $2$", [days[date.day_of_week], date.day.format("%d")]);
    }

    function toKValue(value) {
        var valK = value / 1000.0;
        return valK.format("%0.1f");
    }
}
```

- [ ] **Step 2: Implement `source/BackgroundService.mc` for Open-Meteo `metno` (`yr.no`) and Google Calendar OAuth2 Device Flow**

Write `source/BackgroundService.mc`:
```monkeyc
using Toybox.Background as Bg;
using Toybox.System as Sys;
using Toybox.Communications as Comms;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Time.Gregorian as Date;
using Toybox.Math;
using Toybox.Lang;

(:background)
class BackgroundService extends Sys.ServiceDelegate {

    var mNewRefreshToken = null;

    (:background_method)
    function initialize() {
        Sys.ServiceDelegate.initialize();
    }

    (:background_method)
    function onTemporalEvent() {
        var app = App.getApp();
        var pending = app.getProperty("PendingWebRequests");
        if (pending == null) {
            Bg.exit({});
            return;
        }

        // Prioritize Weather if pending, otherwise Calendar
        if (pending["Weather"] != null) {
            requestWeather();
        } else if (pending["Calendar"] != null) {
            requestCalendarStep();
        } else {
            Bg.exit({});
        }
    }

    (:background_method)
    function requestWeather() {
        var app = App.getApp();
        var lat = app.getProperty("LastLocationLat");
        var lng = app.getProperty("LastLocationLng");
        if (lat == null || lng == null) {
            Bg.exit({});
            return;
        }

        var tempUnitPref = app.getProperty("temp_unit");
        var unitStr = "celsius";
        if (tempUnitPref == 2 || (tempUnitPref == 0 && Sys.getDeviceSettings().temperatureUnits == Sys.UNIT_STATUTE)) {
            unitStr = "fahrenheit";
        }

        var params = {
            "latitude" => lat,
            "longitude" => lng,
            "hourly" => "temperature_2m,precipitation,weather_code",
            "forecast_hours" => 24,
            "timezone" => "auto",
            "timeformat" => "unixtime",
            "temperature_unit" => unitStr
        };

        makeGetRequest("https://api.open-meteo.com/v1/metno", params, method(:onReceiveWeather));
    }

    (:background_method)
    function onReceiveWeather(responseCode, data) {
        if (responseCode != 200 || data == null || data["hourly"] == null) {
            Bg.exit({});
            return;
        }

        var hourly = data["hourly"];
        var temps = hourly["temperature_2m"];
        var precip = hourly["precipitation"];
        var codes = hourly["weather_code"];
        if (temps == null || precip == null || codes == null || temps.size() < 16) {
            Bg.exit({});
            return;
        }

        var currentHour = Sys.getClockTime().hour;
        var currentTemp = Math.round(temps[0]).toNumber();
        var minTemp = currentTemp;
        var maxTemp = currentTemp;
        for (var i = 1; i < 16 && i < temps.size(); i += 1) {
            if (temps[i] != null) {
                var t = Math.round(temps[i]).toNumber();
                if (t < minTemp) { minTemp = t; }
                if (t > maxTemp) { maxTemp = t; }
            }
        }

        var sumPrecip = 0.0;
        for (var j = 0; j < 24 && j < precip.size(); j += 1) {
            if (precip[j] != null) {
                sumPrecip += precip[j];
            }
        }
        var totalPrecip = Math.round(sumPrecip).toNumber();

        var result = [
            Time.now().value(),
            currentHour,
            currentTemp,
            minTemp,
            maxTemp,
            totalPrecip
        ];

        for (var k = 0; k < 24; k += 1) {
            var wmo = (k < codes.size()) ? codes[k] : null;
            var hOfDay = (currentHour + k) % 24;
            var isDay = (hOfDay >= 6 && hOfDay < 20);
            result.add(mapWmoToMeteoCode(wmo, isDay));
        }

        Bg.exit({ "WeatherData" => result });
    }

    (:background_method)
    function requestCalendarStep() {
        var app = App.getApp();
        var clientId = app.getProperty("google_client_id");
        var clientSecret = app.getProperty("google_client_secret");
        var refreshToken = app.getProperty("google_refresh_token");
        var deviceCode = app.getProperty("google_device_code");

        if (clientId == null || clientId.length() == 0) {
            Bg.exit({});
            return;
        }

        if (refreshToken != null && refreshToken.length() > 0) {
            // Step 3: Exchange refresh_token for access_token
            makePostRequest(
                "https://oauth2.googleapis.com/token",
                {
                    "client_id" => clientId,
                    "client_secret" => clientSecret,
                    "refresh_token" => refreshToken,
                    "grant_type" => "refresh_token"
                },
                method(:onReceiveTokenRefresh)
            );
        } else if (deviceCode != null && deviceCode.length() > 0) {
            // Step 2: Poll device_code for user approval
            makePostRequest(
                "https://oauth2.googleapis.com/token",
                {
                    "client_id" => clientId,
                    "client_secret" => clientSecret,
                    "device_code" => deviceCode,
                    "grant_type" => "urn:ietf:params:oauth:grant-type:device_code"
                },
                method(:onReceiveDevicePoll)
            );
        } else {
            // Step 1: Request new device_code and user_code
            makePostRequest(
                "https://oauth2.googleapis.com/device/code",
                {
                    "client_id" => clientId,
                    "scope" => "https://www.googleapis.com/auth/calendar.readonly"
                },
                method(:onReceiveDeviceCode)
            );
        }
    }

    (:background_method)
    function onReceiveDeviceCode(responseCode, data) {
        if (responseCode == 200 && data != null && data["device_code"] != null) {
            Bg.exit({
                "CalendarAuth" => {
                    "device_code" => data["device_code"],
                    "user_code" => data["user_code"],
                    "verification_url" => "google.com/device"
                }
            });
            return;
        }
        Bg.exit({});
    }

    (:background_method)
    function onReceiveDevicePoll(responseCode, data) {
        if (responseCode == 200 && data != null && data["access_token"] != null) {
            mNewRefreshToken = data["refresh_token"];
            fetchCalendarEvents(data["access_token"]);
            return;
        }
        if (data != null && data["error"] != null && data["error"].equals("expired_token")) {
            Bg.exit({
                "CalendarAuth" => {
                    "device_code" => "",
                    "user_code" => ""
                }
            });
            return;
        }
        Bg.exit({});
    }

    (:background_method)
    function onReceiveTokenRefresh(responseCode, data) {
        if (responseCode == 200 && data != null && data["access_token"] != null) {
            fetchCalendarEvents(data["access_token"]);
            return;
        }
        Bg.exit({});
    }

    (:background_method)
    function fetchCalendarEvents(accessToken) {
        var calId = App.getApp().getProperty("calendar_ids");
        if (calId == null || calId.length() == 0) {
            calId = "primary";
        } else {
            var commaIdx = calId.find(",");
            if (commaIdx != null && commaIdx > 0) {
                calId = calId.substring(0, commaIdx);
            }
        }

        var now = Time.now();
        var next24 = now.add(new Time.Duration(24 * 3600));
        var url = "https://www.googleapis.com/calendar/v3/calendars/" + Comms.encodeURL(calId) + "/events";
        var params = {
            "singleEvents" => "true",
            "orderBy" => "startTime",
            "timeMin" => formatUtcIso(now),
            "timeMax" => formatUtcIso(next24),
            "maxResults" => "6",
            "fields" => "items(summary,location,start/dateTime,end/dateTime)"
        };
        var options = {
            :method => Comms.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + accessToken
            },
            :responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Comms.makeWebRequest(url, params, options, method(:onReceiveCalendarEvents));
    }

    (:background_method)
    function onReceiveCalendarEvents(responseCode, data) {
        if (responseCode != 200 || data == null) {
            if (mNewRefreshToken != null) {
                Bg.exit({
                    "CalendarData" => {
                        "ts" => Time.now().value(),
                        "refresh_token" => mNewRefreshToken,
                        "events" => []
                    }
                });
            } else {
                Bg.exit({});
            }
            return;
        }

        var eventsOut = [];
        var items = data["items"];
        if (items != null && (items instanceof Toybox.Lang.Array)) {
            for (var i = 0; i < items.size(); i += 1) {
                var item = items[i];
                var startObj = item["start"];
                var endObj = item["end"];
                if (startObj != null && startObj["dateTime"] != null && endObj != null && endObj["dateTime"] != null) {
                    var startEpoch = parseIso8601ToEpoch(startObj["dateTime"]);
                    var endEpoch = parseIso8601ToEpoch(endObj["dateTime"]);
                    if (startEpoch != null && endEpoch != null) {
                        var summary = (item["summary"] != null) ? item["summary"] : "Event";
                        if (summary.length() > 20) {
                            summary = summary.substring(0, 20);
                        }
                        var loc = (item["location"] != null) ? item["location"] : "";
                        var comma = loc.find(",");
                        if (comma != null && comma > 0) {
                            loc = loc.substring(0, comma);
                        }
                        if (loc.length() > 12) {
                            loc = loc.substring(0, 12);
                        }
                        eventsOut.add([startEpoch, endEpoch, summary, loc]);
                    }
                }
            }
        }

        Bg.exit({
            "CalendarData" => {
                "ts" => Time.now().value(),
                "refresh_token" => mNewRefreshToken,
                "events" => eventsOut
            }
        });
    }

    (:background_method)
    function formatUtcIso(moment) {
        var utcInfo = Date.utcInfo(moment, Time.FORMAT_SHORT);
        return Lang.format("$1$-$2$-$3$T$4$:$5$:00Z", [
            utcInfo.year.format("%04d"),
            utcInfo.month.format("%02d"),
            utcInfo.day.format("%02d"),
            utcInfo.hour.format("%02d"),
            utcInfo.min.format("%02d")
        ]);
    }

    (:background_method)
    function makeGetRequest(url, params, callback) {
        var options = {
            :method => Comms.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Comms.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            :responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Comms.makeWebRequest(url, params, options, callback);
    }

    (:background_method)
    function makePostRequest(url, params, callback) {
        var options = {
            :method => Comms.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Comms.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            :responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Comms.makeWebRequest(url, params, options, callback);
    }
}
```

- [ ] **Step 3: Compile to verify `BackgroundService.mc` and `HuwaiiApp.mc` build cleanly**

Run:
```powershell
& "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin\monkeyc.bat" -d fenix6pro -f monkey.jungle -o "$env:TEMP\infocal_task3.prg" -y "d:\Work\Coding\garmin_developer_key.der" -l 0; Remove-Item "$env:TEMP\infocal_task3*" -ErrorAction SilentlyContinue
```
Expected: Compiles with exit code 0 and zero errors.

- [ ] **Step 4: Commit Task 3**

```powershell
git add source/HuwaiiApp.mc source/BackgroundService.mc
git commit -m "feat: implement Open-Meteo yr.no weather and Google Calendar OAuth2 background service"
```

---

### Task 4: Single-Pass Hybrid Watchface Renderer (`HuwaiiView.mc`)

**Files:**
- Modify: `source/HuwaiiView.mc`

**Interfaces:**
- Consumes:
  - `computeSunTimes`, `computeLunarAgeDays`, `drawMoonPhase`, `formatNotificationCount` from `source/SunMoonCompute.mc`
  - `getCompactSlotText` from `source/datafield/DataFactory.mc`
  - `WeatherData`, `CalendarData`, `google_user_code`, and user settings from `Application.getApp().getProperty(...)`
- Produces:
  - Complete single-pass rendering of all 6 zones in `HuwaiiView.onUpdate(dc)`

- [ ] **Step 1: Implement `source/HuwaiiView.mc`**

Write `source/HuwaiiView.mc`:
```monkeyc
using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian as Date;
using Toybox.Application as App;

var last_battery_percent = -1;
var last_hour_consumtion = -1;

class HuwaiiView extends WatchUi.WatchFace {

    var last_draw_minute = -1;
    var last_battery_hour = null;

    var fontHours = null;
    var fontSmall = null;

    // Theme palette colors
    var bgColor = 0x000000;
    var mainColor = 0xFFAA00;
    var primaryTextColor = 0xFFFFFF;
    var secondaryTextColor = 0xAAAAAA;
    var dimmedColor = 0x555555;
    var notifColor = 0xAAAAAA;

    // Meteo forecast ring palette (0: Clear Day, 1: Partly Cloudy, 2: Light Rain, 3: Heavy Rain, 4: Light Snow, 5: Heavy Snow, 6: Clear Night)
    var meteoColors = [0xFFAA00, 0xAA5500, 0x005555, 0x00AAFF, 0xAAAAAA, 0xFFFFFF, 0x555500];

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        fontHours = WatchUi.loadResource(Rez.Fonts.bigdigi);
        fontSmall = WatchUi.loadResource(Rez.Fonts.smadigi);
        centerX = dc.getWidth() / 2;
        centerY = dc.getHeight() / 2;
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() {
        last_draw_minute = -1;
        checkBackgroundRequest();
    }

    function onUpdate(dc) {
        var clockTime = System.getClockTime();
        updateBatteryHistory();

        if (clockTime.min != last_draw_minute) {
            checkBackgroundRequest();
            last_draw_minute = clockTime.min;
        }

        applyThemeSettings();

        var width = dc.getWidth();
        var height = dc.getHeight();
        centerX = width / 2;
        centerY = height / 2;

        // Clear background
        dc.setColor(bgColor, bgColor);
        dc.clear();

        // 1. Outer Bezel Rings: 24h/12h Weather Forecast Ring & Calendar Event Ring + Sunrise/Sunset/Now Markers
        drawOuterRings(dc, width, height, clockTime);

        // 2. Top Row: [Notif 1..9 / 9+]  WED 28  [Moon Phase]
        drawTopRow(dc, width, height);

        // 3. Upper-Left Precipitation (mm) & Upper-Right Temperature + Min-Max Range Bar
        drawUpperWeatherReadouts(dc, width, height);

        // 4. Center Hour + Radial Minute Progress Arc + Orbiting Minute Number
        drawCenterTimeAndMinuteArc(dc, width, height, clockTime);

        // 5. Left & Right Stacked Infocal Metric Slots (2 Left, 2 Right)
        drawSideMetricSlots(dc, width, height);

        // 6. Bottom 2-Line Next Calendar Event / OAuth Prompt + Low Battery Icon
        drawBottomCalendarAndBattery(dc, width, height);
    }

    function applyThemeSettings() {
        var app = App.getApp();
        var accentCode = app.getProperty("mainColor");
        var accents = [0xFF0000, 0xFFAA00, 0x00FF00, 0x00AAFF, 0xAA00FF, 0xFFFFFF];
        if (accentCode != null && accentCode >= 0 && accentCode < accents.size()) {
            mainColor = accents[accentCode];
        } else {
            mainColor = 0xFFAA00;
        }

        var tone = app.getProperty("tone");
        if (tone == 2) {
            bgColor = 0xFFFFFF;
            primaryTextColor = 0x000000;
            secondaryTextColor = 0x555555;
            dimmedColor = 0xAAAAAA;
        } else if (tone == 1) {
            bgColor = 0x000000;
            primaryTextColor = 0xFFFFFF;
            secondaryTextColor = 0xFFFFFF;
            dimmedColor = 0xAAAAAA;
        } else {
            bgColor = 0x000000;
            primaryTextColor = 0xFFFFFF;
            secondaryTextColor = 0xAAAAAA;
            dimmedColor = 0x555555;
        }

        var notifCode = app.getProperty("notifColor");
        if (notifCode == 1) {
            notifColor = mainColor;
        } else if (notifCode == 2) {
            notifColor = primaryTextColor;
        } else if (notifCode == 3) {
            notifColor = 0xFFAA00;
        } else if (notifCode == 4) {
            notifColor = 0xFF5555;
        } else {
            notifColor = secondaryTextColor;
        }
    }

    function hourToRingDegree(hourFloat, is12hRing) {
        var totalHours = is12hRing ? 12.0 : 24.0;
        var h = hourFloat;
        if (is12hRing) {
            while (h >= 12.0) { h -= 12.0; }
        } else {
            while (h >= 24.0) { h -= 24.0; }
        }
        var deg = 90.0 - (h / totalHours) * 360.0;
        while (deg < 0.0) { deg += 360.0; }
        while (deg >= 360.0) { deg -= 360.0; }
        return Math.round(deg).toNumber();
    }

    function drawOuterRings(dc, width, height, clockTime) {
        var app = App.getApp();
        var is12h = (app.getProperty("d24") == 1);
        var ringHours = is12h ? 12 : 24;
        var stepDeg = is12h ? 30 : 15;
        var weatherArcR = centerY - 3;
        var calArcR = centerY - 10;
        var weatherPen = (centerX == 195) ? 8 : 5;
        var calPen = (centerX == 195) ? 9 : 6;

        // 1a. Weather Forecast Ring
        if (app.getProperty("weather") == true) {
            var wData = app.getProperty("WeatherData");
            if (wData != null && (wData instanceof Toybox.Lang.Array) && wData.size() >= 30) {
                var baseHour = wData[1];
                dc.setPenWidth(weatherPen);
                for (var i = 0; i < ringHours; i += 1) {
                    var code = wData[6 + i];
                    if (code != null && code >= 0 && code < meteoColors.size()) {
                        var hStart = (baseHour + i) % 24;
                        var degStart = hourToRingDegree(hStart.toFloat(), is12h);
                        var degEnd = (degStart - stepDeg + 360) % 360;
                        dc.setColor(meteoColors[code], Graphics.COLOR_TRANSPARENT);
                        dc.drawArc(centerX, centerY, weatherArcR, Graphics.ARC_CLOCKWISE, degStart, degEnd);
                    }
                }
            }
        }

        // 1b. Calendar Event Ring
        if (app.getProperty("enable_calendar") == true) {
            var calData = app.getProperty("CalendarData");
            if (calData != null && calData["events"] != null) {
                var events = calData["events"];
                var nowEpoch = Time.now().value();
                var windowSec = ringHours * 3600;
                dc.setPenWidth(calPen);
                for (var e = 0; e < events.size(); e += 1) {
                    var ev = events[e];
                    var sEpoch = ev[0];
                    var eEpoch = ev[1];
                    if (eEpoch > nowEpoch && sEpoch < (nowEpoch + windowSec)) {
                        var clipStart = (sEpoch < nowEpoch) ? nowEpoch : sEpoch;
                        var clipEnd = (eEpoch > (nowEpoch + windowSec)) ? (nowEpoch + windowSec) : eEpoch;
                        var sInfo = Date.info(new Time.Moment(clipStart), Time.FORMAT_SHORT);
                        var eInfo = Date.info(new Time.Moment(clipEnd), Time.FORMAT_SHORT);
                        var sHourF = sInfo.hour + (sInfo.min / 60.0);
                        var eHourF = eInfo.hour + (eInfo.min / 60.0);
                        var fromDeg = hourToRingDegree(sHourF, is12h);
                        var toDeg = hourToRingDegree(eHourF, is12h);
                        if (fromDeg != toDeg) {
                            dc.setColor(mainColor, Graphics.COLOR_TRANSPARENT);
                            dc.drawArc(centerX, centerY, calArcR, Graphics.ARC_CLOCKWISE, (fromDeg - 1 + 360) % 360, toDeg);
                        }
                    }
                }
            }
        }

        // 1c. Sunrise & Sunset Vector Markers
        if (app.getProperty("sunriset") == true && gLocationLat != null && gLocationLng != null) {
            var sunTimes = computeSunTimes(gLocationLat, gLocationLng, null, false);
            if (sunTimes[0] != null && sunTimes[0] >= 0) {
                drawSunMarker(dc, sunTimes[0], is12h, calArcR, true);
            }
            if (sunTimes[1] != null && sunTimes[1] >= 0) {
                drawSunMarker(dc, sunTimes[1], is12h, calArcR, false);
            }
        }

        // 1d. Current Time ("Now") Dot on Outer Ring
        var nowHourF = clockTime.hour + (clockTime.min / 60.0);
        var nowDeg = hourToRingDegree(nowHourF, is12h);
        var nowRad = degreesToRadians(nowDeg);
        var nx = centerX + Math.round(calArcR * Math.cos(nowRad)).toNumber();
        var ny = centerY - Math.round(calArcR * Math.sin(nowRad)).toNumber();
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(nx, ny, 5);
        dc.setColor(primaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(nx, ny, 3);
    }

    function drawSunMarker(dc, hourFloat, is12h, radius, isSunrise) {
        var deg = hourToRingDegree(hourFloat, is12h);
        var rad = degreesToRadians(deg);
        var sx = centerX + Math.round(radius * Math.cos(rad)).toNumber();
        var sy = centerY - Math.round(radius * Math.sin(rad)).toNumber();
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(sx, sy, 5);
        dc.setColor(isSunrise ? 0xFFAA00 : 0xFF5500, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(sx, sy, 3);
        dc.setPenWidth(1);
        dc.setColor(primaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(sx - 4, sy, sx + 4, sy);
    }

    function drawTopRow(dc, width, height) {
        var dateY = (0.14 * height).toNumber();
        var dateStr = App.getApp().getFormatedDate();
        var dateDims = dc.getTextDimensions(dateStr, fontSmall);
        var dateHalfW = dateDims[0] / 2;

        // Center: Date
        dc.setColor(primaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, dateY, fontSmall, dateStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Left of Date: Plain Notification Counter (1..9 or 9+, hidden when 0)
        var notifCount = System.getDeviceSettings().notificationCount;
        var notifStr = formatNotificationCount(notifCount);
        if (notifStr.length() > 0) {
            var notifX = centerX - dateHalfW - 8;
            dc.setColor(notifColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(notifX, dateY, fontSmall, notifStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Right of Date: Live Moon Phase Indicator
        if (App.getApp().getProperty("showMoon") == true) {
            var moonX = centerX + dateHalfW + 12;
            var lunarAge = computeLunarAgeDays(Time.now().value());
            drawMoonPhase(dc, moonX, dateY, 6, lunarAge, dimmedColor, primaryTextColor);
        }
    }

    function drawUpperWeatherReadouts(dc, width, height) {
        if (App.getApp().getProperty("weather") != true) {
            return;
        }
        var wData = App.getApp().getProperty("WeatherData");
        if (wData == null || !(wData instanceof Toybox.Lang.Array) || wData.size() < 6) {
            return;
        }

        var currentTemp = wData[2];
        var minTemp = wData[3];
        var maxTemp = wData[4];
        var totalPrecip = wData[5];
        var upperY = (0.26 * height).toNumber();

        // Upper-Left: Precipitation (mm) when > 0
        if (totalPrecip > 0) {
            var precipX = (0.23 * width).toNumber();
            dc.setColor(secondaryTextColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(precipX, upperY - 5, fontSmall, totalPrecip.format("%d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(dimmedColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(precipX, upperY + 7, fontSmall, "MM", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Upper-Right: Temperature + Min/Max Range Bar
        var tempX = (0.77 * width).toNumber();
        var extremeTemp = ((maxTemp - currentTemp) >= (currentTemp - minTemp)) ? maxTemp : minTemp;
        var sep = (extremeTemp < 0) ? "" : "-";
        var tempLabel = currentTemp.format("%d") + "°" + sep + extremeTemp.format("%d");
        dc.setColor(secondaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(tempX, upperY - 4, fontSmall, tempLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Min-Max Range Bar underneath
        var barHalfW = 14;
        var barY = upperY + 8;
        dc.setPenWidth(2);
        dc.setColor(dimmedColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(tempX - barHalfW, barY, tempX + barHalfW, barY);

        var ratio = 0.5;
        if (maxTemp > minTemp) {
            ratio = (currentTemp - minTemp).toFloat() / (maxTemp - minTemp).toFloat();
            if (ratio < 0.0) { ratio = 0.0; }
            if (ratio > 1.0) { ratio = 1.0; }
        }
        var dotX = (tempX - barHalfW) + Math.round(ratio * (barHalfW * 2)).toNumber();
        dc.setColor(primaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(dotX, barY, 2);
    }

    function drawCenterTimeAndMinuteArc(dc, width, height, clockTime) {
        var hour = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }
        var hourStr = hour.format("%02d");
        var minute = clockTime.min;
        var minuteArcR = (0.21 * height).toNumber();
        var boldness = App.getApp().getProperty("boldness");
        if (boldness == null || boldness < 1) { boldness = 2; }

        // Center Hour
        dc.setColor(primaryTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, fontHours, hourStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Radial Minute Progress Arc
        if (minute > 0) {
            var endDeg = (450 - (minute * 6)) % 360;
            dc.setPenWidth(boldness * 2);
            dc.setColor(mainColor, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(centerX, centerY, minuteArcR, Graphics.ARC_CLOCKWISE, 90, endDeg);
        }

        // Orbiting Minute Number
        var minAngleRad = (minute / 60.0) * 2.0 * Math.PI - (Math.PI / 2.0);
        var mx = centerX + Math.round(minuteArcR * Math.cos(minAngleRad)).toNumber();
        var my = centerY + Math.round(minuteArcR * Math.sin(minAngleRad)).toNumber();

        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mx, my, 10);
        dc.setColor(mainColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(mx, my, fontSmall, minute.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawSideMetricSlots(dc, width, height) {
        var app = App.getApp();
        var slotLeftX = (0.17 * width).toNumber();
        var slotRightX = (0.83 * width).toNumber();
        var slotTopY = centerY - (0.05 * height).toNumber();
        var slotBottomY = centerY + (0.05 * height).toNumber();
        var batDaysStr = computeBatteryDaysCompact();

        dc.setColor(secondaryTextColor, Graphics.COLOR_TRANSPARENT);

        var tlText = getCompactSlotText(app.getProperty("slot_tl"), batDaysStr);
        if (tlText.length() > 0) {
            dc.drawText(slotLeftX, slotTopY, fontSmall, tlText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        var blText = getCompactSlotText(app.getProperty("slot_bl"), batDaysStr);
        if (blText.length() > 0) {
            dc.drawText(slotLeftX, slotBottomY, fontSmall, blText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        var trText = getCompactSlotText(app.getProperty("slot_tr"), batDaysStr);
        if (trText.length() > 0) {
            dc.drawText(slotRightX, slotTopY, fontSmall, trText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        var brText = getCompactSlotText(app.getProperty("slot_br"), batDaysStr);
        if (brText.length() > 0) {
            dc.drawText(slotRightX, slotBottomY, fontSmall, brText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function drawBottomCalendarAndBattery(dc, width, height) {
        var app = App.getApp();
        var messageY = (0.71 * height).toNumber();

        if (app.getProperty("enable_calendar") == true) {
            var refreshToken = app.getProperty("google_refresh_token");
            var userCode = app.getProperty("google_user_code");
            var clientId = app.getProperty("google_client_id");

            if ((refreshToken == null || refreshToken.length() == 0) && userCode != null && userCode.length() > 0) {
                dc.setColor(primaryTextColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, messageY, Graphics.FONT_XTINY, "google.com/device", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(mainColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, messageY + 14, Graphics.FONT_XTINY, userCode, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else if (refreshToken != null && refreshToken.length() > 0) {
                var calData = app.getProperty("CalendarData");
                if (calData != null && calData["events"] != null) {
                    var events = calData["events"];
                    var nowEpoch = Time.now().value();
                    var nextEv = null;
                    for (var i = 0; i < events.size(); i += 1) {
                        if (events[i][1] > nowEpoch) {
                            nextEv = events[i];
                            break;
                        }
                    }
                    if (nextEv != null) {
                        var summary = nextEv[2];
                        var loc = nextEv[3];
                        var diffMin = ((nextEv[0] - nowEpoch) / 60).toNumber();
                        var timeLabel = "";
                        if (diffMin <= 0) {
                            timeLabel = "now!";
                        } else if (diffMin < 60) {
                            timeLabel = diffMin.format("%d") + "m";
                        } else if (diffMin < 180) {
                            timeLabel = (diffMin / 60).format("%d") + "h" + (diffMin % 60).format("%02d");
                        } else {
                            var stInfo = Date.info(new Time.Moment(nextEv[0]), Time.FORMAT_SHORT);
                            timeLabel = stInfo.hour.format("%02d") + ":" + stInfo.min.format("%02d");
                        }
                        var line2 = (loc != null && loc.length() > 0) ? (timeLabel + ": " + loc) : timeLabel;
                        dc.setColor(primaryTextColor, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(centerX, messageY, Graphics.FONT_XTINY, summary, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                        dc.setColor(secondaryTextColor, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(centerX, messageY + 14, Graphics.FONT_XTINY, line2, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    }
                }
            } else if ((clientId == null || clientId.length() == 0) && gLocationLat == null && app.getProperty("weather") == true) {
                dc.setColor(dimmedColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, messageY, fontSmall, "NO GPS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Low Battery Icon at bottom
        var batThreshold = app.getProperty("batThreshold");
        if (batThreshold == null) { batThreshold = 33; }
        var currentBat = System.getSystemStats().battery;
        if (currentBat <= batThreshold) {
            var batY = (0.88 * height).toNumber();
            dc.setPenWidth(1);
            dc.setColor(0xFF5555, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(centerX - 8, batY - 4, 15, 8);
            dc.fillRectangle(centerX + 7, batY - 2, 2, 4);
            dc.fillRectangle(centerX - 6, batY - 2, 4, 4);
        }
    }

    function updateBatteryHistory() {
        var time_now = Time.now();
        if (last_battery_hour == null) {
            last_battery_hour = time_now;
            last_battery_percent = System.getSystemStats().battery;
            last_hour_consumtion = -1;
        } else if (time_now.compare(last_battery_hour) >= 3600) {
            last_battery_hour = time_now;
            var current_battery = System.getSystemStats().battery;
            last_hour_consumtion = last_battery_percent - current_battery;
            if (last_hour_consumtion < 0) {
                last_hour_consumtion = -1;
            }
            if (last_hour_consumtion > 0) {
                App.getApp().setProperty("last_hour_consumtion", last_hour_consumtion);
                var consumtion_history = App.getApp().getProperty("consumtion_history");
                if (consumtion_history == null) {
                    App.getApp().setProperty("consumtion_history", [last_hour_consumtion]);
                } else {
                    consumtion_history.add(last_hour_consumtion);
                    if (consumtion_history.size() > 24) {
                        var object0 = consumtion_history[0];
                        consumtion_history.remove(object0);
                    }
                    App.getApp().setProperty("consumtion_history", consumtion_history);
                }
            }
            last_battery_percent = current_battery;
        }
    }

    function computeBatteryDaysCompact() {
        var hour_consumtion = last_hour_consumtion;
        if (hour_consumtion <= 0) {
            var consumtion_history = App.getApp().getProperty("consumtion_history");
            if (consumtion_history != null && consumtion_history.size() > 0) {
                var total = 0.0;
                for (var i = 0; i < consumtion_history.size(); i += 1) {
                    total += consumtion_history[i];
                }
                hour_consumtion = total / consumtion_history.size();
            } else {
                var saved = App.getApp().getProperty("last_hour_consumtion");
                if (saved != null) {
                    hour_consumtion = saved;
                }
            }
        }
        if (hour_consumtion == null || hour_consumtion <= 0) {
            return null;
        }
        var bat = System.getSystemStats().battery;
        var daysLeft = (bat / hour_consumtion) / 24.0;
        if (daysLeft > 99.0) {
            daysLeft = 99.0;
        }
        return daysLeft.format("%0.1f") + "D";
    }

    function onExitSleep() {
        checkBackgroundRequest();
        WatchUi.requestUpdate();
    }

    function onEnterSleep() {
    }

    function checkBackgroundRequest() {
        if (HuwaiiApp has :checkPendingWebRequests) {
            App.getApp().checkPendingWebRequests();
        }
    }
}
```

- [ ] **Step 2: Compile both production `.prg` and `-t` unit test `.prg` for `fenix6pro` (`260x260`) and `fr965` (`454x454`)**

Run:
```powershell
New-Item -ItemType Directory -Force -Path "d:\Work\Coding\Infocal\bin" | Out-Null
& "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin\monkeyc.bat" -d fenix6pro -f monkey.jungle -o "d:\Work\Coding\Infocal\bin\Infocal-fenix6pro.prg" -y "d:\Work\Coding\garmin_developer_key.der" -l 0 -w
& "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin\monkeyc.bat" -d fenix6pro -f monkey.jungle -o "$env:TEMP\Infocal-tests.prg" -y "d:\Work\Coding\garmin_developer_key.der" -l 0 -t
Remove-Item "$env:TEMP\Infocal-tests*" -ErrorAction SilentlyContinue
```
Expected: Both builds succeed with exit code 0 and zero errors.

- [ ] **Step 3: Commit Task 4**

```powershell
git add source/HuwaiiView.mc
git commit -m "feat: implement single-pass Simply late! + Infocal hybrid watchface view"
```
