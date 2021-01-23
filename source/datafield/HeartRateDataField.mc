using Toybox.Activity as Activity;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Lang;

module DataField {

    class HeartRateDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function min_val() {
            return 50.0;
        }

        function max_val() {
            return 120.0;
        }

        function cur_val() {
            var heartRate = retrieveHeartRate();
            return heartRate.toFloat();
        }

        function min_label(value) {
            return value.format("%d");
        }

        function max_label(value) {
            return value.format("%d");
        }

        function cur_label(heartRate) {
            if (heartRate <= 1) {
                return "HR --";
            }

            return Lang.format("HR $1$", [heartRate.format("%d")]);
        }

        function bar_data() {
            return true;
        }

        private function retrieveHeartRate() {
            var currentHeartrate = 0.0;
            var activityInfo = Activity.getActivityInfo();
            var sample = activityInfo.currentHeartRate;

            if (sample != null) {
                currentHeartrate = sample;
            } else {
                sample = ActivityMonitor.getHeartRateHistory(1, /* newestFirst */ true)
                    .next();
                if ((sample != null) && (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
                    currentHeartrate = sample.heartRate;
                }
            }

            return currentHeartrate.toFloat();
        }
    }

    //////////////////
    // end HR stage //
    //////////////////

}
