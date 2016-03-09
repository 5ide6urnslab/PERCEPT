/*************************************************************************
* File Name          : MultiAccelerationSim
* Author             : Show Kawabata(5ide6urns lab)
* Version            : v1.04
* Date               : 01/25/2016
* Parts required     : Arduino compatible board, Acceleration(MPU6050/9150)
* Description        : 
*
* License            : Released under the MIT license.
*                      http://opensource.org/licenses/mit-license.php
* Copyright          : Copyright (C) 2015 5ide6urns lab All right reserved.
* History            : 12/02/2015 v1.00 Show Kawabata Create on.
*                      12/03/2015 v1.01 Show Kawabata [New func] add the multi-device.
*                      01/14/2016 v1.02 Show Kawabata [New func] add the Sim-Display On/Off.
*                      01/22/2016 v1.03 Show Kawabata [Bug fix] fix the framerate problem.
*                      01/25/2016 v1.04 Show Kawabata [New func] add the Data Logging.
**************************************************************************/
import processing.serial.*;
import processing.opengl.*;
import toxi.geom.*;
import toxi.processing.*;
import controlP5.*;

import oscP5.*;
import netP5.*;

/******************************************
 * Class Object
 ******************************************/
ControlP5 cp5;
Textarea myTextarea;                   // The text area for console

Chart[] yawChart   = new Chart[4];     // The graph chart of yaw
Chart[] pitchChart = new Chart[4];     // The graph chart of pitch
Chart[] rollChart  = new Chart[4];     // The graph chart of roll
Chart[] x          = new Chart[4];     // The graph chart of x(gravity, euler)
Chart[] y          = new Chart[4];     // The graph chart of y(gravity, euler)
Chart[] z          = new Chart[4];     // The graph chart of z(gravity, euler)

Println console;                       // The console

Serial portA;                          // The serial port
Serial portB;
Serial portC;
Serial portD;

OscP5 oscP5;
NetAddress myRemoteLocation;

boolean displaytoggle;
boolean loggingtoggle;

String loggingStatus;
String displayStatus;

/*  [NOTE]: about the ToxicLibs.
 *   1. Download from http://toxiclibs.org/downloads.
 *   2. Extract into [userdir]/Processing/libraries.
 *      rename the toxiclibs.
 */
ToxiclibsSupport gfx;

/******************************************
 * Acceleration
 ******************************************/
char[][] packet   = new char[4][17];  // [$, ID, data, data, ....]  InvenSense packet
float[][] q       = new float[4][4];  // [w, x, y, z]  quaternion
int[] serialCount = new int[4];       // current packet byte position
int[] synced      = new int[4];

int interval = 0;

Quaternion quat1  = new Quaternion(1, 0, 0, 0);
Quaternion quat2  = new Quaternion(1, 0, 0, 0);
Quaternion quat3  = new Quaternion(1, 0, 0, 0);
Quaternion quat4  = new Quaternion(1, 0, 0, 0);

float[][] gravity = new float[4][3];  // [gX, gY, gZ]  gravity
float[][] euler   = new float[4][3];  // [degX, degY, degZ]  euler degree
float[][] ypr     = new float[4][3];  // [yaw, pitch, roll]  Yaw/Pitch/Roll

 //<>//
/*! *******************************************************************
 *  @fn         setup [Default function]
 *  @brief      This function is the initilize process.
 *
 *  @param[in]  void
 *  @return     void
 *  @version    v1.03
 *  @date       12/02/2015 v1.00 Show Kawabata Create on.
 *              12/03/2015 v1.01 Show Kawabata [New func] add the multi-device.
 *              01/14/2016 v1.02 Show Kawabata [New func] add the Sim-Display On/Off.
 *              01/22/2016 v1.03 Show Kawabata [Bug fix] fix the framerate problem.
 ***********************************************************************/
