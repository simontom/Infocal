using Toybox.System as Sys;
using Toybox.Lang;

module DataField {

    ////////////////////////
    // Notification stage //
    ////////////////////////

    class NotificationDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var settings = Sys.getDeviceSettings();
            var value = settings.notificationCount;

            return Lang.format("NOTIF $1$", [value.format("%d")]);
        }
    }

}
