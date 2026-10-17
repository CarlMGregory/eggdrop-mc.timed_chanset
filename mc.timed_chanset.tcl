##
# Timed Chanset v1.0 by MC_8 - Carl M. Gregory <gregory@worldinter.net>
#
# My SVS Website - http://mc.purehype.net/
#
# If you have any questions/comments/suggestions/ideas, go ahead
#  and email me.
##

##
# This script will perform chanset commands at particular times.  This was
# origional built for my Spam Check script, to enable the script for particular
# channels but only during peek hours.  But I realized this idea could be
# utalized effecently with other things as well.
##

##
# History
##
# v1.0 (03.07.01)
#  MC_8 - Added an database updater from v0.0.0.2 -> v0.0.0.3 (auto runs on load)
#  MC_8 - Added min as well as hour to do the timed chanset command.
#  MC_8 - Added veriable to specify where & what the database is to
#         be saved to.
#  MC_8 - Added veriable to specify what flaged users can access the dcc commands.
#  MC_8 - Removed ability to set tchansets within the script, can now be done
#         via dcc commands.
#  MC_8 - Added dcc commands:  +tchanset -tchanset chansets
#  MC_8 - Marek - Fixed `invalid command name "mc:tcs:init"'
#  MC_8 - Marek - Inital Beta Release.
##

##
# Commands (dcc)
##
# +tchanset <time(hh:mm)[time(hh:mm)[...]]> [<#>channel] <chanset modes>
# -tchanset <time(hh:mm)[time(hh:mm)[...]]> [<#>channel] <chanset modes>
# tchansets [<#>channel]
# 
#  Time is in military hour format, 0 is midnight .. 23 is 11pm.
#  You can specify more than one time if you seperate each
#  hour with a comma.
#
#  Only put one chanset mode per tchanset.  If you want to do more
#  than one chanset mode change, then just create a new tchanset
#  line.
#
# Once an hour, it checks what you have here, if the hour matches
# then it will perform the chanset mode change.
#
# In the following example, the script will set #ontopwarez to
# chanset mode +spamcheck +spamcycle at 3am and 1pm.
# The script will also set #ontopwarez to -spamcheck -spamcycle
# at 5am and midnight.  So, that means spamcheck and spamcycle
# will be on from 3am-5am and 1pm-midnight, any other times it
# would be turned off.
#  DCC with bot>  .+tchanset 03:00,13:00 #ontopwarez +spamcheck
#  DCC with bot>  .+tchanset 03:00,13:00 #ontopwarez +spamcycle
#  DCC with bot>  .+tchanset 05:00,00:00 #ontopwarez -spamcheck
#  DCC with bot>  .+tchanset 05:00,00:00 #ontopwarez -spamcycle
##

##
# Settings
##

# What flaged users are allowed to perform the .tchanset command?
#  Flag format goes in <global>|<channel> format.
set mc_tcs(access) m|m

# This script keeps all it's information in a database file, what
# do you want to call this file?
set mc_tcs(database) "tchanset.dat"

## MC SVS (Script Version Server) v1.2 ##
# Do you want the bot to connection to MC_8's SVS to see if there are newer versions
# of this script avilable?  It will only tell you -- It's up to you to get the newest
# version (I decided not to auto update the code, there may be new features in the
# newest script that may require your attention).
# 0=no/1=yes
set mc_tcs(svs:enabled) 1

# Once a day the script will check with the SVS -- this specifies when
# that should happen.  The setting should be the hour (military).
# examples:
#  set mc_tcs(svs:check) 0  ;#This is at Midnight
#  set mc_tcs(svs:check) 5  ;#This is at 5am
#  set mc_tcs(svs:check) 13  ;#This is at 1pm
#  set mc_tcs(svs:check) 23  ;#This is at 11pm
set mc_tcs(svs:check) 3

# Upon finding a newer version, who do you want to notify via note?
# Only the admin of the bot should really be worried about these notes,
# there the ones that keep everything up to par on the bots.
# Seperate each user with a " " (space).
set mc_tcs(svs:notify) "MC_8"

# Do you want even beta version notified to whomever you have set?  Or just
# stable releases of the script?
#  0 = Tell me about all version, even beta versions.
#  1 = Just tell me about new stable versions.
set mc_tcs(svs:stableonly) 0



