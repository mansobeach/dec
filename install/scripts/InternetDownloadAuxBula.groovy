package com.dms.eo.naos.orchestration.operational;

import java.nio.charset.Charset
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle

import org.apache.commons.io.FileUtils
import org.slf4j.Logger
import org.slf4j.LoggerFactory

@groovy.transform.ThreadInterrupt
public class InternetDownloadAuxBula {
	
    private static final Logger logger = LoggerFactory.getLogger(InternetDownloadAuxBula.class);
	
	public static enum InterfaceTypeEnum {
		AUX_BULA__
	}
	
    public static int getBulletinA() {
		logger.info("start get IERS bulletin A") ;
        def cmd 		    = ['bash', '-c', 'source ~/.bash_profile ; decGetFromInterface -m IERS_BULA'].execute() ;
        def outputStream    = new StringBuffer() ;
        cmd.waitForProcessOutput(outputStream, System.err) ;        
        String[] lines = outputStream.toString().split("\\n") ;
        for(String str: lines){
            logger.info(str) ;
        }
        def myexitCode 		= cmd.exitValue() ;
        logger.info("end get IERS bulletin A") ;
        return myexitCode ;
	}

}

println "Executing InternetDownloadAuxBula tweaked with DEC";

int boolSheet = InternetDownloadAuxBula.getBulletinA();

if ( boolSheet == 0 ){ SCRIPT_FUNCTIONS.setFinalOutputMessage("Script finished OK"); }else{ SCRIPT_FUNCTIONS.setFinalOutputMessage("Script finished KO");}