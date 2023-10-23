from __future__ import absolute_import
from __future__ import print_function
import sys
import os
import time
import re
from config import CONF
from util import *
from counterexample_checking import rename

from config import CONF
from preprocessing import preprocessing

def escape_id(id):
    if (id.count("[")) and (id.count(".") == 0):
        return "\\" + id
    else:
        return id

def id2val(id):
    if id.count(".") == 0:
        return id
    else:
        id_l = id.split(".")
        return "\\"+".".join(id_l)


def createInvariantfromregs(id, width):
    return {"id": id2val(id), "cond": "1", "attrs": [ {"value": id2val(id), "width": width} ]}

def createInvariantfrommems(id, i, width):
    return {"id": id2val(id) + "_"+str(i), "cond": "1", "attrs": [ {"value": id2val(id)+"_"+str(i), "width": width} ]}
def createAvfrommems(id,i,width):
    return ({"id": id2val(id) + "_"+str(i), "value": id2val(id) + "_"+str(i), "width": width})

def show_regs_mems(cstrtype, outFolder):

    if CONF.modality == "2way":
        module = CONF.module
    else:
        if cstrtype == "trg":
            module = CONF.trgModule
        else:
            module = CONF.srcModule
    yosysScript = ""
    yosysScript += "read_verilog -sv {}/*.v\n".format(outFolder)
    yosysScript += "hierarchy -top {}\n".format(module)
    yosysScript += "proc\n"
    yosysScript += "flatten\n"
    yosysScript += "select {}\n".format(module)
    #yosysScript += "opt\n"
    yosysScript += "write_verilog  {}/{}.v\n".format(outFolder,module)
    yosysScript += "show_regs_mems -o {} {}\n".format(outFolder, module)
    yosysScript += "write_verilog  {}/{}.v\n".format(outFolder,module)

    with open("{}/show_yosys.script".format(outFolder) , 'w') as f:
        f.write(yosysScript)
    
    # cmd = [CONF.yosysPath]
    # for m in CONF.yosysAdditionalModules:
    #     cmd.append(f"-m{m}")
    # cmd.append("-s{}/show_yosys.script".format(outFolder))
    # run_process(cmd, CONF.verbose_verification)

    run_yosys("{}/show_yosys.script".format(outFolder),  CONF.verbose_verification, CONF.yosys_strictness)

def initInvariant(filtertype):
    outFolder = CONF.outFolder + f"/{filtertype}_init" 
    ## 0. copy source code to target
    run_process(["rm", "-rf", outFolder], CONF.verbose_preprocessing)
    run_process(["cp", "-R", CONF.codeFolder, outFolder], CONF.verbose_preprocessing)
    
    ## 1. get the information about the memories and registers from the flattened design
    show_regs_mems("trg", outFolder)
       
    # 2. phase the regs_mems.dat
    invariant = []
    to_expand = []
    auxiliaryVariables = []
    av_dict = []
    f = open("{}/regs_mems.dat".format(outFolder))
    for line in f:
        linelist = line.split(" ")
        # create the invariants for memories 
        # Memories: name width size filename
        if linelist[0] == "Memories":
            id = linelist[1]
            if id not in CONF.memoryList:
                width = int(linelist[2])
                size = int(linelist[3])
                filename = (linelist[4].replace("\n", "")).split("/")[-1]
                to_expand.append({"filename": filename, "array": id.split(".")[-1], "width": width, "size": size, "mult": "true"})
                for i in range(size):
                    invariant.append(createInvariantfrommems(id,i,width))
                    auxiliaryVariables.append(createAvfrommems(id, i, width))
            # print("auxiliaryVariables:\n")
            # print(auxiliaryVariables)
        # create the invariants for registers 
        # Registers: name width
        elif linelist[0] == CONF.initInvariant:
            id = linelist[1]
            width = int(linelist[2])
            if (not id.count("$")) and (not (id.startswith("_") and id.endswith("_"))):
                id = escape_id(id)
                invariant.append(createInvariantfromregs(id,width))
        
        # Auxiliary variables from trg design
        if linelist[0] == "Variables":
            id = linelist[1]
            width = int(linelist[2])
            if (not id.count("$")) and (not (id.startswith("_") and id.endswith("_"))):
                id = escape_id(id)
                av_dict.append(id2val(id))
                auxiliaryVariables.append({"id": id2val(id), "value": id2val(id), "width": width})
    f.close()
    # Auxiliary variables from src design
    show_regs_mems("src", outFolder)
    # 2. phase the regs_mems.dat
    f = open("{}/regs_mems.dat".format(outFolder))
    for line in f:
        linelist = line.split(" ")

        if linelist[0] == "Variables":
            id = linelist[1]
            width = int(linelist[2])
            if (not id.count("$")) and (not (id.startswith("_") and id.endswith("_"))):
                id = escape_id(id)
                if id not in av_dict:
                    av_dict.append(id2val(id))
                    auxiliaryVariables.append({"id": id2val(id), "value": id2val(id), "width": width})
    f.close()
    
    for av in CONF.auxiliaryVariables:
        if av.get("id") not in av_dict:
            auxiliaryVariables.append(av)
            av_dict.append(av.get("id"))
    return auxiliaryVariables, to_expand, embedInvariant(invariant, CONF.invariant)

def embedInvariant(invariant, toembedinv):
    
    for inv in invariant:
        exist = False
        for toinv in toembedinv:
            if inv.get("id") == toinv.get("id"):
                exist = True
        if not exist:
            toembedinv.append(inv)
    return toembedinv


def refineInvariant(invariant, diffInvList):
    newinvariant = []
    for inv in invariant:
        if (inv.get("id") not in diffInvList) and (rename(inv.get("id")) not in diffInvList):
            newinvariant.append(inv)


    return newinvariant