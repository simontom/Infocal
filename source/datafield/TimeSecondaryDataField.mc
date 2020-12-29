using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Activity as Activity;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.SensorHistory as SensorHistory;
using RuntimeData as RD;
using Toybox.Lang as Ex;
using ConversionUtils as CU;
using Toybox.UserProfile;
using Toybox.Time;
using Toybox.Time.Gregorian as Date;

module DataField {

    //////////////////////////
    // Time secondary stage //
    //////////////////////////

    class TimeSecondaryDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var currentSettings = System.getDeviceSettings();
            var clockTime = Sys.getClockTime();
            var to_utc_second = clockTime.timeZoneOffset;

            var target = App.getApp().getProperty("utc_timezone");
            var shift_val = App.getApp().getProperty("utc_shift") ? 0.5 : 0.0;
            var secondary_zone_delta = (target+shift_val)*3600 - to_utc_second;

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

            return Lang.format("$1$:$2$ $3$",[hour.format(Constants.ZeroLeadingFormat), minute.format(Constants.ZeroLeadingFormat), mark]);
        }
    }

}
