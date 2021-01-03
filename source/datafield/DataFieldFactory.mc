using DataField as DF;
using Toybox.Lang as Ex;
using SettingsEnums as SE;

module DataFieldFactory {

    function buildFieldObject(fieldType) {
        switch (fieldType) {
            case SE.FIELD_TYPE_HEART_RATE:         return new DF.HeartRateDataField(fieldType);
            case SE.FIELD_TYPE_BATTERY:            return new DF.BatteryDataField(fieldType);
            case SE.FIELD_TYPE_CALORIES:           return new DF.CaloriesDataField(fieldType);
            case SE.FIELD_TYPE_DISTANCE:           return new DF.DistanceDataField(fieldType);
            case SE.FIELD_TYPE_MOVE:               return new DF.MoveDataField(fieldType);
            case SE.FIELD_TYPE_STEP:               return new DF.StepDataField(fieldType);
            case SE.FIELD_TYPE_ACTIVE:             return new DF.ActiveDataField(fieldType);
            case SE.FIELD_TYPE_DATE:               return new DF.DateDataField(fieldType);
            case SE.FIELD_TYPE_TIME:               return new DF.TimeDataField(fieldType);
            case SE.FIELD_TYPE_EMPTY:              return new DF.EmptyDataField(fieldType);
            case SE.FIELD_TYPE_NOTIFICATIONS:      return new DF.NotificationDataField(fieldType);
            case SE.FIELD_TYPE_ALARMS:             return new DF.AlarmDataField(fieldType);
            case SE.FIELD_TYPE_ALTITUDE:           return new DF.AltitudeDataField(fieldType);
            case SE.FIELD_TYPE_TEMPERATURE:        return new DF.TemparatureDataField(fieldType);
            case SE.FIELD_TYPE_SUNRISE_SUNSET:     return new DF.SunDataField(fieldType);
            case SE.FIELD_TYPE_FLOOR:              return new DF.FloorDataField(fieldType);
            case SE.FIELD_TYPE_GROUP_NOTI:         return new DF.GroupNotiDataField(fieldType);
            case SE.FIELD_TYPE_DISTANCE_WEEK:      return new DF.WeekDistanceDataField(fieldType);
            case SE.FIELD_TYPE_BAROMETER:          return new DF.BarometerDataField(fieldType);
            case SE.FIELD_TYPE_TIME_SECONDARY:     return new DF.TimeSecondaryDataField(fieldType);
            case SE.FIELD_TYPE_PHONE_STATUS:       return new DF.PhoneDataField(fieldType);
            case SE.FIELD_TYPE_COUNTDOWN:          return new DF.CountdownDataField(fieldType);
            case SE.FIELD_TYPE_WEEKCOUNT:          return new DF.WeekCountDataField(fieldType);
            case SE.FIELD_TYPE_TEMPERATURE_OUT:    return new DF.TemparatureOutDataField(fieldType);
            case SE.FIELD_TYPE_TEMPERATURE_HL:     return new DF.TemparatureHLDataField(fieldType);
            case SE.FIELD_TYPE_WEATHER:            return new DF.WeatherDataField(fieldType);
            case SE.FIELD_TYPE_CTEXT_INDICATOR:    return new DF.CTextDataField(fieldType);
            case SE.FIELD_TYPE_WIND:               return new DF.WindDataField(fieldType);
        }

        throw new Ex.InvalidValueException("Invalid type of 'fieldType' in ':buildFieldObject'");
    }

}
