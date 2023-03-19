#создаем симулятор
set ns [new Simulator]

#Открыть трейс-файл для nam
set nf [open ns2-4.nam w]
$ns namtrace-all $nf 

#создаем узлы

set node_(r0) [$ns node]
set node_(r1) [$ns node]
$node_(r0) color "red"
$node_(r1) color "red"
$node_(r0) label "Router_with_red"
$node_(r0) shape "square"
$node_(r1) shape "square"

set N 44
for {set i 2} {$i < $N-1} {incr i} {
   set node_s($i) [$ns node]
   if {[expr $i % 2] < 1} {
	$node_s($i) color "blue"
	$node_s($i) label "src_tcp/ftp"}
}

#Создаем линки
for {set j 3} {$j < $N-1} {incr j 2} {
   $ns duplex-link $node_s($j) $node_(r1) 100Mb 20ms DropTail
}
for {set k 2} {$k < $N-1} {incr k 2} {
   $ns duplex-link $node_s($k) $node_(r0) 100Mb 20ms DropTail
}

$ns duplex-link $node_(r0) $node_(r1) 20Mb 15ms RED
$ns simplex-link $node_(r1) $node_(r0) 15Mb 20ms DropTail

#Задаем лимит очереди
$ns queue-limit $node_(r0) $node_(r1) 300
$ns queue-limit $node_(r1) $node_(r0) 300

#Строим соединение
set k 1
set z 3
for { set t 2} {$t < $N-2} {incr t 2} {
$ns color $t green
set tcp($k) [$ns create-connection TCP/Reno $node_s($t) TCPSink $node_s($z) $k]
$tcp($k) set window_ 32
set ftp($k) [$tcp($k) attach-source FTP]
incr k
incr z 2
}

#Расположение в nam
$ns duplex-link-op $node_(r0) $node_(r1) orient right
$ns simplex-link-op $node_(r1) $node_(r0) orient left
$ns duplex-link-op $node_(r0) $node_(r1) queuePos 0
$ns simplex-link-op $node_(r1) $node_(r0) queuePos 0



set P 30
set G 15
for {set v 2} {$v < $G-1} {incr v 2} {
   $ns duplex-link-op $node_s($v) $node_(r0) orient right-up
}
for {set v G} {$v < $P-1} {incr v 2} {
   $ns duplex-link-op $node_s($v) $node_(r0) orient right
}
for {set v P} {$v < $N-1} {incr v 2} {
   $ns duplex-link-op $node_s($v) $node_(r0) orient right-down
}
for {set j 3} {$j < $N-1} {incr j 2} {
   $ns duplex-link-op $node_s($j) $node_(r1) orient left
}

#Window
set windowVsTime [open WindowVsTimeReno w]
set qmon [$ns monitor-queue $node_(r0) $node_(r1) [open qm.out w] 0.1]
[$ns link $node_(r0) $node_(r1)] queue-sample-timeout



#Queue
set redq [[$ns link $node_(r0) $node_(r1)] queue]
set tchan_ [open all.q w]
$redq trace curq_
$redq trace ave_
$redq attach $tchan_

#Задаём планировщик
set k 20
for {set i 1} {$i < $k} {incr i} {
$ns at 0.0 "$ftp($i) start"
$ns at 1.0 "plotWindow $tcp($i) $windowVsTime"
$ns at 22.0 "$ftp($i) stop"
}
$ns at 25 "finish"

# Формирование файла с данными о размере окна TCP:
proc plotWindow {tcpSource file} {
	global ns
	set time 0.01
	set now [$ns now]
	set cwnd [$tcpSource set cwnd_]
	puts $file "$now $cwnd"
	$ns at [expr $now+$time] "plotWindow $tcpSource $file"
}




#Поставим процедуру "Finish"
proc finish {} {
	global ns nf
	$ns flush-trace
	#Закрыть трейс-файл nam
	close $nf
	global tchan_
	#графики для мгновенной и средневзвешанной экспоненциальной очереди в xgraph
	set awkCode {
	{
		if ($1 == "Q" && NF>2) {
		print $2, $3 >> "temp.q";
		set end $2
		}
		else if ($1 == "a" && NF>2)
		print $2, $3 >> "temp.a";
	}
	}
	
	set f [open temp.queue w]
	puts $f "TitleText: RED"
	puts $f "Device: Postscript"

	if { [info exists tchan_] } {
	close $tchan_
	}
	
	#Удалим предыдущие временные файлы при их наличии
	exec rm -f temp.q temp.a
	exec touch temp.a temp.q
	
	exec awk $awkCode all.q
	
	puts $f \"queue
	exec cat temp.q >@ $f
	puts $f \n\"ave_queue
	exec cat temp.a >@ $f
	close $f
	
	exec xgraph -bb -tk -x time -t "TCPRenoCWND" WindowVsTimeReno &
	exec xgraph -bb -tk -x time -y queue temp.queue &
	exit 0
}
$ns run


















 