## Coding starts here, please do not proceed in editing past this point.

set mc_tcs(version) v1.0
set mc_tcs(svs:script) "timed-chanset 001000000000"
set mc_tcs(svs:server) "mc.purehype.net 8085"

bind dcc - +tchanset *mc:tcs:dcc:+tchanset
proc *mc:tcs:dcc:+tchanset {hand idx args} {mc:tcs:tchanset add $hand $idx [join $args]}
bind dcc - -tchanset *mc:tcs:dcc:-tchanset
proc *mc:tcs:dcc:-tchanset {hand idx args} {mc:tcs:tchanset remove $hand $idx [join $args]}

bind dcc - tchansets *mc:tcs:dcc:tchansets
proc *mc:tcs:dcc:tchansets {hand idx args} {
 global mc_tcs;set args [join $args]
 set time [lindex $args 0]
 if {[string index $args 0] == "#"} {
  set chan [string tolower $args]
 } {set chan global}

 if {($chan != "global") && (![validchan $chan])} {
  putdcc $idx "Timed Chanset:  Invalid channel: tchanset $chan"
  return 0
 }
 if {$chan == "global"} {
  set matchattr "[lindex [split $mc_tcs(access) |] 0]"
  set access [lindex [split $mc_tcs(access) |] 0]
  set access_chan ""
  set s global
  set x " global"
 } {
  set matchattr "[lindex [split $mc_tcs(access) |] 0] $chan"
  set access $mc_tcs(access)
  set access_chan $chan
  set s "$chan's"
  set x ""
 }
 if {![matchattr $hand $matchattr]} {
  putdcc $idx "You do not have access to view $s tchansets, requires$x $access access."
  putcmdlog "#$hand# Denied (no access):  tchansets$x"
  return 0
 }
 if {![file exists $mc_tcs(database)]} {close [open $mc_tcs(database) w]}
 set io [open $mc_tcs(database) r];set i 0
 while {![eof $io]} {
  set gets [gets $io]
  if {($chan != "global") && ([lindex $gets 1] != $chan)} {continue}
  if {[join $gets] == ""} {continue}
  putdcc $idx "[join [lindex $gets 0] ,] [lindex $gets 1] [lindex $gets 2]";incr i 1
 };close $io
 putdcc $idx ""
 if {$i == "1"} {set s ""} {set s "'s"}
 if {$chan == "global"} {set c "globally"} {set c "for $chan"}
 putdcc $idx "$i Timed Chanset$s found $c."
 if {$chan == "global"} {set x ""} {set x " $chan"}
 putcmdlog "#$hand# tchansets$x"
 return 0
}

proc mc:tcs:tchanset {method hand idx args} {
 global mc_tcs;set args [join $args]
 set time [lindex $args 0]
 if {[string index [lindex $args 1] 0] == "#"} {
  set chan [string tolower [lindex $args 1]]
  set chanset [lrange $args 2 e]
 } {
  set chan [string tolower [lindex [console $idx] 0]]
  set chanset [lrange $args 1 e]
 };set args "$time $chan $chanset"
 if {![validchan $chan]} {
  putdcc $idx "Timed Chanset:  Invalid channel: tchanset $args"
  return 0
 }
 if {![matchattr $hand $mc_tcs(access) $chan]} {
  putdcc $idx "You do not have access to this command, requires $mc_tcs(access) access."
  if {$method == "add"} {
   set m +;set s " $args"
  } elseif {$method == "remove"} {
   set m -;set s " $args"
  }
  putcmdlog "#$hand# Denied (no access):  ${m}tchanset$s"
  return 0
 }
 if {[lindex $args 2] == ""} {
  if {$method == "add"} {
   set m +;set s " $args"
  } elseif {$method == "remove"} {
   set m -;set s " $args"
  }
  putdcc $idx "Timed Chanset:  Error in: ${m}tchanset$s"
  putdcc $idx "                Syntax: ${m}tchanset <time> \[channel\] <chanset mode>"
  return 0
 }
 set t ""
 foreach tim [split $time ,] {
  set hour [lindex [split $tim :] 0]
  if {($hour > 23) || ($hour < 0)} {set hour 00}
  if {[string length $hour] == 1} {set hour 0$hour}
  set hour [string range $hour 0 1]
  set min [lindex [split $tim :] 1]
  if {($min > 59) || ($min < 0)} {set min 00}
  if {[string length $min] == 1} {set min 0$min}
  set min [string range $min 0 1]
  set t "$t $hour:$min"
 };set t [string trim $t]
 switch -- $method {
  add {
   set error [mc:tcs:database add "{$t} $chan {$chanset}"]
   if {$error == "1"} {
    putdcc $idx "Timed Chanset:  Record already exists:  $args"
   } {
    putdcc $idx "Timed Chanset:  Successfully added modes { $chanset } on $chan at [join $t ,]."
    putcmdlog "+tchanset $args"
   }
   return 0
  }
  remove {
   set error [mc:tcs:database remove "{$t} $chan {$chanset}"]
   if {$error == "1"} {
    putdcc $idx "Timed Chanset:  No such record:  $args"
   } {
    putdcc $idx "Timed Chanset:  Successfully removed modes { $chanset } on $chan at [join $t ,]."
    putcmdlog "-tchanset $chan $chanset"
   }
   return 0
  }
 }
}

