// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform VertInfo {
  mat4 mvp;
}
vert_info;

in vec2 position;
in vec2 texture_coords;
in vec4 color;

out vec2 v_texture_coords;
out vec4 v_color;

void main() {
  gl_Position = vert_info.mvp * vec4(position, 0.0, 1.0);
  v_texture_coords = texture_coords;
  v_color = color;
}
