using Toybox.System as Sys;
using Toybox.Application as App;
using ConversionUtils as CU;

module DataField {

    ///////////////////
    // Weather stage //
    ///////////////////

    class WeatherDataField extends BaseDataField {

        var weather_icon_mapper;

        function initialize(id) {
            BaseDataField.initialize(id);

            weather_icon_mapper = {
                "01d" => "",
                "02d" => "",
                "03d" => "",
                "04d" => "",
                "09d" => "",
                "10d" => "",
                "11d" => "",
                "13d" => "",
                "50d" => "",

                "01n" => "",
                "02n" => "",
                "03n" => "",
                "04n" => "",
                "09n" => "",
                "10n" => "",
                "11n" => "",
                "13n" => "",
                "50n" => "",
            };
        }

        function cur_icon() {
            var weather_data = App.getApp().getProperty("OpenWeatherMapCurrent");

            if (weather_data != null) {
                return weather_icon_mapper[weather_data["icon"]];
            }

            return null;
        }

        function cur_label(value) {
            // WEATHER
            var weather_data = App.getApp().getProperty("OpenWeatherMapCurrent");

            if (weather_data != null) {
                var settings = Sys.getDeviceSettings();
                var temp = weather_data["temp"];
                var unit = "°C";
                if (settings.temperatureUnits == System.UNIT_STATUTE) {
                    temp = CU.toFahrenheit(temp);
                    unit = "°F";
                }
                value = temp.format("%d") + unit;

                var description = weather_data.get("des");
                if (description != null) {
                    return description + " " +  value;
                }
            }

            return "--";
        }
    }

}
