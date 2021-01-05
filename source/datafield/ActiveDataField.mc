using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Lang;

module DataField {

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
