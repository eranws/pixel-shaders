module.exports = (ctx, opts) ->
  o = _.extend({
    equations: []
    domain: [-2.6, 2.6]
    range: [-2.6, 2.6]
    label: 1
    labelSize: 5
  }, opts)
  
  
  canvas = ctx.canvas
  width = canvas.width
  height = canvas.height
  
  toCanvasCoords = ([x, y]) ->
    cx = (x - o.domain[0]) / (o.domain[1] - o.domain[0]) * width
    cy = (y - o.range[0]) / (o.range[1] - o.range[0]) * height
    [cx, height - cy]
  
  fromCanvasCoords = ([cx, cy]) ->
    x = (cx / width) * (o.domain[1] - o.domain[0]) + o.domain[0]
    y = ((height-cy) / height) * (o.range[1] - o.range[0]) + o.range[0]
    [x, y]
  
  
  draw = () ->
    # reset
    ctx.setTransform(1, 0, 0, 1, 0, 0)
    ctx.clearRect(0, 0, width, height)
    
    # draw axes
    origin = toCanvasCoords([0, 0])
    ctx.strokeStyle = "#999"
    ctx.lineWidth = 0.5
    ctx.beginPath()
    ctx.moveTo(origin[0], 0)
    ctx.lineTo(origin[0], height)
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo(0, origin[1])
    ctx.lineTo(height, origin[1])
    ctx.stroke()
    
    # draw labels
    ctx.font = "12px verdana"
    ctx.fillStyle = "#666"
    [xmin, ymin] = fromCanvasCoords([0, height])
    [xmax, ymax] = fromCanvasCoords([width, 0])
    
    ctx.textAlign = "center"
    ctx.textBaseline = "top"
    for xi in [Math.ceil(xmin/o.label) .. Math.floor(xmax/o.label)]
      if xi != 0
        x = xi * o.label
        [cx, cy] = toCanvasCoords([x, 0])
        ctx.beginPath()
        ctx.moveTo(cx, cy-o.labelSize)
        ctx.lineTo(cx, cy+o.labelSize)
        ctx.stroke()
        ctx.fillText(""+x, cx, cy+o.labelSize*1.5)
    
    ctx.textAlign = "left"
    ctx.textBaseline = "middle"
    for yi in [Math.ceil(ymin/o.label) .. Math.floor(ymax/o.label)]
      if yi != 0
        y = yi * o.label
        [cx, cy] = toCanvasCoords([0, y])
        ctx.beginPath()
        ctx.moveTo(cx-o.labelSize, cy)
        ctx.lineTo(cx+o.labelSize, cy)
        ctx.stroke()
        ctx.fillText(""+y, cx+o.labelSize*1.5, cy)
    
    
    # console.log xmin, ymin, xmax, ymax
    
    # draw graph
    ctx.lineWidth = 2
    
    for equation in o.equations
      ctx.strokeStyle = equation.color
      f = equation.f
      
      ctx.beginPath()
      
      resolution = 0.25
      for i in [0..(width/resolution)]
        cx = i * resolution
        x = fromCanvasCoords([cx, 0])[0]
        y = f(x)
        cy = toCanvasCoords([x, y])[1]
        ctx.lineTo(cx, cy)
      
      ctx.stroke()
    
    if o.hint || o.hint == 0
      ctx.lineWidth = 0.25
      for equation in o.equations
        x = o.hint
        y = equation.f(o.hint)
        [cx, cy] = toCanvasCoords([x, y])
        
        ctx.strokeStyle = "#000"
        ctx.beginPath()
        ctx.moveTo(toCanvasCoords([x, 0])...)
        ctx.lineTo(cx, cy)
        ctx.stroke()
        
        ctx.strokeStyle = equation.color
        ctx.beginPath()
        ctx.moveTo(cx, cy)
        ctx.lineTo(toCanvasCoords([0, y])...)
        ctx.stroke()
        
        ctx.fillStyle = equation.color
        ctx.beginPath()
        ctx.arc(cx, cy, 3, 0, Math.PI*2, false)
        ctx.fill()
  
  
  
  
  
  
  return {
    toCanvasCoords: toCanvasCoords
    fromCanvasCoords: fromCanvasCoords
    draw: (opts) ->
      o = _.extend(o, opts)
      draw()
  }
























