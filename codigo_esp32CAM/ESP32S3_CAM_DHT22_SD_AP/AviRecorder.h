#pragma once

#include <Arduino.h>
#include <FS.h>

// Gravador AVI simples com um stream MJPEG (cada frame e um JPEG da camera).
// O indice e escrito primeiro em um arquivo temporario para nao consumir RAM.
class AviRecorder {
 public:
  bool begin(FS &fileSystem, const String &aviPath, const String &indexPath,
             uint16_t width, uint16_t height, uint16_t requestedFps);
  bool addFrame(const uint8_t *jpeg, size_t length);
  bool checkpoint();
  bool finish();
  void abortAndRemove();

  bool active() const { return active_; }
  uint32_t frameCount() const { return frameCount_; }
  uint32_t elapsedMs() const;
  uint32_t playbackFps() const;
  uint64_t fileBytes() const { return 268ULL + videoDataBytes_; }
  const String &path() const { return aviPath_; }

 private:
  bool writeInitialHeader();
  bool rewriteHeader(bool hasIndex);
  bool appendIndex();
  bool writeFourCC(File &file, const char value[4]);
  bool writeU16(File &file, uint16_t value);
  bool writeU32(File &file, uint32_t value);
  bool writeZeros(File &file, size_t count);
  void closeFiles();

  FS *fs_ = nullptr;
  File aviFile_;
  File indexFile_;
  String aviPath_;
  String indexPath_;
  uint16_t width_ = 0;
  uint16_t height_ = 0;
  uint16_t requestedFps_ = 0;
  uint32_t startedAtMs_ = 0;
  uint32_t stoppedAtMs_ = 0;
  uint32_t frameCount_ = 0;
  uint32_t maxFrameBytes_ = 0;
  uint64_t videoDataBytes_ = 0;
  bool active_ = false;
};

