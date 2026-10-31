#include <Arduino.h>
#include "esp_camera.h"
#include <WiFi.h>
#include <WebServer.h>

// ============================================================
// BEECAM - ESP32-S3 CAMERA SERVER PARA RECEIVER PC
//
// Hardware validado:
//   ESP32-S3-WROOM-1 N16R8
//   OV5640
//
// Objetivo:
//   - sem microSD
//   - ESP32 cria Wi-Fi proprio
//   - PC conecta ao Wi-Fi BeeCam
//   - programa Python controla a camera por HTTP
//
// Endpoints:
//   GET /api/start  -> inicializa/liga a camera
//   GET /capture    -> retorna 1 JPEG
//   GET /api/stop   -> software power-down + deinit
//   GET /status     -> status simples em texto
//
// Configuracao:
//   Resolucao: 800x600 (SVGA)
//   JPEG quality: 6
//   1 framebuffer em PSRAM
//
// Wi-Fi:
//   SSID: BeeCam-XXXX
//   Senha: beecam123
//   IP: 192.168.4.1
// ============================================================


// -------------------- WIFI --------------------

const char* AP_PASSWORD = "beecam123";

WebServer server(80);

String apSSID;


// -------------------- CAMERA PINS --------------------

// Pinagem validada com OV5640 (PID 0x5640)
#define PWDN_GPIO_NUM  -1
#define RESET_GPIO_NUM -1

#define XCLK_GPIO_NUM  15
#define SIOD_GPIO_NUM  4
#define SIOC_GPIO_NUM  5

#define Y9_GPIO_NUM    16
#define Y8_GPIO_NUM    17
#define Y7_GPIO_NUM    18
#define Y6_GPIO_NUM    12
#define Y5_GPIO_NUM    10
#define Y4_GPIO_NUM    8
#define Y3_GPIO_NUM    9
#define Y2_GPIO_NUM    11

#define VSYNC_GPIO_NUM 6
#define HREF_GPIO_NUM  7
#define PCLK_GPIO_NUM  13


// -------------------- CAMERA CONFIG --------------------

#define CAMERA_FRAME_SIZE FRAMESIZE_SVGA   // 800x600
#define CAMERA_JPEG_QUALITY 6

volatile bool cameraActive = false;
volatile uint32_t captureCount = 0;
volatile uint32_t captureErrors = 0;

SemaphoreHandle_t cameraMutex;


// ============================================================
// AUXILIARES
// ============================================================

bool jpegMarkersOK(const uint8_t* data, size_t len) {
  if (!data || len < 4) return false;

  return (
    data[0] == 0xFF &&
    data[1] == 0xD8 &&
    data[len - 2] == 0xFF &&
    data[len - 1] == 0xD9
  );
}


String makeSSID() {
  uint64_t chipid = ESP.getEfuseMac();
  uint16_t suffix = (uint16_t)(chipid & 0xFFFF);

  char buf[32];
  snprintf(buf, sizeof(buf), "BeeCam-%04X", suffix);

  return String(buf);
}


// ============================================================
// CAMERA
// ============================================================

bool initCamera() {
  if (cameraActive) {
    Serial.println("Camera ja esta ativa.");
    return true;
  }

  Serial.println();
  Serial.println("Inicializando camera...");

  camera_config_t config = {};

  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;

  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;

  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;

  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;

  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;

  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  config.frame_size = CAMERA_FRAME_SIZE;
  config.jpeg_quality = CAMERA_JPEG_QUALITY;

  // Mantemos 1 framebuffer porque 2 ja provocaram FB-OVF
  // nos testes anteriores.
  config.fb_count = 1;

  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;

  config.sccb_i2c_port = -1;

  // Campo presente nas versoes recentes do esp32-camera.
  config.jpeg_buffer_size = 0;

  esp_err_t err = esp_camera_init(&config);

  if (err != ESP_OK) {
    Serial.printf(
      "ERRO: esp_camera_init falhou: 0x%X\n",
      (unsigned)err
    );

    cameraActive = false;
    return false;
  }

  sensor_t* sensor = esp_camera_sensor_get();

  if (!sensor) {
    Serial.println("ERRO: sensor nao encontrado apos init.");
    esp_camera_deinit();
    cameraActive = false;
    return false;
  }

  Serial.printf("Sensor PID: 0x%04X\n", sensor->id.PID);

  if (sensor->id.PID == 0x5640) {
    Serial.println("OV5640 detectado.");
  } else {
    Serial.println("ATENCAO: PID diferente do OV5640 esperado.");
  }

  cameraActive = true;

  Serial.println("Camera pronta.");
  Serial.println("Resolucao: 800x600");
  Serial.println("JPEG quality: 6");

  return true;
}


