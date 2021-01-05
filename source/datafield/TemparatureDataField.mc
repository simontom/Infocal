using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.SensorHistory as SensorHistory;
using ConversionUtils as CU;
using Toybox.Lang;

module DataField {

    class TemparatureDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var need_minimal = App.getApp().getProperty("minimal_data");
            var value = 0;
            var settings = Sys.getDeviceSettings();
            var sample = SensorHistory.getTemperatureHistory(null).next();

            if ((sample == null) || (sample.data == null)) {
                if (need_minimal) {
                    return "--";
                }

                return "TEMP --";
            }

            var unit = "°C";
            var temperature = sample.data;
            if (settings.temperatureUnits == Sys.UNIT_STATUTE) {
                unit = "°F";
                temperature = CU.toFahrenheit(temperature);
            }

            value = temperature.format("%d") + unit;

            if (need_minimal) {
                return value;
            }

            return Lang.format("TEMP $1$", [value]);
        }
    }

}
