using Toybox.Time.Gregorian as Date;
using Toybox.Lang as Ex;

module DateUtils {

    class FormattedDateProvider {
        private const shortFormat = "$1$ $2$";
        private const shortFormatWithDot = "$1$.$2$";
        private const longFormatWithDots = "$1$.$2$.$3$";

        private const integerFormat = "%d";

        private var dateFormat;
        private var isForceDateEnglish; // TODO: Remove this and make all date reading use the DateUtils.DAYS / DateUtils.MONTHS

        function initialize() {
            reloadSettings();
        }

        function reloadSettings() {
            dateFormat = Application.getApp().getProperty("date_format");
            isForceDateEnglish = Application.getApp().getProperty("force_date_english");
        }

        function getFormattedDate() {
            var now = Time.now();
            var dateShort = Date.info(now, Time.FORMAT_SHORT);

            switch (dateFormat) {
                case DateUtils.DATE_FORMAT_1: { // dof d (TUE 2)
                    var day = dateShort.day.format(integerFormat);
                    var dayOfWeek = null;

                    if (isForceDateEnglish) {
                        dayOfWeek = DateUtils.DAYS[dateShort.day_of_week];
                    } else {
                        var dateLong = Date.info(now, Time.FORMAT_LONG);
                        dayOfWeek = dateLong.day_of_week.toUpper();
                    }

                    return Lang.format(shortFormat, [dayOfWeek, day]);
                }

                case DateUtils.DATE_FORMAT_2: // dd.mm (2.9)
                    return Lang.format(shortFormatWithDot, [dateShort.day.format(integerFormat), dateShort.month.format(integerFormat)]);

                case DateUtils.DATE_FORMAT_21: // mm.dd (9.2)
                    return Lang.format(shortFormatWithDot, [dateShort.month.format(integerFormat), dateShort.day.format(integerFormat)]);

                case DateUtils.DATE_FORMAT_3: { // dd.mm.yy (2.9.19)
                    var year = dateShort.year;
                    var yy = year / 100.0;
                    yy = Math.round((yy - yy.toNumber()) * 100.0);
                    return Lang.format(longFormatWithDots, [dateShort.day.format(integerFormat), dateShort.month.format(integerFormat), yy.format(integerFormat)]);
                }

                case DateUtils.DATE_FORMAT_31: { // mm.dd.yy (9.2.19)
                    var year = dateShort.year;
                    var yy = year / 100.0;
                    yy = Math.round((yy - yy.toNumber()) * 100.0);
                    return Lang.format(longFormatWithDots, [dateShort.month.format(integerFormat), dateShort.day.format(integerFormat), yy.format(integerFormat)]);
                }

                case DateUtils.DATE_FORMAT_4:    // dd mmm (2 OCT)
                case DateUtils.DATE_FORMAT_41: { // mmm dd (OCT 2)
                    var day = dateShort.day.format(integerFormat);
                    var month = null;

                    if (isForceDateEnglish) {
                        month = DateUtils.MONTHS[dateShort.month];
                    } else {
                        var dateMedium = Date.info(now, Time.FORMAT_MEDIUM);
                        month = dateMedium.month.toUpper();
                    }

                    if (dateFormat == DateUtils.DATE_FORMAT_4) {
                        return Lang.format(shortFormat, [day, month]);
                    }

                    return Lang.format(shortFormat, [month, day]);
                }
            }

            throw new Ex.InvalidValueException("Invalid type of 'dateFormat' in ':getFormattedDate'");
        }
    }

}
