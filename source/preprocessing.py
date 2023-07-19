from __future__ import absolute_import
from __future__ import print_function
import sys
import os
import time
import re
from config import CONF
from datetime import datetime

from util import *
from counterexample_checking import renameDotNotation
from verification import precomputing

ctr = 0

def log(msg):
    global ctr
    if CONF.verbose_preprocessing:
        print(f">>> Preprocessing {ctr}) {msg}")
        ctr += 1


def expandArrays(folder, toExpand):
    for v in toExpand:
        mult = v.get("mult")
        if mult == "true":
            print(mult)
            print(v)
            filename = v.get("filename")
            array = v.get("array")
            width = int(v.get("width"))
            size = int(v.get("size"))

            src = ""
            with open("{}/{}".format(folder, filename), "r") as f:
                src = f.read()

            if src.count("endmodule") > 1:
                print(f"There is more than one module declaration in {folder}/{filename}!")
                exit(1)

            if width > 1:
                tp = f"[{width-1}:0]"
            else:
                tp = ""

            expansion = ""
            for i in range(size):
                expansion += "\t\twire {} {}_{};\n".format( tp, array, str(i))
                expansion += "\t\tassign {}_{} = {}[{}] ;\n".format(array, str(i), array, str(i))
            expansion += "endmodule\n"
            print(f"connecting {array}_i to memory {array} [i] in file {folder}/{filename}")

        else:
            filename = v.get('filename')
            array = v.get('array')
            size1 = int(v.get('i'))
            size2 = int(v.get('j'))
            var = v.get("var")
            if v.get("flatten") is None:
                flatten = False
            else:
                flatten = bool(v.get("flatten"))

            src = ""
            with open("{}/{}".format(folder,filename), "r") as f:
                src = f.read()
            
            if src.count("endmodule") > 1:
                print(f"There is more than one module declaration in {folder}/{filename}!")
                exit(1)

            expansion = ""
            if flatten:
                if len(getIndexMetaVariables(var)) != 0:
                    print(f"Var field {var} cannot contain metavariables")
                    exit(1)
                expansion += f"localparam {array}_DIM1 = {size1};\n"
                expansion += f"localparam {array}_DIM2 = {size2};\n"
                expansion += f"genvar {array}_i;\n"
                expansion += f"wire [{array}_DIM1*{array}_DIM2-1:0] {var};\n"
                # expansion += "generate for (i = 0; i < DIM1; i = i+1) begin\n"
                expansion += f"generate for ({array}_i = 0; {array}_i < {array}_DIM2; {array}_i = {array}_i+1) begin\n"
                # expansion += f"\tassign {var}[i*DIM1 +: DIM2] = {array}[i];\n"
                expansion += f"\tassign {var}[{array}_i*{array}_DIM1 +: {array}_DIM1] = {array}[{array}_i];\n"
                expansion += "end endgenerate\n\n"
            else:
                if getIndexMetaVariables(var) != set("j"):
                    print(f"Var field {var} must contain only the metavariable \"j\"")
                    exit(1)

                if size1 is None or size1 > 1:
                    width = f"[{size1-1}:0]"
                else:
                    width = ""

                assignTemplate = ""
                assignTemplate += "\t\twire {} {};\n".format( width, var)
                assignTemplate += "\t\tassign {} = {}[$$j$$] ;\n".format(var, array)

                for j in range(size2):
                    expansion += replaceIndexMetaVariable(assignTemplate, "j", str(j))

            expansion += "endmodule\n"
            print(f"Expanding vector {array} in file {folder}/{filename}")
        
        src = src.replace("endmodule", expansion)
        with open("{}/{}".format(folder,filename), "w") as f:
            f.write(src)


def preprocessing(to_expand, srcObservations, invariant, stateInvariant, auxVars, metaVars, cstrtype):

    log("START")
    
    outFolder = CONF.outFolder
    ## 0. copy source code to target
    log("Setting up output folder")
    run_process(["rm", "-rf", outFolder], CONF.verbose_preprocessing)
    run_process(["cp", "-R", CONF.codeFolder, outFolder], CONF.verbose_preprocessing)

    ## 1. Expanding arrays
    if to_expand != None and len(to_expand) > 0:
        log(f"Expanding arrays in {CONF.module}")
        expandArrays(outFolder, to_expand)

    
    precomputing(srcObservations, invariant, stateInvariant, auxVars, metaVars, cstrtype)
    time1 = datetime.now()
    
    # run_process(["cp", "{}/{}_inductive/{}".format(CONF.outFolder,cstrtype,CONF.prodCircuitTemplate.replace(".v", "_renamed.temp")), "{}/{}_inductive/{}".format(CONF.outFolder,cstrtype,CONF.prodCircuitTemplate.replace(".v", "_non-renamed.temp"))])
    renameDotNotation("{}/{}_base/{}".format(CONF.outFolder,cstrtype,CONF.prodCircuitTemplate.replace(".v", "_renamed.temp")), testbed=False)
    renameDotNotation("{}/{}_inductive/{}".format(CONF.outFolder,cstrtype,CONF.prodCircuitTemplate.replace(".v", "_renamed.temp")), testbed=False)

    run_process(["cp", "{}/{}".format(CONF.outFolder,CONF.moduleFile), "{}/{}_base/{}.v".format(CONF.outFolder,cstrtype,CONF.module)])
    run_process(["cp", "{}/{}".format(CONF.outFolder,CONF.moduleFile), "{}/{}_inductive/{}.v".format(CONF.outFolder,cstrtype,CONF.module)])
    run_process(["cp", "{}/{}".format(CONF.outFolder,CONF.prodCircuitTemplate.replace(".v", "_base.temp")), "{}/{}_base/{}".format(CONF.outFolder,cstrtype,CONF.prodCircuitTemplate.replace(".v", ".temp"))])
    run_process(["cp", "{}/{}".format(CONF.outFolder,CONF.prodCircuitTemplate.replace(".v", "_inductive.temp")), "{}/{}_inductive/{}".format(CONF.outFolder,cstrtype,CONF.prodCircuitTemplate.replace(".v", ".temp"))])
    time2 = datetime.now()
    logtimefile("\n\t\tTime for renaming the flattened product circuit: "+ str((time2- time1).seconds))







