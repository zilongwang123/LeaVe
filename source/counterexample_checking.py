import os
from config import CONF
import re
from datetime import datetime 
from util import *


## Variables (TODO MG: Move to config)
ctr = 0

def log(msg):
    global ctr
    if CONF.verbose_preprocessing:
        print(f">>> Counterexample {ctr}) {msg}")
        ctr += 1

def compileWithIVerilog(file,outFolder):
    cmd = [CONF.iverilogPath]
    cmd.append("-gno-assertions")
    cmd.append("-g2005-sv")
    cmd.append("-o{}/{}".format(outFolder, CONF.prodCircuitTemplate.replace(".v","")))
    cmd.append(f"-I{outFolder}")
    cmd.append(f"-y{outFolder}")
    cmd.append(file)
    output = run_process(cmd, CONF.verbose_counterexample_checking)
    if "error" in output:
        print("Errors during counterexample compilation!")
        exit(1)
    return "{}/{}".format(outFolder, CONF.prodCircuitTemplate.replace(".v",""))
    
def runTestbed(testbed):
    cmd = [CONF.vvpPath, testbed]
    ctx = run_process(cmd, CONF.verbose_counterexample_checking)
    cycles = ctx.split(">>>>>")
        
    
    diffcycle = False
    for cycle in cycles:

        if diffcycle:
            break
        else:
            diffInvList = []
            invs = cycle.split("\n")
            for inv in invs:
                tbname = inv.split(" ")
                if (tbname[-1] == "0" or tbname[-1] == "x") and len(tbname) == 2:
                    name = tbname[0].split("_trg")[0].split(".")[-1]
                    if name == "MUL_execute" or name == "ready" or name == "MUL_IMM" :
                        logtimefile("Failed to prove " + name)
                        logtimefile("\nVerification failed!!!\n ")
                        logfile("\nVerification failed!!!\n ")
                        exit(1)
                    diffInvList.append(name)
            if len(diffInvList) < 2:
                diffcycle = False
            else:
                diffcycle = True

    print("diffInvList: ",diffInvList[0:-1])
    return diffInvList[0:-1]

                    


def isSpurious(counterexample,outFolder):

    # 0. move exiting context of CONF.outFolder to CONF.outFolder/old
    if CONF.verbose_counterexample_checking:
        print(f">>> Counterexample checking 0) Setting up new {outFolder} folder")
    cmd = ["cp", "-R", f"{outFolder}", f"{outFolder}_tmp"]
    run_process(cmd, CONF.verbose_counterexample_checking)
    cmd = ["rm", "-Rf", f"{outFolder}"]
    run_process(cmd, CONF.verbose_counterexample_checking)
    cmd = ["cp", "-R", CONF.codeFolder, outFolder]
    run_process(cmd, CONF.verbose_counterexample_checking)
    cmd = ["mv", f"{outFolder}_tmp", f"{outFolder}/{outFolder}_tmp"]
    run_process(cmd, CONF.verbose_counterexample_checking)

    # 1. preprocess counterexample
        # 1.a write another prod.v using sources instead of targets and without assert/assume
        # - for this, we can probably move the construction of product circuit to its own module
        # - add back src/trg modules
        # - do we need to construct and inline observations again? Yes, because
        #   these are new observations!
        # 1.c modify the counterexample testbed to add checks for trace
        # equivalence + $display for output

    # 2. collect all files 
    files = [file for file in os.listdir(outFolder) if file.endswith(".v")]

    # 3. compile testbed using iverilog
    testbed = compileWithIVerilog(files, outFolder)

    # 4. run
    return runTestbed(testbed)

    ### 
    # iverilog -o dsn test.v counter.v
    # vvp dsn
    # To the code add something like 
    # always @* begin
    #    $display("%b",c);
    # end
    # to monitor changes to values


def displayObservations(counterexample, obsDict, prodType, keyword):
    debug = True
    if len(obsDict) > 0:
        code = ""
        with open(counterexample, "r") as f:
            code = f.read()

        if CONF.yosysCtxDisplayAtEdge:
            displayObs = f"\talways @(posedge {CONF.yosysCtxClock}) begin\n"
        else:
            displayObs = f"\talways @* begin\n"
        displayObs += f"\t\t$display(\">>>>> CYCLE %0d -- {keyword}\", {CONF.yosysCtxCycle});\n"
        for obsId in obsDict.keys():
            displayObs += f"\t\t $display(\"{CONF.yosysCtxUUT}.{obsId}_{prodType} %b\", {CONF.yosysCtxUUT}.{obsId}_{prodType});\n"
        displayObs += f"\t\t$display(\"{CONF.yosysCtxUUT}.{prodType}_equiv %b\", {CONF.yosysCtxUUT}.{prodType}_equiv);\n"
        if debug:
            for obsId in obsDict.keys():
                displayObs += f"\t\t$display(\">>> {obsId}\");\n"
                for obs in obsDict[obsId]:
                    var = obs.get("var")
                    displayObs += f"\t\t$display(\"{var} %b =?= %b\", {CONF.yosysCtxUUT}.{var}_{prodType}_left,  {CONF.yosysCtxUUT}.{var}_{prodType}_right);\n"
        displayObs += "\tend\n"
        displayObs += "endmodule\n"

        code = code.replace("endmodule", displayObs)
        with open(counterexample, "w") as f:
            f.write(code)


