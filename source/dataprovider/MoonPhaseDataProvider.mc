using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Time as T;

module DataProvider {

    class MoonPhaseDataProvider {

        private var lastCalculationTime;
        private var moonPhase;

        function initialize() {
            lastCalculationTime = null;
        }

        function calculateMoonPhase() {
            var timeNow = T.now();

            // Period in seconds -> 3600 = 60 min for hour * 60 sec for min
            if ((lastCalculationTime == null) || (timeNow.compare(lastCalculationTime) >= 4)) {
                lastCalculationTime = timeNow;

                moonPhase = calculateMoonPhaseHelper(timeNow);
                // Sys.println(moonPhase);
            }

            return moonPhase;
        }

        var nowXXX = T.now().subtract(new T.Duration(17 * T.Gregorian.SECONDS_PER_DAY));
        var oneDay = new T.Duration(T.Gregorian.SECONDS_PER_DAY);
        // INFO: Extracted from LowEnergyFace watchface
        private function calculateMoonPhaseHelper(now) {
            var date = T.Gregorian.info(nowXXX, Time.FORMAT_SHORT);

            var n0 = 0;
            var f0 = 0.0d;
            var AG = f0;

            //current date
            var Y1 = date.year;
            var M1 = date.month;
            var D1 = date.day;

            nowXXX = nowXXX.add(oneDay);

            var YY1 = n0;
            var MM1 = n0;
            var K11 = n0;
            var K21 = n0;
            var K31 = n0;
            var JD1 = n0;
            var IP1 = f0;
            var DP1 = f0;

            // calculate the Julian date at 12h UT
            YY1 = Y1 - ((12 - M1) / 10).toNumber();
            MM1 = M1 + 9;
            if (MM1 >= 12) {
                MM1 = MM1 - 12;
            }
            K11 = (365.25d * (YY1 + 4712)).toNumber();
            K21 = (30.6d * MM1 + 0.5d).toNumber();
            K31 = (((YY1 / 100) + 49).toNumber() * 0.75d).toNumber() - 38;

            JD1 = K11 + K21 + D1 + 59;  // for dates in Julian calendar
            if (JD1 > 2299160) {
                JD1 = JD1 - K31;        // for Gregorian calendar
            }

            // calculate moon's age in days
            IP1 = normalize((JD1 - 2451550.1d) / 29.530588853d);
            var AG1 = IP1 * 29.53;

            // Adjust the value to be usable in MoonPhaseDrawable draw-algorithm
            if (IP1 > 0.5) {
                IP1 = IP1 - 0.5;
            } else {
                IP1 = IP1 + 0.5;
            }

            // return AG1.toNumber();
            // return [M1, D1, IP1, AG1];
            return IP1;
        }

        private function normalize(value) {
            value = value - value.toNumber();

            if (value < 0) {
                value = value + 1;
            }

            return value;
        }
    }

}