void setup() {
  size(1400, 830, P3D);
  frameRate(50);

  /******************************************
   * OSC Receive setting
   ******************************************/
  oscP5 = new OscP5(this, 5555);
  myRemoteLocation = new NetAddress("169.254.113.80", 8000);

  cp5 = new ControlP5(this);
  cp5.enableShortcuts();
  

  /******************************************
   * Framerate setting
   ******************************************/
  cp5.addFrameRate().setInterval(10).setPosition(0,height - 10);

  /******************************************
   * Debug console setting
   ******************************************/
  myTextarea = cp5.addTextarea("txt")
                  .setPosition(30, 700)
                  .setSize(350, 100)
                  .setFont(createFont("", 10))
                  .setLineHeight(14)
                  .setColor(color(200))
                  .setColorBackground(color(0, 100))
                  .setColorForeground(color(255, 500))
                  ;

//  console = cp5.addConsole(myTextarea);

  /******************************************
   * Simulation display ON/OFF
   ******************************************/
  cp5.addToggle("DisplayOnOff")
     .setPosition(1000,720)
     .setSize(50,20)
     .setValue(true)
     .setMode(ControlP5.SWITCH)
     ;

  /******************************************
   * Logging ON/OFF setting
   ******************************************/
  cp5.addToggle("LoggingOnOff")
     .setPosition(1000,770)
     .setSize(50,20)
     .setValue(false)
     .setMode(ControlP5.SWITCH)
     ;


  /******************************************
   * Yaw-1 chart graph setting
   ******************************************/   
  Group g1 = cp5.addGroup("Yaw Chartgraph-1")
                .setPosition(200,20)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;
   
  yawChart[0] = cp5.addChart("Yaw-1")
                .setPosition(0, 0)
                .setSize(150, 100)
                .setRange(-1, 1)
                .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
                .setStrokeWeight(1.5)
                .setColorCaptionLabel(color(255))
                .setGroup(g1)
                ;

  yawChart[0].addDataSet("yawChart1");
  yawChart[0].setData("yawChart1", new float[100]);
  
  /******************************************
   * Pitch-1 chart graph setting
   ******************************************/  
  Group g2 = cp5.addGroup("Pitch Chartgraph-1")
                .setPosition(370,20)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  
  pitchChart[0] = cp5.addChart("Pitch-1")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g2)
                 ;
  
  pitchChart[0].addDataSet("pitchChart1");
  pitchChart[0].setData("pitchChart1", new float[100]);

  /******************************************
   * Roll-1 chart graph setting
   ******************************************/  
  Group g3 = cp5.addGroup("Roll Chartgraph-1")
                .setPosition(540,20)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  
  rollChart[0] = cp5.addChart("Roll-1")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g3)
                 ;
  
  rollChart[0].addDataSet("rollChart1");
  rollChart[0].setData("rollChart1", new float[100]);

  /******************************************
   * x-1(gravity, euler) chart graph setting
   ******************************************/
  Group g4 = cp5.addGroup("X Chartgraph-1")
                .setPosition(710,20)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  x[0]        = cp5.addChart("X-axis-1")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g4)
                 ;
  
  x[0].addDataSet("XChart1");
  x[0].setData("XChart1", new float[100]);

  /******************************************
   * y-1(gravity, euler) chart graph setting
   ******************************************/
  Group g5 = cp5.addGroup("Y Chartgraph-1")
                .setPosition(880,20)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  y[0]        = cp5.addChart("Y-axis-1")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g5)
                 ;
  
  y[0].addDataSet("YChart1");
  y[0].setData("YChart1", new float[100]);

  /******************************************
   * z-1(gravity, euler) chart graph setting
   ******************************************/
  Group g6 = cp5.addGroup("Z Chartgraph-1")
                .setPosition(1050,20)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  z[0]        = cp5.addChart("Z-axis-1")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g6)
                 ;
  
  z[0].addDataSet("ZChart1");
  z[0].setData("ZChart1", new float[100]);

  /******************************************
   * Yaw-2 chart graph setting
   ******************************************/   
  Group g7 = cp5.addGroup("Yaw Chartgraph-2")
                .setPosition(200,200)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;
   
  yawChart[1] = cp5.addChart("Yaw-2")
                .setPosition(0, 0)
                .setSize(150, 100)
                .setRange(-1, 1)
                .setView(Chart.LINE)
                .setStrokeWeight(1.5)
                .setColorCaptionLabel(color(255))
                .setGroup(g7)
                ;

  yawChart[1].addDataSet("yawChart2");
  yawChart[1].setData("yawChart2", new float[100]);

  /******************************************
   * Pitch-2 chart graph setting
   ******************************************/  
  Group g8 = cp5.addGroup("Pitch Chartgraph-2")
                .setPosition(370,200)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  
  pitchChart[1] = cp5.addChart("Pitch-2")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g8)
                 ;
  
  pitchChart[1].addDataSet("pitchChart2");
  pitchChart[1].setData("pitchChart2", new float[100]);

  /******************************************
   * Roll-2 chart graph setting
   ******************************************/  
  Group g9 = cp5.addGroup("Roll Chartgraph-2")
                .setPosition(540,200)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  
  rollChart[1] = cp5.addChart("Roll-2")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g9)
                 ;
  
  rollChart[1].addDataSet("rollChart2");
  rollChart[1].setData("rollChart2", new float[100]);

  /******************************************
   * x-2(gravity, euler) chart graph setting
   ******************************************/
  Group g10 = cp5.addGroup("X Chartgraph-2")
                .setPosition(710,200)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  x[1]        = cp5.addChart("X-axis-2")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g10)
                 ;
  
  x[1].addDataSet("XChart2");
  x[1].setData("XChart2", new float[100]);

  /******************************************
   * y-2(gravity, euler) chart graph setting
   ******************************************/
  Group g11 = cp5.addGroup("Y Chartgraph-2")
                .setPosition(880,200)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  y[1]        = cp5.addChart("Y-axis-2")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g11)
                 ;
  
  y[1].addDataSet("YChart2");
  y[1].setData("YChart2", new float[100]);

  /******************************************
   * z-2(gravity, euler) chart graph setting
   ******************************************/
  Group g12 = cp5.addGroup("Z Chartgraph-2")
                .setPosition(1050,200)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  z[1]        = cp5.addChart("Z-axis-2")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g12)
                 ;
  
  z[1].addDataSet("ZChart2");
  z[1].setData("ZChart2", new float[100]);

  /******************************************
   * Yaw-3 chart graph setting
   ******************************************/   
  Group g13 = cp5.addGroup("Yaw Chartgraph-3")
                .setPosition(200,380)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;
   
  yawChart[2] = cp5.addChart("Yaw-3")
                .setPosition(0, 0)
                .setSize(150, 100)
                .setRange(-1, 1)
                .setView(Chart.LINE)
                .setStrokeWeight(1.5)
                .setColorCaptionLabel(color(255))
                .setGroup(g13)
                ;

  yawChart[2].addDataSet("yawChart3");
  yawChart[2].setData("yawChart3", new float[100]);

  /******************************************
   * Pitch-3 chart graph setting
   ******************************************/  
  Group g14 = cp5.addGroup("Pitch Chartgraph-3")
                .setPosition(370,380)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  
  pitchChart[2] = cp5.addChart("Pitch-3")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g14)
                 ;
  
  pitchChart[2].addDataSet("pitchChart3");
  pitchChart[2].setData("pitchChart3", new float[100]);

  /******************************************
   * Roll-3 chart graph setting
   ******************************************/  
  Group g15 = cp5.addGroup("Roll Chartgraph-3")
                .setPosition(540,380)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  
  rollChart[2] = cp5.addChart("Roll-3")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g15)
                 ;
  
  rollChart[2].addDataSet("rollChart3");
  rollChart[2].setData("rollChart3", new float[100]);

  /******************************************
   * x-3(gravity, euler) chart graph setting
   ******************************************/
  Group g16 = cp5.addGroup("X Chartgraph-3")
                .setPosition(710,380)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  x[2]        = cp5.addChart("X-axis-3")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g16)
                 ;
  
  x[2].addDataSet("XChart3");
  x[2].setData("XChart3", new float[100]);

  /******************************************
   * y-3(gravity, euler) chart graph setting
   ******************************************/
  Group g17 = cp5.addGroup("Y Chartgraph-3")
                .setPosition(880,380)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  y[2]        = cp5.addChart("Y-axis-3")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g17)
                 ;
  
  y[2].addDataSet("YChart3");
  y[2].setData("YChart3", new float[100]);

  /******************************************
   * z-3(gravity, euler) chart graph setting
   ******************************************/
  Group g18 = cp5.addGroup("Z Chartgraph-3")
                .setPosition(1050,380)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  z[2]        = cp5.addChart("Z-axis-3")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g18)
                 ;
  
  z[2].addDataSet("ZChart3");
  z[2].setData("ZChart3", new float[100]);

  /******************************************
   * Yaw-4 chart graph setting
   ******************************************/   
  Group g19 = cp5.addGroup("Yaw Chartgraph-4")
                .setPosition(200,560)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;
   
  yawChart[3] = cp5.addChart("Yaw-4")
                .setPosition(0, 0)
                .setSize(150, 100)
                .setRange(-1, 1)
                .setView(Chart.LINE)
                .setStrokeWeight(1.5)
                .setColorCaptionLabel(color(255))
                .setGroup(g19)
                ;

  yawChart[3].addDataSet("yawChart4");
  yawChart[3].setData("yawChart4", new float[100]);

  /******************************************
   * Pitch-4 chart graph setting
   ******************************************/  
  Group g20 = cp5.addGroup("Pitch Chartgraph-4")
                .setPosition(370,560)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  
  pitchChart[3] = cp5.addChart("Pitch-4")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g20)
                 ;
  
  pitchChart[3].addDataSet("pitchChart4");
  pitchChart[3].setData("pitchChart4", new float[100]);

  /******************************************
   * Roll-4 chart graph setting
   ******************************************/  
  Group g21 = cp5.addGroup("Roll Chartgraph-4")
                .setPosition(540,560)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  
  rollChart[3] = cp5.addChart("Roll-4")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g21)
                 ;
  
  rollChart[3].addDataSet("rollChart4");
  rollChart[3].setData("rollChart4", new float[100]);

  /******************************************
   * x-4(gravity, euler) chart graph setting
   ******************************************/
  Group g22 = cp5.addGroup("X Chartgraph-4")
                .setPosition(710,560)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  x[3]        = cp5.addChart("X-axis-4")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g22)
                 ;
  
  x[3].addDataSet("XChart4");
  x[3].setData("XChart4", new float[100]);

  /******************************************
   * y-4(gravity, euler) chart graph setting
   ******************************************/
  Group g23 = cp5.addGroup("Y Chartgraph-4")
                .setPosition(880,560)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  y[3]        = cp5.addChart("Y-axis-4")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g23)
                 ;
  
  y[3].addDataSet("YChart4");
  y[3].setData("YChart4", new float[100]);

  /******************************************
   * z-4(gravity, euler) chart graph setting
   ******************************************/
  Group g24 = cp5.addGroup("Z Chartgraph-4")
                .setPosition(1050,560)
                .setBackgroundHeight(100)
                .setBackgroundColor(color(255,50))
                ;

  z[3]        = cp5.addChart("Z-axis-4")
                 .setPosition(0, 0)
                 .setSize(150, 100)
                 .setRange(-1, 1)
                 .setView(Chart.LINE)
                 .setStrokeWeight(1.5)
                 .setColorCaptionLabel(color(255))
                 .setGroup(g24)
                 ;
  
  z[3].addDataSet("ZChart4");
  z[3].setData("ZChart4", new float[100]);


  /******************************************
   * Serial Settings
   ******************************************/
  gfx = new ToxiclibsSupport(this);

  // setup lights and antialiasing
  lights();
  smooth();
  
  // display serial port list for debugging/clarity
  println(Serial.list());

  // get the first available port (use EITHER this OR the specific port code below)
  String portNameA = "/dev/tty.usbserial-DA01MH98";
  String portNameB = "/dev/tty.usbserial-DA00X1XF";
  String portNameC = "/dev/tty.usbserial-DN00OK5F";
  String portNameD = "/dev/tty.usbserial-DA01MHO9";
    
  // get a specific serial port (use EITHER this OR the first-available code above)
  //String portName = "COM4";
    
  // open the serial port
  portA = new Serial(this, portNameA, 115200);
  portB = new Serial(this, portNameB, 115200);
  portC = new Serial(this, portNameC, 115200);
  portD = new Serial(this, portNameD, 115200);
    
  // send single character to trigger DMP init/start
  // (expected by MPU6050_DMP6 example Arduino sketch)
  portA.write('r');
  portB.write('r');
  portC.write('r');
  portD.write('r');

  return;

}

