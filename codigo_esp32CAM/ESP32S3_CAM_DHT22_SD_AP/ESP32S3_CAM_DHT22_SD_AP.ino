#include <Arduino.h>
#include <DHT.h>
#include <FS.h>
#include <SD_MMC.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include <esp_camera.h>
#include <esp_http_server.h>
#include <esp_mac.h>
#include <sys/time.h>
#include <time.h>

#include "AviRecorder.h"

// ============================================================
// CONFIGURACAO DO EQUIPAMENTO
// Placa alvo: ESP32-S3-CAM 40 pinos, ESP32-S3-WROOM-1 N16R8,
// camera OV5640, dois conectores USB-C e slot microSD integrado.
// Confira o pinout da sua placa antes de energizar o circuito.
// ============================================================

// A senha deve ter no minimo 8 caracteres para o Wi-Fi protegido.
constexpr char AP_PASSWORD[] = "123456789";
constexpr char DEVICE_TYPE_CODE[] = "ESP32S3-CAM-DHT22-AVI-V2";
constexpr uint16_t ANNOUNCE_UDP_PORT = 4210;
constexpr uint8_t AP_CHANNEL = 6;
constexpr uint8_t AP_MAX_CLIENTS = 4;

// Intervalos de coleta e armazenamento.
constexpr uint32_t SENSOR_INTERVAL_MS = 10UL * 1000UL;
constexpr uint32_t PHOTO_INTERVAL_MS = 60UL * 1000UL;
constexpr uint32_t ANNOUNCE_INTERVAL_MS = 1000UL;

// Video AVI/MJPEG. Cada arquivo e fechado e um novo segmento e iniciado
// para evitar arquivos gigantes e reduzir perdas se faltar energia.
constexpr bool AUTO_START_VIDEO_RECORDING = false;
constexpr uint16_t VIDEO_TARGET_FPS = 5;
constexpr uint32_t VIDEO_FRAME_INTERVAL_MS = 1000UL / VIDEO_TARGET_FPS;
constexpr uint32_t VIDEO_SEGMENT_DURATION_MS = 5UL * 60UL * 1000UL;
constexpr uint64_t VIDEO_SEGMENT_MAX_BYTES = 512ULL * 1024ULL * 1024ULL;
constexpr uint64_t STORAGE_MIN_FREE_BYTES = 2ULL * 1024ULL * 1024ULL * 1024ULL;
constexpr uint64_t STORAGE_CLEANUP_TARGET_EXTRA_BYTES = VIDEO_SEGMENT_MAX_BYTES;
constexpr uint16_t AVI_CHECKPOINT_EVERY_FRAMES = 50;

// DHT22: DATA no GPIO21, VCC em 3V3 e GND em GND.
// Use resistor de 10 kohms entre DATA e 3V3 se o modulo nao o possuir.
constexpr gpio_num_t DHT_PIN = GPIO_NUM_21;
#define DHT_TYPE DHT22

// Camera - pinout da ESP32-S3-CAM N16R8 de 40 pinos.
constexpr int CAM_PIN_PWDN = -1;
constexpr int CAM_PIN_RESET = -1;
constexpr int CAM_PIN_XCLK = 15;
constexpr int CAM_PIN_SIOD = 4;
constexpr int CAM_PIN_SIOC = 5;
constexpr int CAM_PIN_D0 = 11;
constexpr int CAM_PIN_D1 = 9;
constexpr int CAM_PIN_D2 = 8;
constexpr int CAM_PIN_D3 = 10;
constexpr int CAM_PIN_D4 = 12;
constexpr int CAM_PIN_D5 = 18;
constexpr int CAM_PIN_D6 = 17;
constexpr int CAM_PIN_D7 = 16;
constexpr int CAM_PIN_VSYNC = 6;
constexpr int CAM_PIN_HREF = 7;
constexpr int CAM_PIN_PCLK = 13;

// microSD em modo SD_MMC de 1 bit.
constexpr int SD_PIN_CLK = 39;
constexpr int SD_PIN_CMD = 38;
constexpr int SD_PIN_D0 = 40;

// Resolucao usada tanto nas fotos quanto no stream MJPEG.
// XGA = 1024 x 768. Reduza para FRAMESIZE_VGA se quiser mais FPS.
constexpr framesize_t CAMERA_FRAME_SIZE = FRAMESIZE_VGA;
constexpr int CAMERA_JPEG_QUALITY = 12;  // 10-63; menor = mais qualidade.

constexpr char DATA_FILE[] = "/dados.csv";
constexpr char PHOTOS_DIR[] = "/fotos";
constexpr char VIDEOS_DIR[] = "/videos";

DHT dht(DHT_PIN, DHT_TYPE);
WiFiUDP announceUdp;
httpd_handle_t controlServer = nullptr;
httpd_handle_t streamServer = nullptr;
SemaphoreHandle_t sdMutex = nullptr;
AviRecorder aviRecorder;

