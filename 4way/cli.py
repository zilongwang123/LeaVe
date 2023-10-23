from __future__ import absolute_import
from __future__ import print_function
import sys
import os
import yaml
from optparse import OptionParser
from util import *
from datetime import datetime 


from config import CONF
from preprocessing import preprocessing, preprocessing4way
from verification import verify, verify4way
from counterexample_checking import runCounterexample
from invariant import initInvariant
from invariant import refineInvariant

## TODO
# 1. better error handling :-\



def microEquivCheck(srcObservations, trgObservations, invariant, stateInvariant, auxVars, metaVars,  srcToexpandArray , trgToexpandArray, filtertype):
    counter = 1
    basepass = False
    starttime = datetime.now() 
    while(invariant):
        logfile("\nBegin the {}th loop...\n".format(counter))
        logtimefile("\nTime for the {}th loop...\n".format(counter))
        counter+=1
        logfile("\tThe invariant for verification is:\n" + "".join(inv2str(invariant)))
        if not basepass: 
            preprocessing4way(srcToexpandArray, trgToexpandArray, filtertype + "_"+"base")

            # 1.1 verification_base
            print("Checking the base case")
            logfile("\n3.1. Checking the micro-equivalence relation...\n")
            logfile("\n3.1.1. Checking the base case...\n")
            verifStatus, cex, srcObs, inv = verify4way(srcObservations, invariant, stateInvariant, auxVars, metaVars, "base", filtertype)
            if verifStatus == "FAIL":
                diffInvList = runCounterexample(cex, [], inv, "base", filtertype)
                logfile("  The base step is not satisfied!\n" + "\tthe difference set of invariant is:\n------\n"+ "\n".join(diffInvList)+"\n------\n")
                print("The base case is not satisfied!")
                #exit(1)
                if diffInvList == []:
                    logfile("  Nothing learned from counterexample! The result is UNKNOWN!")
                    print("Nothing learned from counterexample!")
                    return False
                invariant = refineInvariant(invariant, diffInvList)
                continue
            else:
                basepass = True
                logfile("  The base case is satisfied!\n")
                basetime = datetime.now()
                continue
        else:
            # 1.2 verification_inductive
            preprocessing4way(srcToexpandArray, trgToexpandArray, filtertype + "_"+"induction")
            print("  Checking the inductive step")
            logfile("\n\t Checking the inductive step...\n")
            verifStatus, cex, srcObs, inv = verify4way(srcObservations, invariant, stateInvariant, auxVars, metaVars, "induction", filtertype)
            if verifStatus == "FAIL":
                print("The induction step is not satisfied!")
                diffInvList = runCounterexample(cex, [], inv, "induction", filtertype)
                logfile("\tThe induction step is not satisfied!\n" + "\tthe difference set of invariant is:\n------\n"+ "\n".join(diffInvList)+"\n------\n")
                #exit(1)
                if diffInvList == []:
                    print("Nothing learned from counterexample!")
                    logfile("\tNothing learned from counterexample! The result is UNKNOWN!")
                    return False
                invariant = refineInvariant(invariant, diffInvList)
                continue
            else:
                logfile("\tThe induction step is satisfied!\n")
                invtime = datetime.now()
                preprocessing4way(srcToexpandArray, trgToexpandArray, filtertype + "_"+"check")
                logfile("\n\tChecking the relation between target and invariant...\n")
                logfile("\tThe invariant for checking is:\n" + "".join(inv2str(invariant)))
                print("Checking the relation between target and invariant")
                verifStatus, cex, srcObs, trgObs = verify(invariant, trgObservations, stateInvariant, auxVars, metaVars, "check", filtertype)
                print("The invariant used to prove the security: \n",invariant)
                checktime = datetime.now()
                if verifStatus == "FAIL":
                    runCounterexample(cex, [], trgObs, "check", filtertype)
                    logfile("  \n\tThe contract checked is not satisfied!\n")
                    print("INSECURE")
                    logfile("\n\tTime for base step: "+ str((basetime- starttime).seconds))
                    logfile("\n\tTime for induction step: "+ str((invtime - basetime).seconds))
                    logfile("\n\tTime for generating invariant: "+ str((invtime - starttime).seconds))
                    logfile("\n\tTime for checking: "+ str((checktime - invtime).seconds))
                    return False
                else:
                    print("SECURE")
                    logfile("\n\tTime for base step: "+ str((basetime - starttime).seconds))
                    logfile("\n\tTime for induction step: "+ str((invtime - basetime).seconds))
                    logfile("\n\tTime for generating invariant: "+ str((invtime - starttime).seconds))
                    logfile("\n\tTime for checking: "+ str((checktime - invtime).seconds))
                    return True
    print("No invariant found! The contract checked is not satisfied!")
    logfile("  \n\t No invariant found! The contract checked is not satisfied!\n")
    return False

