require "rrobots/numeric"
require "rrobots/explosion"

# :stopdoc:
class Bullet
  attr_accessor :dead
  attr_accessor :energy
  attr_accessor :heading
  attr_accessor :origin
  attr_accessor :speed
  attr_accessor :x
  attr_accessor :y

  attr_reader :battlefield

  alias dead? dead

  def initialize bf, x, y, heading, speed, energy, origin
    @battlefield, @x, @y = bf, x, y
    @heading, @speed, @energy, @origin = heading, speed, energy, origin

    @dead = false
  end

  def tick
    return if dead?

    self.x += Math::cos(heading.to_rad) * speed
    self.y -= Math::sin(heading.to_rad) * speed # minus because y goes down

    self.dead ||= (x < 0) || (x >= battlefield.width)
    self.dead ||= (y < 0) || (y >= battlefield.height)

    battlefield.robots.each do |other|
      distance = Math.hypot(y - other.y, other.x - x)

      if other != origin && distance < 40 && !other.dead?
        battlefield << Explosion.new(battlefield, other.x, other.y)

        damage = other.hit(self)
        origin.damage_given += damage
        origin.kills += 1 if other.dead?

        self.dead = true
      end
    end
  end
end
