using Toybox.Application as App;
using Toybox.Time;
using Toybox.System as Sys;
using Toybox.WatchUi;
using Toybox.StringUtil;

// Beta: 50ac2551-8763-44be-8bbd-e333997b0231
// Prod: 2c3dfe98-f99e-43c7-95da-045af2c71777


function momentToString(moment, is24Hour, showAM) {

    if (moment == null) {return "-";}

    //var tinfo = Time.Gregorian.info(new Time.Moment(moment.value() + 30), Time.FORMAT_SHORT);
    var tinfo = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
    var text;
    if (is24Hour) {text = tinfo.hour.format("%u") + ":" + tinfo.min.format("%02d");} 
    else {
        var hour = tinfo.hour % 12;
        if (hour == 0) {hour = 12;}
        text = hour.format("%u") + ":" + tinfo.min.format("%02d") + (showAM ? (tinfo.hour < 12 ? "a" : "p") : "");
    }
    return text;
}

function capitalize(s) {
	if (s == null || s.length() == 0) {return s;}
	return s.substring(0,1).toUpper() + (s.length() == 1 ? "" : s.substring(1, s.length()).toLower());
}

function R(s) {return WatchUi.loadResource(s);}

function celsius2fahrenheit(c) {return (c * 1.8) + 32;}

function windDegreeToName (windDegree) {
	var windName = "";
	if (windDegree != null) {
		if      (windDegree < 12.25 ) {windName = "N";}
		else if (windDegree < 34.75 ) {windName = "NNE";}
		else if (windDegree < 57.25 ) {windName = "NE";}
		else if (windDegree < 79.75 ) {windName = "ENE";}
		else if (windDegree < 102.25) {windName = "E";}
		else if (windDegree < 124.75) {windName = "ESE";}
		else if (windDegree < 147.25) {windName = "SE";}
		else if (windDegree < 169.75) {windName = "SSE";}
		else if (windDegree < 192.25) {windName = "S";}
		else if (windDegree < 214.75) {windName = "SSW";}
		else if (windDegree < 237.25) {windName = "SW";}
		else if (windDegree < 259.75) {windName = "WSW";}
		else if (windDegree < 282.25) {windName = "W";}
		else if (windDegree < 304.75) {windName = "WNW";}
		else if (windDegree < 327.45) {windName = "NW";}
		else if (windDegree < 349.75) {windName = "NNW";}
        else {windName = "N";}
	}
	return windName;
}

const DEGREE_SYMBOL = "\u00B0";

(:background)
function p(p) {Sys.println(p);}
