#include <mysql++.h>

#include <iostream>
#include <iomanip>
#include <string>
#include <vector>

using namespace std;
using namespace mysqlpp;


class Messages_DB_Helper {

   private:
      Connection con;
      bool bConnected;
      char * db;
      char * server;
      char * user;
      char * pass; 

   public:

      Messages_DB_Helper() {

         db     = getenv("ORC_DATABASE_NAME");
         server = "localhost";
         user   = getenv("ORC_DATABASE_USER");
         pass   = getenv("ORC_DATABASE_PASSWORD");
   
         con.set_option(new MultiStatementsOption(true));

         // Connect to the database
         if (con.connect(db, server, user, pass)) {
            bConnected = true;
         } else {
            bConnected = false;
         }

      }

      ~Messages_DB_Helper() {}

      int store_message(char * src_type, int src_id, char * tgt_type, int tgt_id, char * msg_type, vector<string> vParams){

         // abort operation if connection to database failed
         if(!bConnected){
            return 0;
         }

         // abort operation if vParams size number is odd (each param needs a name and a value)
         if(vParams.size()%2 != 0){
            return 0;
         }

         Transaction trans(con);

            //==============================================================

            int msg_db_id;

            Query msg_query = con.query();
            msg_query << "insert into orchestrator_messages values ('', '"
                      << src_type << "', "
                      << src_id   << ", '"
                      << tgt_type << "', "
                      << tgt_id   << ", '"
                      << msg_type << "')";

            SimpleResult res = msg_query.execute();

            if (res.rows() != 1) {
               return 0;
            } else {
               msg_db_id = res.insert_id();
            }

            //==============================================================

            Query param_query = con.query();
            param_query << "insert into message_parameters values ";

            vector<string>::iterator iter = vParams.begin();
            while( iter != vParams.end() ) {
               param_query << "('', " << msg_db_id << ", '" << *iter << "', '";
               iter++;
               param_query << *iter << "')";
               iter++;
               if (iter != vParams.end()){
                  param_query << ", ";
               }
            }

            res = param_query.execute();

            if (res.rows() != vParams.size()/2) {
               return 0;
            }

            //==============================================================

         trans.commit();

         return msg_db_id;
      }


      bool delete_message(int mes_id){

         if (bConnected) {
            
            Query query1 = con.query();
            query1 << "delete from message_parameters where orchestrator_message_id = " << mes_id ;

            Query query2 = con.query();
            query2 << "delete from orchestrator_messages where id = " << mes_id ;

            Transaction trans(con);

               bool res = query1.exec();

               if (!res) {
                  return false;
               }

               res = query2.exec();

               if (!res) {
                  return false;
               }

            trans.commit();

            return true;

         } else {

            return false;

         }

      }

};