/*! *******************************************************************
 *  @fn         draw [Default function]
 *  @brief      This function is the draw process.
 *
 *  @param[in]  void
 *  @return     void
 *  @version    v1.02
 *  @date       12/02/2015 v1.00 Show Kawabata Create on.
 *              12/03/2015 v1.01 Show Kawabata [New func] add the multi-device.
 *              01/14/2016 v1.02 Show Kawabata [New func] add the Sim-Display On/Off.
 ***********************************************************************/
void draw() {
  
  if (millis() - interval > 1000) {
    // resend single character to trigger DMP init/start
     // in case the MPU is halted/reset while applet is running
    portA.write('r');
    portB.write('r');
    portC.write('r');
    portD.write('r');
    interval = millis();
  }
    
  // black background
  background(0);
    
  // translate everything to the middle of the viewport
  pushMatrix();
  translate(width / 2, height / 3);

  /******************************************
   * Draw the Sensor-1 model
   ******************************************/
  pushMatrix();
    
  translate(-600,-200);
  float[] axis = quat1.toAxisAngle();
  rotate(axis[0], -axis[1], axis[3], axis[2]);

  // draw main body in red
  stroke(.5);
  fill(255, 255, 255);
  box(40, 40, 40);
  popMatrix();
      
  /******************************************
   * Draw the Sensor-2 model
   ******************************************/
  pushMatrix();
    
  translate(-600,-20);
  float[] axis1 = quat2.toAxisAngle();
  rotate(axis1[0], -axis1[1], axis1[3], axis1[2]);

  // draw main body in red
  stroke(.5);
  fill(255, 255, 255);
  box(40, 40, 40);
  popMatrix();

  /******************************************
   * Draw the Sensor-3 model
   ******************************************/
  pushMatrix();
    
  translate(-600,160);
  float[] axis2 = quat3.toAxisAngle();
  rotate(axis2[0], -axis2[1], axis2[3], axis2[2]);

  // draw main body in red
  stroke(.5);
  fill(255, 255, 255);
  box(40, 40, 40);
  popMatrix();

  /******************************************
   * Draw the Sensor-4 model
   ******************************************/
  pushMatrix();
    
  translate(-600,360);
  float[] axis3 = quat4.toAxisAngle();
  rotate(axis3[0], -axis3[1], axis3[3], axis3[2]);

  // draw main body in red
  stroke(.5);
  fill(255, 255, 255);
  box(40, 40, 40);
  popMatrix();

  /******************************************
   * Send the OSC
   ******************************************/
  OscBundle myBundle = new OscBundle();
  OscMessage myMessage = new OscMessage("/accel/LF");

  myMessage.add(gravity[0][0]);
  myMessage.add(gravity[0][1]);
  myMessage.add(gravity[0][2]);

  myBundle.add(myMessage);
  myMessage.clear();
  
  myMessage.setAddrPattern("/accel/RF");

  myMessage.add(gravity[1][0]);
  myMessage.add(gravity[1][1]);
  myMessage.add(gravity[1][2]);  

  myBundle.add(myMessage);
  myMessage.clear();
  
  myMessage.setAddrPattern("/accel/LH");

  myMessage.add(gravity[2][0]);
  myMessage.add(gravity[2][1]);
  myMessage.add(gravity[2][2]);

  myBundle.add(myMessage);
  myMessage.clear();
  
  myMessage.setAddrPattern("/accel/RH");

  myMessage.add(gravity[3][0]);
  myMessage.add(gravity[3][1]);
  myMessage.add(gravity[3][2]);  

  myBundle.add(myMessage);


  oscP5.send(myBundle, myRemoteLocation);

  /******************************************
   * Draw the Chartgraph
   ******************************************/
  if(displaytoggle){
    yawChart[0].push("yawChart1", ypr[0][0]);
    yawChart[1].push("yawChart2", ypr[1][0]);
    yawChart[2].push("yawChart3", ypr[2][0]);
    yawChart[3].push("yawChart4", ypr[3][0]);    
    
    pitchChart[0].push("pitchChart1", ypr[0][1]);
    pitchChart[1].push("pitchChart2", ypr[1][1]);
    pitchChart[2].push("pitchChart3", ypr[2][1]);
    pitchChart[3].push("pitchChart4", ypr[3][1]);
    
    rollChart[0].push("rollChart1",ypr[0][2]);    
    rollChart[1].push("rollChart2",ypr[1][2]);
    rollChart[2].push("rollChart3",ypr[2][2]);    
    rollChart[3].push("rollChart4",ypr[3][2]);    
    
    x[0].push("XChart1", gravity[0][0]);
    x[1].push("XChart2", gravity[1][0]);
    x[2].push("XChart3", gravity[2][0]);
    x[3].push("XChart4", gravity[3][0]);
    
    y[0].push("YChart1",gravity[0][1]);
    y[1].push("YChart2",gravity[1][1]);    
    y[2].push("YChart3",gravity[2][1]);
    y[3].push("YChart4",gravity[3][1]);
    
    z[0].push("ZChart1",gravity[0][2]);
    z[1].push("ZChart2",gravity[1][2]);    
    z[2].push("ZChart3",gravity[2][2]);
    z[3].push("ZChart4",gravity[3][2]);
  }
  else{
    // non-display the simulation
    background(0, 0, 0);
  }
  
  text(loggingStatus, 380, 510);
  text(displayStatus, 380, 460);

  popMatrix();
  
  return;

}


