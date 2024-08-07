// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_PLATFORM_MESSAGE_HANDLER_IOS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_PLATFORM_MESSAGE_HANDLER_IOS_H_

#include <unordered_map>

#include "flutter/common/task_runners.h"
#include "flutter/fml/platform/darwin/scoped_block.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_message_handler.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"

@protocol FlutterTaskQueue;

namespace flutter {

class PlatformMessageHandlerIos : public PlatformMessageHandler {
 public:
  static NSObject<FlutterTaskQueue>* MakeBackgroundTaskQueue();

  PlatformMessageHandlerIos(TaskRunners task_runners);

  void HandlePlatformMessage(std::unique_ptr<PlatformMessage> message) override;

  bool DoesHandlePlatformMessageOnPlatformThread() const override { return false; }

  void InvokePlatformMessageResponseCallback(int response_id,
                                             std::unique_ptr<fml::Mapping> mapping) override;

  void InvokePlatformMessageEmptyResponseCallback(int response_id) override;

  void SetMessageHandler(const std::string& channel,
                         FlutterBinaryMessageHandler handler,
                         NSObject<FlutterTaskQueue>* task_queue);

  struct HandlerInfo {
    fml::scoped_nsprotocol<NSObject<FlutterTaskQueue>*> task_queue;
    fml::ScopedBlock<FlutterBinaryMessageHandler> handler;
  };

 private:
  std::unordered_map<std::string, HandlerInfo> message_handlers_;
  TaskRunners task_runners_;
  std::mutex message_handlers_mutex_;
  FML_DISALLOW_COPY_AND_ASSIGN(PlatformMessageHandlerIos);
};

}  // namespace flutter

#endif
