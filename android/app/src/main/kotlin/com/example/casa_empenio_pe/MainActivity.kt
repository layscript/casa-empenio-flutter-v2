package com.example.casa_empenio_pe

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var huellero: HuelleroChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lector de huellas BioMini (canal "casa_empenio/huellero")
        huellero = HuelleroChannel(this).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onDestroy() {
        huellero?.dispose()
        super.onDestroy()
    }
}
