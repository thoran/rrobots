History  truct.new(:x, :y, :t, :prec)

class GayRush
    Margin  00
    MinRefl  0
    FlurryAngle    include Robot

    def clamp(val, min, max)
        return val < min ? min : (val > max ? max : val)
    end

    def turn_to(dir)
        unless dir
            return 0
        end

        delta2  dir + 360 - @heading) % 360
        delta1  @heading + 360 - dir) % 360
        if(delta1 < delta2)
            if delta1 < 0
                return -delta1
            else
                return -10
            end
        else
            if delta2 < 0
                return delta2
            else
                return 10
            end
        end
    end

    def turn_gun_to(dir)
        unless dir
            return 0
        end

        delta2  dir + 360 - @gun_heading) % 360
        delta1  @gun_heading + 360 - dir) % 360
        if(delta1 < delta2)
            if delta1 < 0
                return -delta1
            else
                return -20
            end
        else
            if delta2 < 0
                return delta2
            else
                return 20
            end
        end
    end



    def tick(events)
        if time
            # - obsolete heuristic
                #@oldavx  attlefield_height/2
                #@avx  attlefield_height/2
                #@oldavy  attlefield_width/2
                #@avy  attlefield_width/2

            @radarstep0
            @flurry            @last_not_f  
            @dist  
            puts "GayRush> Do you think you are stronger than me?"
            @h  rray.new(3) { History.new(800.to_f,800.to_f,0.to_f,0.to_f) }
        end


        guntrn  

        # check if the enemy was detected
        if events['robot_scanned'].empty?

            #update the radar position
            if @radarstep.abs<60
                if not @was_seen
                    #look alternatively left and right with 2x bigger windows
                    @radarstep*
                else
                    # if we did not find the robot (but the prev tick it had
                    # been found) simply move forward the radar
                    @radarstep*2
                end
            end

            @radarstep  lamp( @radarstep, -60, 60)

            if not @was_seen
                @escape_to  il
            end
            @was_seen  il

            @last_not_f  ime

        else #seen
            # get the distance of the robot
            @dist  vents['robot_scanned'].flatten.min

            # this is the average angle we are looking at
            angle  radar_heading - @radarstep * 0.5

            #invert the direction of the radar if we have seen something
            @radarstep*.5

            # mark that we have seen something
            @was_seen  rue

            # choose the direction to move to try to escape enemy hits
            dir  dist>700 ? 75 : (@dist < 400 ? 135 : (@dist < 550 ? 105 : 90) )
            @escape_to  ngle + (((time / 100) % 2 0) ? dir : -dir)

            # where we guess that the enemy is
            guess_x   + @dist * Math.cos( angle * (Math::PI / 180.0))
            guess_y   + @dist * -Math.sin( angle * (Math::PI / 180.0))

            #update the history, of the radar step is small enough
            prec  radarstep.abs
            if prec < 
                if (@h[2].t>time-8) and (prec<@h[2].prec) and
                                                @h[2].prec > 1
                # replace the last entry with a more accurate one
                @h[2]  istory.new( guess_x.to_f, guess_y.to_f,
                                                @time.to_f, prec.to_f )
                else
                # set the new last entry
                @h.shift
                @h << History.new( guess_x.to_f, guess_y.to_f,
                                                @time.to_f, prec.to_f )
                end
            end

            # - update the heuristic (obsolete)
                #fact1  .7
                #fact2  .3
                #@avx  avx * (1-fact1) + guess_x * fact1
                #@avy  avy * (1-fact1) + guess_y * fact1
                #@oldavx  oldavx * (1-fact2) + guess_x * fact2
                #@oldavy  oldavy * (1-fact2) + guess_y * fact2


                #if gun_heat 0
                #  fire 0.5
                #end
        end

    ##########################################################################
    #   Take the aim
    ##########################################################################

      # - obsolete heuristic aiming
       #advfact  dist * 0.008
       #shx  @avx - @oldavx)*advfact + @avx
       #shy  @avy - @oldavy)*advfact + @avy

      # take the aim linearly
        # guess the time at which the cannonball will reach the enemy
        sht  time + @dist / 30
        ratio  sht-@h[2].t) / (@h[2].t-@h[1].t).to_f
        # this is the delta position vector
        vx  h[2].x - @h[1].x;
        vy  h[2].y - @h[1].y;
        # this is the linear guess
        shx  h[2].x + vx*ratio
        shy  h[2].y + vy*ratio

      # add a correction to be better vrt non linear robots (optional)
        # this is the delta position vector
        dx  h[1].x - @h[0].x;
        dy  h[1].y - @h[0].y;
        ratio2  sht-@h[2].t) / (@h[1].t-@h[0].t).to_f
        # apply Gram-Schmidt to orthogonalize relatively to v[xy]
        fact  dx*vx+dy*vy) / (vx*vx+vy*vy).to_f
        latx  x - fact*vx;
        laty  y - fact*vy;
        # subtract a section of the orthogonal vector proportional to the time
        shx  hx - latx*ratio2
        shy  hy - laty*ratio2

      #calculate the angle at which the cannon should be aiming
        angle2  ath::atan2( -shy+y, shx-x ) * (180.0 / Math::PI);
        guntrn  urn_gun_to(angle2)

    ##########################################################################
    #   Reflect against the borders
    ##########################################################################
        if @target_angle.nil?
            if @x<Margin and (@heading>and @heading<'0)
                @target_angle  and(180 - MinRefl*2) + 270 + MinRefl
            elsif @y<Margin and (@heading<0)
                @target_angle  and(180 - MinRefl*2) + 180 + MinRefl
            elsif @x>(battlefield_width-Margin) and (@heading<or @heading>'0)
                @target_angle  and(180 - MinRefl*2) + 90 + MinRefl
            elsif @y>(battlefield_height-Margin) and (@heading>0)
                @target_angle  and(180 - MinRefl*2) + MinRefl
            end
        end

        turnangle  
        if @target_angle
            turnangle  urn_to(@target_angle)
            if turnangle 0
                @target_angle  il
            end
        else
            turnangle  urn_to(@escape_to)
        end

        oldflurrylurry #adjust
        @flurry
nd(2*FlurryAngle+1)-FlurryAngle
        @flurryif @radarstep.abs >20
        turn turnangle
        turn_gun guntrn+@flurry-oldflurry-turnangle
        #radar movement should be flurry independent
        turn_radar @radarstep-guntrn-@flurry+oldflurry
        #XXX: adjust aim when strafing

        accelerate(8)

        #fire small bullets
        fire 0.1

    if not events['got_hit'].empty?
      puts "GayRush> Ouch!"
    end
  end #tick
end #class
