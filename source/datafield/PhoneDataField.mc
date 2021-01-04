using Toybox.System as Sys;

module DataField {

    ////////////////////////
    // Phone status stage //
    ////////////////////////

    class PhoneDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_label(value) {
            var settings = Sys.getDeviceSettings();
            if (settings.phoneConnected) {
                return "CONN";
            }

            return "--";
        }
    }

}
