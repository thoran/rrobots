# :stopdoc:
class RobotRunner
  STATE_IVARS = [:x, :y, :gun_heat, :heading, :gun_heading, :radar_heading,
                 :time, :size, :speed, :energy, :team ]
  NUMERIC_ACTIONS = [ :fire, :turn, :turn_gun, :turn_radar, :accelerate ]
  STRING_ACTIONS = [ :say, :broadcast ]

  STATE_IVARS.each do |iv|
    attr_accessor iv
  end

  NUMERIC_ACTIONS.each do |iv|
    attr_accessor "#{iv}_min", "#{iv}_max"
  end

  STRING_ACTIONS.each do |iv|
    attr_accessor "#{iv}_max"
  end

  # AI of this robot
  attr_accessor :robot

  # keeps track of total damage done by this robot
  attr_accessor :damage_given

  # keeps track of the kills
  attr_accessor :kills

  attr_reader :actions, :speech

  def initialize robot, bf, team=0
    @robot       = robot
    @battlefield = bf
    @team        = team

    set_action_limits
    set_initial_state

    @events = Hash.new{|h, k| h[k]=[]}
    @actions = Hash.new(0)
  end

  def skin_prefix
    @robot.skin_prefix
  end

  def set_action_limits
    @fire_min, @fire_max             =   0,  3
    @turn_min, @turn_max             = -10, 10
    @turn_gun_min, @turn_gun_max     = -30, 30
    @turn_radar_min, @turn_radar_max = -60, 60
    @accelerate_min, @accelerate_max =  -1,  1
    @speed_min, @speed_max           =  -8,  8

    @say_max       = 256
    @broadcast_max = 16
  end

  def set_initial_state
    @x              = 0
    @y              = 0
    @speech_counter = -1
    @speech         = nil
    @time           = 0
    @size           = 60
    @speed          = 0
    @energy         = 100
    @damage_given   = 0
    @kills          = 0

    teleport
  end

  def teleport
    @x += (rand * @battlefield.width).to_i
    @y += (rand * @battlefield.height).to_i

    @gun_heat      = 3
    @heading       = (rand * 360).to_i
    @gun_heading   = @heading
    @radar_heading = @heading
  end

  def hit bullet
    damage = bullet.energy
    @energy -= damage
    @events['got_hit'] << [@energy]
    damage
  end

  def dead
    @energy < 0
  end

  alias dead? dead

  def clamp var, min, max
    val = 0 + (var || 0)
    val > max ? max : val < min ? min : val
  end

  def internal_tick
    update_state
    robot_tick
    parse_actions
    fire
    turn
    move
    scan
    speak
    broadcast
    @time += 1
  end

  def parse_actions
    @actions.clear
    NUMERIC_ACTIONS.each{|an|
      @actions[an] = clamp(@robot.actions[an], send("#{an}_min"), send("#{an}_max"))
    }
    STRING_ACTIONS.each{|an|
      if @robot.actions[an] != 0
        @actions[an] = String(@robot.actions[an])[0, send("#{an}_max")]
      end
    }
    @actions
  end

  def state
    current_state = {}

    STATE_IVARS.each do |iv|
      current_state[iv] = send(iv)
    end

    current_state[:battlefield_width]  = @battlefield.width
    current_state[:battlefield_height] = @battlefield.height
    current_state[:game_over]          = @battlefield.game_over

    current_state
  end

  def update_state
    new_state = state
    @robot.state = new_state

    new_state.each do |k,v|
      @robot.send("#{k}=", v)
    end

    @robot.events = @events.dup
    @robot.actions ||= Hash.new(0)
    @robot.actions.clear
  end

  def robot_tick
    @robot.tick @robot.events
    @events.clear
  end

  def fire
    if @actions[:fire] > 0 && @gun_heat == 0
      bullet = Bullet.new(@battlefield, @x, @y,
                          @gun_heading,
                          30, # FIX: should be proportional to energy
                          @actions[:fire]*3.0,
                          self)

      @battlefield << bullet

      @gun_heat = @actions[:fire]
    end

    @gun_heat -= 0.1
    @gun_heat = 0 if @gun_heat < 0
  end

  def turn
    @old_radar_heading = @radar_heading

    # TODO: remove this cascade
    @heading       += (@actions[:turn])
    @gun_heading   += (@actions[:turn] + @actions[:turn_gun])
    @radar_heading += (@actions[:turn] + @actions[:turn_gun] + @actions[:turn_radar])

    @new_radar_heading = @radar_heading

    @heading       %= 360
    @gun_heading   %= 360
    @radar_heading %= 360
  end

  def move
    @speed += @actions[:accelerate]
    @speed = clamp(@speed, @speed_min, @speed_max)

    @x += Math::cos(@heading.to_rad) * @speed
    @y -= Math::sin(@heading.to_rad) * @speed

    @x = clamp(@x, 0+@size, @battlefield.width-@size)
    @y = clamp(@y, 0+@size, @battlefield.height-@size)
  end

  def scan
    @battlefield.robots.each do |other|
      if (other != self) && (!other.dead)
        a = Math.atan2(@y - other.y, other.x - @x) / Math::PI * 180 % 360
        if ((@old_radar_heading <= a     && a <= @new_radar_heading)     ||
            (@old_radar_heading >= a     && a >= @new_radar_heading)     ||
            # TODO: verify this logic even works
            (@old_radar_heading <= a+360 && a+360 <= @new_radar_heading) ||
            (@old_radar_heading >= a+360 && a+360 >= @new_radar_heading) ||
            (@old_radar_heading <= a-360 && a-360 <= @new_radar_heading) ||
            (@old_radar_heading >= a-360 && a-360 >= @new_radar_heading))
          @events['robot_scanned'] << [Math.hypot(@y - other.y, other.x - @x)]
        end
      end
    end
  end

  def speak
    if @actions[:say] != 0
      @speech = @actions[:say]
      @speech_counter = 50
    elsif @speech and (@speech_counter -= 1) < 0
      @speech = nil
    end
  end

  def broadcast
    @battlefield.robots.each do |other|
      if (other != self) && (!other.dead)
        msg = other.actions[:broadcast]
        if msg != 0
          a = Math.atan2(@y - other.y, other.x - @x) / Math::PI * 180 % 360
          dir = 'east'
          dir = 'north' if a.between? 45,135
          dir = 'west' if a.between? 135,225
          dir = 'south' if a.between? 225,315
          @events['broadcasts'] << [msg, dir]
        end
      end
    end
  end

  def to_s
    @robot.class.name
  end

  def name
    @robot.class.name
  end

end
