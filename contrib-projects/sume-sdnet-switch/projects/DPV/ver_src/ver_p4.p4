//
// Copyright (c) 2018 -
// All rights reserved.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
// license agreements.  See the NOTICE file distributed with this work for
// additional information regarding copyright ownership.  NetFPGA licenses this
// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//

#include <core.p4>
#include <sume_switch.p4>

// USEFUL DEFINITIONS
#define IPV4_TYPE 0x0800
#define VLAN_TYPE 0x8100
#define NDP_TYPE 0xC7
#define TCP_TYPE 0x06
#define ETH_HDR_SIZE 14
#define IPV4_HDR_SIZE 20
#define VLAN_HDR_SIZE 4
#define CRC_FCS 4
#define PORT_SIZE 8
#define PORTS_SIZE 16

// SUME PORTS
#define NF0 0b0000_0001
#define NF1 0b0000_0100
#define NF2 0b0001_0000
#define NF3 0b0100_0000
#define DRP 0b0000_0000
#define BRD 0b0101_0101
#define BRD_0 0b0101_0100
#define BRD_1 0b0101_0001
#define BRD_2 0b0100_0101
#define BRD_3 0b0001_0101
#define UNK 0b1111_1111

// EXTERN RWI OPs
#define READ    8w0
#define WRITE   8w1
#define INC     8w2

// EXTERNS
#define BUS_WIDTH 32
#define QUE_WIDTH 32

// COUNTER
#define COUNT_INDEX_WIDTH 1

// DROP
#define DROP_INDEX_WIDTH 4

// DSTPORT
#define DSTPORT_INDEX_WIDTH 4

// PKTSIZE
#define PKTSIZE_INDEX_WIDTH 3

////////////////////////////////////////////////////////////////////////////////
///                        EXTERNs
////////////////////////////////////////////////////////////////////////////////

// COUNTER
// ctrlPort register (#REGs = 2^INDEX_WIDTH) (R 0 / W 1 / I 2)
// WARNING !!! Writing data to highest index resets the extern module
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(4)
extern void vercount_reg_rw(in bit<COUNT_INDEX_WIDTH> index, 
                         in bit<BUS_WIDTH> newVal, 
                         in bit<8> opCode, 
                         out bit<BUS_WIDTH> result);

// DROP
// ctrlPort register (#REGs = 2^INDEX_WIDTH) (R 0 / W 1 / I 2)
// WARNING !!! Writing data to highest index resets the extern module
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(4)
extern void vdrop_reg_rw(in bit<DROP_INDEX_WIDTH> index, 
                         in bit<QUE_WIDTH> newVal, 
                         in bit<8> opCode, 
                         out bit<QUE_WIDTH> result);

// DSTPORT
// ctrlPort register (#REGs = 2^INDEX_WIDTH) (R 0 / W 1 / I 2)
// WARNING !!! Writing data to highest index resets the extern module
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(4)
extern void vdstport_reg_rw(in bit<DSTPORT_INDEX_WIDTH> index, 
                         in bit<QUE_WIDTH> newVal, 
                         in bit<8> opCode, 
                         out bit<QUE_WIDTH> result);

// PACKET SIZE
// ctrlPort register (#REGs = 2^INDEX_WIDTH) (R 0 / W 1 / I 2)
// WARNING !!! Writing data to highest index resets the extern module
//@Xilinx_MaxLatency(3)
//@Xilinx_ControlWidth(6)
//extern void verpktsize_reg_rw(in bit<PKTSIZE_INDEX_WIDTH> index, 
//                         in bit<BUS_WIDTH> newVal, 
//                         in bit<8> opCode, 
//                         out bit<BUS_WIDTH> result);

////////////////////////////////////////////////////////////////////////////////
///                        STANDARD HEADERs
////////////////////////////////////////////////////////////////////////////////

// --------------------------
//          ETHERNET
// --------------------------
#define ETHERNET_SIZEB 14
#define ETHERNET_SIZEb (ETHERNET_SIZEB*8)

