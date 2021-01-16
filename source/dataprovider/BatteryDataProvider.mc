using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Time as T;

module DataProvider {

    class BatteryDataProvider {

        private var lastBatteryCalculation = null;
        private var last_battery_percent = -1;
        private var last_hour_consumtion = -1;

        function getLastHourConsumption() {
            return last_hour_consumtion;
        }

        function getSavedLastHourConsumption() {
            return App.getApp().getProperty("last_hour_consumtion");
        }

        function getSavedConsumptionHistory() {
            return App.getApp().getProperty("consumtion_history");
        }

        function calculateBatteryConsumption() {
            var timeNow = T.now();

            if (lastBatteryCalculation == null) {
                lastBatteryCalculation = timeNow;
                last_battery_percent = Sys.getSystemStats().battery;
                last_hour_consumtion = -1;
            } else if (timeNow.compare(lastBatteryCalculation) >= 60 * 60) { // 60 min
                lastBatteryCalculation = timeNow;
                var current_battery = Sys.getSystemStats().battery;
                last_hour_consumtion = last_battery_percent - current_battery;

                if (last_hour_consumtion < 0) {
                    last_hour_consumtion = -1;
                }

                if (last_hour_consumtion > 0) {
                    App.getApp().setProperty("last_hour_consumtion", last_hour_consumtion);
                    updateConsumptionHistory(last_hour_consumtion);
                }

                last_battery_percent = current_battery;
            }
        }

        private function updateConsumptionHistory(lastHourConsumption) {
            var consumtion_history = App.getApp().getProperty("consumtion_history");

            if (consumtion_history == null) {
                App.getApp().setProperty("consumtion_history", [lastHourConsumption]);
            } else {
                consumtion_history.add(lastHourConsumption);

                if (consumtion_history.size() > 24) {
                    var object0 = consumtion_history[0];
                    consumtion_history.remove(object0);
                }
                App.getApp().setProperty("consumtion_history", consumtion_history);
            }
        }

    }

}