proc mc:tcs:database {method args} {
 global mc_tcs
 set args [join $args];set time [lindex $args 0]
 set chan [lindex $args 1];set chanset [lindex $args 2]
 if {![file exists $mc_tcs(database)]} {close [open $mc_tcs(database)]}
 switch -- $method {
  add {
   set io [open $mc_tcs(database) r];set i 0
   while {![eof $io]} {
    set gets [gets $io]
    if {[string match "{$time} $chan {$chanset}" $gets]} {set i 1;break}
   };close $io
   if {$i} {return 1}
   set io [open $mc_tcs(database) a];puts $io "{$time} $chan {$chanset}";close $io
   return 0
  }
  remove {
   set io [open $mc_tcs(database) r];set database "";set return 1
   while {![eof $io]} {
    set gets [gets $io]
    if {![string match "{$time} $chan {$chanset}" $gets]} {
     set database "$database {$gets}"
    } {set return 0}
   }
   close $io;set database [string trim $database]
   if {!$return} {
    set io [open $mc_tcs(database) w];foreach out $database {puts $io $out};close $io
   };return $return
  }
 }
}

bind time - "* * * * *" mc:tcs:time
proc mc:tcs:time {min hour day month year} {
 global mc_tcs
 if {![file exists $mc_tcs(database)]} {close [open $mc_tcs(database) w]}
 set io [open $mc_tcs(database) r]
 while {![eof $io]} {
  set tcs [gets $io]
  if {![string match "* $hour:$min *" " [lindex $tcs 0] "]} {continue}
  if {![validchan [lindex $tcs 1]]} {
   putlog "Timed Chanset:  Invalid channel: tchanset [join [lindex $tcs 0] ,] [lindex $tcs 1] [lindex $tcs 2]"
   continue
  }
  if {[llength [lindex $tcs 2]] >= 2} {
   channel set [lindex $tcs 1] [lindex [lindex $tcs 2] 0] [string trim [lindex [lindex $tcs 2] 1]]
   putlog "Timed Chanset:  Successfully set modes { [lindex [lindex $tcs 2] 0] { [string trim [lindex [lindex $tcs 2] 1]] } } on [lindex $tcs 1]."
  } {
   channel set [lindex $tcs 1] [lindex $tcs 2]
   putlog "Timed Chanset:  Successfully set modes { [lindex $tcs 2] } on [lindex $tcs 1]."
  }
 };close $io
}

# Database update, 0.0.0.2 -> 0.0.0.3
if {![file exists $mc_tcs(database)]} {close [open $mc_tcs(database) w]}
set io [open $mc_tcs(database) r];set temp "";set needsupdate 0
while {![eof $io]} {
 set tcs [gets $io]
 if {[join [join [join $tcs]]] == ""} {set needsupdate 1;continue}
 if {[string match *:* [lindex $tcs 0]]} {
  set temp "$temp {$tcs}"
 } {
  set times_temp ""
  foreach times [lindex $tcs 0] {
   if {![string match *:* $times]} {set times "${times}:00";set needsupdate 1}
   set times_temp "$times_temp $times"
  };set times_temp [string trim $times_temp]
  set temp "$temp {{$times_temp} [lindex $tcs 1] {[lindex $tcs 2]}}"
 } 
};set temp [string trim $temp];close $io
if {$needsupdate} {
 set io [open $mc_tcs(database) w];foreach out $temp {puts $io $out};close $io
}
## ^^

