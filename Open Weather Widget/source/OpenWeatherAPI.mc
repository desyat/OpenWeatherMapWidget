using Toybox.WatchUi;
using Toybox.Background as Bg;
using Toybox.System as Sys;
using Toybox.Communications as Comms;
using Toybox.Application as App;
using Toybox.Activity;
using Toybox.Weather;
using Toybox.Lang;

(:background)
function makeOWMwebRequest(runInBackground) {
	//p("makeOWMwebRequest");
	var options = {
		:method => Comms.HTTP_REQUEST_METHOD_GET,
		:headers => {"Content-Type" => Comms.REQUEST_CONTENT_TYPE_URL_ENCODED},
		:responseType => Comms.HTTP_RESPONSE_CONTENT_TYPE_JSON
	};
	
	// API key
	var apiKey = App.Properties.getValue("api_key");
	if (apiKey == null || apiKey.length() == 0) {
		// Put your own apiKey here
		apiKey = "";
	}
	
	// Location
	var loc = getLocation();
	
	// Language
	var lang = "en";
	if (Sys.DeviceSettings has :systemLanguage) {
		var langDictionary = {
			Sys.LANGUAGE_ENG => "en",
			Sys.LANGUAGE_FRE => "fr",
			Sys.LANGUAGE_SPA => "sp",
			Sys.LANGUAGE_ITA => "it",
			Sys.LANGUAGE_RUS => "ru",
			Sys.LANGUAGE_DEU => "de"
			};
			
		lang = langDictionary.get(Sys.getDeviceSettings().systemLanguage);
	}
	
	if (loc != null) {
		var params = {
			"lat" => loc[0],
			"lon" => loc[1],
			"lang" => lang == null ? "en" : lang,
			"appid" => apiKey,
			"units" => "metric" // Celcius
		};
		//$.p(params);
		var callBack;
		if (runInBackground) {
			callBack = new Lang.Method($, :onReceiveOpenWeatherMapBackground);
		} else {
			callBack = new Lang.Method($, :onReceiveOpenWeatherMapForeground);
		}
		Comms.makeWebRequest("https://api.openweathermap.org/data/2.5/weather", params, options, callBack);
	}
}

(:background)
function onReceiveOpenWeatherMapBackground(responseCode, data) {
	Bg.exit(openWeatherMapData(responseCode, data));
}

(:glance)
function onReceiveOpenWeatherMapForeground(responseCode, data) {
	// Process only if no BLE error
	if (responseCode > 0) {
		App.Storage.setValue("weather", openWeatherMapData(responseCode, data));
		WatchUi.requestUpdate();
	}
}

(:background)
function openWeatherMapData(responseCode, data) {
	var result;
	//$.p(responseCode);
	if (responseCode == 200) {
		result = [responseCode,
			data["weather"][0]["id"],			// 1 - Condition ID (800)
			data["weather"][0]["main"],			// 2 - Condition Group text ("Clear")
			data["weather"][0]["description"],	// 3 - Condition description ("clear sky")
			data["weather"][0]["icon"],			// 4 - Icon ("01n")
			data["name"],						// 5 - Location name ("Olathe")
			data["sys"]["country"],				// 6 - Location country ("US")
			data["dt"],							// 7 - date (1639535620)
			data["sys"]["sunrise"],				// 8 - sunrise (1639488608)
			data["sys"]["sunset"],				// 9 - sunset (1639522685)
			data["main"]["temp"],				// 10- temp (14.420000)
			data["main"]["feels_like"],			// 11- feels like (14.420000)
			data["main"]["humidity"],			// 12- humidity (89)
			data["main"]["pressure"],			// 13- pressure (1013)
			data["wind"]["speed"],				// 14- wind speed (1.790000)
			data["wind"]["gust"],				// 15- wind gusts (1.790000)
			data["wind"]["deg"]					// 16- wind degree (186)
			];
	// HTTP error
	} else {
		result = [responseCode];
	}
	return result;
}

(:background)
function getLocation() {
	// Get Location from Garmin Weather
	var useGarminLocation = App.Properties.getValue("use_garmin_location");
	if (useGarminLocation && Toybox has :Weather) {
		var w = Weather.getCurrentConditions();
		if (w != null && w.observationLocationPosition != null) {
	    	//$.p("Location obtained from Weather");
	    	var loc = w.observationLocationPosition.toDegrees();
	    	saveLocation(loc);
	    	return loc;
		}
	}
	
	// Get Location from Activity
	var activityLoc = Activity.getActivityInfo().currentLocation;
	if (activityLoc != null) {
		//$.p("Location obtained from Activity");
		var loc = activityLoc.toDegrees();
		saveLocation(loc);
		return loc;
	}

	// Get last known Location
	return App.Storage.getValue("last_location");
}

(:background)
function saveLocation(loc) {
	try {App.Storage.setValue("last_location", loc);} 
	catch(ex) {}
}