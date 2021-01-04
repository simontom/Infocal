using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Activity as Activity;
using Toybox.SensorHistory as SensorHistory;

module DataField {

    ////////////////////
    // Altitude stage //
    ////////////////////

    class AltitudeDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var need_minimal = App.getApp().getProperty("minimal_data");
            var value = 0;

            // #67 Try to retrieve altitude from current activity, before falling back on elevation history
            var settings = Sys.getDeviceSettings();
            var activityInfo = Activity.getActivityInfo();
            var altitude = activityInfo.altitude;

            if (altitude == null) {
                var sample = SensorHistory.getElevationHistory({ :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST })
                    .next();
                if ((sample != null) && (sample.data != null)) {
                    altitude = sample.data;
                }
            }

            if (altitude == null) {
                if (need_minimal) {
                    return "--";
                }

                return "ALT --";
            }

            var unit = "m";
            if (settings.elevationUnits != Sys.UNIT_METRIC) {
                altitude *= /* FT_PER_M */ 3.28084;
                unit = "ft";
            }

            value = altitude.format("%d") + unit;

            if (need_minimal) {
                return value;
            }

            return Lang.format("ALT $1$", [value]);
        }
    }

}
