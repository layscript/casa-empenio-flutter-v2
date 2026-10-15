package com.example.casa_empenio_pe;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Base64;

import com.biominiseries.BioMiniFactory;
import com.biominiseries.CaptureResponder;
import com.biominiseries.IBioMiniDevice;
import com.biominiseries.IUsbEventHandler;

import java.io.ByteArrayOutputStream;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Conecta la app con el lector de huellas Suprema BioMini (SDK BioMini v3.0.3.3).
 * Canal Flutter: "casa_empenio/huellero"
 *   - capturar : pide permiso USB, captura una huella y devuelve
 *                { template (base64), templateType, quality, image (PNG base64) }
 *   - cancelar : aborta la captura en curso
 */
public class HuelleroChannel implements MethodChannel.MethodCallHandler {

    private static final String CHANNEL = "casa_empenio/huellero";
    private static final String ACTION_USB_PERMISSION = "com.example.casa_empenio_pe.USB_PERMISSION";
    private static final int VENDOR_ID = 0x16d1; // Suprema (igual que el ejemplo del SDK)
    private static final long TIMEOUT_MS = 25000;

    private final Activity activity;
    private final UsbManager usbManager;
    private final Handler main = new Handler(Looper.getMainLooper());

    private BioMiniFactory factory;
    private IBioMiniDevice device;
    private UsbDevice usbDevice;
    private MethodChannel.Result pending;
    private Runnable timeoutTask;
    private boolean receiverRegistered = false;

    public HuelleroChannel(Activity activity) {
        this.activity = activity;
        this.usbManager = (UsbManager) activity.getSystemService(Context.USB_SERVICE);
    }

