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

(:test)
function testLayoutZonesClearance(logger) {
    var resolutions = [218, 240, 260, 280, 390];
    for (var i = 0; i < resolutions.size(); i += 1) {
        var h = resolutions[i];
        var cy = h / 2;
        var dateY = (0.14 * h).toNumber();
        var upperY = (0.26 * h).toNumber();
        var minuteArcR = (0.23 * h).toNumber();
        var minuteArcTop = cy - minuteArcR;
        var minuteArcBottom = cy + minuteArcR;
        var messageY = (0.78 * h).toNumber();
        var batY = (0.90 * h).toNumber();
        var calArcR = cy - 10;

        // Verify strictly non-overlapping vertical zones
        Test.assert(dateY < upperY);
        Test.assert(upperY <= minuteArcTop);
        Test.assert(minuteArcTop < cy);
        Test.assert(cy < minuteArcBottom);
        Test.assert(minuteArcBottom < messageY);
        Test.assert(messageY < batY);
        Test.assert(batY < (cy + calArcR));
    }
    return true;
}