def rename(id_):
    # print("id_: ", id_)
    renamed = "renamed_"+id_.replace(".","__").replace("[","___").replace("]","").replace("\\","").replace(" ","")#.replace("$","").replace("/","").replace(":","")
    # if renamed.find("$func$") != -1:
    #     print("-renamed-: ", renamed)
    return renamed

def renameDotNotation(file, testbed: bool):

    code = ""
    with open(file, "r") as f:
        code = f.read()
    timein1 = datetime.now()
    #1) find all occurrences of . notation
    if testbed:
        #ids = re.findall('UUT\.([A-Za-z0-9_\.\\]*)(\[[A-Za-z0-9\']*\])?[A-Za-z0-9_\.\\\\]*', code)
        ids = re.findall('UUT\.(left\.[A-Za-z0-9_\.\\\\$/;]*)(?:\[[A-Za-z0-9\']*\])?([A-Za-z0-9_\.\\\\]*)? =', code)  
        ids += re.findall('UUT\.(right\.[A-Za-z0-9_\.\\\\$/;]*)(?:\[[A-Za-z0-9\']*\])?([A-Za-z0-9_\.\\\\]*)? =', code)

        ids_auto = re.findall('UUT\.(left\.[A-Za-z0-9_\.$/;]*)(\\\\[A-Za-z_\.]*\[[A-Za-z0-9\']*\] )([A-Za-z0-9_\.\\\\]*)? =', code)
        ids_auto += re.findall('UUT\.(right\.[A-Za-z0-9_\.$/;]*)(\\\\[A-Za-z_\.]*\[[A-Za-z0-9\']*\] )([A-Za-z0-9_\.\\\\]*)? =', code)

        # rename the variables defined in the prod.v start with "\\"
        namedArrays = re.findall('UUT\.(\\\\[A-Za-z0-9_\.\\\\$/;]*)(\[[A-Za-z0-9\']*\])?([A-Za-z0-9_\.\\\\]*)?', code)
        # currently yosys puts two spaces before the assignment whenever the [..] is used as part of an identifier :-\
        namedArrays += re.findall('UUT\.(left\.\\\\[A-Za-z0-9_\.\\\\$/;]*)(\[[A-Za-z0-9\']*\])?([A-Za-z0-9_\.\\\\]*)?  =', code)  # UUT.left.\IACK_reg[7]  =
        namedArrays += re.findall('UUT\.(right\.\\\\[A-Za-z0-9_\.\\\\$/;]*)(\[[A-Za-z0-9\']*\])?([A-Za-z0-9_\.\\\\]*)?  =', code)
        
        namedArrays += re.findall('UUT\.(left\.[A-Za-z0-9_\.\\\\$/;]*)(\[[A-Za-z0-9\']*\])?([A-Za-z0-9_\.\\\\]*)?  =', code)  # UUT.left.\IACK_reg[7]  =
        namedArrays += re.findall('UUT\.(right\.[A-Za-z0-9_\.\\\\$/;]*)(\[[A-Za-z0-9\']*\])?([A-Za-z0-9_\.\\\\]*)?  =', code)

        ids+=ids_auto
        ids+=namedArrays
    else:
        # We are renaming prod.v
        # yosys syntax for dot notation is "\xx.yy.zz"
        # These should be all definitions of registers and wires using DOT notation 
        ids =  re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\([A-Za-z0-9_\.\\\\$/;]*)(\[[0-9]*\])?([A-Za-z0-9_\.\\\\]*)? (?:;| =)', code)  #  wire [31:0] \IOMUX[0]_obs_trg_arg0_trg_left ;
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\(left\.[A-Za-z0-9_\.\\\\$/;]*)(\[[0-9]*\])?([A-Za-z0-9_\.\\\\]*)? (?:;| =)', code)
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\(right\.[A-Za-z0-9_\.\\\\$/;]*)(\[[0-9]*\])?([A-Za-z0-9_\.\\\\]*)? (?:;| =)', code)

        # These should be all definitions of vector registers using DOT notation 
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\([A-Za-z0-9_\.\\\\$/;]*)(\[[0-9]*\])?([A-Za-z0-9_\.\\\\]*)?  \[[0-9]*:[0-9]*\]', code)
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\(left\.[A-Za-z0-9_\.\\\\$/;]*)(\[[0-9]*\])?([A-Za-z0-9_\.\\\\]*)?  \[[0-9]*:[0-9]*\]', code)
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\(right\.[A-Za-z0-9_\.\\\\$/;]*)(\[[0-9]*\])?([A-Za-z0-9_\.\\\\]*)?  \[[0-9]*:[0-9]*\]', code)
    # logtimefile("\n\t\t\tTime for finding illegal strings: "+ str((timein2- timein1).seconds))
    ids.sort(reverse=True,key=lambda id_: len(id_[0]+id_[1]) )
    list(set(ids))
    # logtimefile("\n\t\t\tTime for processing list: "+ str((timein3- timein2).seconds))
    print(f"Renamed {len(ids)} identifiers in {file}")
    for id_ in ids:
        if testbed:
            if id_ in namedArrays:
                id_ = id_[0] + id_[1] +id_[2]
                code = code.replace("UUT."+id_, "UUT."+rename(id_))
            elif id_ in ids_auto:
                id_ = id_[0] + id_[1] +id_[2]
                code = code.replace("UUT."+id_, "UUT."+rename(id_))
            else:
                id_ = id_[0] + id_[1]
                code = code.replace("UUT."+id_, "UUT."+rename(id_))

        else:
            id_ = id_[0]+id_[1]+id_[2]
            code = code.replace("\\"+id_+" ", rename(id_)+" ")

    with open(file, "w") as f:
        f.write(code)
    timein4 = datetime.now()
    # logtimefile("\n\t\t\tTime for replacing illegal strings: "+ str((timein4- timein3).seconds))
