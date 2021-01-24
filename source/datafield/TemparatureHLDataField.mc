using Toybox.Application as App;
using Toybox.Lang;
using RuntimeData as RD;

module DataField {

    class TemparatureHLDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            // WEATHER
            var need_minimal = App.getApp().getProperty("minimal_data");
            var weather_data = RD.weatherDataProvider.getWeather();

            if (weather_data == null) {
                if (need_minimal) {
                    return "--";
                }

                return "H - L -";
            }

            var temp_min = weather_data["temp_min"];
            var temp_max = weather_data["temp_max"];

            if (need_minimal) {
                return Lang.format("$1$ $2$",[temp_max.format("%d"), temp_min.format("%d")]);
            }

            return Lang.format("H $1$ L $2$",[temp_max.format("%d"), temp_min.format("%d")]);
        }
    }

}
