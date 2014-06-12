# :stopdoc:
class Explosion
  attr_accessor :x
  attr_accessor :y
  attr_accessor :t
  attr_accessor :dead

  alias dead? dead

  def initialize bf, x, y
    @battlefield, @x, @y = bf, x, y
    @t, @dead = 0, false
  end

  def tick
    @t += 1
    @dead ||= t > 15
  end
end
