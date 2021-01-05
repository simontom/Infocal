using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.ActivityMonitor as ActivityMonitor;
using ConversionUtils as CU;
using Toybox.Lang;

module DataField {

    class DistanceDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function max_val() {
            return 300000.0;
        }

        function cur_val() {
            var activityInfo = ActivityMonitor.getInfo();
            var value = activityInfo.distance.toFloat();
            return value;
        }

        function max_label(value) {
            var value = value / 1000.0;
            value = value / 100.0; // convert cm to km
            var valKp = CU.toKValue(value);
            return Lang.format("$1$K",[valKp]);
        }

        function cur_label(cm) {
            var need_minimal = App.getApp().getProperty("minimal_data");
            var settings = Sys.getDeviceSettings();

            var unit = "Km";
            var distance = cm / 100000;

            if (settings.distanceUnits != Sys.UNIT_METRIC) {
                unit = "Mi";
                distance *= 0.621371;
            }

            if (need_minimal) {
                return Lang.format("$1$ $2$", [distance.format("%0.1f"), unit]);
            }

            var valKp = CU.toKValue(distance * 1000);
            return Lang.format("DIS $1$$2$", [valKp, unit]);
        }

        function bar_data() {
            return true;
        }
    }

}