String apSsid;
String deviceId;
bool cameraReady = false;
bool sdReady = false;
bool timeSynchronized = false;
float lastTemperatureC = NAN;
float lastHumidityPct = NAN;
uint32_t lastSensorAt = 0;
uint32_t lastPhotoAt = 0;
uint32_t lastAnnounceAt = 0;
uint8_t previousStationCount = 0;
volatile bool videoRecordingRequested = AUTO_START_VIDEO_RECORDING;
volatile bool videoRecording = false;
uint32_t lastVideoFrameAt = 0;
uint32_t lastVideoSpaceCheckAt = 0;
uint32_t lastStorageMaintenanceAt = 0;
String currentVideoPath;

static const char INDEX_HTML[] PROGMEM = R"rawliteral(
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>ESP32-S3-CAM</title>
  <style>
    :root{color-scheme:dark;font-family:system-ui,sans-serif;background:#101418;color:#edf2f7}
    body{max-width:900px;margin:auto;padding:18px}.card{background:#192129;border:1px solid #2e3b47;border-radius:14px;padding:16px;margin:12px 0}
    h1{font-size:1.45rem;margin:0 0 8px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:10px}
    .value{font-size:1.65rem;font-weight:700}.muted{color:#a9b6c2;font-size:.9rem}img{width:100%;border-radius:10px;background:#000;min-height:220px;object-fit:contain}
    button,a.button{display:inline-block;background:#2d7ff9;color:#fff;border:0;border-radius:9px;padding:11px 14px;margin:4px 6px 4px 0;text-decoration:none;cursor:pointer}
    button.secondary,a.secondary{background:#344452}code{word-break:break-all}#status{color:#7ee787}
  </style>
</head>
<body>
  <div class="card"><h1>Monitor ESP32-S3-CAM</h1><div id="status">Conectando...</div><div class="muted" id="identity"></div></div>
  <div class="grid">
    <div class="card"><div class="muted">Temperatura</div><div class="value" id="temperature">--</div></div>
    <div class="card"><div class="muted">Umidade</div><div class="value" id="humidity">--</div></div>
    <div class="card"><div class="muted">Clientes conectados</div><div class="value" id="clients">--</div></div>
    <div class="card"><div class="muted">Gravacao AVI</div><div class="value" id="recording">--</div></div>
    <div class="card"><div class="muted">Espaco livre</div><div class="value" id="freeSpace">--</div></div>
  </div>
  <div class="card"><img id="stream" alt="Video ao vivo"><p>
    <button onclick="capturePhoto()">Capturar e salvar foto</button>
    <button onclick="startVideo()">Iniciar video</button>
    <button class="secondary" onclick="stopVideo()">Parar e fechar AVI</button>
    <a class="button secondary" href="/api/file?path=/dados.csv">Baixar CSV</a>
    <button class="secondary" onclick="loadFiles()">Atualizar arquivos</button></p>
    <div class="muted" id="videoFile">Nenhum video em gravacao</div>
  </div>
  <div class="card"><strong>Arquivos recentes</strong><div id="files" class="muted">Carregando...</div></div>
<script>
const host=location.hostname;
async function json(url){const r=await fetch(url,{cache:'no-store'});if(!r.ok)throw new Error(r.status);return r.json()}
async function init(){
  document.getElementById('stream').src=`http://${host}:81/stream`;
  try{await fetch(`/api/time?epoch=${Math.floor(Date.now()/1000)}`,{cache:'no-store'})}catch(e){}
  try{const d=await json('/api/identity');document.getElementById('identity').textContent=`Codigo: ${d.device_code} | ID: ${d.device_id} | Rede: ${d.ssid}`;document.getElementById('status').textContent='Dispositivo identificado'}catch(e){document.getElementById('status').textContent='Falha ao identificar o dispositivo'}
  refresh();loadFiles();setInterval(refresh,3000);
}
async function refresh(){try{const d=await json('/api/measurements');document.getElementById('temperature').textContent=d.temperature_c===null?'--':`${d.temperature_c.toFixed(1)} °C`;document.getElementById('humidity').textContent=d.humidity_pct===null?'--':`${d.humidity_pct.toFixed(1)} %`;document.getElementById('clients').textContent=d.connected_clients;document.getElementById('recording').textContent=d.video_recording?'GRAVANDO':'PARADO';document.getElementById('freeSpace').textContent=d.sd_free_mb===null?'--':`${(d.sd_free_mb/1024).toFixed(1)} GB`;document.getElementById('videoFile').textContent=d.current_video||'Nenhum video em gravacao'}catch(e){document.getElementById('status').textContent='Conexao interrompida'}}
async function capturePhoto(){try{const r=await fetch('/capture',{cache:'no-store'});if(!r.ok)throw new Error(r.status);const b=await r.blob();const u=URL.createObjectURL(b);const a=document.createElement('a');a.href=u;a.download=`captura_${Date.now()}.jpg`;a.click();URL.revokeObjectURL(u);loadFiles()}catch(e){alert('Falha ao capturar foto')}}
async function startVideo(){try{const r=await fetch('/api/video/start',{method:'POST'});if(!r.ok)throw new Error(await r.text());await refresh()}catch(e){alert(`Nao foi possivel iniciar: ${e.message}`)}}
async function stopVideo(){try{const r=await fetch('/api/video/stop',{method:'POST'});if(!r.ok)throw new Error(await r.text());await new Promise(resolve=>setTimeout(resolve,1500));await refresh();loadFiles()}catch(e){alert(`Nao foi possivel parar: ${e.message}`)}}
async function loadFiles(){try{const d=await json('/api/files');document.getElementById('files').innerHTML=d.files.length?d.files.map(f=>`<div><a href="/api/file?path=${encodeURIComponent(f.path)}">${f.path}</a> (${Math.round(f.size/1024)} KB)</div>`).join(''):'Nenhum arquivo encontrado'}catch(e){document.getElementById('files').textContent='Nao foi possivel listar os arquivos'}}
init();
</script></body></html>
)rawliteral";

String jsonEscape(const String &value) {
  String output;
  output.reserve(value.length() + 8);
  for (size_t i = 0; i < value.length(); ++i) {
    const char c = value[i];
    if (c == '\\' || c == '"') {
      output += '\\';
      output += c;
    } else if (c == '\n') {
      output += "\\n";
    } else if (static_cast<uint8_t>(c) >= 0x20) {
      output += c;
    }
  }
  return output;
}

void setCommonHeaders(httpd_req_t *req) {
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  httpd_resp_set_hdr(req, "Cache-Control", "no-store");
  httpd_resp_set_hdr(req, "X-Device-Code", DEVICE_TYPE_CODE);
  httpd_resp_set_hdr(req, "X-Device-Id", deviceId.c_str());
}

String isoTimestamp() {
  if (!timeSynchronized) {
    return String("uptime-") + String(millis());
  }
  time_t now = time(nullptr);
  struct tm timeInfo;
  gmtime_r(&now, &timeInfo);
  char buffer[25];
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", &timeInfo);
  return String(buffer);
}

String photoPath() {
  if (!timeSynchronized) {
    return String(PHOTOS_DIR) + "/uptime_" + String(millis()) + ".jpg";
  }
  time_t now = time(nullptr);
  struct tm timeInfo;
  gmtime_r(&now, &timeInfo);
  char buffer[48];
  strftime(buffer, sizeof(buffer), "/fotos/%Y%m%d_%H%M%S", &timeInfo);
  return String(buffer) + "_" + String(millis()) + ".jpg";
}

String videoPath() {
  if (!timeSynchronized) {
    return String(VIDEOS_DIR) + "/uptime_" + String(millis()) + ".avi";
  }
  time_t now = time(nullptr);
  struct tm timeInfo;
  gmtime_r(&now, &timeInfo);
  char buffer[64];
  strftime(buffer, sizeof(buffer), "/videos/%Y%m%d_%H%M%S", &timeInfo);
  return String(buffer) + "_" + String(millis()) + ".avi";
}

uint64_t sdFreeBytes() {
  if (!sdReady) return 0;
  const uint64_t total = SD_MMC.totalBytes();
  const uint64_t used = SD_MMC.usedBytes();
  return total > used ? total - used : 0;
}

uint64_t storageReserveBytes() {
  if (!sdReady) return STORAGE_MIN_FREE_BYTES;
  const uint64_t tenPercent = SD_MMC.totalBytes() / 10ULL;
  return tenPercent < STORAGE_MIN_FREE_BYTES ? tenPercent : STORAGE_MIN_FREE_BYTES;
}

void considerOldestFile(const char *directoryPath, String &oldestPath,
                        time_t &oldestTime) {
  File directory = SD_MMC.open(directoryPath);
  if (!directory || !directory.isDirectory()) return;

  File file = directory.openNextFile();
  while (file) {
    if (!file.isDirectory()) {
      const String path = file.path();
      if (path != currentVideoPath && !path.endsWith(".idx")) {
        const time_t modified = file.getLastWrite();
        if (oldestPath.length() == 0 || modified < oldestTime) {
          oldestPath = path;
          oldestTime = modified;
        }
      }
    }
    file.close();
    file = directory.openNextFile();
  }
  directory.close();
}

// Deve ser chamada com sdMutex adquirido. Apaga somente fotos e videos,
// nunca o CSV, e sempre comeca pelo arquivo mais antigo.
bool cleanupStorageLocked(uint64_t targetFreeBytes) {
  while (sdFreeBytes() < targetFreeBytes) {
    String oldestPath;
    time_t oldestTime = 0;
    considerOldestFile(VIDEOS_DIR, oldestPath, oldestTime);
    considerOldestFile(PHOTOS_DIR, oldestPath, oldestTime);
    if (oldestPath.length() == 0) {
      return false;
    }
    Serial.printf("Armazenamento: apagando arquivo antigo %s\n", oldestPath.c_str());
    if (!SD_MMC.remove(oldestPath)) {
      return false;
    }
  }
  return true;
}

void buildIdentity() {
  uint8_t mac[6];
  esp_read_mac(mac, ESP_MAC_WIFI_SOFTAP);
  char idBuffer[18];
  snprintf(idBuffer, sizeof(idBuffer), "%02X:%02X:%02X:%02X:%02X:%02X",
           mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
  deviceId = idBuffer;
  char ssidBuffer[24];
  snprintf(ssidBuffer, sizeof(ssidBuffer), "ESP32CAM-%02X%02X%02X", mac[3], mac[4], mac[5]);
  apSsid = ssidBuffer;
}

bool initCamera() {
  camera_config_t config = {};
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = CAM_PIN_D0;
  config.pin_d1 = CAM_PIN_D1;
  config.pin_d2 = CAM_PIN_D2;
  config.pin_d3 = CAM_PIN_D3;
  config.pin_d4 = CAM_PIN_D4;
  config.pin_d5 = CAM_PIN_D5;
  config.pin_d6 = CAM_PIN_D6;
  config.pin_d7 = CAM_PIN_D7;
  config.pin_xclk = CAM_PIN_XCLK;
  config.pin_pclk = CAM_PIN_PCLK;
  config.pin_vsync = CAM_PIN_VSYNC;
  config.pin_href = CAM_PIN_HREF;
  config.pin_sccb_sda = CAM_PIN_SIOD;
  config.pin_sccb_scl = CAM_PIN_SIOC;
  config.pin_pwdn = CAM_PIN_PWDN;
  config.pin_reset = CAM_PIN_RESET;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = CAMERA_FRAME_SIZE;
  config.jpeg_quality = CAMERA_JPEG_QUALITY;
  config.fb_count = psramFound() ? 2 : 1;
  config.fb_location = psramFound() ? CAMERA_FB_IN_PSRAM : CAMERA_FB_IN_DRAM;
  config.grab_mode = CAMERA_GRAB_LATEST;

  const esp_err_t error = esp_camera_init(&config);
  if (error != ESP_OK) {
    Serial.printf("ERRO: camera nao iniciou (0x%X). Confira o pinout.\n", error);
    return false;
  }

  sensor_t *sensor = esp_camera_sensor_get();
  if (sensor != nullptr) {
    // Algumas montagens da OV5640 ficam invertidas. Altere para 1 se necessario.
    sensor->set_vflip(sensor, 0);
    sensor->set_hmirror(sensor, 0);
    sensor->set_exposure_ctrl(sensor, 1); // Exposição automática
    sensor->set_gain_ctrl(sensor, 1);     // Ganho automático
    sensor->set_whitebal(sensor, 1);      // Balanço de branco
    sensor->set_wb_mode(sensor, 0);       // Cores em modo automático
    sensor->set_ae_level(sensor, 1);      // Alvo de exposição mais claro
  }
  return true;
}

bool initSdCard() {
  if (!SD_MMC.setPins(SD_PIN_CLK, SD_PIN_CMD, SD_PIN_D0)) {
    Serial.println("ERRO: nao foi possivel configurar os pinos SD_MMC.");
    return false;
  }
  if (!SD_MMC.begin("/sdcard", true)) {
    Serial.println("ERRO: cartao microSD nao montado.");
    return false;
  }
  if (SD_MMC.cardType() == CARD_NONE) {
    Serial.println("ERRO: nenhum cartao microSD detectado.");
    return false;
  }
  if (!SD_MMC.exists(PHOTOS_DIR)) {
    SD_MMC.mkdir(PHOTOS_DIR);
  }
  if (!SD_MMC.exists(VIDEOS_DIR)) {
    SD_MMC.mkdir(VIDEOS_DIR);
  }
  if (!SD_MMC.exists(DATA_FILE)) {
    File file = SD_MMC.open(DATA_FILE, FILE_WRITE);
    if (file) {
      file.println("device_code,device_id,timestamp_utc,uptime_ms,temperature_c,humidity_pct");
      file.close();
    }
  }
  Serial.printf("microSD: %llu MB\n", SD_MMC.cardSize() / (1024ULL * 1024ULL));
  return true;
}

bool startVideoSegment() {
  if (!cameraReady || !sdReady || videoRecording) return false;

  camera_fb_t *frame = esp_camera_fb_get();
  if (frame == nullptr) {
    Serial.println("ERRO: camera nao forneceu o primeiro frame do AVI.");
    return false;
  }

  if (xSemaphoreTake(sdMutex, pdMS_TO_TICKS(10000)) != pdTRUE) {
    esp_camera_fb_return(frame);
    return false;
  }

  const uint64_t targetFree = storageReserveBytes() + STORAGE_CLEANUP_TARGET_EXTRA_BYTES;
  const bool hasSpace = cleanupStorageLocked(targetFree);
  currentVideoPath = videoPath();
  const String indexPath = currentVideoPath + ".idx";
  const bool began = hasSpace &&
                     aviRecorder.begin(SD_MMC, currentVideoPath, indexPath,
                                       frame->width, frame->height,
                                       VIDEO_TARGET_FPS);
  bool ok = began;
  if (ok) {
    ok = aviRecorder.addFrame(frame->buf, frame->len);
  }
  if (began && !ok) {
    aviRecorder.abortAndRemove();
  }
  if (!ok) {
    currentVideoPath = "";
  }
  xSemaphoreGive(sdMutex);
  esp_camera_fb_return(frame);

  videoRecording = ok;
  lastVideoFrameAt = millis();
  lastVideoSpaceCheckAt = millis();
  if (ok) {
    Serial.printf("Video iniciado: %s\n", currentVideoPath.c_str());
  } else {
    Serial.println("ERRO: nao foi possivel iniciar o video AVI.");
  }
  return ok;
}

bool finishVideoSegment() {
  if (!videoRecording) return true;
  if (xSemaphoreTake(sdMutex, pdMS_TO_TICKS(15000)) != pdTRUE) return false;

  const uint32_t frames = aviRecorder.frameCount();
  const uint32_t fps = aviRecorder.playbackFps();
  const String finishedPath = currentVideoPath;
  const bool ok = aviRecorder.finish();
  currentVideoPath = "";
  xSemaphoreGive(sdMutex);

  videoRecording = false;
  Serial.printf("Video finalizado: %s | %lu frames | %lu FPS | %s\n",
                finishedPath.c_str(), static_cast<unsigned long>(frames),
                static_cast<unsigned long>(fps), ok ? "OK" : "ERRO");
  return ok;
}

void processVideoRecording(uint32_t now) {
  if (!videoRecordingRequested) {
    if (videoRecording) finishVideoSegment();
    return;
  }

  if (!videoRecording) {
    if (!startVideoSegment()) {
      videoRecordingRequested = false;
    }
    return;
  }

  const bool segmentFinished =
      aviRecorder.elapsedMs() >= VIDEO_SEGMENT_DURATION_MS ||
      aviRecorder.fileBytes() >= VIDEO_SEGMENT_MAX_BYTES;

  bool lowSpace = false;
  if (now - lastVideoSpaceCheckAt >= 10000) {
    lastVideoSpaceCheckAt = now;
    lowSpace = sdFreeBytes() <= storageReserveBytes();
  }

  if (segmentFinished || lowSpace) {
    // videoRecordingRequested permanece true: o loop abre o proximo segmento.
    finishVideoSegment();
    return;
  }

  if (now - lastVideoFrameAt < VIDEO_FRAME_INTERVAL_MS) return;
  lastVideoFrameAt = now;

  camera_fb_t *frame = esp_camera_fb_get();
  if (frame == nullptr) return;

  bool ok = false;
  if (xSemaphoreTake(sdMutex, pdMS_TO_TICKS(5000)) == pdTRUE) {
    ok = aviRecorder.addFrame(frame->buf, frame->len);
    if (ok && aviRecorder.frameCount() % AVI_CHECKPOINT_EVERY_FRAMES == 0) {
      ok = aviRecorder.checkpoint();
    }
    if (!ok) {
      aviRecorder.abortAndRemove();
    }
    xSemaphoreGive(sdMutex);
  }
  esp_camera_fb_return(frame);

  if (!ok) {
    Serial.println("ERRO: gravacao AVI interrompida e segmento incompleto removido.");
    videoRecording = false;
    videoRecordingRequested = false;
    currentVideoPath = "";
  }
}

void maintainStorage() {
  if (!sdReady || videoRecording) return;
  if (xSemaphoreTake(sdMutex, pdMS_TO_TICKS(5000)) != pdTRUE) return;
  cleanupStorageLocked(storageReserveBytes());
  xSemaphoreGive(sdMutex);
}

void readAndStoreSensor() {
  const float humidity = dht.readHumidity();
  const float temperature = dht.readTemperature();
  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("AVISO: leitura invalida do DHT22.");
    return;
  }

  lastHumidityPct = humidity;
  lastTemperatureC = temperature;
  Serial.printf("DHT22: %.1f C | %.1f %%\n", temperature, humidity);

  if (!sdReady || xSemaphoreTake(sdMutex, pdMS_TO_TICKS(2000)) != pdTRUE) {
    return;
  }
  File file = SD_MMC.open(DATA_FILE, FILE_APPEND);
  if (file) {
    file.printf("%s,%s,%s,%lu,%.1f,%.1f\n", DEVICE_TYPE_CODE, deviceId.c_str(),
                isoTimestamp().c_str(), static_cast<unsigned long>(millis()), temperature, humidity);
    file.close();
  }
  xSemaphoreGive(sdMutex);
}

bool saveFrameToSd(const camera_fb_t *frame, String &savedPath) {
  if (!sdReady || frame == nullptr || xSemaphoreTake(sdMutex, pdMS_TO_TICKS(3000)) != pdTRUE) {
    return false;
  }
  savedPath = photoPath();
  File file = SD_MMC.open(savedPath, FILE_WRITE);
  const bool ok = file && file.write(frame->buf, frame->len) == frame->len;
  if (file) {
    file.close();
  }
  xSemaphoreGive(sdMutex);
  if (ok) {
    Serial.printf("Foto salva: %s (%u bytes)\n", savedPath.c_str(),
                  static_cast<unsigned int>(frame->len));
  }
  return ok;
}

void captureScheduledPhoto() {
  if (!cameraReady || !sdReady) {
    return;
  }
  camera_fb_t *frame = esp_camera_fb_get();
  if (frame == nullptr) {
    Serial.println("AVISO: camera nao forneceu frame para foto periodica.");
    return;
  }
  String path;
  saveFrameToSd(frame, path);
  esp_camera_fb_return(frame);
}

void announceDevice() {
  IPAddress broadcast(192, 168, 4, 255);
  String message = "{\"type\":\"esp32_announce\",\"device_code\":\"";
  message += DEVICE_TYPE_CODE;
  message += "\",\"device_id\":\"" + jsonEscape(deviceId);
  message += "\",\"ssid\":\"" + jsonEscape(apSsid);
  message += "\",\"ip\":\"192.168.4.1\",\"http_port\":80,\"stream_port\":81";
  if (!isnan(lastTemperatureC)) {
    message += ",\"temperature_c\":" + String(lastTemperatureC, 1);
    message += ",\"humidity_pct\":" + String(lastHumidityPct, 1);
  }
  message += ",\"video_recording\":" + String(videoRecording ? "true" : "false");
  message += "}";
  announceUdp.beginPacket(broadcast, ANNOUNCE_UDP_PORT);
  announceUdp.write(reinterpret_cast<const uint8_t *>(message.c_str()), message.length());
  announceUdp.endPacket();
}

esp_err_t indexHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  httpd_resp_set_type(req, "text/html; charset=utf-8");
  return httpd_resp_send(req, INDEX_HTML, HTTPD_RESP_USE_STRLEN);
}

esp_err_t identityHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  httpd_resp_set_type(req, "application/json");
  String body = "{\"device_code\":\"" + String(DEVICE_TYPE_CODE) +
                "\",\"device_id\":\"" + jsonEscape(deviceId) +
                "\",\"ssid\":\"" + jsonEscape(apSsid) +
                "\",\"ip\":\"192.168.4.1\",\"announce_udp_port\":" +
                String(ANNOUNCE_UDP_PORT) + "}";
  return httpd_resp_send(req, body.c_str(), body.length());
}

esp_err_t measurementsHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  httpd_resp_set_type(req, "application/json");
  String body = "{\"device_code\":\"" + String(DEVICE_TYPE_CODE) +
                "\",\"device_id\":\"" + jsonEscape(deviceId) + "\",\"temperature_c\":";
  body += isnan(lastTemperatureC) ? "null" : String(lastTemperatureC, 1);
  body += ",\"humidity_pct\":";
  body += isnan(lastHumidityPct) ? "null" : String(lastHumidityPct, 1);
  body += ",\"timestamp_utc\":\"" + isoTimestamp() + "\",\"uptime_ms\":" + String(millis());
  body += ",\"connected_clients\":" + String(WiFi.softAPgetStationNum());
  body += ",\"camera_ready\":" + String(cameraReady ? "true" : "false");
  body += ",\"sd_ready\":" + String(sdReady ? "true" : "false");
  body += ",\"video_recording\":" + String(videoRecording ? "true" : "false");
  String pathSnapshot;
  uint64_t freeBytesSnapshot = 0;
  if (sdReady && xSemaphoreTake(sdMutex, pdMS_TO_TICKS(500)) == pdTRUE) {
    pathSnapshot = currentVideoPath;
    freeBytesSnapshot = sdFreeBytes();
    xSemaphoreGive(sdMutex);
  }
  body += ",\"current_video\":\"" + jsonEscape(pathSnapshot) + "\"";
  body += ",\"sd_free_mb\":";
  body += sdReady ? String(freeBytesSnapshot / (1024ULL * 1024ULL)) : "null";
  body += "}";
  return httpd_resp_send(req, body.c_str(), body.length());
}

// O enum de erros do ESP-IDF nao inclui HTTP 503. Defina o status
// explicitamente e envie a mensagem pelas funcoes publicas do servidor.
esp_err_t sendServiceUnavailable(httpd_req_t *req, const char *message) {
  esp_err_t result = httpd_resp_set_status(req, "503 Service Unavailable");
  if (result != ESP_OK) {
    return result;
  }
  result = httpd_resp_set_type(req, "text/plain; charset=utf-8");
  if (result != ESP_OK) {
    return result;
  }
  return httpd_resp_send(req, message, HTTPD_RESP_USE_STRLEN);
}

esp_err_t startVideoHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  httpd_resp_set_type(req, "application/json");
  if (!cameraReady || !sdReady) {
    return sendServiceUnavailable(req, "Camera ou microSD indisponivel");
  }
  videoRecordingRequested = true;
  return httpd_resp_sendstr(req, "{\"accepted\":true,\"requested_state\":\"recording\"}");
}

