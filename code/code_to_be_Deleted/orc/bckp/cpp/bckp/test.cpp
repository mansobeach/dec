#include "ORC_DB_Driver.h"

using namespace std;

int main(int argc, char *argv[])
{
   ORC_DB_Driver dbDrive;
   dbDrive = ORC_DB_Driver::ORC_DB_Driver();

   mysqlpp::StoreQueryResult res = dbDrive.request("select filename from archived_files");

   cout << "We have " << res.num_rows() << " results :" << endl;
  	for (size_t i = 0; i < res.num_rows(); ++i) {
  		cout << '\t' << res[i][0] << endl;
	}

}