void shutdownCamera() {
  if (!cameraActive) {
    Serial.println("Camera ja esta desligada.");
    return;
  }

  Serial.println();
  Serial.println("Desligando camera...");

  sensor_t* sensor = esp_camera_sensor_get();

  if (sensor) {
    // Software power-down confirmado nos testes anteriores.
    // Registro 0x3008, bit 6.
    int ret = sensor->set_reg(
      sensor,
      0x3008,
      0x40,
      0x40
    );

    Serial.printf(
      "Software power-down: %s\n",
      ret == 0 ? "OK" : "FALHOU"
    );
  }

  delay(200);

  esp_err_t err = esp_camera_deinit();

  if (err == ESP_OK) {
    Serial.println("Driver da camera desligado.");
  } else {
    Serial.printf(
      "ATENCAO: esp_camera_deinit retornou 0x%X\n",
      (unsigned)err
    );
  }

  cameraActive = false;

  Serial.println("Camera inativa.");
}


// ============================================================
// HTTP HANDLERS
// ============================================================

void handleRoot() {
  String html;

  html += "<!DOCTYPE html><html><head>";
  html += "<meta charset='utf-8'>";
  html += "<meta name='viewport' content='width=device-width,initial-scale=1'>";
  html += "<title>BeeCam</title>";
  html += "</head><body>";
  html += "<h2>BeeCam ESP32-S3</h2>";
  html += "<p>Servidor pronto para o BeeCam Receiver PC.</p>";
  html += "<p><b>Endpoints:</b></p>";
  html += "<ul>";
  html += "<li>/api/start</li>";
  html += "<li>/capture</li>";
  html += "<li>/api/stop</li>";
  html += "<li>/status</li>";
  html += "</ul>";
  html += "<p>Camera: ";
  html += cameraActive ? "ATIVA" : "INATIVA";
  html += "</p>";
  html += "</body></html>";

  server.send(200, "text/html; charset=utf-8", html);
}


void handleStart() {
  Serial.println();
  Serial.println("HTTP /api/start");

  if (xSemaphoreTake(cameraMutex, pdMS_TO_TICKS(5000)) != pdTRUE) {
    server.send(
      503,
      "text/plain; charset=utf-8",
      "BUSY"
    );
    return;
  }

  bool ok = initCamera();

  xSemaphoreGive(cameraMutex);

  if (!ok) {
    server.send(
      500,
      "text/plain; charset=utf-8",
      "CAMERA_INIT_FAILED"
    );
    return;
  }

  server.send(
    200,
    "text/plain; charset=utf-8",
    "OK"
  );
}


void handleStop() {
  Serial.println();
  Serial.println("HTTP /api/stop");

  if (xSemaphoreTake(cameraMutex, pdMS_TO_TICKS(5000)) != pdTRUE) {
    server.send(
      503,
      "text/plain; charset=utf-8",
      "BUSY"
    );
    return;
  }

  shutdownCamera();

  xSemaphoreGive(cameraMutex);

  server.send(
    200,
    "text/plain; charset=utf-8",
    "OK"
  );
}


void handleCapture() {
  if (!cameraActive) {
    server.send(
      409,
      "text/plain; charset=utf-8",
      "CAMERA_OFF"
    );
    return;
  }

  if (xSemaphoreTake(cameraMutex, pdMS_TO_TICKS(5000)) != pdTRUE) {
    server.send(
      503,
      "text/plain; charset=utf-8",
      "BUSY"
    );
    return;
  }

  uint32_t t0 = millis();

  camera_fb_t* fb = esp_camera_fb_get();

  if (!fb) {
    captureErrors++;

    xSemaphoreGive(cameraMutex);

    Serial.println("ERRO: esp_camera_fb_get retornou NULL.");

    server.send(
      500,
      "text/plain; charset=utf-8",
      "CAPTURE_FAILED"
    );

    return;
  }

  size_t jpegLen = fb->len;

  if (!jpegMarkersOK(fb->buf, jpegLen)) {
    captureErrors++;

    Serial.printf(
      "JPEG invalido na camera | %u bytes\n",
      (unsigned)jpegLen
    );

    esp_camera_fb_return(fb);

    xSemaphoreGive(cameraMutex);

    server.send(
      500,
      "text/plain; charset=utf-8",
      "INVALID_JPEG"
    );

    return;
  }

  WiFiClient client = server.client();

  client.print(
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: image/jpeg\r\n"
    "Cache-Control: no-store, no-cache, must-revalidate\r\n"
    "Pragma: no-cache\r\n"
    "Connection: close\r\n"
    "Content-Length: "
  );

  client.print(jpegLen);
  client.print("\r\n\r\n");

  size_t sent = 0;

  while (sent < jpegLen && client.connected()) {
    size_t remaining = jpegLen - sent;

    size_t chunk =
      remaining > 4096 ? 4096 : remaining;

    size_t n = client.write(
      fb->buf + sent,
      chunk
    );

    if (n == 0) {
      break;
    }

    sent += n;
  }

  client.flush();

  uint32_t elapsed = millis() - t0;

  captureCount++;

  if (sent != jpegLen) {
    captureErrors++;

    Serial.printf(
      "Captura #%lu | JPEG=%u | enviado=%u | %lu ms | ENVIO INCOMPLETO\n",
      (unsigned long)captureCount,
      (unsigned)jpegLen,
      (unsigned)sent,
      (unsigned long)elapsed
    );
  } else {
    Serial.printf(
      "Captura #%lu | JPEG=%u bytes | %lu ms\n",
      (unsigned long)captureCount,
      (unsigned)jpegLen,
      (unsigned long)elapsed
    );
  }

  esp_camera_fb_return(fb);

  xSemaphoreGive(cameraMutex);
}


