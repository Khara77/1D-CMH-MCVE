source [file join [file dirname [info script]] project_common.tcl]
set root [cmh_root]
set cfg [cmh_parse_args]
cmh_run_generator $root $cfg
set build_dir [cmh_create_project $root $cfg cmh_top]
puts "Created portable Vivado project: $build_dir"
puts "Open the .xpr file in this directory."
