using Toybox.System as Sys;
using Toybox.Lang;

module DataField {

    ////////////////
    // Time stage //
    ////////////////

    class TimeDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            return getTimeString();
        }

        function getTimeString() {
            var is24Hour = Sys.getDeviceSettings().is24Hour;

            var clockTime = Sys.getClockTime();
            var hour = clockTime.hour;
            var minute = clockTime.min.format(Constants.ZeroLeadingFormat);
            var mark = "";

            if(!is24Hour) {
                if (hour >= 12) {
                    mark = "p";
                } else {
                    mark = "a";
                }

                hour = hour % 12;
                hour = (hour == 0) ? 12 : hour;
            }

            return Lang.format("$1$:$2$ $3$", [hour.format(Constants.ZeroLeadingFormat), minute, mark]);
        }
    }

}