esp_err_t stopVideoHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  httpd_resp_set_type(req, "application/json");
  videoRecordingRequested = false;
  return httpd_resp_sendstr(req, "{\"accepted\":true,\"requested_state\":\"stopped\"}");
}

esp_err_t timeHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  char query[96] = {};
  char epochValue[24] = {};
  if (httpd_req_get_url_query_str(req, query, sizeof(query)) != ESP_OK ||
      httpd_query_key_value(query, "epoch", epochValue, sizeof(epochValue)) != ESP_OK) {
    return httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Parametro epoch ausente");
  }
  const time_t epoch = static_cast<time_t>(strtoll(epochValue, nullptr, 10));
  if (epoch < 1700000000) {
    return httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Epoch invalido");
  }
  timeval tv;
  tv.tv_sec = epoch;
  tv.tv_usec = 0;
  settimeofday(&tv, nullptr);
  timeSynchronized = true;
  return httpd_resp_sendstr(req, "{\"ok\":true}");
}

esp_err_t captureHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  if (!cameraReady) {
    return sendServiceUnavailable(req, "Camera indisponivel");
  }
  camera_fb_t *frame = esp_camera_fb_get();
  if (frame == nullptr) {
    return httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Falha na captura");
  }
  String path;
  saveFrameToSd(frame, path);
  httpd_resp_set_type(req, "image/jpeg");
  httpd_resp_set_hdr(req, "Content-Disposition", "inline; filename=captura.jpg");
  const esp_err_t result = httpd_resp_send(req, reinterpret_cast<const char *>(frame->buf), frame->len);
  esp_camera_fb_return(frame);
  return result;
}

