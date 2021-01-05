using Toybox.Lang as L;
using Toybox.Lang as Ex;
using Toybox.Application.Properties;

module ApplicationDataWrapper {

    // INFO: Keep them readable so far until settings menu created
    class SettingsWrapper {
        private const keysDictionary = {
            :themeCode => "theme_code",
            :alwaysOnSecond => "always_on_second",
            :alwaysOnHeart => "always_on_heart",
            :digitalStyle => "digital_style",
            :alwaysOnStyle => "always_on_style",
            :bigNumberType => "big_number_type",
            :minimalData => "minimal_data",
            :bigNumStripes => "big_num_stripes",
            :leftDigitalInfo => "left_digital_info",
            :ticksStyle => "ticks_style",
            :comp12h => "comp12h",
            :comp2h => "comp2h",
            :comp4h => "comp4h",
            :comp6h => "comp6h",
            :comp8h => "comp8h",
            :comp10h => "comp10h",
            :compbart => "compbart",
            :compbarb => "compbarb",
            :compgrapht => "compgrapht",
            :compgraphb => "compgraphb",
            :utcTimezone => "utc_timezone",
            :utcShift => "utc_shift",
            :dateFormat => "date_format",
            :batteryFormat => "battery_format",
            :countdownDate => "countdown_date",
            :barometerUnit => "barometer_unit",
            :openweathermapApi => "openweathermap_api",
            :ctextInput => "ctext_input"
        };

        // Dictionary<key as String; FieldDataSettingsWrapper>
        private const _dataFields = {};

        function initialize() {
            initializeDataFields();
        }

        function reloadSettings() {
            var dataFields = _dataFields.values();
            var dataField;

            for(var i = 0; i < dataFields.size(); i++) {
                dataField = dataFields[i];
                dataField.reloadSettings();
            }
        }

        /**
            Key can be instance of:
                - String - e.g. "big_number_type"
                - Symbol - e.g. :bigNumberType
        */
        function getValue(key) {
            key = getKey(key);
            var dataField = getDataField(key);

            return dataField.getValue();
        }

        private function initializeDataFields() {
            var stringKeys = keysDictionary.values();
            var key;
            var dataField;

            for(var i = 0; i < stringKeys.size(); i++) {
                key = stringKeys[i];
                dataField = new ReadableDataField(Properties, key);
                _dataFields.put(key, dataField);
            }
        }

        private function getKey(key) {
            if (key == null) {
                throw new Ex.InvalidValueException("Key mustn't be null");
            }

            if (!((key instanceof String) || (key instanceof L.Symbol))) {
                throw new Ex.UnexpectedTypeException("Unexpected type of 'key', is not an instance of String nor Symbol");
            }

            if (key instanceof L.Symbol) {
                key = keysDictionary[key];
            }

            if (key == null) {
                throw new Ex.InvalidValueException("Key doesn't exist");
            }

            return key;
        }

        private function getDataField(key) {
            var dataField = _dataFields[key];

            if (dataField == null) {
                throw new Ex.InvalidValueException("DataField not found for '" + key + "'");
            }

            return dataField;
        }
    }

}
