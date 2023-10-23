from __future__ import absolute_import
from __future__ import print_function
import sys
import os
import time
import re
from config import CONF
from util import *



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
            if v.get('start'):
                start = int(v.get('start'))
            else:
                start = 0

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
                # expansion += f"wire [10:0] {var};\n"
                expansion += f"wire [{size1}*({size2})-1:0] {var};\n"
                expansion += f"assign {var} = {{"
                for i in range(int(size2)-1):
                    expansion += f"{array}[{start} + {i}],"
                expansion += f"{array}[{start} + {size2} - 1] }};\n"
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


def preprocessing(to_expand, cstrType):

    log("START")
    
    outFolder = CONF.outFolder + "/" + cstrType
    ## 0. copy source code to target
    log("Setting up output folder")
    run_process(["rm", "-rf", outFolder], CONF.verbose_preprocessing)
    run_process(["cp", "-R", CONF.codeFolder, outFolder], CONF.verbose_preprocessing)

    ## 1. Expanding arrays
    if to_expand != None and len(to_expand) > 0:
        log(f"Expanding arrays in {CONF.module}")
        expandArrays(outFolder, to_expand)
    log("END")

def preprocessing4way(srcToExpand, trgToExpand, cstrType):

    log("START")
    
    outFolder = CONF.outFolder + "/" + cstrType
    ## 0. copy source code to target
    log("Setting up output folder")
    run_process(["rm", "-rf", outFolder], CONF.verbose_preprocessing)
    run_process(["cp", "-R", CONF.codeFolder, outFolder], CONF.verbose_preprocessing)

    ## 1. Expanding arrays
    if srcToExpand != None and len(srcToExpand) > 0:
        log(f"Expanding arrays in {CONF.srcModule}")
        expandArrays(outFolder, srcToExpand)
    if trgToExpand != None and len(trgToExpand) > 0:
        log(f"Expanding arrays in {CONF.trgModule}")
        expandArrays(outFolder, trgToExpand)
    log("END")