/*! *******************************************************************
 *  @fn         LoggingOnOff
 *  @brief      The toggle button callback for Logging.
 *
 *  @param[in]  theFlag  toggle button status
 *  @return     void
 *  @version    v1.04
 *  @date       01/25/2016  v1.04:  Create on.
 ***********************************************************************/
void LoggingOnOff(boolean theFlag){
  if(theFlag == true){
    loggingtoggle = true;
    loggingStatus = "Data Logging";
  }
  else{
    loggingtoggle = false;
    loggingStatus = "Save Log";
  }
  
  return;
}


/*! *******************************************************************
 *  @fn         DisplayOnOff
 *  @brief      The toggle button callback for Simulator display.
 *
 *  @param[in]  theFlag  toggle button status
 *  @return     void
 *  @version    v1.02
 *  @date       01/14/2016  v1.02:  Create on.
 ***********************************************************************/
void DisplayOnOff(boolean theFlag) {
  if(theFlag == true) {
    displaytoggle = true;
    displayStatus = "Display ON";
  }
  else{
    displaytoggle = false;
    displayStatus = "Display OFF";
  }
  
  return;
}

/*! *******************************************************************
 *  @fn         serialEvent [Default function]
 *  @brief      This function is the serial process.
 *
 *  @param[in]  port  :  the serial port.
 *  @return     void
 *  @version    v1.00
 *  @date       12/02/2015 v1.00 Show Kawabata Create on.
 ***********************************************************************/
