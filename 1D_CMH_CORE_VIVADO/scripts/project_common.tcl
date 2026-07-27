set ::CMH_SCRIPT_DIR [file dirname [file normalize [info script]]]

proc cmh_root {} {
    return [file normalize [file join $::CMH_SCRIPT_DIR ..]]
}

proc cmh_parse_args {} {
    global argv
    set cfg [dict create \
        branches 9 \
        rho_re 0.32 \
        rho_im -0.33 \
        sigma_re -1.80 \
        sigma_im -0.90 \
        z0_re 0.10 \
        z0_im 0.20]
    set names {branches rho_re rho_im sigma_re sigma_im z0_re z0_im}
    for {set i 0} {$i < [llength $argv] && $i < [llength $names]} {incr i} {
        dict set cfg [lindex $names $i] [lindex $argv $i]
    }
    return $cfg
}

proc cmh_clear_python_environment {} {
    set saved [dict create]
    foreach name {PYTHONHOME PYTHONPATH} {
        if {[info exists ::env($name)]} {
            dict set saved $name $::env($name)
            unset ::env($name)
        }
    }
    return $saved
}

proc cmh_restore_python_environment {saved} {
    foreach name {PYTHONHOME PYTHONPATH} {
        if {[dict exists $saved $name]} {
            set ::env($name) [dict get $saved $name]
        } elseif {[info exists ::env($name)]} {
            unset ::env($name)
        }
    }
}

proc cmh_exec_clean {cmd} {
    set saved [cmh_clear_python_environment]
    set status [catch {exec {*}$cmd 2>@1} result options]
    cmh_restore_python_environment $saved
    if {$status} {
        return -options $options $result
    }
    return $result
}

proc cmh_python_candidates {} {
    set candidates {}
    if {[info exists ::env(CMH_PYTHON)] && $::env(CMH_PYTHON) ne ""} {
        lappend candidates [list $::env(CMH_PYTHON)]
    }
    if {$::tcl_platform(platform) eq "windows"} {
        set launcher [auto_execok py]
        if {$launcher ne ""} {
            lappend candidates [list $launcher -3]
        }
    }
    foreach name {python3 python} {
        set executable [auto_execok $name]
        if {$executable ne ""} {
            lappend candidates [list $executable]
        }
    }
    return $candidates
}

proc cmh_find_python {} {
    set failures {}
    foreach candidate [cmh_python_candidates] {
        set probe [concat $candidate [list -E -c {import sys, re; print(sys.executable); print(sys.version)}]]
        set status [catch {cmh_exec_clean $probe} result]
        if {!$status} {
            puts "Using external Python: [lindex [split $result \n] 0]"
            return $candidate
        }
        lappend failures "$candidate => $result"
    }
    set details [join $failures "\n"]
    error "A working external Python 3 interpreter was not found. Install Python 3 with the Windows py launcher or set ::env(CMH_PYTHON) to the full path of python.exe. Candidate failures:\n$details"
}

proc cmh_run_generator {root cfg} {
    set generator [file join $root scripts configure_core.py]
    set python_cmd [cmh_find_python]
    set cmd [concat $python_cmd [list \
        -E \
        -B \
        $generator \
        --branches [dict get $cfg branches] \
        --rho-re [dict get $cfg rho_re] \
        --rho-im [dict get $cfg rho_im] \
        --sigma-re [dict get $cfg sigma_re] \
        --sigma-im [dict get $cfg sigma_im] \
        --z0-re [dict get $cfg z0_re] \
        --z0-im [dict get $cfg z0_im]]]
    puts "Running generator: $cmd"
    puts [cmh_exec_clean $cmd]
}

proc cmh_add_sources {root} {
    set rtl [file join $root rtl]
    add_files -norecurse [list \
        [file join $rtl cmh_config.vh] \
        [file join $rtl cmul_q824_pipe.v] \
        [file join $rtl cfold_mod1_q824.v] \
        [file join $rtl cmh_arg_sector_cordic.v] \
        [file join $rtl cmh_branch_coeff_rom.v] \
        [file join $rtl cmh_parallel_core.v] \
        [file join $rtl cmh_top.v]]
    set_property include_dirs [list $rtl] [current_fileset]
}

proc cmh_create_project {root cfg top_name} {
    set m [dict get $cfg branches]
    set build_dir [file join $root build cmh_m${m}]
    file mkdir $build_dir
    create_project -force cmh_m${m} $build_dir -part xc7z020clg400-1
    set_property target_language Verilog [current_project]
    cmh_add_sources $root
    set_property top $top_name [current_fileset]
    update_compile_order -fileset sources_1
    return $build_dir
}
