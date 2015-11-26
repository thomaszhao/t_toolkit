#!/usr/bin/python

import sys
import os
import re


pattern = None
rtt_arr = []
snd_cwnd_arr = []



def analyseLine(line):
    match = pattern.match(line)

    #print line
   
    if match:
       #print "Matched!"
       #print match.groups()
       
       rtt = match.group(1)
       rtt_arr.append(float(rtt))
       
       rttvar = match.group(2)
       
       snd_cwnd = match.group(3)
       snd_cwnd_arr.append(int(snd_cwnd))
       
       send = match.group(4)
       
    else:
       #print "Not Matched!"
       pass


def printMeanValue(title, arr):
    print "###########################" 
    print title

    length = len(arr)
    
    # for debug:
    if length < 100:
        print arr

    arr.sort()

    print "length:     %d" % length
    print "25th Percentile:    " + str(arr[int(length*0.25)])
    print "50th Percentile:    " + str(arr[int(length*0.50)]) + "  *"
    print "75th Percentile:    " + str(arr[int(length*0.75)])
    print "95th Percentile:    " + str(arr[int(length*0.95)])

    # average value
    sum = 0.0
    for a in arr:
        sum += a
    print " Average Value:     %.3f  *" % (sum/length)




def doStatistic():
    printMeanValue("RTT:", rtt_arr)
    printMeanValue("snd_cwnd:", snd_cwnd_arr)


def usage():
    print "Usage:"
    print "   ss -t -i \"sport == :80\" | ./analyse_ss.py"
    print "Or"
    print "   echo \"xxxxxxx\" | ./analyse_ss.py"


if __name__ == "__main__":
    if len(sys.argv) != 1:
        usage()
        os._exit(2)

    '''
    cubic wscale:7,7 rto:204 rtt:0.079/0.118 ato:40 mss:24576 cwnd:10 send 24887.1Mbps rcv_space:43690
    '''
    pattern = re.compile(r'.*rtt:([0-9\.]+)/([0-9\.]+).*cwnd:([0-9\.]+).*send ([0-9\.MK]+)')

    try:
        while True:
            line = sys.stdin.readline()
            if line:
                analyseLine(line)
            else:
                break
    except Exception as e:
        print e


    doStatistic()

    os._exit(0)
