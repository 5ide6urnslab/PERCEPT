/*************************************************************************
* File Name          : LogFunction
* Author             : Show Kawabata(5ide6urns lab)
* Version            : v1.00
* Date               : 01/25/2016
* Parts required     : 
* Description        : 
*
* License            : Released under the MIT license.
*                      http://opensource.org/licenses/mit-license.php
* Copyright          : Copyright (C) 2016 5ide6urns lab All right reserved.
* History            : 01/25/2016 v1.00 Show Kawabata Create on.
**************************************************************************/

String saveFileName = "accel.csv";
PrintWriter output;

/*! *******************************************************************
 *  @fn         startLogging
 *  @brief      It is start the Data Logging "CSV file".
 *              The file name is "year" + "month" + "day" + "hour" + 
 *              "minute" + "second". 
 *  @param[in]  void
 *  @return     void
 *  @version    v1.00
 *  @date       01/25/2016  v1.00:  Create on.
 ***********************************************************************/
void startLogging(){
  int m = month();
  int d = day();
  
  saveFileName = year() + "";
  
  /*******************************
   * Month
   *******************************/
  if(m < 10){
    saveFileName = saveFileName + "0" + m;  
  }
  else{
    saveFileName = saveFileName + m;  
  }
  
  /*******************************
   * Day
   *******************************/
  if(d < 10){
    saveFileName = saveFileName + "0" + d;  
  }
  else{
    saveFileName = saveFileName + d;  
  }
  
  saveFileName = saveFileName + "_";
  
  
  int _s = second();
  int _m = minute();
  int _h = hour();
  
  /*******************************
   * Hour
   *******************************/
  if(_h < 10){
    saveFileName = saveFileName + "0" + _h;  
  }
  else{
    saveFileName = saveFileName + _h;  
  }
  
  /*******************************
   * Minute
   *******************************/
  if(_m < 10){
    saveFileName = saveFileName + "0" + _m;  
  }
  else{
    saveFileName = saveFileName + _m;  
  }
  
  /*******************************
   * Secound
   *******************************/
  if(_s < 10){
    saveFileName = saveFileName + "0" + _s;  
  }
  else{
    saveFileName = saveFileName + _s;
  }
  
  output = createWriter( saveFileName + ".csv");
  output.println("X-axis, Y-axis, Z-axis");
  
}


/*! *******************************************************************
 *  @fn         saveLog
 *  @brief      It is save the CSV file.
 *
 *  @param[in]  sensorNum    the sensor type for multi-sensor
 *              getDataName  the data name of logging (ex. gravity, yaw, pitch etc)
 *              x            the sensor data of X-axis
 *              y            the sensor data of Y-axis
 *              z            the sensor data of Z-axis
 *  @return     void
 *  @version    v1.00
 *  @date       01/25/2016  v1.00:  Create on.
 ***********************************************************************/
void saveLog(int sensorNum, String getDataName, float x, float y, float z){
  output.println( sensorNum + getDataName + "," + x + "," + y + ","  + z );
}


/*! *******************************************************************
 *  @fn         closeLogging
 *  @brief      It is close the CSV file.
 *
 *  @param[in]  void
 *  @return     void
 *  @version    v1.00
 *  @date       01/25/2016  v1.00:  Create on.
 ***********************************************************************/
void closeLogging(){
  output.flush();
  output.close();
} //<>//