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

    ////////////////
    // Time stage //
    ////////////////

    class TimeDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            return getTimeString();
        }

        function getTimeString() {
            var is24Hour = System.getDeviceSettings().is24Hour;

            var clockTime = Sys.getClockTime();
            var hour = clockTime.hour;
            var minute = clockTime.min.format(Constants.ZeroLeadingFormat);
            var mark = "";

            if(!is24Hour) {
                if (hour >= 12) {
                    mark = "p";
                } else {
                    mark = "a";
                }

                hour = hour % 12;
                hour = (hour == 0) ? 12 : hour;
            }

            return Lang.format("$1$:$2$ $3$", [hour.format(Constants.ZeroLeadingFormat), minute, mark]);
        }
    }

}
