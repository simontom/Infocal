using Toybox.Lang as Ex;

module ApplicationDataWrapper {

    class ReadableDataField {
        protected var _dataModule;
        protected var _key;
        protected var _value;

        function initialize(dataModule, key) {
            ensureInitializeArguments(dataModule, key);
            ensureDataModulePosibilities(dataModule);

            _dataModule = dataModule;
            _key = key;
            reloadSettings();
        }

        function reloadSettings() {
            _value = _dataModule.getValue(_key);
        }

        function getValue() {
            return _value;
        }

        protected function ensureInitializeArguments(dataModule, key) {
            if ((dataModule == null) || (key == null)) {
                throw new Ex.InvalidValueException("DataModule & Key mustn't be null");
            }
        }

        protected function ensureDataModulePosibilities(dataModule) {
            if (!(dataModule has :getValue)) {
                throw new Ex.UnexpectedTypeException("Missing ':getValue' function on '_dataModule'");
            }
        }
    }

}
