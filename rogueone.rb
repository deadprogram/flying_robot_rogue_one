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
  define "MAX_SPEED 127"
  software_serial 10, 3, :as => :main_thrusters, :rate => 38400
  output_pin 4, :as => :main_thrusters_reset
  @left_motor = "2, byte"
  @right_motor = "3, byte"
  @forward = "1, byte"
  @reverse = "0, byte"
  @direction = "1, byte"
  @left_direction = "1, byte"
  @right_direction = "1, byte"
  @left_motor_speed = "0, long"
  @right_motor_speed = "0, long"
  @deflection = "0, byte"
  @deflection_percent = "0, long"
  @deflection_val = "0, long"
  @autopilot_update_frequency = "500, unsigned long"
  @last_autopilot_update = "0, unsigned long"
  
  # just to make something blink  
  output_pin 13, :as => :led
  
  # read battery voltage, to protect our expensive LiPo from going below minimum power.
  input_pin 0, :as => :battery
  
  # test for IR beacon
  input_pin 6, :as => :ir_front
  input_pin 7, :as => :ir_right
  input_pin 8, :as => :ir_rear
  input_pin 9, :as => :ir_left  
   
  # xbee used for communication with ground station
  serial_begin :rate => 19200
  
  # main command loop, required for any arduino program
  def loop
    be_flying_robot
    battery_test
    update_ir_receiver(ir_front, ir_right, ir_rear, ir_left)
    handle_autopilot_update
    
    process_command
    servo_refresh
  end

  # flying robot interface methods
  def hail
    serial_println "Roger"
  end
  
  def status
    serial_println "Status: operational"
    check_battery_voltage
    check_compass
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
    if current_command_instrument == 'b'
      check_battery_voltage
    end
    if current_command_instrument == 'c'
      check_compass
    end
    if current_command_instrument == 'i'
      check_ir
    end
  end
  
  def autopilot
    if current_command_autopilot == '0'
      # autopilot cancel, so we should shutoff motors
      throttle_speed = 0
      set_thrusters
      serial_println "Autopilot Is Off"
    end
    
    if current_command_autopilot == '1'
      # follow IR beacon
      autopilot_on
      serial_println "Autopilot Is On"
    end
  end
  
  def handle_autopilot_update
    if is_autopilot_on && millis() - @last_autopilot_update > @autopilot_update_frequency
      if current_command_autopilot == '1'
        if current_ir_beacon_direction == 0
          @left_motor_speed = 0
          @right_motor_speed = 0
          @left_direction = @forward
          @right_direction = @forward
        end
        if current_ir_beacon_direction == 1
          @left_motor_speed = 0
          @right_motor_speed = 0
          @left_direction = @forward
          @right_direction = @forward
        end
        if current_ir_beacon_direction == 2
          @left_motor_speed = MAX_SPEED / 10
          @left_direction = @forward
          
          @right_motor_speed = MAX_SPEED / 10
          @right_direction = @reverse
        end
        if current_ir_beacon_direction == 3
          @left_motor_speed = MAX_SPEED / 10
          @left_direction = @forward
          
          @right_motor_speed = MAX_SPEED / 10
          @right_direction = @reverse
        end
        if current_ir_beacon_direction == 4
          @left_motor_speed = MAX_SPEED / 10
          @left_direction = @reverse
          
          @right_motor_speed = MAX_SPEED / 10
          @right_direction = @forward
        end
        
        activate_thrusters
      end
    
      @last_autopilot_update = millis()
    end
  end
  
  # motor control
  def set_thrusters
    if current_throttle_direction == 'f'
      @left_direction = @forward
      @right_direction = @forward
    else
      @left_direction = @reverse
      @right_direction = @reverse
    end
    
    calculate_motor_speeds
    activate_thrusters
  end
  
  def activate_thrusters
    main_thrusters_reset.qik_init(main_thrusters)
    main_thrusters.qik_send_command(@left_motor, @left_direction, @left_motor_speed)
    main_thrusters.qik_send_command(@right_motor, @right_direction, @right_motor_speed)
  end
  
  def calculate_motor_speeds
    if current_rudder_direction == 'c'
      @left_motor_speed = current_throttle_speed / 100.0 * MAX_SPEED
      @right_motor_speed = current_throttle_speed / 100.0 * MAX_SPEED
    end
    if current_rudder_direction == 'l'
      @left_motor_speed = adjusted_throttle_speed / 10000
      @right_motor_speed = current_throttle_speed / 100.0 * MAX_SPEED
    end
    if current_rudder_direction == 'r'
      @left_motor_speed = current_throttle_speed / 100.0 * MAX_SPEED
      @right_motor_speed = adjusted_throttle_speed / 10000
    end
  end
  
  def adjusted_throttle_speed
    @deflection_percent = (current_rudder_deflection * 100 / 90)
    @deflection_val = 100 - @deflection_percent
    return @deflection_val * current_throttle_speed * MAX_SPEED
  end
  
  # instruments
  def check_battery_voltage
    serial_print "Battery voltage: "
    serial_println int(battery.voltage)
  end

  def check_compass
    prepare_compass
    read_compass
    serial_print "Compass heading: "
    serial_print heading
    serial_print "."
    serial_println heading_fractional
  end
  
  def check_ir   
    serial_print "IR: "
    serial_println current_ir_beacon_direction
  end
end
