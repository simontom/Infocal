using Toybox.Lang as Ex;

module DateUtils {

    class FormattedDateProvider {
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
                case DateUtils.DATE_FORMAT_1: // dof d (TUE 2)
                    var dayOfWeek = DateUtils.DAYS[dateShort.day_of_week];
                    return Lang.format(shortFormat, [dayOfWeek, day.format(integerFormat)]);

                case DateUtils.DATE_FORMAT_2: // dd.mm (2.9)
                    return Lang.format(shortFormatWithDot, [day, month]);

                case DateUtils.DATE_FORMAT_21: // mm.dd (9.2)
                    return Lang.format(shortFormatWithDot, [month, day]);

                case DateUtils.DATE_FORMAT_3: // dd.mm.yy (2.9.19)
                case DateUtils.DATE_FORMAT_31: // mm.dd.yy (9.2.19)
                    var shortenedYear = getShortenedYearAsString(dateShort.year);

                    if (dateFormat == DateUtils.DATE_FORMAT_31) {
                        return Lang.format(longFormatWithDots, [month, day, shortenedYear]);
                    }
                    return Lang.format(longFormatWithDots, [day, month, shortenedYear]);

                case DateUtils.DATE_FORMAT_4:    // dd mmm (2 OCT)
                case DateUtils.DATE_FORMAT_41: // mmm dd (OCT 2)
                    var monthName = DateUtils.MONTHS[dateShort.month];

                    if (dateFormat == DateUtils.DATE_FORMAT_4) {
                        return Lang.format(shortFormat, [day, month]);
                    }
                    return Lang.format(shortFormat, [month, day]);
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
