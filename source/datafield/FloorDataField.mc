using Toybox.ActivityMonitor as AM;
using Toybox.Lang;

module DataField {

    /////////////////
    // Floor stage //
    /////////////////

    class FloorDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function max_val() {
            var activityInfo = AM.getInfo();
            return activityInfo.floorsClimbedGoal.toFloat();
        }

        function cur_val() {
            var activityInfo = AM.getInfo();
            return activityInfo.floorsClimbed.toFloat();
        }

        function max_label(value) {
            return value.format("%d");
        }

        function cur_label(value) {
            if (value == null) {
                return "FLOOR --";
            }

            return Lang.format("FLOOR $1$",[value.format("%d")]);
        }

        function bar_data() {
            return true;
        }
    }

}
