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
using SettingsEnums as SE;

module DataField {

    ///////////////////
    // Battery stage //
    ///////////////////

    class BatteryDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function min_val() {
            return 0.0;
        }

        function max_val() {
            return 100.0;
        }

        function cur_val() {
            return Sys.getSystemStats().battery;
        }

        function min_label(value) {
            return "b";
        }

        function max_label(value) {
            return "P";
        }

        function cur_label(value) {
            var battery_format = App.getApp().getProperty("battery_format");
            var hour_consumtion = RD.last_hour_consumtion;

            if (hour_consumtion <= 0) {
                var consumtion_history = App.getApp().getProperty("consumtion_history");
                if (consumtion_history != null) {
                    var total = 0.0;
                    for(var i = 0; i < consumtion_history.size(); i++) {
                        total += consumtion_history[i];
                    }
                    hour_consumtion = total / consumtion_history.size();
                } else {
                    var hour_consumtion_saved = App.getApp().getProperty("last_hour_consumtion");
                    if (hour_consumtion_saved != null) {
                        hour_consumtion = hour_consumtion_saved;
                    }
                }
            }

            hour_consumtion = hour_consumtion.toFloat();

            if (battery_format == SE.BATTERY_FORMAT_PERCENTAGE || hour_consumtion == -1) {
                return Lang.format("BAT $1$%", [Math.round(value).format("%d")]);
            }

            if (hour_consumtion == 0) {
                return "99 DAYS";
            }

            var hoursLeft = value / (hour_consumtion * 1.0);
            var daysLeft = hoursLeft / 24.0;
            return Lang.format("$1$ DAYS", [daysLeft.format("%0.1f")]);
        }

        function bar_data() {
            return true;
        }
    }

}
