using Toybox.Background as Bg;
using Toybox.System as Sys;
using Toybox.Communications as Comms;
using Toybox.Application as App;

(:background)
class BackgroundService extends Sys.ServiceDelegate {
	
	function initialize() {
		Sys.ServiceDelegate.initialize();
	}

	// onTemporalEvent is called in background
	function onTemporalEvent() {
		//$.p("onTemporalEvent");
		$.makeOWMwebRequest(true);
	}
}
