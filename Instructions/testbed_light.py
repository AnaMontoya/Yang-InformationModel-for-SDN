#!/usr/bin/python

"""
Testbed.

Created on Jun 19, 2015

@author: festradasolano
"""

import sys
import struct
import socket

from mininet.util import irange
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.log import setLogLevel
from mininet.cli import CLI
from mininet.node import RemoteController

class OvsdbTopo(Topo):
    "Topology for OVSDB Testbed"

    def __init__(self, fanout=2, initSw=1, initHost=1, **opts):
        # Initialize topology and default options
        Topo.__init__(self, **opts)
        hNum = initHost
        # Create switch from core layer
        coreSwitch = self.addSwitch("s%s" % initSw)
        # Fanout for switches from aggregation layer
        for a in irange(initSw + 1, initSw + fanout):
            # Create switches from aggregation layer
            aggSwitch = self.addSwitch("s%s" % a)
            # Link aggregation switch with core switch
            self.addLink(aggSwitch, coreSwitch)
            # Fanout for switches from edge layer
            eInit = (fanout ** 0) + (fanout ** 1) + ((a - initSw - 1) * fanout) + initSw
            for e in irange(eInit, eInit + fanout - 1):
                # Create switches from edge layer
                edgeSwitch = self.addSwitch("s%s" % e)
                # Link edge switch with aggregation switch
                self.addLink(edgeSwitch, aggSwitch)
                # Fanout for hosts
                for h in irange(hNum, hNum):
                    # Create hosts
                    host = self.addHost("h%s" % h)
                    # Link host with edge switch
                    self.addLink(host, edgeSwitch)
                hNum = hNum + 1

def launchTopology(topoFanout, topoInitialSw, topoInitialHost, controllerIp, controllerPort):
    """
    Create and launch the network
    """
    
    # Create network
    print "a. Creating Network"
    topo = OvsdbTopo(fanout=topoFanout, initSw=topoInitialSw, initHost=topoInitialHost)
    c0 = RemoteController("c0", ip=controllerIp, port=controllerPort)
    net = Mininet(topo=topo, controller=c0)

    # Customize IP and MAC for hosts
    print "b. Customizing IP and MAC for hosts"
    initialIp = ipToLong("10.0.0.0")
    topoFinalHost = (topoFanout ** 2) + (topoInitialHost - 1)
    for h in irange(topoInitialHost, topoFinalHost):
        host = net.get("h%s" % h)
        host.setIP("%s/16" % numToIp(h + initialIp))
        host.setMAC(numToMac(h))

    # Run network
    print "c. Firing up Mininet"
    net.start()
  
    # Start CLI
    print "d. Starting CLI"
    CLI(net)
    
    print "e. Stopping Mininet"
    net.stop()

def numToMac (num):
    """
    Convert a numeric value into the MAC string form.
    """
    num = long(num)
    num = struct.pack('!Q', num)
    assert len(num) == 8
    r = ':'.join(['%02x' % (ord(x),) for x in num[2:]])
    return r

def ipToLong (ip):
    """
    Convert an IP string into the long numeric value.
    """
    packedIP = socket.inet_aton(ip)
    return struct.unpack("!L", packedIP)[0]

def numToIp (num):
    """
    Convert a numeric value into the IP string form.
    """
    num = long(num)
    return socket.inet_ntoa(struct.pack('!L', num))

if __name__ == "__main__":
    # Tell mininet to print useful information
    setLogLevel("info")
    
    # Default parameters
    topoFanout = 2
    topoInitialSw = 1
    topoInitialHost = 1
    controllerIp = "192.168.56.1"
    controllerPort = 6653
    
    # Obtain parameters from arguments
    error = False
    for arg in sys.argv[1:]:
        option = arg.split("=")
        if (option[0] == "--topoFanout"):
            topoFanout = int(option[1])
        elif (option[0] == "--topoInitialSw"):
            topoInitialSw = int(option[1])
        elif (option[0] == "--topoInitialHost"):
            topoInitialHost = int(option[1])
        elif (option[0] == "--controllerIp"):
            controllerIp = option[1]
        elif (option[0] == "--controllerPort"):
            controllerPort = int(option[1])
        else:
            print "Option %s is not valid" % option[0]
            error = True
    
    if (error == False):
        # Launch the network
        launchTopology(topoFanout=topoFanout, topoInitialSw=topoInitialSw, topoInitialHost=topoInitialHost, controllerIp=controllerIp, controllerPort=controllerPort)
    else:
        print "Error running the network"
