#include <stdio.h>
#include <wiringPi.h>
#include <stdlib.h>

#define MOSI 0
#define MISO 1
#define MCLK 2
#define SCLK 3

void setup(){
  if(wiringPiSetup() == -1){
    printf("wiringPiSetup failed...?\n");
    exit(1);
  }

  pinMode(MCLK, OUTPUT);
  pinMode(SCLK, INPUT);
  pinMode(MOSI, OUTPUT);
  pinMode(MISO, INPUT);
}

void shutdown(){
  pinMode(MCLK, INPUT);
  pinMode(SCLK, INPUT);
  pinMode(MOSI, INPUT);
  pinMode(MISO, INPUT);
}

int io1(int send){
  int in;

  digitalWrite(MCLK,1);

  while(digitalRead(SCLK)==0){
    continue; // add a delay here?
    //delay(1); // 1 ms delay
  }

  digitalWrite(MOSI,send);
  digitalWrite(MCLK,0);

  while(digitalRead(SCLK)==1){
    continue; // add a delay here?
    //delay(1); // 1 ms delay
  }

  in = digitalRead(MISO);

  return in;
}

int io16(int send){
  int i=0;
  int in=0;
  
  for(i=0; i<16; ++i){
    in = in | (io1(send & 1) << i);
    send = send >> 1;
  }

  return in;
}

int main(void){
  int in,out,i;
  setup();

  printf("starting up...\n");
  out = 15;
  for(i=0; i<10000; ++i){
    in = io16(out);
  }
  printf("finished!\n");

  shutdown();

  return 0;
}
