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

    //////////////////
    // Active stage //
    //////////////////

    class ActiveDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function max_val() {
            var activityInfo = ActivityMonitor.getInfo();
            return activityInfo.activeMinutesWeekGoal.toFloat();
        }

        function cur_val() {
            var activityInfo = ActivityMonitor.getInfo();
            return activityInfo.activeMinutesWeek.total.toFloat();
        }

        function max_label(value) {
            return value.format("%d");
        }

        function cur_label(value) {
            return Lang.format("ACT $1$", [value.format("%d")]);
        }

        function bar_data() {
            return true;
        }
    }

}