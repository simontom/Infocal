using Toybox.System as Sys;
using Toybox.Lang;

module DataField {

    class AlarmDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_val() {
            var settings = Sys.getDeviceSettings();
            return settings.alarmCount;
        }

        function cur_label(value) {
            return Lang.format("ALAR $1$", [value.format("%d")]);
        }
    }

}
