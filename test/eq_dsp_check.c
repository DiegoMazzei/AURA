#include "../ios/Runner/AuraEQDSP.h"
#include <stdio.h>
static double tone(double hz,int cut,int enabled){
 AuraEQSettings settings={0};atomic_store(&settings.enabled,enabled);atomic_store(&settings.gains[0],cut);atomic_store(&settings.generation,1);
 AuraEQState state={0};state.settings=&settings;state.valid=1;AuraEQPrepare(&state,48000);
 float samples[48000];for(int i=0;i<48000;i++)samples[i]=.2*sin(2*M_PI*hz*i/48000);
 AuraEQProcess(&state,samples,48000,1,0);double sum=0;for(int i=24000;i<48000;i++)sum+=samples[i]*samples[i];return sqrt(sum/24000);
}
int main(){double base=tone(60,0,1),cut=tone(60,-12,1),mid=tone(1000,-12,1),bypass=tone(60,-12,0);
 printf("60 Hz baseline %.6f, cut %.6f, 1 kHz %.6f, bypass %.6f\n",base,cut,mid,bypass);
 return !(cut/base<.30 && cut/base>.20 && mid/base>.95 && fabs(bypass/base-1)<.001);
}
