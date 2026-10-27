#import "AuraAudioEffects.h"
#import "AuraEQDSP.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaToolbox/MediaToolbox.h>
#import <objc/runtime.h>
static char AuraTapKey;
static __weak AuraAudioEffects *AuraCurrentEffects;
static void TapInit(MTAudioProcessingTapRef tap,void *info,void **storage){*storage=info;}
static void TapFinalize(MTAudioProcessingTapRef tap){free(MTAudioProcessingTapGetStorage(tap));}
static void TapPrepare(MTAudioProcessingTapRef tap,CMItemCount frames,const AudioStreamBasicDescription *format){
 AuraEQState *s=MTAudioProcessingTapGetStorage(tap);AuraEQPrepare(s,format->mSampleRate);
 s->valid=(format->mFormatFlags&kAudioFormatFlagIsFloat)&&format->mBitsPerChannel==32;
}
static void TapProcess(MTAudioProcessingTapRef tap,CMItemCount count,MTAudioProcessingTapFlags flags,AudioBufferList *buffers,CMItemCount *outCount,MTAudioProcessingTapFlags *outFlags){
 OSStatus status=MTAudioProcessingTapGetSourceAudio(tap,count,buffers,outFlags,NULL,outCount);
 if(status!=noErr){*outCount=0;return;}
 AuraEQState *s=MTAudioProcessingTapGetStorage(tap);unsigned offset=0;
 for(UInt32 i=0;i<buffers->mNumberBuffers;i++){AudioBuffer *b=&buffers->mBuffers[i];if(b->mData&&s->valid)AuraEQProcess(s,b->mData,(unsigned)*outCount,b->mNumberChannels,offset);offset+=b->mNumberChannels;}
}
@implementation AuraAudioEffects { AuraEQSettings *_settings; __weak AVPlayerItem *_item; }
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
 AuraAudioEffects *instance=[AuraAudioEffects new];instance->_settings=calloc(1,sizeof(AuraEQSettings));AuraCurrentEffects=instance;
 FlutterMethodChannel *channel=[FlutterMethodChannel methodChannelWithName:@"aura/equalizer" binaryMessenger:registrar.messenger];
 [registrar addMethodCallDelegate:instance channel:channel];
 [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(itemReady:) name:@"AuraAudioItemReady" object:nil];
}
- (void)itemReady:(NSNotification*)note {
 AVPlayerItem *item=note.object;if(![item isKindOfClass:AVPlayerItem.class])return;
 _item=item;atomic_store(&_settings->frames,0);if(objc_getAssociatedObject(item,&AuraTapKey))return;
 // The item has reached readyToPlay; its progressive/local audio tracks are loaded.
 NSArray<AVAssetTrack*> *tracks=[item.asset tracksWithMediaType:AVMediaTypeAudio];
 if(!tracks.count)return;
 AuraEQState *state=calloc(1,sizeof(AuraEQState));state->settings=_settings;
 MTAudioProcessingTapCallbacks callbacks={kMTAudioProcessingTapCallbacksVersion_0,state,TapInit,TapFinalize,TapPrepare,NULL,TapProcess};
 MTAudioProcessingTapRef tap=NULL;
 OSStatus status=MTAudioProcessingTapCreate(kCFAllocatorDefault,&callbacks,kMTAudioProcessingTapCreationFlag_PostEffects,&tap);
 if(status!=noErr){free(state);return;}
 AVMutableAudioMixInputParameters *params=[AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:tracks.firstObject];
 params.audioTapProcessor=tap;AVMutableAudioMix *mix=[AVMutableAudioMix audioMix];mix.inputParameters=@[params];item.audioMix=mix;
 objc_setAssociatedObject(item,&AuraTapKey,(__bridge id)tap,OBJC_ASSOCIATION_RETAIN_NONATOMIC);CFRelease(tap);
}
+ (NSDictionary*)processingStatus { return AuraCurrentEffects ? [AuraCurrentEffects status] : @{@"supported":@NO}; }
- (NSDictionary*)status { return @{@"supported":@YES,@"attached":@(objc_getAssociatedObject(_item,&AuraTapKey)!=nil),@"frames":@(atomic_load(&_settings->frames))}; }
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
 if([call.method isEqualToString:@"configure"]){
  NSArray *gains=call.arguments[@"gains"];if(gains.count!=AURA_BANDS){result([FlutterError errorWithCode:@"bands" message:@"Cinque bande richieste" details:nil]);return;}
  for(int i=0;i<AURA_BANDS;i++)atomic_store(&_settings->gains[i],fmaxf(-12,fminf(12,[gains[i] floatValue])));
  atomic_store(&_settings->enabled,[call.arguments[@"enabled"] boolValue]);atomic_fetch_add(&_settings->generation,1);result(nil);
 }else if([call.method isEqualToString:@"status"]){result([self status]);}
 else result(FlutterMethodNotImplemented);
}
// Settings remain alive for any tap retained by AVFoundation during teardown.
- (void)dealloc {[[NSNotificationCenter defaultCenter] removeObserver:self];}
@end
