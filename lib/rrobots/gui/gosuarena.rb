# :stopdoc:
require 'gosu'

GosuRobot = Struct.new(:body, :gun, :radar, :speech, :info,
                       :status, :color, :font_color)

module ZOrder
  Background, Robot, Explosions, UI = *0..3
end

class RRobotsGameWindow < Gosu::Window
  EXPLOSION_COUNT = 14
  BIG_FONT        = 'Courier New'
  SMALL_FONT      = 'Courier New'
  FONT_SIZE       = 24
  COLORS          = %w[white blue yellow red lime]
  FONT_COLORS     = [0xffffffff, 0xff0008ff, 0xfffff706, 0xffff0613, 0xff00ff04]

  attr_reader :battlefield, :xres, :yres, :update_interval
  attr_accessor :on_game_over_handlers, :boom, :robots, :bullets, :explosions

  def initialize(battlefield, xres, yres, update_interval)
    super(xres, yres, false, update_interval)

    self.caption           = 'RRobots'
    @font                  = Gosu::Font.new(self, BIG_FONT, FONT_SIZE*2)
    @small_font            = Gosu::Font.new(self, SMALL_FONT, FONT_SIZE)
    @battlefield           = battlefield
    @xres, @yres           = xres, yres
    @on_game_over_handlers = []
    @boom                  = (0..EXPLOSION_COUNT).map { |i| image("explosion%02d", i) }
    @bullet_image          = image("bullet")
    @robots                = {}
    @bullets               = {}
    @explosions            = {}
    @leaderboard           = Leaderboard.new(self, @robots)
  end

  def on_game_over(&block)
    @on_game_over_handlers << block
  end

  def image name, number = nil
    f = if number then
          "../images/#{name}.bmp" % number
        else
          "../images/#{name}.png"
        end

    Gosu::Image.new self, File.join(File.dirname(__FILE__), f)
  end

  def draw
    simulate
    draw_battlefield
    @leaderboard.draw
    if button_down? Gosu::Button::KbEscape
      self.close
    end
  end

  def draw_battlefield
    draw_robots
    draw_bullets
    draw_explosions
  end

  def simulate(ticks=1)
    @explosions.reject! { |e, _| e.dead }
    @bullets.reject!    { |b, _| b.dead }
    @robots.reject!     { |r, _| r.dead }

    ticks.times do
      if @battlefield.game_over
        @on_game_over_handlers.each{|h| h.call(@battlefield) }
        winner = @robots.keys.first
        whohaswon = if winner.nil?
                      "Draw!"
                    elsif @battlefield.teams.all?{|k,t|t.size<2}
                      "#{winner.name} won!"
                    else
                      "Team #{winner.team} won!"
                    end
        @font.draw_rel("#{whohaswon}", xres/2, yres/2, ZOrder::UI,
                       0.5, 0.5, 1, 1, 0xffffff00)
      end
      @battlefield.tick
    end
  end

  def draw_robots
    @battlefield.robots.each_with_index do |ai, i|
      next if ai.dead

      color      = COLORS[i % COLORS.size]
      font_color = FONT_COLORS[i % FONT_COLORS.size]

      @robots[ai] ||= GosuRobot.new(
                                    image("#{color}_body%03d", 0),
                                    image("#{color}_turret%03d", 0),
                                    image("#{color}_radar%03d", 0),
                                    @small_font,
                                    @small_font,
                                    @small_font,
                                    color,
                                    font_color
                                   )

      draw_ai_body ai, :body,  :heading
      draw_ai_body ai, :gun,   :gun_heading
      draw_ai_body ai, :radar, :radar_heading

      draw_ai_label ai, :speech, ai.speech,      -40, font_color
      draw_ai_label ai, :info,   ai.name,        +30, font_color
      draw_ai_label ai, :info,   ai.energy.to_i, +50, font_color
    end
  end

  def draw_ai_body ai, part, angle
    @robots[ai].send(part).draw_rot(ai.x, ai.y, ZOrder::Robot,
                                    (-(ai.send(angle)-90)) % 360)
  end

  def draw_ai_label ai, part, text, offset, color
    @robots[ai].send(part).draw_rel(text.to_s, ai.x, ai.y + offset,
                                    ZOrder::UI, 0.5, 0.5, 1, 1, color)
  end

  def draw_bullets
    @battlefield.bullets.each do |bullet|
      @bullets[bullet] ||= @bullet_image
      @bullets[bullet].draw(bullet.x, bullet.y, ZOrder::Explosions)
    end
  end

  def draw_explosions
    @battlefield.explosions.each do |explosion|
      @explosions[explosion] = boom[explosion.t % EXPLOSION_COUNT]
      @explosions[explosion].draw_rot(explosion.x, explosion.y, ZOrder::Explosions, 0)
    end
  end
end
