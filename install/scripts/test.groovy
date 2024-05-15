
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

final Logger logger = LoggerFactory.getLogger("myGroovyLogger");

//Logger logger = LoggerFactory.getLogger("TEST");

logger.info("start get NASA reflectance models") ;
logger.info("get NASA reflectance product URL") ;

def pathConfig = "/path/de/mierda" ;
def firstProduct = "2024.01.01"

def sDescription = "foo"
def sedCommand = "sed -i 's/\\/MOLT\\/MOD09A1.061\\/[^\\/]*\\/</\\/MOLT\\/MOD09A1.061\\/$firstProduct\\/</g' " + pathConfig as String
println sedCommand ;

//def strcmd = 'sed -i \"s\/\/MOLT\/MOD09A1.061\\/[^\/]*\/\"  ' + pathConfig ;

// println strcmd ;

// def strcmd = "sed -i \"s/\/MOLT\/MOD09A1.061\/[^\/]*\/</\/MOLT\/MOD09A1.061\/9999.99.99\/</g\" " +  pathConfig ;
