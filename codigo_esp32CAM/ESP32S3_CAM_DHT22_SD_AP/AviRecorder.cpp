#include "AviRecorder.h"

namespace {
constexpr uint32_t AVI_HEADER_BYTES = 268;
constexpr uint32_t AVI_HAS_INDEX = 0x10;
constexpr uint32_t INDEX_ENTRY_BYTES = 16;
}

bool AviRecorder::writeFourCC(File &file, const char value[4]) {
  return file.write(reinterpret_cast<const uint8_t *>(value), 4) == 4;
}

bool AviRecorder::writeU16(File &file, uint16_t value) {
  uint8_t bytes[2] = {
      static_cast<uint8_t>(value & 0xFF),
      static_cast<uint8_t>((value >> 8) & 0xFF),
  };
  return file.write(bytes, sizeof(bytes)) == sizeof(bytes);
}

bool AviRecorder::writeU32(File &file, uint32_t value) {
  uint8_t bytes[4] = {
      static_cast<uint8_t>(value & 0xFF),
      static_cast<uint8_t>((value >> 8) & 0xFF),
      static_cast<uint8_t>((value >> 16) & 0xFF),
      static_cast<uint8_t>((value >> 24) & 0xFF),
  };
  return file.write(bytes, sizeof(bytes)) == sizeof(bytes);
}

bool AviRecorder::writeZeros(File &file, size_t count) {
  static const uint8_t zeros[16] = {};
  while (count > 0) {
    const size_t amount = count > sizeof(zeros) ? sizeof(zeros) : count;
    if (file.write(zeros, amount) != amount) {
      return false;
    }
    count -= amount;
  }
  return true;
}

bool AviRecorder::begin(FS &fileSystem, const String &aviPath,
                        const String &indexPath, uint16_t width,
                        uint16_t height, uint16_t requestedFps) {
  if (active_ || width == 0 || height == 0 || requestedFps == 0) {
    return false;
  }

  fs_ = &fileSystem;
  aviPath_ = aviPath;
  indexPath_ = indexPath;
  width_ = width;
  height_ = height;
  requestedFps_ = requestedFps;
  frameCount_ = 0;
  maxFrameBytes_ = 0;
  videoDataBytes_ = 0;
  startedAtMs_ = millis();
  stoppedAtMs_ = 0;

  aviFile_ = fs_->open(aviPath_, FILE_WRITE);
  indexFile_ = fs_->open(indexPath_, FILE_WRITE);
  if (!aviFile_ || !indexFile_ || !writeInitialHeader()) {
    abortAndRemove();
    return false;
  }

  active_ = true;
  return true;
}

