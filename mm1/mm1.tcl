#Создаем новый симулятор
set ns [new Simulator]

#Пишем общий trace
set tf [open out.tr w]
$ns trace-all $tf

#Задаем произвольные мью и льямбду
set lambda 30.0
set mu 35.0

#Размер очереди и время моделирования
set qsize	100000
set duration	2000.0

#Создаём узлы
set n1 [$ns node]
set n2 [$ns node]

#Создаём Линк
set link [$ns simplex-link $n1 $n2 100kb 0ms DropTail]
$ns queue-limit $n1 $n2 $qsize

#Задаём время обслуживания и скорость заявок
set InterArrivalTime [new RandomVariable/Exponential]
$InterArrivalTime set avg_ [expr 1/$lambda]
set pktSize [new RandomVariable/Exponential]
$pktSize set avg_ [expr 100000.0/(8*$mu)]

#Создаём нового агента, навещивающегося на n1
set src [new Agent/UDP]
$src set packetSize_ 100000
$ns attach-agent $n1 $src

#Агент 0, который навещивается на n2
set sink [new Agent/Null]
$ns attach-agent $n2 $sink
$ns connect $src $sink

#мониторинг очереди
set qmon [$ns monitor-queue $n1 $n2 [open qm.out w] 0.1]
$link queue-sample-timeout

#finish procedure
proc finish {} {
	global ns tf
	$ns flush-trace
	close $tf
	exit 0
}

#sendpacket procedure
proc sendpacket {} {
	global ns src InterArrivalTime pktSize
	set time [$ns now]
	$ns at [expr $time + [$InterArrivalTime value]] "sendpacket"
	set bytes [expr round ([$pktSize value])]
	$src send $bytes
}

#Запускаем процедуры
$ns at 0.0001 "sendpacket"
$ns at $duration "finish"

#set rho [expr $lambda/$mu]
#set ploss [expr (1-$rho)*pow($rho,$qsize)/(1-pow($rho,($qsize+1)))]
#puts "Теоритеческая вероятность потери = $ploss"

$ns run



 


