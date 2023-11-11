package com.dms.eo.naos.orchestration.operational;

import java.nio.charset.Charset
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle

import groovy.io.FileType
import static groovy.io.FileType.FILES

import org.apache.commons.io.FileUtils
import org.slf4j.Logger
import org.slf4j.LoggerFactory

@groovy.transform.ThreadInterrupt
public class InternetDownloadAuxRfm {
	
    private static final Logger logger = LoggerFactory.getLogger(InternetDownloadAuxRfm.class);
	
    public static enum InterfaceTypeEnum {
	    AUX_RFM___
    }
	
    public static int getRFM() {
	    logger.info("start get NASA reflectance models") ;
        logger.info("get NASA reflectance products URL") ;
        def cmd 		    = ['bash', '-c', 'source ~/.bash_profile ; decGetFromInterface -m NASA_RFM_URL'].execute() ;
        def outputStream    = new StringBuffer() ;
        cmd.waitForProcessOutput(outputStream, System.err) ;        
        String[] lines = outputStream.toString().split("\\n") ;
        for(String str: lines){
            logger.info(str) ;
        }
        def myexitCode 		= cmd.exitValue() ;
        
        if (myexitCode != 0){
            logger.error("Failed to get NASA RFM URL products") ;
            return myexitCode ;
        }

        def dir = new File("/data/mocExternalInterfaces/int/MOD09A1_URL");
        def files = [];
        dir.traverse(type: FILES, maxDepth: 0) { files.add(it) };

        files.each{
            logger.info(it.path)
        }

        def firstProduct ;
        
        try{
            firstProduct = files.first().path[-10..-1] ;   
        }catch(Exception e)
        {
            logger.info("No new RFM products URL available") ;
            return 0 ;
        }
        
        logger.info("get " + firstProduct) ;

        logger.info("get DEC configuration location") ;
        cmd 		    = ['bash', '-c', 'source ~/.bash_profile ; decValidateConfig -i -L'].execute() ;
        outputStream    = new StringBuffer() ;
        cmd.waitForProcessOutput(outputStream, System.err) ;        
        lines = outputStream.toString().split("\\n") ;
        String pathConfig ;
        for(String str: lines){
            pathConfig = str ;
        }
        myexitCode 		= cmd.exitValue() ;
        logger.info(pathConfig) ;

        def sedCommand = "source ~/.bash_profile ; sed -i 's/\\/MOLT\\/MOD09A1.061\\/[^\\/]*\\/</\\/MOLT\\/MOD09A1.061\\/$firstProduct\\/</g' " + pathConfig as String
        logger.info(sedCommand) ;

        cmd = ['bash', '-c', sedCommand].execute() ;
        outputStream    = new StringBuffer() ;
        cmd.waitForProcessOutput(outputStream, System.err) ;
        myexitCode 		= cmd.exitValue() ;

        if (myexitCode != 0){
            logger.error("Failed to update DEC NASA_RFM configuration with " + firstProduct) ;
            return myexitCode ;
        }

        logger.info("get NASA reflectance products") ;
        cmd 		    = ['bash', '-c', 'source ~/.bash_profile ; decGetFromInterface -m NASA_RFM'].execute() ;
        outputStream    = new StringBuffer() ;
        cmd.waitForProcessOutput(outputStream, System.err) ;        
        lines = outputStream.toString().split("\\n") ;
        for(String str: lines){
            logger.info(str) ;
        }
        
        myexitCode 		= cmd.exitValue() ;

        if (myexitCode == 0){
            logger.info("get NASA reflectance products") ;
            boolean fileSuccessfullyDeleted =  new File("/data/mocExternalInterfaces/int/MOD09A1_URL/" + firstProduct).delete() ;
            if (fileSuccessfullyDeleted == true){
                logger.info("Deleted RFM URL product : " + firstProduct) ;
            }else{
                logger.error("Could not delete RFM URL product : " + firstProduct) ;
            }
        }

        logger.info("end get NASA reflectance models") ;
        return myexitCode ;
    }

}

println "Executing InternetDownloadAuxRfm powered with DEC" ;

int boolSheet = InternetDownloadAuxRfm.getRFM() ;

if ( boolSheet == 0 ){ SCRIPT_FUNCTIONS.setFinalOutputMessage("Script finished OK"); }else{ SCRIPT_FUNCTIONS.setFinalOutputMessage("Script finished KO");}
