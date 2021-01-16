using Toybox.System as Sys;
using Toybox.Application as App;
using RuntimeData as RD;
using SettingsEnums as SE;
using Toybox.Lang;
using Toybox.Math;

module DataField {

    class BatteryDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function min_val() {
            return 0.0;
        }

        function max_val() {
            return 100.0;
        }

        function cur_val() {
            return Sys.getSystemStats().battery;
        }

        function min_label(value) {
            return "b";
        }

        function max_label(value) {
            return "P";
        }

        function cur_label(value) {
            var battery_format = App.getApp().getProperty("battery_format");
            var hourConsumption = RD.batteryDataProvider.getLastHourConsumption();

            if (hourConsumption <= 0) {
                var consumptionHistory = RD.batteryDataProvider.getSavedConsumptionHistory();
                if (consumptionHistory != null) {
                    var total = 0.0;
                    for(var i = 0; i < consumptionHistory.size(); i++) {
                        total += consumptionHistory[i];
                    }
                    hourConsumption = total / consumptionHistory.size();
                } else {
                    var hourConsumptionSaved = RD.batteryDataProvider.getSavedLastHourConsumption();
                    if (hourConsumptionSaved != null) {
                        hourConsumption = hourConsumptionSaved;
                    }
                }
            }

            hourConsumption = hourConsumption.toFloat();

            if (battery_format == SE.BATTERY_FORMAT_PERCENTAGE || hourConsumption == -1) {
                return Lang.format("BAT $1$%", [Math.round(value).format("%d")]);
            }

            if (hourConsumption == 0) {
                return "99 DAYS";
            }

            var hoursLeft = value / (hourConsumption * 1.0);
            var daysLeft = hoursLeft / 24.0;
            return Lang.format("$1$ DAYS", [daysLeft.format("%0.1f")]);
        }

        function bar_data() {
            return true;
        }
    }

}
