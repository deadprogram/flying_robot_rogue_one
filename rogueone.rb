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
    
  output_pin 13, :as => :led
  
  # xbee used for communication with ground station
  serial_begin :rate => 9600
  
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
    print_current_command("Elevators")
    servo_refresh
    vectoring_servo.position current_command_value
  end
    
  def rudder
    print_current_command("Rudder")
  end
  
  def throttle
    print_current_command("Throttle")
    
    mc_init(main_thrusters_reset)
    if current_command_direction == 'f'
      mc_send_command(main_thrusters, @left_motor, @forward, current_command_value)
      mc_send_command(main_thrusters, @right_motor, @forward, current_command_value)
    end
    if current_command_direction == 'r'
      mc_send_command(main_thrusters, @left_motor, @reverse, current_command_value)
      mc_send_command(main_thrusters, @right_motor, @reverse, current_command_value)
    end
  end
    
  def instruments
    prepare_compass
    read_compass
    serial_print "Instruments command - compass heading:"
    serial_print heading
    serial_print "."
    serial_println heading_fractional
    #serial_println current_command_instrument
  end
end
