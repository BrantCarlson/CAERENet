#include <stdio.h>
#include <wiringPi.h>

#define MCLK 0
#define SCLK 1
#define MOSI 2
#define MISO 3

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

  for(i=0; i<10; ++i){
    out = 15;
    in = io16(out);
    printf("sent %d, got %d\n",out,in);
  }

  shutdown();

  return 0;
}
