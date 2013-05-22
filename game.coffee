# vim, use tau iabbr
canvas = atom.canvas
canvas.width = 800
canvas.height = 600
ctx = atom.context
ctx.scale 1, -1
ctx.translate 0,-600

τ = Math.PI*2

v = cp.v

atom.input.bind atom.key.SPACE, 'pause/play'
atom.input.bind atom.key.T, 'restart'
atom.input.bind atom.button.LEFT, 'lmb'

class Game extends atom.Game
  constructor: ->
    @forces = {}
    @reset()
    @paused = true
    @dirty = true

  reset: ->
    @space = new cp.Space
    @space.gravity = v(0, -100)

    @forcing = false
    @forceFrom = null
    @forceTo = null
    @t = 0

    @ball = @newBall()
    @ball.p = v 400, 300
    b = @ball
    b.shapeList[0].update(b.p, b.rot)

    ctx.fillStyle = 'white'
    ctx.fillRect 0, 0, canvas.width, canvas.height

  newBall: ->
    mass = 2
    body = @space.addBody new cp.Body mass, cp.momentForCircle mass, 0, 40, v(0,0)
    shape = @space.addShape new cp.CircleShape body, 40, v(0,0)
    shape.setElasticity 0.9
    shape.setFriction 0.6
    body

  addWalls: ->
    bottom = @space.addShape(new cp.SegmentShape(@space.staticBody, v(0, 0), v(800, 0), 0))
    bottom.setElasticity(1)
    bottom.setFriction(0.1)
    bottom.group = 1
    top = @space.addShape(new cp.SegmentShape(@space.staticBody, v(0, 600), v(800, 600), 0))
    top.setElasticity(1)
    top.setFriction(0.1)
    top.group = 1

  update: (dt) ->
    dt = 1/60
    if atom.input.pressed 'restart'
      @reset()
      @dirty = true
    if not @forcing and atom.input.pressed 'pause/play'
      @paused = not @paused

    if @paused
      if atom.input.pressed 'lmb'
        mouse = v(atom.input.mouse.x, canvas.height-atom.input.mouse.y)
        if @ball.shapeList[0].pointQuery mouse
          @forceFrom = v.sub mouse, @ball.p
          @forcing = true
      if atom.input.down 'lmb'
        mouse = v(atom.input.mouse.x, canvas.height-atom.input.mouse.y)
        @forceTo = v.sub mouse, @ball.p
        @dirty = true
      else if @forcing
        @forcing = false
        @applyForce @t, @forceFrom, @forceTo
    else
      if @t of @forces
        for f in @forces[@t]
          r = v.sub(f.to, f.from).mult 2
          @ball.applyImpulse r, f.from
      @t += 1
      @space.step dt
      @dirty = true

  applyForce: (time, from, to) ->
    (@forces[time] ?= []).push {from, to}

  drawForce: (f) ->
    from = v.add @ball.p, f.from
    to = v.add @ball.p, f.to
    ctx.lineWidth = 3
    ctx.lineCap = 'round'
    ctx.beginPath()
    ctx.moveTo from.x, from.y
    ctx.lineTo to.x, to.y
    ctx.strokeStyle = 'red'
    ctx.stroke()
    
  draw: ->
    return unless @dirty
    ctx.fillStyle = 'white'
    ctx.fillRect 0, 0, canvas.width, canvas.height
    ctx.fillStyle = 'black'

    ctx.strokeStyle = 'black'
    @ball.shapeList[0].draw()

    if @t of @forces
      for f in @forces[@t]
        @drawForce f

    if @forcing
      @drawForce {from: @forceFrom, to: @forceTo}

cp.PolyShape::draw = ->
  ctx.beginPath()

  verts = this.tVerts
  len = verts.length
  lastPoint = new cp.Vect(verts[len - 2], verts[len - 1])
  ctx.moveTo(lastPoint.x, lastPoint.y)

  i = 0
  while i < len
    p = new cp.Vect(verts[i], verts[i+1])
    ctx.lineTo(p.x, p.y)
    i += 2
  #ctx.fill()
  ctx.stroke()

cp.SegmentShape::draw = ->
  oldLineWidth = ctx.lineWidth
  ctx.lineWidth = Math.max 1, this.r * 2
  ctx.beginPath()
  ctx.moveTo @ta.x, @ta.y
  ctx.lineTo @tb.x, @tb.y
  ctx.stroke()
  ctx.lineWidth = oldLineWidth

cp.CircleShape::draw = ->
  ctx.lineWidth = 3
  ctx.lineCap = 'round'
  ctx.beginPath()
  ctx.arc @tc.x, @tc.y, @r, 0, τ, false

  # And draw a little radius so you can see the circle roll.
  ctx.moveTo @tc.x, @tc.y
  r = cp.v.mult(@body.rot, @r).add @tc
  ctx.lineTo r.x, r.y
  ctx.stroke()

game = new Game
game.run()

window.onblur = -> game.stop()
window.onfocus = -> game.run()
