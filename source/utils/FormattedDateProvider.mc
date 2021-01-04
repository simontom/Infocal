using Toybox.Time;
using Toybox.Time.Gregorian as Date;
using Toybox.Lang as L;
using Toybox.Lang as Ex;
using SettingsEnums as SE;
using Toybox.Application;
using Toybox.Math;
using DateUtils as DU;

module DataProvider {

    class FormattedDateDataProvider {
        private const shortFormat = "$1$ $2$";
        private const shortFormatWithDot = "$1$.$2$";
        private const longFormatWithDots = "$1$.$2$.$3$";

        private const integerFormat = "%d";

        private var dateFormat;

        function initialize() {
            reloadSettings();
        }

        function reloadSettings() {
            dateFormat = Application.getApp().getProperty("date_format");
        }

        function getFormattedDate() {
            var now = Time.now();
            var dateShort = Date.info(now, Time.FORMAT_SHORT);

            var month = dateShort.month.format(integerFormat);
            var day = dateShort.day.format(integerFormat);

            switch (dateFormat) {
                case SE.DATE_FORMAT_1: // dof d (TUE 2)
                    var dayOfWeek = DU.DAYS[dateShort.day_of_week];
                    return L.format(shortFormat, [dayOfWeek, day]);

                case SE.DATE_FORMAT_2: // dd.mm (2.9)
                    return L.format(shortFormatWithDot, [day, month]);

                case SE.DATE_FORMAT_21: // mm.dd (9.2)
                    return L.format(shortFormatWithDot, [month, day]);

                case SE.DATE_FORMAT_3: // dd.mm.yy (2.9.19)
                case SE.DATE_FORMAT_31: // mm.dd.yy (9.2.19)
                    var shortenedYear = getShortenedYearAsString(dateShort.year);

                    if (dateFormat == SE.DATE_FORMAT_31) {
                        return L.format(longFormatWithDots, [month, day, shortenedYear]);
                    }
                    return L.format(longFormatWithDots, [day, month, shortenedYear]);

                case SE.DATE_FORMAT_4:    // dd mmm (2 OCT)
                case SE.DATE_FORMAT_41: // mmm dd (OCT 2)
                    var monthName = DU.MONTHS[dateShort.month];

                    if (dateFormat == SE.DATE_FORMAT_4) {
                        return L.format(shortFormat, [day, month]);
                    }
                    return L.format(shortFormat, [month, day]);
            }

            throw new Ex.InvalidValueException("Invalid type of 'dateFormat' in ':getFormattedDate'");
        }

        private function getShortenedYearAsString(year) {
            var shortenedYear = year / 100.0;
            shortenedYear = Math.round((shortenedYear - shortenedYear.toNumber()) * 100.0);
            return shortenedYear.format(integerFormat);
        }
    }

}
