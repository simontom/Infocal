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

(:background)
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
(:background)
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
    if (moment == null) {
        return null;
    }
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
