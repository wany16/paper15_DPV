################################################################################
#
# Copyright (c) 2018 -
# All rights reserved.
#
# Copyright (c) 2015 University of Cambridge
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#

# CHOOSE DATA PLANE UNDER TEST (P4 data plane: nf_sume_sdnet_ppl):
#export SWITCH_PPL=switch_output_port_lookup
export SWITCH_PPL=nf_sume_sdnet_ppl

export P4_PROJECT_NAME=DPV
export P4_PPL_NAME=ppl_p4
export P4_DBG_NAME=dbg_p4
export P4_VER_NAME=ver_p4
export NF_PROJECT_NAME=simple_sume_switch
export SUME_FOLDER=~/paper15_DPV
export SUME_SDNET=${SUME_FOLDER}/contrib-projects/sume-sdnet-switch
export P4_PROJECT_DIR=${SUME_SDNET}/projects/${P4_PROJECT_NAME}
export LD_LIBRARY_PATH=${SUME_SDNET}/sw/sume:${LD_LIBRARY_PATH}
export DEV_PROJECTS=${SUME_FOLDER}/contrib-projects
export IP_FOLDER=${SUME_FOLDER}/lib/hw/std/cores
export CONTRIB_IP_FOLDER=${SUME_FOLDER}/lib/hw/contrib/cores
export CONSTRAINTS=${SUME_FOLDER}/lib/hw/std/constraints
export XILINX_IP_FOLDER=${SUME_FOLDER}/lib/hw/xilinx/cores
export NF_DESIGN_DIR=${P4_PROJECT_DIR}/${NF_PROJECT_NAME}
export NF_WORK_DIR=/tmp/${USER}
export PYTHONPATH=.:${SUME_SDNET}/bin:${SUME_FOLDER}/tools/scripts/:${NF_DESIGN_DIR}/lib/Python:${SUME_FOLDER}/tools/scripts/NFTest
export DRIVER_NAME=sume_riffa_v1_0_0
export DRIVER_FOLDER=${SUME_FOLDER}/lib/sw/std/driver/${DRIVER_NAME}
export APPS_FOLDER=${SUME_FOLDER}/lib/sw/std/apps/${DRIVER_NAME}
export HWTESTLIB_FOLDER=${SUME_FOLDER}/lib/sw/std/hwtestlib
export RWAXI=${SUME_FOLDER}/lib/sw/std/apps/sume_riffa_v1_0_0
export BITFILE=${P4_PROJECT_DIR}/simple_sume_switch/hw/project/simple_sume_switch.runs/impl_1
export VIVADOPRJ=${P4_PROJECT_DIR}/simple_sume_switch/hw/project/
export PCIRESCAN=${SUME_FOLDER}/tools/scripts/reconfigure
export PPLSW=${P4_PROJECT_DIR}/ppl_sw
export DBGSW=${P4_PROJECT_DIR}/dbg_sw
export VERSW=${P4_PROJECT_DIR}/ver_sw
export PPLSRC=${P4_PROJECT_DIR}/ppl_src
export DBGSRC=${P4_PROJECT_DIR}/dbg_src
export VERSRC=${P4_PROJECT_DIR}/ver_src
export DPVLIB=${P4_PROJECT_DIR}/DPV_Library
export TESTS=${P4_PROJECT_DIR}/tests
export TOOLS=${SUME_FOLDER}/tools/DPV_tools
export CONTROL_PLANE=${PPLSRC}/control_plane

alias progsume='sh ${TOOLS}/progsume.sh'
alias progtabs='sh ${TOOLS}/progtabs.sh'
alias progswitch='progsume -d 0 && progtabs'
alias progswitchd='progsume -d 1 && progtabs'
alias progintfsup='sh ${TOOLS}/progintfsup.sh'

alias watchregs='watch -d -n 1 sh ${TOOLS}/scanregs.sh'
alias scanregs='clear & sh ${TOOLS}/scanregs.sh'
alias clearregs='sh ${TOOLS}/clearregs.sh'
alias scanout='clear & sh ${TOOLS}/scanout.sh'
alias selftest='sh ${P4_PROJECT_DIR}/test_infrastructure/DPV_self_test.sh'

alias genpkts='bash ${TOOLS}/genpkts.sh'

alias editrepo='subl $DBGSRC/dbg_p4.p4 $DBGSRC/cmds.txt $PPLSRC/ppl_p4.p4 $PPLSRC/cmds.txt $VERSRC/ver_p4.p4 $VERSRC/cmds.txt'
