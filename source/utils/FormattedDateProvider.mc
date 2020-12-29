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
                case DATE_FORMAT_1: {
                    if (isForceDateEnglish) {
                        var day_of_weak = date.day_of_week;
                        return Lang.format("$1$ $2$", [DateUtils.DAYS[day_of_weak], date.day.format("%d")]);
                    }

                    var dateLong = Date.info(now, Time.FORMAT_LONG);
                    var day_of_weak = date.day_of_week;
                    return Lang.format("$1$ $2$", [day_of_weak.toUpper(), date.day.format("%d")]);
                }

                case DATE_FORMAT_2: {
                    // dd/mm
                    return Lang.format("$1$.$2$", [date.day.format("%d"), date.month.format("%d")]);
                }

                case DATE_FORMAT_21: {
                    // mm/dd
                    return Lang.format("$1$.$2$", [date.month.format("%d"), date.day.format("%d")]);
                }

                case DATE_FORMAT_3: {
                    // dd/mm/yyyy
                    var year = date.year;
                    var yy = year / 100.0;
                    yy = Math.round((yy - yy.toNumber()) * 100.0);
                    return Lang.format("$1$.$2$.$3$", [date.day.format("%d"), date.month.format("%d"), yy.format("%d")]);
                }

                case DATE_FORMAT_31: {
                    // mm/dd/yyyy
                    var year = date.year;
                    var yy = year / 100.0;
                    yy = Math.round((yy - yy.toNumber()) * 100.0);
                    return Lang.format("$1$.$2$.$3$", [date.month.format("%d"), date.day.format("%d"), yy.format("%d")]);
                }

                case DATE_FORMAT_4:
                case DATE_FORMAT_41: {
                    // dd mmm
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

                    if (dateFormat == DATE_FORMAT_4) {
                        return Lang.format("$1$ $2$", [day.format("%d"), month]);
                    }

                    return Lang.format("$1$ $2$", [month, day.format("%d")]);
                }
            }

            throw new Ex.InvalidValueException("Invalid type of 'dateFormat' in ':getFormattedDate'");
        }
    }

}