esp_err_t streamHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  if (!cameraReady || WiFi.softAPgetStationNum() == 0) {
    return sendServiceUnavailable(req, "Stream indisponivel");
  }
  static const char *contentType = "multipart/x-mixed-replace;boundary=frame";
  static const char *boundary = "\r\n--frame\r\n";
  char header[96];
  httpd_resp_set_type(req, contentType);
  while (WiFi.softAPgetStationNum() > 0) {
    camera_fb_t *frame = esp_camera_fb_get();
    if (frame == nullptr) {
      break;
    }
    const int headerLength = snprintf(header, sizeof(header),
                                      "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n",
                                      static_cast<unsigned int>(frame->len));
    esp_err_t result = httpd_resp_send_chunk(req, boundary, strlen(boundary));
    if (result == ESP_OK) {
      result = httpd_resp_send_chunk(req, header, headerLength);
    }
    if (result == ESP_OK) {
      result = httpd_resp_send_chunk(req, reinterpret_cast<const char *>(frame->buf), frame->len);
    }
    esp_camera_fb_return(frame);
    if (result != ESP_OK) {
      break;
    }
    vTaskDelay(pdMS_TO_TICKS(60));
  }
  return ESP_OK;
}

esp_err_t filesHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  httpd_resp_set_type(req, "application/json");
  if (!sdReady || xSemaphoreTake(sdMutex, pdMS_TO_TICKS(2000)) != pdTRUE) {
    return httpd_resp_send(req, "{\"files\":[]}", HTTPD_RESP_USE_STRLEN);
  }
  String body = "{\"files\":[";
  bool first = true;
  if (SD_MMC.exists(DATA_FILE)) {
    File data = SD_MMC.open(DATA_FILE);
    body += "{\"path\":\"/dados.csv\",\"size\":" + String(data.size()) + "}";
    first = false;
    data.close();
  }
  const char *directories[] = {VIDEOS_DIR, PHOTOS_DIR};
  uint16_t count = 0;
  for (const char *directoryPath : directories) {
    File directory = SD_MMC.open(directoryPath);
    if (!directory || !directory.isDirectory()) continue;
    File file = directory.openNextFile();
    while (file && count < 150) {
      if (!file.isDirectory()) {
        String path = file.path();
        if (!path.endsWith(".idx")) {
          if (!first) body += ',';
          body += "{\"path\":\"" + jsonEscape(path) + "\",\"size\":" + String(file.size()) + "}";
          first = false;
          ++count;
        }
      }
      file.close();
      file = directory.openNextFile();
    }
    directory.close();
  }
  body += "]}";
  xSemaphoreGive(sdMutex);
  return httpd_resp_send(req, body.c_str(), body.length());
}

