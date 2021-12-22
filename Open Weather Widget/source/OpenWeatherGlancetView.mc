using Toybox.Graphics as G;
using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Application as App;

(:glance)
class OpenWeatherGlancetView extends Ui.GlanceView {

	var GW;
	var GH;
	
	var settingsArr = $.getSettings();
	
    function initialize() {
    	//p("GlanceView initialize");
        GlanceView.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
    	//p("Glance onLayout");
    	GW = dc.getWidth();
    	GH = dc.getHeight();
    }

    function onShow() as Void {}

    // Update the view
    function onUpdate(dc as Dc) as Void {
        GlanceView.onUpdate(dc);
    	//p("Glance onUpdate");
    	dc.setColor(0, G.COLOR_BLACK);
        dc.clear();
        dc.setColor(G.COLOR_WHITE, -1);
        dc.setPenWidth(1);
        dc.drawLine(0, GH /2, GW, GH/2);
        dc.drawText(0, GH/4, G.FONT_SYSTEM_TINY, "Open Weather", G.TEXT_JUSTIFY_LEFT | G.TEXT_JUSTIFY_VCENTER);
        // Retrieve weather data
        var weatherData = App.Storage.getValue("weather");
        var str = "N/A";

        var apiKey = App.Properties.getValue("api_key");
		if (apiKey == null || apiKey.length() == 0) {str = "No API key";}
        else if (App.Storage.getValue("last_location") == null) {str = "No Location";}
        
        if (weatherData != null && weatherData[0] == 401) {str = "Invalid API key";}

        if (weatherData != null && weatherData[0] == 200 && weatherData.size() > 16) {
			if (weatherData[7] == null) {weatherData[7] = Time.now().value();}
			if (weatherData[10] == null) {weatherData[10] = 0;}
			if (weatherData[11] == null) {weatherData[11] = weatherData[10];}
			if (weatherData[12] == null) {weatherData[12] = 0;}
			if (weatherData[14] == null) {weatherData[14] = 0;}
			if (weatherData[15] == null) {weatherData[15] = weatherData[14];}
			if (weatherData[16] == null) {weatherData[16] = 0;}

        	str = (settingsArr[2] ? weatherData[10].format("%.0f") : celsius2fahrenheit(weatherData[10]).format("%.0f")) + settingsArr[3];
        	str += ": " + $.capitalize(weatherData[3]);
        }
        
        dc.drawText(0, GH*0.75, G.FONT_SYSTEM_TINY, str, G.TEXT_JUSTIFY_LEFT | G.TEXT_JUSTIFY_VCENTER);
    }

    function onHide() as Void {}

	function p(s) {System.println(s);}
}