def fixClock(file):
    code = ""
    with open(file, "r") as f:
        code = f.read()

    testbed_clock = "PI_"+CONF.clockInput

    if f"wire [0:0] {testbed_clock} = clock;" not in code:
        ## yosys-smtbmc messed up, we need to fix it :-|
        code = code.replace(f".{CONF.clockInput}({testbed_clock})", f".{CONF.clockInput}(clock)")
        with open(file, "w") as f:
            f.write(code)
        print("Fixed clock signal")
    else:
        print("Yosys-smtbmc correctly assigned the clock signal")
        

def runCounterexample(counterexample, trgObservations, cstrtype, filtertype):
    log("START - RUN CTX")
    time1 = datetime.now()

    outFolder = CONF.outFolder + "/" + filtertype + "_" +cstrtype
    run_process(["cp", "{}/prod_renamed.temp".format(outFolder), "{}/prod.v".format(outFolder)])
 

    # new_trg_equiv = ""
    # if len(trgObservations.keys()) > 0:
    #     new_trg_equiv += "\tassign trg_equiv = {} ;\n".format( " && ".join( ["{}_trg".format(rename(obsId)) for obsId in trgObservations.keys() ] ))
    # print(new_trg_equiv)

    # prod = ""
    # with open("{}/{}".format(outFolder,CONF.prodCircuitTemplate), "r") as f:
    #     lines = f.readlines()   
    #     for line in lines:
    #         if "assign trg_equiv" in line:
    #             prod += new_trg_equiv 
    #         else: 
    #             prod += line
    # with open("{}/{}".format(outFolder,CONF.prodCircuitTemplate), "w+") as f:
    #     f.write(prod)   

    # 1nd hack:
    # yosys-smtbmc sometimes uses the wrong clock signal for the generated testbed
    # we're fixing this manually
    log(f"Check if clock signal need to be fixed in {counterexample}")
    fixClock(counterexample)

    # 2st append display statements to the counterexample
    log(f"Append display statements")
    displayObservations(counterexample, trgObservations, "trg", "ASSERT")

    # 3st hack:
    # iverilog seems to have trouble with using dot notation, which is used by yosys
    # we therefore need to rename stuff in prod.v :-|
    # run_process(["cp", "{}/{}".format(outFolder,counterexample), "{}/{}_non-renamed".format(outFolder,counterexample)])
    log(f"Rename dot notation in {counterexample}")
    # exit(1)
    renameDotNotation(counterexample,testbed=True)
    
    time11 = datetime.now()
    # compile and run counterexample
    log(f"Compile counterexample testbed")
    tb = compileWithIVerilog(counterexample,outFolder)
    time12 = datetime.now()
    log(f"Run counterexample testbed")
    diffInvList = runTestbed(tb)
    time13 = datetime.now()

    time2 = datetime.now()
    logtimefile("\n\t\tTime for analyzing counterexample: "+ str((time2- time1).seconds))
    # logtimefile("\n\t\tTime for renaming prod: "+ str((time11- time1).seconds))
    # logtimefile("\n\t\tTime for iverilog: "+ str((time12- time11).seconds))
    # logtimefile("\n\t\tTime for VVP: "+ str((time13- time12).seconds))
    run_process(["rm", "{}/prod.v".format(outFolder)])
    log("END - RUN CTX")
    # exit(1)
    return diffInvList


