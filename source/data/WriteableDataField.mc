using Toybox.Lang as Ex;

module ApplicationDataWrapper {

    class WriteableDataField extends ReadableDataField {

        function initialize(dataModule, key) {
            ReadableDataField.initialize(dataModule, key);
        }

        function setValue(value) {
            _dataModule.setValue(_key, value);
            _value = value;
        }

        protected function ensureDataModulePosibilities(dataModule) {
            WriteableDataField.ensureDataModulePosibilities(dataModule);

            if (!(dataModule has :setValue)) {
                throw new Ex.UnexpectedTypeException("Missing ':setValue' function on '_dataModule'");
            }
        }
    }

}
