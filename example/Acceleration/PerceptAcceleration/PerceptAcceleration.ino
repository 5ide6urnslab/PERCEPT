/*************************************************************************
 * File Name          : PerceptAcceleration
 * Author             : Show Kawabata(5ide6urns lab)
 * Version            : v1.00
 * Date               : 10/16/2015
 * Parts required     : MPU9150(Sparkfun), Adafruit Trinket Pro 3V 12MHz,
 *                      FTDI USB-Serial convert board(5V)
 * Description        : 
 *
 * License            : Released under the MIT license.
 *                      http://opensource.org/licenses/mit-license.php
 * Copyright          : Copyright (C) 2015 5ide6urns lab All right reserved.
 * History            : 10/16/2015 v1.00 Show Kawabata Create on.
 **************************************************************************/
 
#include "I2Cdev.h"

/*  [Note]: about the MPU9150_9Axis_MotionApps41 header file
 *    It is added to use the DMP of MPU9150.
 */
#include "MPU9150_9Axis_MotionApps41.h"

#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
    #include "Wire.h"
#endif

/******************************************
 * Class Object
 ******************************************/
/*  [Note]: about the MPU9150 mpu.
 *    It is added to use the DMP of MPU9150.
 */
MPU9150 mpu;

/******************************************
 * Global Variable
 ******************************************/
// (Arduino is 13, Teensy is 11, Teensy++ is 6)
#define LED_PIN 13
bool blinkState = false;

bool dmpReady = false;  // set true if DMP init was successful
uint8_t mpuIntStatus;   // holds actual interrupt status byte from MPU
uint8_t devStatus;      // return status after each device operation (0 = success, !0 = error)
uint16_t packetSize;    // expected DMP packet size (default is 42 bytes)
uint16_t fifoCount;     // count of all bytes currently in FIFO
uint8_t fifoBuffer[64]; // FIFO storage buffer

// packet structure for communicating the Processing
uint8_t packet[14] = { '$', 0x02, 0,0, 0,0, 0,0, 0,0, 0x00, 0x00, '\r', '\n' };

volatile bool mpuInterrupt = false;     // indicates whether MPU interrupt pin has gone high


/*! ********************************************************************
 *  @fn         dmpDataReady
 *  @brief      This function is the Interrupt Detection Routine.
 *
 *  @param[in]  void
 *  @return     void
 *  @version    v1.00
 *  @date       10/16/2015 v1.00 Show Kawabata Create on.
 ***********************************************************************/
void dmpDataReady() {
    mpuInterrupt = true;
    return;
}


/*! ********************************************************************
 *  @fn         setup [Default function]
 *  @brief      This function is the initilize process.
 *
 *  @param[in]  void
 *  @return     void
 *  @version    v1.00
 *  @date       10/16/2015 v1.00 Show Kawabata Create on.
 ***********************************************************************/
void setup() {
    // join I2C bus (I2Cdev library doesn't do this automatically)
    #if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
        Wire.begin();
        TWBR = 24; // 400kHz I2C clock (200kHz if CPU is 8MHz)
    #elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
        Fastwire::setup(400, true);
    #endif

    Serial.begin(115200);
    while (!Serial); // wait for Leonardo enumeration, others continue immediately

    Serial.println(F("Initializing I2C devices..."));
    mpu.initialize();

    Serial.println(F("Testing device connections..."));
    Serial.println(mpu.testConnection() ? F("MPU6050 connection successful") : F("MPU6050 connection failed"));

    Serial.println(F("Initializing DMP..."));
    devStatus = mpu.dmpInitialize();

    if (devStatus == 0) {
        // turn on the DMP, now that it's ready
        Serial.println(F("Enabling DMP..."));
        mpu.setDMPEnabled(true);

        Serial.println(F("Enabling interrupt detection (Arduino external interrupt 1)..."));

        /*  [Note]: about the external interrupt.
         *    When you use the Adafruit Trinket Pro 3V, 
         *    the external interrupt is only INT1(D3).
         */ 
        attachInterrupt(digitalPinToInterrupt(3), dmpDataReady, RISING);
        mpuIntStatus = mpu.getIntStatus();

        Serial.println(F("DMP ready! Waiting for first interrupt..."));
        dmpReady = true;

        packetSize = mpu.dmpGetFIFOPacketSize();
    }
    else {
        Serial.print(F("DMP Initialization failed (code "));
        Serial.print(devStatus);
        Serial.println(F(")"));
    }

    // configure LED for output
    pinMode(LED_PIN, OUTPUT);
    
    return;
}


/*! ********************************************************************
 *  @fn         loop [Default function]
 *  @brief      This function is the loop process.
 *
 *  @param[in]  void
 *  @return     void
 *  @version    v1.00
 *  @date       10/16/2015 v1.00 Show Kawabata Create on.
 ***********************************************************************/
void loop() {
  
    // if programming failed, don't try to do anything
    if (!dmpReady) return;

    // wait for MPU interrupt or extra packet(s) available
    while (!mpuInterrupt && fifoCount < packetSize) {
        // if you are really paranoid you can frequently test in between other
        // stuff to see if mpuInterrupt is true, and if so, "break;" from the
        // while() loop to immediately process the MPU data
    }

    // reset interrupt flag and get INT_STATUS byte
    mpuInterrupt = false;
    mpuIntStatus = mpu.getIntStatus();

    fifoCount = mpu.getFIFOCount();

    // check for overflow (this should never happen unless our code is too inefficient)
    if ((mpuIntStatus & 0x10) || fifoCount == 1024) {
        // reset so we can continue cleanly
        mpu.resetFIFO();
        Serial.println(F("FIFO overflow!"));

    }
    else if (mpuIntStatus & 0x02) {
        // wait for correct available data length, should be a VERY short wait
        while (fifoCount < packetSize) fifoCount = mpu.getFIFOCount();

        mpu.getFIFOBytes(fifoBuffer, packetSize);        
        fifoCount -= packetSize;
    
        // display quaternion values
        packet[2] = fifoBuffer[0];
        packet[3] = fifoBuffer[1];
        packet[4] = fifoBuffer[4];
        packet[5] = fifoBuffer[5];
        packet[6] = fifoBuffer[8];
        packet[7] = fifoBuffer[9];
        packet[8] = fifoBuffer[12];
        packet[9] = fifoBuffer[13];
        Serial.write(packet, 14);
        packet[11]++; // packetCount, loops at 0xFF on purpose

        // blink LED to indicate activity
        blinkState = !blinkState;
        digitalWrite(LED_PIN, blinkState);
    }
    
    return;
}
