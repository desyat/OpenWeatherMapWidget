using Toybox.Activity;
using Toybox.Time;
using Toybox.Graphics as G;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Communications as Comms;
using Toybox.Application as App;
using Toybox.Position;
using Toybox.Timer;

class OpenWeatherWidgetView extends Ui.View {

	var W;
	var H;
	var iconsFont;
	var screenNum = 1;
	var gpsRequested = false;

	var isInstinct = false;
	var instSubscr = null;
	var instSubscrCentr = null;

	var updateTimer = new Timer.Timer();
    var apiKeyPresent = false;
    var locationPresent = false;
    
	var weatherData = null;
	var owmRetryCount = 5;
	var owmTimer = new Timer.Timer();

	var iconsDictionary = {
		"01d" => Rez.Drawables.d01,
		"01n" => Rez.Drawables.n01,
		"02d" => Rez.Drawables.d02,
		"02n" => Rez.Drawables.n02,
		"03d" => Rez.Drawables.d03,
		"03n" => Rez.Drawables.n03,
		"04d" => Rez.Drawables.d04,
		"04n" => Rez.Drawables.n04,
		"09d" => Rez.Drawables.d09,
		"09n" => Rez.Drawables.n09,
		"10d" => Rez.Drawables.d10,
		"10n" => Rez.Drawables.n10,
		"11d" => Rez.Drawables.d11,
		"11n" => Rez.Drawables.n11,
		"13d" => Rez.Drawables.d13,
		"13n" => Rez.Drawables.n13,
		"50d" => Rez.Drawables.d50,
		"50n" => Rez.Drawables.n50
	};
	
	var speedUnitsCode = 1; // [4]
	var speedMultiplier = 3.6; // [0]
	var speedUnits = "kmh"; // [1]
	var tempCelsius = true; // [2]
	var tempSymbol = $.DEGREE_SYMBOL; // [3]
	var pressureDivider = 1;
	
    function initialize() {
        View.initialize();
        updateSettings();
    }

    function updateSettings() {
		var MPH_IN_METERS_PER_SECOND = 2.23694;
		var KMH_IN_METERS_PER_SECOND = 3.6;
		var KTS_IN_METERS_PER_SECOND = 1.944;
		
		//var settingsArr = [KMH_IN_METERS_PER_SECOND, "kmh", true, $.DEGREE_SYMBOL, 1, 1];
	
		speedUnitsCode = App.Properties.getValue("speed_units");
		speedUnitsCode = speedUnitsCode == null ? 0 : speedUnitsCode;
		
		var deviceSettings = Sys.getDeviceSettings();
		// Speed multiplier and units
		if (speedUnitsCode == 0) {
			speedMultiplier = KMH_IN_METERS_PER_SECOND;
			speedUnits = "kmh";
			speedUnitsCode = 1;
			if (deviceSettings.distanceUnits == Sys.UNIT_STATUTE) {
				speedMultiplier = MPH_IN_METERS_PER_SECOND;
				speedUnits = "mph";
				speedUnitsCode = 2;
			}
		} else if (speedUnitsCode == 1) {
			speedMultiplier = KMH_IN_METERS_PER_SECOND;
			speedUnits = "kmh";
		} else if (speedUnitsCode == 2) {
			speedMultiplier = MPH_IN_METERS_PER_SECOND;
			speedUnits = "mph";
		} else if (speedUnitsCode == 3) {
			speedMultiplier = KTS_IN_METERS_PER_SECOND;
			speedUnits = "kts";
		} else if (speedUnitsCode == 4) {
			speedMultiplier = 1;
			speedUnits = "mps";
		} else if (speedUnitsCode == 5) {
			speedMultiplier = 0;
			speedUnits = "bft";
		}
		// Temperature in Celsius
		tempCelsius = !(deviceSettings.temperatureUnits == Sys.UNIT_STATUTE);
		// Temperature unit
		if (tempCelsius) {tempSymbol = $.DEGREE_SYMBOL + "C";}
		else {tempSymbol = $.DEGREE_SYMBOL + "F";}
		
		// Pressure units
		var pressureUnits = App.Properties.getValue("pres_units");
		pressureUnits = pressureUnits == null ? 0 : pressureUnits;
		if (pressureUnits == 1) {pressureDivider = 33.8639;}
		else if (pressureUnits == 2) {pressureDivider = 1.33322;}

    	checkApiAndLocation();
	}