void handleStatus() {
  String s;

  s += "beecam=ready\n";
  s += "camera=";
  s += cameraActive ? "on\n" : "off\n";

  s += "captures=";
  s += String(captureCount);
  s += "\n";

  s += "errors=";
  s += String(captureErrors);
  s += "\n";

  s += "resolution=800x600\n";
  s += "jpeg_quality=6\n";

  server.send(
    200,
    "text/plain; charset=utf-8",
    s
  );
}


void handleNotFound() {
  server.send(
    404,
    "text/plain; charset=utf-8",
    "NOT_FOUND"
  );
}


// ============================================================
// SETUP
// ============================================================

void setup() {
  Serial.begin(115200);
  delay(1200);

  Serial.println();
  Serial.println("============================================");
  Serial.println(" BEECAM - CAMERA WIFI PARA RECEIVER PC");
  Serial.println("============================================");

  if (psramFound()) {
    Serial.println("PSRAM: OK");
    Serial.printf(
      "PSRAM total: %u bytes\n",
      (unsigned)ESP.getPsramSize()
    );
    Serial.printf(
      "PSRAM livre: %u bytes\n",
      (unsigned)ESP.getFreePsram()
    );
  } else {
    Serial.println("ERRO: PSRAM nao encontrada.");
  }

  cameraMutex = xSemaphoreCreateMutex();

  if (!cameraMutex) {
    Serial.println("ERRO FATAL: nao foi possivel criar mutex.");
    while (true) delay(1000);
  }

  // Camera permanece desligada no boot.
  cameraActive = false;

  apSSID = makeSSID();

  WiFi.mode(WIFI_AP);

  bool apOK = WiFi.softAP(
    apSSID.c_str(),
    AP_PASSWORD,
    6,      // canal
    false,  // SSID visivel
    1       // max 1 cliente
  );

  if (!apOK) {
    Serial.println("ERRO FATAL: falha ao criar AP Wi-Fi.");
    while (true) delay(1000);
  }

  IPAddress ip = WiFi.softAPIP();

  server.on("/", HTTP_GET, handleRoot);
  server.on("/api/start", HTTP_GET, handleStart);
  server.on("/capture", HTTP_GET, handleCapture);
  server.on("/api/stop", HTTP_GET, handleStop);
  server.on("/status", HTTP_GET, handleStatus);

  server.onNotFound(handleNotFound);

  server.begin();

  Serial.println();
  Serial.println("BEECAM PRONTA");
  Serial.printf("Wi-Fi: %s\n", apSSID.c_str());
  Serial.printf("Senha: %s\n", AP_PASSWORD);
  Serial.printf(
    "Endereco: http://%u.%u.%u.%u\n",
    ip[0], ip[1], ip[2], ip[3]
  );

  Serial.println("Resolucao: 800x600 | JPEG quality: 6");
  Serial.println("Camera permanece desligada ate /api/start.");
  Serial.println();
  Serial.println("Endpoints:");
  Serial.println("  GET /api/start");
  Serial.println("  GET /capture");
  Serial.println("  GET /api/stop");
  Serial.println("  GET /status");
  Serial.println("============================================");
}


// ============================================================
// LOOP
// ============================================================

void loop() {
  server.handleClient();
  delay(1);
}
