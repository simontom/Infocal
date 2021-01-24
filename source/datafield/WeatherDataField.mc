using Toybox.Application as App;
using RuntimeData as RD;

module DataField {

    class WeatherDataField extends BaseDataField {

        private var weather_icon_mapper;

        function initialize(id) {
            BaseDataField.initialize(id);

            weather_icon_mapper = {
                "01d" => 61453.toChar(),
                "02d" => 61442.toChar(),
                "03d" => 61505.toChar(),
                "04d" => 61459.toChar(),
                "09d" => 61466.toChar(),
                "10d" => 61448.toChar(),
                "11d" => 61470.toChar(),
                "13d" => 61467.toChar(),
                "50d" => 61539.toChar(),

                "01n" => 61486.toChar(),
                "02n" => 61574.toChar(),
                "03n" => 61505.toChar(),
                "04n" => 61459.toChar(),
                "09n" => 61466.toChar(),
                "10n" => 61480.toChar(),
                "11n" => 61470.toChar(),
                "13n" => 61467.toChar(),
                "50n" => 61539.toChar(),
            };
        }

        function cur_icon() {
            var weather_data = RD.weatherDataProvider.getWeather();

            if (weather_data != null) {
                return weather_icon_mapper[weather_data["icon"]];
            }

            return null;
        }

        function cur_label(value) {
            // WEATHER
            var weather_data = RD.weatherDataProvider.getWeather();

            if (weather_data != null) {
                var temp = weather_data["temp"];
                value = temp.format("%d") + "°C";

                var description = weather_data.get("des");
                if (description != null) {
                    return description + " " +  value;
                }
            }

            return "--";
        }
    }

}
