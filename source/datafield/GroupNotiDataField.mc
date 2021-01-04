using Toybox.System as Sys;
using Toybox.Lang;

module DataField {

    //////////////////////
    // Group noti stage //
    //////////////////////

    class GroupNotiDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var settings = Sys.getDeviceSettings();
            var notificationCount = settings.notificationCount.format("%d");
            var alarmCount = settings.alarmCount.format("%d");
            var phoneConnected = settings.phoneConnected ? "C" : "D";

            return Lang.format("N$1$-A$2$-$3$", [notificationCount, alarmCount, phoneConnected]);
        }
    }

}
