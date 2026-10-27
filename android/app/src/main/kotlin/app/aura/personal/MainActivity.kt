package app.aura.personal
import android.content.Intent
import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
class MainActivity : AudioServiceActivity() {
 private var authResult: MethodChannel.Result? = null
 private var leftForAuth = false
 override fun configureFlutterEngine(engine: FlutterEngine) {
  super.configureFlutterEngine(engine)
  MethodChannel(engine.dartExecutor.binaryMessenger,"aura/spotify_auth").setMethodCallHandler { call,result ->
   if(call.method!="authorize"){result.notImplemented();return@setMethodCallHandler}
   val uri=Uri.parse(call.argument<String>("url") ?: "")
   if(uri.scheme!="https"||uri.host!="accounts.spotify.com"||authResult!=null){result.error("auth","Accesso non disponibile",null);return@setMethodCallHandler}
   authResult=result
   try{startActivity(Intent(Intent.ACTION_VIEW,uri))}catch(e:Exception){authResult=null;result.error("auth","Browser non disponibile",null)}
  }
 }
 override fun onPause(){super.onPause();if(authResult!=null)leftForAuth=true}
 override fun onResume(){super.onResume();if(leftForAuth){leftForAuth=false;android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({authResult?.error("cancelled","Accesso annullato",null);authResult=null},500)}}
 override fun onNewIntent(intent:Intent){
  super.onNewIntent(intent)
  val uri=intent.data ?: return
  if(uri.scheme=="org.example.aura.spotify"&&uri.host=="callback"){authResult?.success(uri.toString());authResult=null}
 }
}