String urlDecode(const String &input) {
  String output;
  output.reserve(input.length());
  for (size_t i = 0; i < input.length(); ++i) {
    if (input[i] == '%' && i + 2 < input.length()) {
      char hex[3] = {input[i + 1], input[i + 2], 0};
      output += static_cast<char>(strtol(hex, nullptr, 16));
      i += 2;
    } else if (input[i] == '+') {
      output += ' ';
    } else {
      output += input[i];
    }
  }
  return output;
}

esp_err_t fileHandler(httpd_req_t *req) {
  setCommonHeaders(req);
  char query[256] = {};
  char encodedPath[192] = {};
  if (httpd_req_get_url_query_str(req, query, sizeof(query)) != ESP_OK ||
      httpd_query_key_value(query, "path", encodedPath, sizeof(encodedPath)) != ESP_OK) {
    return httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Caminho ausente");
  }
  const String path = urlDecode(encodedPath);
  if (!sdReady || !path.startsWith("/") || path.indexOf("..") >= 0) {
    return httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Caminho invalido");
  }
  if (videoRecording && path.endsWith(".avi")) {
    return sendServiceUnavailable(req, "Pare a gravacao antes de baixar videos");
  }
  if (xSemaphoreTake(sdMutex, pdMS_TO_TICKS(3000)) != pdTRUE) {
    return sendServiceUnavailable(req, "SD ocupado");
  }
  File file = SD_MMC.open(path);
  if (!file || file.isDirectory()) {
    if (file) file.close();
    xSemaphoreGive(sdMutex);
    return httpd_resp_send_err(req, HTTPD_404_NOT_FOUND, "Arquivo nao encontrado");
  }
  if (path.endsWith(".csv")) {
    httpd_resp_set_type(req, "text/csv");
  } else if (path.endsWith(".avi")) {
    httpd_resp_set_type(req, "video/x-msvideo");
  } else {
    httpd_resp_set_type(req, "image/jpeg");
  }
  String disposition = "attachment; filename=\"" + path.substring(path.lastIndexOf('/') + 1) + "\"";
  httpd_resp_set_hdr(req, "Content-Disposition", disposition.c_str());
  uint8_t buffer[1024];
  esp_err_t result = ESP_OK;
  while (file.available() && result == ESP_OK) {
    const size_t readBytes = file.read(buffer, sizeof(buffer));
    result = httpd_resp_send_chunk(req, reinterpret_cast<const char *>(buffer), readBytes);
  }
  file.close();
  xSemaphoreGive(sdMutex);
  if (result == ESP_OK) {
    httpd_resp_send_chunk(req, nullptr, 0);
  }
  return result;
}

