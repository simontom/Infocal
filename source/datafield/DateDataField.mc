using RuntimeData as RD;

module DataField {

    ////////////////
    // Date stage //
    ////////////////

    class DateDataField extends BaseDataField {

        function initialize(id) {
            BaseDataField.initialize(id);
        }

        function cur_val() {
            return RD.formattedDateDataProvider.getFormattedDate();
        }

        function cur_label(value) {
            return value;
        }
    }

}
