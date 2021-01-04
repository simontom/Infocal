using Toybox.System as Sys;
using Toybox.Application as App;
using ConversionUtils as CU;
using Toybox.Lang;

module DataField {

    ///////////////////////////
    // Temparature hl stage //
    ///////////////////////////

    class TemparatureHLDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            // WEATHER
            var need_minimal = App.getApp().getProperty("minimal_data");
            var weather_data = App.getApp().getProperty("OpenWeatherMapCurrent");

            if (weather_data == null) {
                if (need_minimal) {
                    return "--";
                }

                return "H - L -";
            }

            var settings = Sys.getDeviceSettings();
            var temp_min = weather_data["temp_min"];
            var temp_max = weather_data["temp_max"];
            var unit = "°C";
            if (settings.temperatureUnits == System.UNIT_STATUTE) {
                temp_min = CU.toFahrenheit(temp_min);
                temp_max = CU.toFahrenheit(temp_max);
                unit = "°F";
            }

            if (need_minimal) {
                return Lang.format("$1$ $2$",[temp_max.format("%d"), temp_min.format("%d")]);
            }

            return Lang.format("H $1$ L $2$",[temp_max.format("%d"), temp_min.format("%d")]);
        }
    }

}
