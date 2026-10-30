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

    function onHide() {
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
        var weatherPen = (centerX >= 195) ? 8 : 5;
        var calPen = (centerX >= 195) ? 9 : 6;

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
        } else if (gLocationLat == null && app.getProperty("weather") == true) {
            dc.setColor(dimmedColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, messageY, fontSmall, "NO GPS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
