# Rogue One - An Unmanned Aerial Vehicle that uses the flying_robot command set for Ruby Arduino Development
# Written by Ron Evans (http://deadprogrammersociety.com) for the flying_robot project
#
# Heavily influenced by the Blimpduino project, thanks for the inspiration!
#
class Rogueone < ArduinoSketch
  # two-wire interface to HMC6352 compass module
  output_pin 19, :as => :wire, :device => :i2c, :enable => :true
  
  # vectoring servo
  output_pin 11, :as => :vectoring_servo, :device => :servo
  
  # softwareserial interface for pololu micro serial controller used for main thrusters
  software_serial 10, 3, :as => :main_thrusters
  output_pin 4, :as => :main_thrusters_reset
  @left_motor = "2, byte"
  @right_motor = "3, byte"
  @forward = "1, byte"
  @reverse = "0, byte"
  @direction = "1, byte"
  @left_motor_speed = "0, byte"
  @right_motor_speed = "0, byte"
  @deflection = "0, byte"
    
  output_pin 13, :as => :led
  
  # xbee used for communication with ground station
  serial_begin :rate => 19200
  
  # main command loop, required for any arduino program
  def loop
    be_flying_robot
    process_command
    servo_refresh
  end

  # flying robot interface, implement these for your own hardware set
  def hail
    serial_println "Roger"
  end
  
  def status
    serial_println "Status: operational"
  end
  
  def elevators
    print_current_command("Elevators", current_elevator_deflection)
    if current_elevator_direction == 'c'
      @deflection = 90
    end
    if current_elevator_direction == 'u'
      @deflection = 90 - current_elevator_deflection
    end
    if current_elevator_direction == 'd'
      @deflection = 90 + current_elevator_deflection
    end

    if @deflection < 45
      @deflection = 45
    end
    if @deflection > 135
      @deflection = 135
    end
    
    servo_refresh
    vectoring_servo.position @deflection
  end
    
  def rudder
    print_current_command("Rudder", current_rudder_deflection)
    set_thrusters
  end
  
  def throttle
    print_current_command("Throttle", current_throttle_speed)
    set_thrusters
  end
    
  def instruments
    prepare_compass
    read_compass
    serial_print "Instruments command - compass heading:"
    serial_print heading
    serial_print "."
    serial_println heading_fractional
  end
  
  def set_thrusters
    if current_command_direction == 'f'
      @direction = @forward
    else
      @direction = @reverse
    end
    
    calculate_motor_speeds
    main_thrusters_reset.mc_init
    main_thrusters.mc_send_command(@left_motor, @direction, @left_motor_speed)
    main_thrusters.mc_send_command(@right_motor, @direction, @right_motor_speed)
  end
  
  def calculate_motor_speeds
    if current_rudder_direction == 'c'
      @left_motor_speed = current_throttle_speed / 100.0 * 127
      @right_motor_speed = current_throttle_speed / 100.0 * 127
    end
    if current_rudder_direction == 'l'
      @left_motor_speed = adjusted_throttle_speed / 100.0 * 127
      @right_motor_speed = current_throttle_speed / 100.0 * 127
    end
    if current_rudder_direction == 'r'
      @left_motor_speed = current_throttle_speed / 100.0 * 127
      @right_motor_speed = adjusted_throttle_speed / 100.0 * 127
    end
  end
  
  def adjusted_throttle_speed
    return (current_rudder_deflection / 90.0) * current_throttle_speed ;
  end
end