    public void register(BinaryMessenger messenger) {
        new MethodChannel(messenger, CHANNEL).setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "capturar":
                capturar(result);
                break;
            case "cancelar":
                cancelar();
                result.success(true);
                break;
            default:
                result.notImplemented();
        }
    }

    // ------------------------------------------------------------------ captura

    private void capturar(MethodChannel.Result result) {
        if (pending != null) {
            result.error("OCUPADO", "Ya hay una captura en curso.", null);
            return;
        }
        usbDevice = buscarLector();
        if (usbDevice == null) {
            result.error("NO_DISPOSITIVO",
                    "No se detecta el lector BioMini. Conéctelo por USB (cable OTG) e intente de nuevo.", null);
            return;
        }
        pending = result;
        registrarReceiver();
        if (!usbManager.hasPermission(usbDevice)) {
            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                flags |= PendingIntent.FLAG_MUTABLE;
            }
            Intent intent = new Intent(ACTION_USB_PERMISSION);
            intent.setPackage(activity.getPackageName());
            PendingIntent pi = PendingIntent.getBroadcast(activity, 0, intent, flags);
            usbManager.requestPermission(usbDevice, pi);
        } else {
            iniciarCaptura();
        }
    }

    private UsbDevice buscarLector() {
        HashMap<String, UsbDevice> lista = usbManager.getDeviceList();
        for (UsbDevice d : lista.values()) {
            if (d.getVendorId() == VENDOR_ID) {
                return d;
            }
        }
        return null;
    }

    private void iniciarCaptura() {
        try {
            if (factory == null || device == null) {
                cerrarLector();
                factory = new BioMiniFactory(activity, usbManager) {
                    @Override
                    public void onDeviceChange(IUsbEventHandler.DeviceChangeEvent event, Object dev) {
                        // sin acciones: el estado se maneja en cada captura
                    }
                };
                factory.setTransferMode(IBioMiniDevice.TransferMode.MODE1);
                boolean ok = factory.addDevice(usbDevice);
                if (!ok) {
                    cerrarLector();
                    fallo("INICIO", "No se pudo iniciar el lector de huellas.");
                    return;
                }
                device = factory.getDevice(0);
            }
            if (device == null) {
                cerrarLector();
                fallo("INICIO", "No se pudo abrir el lector de huellas.");
                return;
            }

            IBioMiniDevice.CaptureOption opcion = new IBioMiniDevice.CaptureOption();
            opcion.captureFuntion = IBioMiniDevice.CaptureFuntion.CAPTURE_SINGLE;
            opcion.extractParam.captureTemplate = true;
            opcion.extractParam.maxTemplateSize = IBioMiniDevice.MaxTemplateSize.MAX_TEMPLATE_1024;

            programarTiempoLimite();
            boolean iniciada = device.captureSingle(opcion, respuesta, true);
            if (!iniciada) {
                fallo("CAPTURA", "No se pudo iniciar la captura de la huella.");
            }
        } catch (Throwable t) {
            cerrarLector();
            fallo("ERROR", "Error con el lector: " + t.getMessage());
        }
    }

    private final CaptureResponder respuesta = new CaptureResponder() {
        @Override
        public void onCapture(Object context, IBioMiniDevice.FingerState fingerState) {
            super.onCapture(context, fingerState);
        }

        @Override
        public boolean onCaptureEx(Object context, IBioMiniDevice.CaptureOption option,
                                   Bitmap capturedImage, IBioMiniDevice.TemplateData capturedTemplate,
                                   IBioMiniDevice.FingerState fingerState) {
            try {
                if (capturedTemplate == null || capturedTemplate.data == null || capturedImage == null) {
                    fallo("SIN_HUELLA", "No se pudo leer la huella. Limpie el lector e intente de nuevo.");
                    return true;
                }
                ByteArrayOutputStream bos = new ByteArrayOutputStream();
                capturedImage.compress(Bitmap.CompressFormat.PNG, 100, bos);

                Map<String, Object> datos = new HashMap<>();
                datos.put("template", Base64.encodeToString(capturedTemplate.data, Base64.NO_WRAP));
                datos.put("templateType", capturedTemplate.type != null ? capturedTemplate.type.value() : 0);
                datos.put("quality", capturedTemplate.quality);
                datos.put("image", Base64.encodeToString(bos.toByteArray(), Base64.NO_WRAP));
                exito(datos);
            } catch (Throwable t) {
                fallo("ERROR", "No se pudo procesar la huella: " + t.getMessage());
            }
            return true;
        }

        @Override
        public void onCaptureError(Object context, int errorCode, String error) {
            fallo("CAPTURA", "Error al capturar la huella (" + errorCode + "): " + error);
        }
    };

    private void cancelar() {
        try {
            if (device != null && device.isCapturing()) {
                device.abortCapturing();
            }
        } catch (Throwable ignored) {
        }
        fallo("CANCELADO", "Captura cancelada.");
    }

    // ------------------------------------------------------------------ respuestas

    private void programarTiempoLimite() {
        limpiarTiempoLimite();
        timeoutTask = new Runnable() {
            @Override
            public void run() {
                try {
                    if (device != null && device.isCapturing()) {
                        device.abortCapturing();
                    }
                } catch (Throwable ignored) {
                }
                fallo("TIEMPO", "Tiempo agotado: no se detectó el dedo en el lector.");
            }
        };
        main.postDelayed(timeoutTask, TIMEOUT_MS);
    }

    private void limpiarTiempoLimite() {
        if (timeoutTask != null) {
            main.removeCallbacks(timeoutTask);
            timeoutTask = null;
        }
    }

    private void exito(final Object datos) {
        main.post(new Runnable() {
            @Override
            public void run() {
                limpiarTiempoLimite();
                if (pending != null) {
                    MethodChannel.Result r = pending;
                    pending = null;
                    r.success(datos);
                }
            }
        });
    }

    private void fallo(final String codigo, final String mensaje) {
        main.post(new Runnable() {
            @Override
            public void run() {
                limpiarTiempoLimite();
                if (pending != null) {
                    MethodChannel.Result r = pending;
                    pending = null;
                    r.error(codigo, mensaje, null);
                }
            }
        });
    }

    // ------------------------------------------------------------------ USB

    private final BroadcastReceiver receptor = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String accion = intent.getAction();
            if (ACTION_USB_PERMISSION.equals(accion)) {
                boolean concedido = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false);
                if (concedido && usbDevice != null) {
                    main.post(new Runnable() {
                        @Override
                        public void run() {
                            iniciarCaptura();
                        }
                    });
                } else {
                    fallo("PERMISO", "Se negó el permiso para usar el lector USB.");
                }
            } else if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(accion)) {
                cerrarLector();
                fallo("DESCONECTADO", "Se desconectó el lector de huellas.");
            }
        }
    };

    private void registrarReceiver() {
        if (receiverRegistered) return;
        IntentFilter filtro = new IntentFilter();
        filtro.addAction(ACTION_USB_PERMISSION);
        filtro.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
        if (Build.VERSION.SDK_INT >= 33) {
            activity.registerReceiver(receptor, filtro, Context.RECEIVER_NOT_EXPORTED);
        } else {
            activity.registerReceiver(receptor, filtro);
        }
        receiverRegistered = true;
    }

    private void cerrarLector() {
        try {
            if (factory != null) {
                if (usbDevice != null) {
                    factory.removeDevice(usbDevice);
                }
                factory.close();
            }
        } catch (Throwable ignored) {
        }
        factory = null;
        device = null;
    }

    public void dispose() {
        limpiarTiempoLimite();
        cerrarLector();
        if (receiverRegistered) {
            try {
                activity.unregisterReceiver(receptor);
            } catch (Throwable ignored) {
            }
            receiverRegistered = false;
        }
    }
}
