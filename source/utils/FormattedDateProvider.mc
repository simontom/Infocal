using Toybox.Time.Gregorian as Date;
using Toybox.Lang as Ex;

module DateUtils {

    class FormattedDateProvider {
        private var dateFormat;
        private var isForceDateEnglish;

        function initialize() {
            reloadSettings();
        }

        function reloadSettings() {
            dateFormat = Application.getApp().getProperty("date_format");
            isForceDateEnglish = Application.getApp().getProperty("force_date_english");
        }

        function getFormattedDate() {
            var now = Time.now();
            var date = Date.info(now, Time.FORMAT_SHORT);

            switch (dateFormat) {
                case DateUtils.DATE_FORMAT_1: {
                    if (isForceDateEnglish) {
                        var dayOfWeek = date.day_of_week;
                        return Lang.format("$1$ $2$", [DateUtils.DAYS[dayOfWeek], date.day.format("%d")]);
                    }

                    var dateLong = Date.info(now, Time.FORMAT_LONG);
                    var dayOfWeek = date.day_of_week;
                    return Lang.format("$1$ $2$", [dayOfWeek.toUpper(), date.day.format("%d")]);
                }

                case DateUtils.DATE_FORMAT_2:
                    return Lang.format("$1$.$2$", [date.day.format("%d"), date.month.format("%d")]);

                case DateUtils.DATE_FORMAT_21:
                    return Lang.format("$1$.$2$", [date.month.format("%d"), date.day.format("%d")]);

                case DateUtils.DATE_FORMAT_3: {
                    var year = date.year;
                    var yy = year / 100.0;
                    yy = Math.round((yy - yy.toNumber()) * 100.0);
                    return Lang.format("$1$.$2$.$3$", [date.day.format("%d"), date.month.format("%d"), yy.format("%d")]);
                }

                case DateUtils.DATE_FORMAT_31: {
                    var year = date.year;
                    var yy = year / 100.0;
                    yy = Math.round((yy - yy.toNumber()) * 100.0);
                    return Lang.format("$1$.$2$.$3$", [date.month.format("%d"), date.day.format("%d"), yy.format("%d")]);
                }

                case DateUtils.DATE_FORMAT_4:
                case DateUtils.DATE_FORMAT_41: {
                    var day = null;
                    var month = null;
                    if (isForceDateEnglish) {
                        day = date.day;
                        month = DateUtils.MONTHS[date.month];
                    } else {
                        var date = Date.info(now, Time.FORMAT_MEDIUM);
                        day = date.day;
                        month = DateUtils.MONTHS[date.month];
                    }

                    if (dateFormat == DateUtils.DATE_FORMAT_4) {
                        return Lang.format("$1$ $2$", [day.format("%d"), month]);
                    }

                    return Lang.format("$1$ $2$", [month, day.format("%d")]);
                }
            }

            throw new Ex.InvalidValueException("Invalid type of 'dateFormat' in ':getFormattedDate'");
        }
    }

}
