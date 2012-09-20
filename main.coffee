tex0 = new Image()




parseShaderError = (error) ->
  # Based on https://github.com/mrdoob/glsl-sandbox/blob/master/static/index.html
  
  # Remove trailing linefeed, for FireFox's benefit.
  while ((error.length > 1) && (error.charCodeAt(error.length - 1) < 32))
    error = error.substring(0, error.length - 1)
  
  parsed = []
  index = 0
  while index >= 0
    index = error.indexOf("ERROR: 0:", index)
    if index < 0
      break
    index += 9;
    indexEnd = error.indexOf(':', index)
    if (indexEnd > index)
      lineNum = parseInt(error.substring(index, indexEnd))
      index = indexEnd + 1
      indexEnd = error.indexOf("ERROR: 0:", index)
      lineError = if indexEnd > index then error.substring(index, indexEnd) else error.substring(index)
      parsed.push({
        lineNum: lineNum
        error: lineError
      })
  return parsed


parseUniforms = (src) ->
  regex = XRegExp('uniform +(?<type>[^ ]+) +(?<name>[^ ;]+) *;', 'g')
  
  uniforms = []
  XRegExp.forEach(src, regex, (match) ->
    uniforms.push({
      type: match.type
      name: match.name
    })
  )
  return uniforms






buildEnv = (opts) ->
  
  src = opts.src
  appendDiv = $(opts.append || "body")
  inspectorHint = opts.inspector
  
  env = $("""
    <div class='env'>
      <canvas width='300' height='300'></canvas>
      <div class='uniforms'></div>
      <div class='code'></div>
    </div>
    """)
  
  appendDiv.append(env)
  
  canvas = env.find("canvas")[0]
  code = env.find(".code")[0]
  $uniforms = env.find(".uniforms")
  
  gl = canvas.getContext("experimental-webgl", {premultipliedAlpha: false})
  
  renderer = flatRenderer(gl)
  
  # Load in tex0 (hack)
  texture = gl.createTexture()
  gl.bindTexture(gl.TEXTURE_2D, texture)
  
  # Set the parameters so we can render any size image.
  gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

  # Upload the image into the texture.
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, tex0);
  
  uniforms = []
  uniformGetters = {}
  errorLines = []
  
  draw = () ->
    # set uniforms
    for own name, getter of uniformGetters
      renderer.setUniform(name, getter())
    
    renderer.draw()
  
  codeChange = () ->
    # make uniforms html
    newUniforms = parseUniforms(cm.getValue())
    if !_.isEqual(uniforms, newUniforms)
      uniforms = newUniforms
      uniformGetters = {}
      $uniforms.html("")
      uniforms.forEach (u) ->
        if u.type == "float"
          input = $("<input type='range' min='0' max='1' step='.0001'>")
          input.change(draw)
          getter = () -> parseFloat(input.val())
        else if u.type == "sampler2D"
          input = $("<img src='tex0.jpg' width='60' height='60'>")
          getter = false
        
        $u = $("""
          <div class="uniform">
            <div class="name">#{u.name}</div>
            <div class="input"></div>
          </div>
        """)
        $u.find(".input").append(input)
        $uniforms.append($u)
        
        if getter
          uniformGetters[u.name] = getter
        
    
    # clear previous error lines
    for line in errorLines
      cm.setLineClass(line, null, null)
      cm.clearMarker(line)
    errorLines = []
    
    err = renderer.loadFragmentShader(cm.getValue())
    if err
      errors = parseShaderError(err)
      
      for error in errors
        line = cm.getLineHandle(error.lineNum - 1)
        errorLines.push(line)
        cm.setLineClass(line, null, "errorLine")
        cm.setMarker(line, "<div class='errorMessage'>#{error.error}</div>%N%", "errorMarker")
    else
      renderer.link()
      draw()
  
  
  cm = CodeMirror(code, {
    value: src
    mode: "text/x-glsl"
    lineNumbers: true
    onChange: codeChange
  })
  
  codeChange()
  
  if inspectorHint
    
    makeSpaces = (num) -> (" " for i in [0...num]).join("")
    round = (n) -> Math.round(n * 10000) / 10000
    convert = (n) ->
      if typeof n == "number"
        return round(n)
      else if typeof n == "string"
        return n
      else
        return "vec#{n.length}(#{n.map(round).join(', ')})"
    
    originalValue = src
    
    update = (x, y) ->
      lines = originalValue.split("\n")
      
      maxLength = 0
      for line in lines
        if line.length > maxLength
          maxLength = line.length
      
      newLines = []
      if originalValue == src
        hints = inspectorHint(x, y)
      else
        hints = ["(This mockup only shows line-by-line", "evaluation on the original code.)"]
      for line, i in lines
        if hints[i] || hints[i] == 0
          newLines.push("#{line}#{makeSpaces(maxLength - line.length)}  // #{convert(hints[i])}")
        else
          newLines.push(line)
      
      cm.setValue(newLines.join("\n"))
    
    $canvas = $(canvas)
    updateWithEvent = (e) ->
      offset = $canvas.offset()
      x = (e.pageX - offset.left + 0.5) / $canvas.width()
      y = (1 - (e.pageY - offset.top + 0.5) / $canvas.height())
      update(x, y)
    $canvas.mouseover (e) ->
      originalValue = cm.getValue()
    $canvas.mousemove (e) ->
      updateWithEvent(e)
    $canvas.mouseout (e) ->
      cm.setValue(originalValue)
    $canvas.click (e) ->
      cm.setValue(src)
      originalValue = src
      updateWithEvent(e)






