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
    // Move stage //
    ////////////////

    class MoveDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function min_val() {
            return ActivityMonitor.MOVE_BAR_LEVEL_MIN;
        }

        function max_val() {
            return ActivityMonitor.MOVE_BAR_LEVEL_MAX;
        }

        function cur_val() {
            var info = ActivityMonitor.getInfo();
            var currentBar = info.moveBarLevel.toFloat();
            return currentBar.toFloat();
        }

        function min_label(value) {
            return value.format("%d");
        }

        function max_label(value) {
            return Lang.format("$1$", [(value).format("%d")]);
        }

        function cur_label(value) {
            return Lang.format("MOVE $1$", [value.format("%d")]);
        }

        function bar_data() {
            return true;
        }
    }

}
