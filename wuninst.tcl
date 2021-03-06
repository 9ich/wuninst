#!/bin/sh
# \
exec wish "$0" -- "$@"

package require Tk
package require registry

focus -force .
wm title . "wuninst"

ttk::treeview .t -columns "a b c d" -selectmode browse
grid .t -column 0 -row 0 -columnspan 3 -sticky nwes

ttk::frame .f
grid .f -row 0 -row 1

ttk::button .f.o -text "Open Location" -comm {openloc [.t selection]}
grid .f.o -column 1 -row 0 -columnspan 1

ttk::button .f.m -text "Modify" -comm {modify [.t selection]}
grid .f.m -column 2 -row 0 -columnspan 1

ttk::button .f.rp -text "Repair" -comm {repair [.t selection]}
grid .f.rp -column 3 -row 0 -columnspan 1

ttk::button .f.u -text "Uninstall" -comm {uninstall [.t selection]}
grid .f.u -column 4 -row 0 -columnspan 1

bind .t <<TreeviewSelect>> {
	set app [lindex $::apps [.t selection]]
	.f.u state [enablestate [string equal [lindex $app 1] ""]]
	.f.m state [enablestate [string equal [lindex $app 2] ""]]
	.f.rp state [enablestate [string equal [lindex $app 3] ""]]
	.f.o state [enablestate [string equal [lindex $app 4] ""]]
}

proc enablestate {v} {
	return [expr {$v ? "disabled" : "!disabled"}]
}

grid columnconfigure . 0 -weight 1
grid rowconfigure    . 0 -weight 1

proc sortby {tree col direction} {
	set data {}
	foreach row [$tree children {}] {
		lappend data [list [$tree set $row $col] $row]
	}

	set dir [expr {$direction ? "-decreasing" : "-increasing"}]
	set r -1

	foreach info [lsort -dictionary -index 0 $dir $data] {
		$tree move [lindex $info 1] {} [incr r]
	}

	set cmd [list sortby $tree $col [expr {!$direction}]]
	$tree heading $col -command $cmd
}

proc openloc {i} {
	set app [lindex $::apps $i]
	set loc [lindex $app 4]
	puts $loc
	exec cmd /c explorer [string trim $loc "\\\""] &
}

proc modify {i} {
	set app [lindex $::apps $i]
	set m [lindex $app 2]
	exec cmd /c explorer [string trim $m "\\\""] &
}

proc repair {i} {
	set app [lindex $::apps $i]
	set r [lindex $app 3]
	exec cmd /c explorer [string trim $r "\\\""] &
}

proc uninstall {i} {
	set app [lindex $::apps $i]
	set u [lindex $app 1]
	set name [lindex $app 0]
	set ans [tk_messageBox -type yesno -icon question -title "Confirm" -message "Really remove $name?"]
	switch -- $ans {
	yes {
		exec cmd /c [string trim $u "\\\""] &
		.t delete $i
	}
	no {}
	}
}

set apps {}

proc mklist {} {
	set i 0
	set keys [registry keys HKEY_LOCAL_MACHINE\\software\\microsoft\\windows\\currentversion\\uninstall]
	foreach k $keys {
		set path HKEY_LOCAL_MACHINE\\software\\microsoft\\windows\\currentversion\\uninstall\\$k
		if {[catch {set name [registry get $path "DisplayName"]} errmsg]} {
			continue
		}
		
		set uninst ""
		set mod ""
		set repair ""
		set version ""
		set publisher ""
		set date ""
		set loc ""
		
		if {[catch {set uninst [registry get $path "UninstallString"]}]} {
			catch {set uninst [registry get $path "UninstallPath"]}
		}
		catch {set mod [registry get $path "ModifyPath"]}
		catch {set repair [registry get $path "RepairPath"]}
		catch {set version [registry get $path "DisplayVersion"]}
		catch {set publisher [registry get $path "Publisher"]}
		catch {set date [registry get $path "InstallDate"]}
		catch {set loc [registry get $path "InstallLocation"]}
				
		lappend ::apps [list $name $uninst $mod $repair $loc]
		.t insert {} end -id $i -image {} -values [list $name $publisher $version $date]
		incr i
	}
}

proc refresh {} {
	mklist
	sortby .t 0 0
}

refresh

.t selection set 0

# hide the -text column
.t column "#0" -width 0 -minwidth 0

.t column 0 -width 250
.t column 1 -width 150
.t column 2 -width 100
.t column 3 -width 70
.t configure -show ""
puts [.t item 0 -text]
