#include "Messages_DB_Helper.h"

int main(int argc, char *argv[])
{
   Messages_DB_Helper dbHelper;

   dbHelper = Messages_DB_Helper::Messages_DB_Helper();

//    bool res = dbHelper.delete_message(1);
// 
//    if(res) {
//       cout << "Success !" << endl;
//    } else {
//       cout << "Failure !" << endl;
//    }

   string str_param1 = "param1";
   string str_param2 = "val1";
   string str_param3 = "param2";
   string str_param4 = "val2";

   vector<string> vParams;

   vParams.push_back(str_param1);
   vParams.push_back(str_param2);
   vParams.push_back(str_param3);
   vParams.push_back(str_param4);

   int res = dbHelper.store_message("srctype", 3, "tgttype", 5, "msgtype", vParams);

   cout << res << endl; 
}
