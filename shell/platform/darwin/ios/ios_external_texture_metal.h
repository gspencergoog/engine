// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_TEXTURE_METAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_TEXTURE_METAL_H_

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#import "flutter/shell/platform/darwin/graphics/FlutterDarwinExternalTextureMetal.h"

namespace flutter {

class IOSExternalTextureMetal final : public Texture {
 public:
  explicit IOSExternalTextureMetal(
      fml::scoped_nsobject<FlutterDarwinExternalTextureMetal>
          darwin_external_texture_metal);

  // |Texture|
  ~IOSExternalTextureMetal();

 private:
  fml::scoped_nsobject<FlutterDarwinExternalTextureMetal>
      darwin_external_texture_metal_;

  // |Texture|
  void Paint(PaintContext& context,
             const SkRect& bounds,
             bool freeze,
             const SkSamplingOptions& sampling) override;

  // |Texture|
  void OnGrContextCreated() override;

  // |Texture|
  void OnGrContextDestroyed() override;

  // |Texture|
  void MarkNewFrameAvailable() override;

  // |Texture|
  void OnTextureUnregistered() override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSExternalTextureMetal);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_TEXTURE_METAL_H_