if {$mc_tcs(svs:enabled)} {
 if {($mc_tcs(svs:check) > "23") || ($mc_tcs(svs:check) < "0")} {set mc_tcs(svs:check) 00}
 if {[string length $mc_tcs(svs:check)] == "1"} {set mc_tcs(svs:check) 0$mc_tcs(svs:check)}
 if {$mc_tcs(svs:stableonly)} {
  set mc_tcs(svs:script) [string range $mc_tcs(svs:script) 0 [expr [string length $mc_tcs(svs:script)]-4]]999
 }
 catch {unbind time - "00 $mc_tcs(svs:oldcheck) * * *" mc:tcs:svs:time}
 set mc_tcs(svs:oldcheck) $mc_tcs(svs:check)
 bind time - "00 $mc_tcs(svs:check) * * *" mc:tcs:svs:time
 proc mc:tcs:svs:time {min hour day month year} {
  global mc_tcs
  catch {control [connect [lindex $mc_tcs(svs:server) 0] [lindex $mc_tcs(svs:server) 1]] mc:tcs:svs:interface}
 }
}
proc mc:tcs:svs:interface {idx args} {
 global mc_tcs;set args [join $args]
 switch -- [lindex $args 0] {
  "" {return 1}
  000 {putdcc $idx q}
  002 {putdcc $idx [lindex $mc_tcs(svs:script) 0]}
  003 {
   set args [lrange $args 1 e]
   if {[lindex $args 0] != [lindex $mc_tcs(svs:script) 0]} {return 0}
   putdcc $idx q
   if {[lindex $args 1] > [lindex $mc_tcs(svs:script) 1]} {
    set note [mc:tcs:svs:replace [lindex $args 7] "%0 {[lindex $args 0]} %1 {[lindex $args 1]} %2 {[lindex $args 2]}"]
    set note [mc:tcs:svs:replace $note "%3 {[lindex $args 3]} %4 {[lindex $args 4]} %5 {[lindex $args 5]}"]
    set note [mc:tcs:svs:replace $note "%6 {[lindex $args 6]} %8 {[lindex $args 8]} %version {$mc_tcs(version)}"]
    set note [mc:tcs:svs:replace $note "%9 {[lindex $args 9]} %10 {[lindex $args 10]} %11 {[lindex $args 11]}"]
    set note [mc:tcs:svs:replace $note "%12 {[lindex $args 12]} %13 {[lindex $args 13]} %14 {[lindex $args 14]}"]
    set note [mc:tcs:svs:replace $note "%15 {[lindex $args 15]} %16 {[lindex $args 16]} %17 {[lindex $args 17]}"]
    set note [mc:tcs:svs:replace $note "%18 {[lindex $args 18]} %19 {[lindex $args 19]} %20 {[lindex $args 20]}"]
    foreach notify [join [split $mc_tcs(svs:notify) ",;"]] {
     set outnote [mc:tcs:svs:replace $note "%nick {$notify}"]
     if {[string match "*$outnote*" "[notes $notify -[notes $notify]]"]} {
      set cont 0
      foreach unote [notes $notify -[notes $notify]] {
       if {$outnote == [lindex $unote 2]} {set cont 1;break}
      };if {$cont} {continue}
     }
     switch -- [sendnote SVS $notify $outnote] {
      0 {putlog "MC SVS for [lindex $mc_tcs(svs:script) 0] had some errors updating $notify on current version of script; unknown reason!"}
      3 {putlog "MC SVS for [lindex $mc_tcs(svs:script) 0] had some errors updating $notify on current version of script; notebox too full!"}
     }
    }
   }
  }
 };return 0
}
proc mc:tcs:svs:replace {string subs} {
 if {[llength $subs] == "1"} {set subs [lindex $subs 0]}
 for {set i 0} {[lindex $subs $i] != ""} {incr i 2} {
  regsub -all -- [lindex $subs $i] $string [lindex $subs [expr $i+1]] string
 } ; return $string
}

putlog "Timed Chanset $mc_tcs(version) by MC_8 loaded."