header Ethernet_h { 
    bit<48> dstAddr; 
    bit<48> srcAddr; 
    bit<16> etherType;
}

// --------------------------
//          IPV4
// --------------------------
#define IPV4_SIZEB 20
#define IPV4_SIZEb (INT_SIZEB*8)

// IPv4 header without options
header IPv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv; 
    bit<16> totalLen; 
    bit<16> identification; 
    bit<3> flags;
    bit<13> fragOffset; 
    bit<8> ttl;
    bit<8> protocol; 
    bit<16> hdrChecksum; 
    bit<32> srcAddr; 
    bit<32> dstAddr;
}

// --------------------------
//          NDP
// --------------------------
#define NDP_SIZEB 20
#define NDP_SIZEb (INT_SIZEB*8)

// NDP header
header NDP_h {
    bit<1> f_res0;
    bit<1> f_fin;
    bit<1> f_pcnumval;
    bit<1> f_keepalive;
    bit<1> f_nack;
    bit<1> f_pull;
    bit<1> f_ack;
    bit<1> f_data;
    bit<8> f_res1;
    bit<16> checksum;
    bit<32> sport;
    bit<32> dport;
    bit<32> seqpull;
    bit<32> pacerecho;
}

// --------------------------
//          TCP
// --------------------------
#define TCP_SIZEB 20
#define TCP_SIZEb (INT_SIZEB*8)

// TCP header without options
header TCP_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4> dataOffset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

////////////////////////////////////////////////////////////////////////////////
///                        RECOGNIZED HEADERS
////////////////////////////////////////////////////////////////////////////////

struct Parsed_packet {
    Ethernet_h ethernet;
    IPv4_h ipv4;
    NDP_h ndp;
    TCP_h tcp;
}

////////////////////////////////////////////////////////////////////////////////
///                        METADATA
////////////////////////////////////////////////////////////////////////////////

// digest data to be sent to CPU if desired. MUST be 80 bits!
struct digest_data_t {
    bit<80>  unused;
}

// user defined metadata: can be used to shared information between
// TopParser, TopPipe, and TopDeparser 
struct user_metadata_t {
    bit<8>  unused;
}

////////////////////////////////////////////////////////////////////////////////
///                        PARSER IMPLEMENTATION
////////////////////////////////////////////////////////////////////////////////

// Parser Implementation
@Xilinx_MaxPacketRegion(16384)
parser TopParser_ver(packet_in b, 
                 out Parsed_packet p, 
                 out user_metadata_t user_metadata,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata) {

    state start {
        b.extract(p.ethernet);
        b.extract(p.ipv4);
        transition select(p.ipv4.protocol) {
            NDP_TYPE: parse_ndp;
            TCP_TYPE: parse_tcp;
            default: accept;
        } 
    }

    state parse_ndp {
        b.extract(p.ndp);
        transition accept;
    }

    state parse_tcp {
        b.extract(p.tcp);
        transition accept;
    }

}

////////////////////////////////////////////////////////////////////////////////
///                        MATCH-ACTION PIPELINE
////////////////////////////////////////////////////////////////////////////////

