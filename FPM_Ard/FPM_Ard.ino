#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
 #include <avr/power.h> // Required for 16 MHz Adafruit Trinket
#endif

#define PIN        6 
#define NUMPIXELS 64 // Popular NeoPixel ring size
Adafruit_NeoPixel pixels(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);
int LED = 0; // for incoming serial data

#define DELAYVAL 500 // Time (in milliseconds) to pause between pixels

void setup() {
#if defined(__AVR_ATtiny85__) && (F_CPU == 16000000)
  clock_prescale_set(clock_div_1);
#endif
  pixels.begin(); // INITIALIZE NeoPixel strip object (REQUIRED)
  Serial.begin(9600)
}

void loop() {
  if (Serial.available() > 0) {
    // read the incoming byte:
    LED = Serial.read();
    pixels.clear(); // Set all pixel colors to 'off'
    // pixels.Color() takes RGB values, from 0,0,0 up to 255,255,255
    // Here we're using a moderately bright green color:
    if (LED<=63){
    pixels.setPixelColor(LED, pixels.Color(255, 0, 0));
    pixels.show();   // Send the updated pixel colors to the hardware.
    }

    if (LED>63 && LED<=127){
    pixels.setPixelColor(LED-64, pixels.Color(0, 255, 0));
    pixels.show();   // Send the updated pixel colors to the hardware.
    }

     if (LED>127 && LED<=191){
    pixels.setPixelColor(LED-64*2, pixels.Color(0, 0, 255));
    pixels.show();   // Send the updated pixel colors to the hardware.
    }
    
  }
}