    // Load your resources here
    function onLayout(dc as Dc) as Void {
    	W = dc.getWidth();
    	H = dc.getHeight();
    	
    	iconsFont = WatchUi.loadResource(Rez.Fonts.owm_font);
    	
    	// Instinct 2:
        if (System.getDeviceSettings().screenShape == 4) {
        	if (Ui has :getSubscreen && H <= 176) {
        		instSubscr = Ui.getSubscreen();
        		if (instSubscr != null) {
        			instSubscrCentr = [instSubscr.x + instSubscr.width / 2, instSubscr.y + instSubscr.height / 2];
        			isInstinct = true;
        			W = H;
        			p("Instinct 2");
        		}
        	}
        }

    	// Get Weather data
    	weatherData = App.Storage.getValue("weather");
        owmRequest();
    }

	function checkApiAndLocation() {
    	var apiKey = App.Properties.getValue("api_key");
		apiKeyPresent = (apiKey != null && apiKey.length() > 0);
		locationPresent = (App.Storage.getValue("last_location") != null);
	}
	
    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    	//$.p("View onShow");
    	updateTimer.start(method(:onTimerUpdate), 10000, true);
    }

    function onHide() as Void {
    	//$.p("View onHide");
    	updateTimer.stop();
    }
	
    function onTimerUpdate() {
    	Ui.requestUpdate();
    }
 
    function startGPS() {
        $.p("startGPS");
        Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
        gpsRequested = true;
        WatchUi.requestUpdate();
    }

    function onPosition(info) {
        $.p("onPosition");
        if (info == null || info.position == null) {return;}
        $.saveLocation(info.position.toDegrees());
        locationPresent = true;
        WatchUi.requestUpdate();
        owmRequest();
	}

    // Update the view
    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        
        // Set anti-alias if available
        if (G.Dc has :setAntiAlias) {dc.setAntiAlias(true);}
        
    	dc.setColor(0, G.COLOR_BLACK);
        dc.clear();
       
        var errorMessage = "";
        
		if (!apiKeyPresent) {
        	errorMessage = R(Rez.Strings.NoAPIkey);
        } else if (!locationPresent) {
        	if (gpsRequested) {errorMessage = R(Rez.Strings.WaitForGPS);}
        	else {errorMessage = R(Rez.Strings.NoLocation);}
        } else if (weatherData == null) {
        	errorMessage = R(Rez.Strings.NoData);
        } else if (weatherData[0] == 401) {
        	errorMessage = R(Rez.Strings.InvalidKey);
        } else if (weatherData[0] == 404) {
        	errorMessage = R(Rez.Strings.InvalidLocation);
        } else if (weatherData[0] == 429) {
        	errorMessage = R(Rez.Strings.SuspendedKey);
        } else if (weatherData[0] != 200 && weatherData[0] > 0) {
        	errorMessage = R(Rez.Strings.OWMerror) + " " + weatherData[0];
        } else if (weatherData.size() < 17) {
        	errorMessage = R(Rez.Strings.InvalidData);
        }
        
		// Display error message
        if (errorMessage.length() > 0) {
        
			var iqImage = Ui.loadResource(Rez.Drawables.LauncherIcon);

        	if (isInstinct) {
	        	drawStr(dc, 50, 62, G.FONT_SYSTEM_SMALL, G.COLOR_WHITE, errorMessage, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
				dc.drawBitmap(instSubscrCentr[0] - (iqImage.getWidth() / 2), instSubscrCentr[1] - (iqImage.getHeight() / 2),iqImage);
			} else {
	        	drawStr(dc, 50, 50, G.FONT_SYSTEM_SMALL, G.COLOR_WHITE, errorMessage, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
				dc.drawBitmap(W/2 - (iqImage.getWidth() / 2), 5, iqImage);
			}

        	return;
        }
        
        // Display Weather. weatherData array structure:
        
		// 1 - Condition ID (800)
		// 2 - Condition Group text ("Clear")
		// 3 - Condition description ("clear sky")
		// 4 - Icon ("01n")
		// 5 - Location name ("Olathe")
		// 6 - Location country ("US")
		// 7 - date (1639535620)
		// 8 - sunrise (1639488608)
		// 9 - sunset (1639522685)
		// 10- temp (14.420000)
		// 11- feels like (14.420000)
		// 12- humidity (89)
		// 13- pressure (1013)
		// 14- wind speed (1.790000)
		// 15- wind gusts (1.790000)
		// 16- wind degree (186)
		
		// Verify OWM data
		if (weatherData[7] == null) {weatherData[7] = Time.now().value();}
		if (weatherData[10] == null) {weatherData[10] = 0;}
		if (weatherData[11] == null) {weatherData[11] = weatherData[10];}
		if (weatherData[12] == null) {weatherData[12] = 0;}
		if (weatherData[13] == null) {weatherData[13] = 0;}
		if (weatherData[14] == null) {weatherData[14] = 0;}
		if (weatherData[15] == null) {weatherData[15] = weatherData[14];}
		if (weatherData[16] == null) {weatherData[16] = 0;}
		
		var weatherImage;
		var str = "";
		
		if (iconsDictionary.get(weatherData[4]) != null) {weatherImage = Ui.loadResource(iconsDictionary.get(weatherData[4]));}
		else {weatherImage = Ui.loadResource(Rez.Drawables.iq_icon);}

		// Temperature
		var convertedTemp = Math.round(tempCelsius ? weatherData[10] : celsius2fahrenheit(weatherData[10]));
		var tempNegative = false;
		if (convertedTemp < 0) {
			tempNegative = true;
			convertedTemp = -1 * convertedTemp;
		}
		str = convertedTemp.format("%.0f");
		var tempWidth = dc.getTextWidthInPixels(str, G.FONT_SYSTEM_NUMBER_MEDIUM) / 2;

		var tempPositionX = 50;
		var tempPositionY = 13;
		if (isInstinct) {
			tempPositionX = 30;
			tempPositionY = 12;
		}
       	
   		drawStr(dc, tempPositionX, tempPositionY, G.FONT_SYSTEM_NUMBER_MEDIUM, 0xFFFF00, str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);

       	if (tempNegative) {dc.drawText(W * tempPositionX / 100 - tempWidth, H * tempPositionY / 100, G.FONT_SYSTEM_NUMBER_MEDIUM, "-", G.TEXT_JUSTIFY_RIGHT | G.TEXT_JUSTIFY_VCENTER);}
       	dc.drawText(W * tempPositionX / 100 + tempWidth + 5, H * (tempPositionY+1) / 100, G.FONT_SYSTEM_MEDIUM, tempSymbol, G.TEXT_JUSTIFY_LEFT | G.TEXT_JUSTIFY_VCENTER);
       	
		// Feels like
		str = "~ " + (tempCelsius ? weatherData[11].format("%.0f") : celsius2fahrenheit(weatherData[11]).format("%.0f")) + tempSymbol;
       	if (isInstinct) {drawStr(dc, 40, 30, G.FONT_SYSTEM_SMALL, G.COLOR_LT_GRAY, str, 5);}
       	else {drawStr(dc, 15, 31, G.FONT_SYSTEM_SMALL, G.COLOR_LT_GRAY, str, G.TEXT_JUSTIFY_LEFT | G.TEXT_JUSTIFY_VCENTER);}

		// Instinct Sub-window background
		if (isInstinct) {
			dc.fillCircle(instSubscrCentr[0], instSubscrCentr[1], instSubscr.height * 0.5 +2);
			dc.setColor(G.COLOR_BLACK, G.COLOR_TRANSPARENT);
		}
		
		if (screenNum == 1) {
			// Humidity
			str = weatherData[12].format("%.0f") + "%";
			if (isInstinct) {
		       	dc.drawText(instSubscrCentr[0], instSubscrCentr[1] - instSubscr.height * 0.1, G.FONT_SYSTEM_SMALL, str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
		       	dc.drawText(instSubscrCentr[0], instSubscrCentr[1] + instSubscr.height * 0.3, iconsFont, "\uF078", G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
	       	} else {
		       	drawStr(dc, 66, 31, G.FONT_SYSTEM_SMALL, G.COLOR_LT_GRAY, str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
		       	drawStr(dc, 81, 31, iconsFont, G.COLOR_LT_GRAY, "\uF078", G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
	       	}
	    } else {
			// Pressure
			str = (weatherData[13] / pressureDivider).format(pressureDivider > 2 ? "%.2f" : "%.0f");
			if (isInstinct) {
		       	dc.drawText(instSubscrCentr[0], instSubscrCentr[1] - instSubscr.height * 0.1, G.FONT_SYSTEM_SMALL, str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
		       	dc.drawText(instSubscrCentr[0], instSubscrCentr[1] + instSubscr.height * 0.3, iconsFont, "\uF079", G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
	       	} else {
		       	drawStr(dc, 66, 31, G.FONT_SYSTEM_SMALL, G.COLOR_LT_GRAY, str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
		       	drawStr(dc, 82, 31, iconsFont, G.COLOR_LT_GRAY, "\uF079", G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
		    }
	    }
		dc.setColor(G.COLOR_WHITE, G.COLOR_TRANSPARENT);

       	// Condition
       	dc.drawBitmap(W * 0 / 100, H * 48 / 100 - 24, weatherImage);
       	str = $.capitalize(weatherData[3]);
       	if (str.length() > (isInstinct ? 8 : 12)) {
	       	drawStr(dc, (isInstinct ? 27 : 19), 48, G.FONT_SYSTEM_MEDIUM, G.COLOR_WHITE,str, G.TEXT_JUSTIFY_LEFT | G.TEXT_JUSTIFY_VCENTER);
       	} else {
       		drawStr(dc, 50, 48, G.FONT_SYSTEM_MEDIUM, G.COLOR_WHITE,str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
       	}

		// Time and location
		var t = (Time.now().value() - weatherData[7]) / 60;
		t = t < 0 ? 0 : t;
		if (t < 120) {str = t.format("%.0f") + " min, ";}
		else {str = (t / 60.0).format("%.0f") + " hr, ";}
		str += weatherData[5];
       	drawStr(dc, 50, 62, G.FONT_SYSTEM_SMALL, G.COLOR_LT_GRAY, str.substring(0, 21), G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
		
		if (screenNum == 1) {
			// Wind
			str = windSpeedConvert(weatherData[14]) + " " + speedUnits + ", g" + windSpeedConvert(weatherData[15]);
	       	drawStr(dc, 50, 78, G.FONT_SYSTEM_SMALL, G.COLOR_WHITE, str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
	       	drawStr(dc, 14, 78, iconsFont, G.COLOR_LT_GRAY, "\uF050", G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
	
			// Wind direction
			str = weatherData[16].format("%.0f") + $.DEGREE_SYMBOL + " " + $.windDegreeToName(weatherData[16]);
	       	drawStr(dc, 50, 90, G.FONT_SYSTEM_SMALL, G.COLOR_LT_GRAY, str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
       	} else {
       		var is24 = Sys.getDeviceSettings().is24Hour;
			// Sunrise
			if (weatherData[8] == null) {str = "-";}
			else {str = momentToString(new Time.Moment(weatherData[8]), is24, true);}
	       	drawStr(dc, 50, 78, G.FONT_SYSTEM_SMALL, G.COLOR_WHITE, str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
	
			// Sunset
			if (weatherData[9] == null) {str = "-";}
			else {str = momentToString(new Time.Moment(weatherData[9]), is24, true);}
	       	drawStr(dc, 50, 90, G.FONT_SYSTEM_SMALL, G.COLOR_LT_GRAY, str, G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);

	       	drawStr(dc, 22, 84, iconsFont, G.COLOR_LT_GRAY, "\uF051", G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
	       	drawStr(dc, 78, 84, iconsFont, G.COLOR_LT_GRAY, "\uF052", G.TEXT_JUSTIFY_CENTER | G.TEXT_JUSTIFY_VCENTER);
	       	dc.setColor(G.COLOR_LT_GRAY, G.COLOR_TRANSPARENT);
	       	dc.drawLine(W * 0.35, H * 84 / 100, W * 0.65, H * 84 / 100);
       	}
       	// Lines
       	dc.setColor(G.COLOR_LT_GRAY, G.COLOR_TRANSPARENT);
       	dc.drawLine(0, H * 39 / 100, W, H * 39 / 100);
       	dc.drawLine(0, H * 70 / 100, W, H * 70 / 100);
    }
    
    // Draws string with all parameters in 1 call. 
    // X and Y are specified in % of screen size
    function drawStr(dc, x, y, font, color, str, alignment) {
    	dc.setColor(color, G.COLOR_TRANSPARENT);
    	dc.drawText(W * x / 100, H * y / 100, font, str, alignment);
    }

	function owmRequest() {
		owmRetryCount = 5;
		$.makeOWMwebRequest(method(:onReceiveOpenWeatherMap));
	}

	function windSpeedConvert(ws) {
		// Bft
		if (speedUnitsCode == 5) {return msToBft(ws).format("%.0f");}
		return (ws * speedMultiplier).format(speedUnitsCode == 4 ? "%.1f" : "%.0f");
	}

	function msToBft (ms) {
		var bft = 0;
		if (ms == null) {return 0;}
	
		if      (ms < 0.5) {bft = 0;}
		else if (ms < 1.6) {bft = 1;}
		else if (ms < 3.4) {bft = 2;}
		else if (ms < 5.5) {bft = 3;}
		else if (ms < 8.0) {bft = 4;}
		else if (ms < 10.8) {bft = 5;}
		else if (ms < 13.9) {bft = 6;}
		else if (ms < 17.2) {bft = 7;}
		else if (ms < 20.8) {bft = 8;}
		else if (ms < 24.5) {bft = 9;}
		else if (ms < 28.5) {bft = 10;}
		else if (ms < 32.7) {bft = 11;}
	    else {bft = 12;}
	
		return bft;
	}
	
	// OWM online response call back
	function onReceiveOpenWeatherMap(responseCode, data) {
		// Process only if no BLE error
		if (responseCode > 0) {
			weatherData = $.openWeatherMapData(responseCode, data);
			App.Storage.setValue("weather", weatherData);
			Ui.requestUpdate();
		}

		// Re-submit request if there is an error
		if (owmRetryCount > 0 && responseCode <= 0) {
			owmRetryCount -= 1;
			owmTimer = new Timer.Timer();
			owmTimer.start(method(:owmRequest), 5000 - (owmRetryCount * 1000), false);
		}
	}
}
