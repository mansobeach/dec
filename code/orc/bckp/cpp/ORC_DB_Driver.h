#include "mysql++.h"

#include <iostream>
#include <iomanip>

class ORC_DB_Driver {

   public:

   ORC_DB_Driver() {

   }

   ~ORC_DB_Driver() {
   }

   mysqlpp::StoreQueryResult request (char * req) {

      mysqlpp::Connection conn(false);
   
      conn.connect(getenv("ORC_DATABASE_NAME"), "localhost", getenv("ORC_DATABASE_USER"), getenv("ORC_DATABASE_PASSWORD"));

      mysqlpp::Query query = conn.query(req);

		mysqlpp::StoreQueryResult res = query.store();
      
      return res;
   }

};
