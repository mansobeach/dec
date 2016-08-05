
import os

from 	weewx.engine import StdPrint
from 	weeutil.weeutil import timestamp_to_string

class MyPrint(StdPrint):

    # Override the default new_loop_packet member function:
    def new_loop_packet(self, event):
        urlMeteo = "http://meteoleoncarmenes.altervista.org/update_realtime.php"
        packet = event.packet
        print "LOOP-CASALE: ", timestamp_to_string(packet['dateTime']), \
                            "pressure_outdoor=",  packet.get('barometer', 'N/A'), \
                            "temperature_outdoor=", packet.get('outTemp', 'N/A'), \
                            "humidity_outdoor=", packet.get('outHumidity', 'N/A'), \
                            "wind_speed=", packet.get('windSpeed', 'N/A'), \
                            "wind_direction=", packet.get('windDir', 'N/A'), \
                            "rain_1h=", packet.get('hourRain', 'N/A'), \
                            "rain_24h=", packet.get('dayRain', 'N/A'), \
                            "rain_rate=", packet.get('rainRate' ,'N/A')
	station_ip = ""
        try:
           with open('/tmp/meteo_ip.txt', 'r') as myfile:
              station_ip = myfile.read().replace('\n', '')
        except:
              station_ip = ""
        cmd = "curl -X POST " + urlMeteo + \
                   " -F stationIP=" + station_ip + \
                   " -F temperature_outdoor=" + "{:.1f}".format( packet.get('outTemp', 'N/A') ) + \
                   " -F temperature_indoor=" + "{:.1f}".format( packet.get('inTemp', 'N/A') ) + \
                   " -F pressure_outdoor=" + "{:.0f}".format( packet.get('barometer', 'N/A') ) + \
                   " -F humidity_outdoor=" +  "{:.1f}".format( packet.get('outHumidity', 'N/A') ) + \
                   " -F humidity_indoor=" +  "{:.1f}".format( packet.get('inHumidity', 'N/A') ) + \
                   " -F wind_speed=" + "{:.1f}".format( packet.get('windSpeed', 'N/A') ) + \
                   " -F windchill=" + "{:.1f}".format( packet.get('windchill', 'N/A') ) + \
                   " -F rain_24h=" + "{:.1f}".format( packet.get('dayRain', '0.0') ) + \
                   " -F rain_1h=" + "{:.1f}".format( packet.get('rainRate', '0.0') ) + \
                   " -F rain_1y=" + "{:.1f}".format( packet.get('yearRain', '0.0') ) + \
                   " -F dewpoint=" + "{:.1f}".format( packet.get('dewpoint', '0.0') ) + \
                   " -F txBatteryStatus=" + "{:d}".format( packet.get('txBatteryStatus', 'N/A') ) + \
                   " -F wind_direction=" + str( packet.get('windDir', 'N/A') )
        print cmd
        os.system(cmd)
