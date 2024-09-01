proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  set_param xicom.use_bs_reader 1
  debug::add_scope template.lib 1
  set_property design_mode GateLvl [current_fileset]
  set_property webtalk.parent_dir F:/Teaching/NUS/TA/CG3207/Lab/__S1_AY2016-17/Work/Lab1/simple_count_Verilog/simple_count_Verilog.cache/wt [current_project]
  set_property parent.project_path F:/Teaching/NUS/TA/CG3207/Lab/__S1_AY2016-17/Work/Lab1/simple_count_Verilog/simple_count_Verilog.xpr [current_project]
  set_property ip_repo_paths f:/Teaching/NUS/TA/CG3207/Lab/__S1_AY2016-17/Work/Lab1/simple_count_Verilog/simple_count_Verilog.cache/ip [current_project]
  set_property ip_output_repo f:/Teaching/NUS/TA/CG3207/Lab/__S1_AY2016-17/Work/Lab1/simple_count_Verilog/simple_count_Verilog.cache/ip [current_project]
  add_files -quiet F:/Teaching/NUS/TA/CG3207/Lab/__S1_AY2016-17/Work/Lab1/simple_count_Verilog/simple_count_Verilog.runs/synth_1/simple_count.dcp
  read_xdc F:/Teaching/NUS/TA/CG3207/Lab/__S1_AY2016-17/Work/Lab1/simple_count_Verilog/simple_count_Verilog.srcs/constrs_1/imports/Desktop/Nexys4_Master.xdc
  link_design -top simple_count -part xc7a100tcsg324-1
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  catch {write_debug_probes -quiet -force debug_nets}
  opt_design 
  write_checkpoint -force simple_count_opt.dcp
  catch {report_drc -file simple_count_drc_opted.rpt}
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  catch {write_hwdef -file simple_count.hwdef}
  place_design 
  write_checkpoint -force simple_count_placed.dcp
  catch { report_io -file simple_count_io_placed.rpt }
  catch { report_utilization -file simple_count_utilization_placed.rpt -pb simple_count_utilization_placed.pb }
  catch { report_control_sets -verbose -file simple_count_control_sets_placed.rpt }
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force simple_count_routed.dcp
  catch { report_drc -file simple_count_drc_routed.rpt -pb simple_count_drc_routed.pb }
  catch { report_timing_summary -warn_on_violation -max_paths 10 -file simple_count_timing_summary_routed.rpt -rpx simple_count_timing_summary_routed.rpx }
  catch { report_power -file simple_count_power_routed.rpt -pb simple_count_power_summary_routed.pb }
  catch { report_route_status -file simple_count_route_status.rpt -pb simple_count_route_status.pb }
  catch { report_clock_utilization -file simple_count_clock_utilization_routed.rpt }
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}

start_step write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  write_bitstream -force simple_count.bit 
  catch { write_sysdef -hwdef simple_count.hwdef -bitfile simple_count.bit -meminfo simple_count.mmi -ltxfile debug_nets.ltx -file simple_count.sysdef }
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
}

