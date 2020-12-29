using Toybox.Time.Gregorian as Date;
using Toybox.Lang as Ex;

module DateUtils {

    const DAYS = {
            Date.DAY_MONDAY => "MON",
            Date.DAY_TUESDAY => "TUE",
            Date.DAY_WEDNESDAY => "WED",
            Date.DAY_THURSDAY => "THU",
            Date.DAY_FRIDAY => "FRI",
            Date.DAY_SATURDAY => "SAT",
            Date.DAY_SUNDAY => "SUN"
        };

    const MONTHS = {
            Date.MONTH_JANUARY => "JAN",
            Date.MONTH_FEBRUARY => "FEB",
            Date.MONTH_MARCH => "MAR",
            Date.MONTH_APRIL => "APR",
            Date.MONTH_MAY => "MAY",
            Date.MONTH_JUNE => "JUN",
            Date.MONTH_JULY => "JUL",
            Date.MONTH_AUGUST => "AUG",
            Date.MONTH_SEPTEMBER => "SEP",
            Date.MONTH_OCTOBER => "OCT",
            Date.MONTH_NOVEMBER => "NOV",
            Date.MONTH_DECEMBER => "DEC"
        };

    enum /* DATE_FORMATS */ {
        DATE_FORMAT_1 = 0,      // dof d (TUE 2)
        DATE_FORMAT_2 = 1,      // dd.mm (2.9)
        DATE_FORMAT_21 = 2,     // mm.dd (9.2)
        DATE_FORMAT_3 = 3,      // dd.mm.yy (2.9.19)
        DATE_FORMAT_31 = 4,     // mm.dd.yy (9.2.19)
        DATE_FORMAT_4 = 5,      // dd mmm (2 OCT)
        DATE_FORMAT_41 = 6      // mmm dd (OCT 2)
    }

}
