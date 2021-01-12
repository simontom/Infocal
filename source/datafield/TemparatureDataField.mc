using Toybox.Application as App;
using Toybox.SensorHistory as SensorHistory;
using Toybox.Lang;

module DataField {

    class TemparatureDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var need_minimal = App.getApp().getProperty("minimal_data");
            var sample = SensorHistory.getTemperatureHistory(null).next();

            if ((sample == null) || (sample.data == null)) {
                if (need_minimal) {
                    return "--";
                }

                return "TEMP --";
            }

            var value = sample.data.format("%d") + "°C";

            if (need_minimal) {
                return value;
            }

            return Lang.format("TEMP $1$", [value]);
        }
    }

}
