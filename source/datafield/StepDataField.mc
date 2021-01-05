using Toybox.Application as App;
using Toybox.ActivityMonitor as ActivityMonitor;
using ConversionUtils as CU;
using Toybox.Lang;

module DataField {

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
