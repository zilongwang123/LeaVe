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

def show_regs_mems(cstrtype, outFolder):

    module = CONF.module
    yosysScript = ""
    yosysScript += "read_verilog -sv {}/*.v\n".format(outFolder)
    yosysScript += "hierarchy -top {}\n".format(module)
    yosysScript += "proc -norom\n"
    yosysScript += "flatten\n"
    yosysScript += "select {}\n".format(module)
    #yosysScript += "opt\n"
    yosysScript += "write_verilog  {}/{}.v\n".format(outFolder,module)
    yosysScript += "show_regs_mems -o {} {}\n".format(outFolder, module)
    yosysScript += "write_verilog  {}/{}.v\n".format(outFolder,module)

    with open("{}/show_yosys.script".format(outFolder) , 'w') as f:
        f.write(yosysScript)
    
    cmd = [CONF.yosysPath]
    for m in CONF.yosysAdditionalModules:
        cmd.append(f"-m{m}")
    cmd.append("-s{}/show_yosys.script".format(outFolder))
    run_process(cmd, CONF.verbose_verification)

def initInvariant(filtertype):
    outFolder = CONF.outFolder + f"/{filtertype}_init" 
    ## 0. copy source code to target
    run_process(["rm", "-rf", outFolder], CONF.verbose_preprocessing)
    run_process(["cp", "-R", CONF.codeFolder, outFolder], CONF.verbose_preprocessing)
    
    ## 1. get the information about the memories and registers from the flattened design
    show_regs_mems("init", outFolder)

       
    # 2. phase the regs_mems.dat
    invariant = []
    to_expand = []
    auxiliaryVariables = []
    f = open("{}/regs_mems.dat".format(outFolder))
    for line in f:
        linelist = line.split(" ")
        # create the invariants for memories 
        # Memories: name width size filename
        if linelist[0] == "Memories":
            id = linelist[1]
            if id not in CONF.memoryList:
                if (not id.count("$")) and (not (id.startswith("_") and id.endswith("_"))):
                    width = int(linelist[2])
                    size = int(linelist[3])
                    filename = (linelist[4].replace("\n", "")).split("/")[-1]
                    to_expand.append({"filename": filename, "array": id.split(".")[-1], "width": width, "size": size, "mult": "true"})
                    for i in range(size):
                        auxiliaryVariables.append({"id": id2val(id)+"_"+str(i), "value": id2val(id)+"_"+str(i), "width": width})
                        invariant.append(createInvariantfrommems(id,i,width))
        # create the invariants for registers 
        # Registers: name width
        elif linelist[0] == "Variables":
            id = linelist[1]
            width = int(linelist[2])
            if (not id.count("$")) and (not (id.startswith("_") and id.endswith("_"))):
                id = escape_id(id)
                auxiliaryVariables.append({"id": id2val(id), "value": id2val(id), "width": width})
                invariant.append(createInvariantfromregs(id,width))
    f.close()
    #print(to_expand)
    #print(invariant)
    # generating auxiliary Variables
    av_dict = []
    auxVars = []
    for av in (auxiliaryVariables + CONF.auxiliaryVariables):
        if av.get("id") not in av_dict:
            auxVars.append(av)
            av_dict.append(av.get("id"))
    return auxVars, to_expand, embedInvariant(CONF.trgObservations,embedInvariant(CONF.invariant,invariant))

def embedInvariant(invariant, toembedinv):
    newinv = []
    for inv in toembedinv:
        newinv.append(inv)
    for inv in invariant:
        exist = False
        for toinv in newinv:
            if inv.get("id") == toinv.get("id"):
                exist = True
        if not exist:
            newinv.append(inv)
    return newinv


def refineInvariant(invariant, diffInvList):
    newinvariant = []
    for inv in invariant:
        if (inv.get("id") not in diffInvList) and (rename(inv.get("id")) not in diffInvList):
            newinvariant.append(inv)
    return newinvariant

def invariantSubset(source, target):
    contain = True
    sourceIDList = []
    for inv in source:
        sourceIDList.append(inv.get("id"))
    for inv in target:
        if (inv.get("id") not in sourceIDList):
            contain = False
    return contain