# :stopdoc:
class Battlefield
  attr_reader :width
  attr_reader :height
  attr_reader :robots
  attr_reader :teams
  attr_reader :bullets
  attr_reader :explosions
  attr_reader :time
  attr_reader :seed
  attr_reader :timeout  # how many ticks the match can go before ending.
  attr_reader :game_over

  alias game_over? game_over

  def initialize width, height, timeout, seed
    @width      = width
    @height     = height
    @seed       = seed
    @time       = 0
    @robots     = []
    @teams      = Hash.new { |h,k| h[k] = [] }
    @bullets    = []
    @explosions = []
    @timeout    = timeout
    @game_over  = false

    srand @seed
  end

  def << object
    case object
    when RobotRunner
      @robots << object
      @teams[object.team] << object
    when Bullet
      @bullets << object
    when Explosion
      @explosions << object
    end
  end

  def tick
    explosions.delete_if(&:dead?)
    bullets.delete_if(&:dead?)

    explosions.each(&:tick)
    bullets.each(&:tick)

    robots.each do |robot|
      begin
        robot.send :internal_tick unless robot.dead
      rescue StandardError => bang
        puts "#{robot} made an exception:"
        puts "#{bang.class}: #{bang}", bang.backtrace
        robot.energy = -1
      end
    end

    @time += 1

    live_robots = robots.reject(&:dead?)

    @game_over = (@time >= timeout || live_robots.empty? ||
                  live_robots.group_by(&:team).size == 1)

    not @game_over
  end

  def state
    {
     :explosions => explosions.map(&:state),
     :bullets    => bullets.map(&:state),
     :robots     => robots.map(&:state),
    }
  end

end
