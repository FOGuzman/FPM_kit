from picamera import PiCamera
import picamera.array
import numpy as np
import serial
import time
led = serial.Serial('/dev/ttyACM1')
print(led.name)
LEDS = np.arange(0,193)



camera = PiCamera(framerate=30,sensor_mode = 1)
camera.awb_mode='off'
camera.exposure_mode='off'
camera.awb_gains=(1,1)
camera.iso=100
camera.shutter_speed = 10000


for k in range(len(LEDS)):
    lit = bytes([LEDS[k]])
    name = "./data_in/im_" + str(k) + ".png"
    print(name)
    led.write(lit)
    camera.capture(name)
	
lit = bytes([500])	
name = "./data_in/im_" + "bknd" + ".png"
led.write(lit)
camera.capture(name)