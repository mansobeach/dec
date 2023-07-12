#!/usr/bin/env groovy

def cmd 		= 'decGetFromInterface -m IERS_BULC --nodb'.execute()
cmd.waitForProcessOutput(System.out, System.err)
def exitCode 		= cmd.exitValue()

println("exit code is " + exitCode)

if (exitCode == 0){
   println("IERS BULC iteration OK")
}else
{
   println("IERS BULC iteration KO")
}
