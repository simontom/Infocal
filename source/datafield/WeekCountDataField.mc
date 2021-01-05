using Toybox.Lang;
using Toybox.Time.Gregorian as Date;

module DataField {

    class WeekCountDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var date = Date.info(Time.now(), Time.FORMAT_SHORT);
            var week_num = iso_week_number(date.year, date.month, date.day);

            return Lang.format("WEEK $1$",[week_num]);
        }

        private function iso_week_number(year, month, day) {
            var first_day_of_year = julian_day(year, 1, 1);
            var given_day_of_year = julian_day(year, month, day);

            var day_of_week = (first_day_of_year + 3) % 7; // days past thursday
            var week_of_year = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;

            // week is at end of this year or the beginning of next year
            if (week_of_year == 53) {
                if (day_of_week == 6) {
                    return week_of_year;
                } else if (day_of_week == 5 && is_leap_year(year)) {
                    return week_of_year;
                }

                return 1;
            } // week is in previous year, try again under that year
            else if (week_of_year == 0) {
                first_day_of_year = julian_day(year - 1, 1, 1);

                day_of_week = (first_day_of_year + 3) % 7;

                return (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
            }

            // any old week of the year
            return week_of_year;
        }

        private function julian_day(year, month, day) {
            var a = (14 - month) / 12;
            var y = (year + 4800 - a);
            var m = (month + 12 * a - 3);
            return day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 32045;
        }

        private function is_leap_year(year) {
            if (year % 4 != 0) {
                return false;
            } else if (year % 100 != 0) {
                return true;
            } else if (year % 400 == 0) {
                return true;
            }

            return false;
        }

    }

}
