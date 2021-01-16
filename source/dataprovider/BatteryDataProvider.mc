using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Time as T;

module DataProvider {

    class BatteryDataProvider {

        private var lastBatteryCalculation = null;
        private var lastBatteryPercent = -1;
        private var lastHourConsumption = -1;

        function initialize() {
            lastBatteryCalculation = T.now();
            lastBatteryPercent = Sys.getSystemStats().battery;
            lastHourConsumption = -1;
        }

        function getLastHourConsumption() {
            return lastHourConsumption;
        }

        function getSavedLastHourConsumption() {
            return App.getApp().getProperty("last_hour_consumption");
        }

        function getSavedConsumptionHistory() {
            return App.getApp().getProperty("consumption_history");
        }

        function calculateBatteryConsumption() {
            var timeNow = T.now();

            if (timeNow.compare(lastBatteryCalculation) >= 60 * 60) { // 60 min
                lastBatteryCalculation = timeNow;
                var current_battery = Sys.getSystemStats().battery;
                lastHourConsumption = lastBatteryPercent - current_battery;

                if (lastHourConsumption < 0) {
                    lastHourConsumption = -1;
                }

                if (lastHourConsumption > 0) {
                    App.getApp().setProperty("last_hour_consumption", lastHourConsumption);
                    updateConsumptionHistory(lastHourConsumption);
                }

                lastBatteryPercent = current_battery;
            }
        }

        private function updateConsumptionHistory(lastHourConsumption) {
            var consumptionHistory = App.getApp().getProperty("consumption_history");

            if (consumptionHistory == null) {
                App.getApp().setProperty("consumption_history", [lastHourConsumption]);
            } else {
                consumptionHistory.add(lastHourConsumption);

                if (consumptionHistory.size() > 24) {
                    var object0 = consumptionHistory[0];
                    consumptionHistory.remove(object0);
                }
                App.getApp().setProperty("consumption_history", consumptionHistory);
            }
        }

    }

}
