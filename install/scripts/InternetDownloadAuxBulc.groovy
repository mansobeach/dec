package com.dms.eo.naos.orchestration.operational;

import java.nio.charset.Charset
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle

import org.apache.commons.io.FileUtils
import org.slf4j.Logger
import org.slf4j.LoggerFactory

@groovy.transform.ThreadInterrupt
public class InternetDownloadAuxBulc {
	
    private static final Logger logger = LoggerFactory.getLogger(InternetDownloadAuxBulc.class);
	
	public static enum InterfaceTypeEnum {
		AUX_BULC__
	}
	
    public static int getBulletinC() {
		logger.info("start get IERS bulletin C") ;
        def cmd 		    = ['bash', '-c', 'source ~/.bash_profile ; decGetFromInterface -m IERS_BULC'].execute() ;
        def outputStream    = new StringBuffer() ;
        cmd.waitForProcessOutput(outputStream, System.err) ;        
        String[] lines = outputStream.toString().split("\\n") ;
        for(String str: lines){
            logger.info(str) ;
        }
        def myexitCode 		= cmd.exitValue() ;
        logger.info("end get IERS bulletin C") ;
        return myexitCode ;
	}

}

println "Executing InternetDownloadAuxBulc tweaked with DEC";

int boolSheet = InternetDownloadAuxBulc.getBulletinC();

if ( boolSheet == 0 ){ SCRIPT_FUNCTIONS.setFinalOutputMessage("Script finished OK"); }else{ SCRIPT_FUNCTIONS.setFinalOutputMessage("Script finished KO");}