def main():
    INFO = "Verification of contract satisfaction"
    VERSION = "0.0 :-|"
    USAGE = "Usage: python cli.py configFile"

    def showVersion():
        print(INFO)
        print(VERSION)
        print(USAGE)
        sys.exit()

    optparser = OptionParser()
    optparser.add_option("-v", "--version", action="store_true", dest="showversion",
                         default=False, help="Show the version")
    # optparser.add_option("-h", "--help", action="store_true", dest="showhelp",
                        #  default=False, help="Show the help")
    optparser.add_option("-I", "--include", dest="include", action="append",
                         default=[], help="Include path")
    optparser.add_option("-D", dest="define", action="append",
                         default=[], help="Macro Definition")
    optparser.add_option("-c", dest="clk", action="append",
                         default='clk', help="Clock Signal Name")                        
    (options, args) = optparser.parse_args()

    filelist = args
    if options.showversion: # or options.showhelp:
        showVersion()

    for f in filelist:
        if not os.path.exists(f):
            raise IOError("file not found: " + f)

    if len(filelist) == 0:
        showVersion()

    ## Init configuration
    configFile = filelist[0]
    
    if getattr(args, 'verbose', 0):
        CONF.set('verbose', 1)
    with open(configFile, "r") as f:
        config_update: Dict = yaml.safe_load(f)
    for var, value in config_update.items():
        CONF.set(var, value)

    if CONF.selfCompositionEquality == "==":
        CONF.selfCompositionInequality = "!="
    if CONF.selfCompositionEquality == "===":
        CONF.selfCompositionInequality = "!=="

    run_process(["rm", "logfile"], CONF.verbose_preprocessing)
    run_process(["rm", "logtimefile"], CONF.verbose_preprocessing)
    logfile("1. Preparing the environment for verification....\n")
    run_process(["rm", "-rf", CONF.outFolder], CONF.verbose_preprocessing)
    run_process(["mkdir", CONF.outFolder], CONF.verbose_preprocessing)
    #'''
    logfile("\n2. Initializing for the leakage ordering check...\n")
    
    # initialize the invariants
    auxVars, to_expand, invariant = initInvariant("nondeleyed")#invariant = CONF.invariant

    # generating toexpandArray
    trgToexpandArray = CONF.trgExpandArrays + to_expand
    srcToexpandArray = CONF.srcExpandArrays

    # normal pipeline invariant
    stateInvariant = CONF.stateInvariant
    # source observations
    srcObservations = CONF.srcObservations
    # target observations
    trgObservations = CONF.trgObservations
    # meta variables
    metaVars = CONF.metaVars
    
    logfile("\n3. Start the leakage ordering check...\n")
    if microEquivCheck(srcObservations, trgObservations, invariant, stateInvariant, auxVars, metaVars, srcToexpandArray , trgToexpandArray, "nondeleyed"):
        logfile("\nThe leakage ordering check is satisfied\n")
        # logfile("\n4. Initializing for the leakage ordering check for predicates...\n")
        # # initialize the invariants
        # auxVars, to_expand, invariant = initInvariant("one-cycle-delayed")#invariant = CONF.invariant
        # # generating toexpandArray
        # toexpandArray = to_expand + CONF.expandArrays
        # # normal pipeline invariant
        # stateInvariant = CONF.stateInvariant
        # # source observations
        # srcObservations = CONF.filteredSrcObservations
        # # target observations
        # trgObservations = CONF.predicatePI
        # # meta variables
        # metaVars = CONF.metaVars
        # if microEquivCheck(srcObservations, trgObservations, invariant, stateInvariant, auxVars, metaVars, toexpandArray, "one-cycle-delayed"):
        #     logfile("\nThe leakage ordering check for predicates is satisfied\n")
        logfile("\nThe contract checked is satisfied\n")
        #     exit(1)
        # else:
        #     logfile("\nThe leakage ordering check for predicates is not satisfied\n")
        #     logfile("\nThe contract checked is not satisfied\n")
        #     exit(1)
    else: 
        logfile("\nThe leakage ordering check is not satisfied\n")
        logfile("\nThe contract checked is not satisfied\n")
        exit(1)


  
if __name__ == '__main__':
    main()