void registerUri(httpd_handle_t server, const char *uri, httpd_method_t method,
                 esp_err_t (*handler)(httpd_req_t *)) {
  httpd_uri_t route = {};
  route.uri = uri;
  route.method = method;
  route.handler = handler;
  route.user_ctx = nullptr;
  httpd_register_uri_handler(server, &route);
}

bool startWebServers() {
  httpd_config_t controlConfig = HTTPD_DEFAULT_CONFIG();
  controlConfig.server_port = 80;
  controlConfig.ctrl_port = 32768;
  controlConfig.max_uri_handlers = 10;
  controlConfig.stack_size = 8192;
  if (httpd_start(&controlServer, &controlConfig) != ESP_OK) {
    return false;
  }
  registerUri(controlServer, "/", HTTP_GET, indexHandler);
  registerUri(controlServer, "/api/identity", HTTP_GET, identityHandler);
  registerUri(controlServer, "/api/measurements", HTTP_GET, measurementsHandler);
  registerUri(controlServer, "/api/time", HTTP_GET, timeHandler);
  registerUri(controlServer, "/api/files", HTTP_GET, filesHandler);
  registerUri(controlServer, "/api/file", HTTP_GET, fileHandler);
  registerUri(controlServer, "/api/video/start", HTTP_POST, startVideoHandler);
  registerUri(controlServer, "/api/video/stop", HTTP_POST, stopVideoHandler);
  registerUri(controlServer, "/capture", HTTP_GET, captureHandler);

  httpd_config_t streamConfig = HTTPD_DEFAULT_CONFIG();
  streamConfig.server_port = 81;
  streamConfig.ctrl_port = 32769;
  streamConfig.stack_size = 8192;
  if (httpd_start(&streamServer, &streamConfig) != ESP_OK) {
    return false;
  }
  registerUri(streamServer, "/stream", HTTP_GET, streamHandler);
  return true;
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\nInicializando ESP32-S3-CAM...");

  if (strlen(AP_PASSWORD) < 8) {
    Serial.println("ERRO FATAL: AP_PASSWORD precisa ter pelo menos 8 caracteres.");
    while (true) delay(1000);
  }

  sdMutex = xSemaphoreCreateMutex();
  dht.begin();
  buildIdentity();
  cameraReady = initCamera();
  sdReady = initSdCard();

  IPAddress localIp(192, 168, 4, 1);
  IPAddress gateway(192, 168, 4, 1);
  IPAddress subnet(255, 255, 255, 0);
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(localIp, gateway, subnet);
  if (!WiFi.softAP(apSsid.c_str(), AP_PASSWORD, AP_CHANNEL, false, AP_MAX_CLIENTS)) {
    Serial.println("ERRO FATAL: nao foi possivel criar a rede Wi-Fi.");
    while (true) delay(1000);
  }
  WiFi.setSleep(false);
  announceUdp.begin(ANNOUNCE_UDP_PORT);

  if (!startWebServers()) {
    Serial.println("ERRO: servidor web nao iniciou corretamente.");
  }

  Serial.println("--------------------------------------------");
  Serial.printf("Rede Wi-Fi: %s\n", apSsid.c_str());
  Serial.printf("Senha: %s\n", AP_PASSWORD);
  Serial.printf("Pagina: http://%s\n", WiFi.softAPIP().toString().c_str());
  Serial.printf("Codigo: %s\n", DEVICE_TYPE_CODE);
  Serial.printf("ID unico: %s\n", deviceId.c_str());
  Serial.println("--------------------------------------------");

  // Primeira leitura ocorre logo apos a inicializacao do DHT22.
  delay(2000);
  readAndStoreSensor();
  lastSensorAt = millis();
  lastPhotoAt = millis();
  lastStorageMaintenanceAt = millis();
}

void loop() {
  const uint32_t now = millis();
  const uint8_t stations = WiFi.softAPgetStationNum();

  if (stations != previousStationCount) {
    Serial.printf("Clientes Wi-Fi conectados: %u\n", stations);
    previousStationCount = stations;
    if (stations > 0) {
      announceDevice();
      lastAnnounceAt = now;
    }
  }

  if (now - lastSensorAt >= SENSOR_INTERVAL_MS) {
    lastSensorAt = now;
    readAndStoreSensor();
  }

  processVideoRecording(now);

  if (now - lastPhotoAt >= PHOTO_INTERVAL_MS) {
    lastPhotoAt = now;
    captureScheduledPhoto();
  }

  if (now - lastStorageMaintenanceAt >= 60UL * 1000UL) {
    lastStorageMaintenanceAt = now;
    maintainStorage();
  }

  // Nenhum dado de rede e transmitido quando nao ha cliente no ponto de acesso.
  if (stations > 0 && now - lastAnnounceAt >= ANNOUNCE_INTERVAL_MS) {
    lastAnnounceAt = now;
    announceDevice();
  }

  delay(20);
}