// match-action pipeline
control TopPipe_ver(inout Parsed_packet p,
                inout user_metadata_t user_metadata, 
                inout digest_data_t digest_data, 
                inout sume_metadata_t sume_metadata) {
 
    // COUNTER
    bit<BUS_WIDTH> count_in;
    bit<BUS_WIDTH> count_out;

    // DROP
    bit<DROP_INDEX_WIDTH> drop_indx = 4w0b1111;
    bit<QUE_WIDTH> drop_in;
    bit<QUE_WIDTH> drop_out;

    // DSTPORT
    bit<DSTPORT_INDEX_WIDTH> dstport_indx = 4w0b1111;
    bit<QUE_WIDTH> dstport_in;
    bit<QUE_WIDTH> dstport_out;

    // PACKET SIZE
    //bit<PKTSIZE_INDEX_WIDTH> packet_size_indx = 3w0;
    //bit<BUS_WIDTH> pktsize_in;
    //bit<BUS_WIDTH> pktsize_out;

    //************************************************
    // ACTION: SET_DROP
    //************************************************
    action set_drop(bit<DROP_INDEX_WIDTH> index) {
        drop_indx = index;
        }

    //************************************************
    // ACTION: SAY_UNK_DROP
    //************************************************
    action sayunk_drop() {
        drop_indx = 4w0b1111;
        }

    //************************************************
    // TABLE: CHECK_DROP
    //************************************************
    table check_drop {
        key = {sume_metadata.drop: exact;}

        actions = {
            set_drop;
            sayunk_drop;
        }
        size = 64;
        default_action = sayunk_drop;
    }

    //************************************************
    // ACTION: SET_DSTPORT
    //************************************************
    action set_dstport(bit<DSTPORT_INDEX_WIDTH> index) {
        dstport_indx = index;
        }

    //************************************************
    // ACTION: SAY_UNK_DSTPORT
    //************************************************
    action sayunk_dstport() {
        dstport_indx = 4w0b1111;
        }

    //************************************************
    // TABLE: CHECK_DSTPORT
    //************************************************
    table check_dstport {
        key = {sume_metadata.dst_port: exact;}

        actions = {
            set_dstport;
            sayunk_dstport;
        }
        size = 64;
        default_action = sayunk_dstport;
    }

    //************************************************
    // ACTION: SET_PACKET_SIZE
    //************************************************
    //action set_packet_size(bit<PKTSIZE_INDEX_WIDTH> index) {
    //    packet_size_indx = index;
    //    }

    //************************************************
    // ACTION: SAY_UNK_SIZE
    //************************************************
    //action sayunk_size() {
    //    packet_size_indx = 3w0b111;
    //    }

    //************************************************
    // TABLE: CHECK_PACKET_SIZE
    //************************************************
    //table check_packet_size {
    //    key = {sume_metadata.pkt_len: exact;}

    //    actions = {
    //        set_packet_size;
    //        sayunk_size;
    //    }
    //    size = 64;
    //    default_action = sayunk_size;
    //}              

    //************************************************
    // MATCH / ACTION FLOW 
    //************************************************
    apply {

        //+++++++++++++++++
        //+  PACKET COUNT EXTERN
        //+++++++++++++++++
        vercount_reg_rw(0, count_in, INC, count_out); 

        //+++++++++++++++++
        //+  DROP
        //+++++++++++++++++
        check_drop.apply();

        //+++++++++++++++++
        //+  DROP EXTERN
        //+++++++++++++++++
        vdrop_reg_rw(drop_indx, drop_in, INC, drop_out);

        //+++++++++++++++++
        //+  DSTPORT
        //+++++++++++++++++
        check_dstport.apply();

        //+++++++++++++++++
        //+  DSTPORT EXTERN
        //+++++++++++++++++
        vdstport_reg_rw(dstport_indx, dstport_in, INC, dstport_out);

    } // apply

} // control

////////////////////////////////////////////////////////////////////////////////
///                        DEPARSER IMPLEMENTATION
////////////////////////////////////////////////////////////////////////////////

// Deparser Implementation
@Xilinx_MaxPacketRegion(16384)
control TopDeparser_ver(packet_out b,
                    in Parsed_packet p,
                    in user_metadata_t user_metadata,
                    inout digest_data_t digest_data, 
                    inout sume_metadata_t sume_metadata) { 
    apply {

        b.emit(p.ethernet); 
        b.emit(p.ipv4);
        b.emit(p.ndp);
        b.emit(p.tcp);

    }

}

////////////////////////////////////////////////////////////////////////////////
///                        SWITCH INSTANCE
////////////////////////////////////////////////////////////////////////////////

// Instantiate the switch
SimpleSumeSwitch(TopParser_ver(), TopPipe_ver(), TopDeparser_ver()) main;
