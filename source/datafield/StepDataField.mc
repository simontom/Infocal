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

    /////////////////
    // Steps stage //
    /////////////////

    class StepDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function max_val() {
            return ActivityMonitor.getInfo().stepGoal.toFloat();
        }

        function cur_val() {
            var currentStep = ActivityMonitor.getInfo().steps;
            return currentStep.toFloat();
        }

        function max_label(value) {
            var valKp = CU.toKValue(value);
            return Lang.format("$1$K",[valKp]);
        }

        function cur_label(value) {
            var need_minimal = App.getApp().getProperty("minimal_data");
            var currentStep = value;

            if (need_minimal) {
                if (currentStep > 999) {
                    return currentStep.format("%d");
                }

                return Lang.format("STEP $1$",[currentStep.format("%d")]);
            }

            var valKp = CU.toKValue(currentStep);
            return Lang.format("STEP $1$K",[valKp]);
        }

        function bar_data() {
            return true;
        }
    }

}
