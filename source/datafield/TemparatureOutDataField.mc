using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Lang;

module DataField {

    class TemparatureOutDataField extends BaseDataField {

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

                return "TEMP --";
            }

            value = weather_data["temp"].format("%d") + "°C";

            if (need_minimal) {
                return value;
            }

            return Lang.format("TEMP $1$",[value]);
        }
    }

}
