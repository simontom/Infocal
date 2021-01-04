module DataField {

    class EmptyDataField {

        function initialize(id) {
            _field_id = id;
        }

        private var _field_id;

        function field_id() {
            return _field_id;
        }

        function need_draw() {
            return false;
        }
    }

}
