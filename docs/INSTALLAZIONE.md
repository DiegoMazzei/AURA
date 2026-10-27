# Installa AURA 0.7.0

## Android · APK di prova

Scarica `AURA-0.7.0-Android.apk` dalla release e aprilo sul telefono.
Consenti l’installazione da quella sorgente quando Android lo richiede.
Richiede Android 7 o successivo; include ARM64, ARMv7 e x86_64.
La build usa una firma di sviluppo: è destinata a prove, non al Play Store.
Le build pubbliche usano la configurazione dei sorgenti ripuliti. Non contengono
la libreria o la cronologia di un telefono.

## iOS · IPA da firmare

`AURA-0.7.0-iOS-unsigned.ipa` è una build Release per dispositivi fisici,
senza certificati, profili di provisioning o dispositivi personali registrati.
Non si installa direttamente toccando il file su iPhone: deve essere firmata
con un account e un profilo compatibili con il dispositivo.

Per lavorare dai sorgenti: apri `ios/Runner.xcworkspace` in Xcode, imposta
un bundle identifier univoco e il tuo Team, seleziona il telefono e avvia
una configurazione Release. Lo snapshot usa `org.example.aura`.

Per distribuire una build già installabile ad altri utenti occorre configurare
TestFlight oppure una distribuzione per dispositivi registrati.
[Guida Apple](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices).
Nessun collegamento TestFlight è attualmente disponibile.

## Verifica dei download

La release include `SHA256SUMS.txt`. Su macOS/Linux esegui nella cartella dei file:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

I download sono disponibili dalla pagina pubblica delle release GitHub.

## Cambiare telefono

Usa Impostazioni → Trasferisci il catalogo. [Guida al backup](CATALOGO_BACKUP.md).