bool AviRecorder::writeInitialHeader() {
  if (!aviFile_.seek(0)) {
    return false;
  }

  // RIFF AVI
  bool ok = writeFourCC(aviFile_, "RIFF") &&
            writeU32(aviFile_, AVI_HEADER_BYTES - 8) &&
            writeFourCC(aviFile_, "AVI ");

  // LIST hdrl
  ok = ok && writeFourCC(aviFile_, "LIST") && writeU32(aviFile_, 192) &&
       writeFourCC(aviFile_, "hdrl");

  // avih (56 bytes de dados)
  const uint32_t fps = requestedFps_;
  ok = ok && writeFourCC(aviFile_, "avih") && writeU32(aviFile_, 56) &&
       writeU32(aviFile_, 1000000UL / fps) &&
       writeU32(aviFile_, width_ * height_ * 3UL * fps) &&
       writeU32(aviFile_, 0) && writeU32(aviFile_, 0) &&
       writeU32(aviFile_, 0) && writeU32(aviFile_, 0) &&
       writeU32(aviFile_, 1) && writeU32(aviFile_, width_ * height_ * 3UL) &&
       writeU32(aviFile_, width_) && writeU32(aviFile_, height_) &&
       writeZeros(aviFile_, 16);

  // LIST strl
  ok = ok && writeFourCC(aviFile_, "LIST") && writeU32(aviFile_, 116) &&
       writeFourCC(aviFile_, "strl");

  // strh (56 bytes de dados)
  ok = ok && writeFourCC(aviFile_, "strh") && writeU32(aviFile_, 56) &&
       writeFourCC(aviFile_, "vids") && writeFourCC(aviFile_, "MJPG") &&
       writeU32(aviFile_, 0) && writeU16(aviFile_, 0) && writeU16(aviFile_, 0) &&
       writeU32(aviFile_, 0) && writeU32(aviFile_, 1) && writeU32(aviFile_, fps) &&
       writeU32(aviFile_, 0) && writeU32(aviFile_, 0) &&
       writeU32(aviFile_, width_ * height_ * 3UL) && writeU32(aviFile_, 0xFFFFFFFF) &&
       writeU32(aviFile_, 0) && writeU16(aviFile_, 0) && writeU16(aviFile_, 0) &&
       writeU16(aviFile_, width_) && writeU16(aviFile_, height_);

  // strf / BITMAPINFOHEADER (40 bytes de dados)
  ok = ok && writeFourCC(aviFile_, "strf") && writeU32(aviFile_, 40) &&
       writeU32(aviFile_, 40) && writeU32(aviFile_, width_) &&
       writeU32(aviFile_, height_) && writeU16(aviFile_, 1) &&
       writeU16(aviFile_, 24) && writeFourCC(aviFile_, "MJPG") &&
       writeU32(aviFile_, width_ * height_ * 3UL) && writeU32(aviFile_, 0) &&
       writeU32(aviFile_, 0) && writeU32(aviFile_, 0) && writeU32(aviFile_, 0);

  // JUNK deixa o inicio dos frames alinhado em 256/268 bytes.
  ok = ok && writeFourCC(aviFile_, "JUNK") && writeU32(aviFile_, 36) &&
       writeZeros(aviFile_, 36);

  // LIST movi. O primeiro chunk comeca no byte 268.
  ok = ok && writeFourCC(aviFile_, "LIST") && writeU32(aviFile_, 4) &&
       writeFourCC(aviFile_, "movi");
  return ok && aviFile_.position() == AVI_HEADER_BYTES;
}

bool AviRecorder::addFrame(const uint8_t *jpeg, size_t length) {
  if (!active_ || jpeg == nullptr || length == 0 || length > UINT32_MAX) {
    return false;
  }

  const uint32_t frameLength = static_cast<uint32_t>(length);
  const uint32_t padding = (4 - (frameLength & 3)) & 3;
  const uint32_t chunkOffset = 4 + static_cast<uint32_t>(videoDataBytes_);

  if (!writeFourCC(aviFile_, "00dc") || !writeU32(aviFile_, frameLength) ||
      aviFile_.write(jpeg, frameLength) != frameLength ||
      !writeZeros(aviFile_, padding)) {
    return false;
  }

  // Entrada idx1: id, keyframe, offset relativo a 'movi', tamanho.
  if (!writeFourCC(indexFile_, "00dc") || !writeU32(indexFile_, 0x10) ||
      !writeU32(indexFile_, chunkOffset) || !writeU32(indexFile_, frameLength)) {
    return false;
  }

  videoDataBytes_ += 8ULL + frameLength + padding;
  ++frameCount_;
  if (frameLength > maxFrameBytes_) {
    maxFrameBytes_ = frameLength;
  }
  return true;
}

uint32_t AviRecorder::elapsedMs() const {
  if (startedAtMs_ == 0) {
    return 0;
  }
  const uint32_t end = stoppedAtMs_ == 0 ? millis() : stoppedAtMs_;
  return end - startedAtMs_;
}

uint32_t AviRecorder::playbackFps() const {
  const uint32_t elapsed = elapsedMs();
  if (elapsed == 0 || frameCount_ == 0) {
    return requestedFps_ == 0 ? 1 : requestedFps_;
  }
  uint32_t fps = static_cast<uint32_t>((frameCount_ * 1000ULL + elapsed / 2) / elapsed);
  if (fps < 1) fps = 1;
  if (fps > 30) fps = 30;
  return fps;
}

