#include "mysql++.h"

#include <iostream>
#include <iomanip>

class ORC_DB_Driver {

   private:
      bool bConnected;

   public:

   ORC_DB_Driver() {

      mysqlpp::Connection conn(false);
   
      if (conn.connect(getenv("ORC_DB_NAME"), "localhost", getenv("ORC_DATABASE_USER"), getenv("ORC_DATABASE_PASSWORD"))) {
         bConnected = true;
	   } else {
	      bConnected = false;
	   }

   }

   ~ORC_DB_Driver() {
   }

   bool isConnected() {
      return bConnected;
   }
};
