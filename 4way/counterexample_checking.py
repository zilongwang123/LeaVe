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
    cycles = ctx.split(">>>>>")[1:]
        
    diffInvList = []
    diffcycle = False
    cycleNr = 0
    for cycle in cycles:
        if diffcycle:
            break
        else:
            invs = cycle.split("\n")
            for inv in invs:
                tbname = inv.split(" ")
                if (tbname[-1] == "0" or tbname[-1] == "x") and len(tbname) == 2 and tbname[0].endswith("_trg"):
                    name = tbname[0].split("_trg")[0].split(".")[-1]
                    diffInvList.append(name)
                    diffcycle = True
        if cycleNr > 0:
            diffcycle = True
        cycleNr = cycleNr + 1
    print("diff: ",diffInvList)
    return diffInvList ## Why are we returning -1?
                    


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
                    displayObs += f"\t\t$display(\"{var} %b =?= %b\", {CONF.yosysCtxUUT}.{var}_left,  {CONF.yosysCtxUUT}.{var}_right);\n"
        displayObs += "\tend\n"
        displayObs += "endmodule\n"

        code = code.replace("endmodule", displayObs)
        with open(counterexample, "w") as f:
            f.write(code)


def rename(id_):
    # print("id_: ", id_)
    renamed = "renamed_"+id_.replace(".","_").replace("[","___").replace("]","").replace("\\","").replace("$","_").replace("/","_").replace(":","_")
    return renamed

def renameDotNotation(file, testbed: bool):

    code = ""
    with open(file, "r") as f:
        code = f.read()

    #1) find all occurrences of . notation
    if testbed:
        #ids = re.findall('UUT\.([A-Za-z0-9_\.\\]*)(\[[A-Za-z0-9\']*\])?[A-Za-z0-9_\.\\\\]*', code)
        ids = re.findall('UUT\.(left\.[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)? =', code)  
        ids += re.findall('UUT\.(right\.[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)? =', code)
        ids += re.findall('UUT\.(left_trg\.[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)? =', code)  
        ids += re.findall('UUT\.(right_trg\.[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)? =', code)
        ids += re.findall('UUT\.(left_src\.[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)? =', code)  
        ids += re.findall('UUT\.(right_src\.[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)? =', code)
        # rename the variables defined in the prod.v start with "\\"
        namedArrays = re.findall('UUT\.(\\\\[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)?', code)
        # currently yosys puts two spaces before the assignment whenever the [..] is used as part of an identifier :-\
        namedArrays += re.findall('UUT\.(left\.\\\\[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)?  =', code)  # UUT.left.\IACK_reg[7]  =
        namedArrays += re.findall('UUT\.(right\.\\\\[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)?  =', code)
        
        namedArrays += re.findall('UUT\.(left_trg\.\\\\[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)?  =', code)  # UUT.left.\IACK_reg[7]  =
        namedArrays += re.findall('UUT\.(right_trg\.\\\\[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)?  =', code)

        namedArrays += re.findall('UUT\.(left_src\.\\\\[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)?  =', code)  # UUT.left.\IACK_reg[7]  =
        namedArrays += re.findall('UUT\.(right_src\.\\\\[A-Za-z0-9_\.]*)(\[[A-Za-z0-9\']*\])?(?:[A-Za-z0-9_$:/]*)?  =', code)


        ids+=namedArrays
    else:
        # We are renaming prod.v
        # yosys syntax for dot notation is "\xx.yy.zz"
        # These should be all definitions of registers and wires using DOT notation 
        ids = re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\([A-Za-z0-9_\.\\\\$:/]*)(\[[0-9]*\])?(?:[A-Za-z0-9_$:/]*)? (?:;| =)', code)  #  wire [31:0] \IOMUX[0]_obs_trg_arg0_trg_left ;
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\(left\.[A-Za-z0-9_\.\\\\$:/]*)(\[[0-9]*\])? (?:;| =)', code)
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\(right\.[A-Za-z0-9_\.\\\\$:/]*)(\[[0-9]*\])? (?:;| =)', code)

        # These should be all definitions of vector registers using DOT notation 
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\([A-Za-z0-9_\.\\\\$:/]*)(\[[0-9]*\])?([A-Za-z0-9_\']*)?  \[[0-9]*:[0-9]*\]', code)
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\(left\.[A-Za-z0-9_\.\\\\$:/]*)(\[[0-9]*\])?  \[[0-9]*:[0-9]*\]', code)
        ids += re.findall('(?:wire|reg) (?:\[[0-9]*:[0-9]*\] )?\\\\(right\.[A-Za-z0-9_\.\\\\$:/]*)(\[[0-9]*\])?  \[[0-9]*:[0-9]*\]', code)
    ids.sort(reverse=True,key=lambda id_: len(id_[0]+id_[1]) )
    print(f"Renamed {len(ids)} identifiers in {file}")
    for id_ in ids:
        if testbed:
            if id_ in namedArrays:
                id_ = id_[0] + id_[1]
                code = code.replace("UUT."+id_, "UUT."+rename(id_))
            else:
                id_ = id_[0]
                code = code.replace("UUT."+id_, "UUT."+rename(id_))
        else:
            id_ = id_[0]+id_[1]
            code = code.replace("\\"+id_, rename(id_))

    with open(file, "w") as f:
        f.write(code)

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
        

def runCounterexample(counterexample, srcObservations, trgObservations, cstrtype, filtertype):
    log("START - RUN CTX")
    time1 = datetime.now()

    outFolder = CONF.outFolder + "/" + filtertype + "_" +cstrtype
    # 1st hack:
    # yosys-smtbmc sometimes uses the wrong clock signal for the generated testbed
    # we're fixing this manually
    log(f"Check if clock signal need to be fixed in {counterexample}")
    fixClock(counterexample)

    # 2nd append display statements to the counterexample
    log(f"Append display statements")
    displayObservations(counterexample, srcObservations, "src", "ASSUME")
    displayObservations(counterexample, trgObservations, "trg", "ASSERT")

    # 3rd hack:
    # iverilog seems to have trouble with using dot notation, which is used by yosys
    # we therefore need to rename stuff in prod.v :-|
    log(f"Rename dot notation in {counterexample}")
    renameDotNotation(counterexample,testbed=True)
    log(f"Rename dot notation in {outFolder}/{CONF.prodCircuitTemplate}")
    renameDotNotation(f"{outFolder}/{CONF.prodCircuitTemplate}", testbed=False)
    time2 = datetime.now()
    logtimefile("\n\tTime for renameing: "+ str((time2- time1).seconds))
    # compile and run counterexample
    log(f"Compile counterexample testbed")
    tb = compileWithIVerilog(counterexample,outFolder)
    time3 = datetime.now()
    logtimefile("\n\tTime for iverilog: "+ str((time3- time2).seconds))
    log(f"Run counterexample testbed")
    diffInvList = runTestbed(tb)
    time4 = datetime.now()
    logtimefile("\n\tTime for analyzing counterexample: "+ str((time4- time3).seconds))
    log("END - RUN CTX")
    return diffInvList


