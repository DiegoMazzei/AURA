#ifndef AURA_EQ_DSP_H
#define AURA_EQ_DSP_H
#include <math.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <string.h>
#define AURA_BANDS 5
#define AURA_CHANNELS 8
typedef struct { _Atomic(float) gains[AURA_BANDS]; atomic_bool enabled; atomic_uint generation; atomic_ullong frames; } AuraEQSettings;
typedef struct { AuraEQSettings *settings; double rate; unsigned generation; int valid; double b0[5],b1[5],b2[5],a1[5],a2[5],z1[8][5],z2[8][5]; float preamp; } AuraEQState;
static inline void AuraEQPrepare(AuraEQState *s,double rate) { s->rate=rate; s->generation=~0u; memset(s->z1,0,sizeof(s->z1));memset(s->z2,0,sizeof(s->z2)); }
static inline void AuraEQCoefficients(AuraEQState *s) {
 static const double frequencies[5]={60,230,910,3600,14000};
 float peak=0;
 for(int i=0;i<5;i++) {
  double gain=atomic_load(&s->settings->gains[i]);if(gain>peak)peak=gain;
  double w=2*M_PI*fmin(frequencies[i],s->rate*.45)/s->rate,A=pow(10,gain/40),alpha=sin(w)/(2*.8),c=cos(w),a0=1+alpha/A;
  s->b0[i]=(1+alpha*A)/a0;s->b1[i]=-2*c/a0;s->b2[i]=(1-alpha*A)/a0;s->a1[i]=-2*c/a0;s->a2[i]=(1-alpha/A)/a0;
 }
 s->preamp=powf(10,-peak/20);s->generation=atomic_load(&s->settings->generation);
}
static inline void AuraEQProcess(AuraEQState *s,float *samples,unsigned frames,unsigned channels,unsigned channelOffset) {
 atomic_fetch_add(&s->settings->frames,frames);
 if(!s->valid||!atomic_load(&s->settings->enabled)||s->rate<=0)return;
 if(s->generation!=atomic_load(&s->settings->generation))AuraEQCoefficients(s);
 for(unsigned frame=0;frame<frames;frame++)for(unsigned ch=0;ch<channels;ch++) {
  unsigned channel=ch+channelOffset;if(channel>=AURA_CHANNELS)continue;
  double x=samples[frame*channels+ch]*s->preamp;
  for(int i=0;i<AURA_BANDS;i++) { double y=s->b0[i]*x+s->z1[channel][i];s->z1[channel][i]=s->b1[i]*x-s->a1[i]*y+s->z2[channel][i];s->z2[channel][i]=s->b2[i]*x-s->a2[i]*y;x=y; }
  samples[frame*channels+ch]=(float)fmax(-1,fmin(1,x));
 }
}
#endif
