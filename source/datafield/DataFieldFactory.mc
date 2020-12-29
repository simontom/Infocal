using DataField as DF;
using Toybox.Lang as Ex;

module DataFieldFactory {

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

    function buildFieldObject(fieldType) {
        switch (fieldType) {
            case FIELD_TYPE_HEART_RATE:         return new DF.HeartRateDataField(fieldType);
            case FIELD_TYPE_BATTERY:            return new DF.BatteryDataField(fieldType);
            case FIELD_TYPE_CALORIES:           return new DF.CaloriesDataField(fieldType);
            case FIELD_TYPE_DISTANCE:           return new DF.DistanceDataField(fieldType);
            case FIELD_TYPE_MOVE:               return new DF.MoveDataField(fieldType);
            case FIELD_TYPE_STEP:               return new DF.StepDataField(fieldType);
            case FIELD_TYPE_ACTIVE:             return new DF.ActiveDataField(fieldType);
            case FIELD_TYPE_DATE:               return new DF.DateDataField(fieldType);
            case FIELD_TYPE_TIME:               return new DF.TimeDataField(fieldType);
            case FIELD_TYPE_EMPTY:              return new DF.EmptyDataField(fieldType);
            case FIELD_TYPE_NOTIFICATIONS:      return new DF.NotificationDataField(fieldType);
            case FIELD_TYPE_ALARMS:             return new DF.AlarmDataField(fieldType);
            case FIELD_TYPE_ALTITUDE:           return new DF.AltitudeDataField(fieldType);
            case FIELD_TYPE_TEMPERATURE:        return new DF.TemparatureDataField(fieldType);
            case FIELD_TYPE_SUNRISE_SUNSET:     return new DF.SunDataField(fieldType);
            case FIELD_TYPE_FLOOR:              return new DF.FloorDataField(fieldType);
            case FIELD_TYPE_GROUP_NOTI:         return new DF.GroupNotiDataField(fieldType);
            case FIELD_TYPE_DISTANCE_WEEK:      return new DF.WeekDistanceDataField(fieldType);
            case FIELD_TYPE_BAROMETER:          return new DF.BarometerDataField(fieldType);
            case FIELD_TYPE_TIME_SECONDARY:     return new DF.TimeSecondaryDataField(fieldType);
            case FIELD_TYPE_PHONE_STATUS:       return new DF.PhoneDataField(fieldType);
            case FIELD_TYPE_COUNTDOWN:          return new DF.CountdownDataField(fieldType);
            case FIELD_TYPE_WEEKCOUNT:          return new DF.WeekCountDataField(fieldType);
            case FIELD_TYPE_TEMPERATURE_OUT:    return new DF.TemparatureOutDataField(fieldType);
            case FIELD_TYPE_TEMPERATURE_HL:     return new DF.TemparatureHLDataField(fieldType);
            case FIELD_TYPE_WEATHER:            return new DF.WeatherDataField(fieldType);
            case FIELD_TYPE_CTEXT_INDICATOR:    return new DF.CTextDataField(fieldType);
            case FIELD_TYPE_WIND:               return new DF.WindDataField(fieldType);
        }

        throw new Ex.InvalidValueException("Invalid type of 'fieldType' in ':buildFieldObject'");
    }

}