bool AviRecorder::rewriteHeader(bool hasIndex) {
  if (!aviFile_) {
    return false;
  }
  aviFile_.flush();
  const size_t endPosition = aviFile_.size();
  const uint32_t fps = playbackFps();
  const uint64_t riffSize64 = endPosition >= 8 ? endPosition - 8 : 0;
  const uint64_t moviSize64 = 4ULL + videoDataBytes_;
  if (riffSize64 > UINT32_MAX || moviSize64 > UINT32_MAX) {
    return false;
  }

  bool ok = aviFile_.seek(4) && writeU32(aviFile_, static_cast<uint32_t>(riffSize64));
  ok = ok && aviFile_.seek(32) && writeU32(aviFile_, 1000000UL / fps);
  ok = ok && writeU32(aviFile_, maxFrameBytes_ * fps);
  ok = ok && aviFile_.seek(44) && writeU32(aviFile_, hasIndex ? AVI_HAS_INDEX : 0);
  ok = ok && writeU32(aviFile_, frameCount_);
  ok = ok && aviFile_.seek(60) && writeU32(aviFile_, maxFrameBytes_);
  ok = ok && aviFile_.seek(128) && writeU32(aviFile_, 1) && writeU32(aviFile_, fps);
  ok = ok && aviFile_.seek(140) && writeU32(aviFile_, frameCount_) &&
       writeU32(aviFile_, maxFrameBytes_);
  ok = ok && aviFile_.seek(192) && writeU32(aviFile_, maxFrameBytes_);
  ok = ok && aviFile_.seek(260) && writeU32(aviFile_, static_cast<uint32_t>(moviSize64));
  ok = ok && aviFile_.seek(endPosition);
  return ok;
}

bool AviRecorder::checkpoint() {
  if (!active_) {
    return false;
  }
  const bool ok = rewriteHeader(false);
  aviFile_.flush();
  indexFile_.flush();
  return ok;
}

bool AviRecorder::appendIndex() {
  indexFile_.flush();
  if (!indexFile_.seek(0) || !aviFile_.seek(aviFile_.size())) {
    return false;
  }
  const uint64_t indexBytes64 = frameCount_ * static_cast<uint64_t>(INDEX_ENTRY_BYTES);
  if (indexBytes64 > UINT32_MAX || !writeFourCC(aviFile_, "idx1") ||
      !writeU32(aviFile_, static_cast<uint32_t>(indexBytes64))) {
    return false;
  }

  uint8_t buffer[1024];
  uint64_t remaining = indexBytes64;
  while (remaining > 0) {
    const size_t wanted = remaining > sizeof(buffer) ? sizeof(buffer) : remaining;
    const size_t amount = indexFile_.read(buffer, wanted);
    if (amount != wanted || aviFile_.write(buffer, amount) != amount) {
      return false;
    }
    remaining -= amount;
  }
  return true;
}

bool AviRecorder::finish() {
  if (!active_) {
    return false;
  }
  stoppedAtMs_ = millis();
  active_ = false;

  if (frameCount_ == 0) {
    abortAndRemove();
    return false;
  }

  bool ok = appendIndex();
  if (ok) {
    ok = rewriteHeader(true);
  }
  aviFile_.flush();
  closeFiles();
  if (fs_ != nullptr) {
    fs_->remove(indexPath_);
    if (!ok) {
      fs_->remove(aviPath_);
    }
  }
  return ok;
}

void AviRecorder::closeFiles() {
  if (aviFile_) aviFile_.close();
  if (indexFile_) indexFile_.close();
}

void AviRecorder::abortAndRemove() {
  active_ = false;
  closeFiles();
  if (fs_ != nullptr) {
    fs_->remove(aviPath_);
    fs_->remove(indexPath_);
  }
}
