module SettingsEnums {

    enum /* DATE_FORMATS */ {
        DATE_FORMAT_1 = 0,      // dof d (TUE 2)
        DATE_FORMAT_2 = 1,      // dd.mm (2.9)
        DATE_FORMAT_21 = 2,     // mm.dd (9.2)
        DATE_FORMAT_3 = 3,      // dd.mm.yy (2.9.19)
        DATE_FORMAT_31 = 4,     // mm.dd.yy (9.2.19)
        DATE_FORMAT_4 = 5,      // dd mmm (2 OCT)
        DATE_FORMAT_41 = 6      // mmm dd (OCT 2)
    }

    enum /* DIGITAL_STYLES */ {
        DIGITAL_STYLE_XBIG = 2,
        DIGITAL_STYLE_BIG = 0,
        DIGITAL_STYLE_MEDIUM = 3,
        DIGITAL_STYLE_SMALL = 1
    }

    enum /* ALWAYS_ON_STYLES */ {
        ALWAYS_ON_STYLE_MEDIUM = 1,
        ALWAYS_ON_STYLE_SMALL = 0
    }

    enum /* BIG_NUMBER_TYPES */ {
        BIG_NUMBER_TYPE_MINUTE_IN_CENTER = 0,
        BIG_NUMBER_TYPE_HOUR_IN_CENTER = 1
    }

    enum /* TICKS_STYLES */ {
        TICKS_STYLE_EMPTY = 0,
        TICKS_STYLE_ARC = 1,
        TICKS_STYLE_MARKS = 2
    }

    enum /* FIELD_TYPES */ {
        FIELD_TYPE_HEART_RATE = 0,
        FIELD_TYPE_BATTERY = 1,
        FIELD_TYPE_CALORIES = 2,
        FIELD_TYPE_DISTANCE = 3,
        FIELD_TYPE_MOVE = 4,
        FIELD_TYPE_STEP = 5,
        FIELD_TYPE_ACTIVE = 6,

        FIELD_TYPE_DATE = 7,
        FIELD_TYPE_TIME = 8,
        FIELD_TYPE_EMPTY = 9,

        FIELD_TYPE_NOTIFICATIONS = 10,
        FIELD_TYPE_ALARMS = 11,
        FIELD_TYPE_ALTITUDE = 12,
        FIELD_TYPE_TEMPERATURE = 13,
        FIELD_TYPE_SUNRISE_SUNSET = 14,
        FIELD_TYPE_FLOOR = 15,
        FIELD_TYPE_GROUP_NOTI = 16,
        FIELD_TYPE_DISTANCE_WEEK = 17,
        FIELD_TYPE_BAROMETER = 18,
        FIELD_TYPE_TIME_SECONDARY = 19,
        FIELD_TYPE_PHONE_STATUS = 20,
        FIELD_TYPE_COUNTDOWN = 21,
        FIELD_TYPE_WEEKCOUNT = 22,

        FIELD_TYPE_TEMPERATURE_OUT = 23,
        FIELD_TYPE_TEMPERATURE_HL = 24,
        FIELD_TYPE_WEATHER = 25,

        FIELD_TYPE_CTEXT_INDICATOR = 27,
        FIELD_TYPE_WIND = 28
    }

    enum /* GRAPH_FIELD_TYPES */ {
        GRAPH_FIELD_TYPE_EMPTY = 0,
        GRAPH_FIELD_TYPE_HEARTRATE = 1,
        GRAPH_FIELD_TYPE_ALTITUDE = 2,
        GRAPH_FIELD_TYPE_BAROMETER = 3,
        GRAPH_FIELD_TYPE_TEMPERATURE = 4
    }

    enum /* BATTERY_FORMATS */ {
        BATTERY_FORMAT_PERCENTAGE = 0,
        BATTERY_FORMAT_DAYS = 1
    }

    enum /* BAROMETER_UNITS */ {
        BAROMETER_UNIT_HPA = 0,
        BAROMETER_UNIT_INHG = 1
    }

}
