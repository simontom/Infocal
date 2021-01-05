using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Lang;

module DataField {

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