void serialEvent(Serial port) {
  interval = millis();
  
  while (port.available() > 0) {
    if(port == portA){
      int ch = port.read();

      if ((synced[0] == 0 && ch != '$')) {      
          return;   // initial synchronization - also used to resync/realign if needed
      }
    
      // add the following if process
      synced[0] = 1;

      if((serialCount[0] == 1 && ch != 2) ||
         (serialCount[0] == 12 && ch != '\r') ||
         (serialCount[0] == 13 && ch != '\n'))  {
      
        serialCount[0] = 0;
        synced[0] = 0;
        return;
      }

      if(serialCount[0] > 0 || ch == '$') {
        packet[0][serialCount[0]++] = (char)ch;
            
        if(serialCount[0] == 14) {
          serialCount[0] = 0; // restart packet byte position
      
          // get quaternion from data packet
          q[0][0] = ((packet[0][2] << 8) | packet[0][3]) / 16384.0f;
          q[0][1] = ((packet[0][4] << 8) | packet[0][5]) / 16384.0f;
          q[0][2] = ((packet[0][6] << 8) | packet[0][7]) / 16384.0f;
          q[0][3] = ((packet[0][8] << 8) | packet[0][9]) / 16384.0f;
        
          for (int i = 0; i < 4; i++) if (q[0][i] >= 2) q[0][i] = -4 + q[0][i];
                
          // set our toxilibs quaternion to new data
          quat1.set(q[0][0], q[0][1], q[0][2], q[0][3]);
                
          print("w:" + q[0][0] + ",\t");
          print("x:" + q[0][1] + ",\t");
          print("y:" + q[0][2] + ",\t");
          println("z:" + q[0][3]);


          // below calculations unnecessary for orientation only using toxilibs
                
          // calculate gravity vector
          gravity[0][0] = 2 * (q[0][1]*q[0][3] - q[0][0]*q[0][2]);
          gravity[0][1] = 2 * (q[0][0]*q[0][1] + q[0][2]*q[0][3]);
          gravity[0][2] = q[0][0]*q[0][0] - q[0][1]*q[0][1] - q[0][2]*q[0][2] + q[0][3]*q[0][3];          
          
    
          // calculate Euler angles
          euler[0][0] = atan2(2*q[0][1]*q[0][2] - 2*q[0][0]*q[0][3], 2*q[0][0]*q[0][0] + 2*q[0][1]*q[0][1] - 1);
          euler[0][1] = -asin(2*q[0][1]*q[0][3] + 2*q[0][0]*q[0][2]);
          euler[0][2] = atan2(2*q[0][2]*q[0][3] - 2*q[0][0]*q[0][1], 2*q[0][0]*q[0][0] + 2*q[0][3]*q[0][3] - 1);
    
          // calculate yaw/pitch/roll angles
          ypr[0][0] = atan2(2*q[0][1]*q[0][2] - 2*q[0][0]*q[0][3], 2*q[0][0]*q[0][0] + 2*q[0][1]*q[0][1] - 1);
          ypr[0][1] = atan(gravity[0][0] / sqrt(gravity[0][1]*gravity[0][1] + gravity[0][2]*gravity[0][2]));
          ypr[0][2] = atan(gravity[0][1] / sqrt(gravity[0][0]*gravity[0][0] + gravity[0][2]*gravity[0][2]));
    
          // output various components for debugging
          //println("q:\t" + round(q[0]*100.0f)/100.0f + "\t" + round(q[1]*100.0f)/100.0f + "\t" + round(q[2]*100.0f)/100.0f + "\t" + round(q[3]*100.0f)/100.0f);
          //println("euler:\t" + euler[0]*180.0f/PI + "\t" + euler[1]*180.0f/PI + "\t" + euler[2]*180.0f/PI);
          //println("ypr:\t" + ypr[0]*180.0f/PI + "\t" + ypr[1]*180.0f/PI + "\t" + ypr[2]*180.0f/PI);
        }
      }
    }
    else if(port == portB){
      int ch = port.read();

      if ((synced[1] == 0 && ch != '$')) {      
          return;   // initial synchronization - also used to resync/realign if needed
      }
    
      // add the following if process
      synced[1] = 1;

      if((serialCount[1] == 1 && ch != 2) ||
         (serialCount[1] == 12 && ch != '\r') ||
         (serialCount[1] == 13 && ch != '\n'))  {
      
        serialCount[1] = 0;
        synced[1] = 0;
        return;
      }

      if(serialCount[1] > 0 || ch == '$') {
        packet[1][serialCount[1]++] = (char)ch;
            
        if(serialCount[1] == 14) {
          serialCount[1] = 0; // restart packet byte position
          // get quaternion from data packet
          q[1][0] = ((packet[1][2] << 8) | packet[1][3]) / 16384.0f;
          q[1][1] = ((packet[1][4] << 8) | packet[1][5]) / 16384.0f;
          q[1][2] = ((packet[1][6] << 8) | packet[1][7]) / 16384.0f;
          q[1][3] = ((packet[1][8] << 8) | packet[1][9]) / 16384.0f;
        
          for (int i = 0; i < 4; i++) if (q[1][i] >= 2) q[1][i] = -4 + q[1][i];
                
          // set our toxilibs quaternion to new data
          quat2.set(q[1][0], q[1][1], q[1][2], q[1][3]);
                
          print("w:" + q[1][0] + ",\t");
          print("x:" + q[1][1] + ",\t");
          print("y:" + q[1][2] + ",\t");
          println("z:" + q[1][3]);


          // below calculations unnecessary for orientation only using toxilibs
                
          // calculate gravity vector
          gravity[1][0] = 2 * (q[1][1]*q[1][3] - q[1][0]*q[1][2]);
          gravity[1][1] = 2 * (q[1][0]*q[1][1] + q[1][2]*q[1][3]);
          gravity[1][2] = q[1][0]*q[1][0] - q[1][1]*q[1][1] - q[1][2]*q[1][2] + q[1][3]*q[1][3];
          
          // calculate Euler angles
          euler[1][0] = atan2(2*q[1][1]*q[1][2] - 2*q[1][0]*q[1][3], 2*q[1][0]*q[1][0] + 2*q[1][1]*q[1][1] - 1);
          euler[1][1] = -asin(2*q[1][1]*q[1][3] + 2*q[1][0]*q[1][2]);
          euler[1][2] = atan2(2*q[1][2]*q[1][3] - 2*q[1][0]*q[1][1], 2*q[1][0]*q[1][0] + 2*q[1][3]*q[1][3] - 1);
    
          // calculate yaw/pitch/roll angles
          ypr[1][0] = atan2(2*q[1][1]*q[1][2] - 2*q[1][0]*q[1][3], 2*q[1][0]*q[1][0] + 2*q[1][1]*q[1][1] - 1);
          ypr[1][1] = atan(gravity[1][0] / sqrt(gravity[1][1]*gravity[1][1] + gravity[1][2]*gravity[1][2]));
          ypr[1][2] = atan(gravity[1][1] / sqrt(gravity[1][0]*gravity[1][0] + gravity[1][2]*gravity[1][2]));    
        }
      }
    }    
    else if(port == portC){
      int ch = port.read();
    
      if ((synced[2] == 0 && ch != '$')) {      
          return;   // initial synchronization - also used to resync/realign if needed
      }
    
      // add the following if process
      synced[2] = 1;

      if((serialCount[2] == 1 && ch != 2) ||
         (serialCount[2] == 12 && ch != '\r') ||
         (serialCount[2] == 13 && ch != '\n'))  {
      
        serialCount[2] = 0;
        synced[2] = 0;
        return;
      }

      if(serialCount[2] > 0 || ch == '$') {
        packet[2][serialCount[2]++] = (char)ch;
            
        if(serialCount[2] == 14) {
          serialCount[2] = 0; // restart packet byte position
                
          // get quaternion from data packet
          q[2][0] = ((packet[2][2] << 8) | packet[2][3]) / 16384.0f;
          q[2][1] = ((packet[2][4] << 8) | packet[2][5]) / 16384.0f;
          q[2][2] = ((packet[2][6] << 8) | packet[2][7]) / 16384.0f;
          q[2][3] = ((packet[2][8] << 8) | packet[2][9]) / 16384.0f;
        
          for (int i = 0; i < 4; i++) if (q[2][i] >= 2) q[2][i] = -4 + q[2][i];
                
          // set our toxilibs quaternion to new data
          quat3.set(q[2][0], q[2][1], q[2][2], q[2][3]);
                
          print("w:" + q[2][0] + ",\t");
          print("x:" + q[2][1] + ",\t");
          print("y:" + q[2][2] + ",\t");
          println("z:" + q[2][3]);


          // below calculations unnecessary for orientation only using toxilibs
                
          // calculate gravity vector
          gravity[2][0] = 2 * (q[2][1]*q[2][3] - q[2][0]*q[2][2]);
          gravity[2][1] = 2 * (q[2][0]*q[2][1] + q[2][2]*q[2][3]);
          gravity[2][2] = q[2][0]*q[2][0] - q[2][1]*q[2][1] - q[2][2]*q[2][2] + q[2][3]*q[2][3];
    
          // calculate Euler angles
          euler[2][0] = atan2(2*q[2][1]*q[2][2] - 2*q[2][0]*q[2][3], 2*q[2][0]*q[2][0] + 2*q[2][1]*q[2][1] - 1);
          euler[2][1] = -asin(2*q[2][1]*q[2][3] + 2*q[2][0]*q[2][2]);
          euler[2][2] = atan2(2*q[2][2]*q[2][3] - 2*q[2][0]*q[2][1], 2*q[2][0]*q[2][0] + 2*q[2][3]*q[2][3] - 1);
    
          // calculate yaw/pitch/roll angles
          ypr[2][0] = atan2(2*q[2][1]*q[2][2] - 2*q[2][0]*q[2][3], 2*q[2][0]*q[2][0] + 2*q[2][1]*q[2][1] - 1);
          ypr[2][1] = atan(gravity[2][0] / sqrt(gravity[2][1]*gravity[2][1] + gravity[2][2]*gravity[2][2]));
          ypr[2][2] = atan(gravity[2][1] / sqrt(gravity[2][0]*gravity[2][0] + gravity[2][2]*gravity[2][2]));    
        }
      }
    }    
    else if(port == portD){
      int ch = port.read();
    
      if ((synced[3] == 0 && ch != '$')) {      
          return;   // initial synchronization - also used to resync/realign if needed
      }
    
      // add the following if process
      synced[3] = 1;

      if((serialCount[3] == 1 && ch != 2) ||
         (serialCount[3] == 12 && ch != '\r') ||
         (serialCount[3] == 13 && ch != '\n'))  {
      
        serialCount[3] = 0;
        synced[3] = 0;
        return;
      }

      if(serialCount[3] > 0 || ch == '$') {
        packet[3][serialCount[3]++] = (char)ch;
            
        if(serialCount[3] == 14) {
          serialCount[3] = 0; // restart packet byte position
                
          // get quaternion from data packet
          q[3][0] = ((packet[3][2] << 8) | packet[3][3]) / 16384.0f;
          q[3][1] = ((packet[3][4] << 8) | packet[3][5]) / 16384.0f;
          q[3][2] = ((packet[3][6] << 8) | packet[3][7]) / 16384.0f;
          q[3][3] = ((packet[3][8] << 8) | packet[3][9]) / 16384.0f;
        
          for (int i = 0; i < 4; i++) if (q[3][i] >= 2) q[3][i] = -4 + q[3][i];
                
          // set our toxilibs quaternion to new data
          quat4.set(q[3][0], q[3][1], q[3][2], q[3][3]);
                
          print("w:" + q[3][0] + ",\t");
          print("x:" + q[3][1] + ",\t");
          print("y:" + q[3][2] + ",\t");
          println("z:" + q[3][3]);


          // below calculations unnecessary for orientation only using toxilibs
                
          // calculate gravity vector
          gravity[3][0] = 2 * (q[3][1]*q[3][3] - q[3][0]*q[3][2]);
          gravity[3][1] = 2 * (q[3][0]*q[3][1] + q[3][2]*q[3][3]);
          gravity[3][2] = q[3][0]*q[3][0] - q[3][1]*q[3][1] - q[3][2]*q[3][2] + q[3][3]*q[3][3];
    
          // calculate Euler angles
          euler[3][0] = atan2(2*q[3][1]*q[3][2] - 2*q[3][0]*q[3][3], 2*q[3][0]*q[3][0] + 2*q[3][1]*q[3][1] - 1);
          euler[3][1] = -asin(2*q[3][1]*q[3][3] + 2*q[3][0]*q[3][2]);
          euler[3][2] = atan2(2*q[3][2]*q[3][3] - 2*q[3][0]*q[3][1], 2*q[3][0]*q[3][0] + 2*q[3][3]*q[3][3] - 1);
    
          // calculate yaw/pitch/roll angles
          ypr[3][0] = atan2(2*q[3][1]*q[3][2] - 2*q[3][0]*q[3][3], 2*q[3][0]*q[3][0] + 2*q[3][1]*q[3][1] - 1);
          ypr[3][1] = atan(gravity[3][0] / sqrt(gravity[3][1]*gravity[3][1] + gravity[3][2]*gravity[3][2]));
          ypr[3][2] = atan(gravity[3][1] / sqrt(gravity[3][0]*gravity[3][0] + gravity[3][2]*gravity[3][2]));    
        }
      }
    }    
  }
  
  return;
}