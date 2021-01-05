using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Time.Gregorian as Date;
using Toybox.Lang;
using Constants as C;

module DataField {

    class TimeSecondaryDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var currentSettings = Sys.getDeviceSettings();
            var clockTime = Sys.getClockTime();
            var to_utc_second = clockTime.timeZoneOffset;

            var target = App.getApp().getProperty("utc_timezone");
            var shift_val = App.getApp().getProperty("utc_shift") ? 0.5 : 0.0;
            var secondary_zone_delta = (target + shift_val) * 3600 - to_utc_second;

            var now = Time.now();
            var now_target_zone_delta = new Time.Duration(secondary_zone_delta);
            var now_target_zone = now.add(now_target_zone_delta);
            var target_zone = Date.info(now_target_zone, Time.FORMAT_SHORT);

            var hour = target_zone.hour;
            var minute = target_zone.min;
            var mark = "";
            if(!currentSettings.is24Hour) {
                mark = (hour >= 12) ? "p" : "a";
                hour = hour % 12;
                hour = (hour == 0) ? 12 : hour;
            }

            return Lang.format("$1$:$2$ $3$", [hour.format(C.ZeroLeadingFormat), minute.format(C.ZeroLeadingFormat), mark]);
        }
    }

}