start = () ->
  buildEnv({
    src: """
      precision mediump float;
      
      varying vec2 position;
      
      void main() {
        gl_FragColor.r = position.x;
        gl_FragColor.g = 0.0;
        gl_FragColor.b = 0.0;
        gl_FragColor.a = 1.0;
      }
      """
    inspector: (x, y) ->
      [
        false,
        false,
        [x, y],
        false,
        false,
        x,
        0,
        0,
        1,
        false
      ]
  })
  
  
  buildEnv({
    src: """
      precision mediump float;
      
      varying vec2 position;
      
      void main() {
        gl_FragColor.r = position.x;
        gl_FragColor.g = 0.0;
        gl_FragColor.b = position.y;
        gl_FragColor.a = 1.0;
      }
      """
    inspector: (x, y) ->
      [
        false,
        false,
        [x, y],
        false,
        false,
        x,
        0,
        y,
        1,
        false
      ]
  })
  
  
  buildEnv({
    src: """
    precision mediump float;
    
    varying vec2 position;
    
    void main() {
      vec2 p = position - vec2(0.5, 0.5);
      
      float radius = length(p);
      float angle = atan(p.y, p.x);
      
      gl_FragColor.r = radius;
      gl_FragColor.g = 0.0;
      gl_FragColor.b = abs(angle / 3.14159);
      gl_FragColor.a = 1.0;
    }
    """
    inspector: (x, y) ->
      p = [x - 0.5, y - 0.5]
      radius = Math.sqrt(p[0]*p[0] + p[1]*p[1])
      angle = Math.atan2(p[1], p[0])
      [
        false,
        false,
        [x, y],
        false,
        false,
        p,
        false,
        radius,
        angle,
        false,
        radius,
        0,
        Math.abs(angle / 3.14159),
        1,
        false
      ]
  })
  
  
  # buildEnv({
  #   src: """
  #   precision mediump float;
  #   
  #   varying vec2 position;
  #   uniform sampler2D tex0;
  #   
  #   void main() {
  #     vec4 color = texture2D(tex0, position);
  #     gl_FragColor.rgb = 1.0 - color.rgb;
  #     gl_FragColor.a = 1.0;
  #   }
  #   """
  # })
  # 
  # buildEnv({
  #   src: """
  #   precision mediump float;
  #   
  #   varying vec2 position;
  #   uniform sampler2D tex0;
  #   uniform float threshold;
  #   
  #   void main() {
  #     vec4 color = texture2D(tex0, position);
  #     float brightness = (color.r + color.g + color.b) / 3.0;
  #     if (brightness > threshold) {
  #       gl_FragColor = color;
  #     } else {
  #       gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #     }
  #   }
  #   """
  # })

tex0.onload = start
tex0.src = "tex0.jpg"