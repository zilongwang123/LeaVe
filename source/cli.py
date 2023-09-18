from __future__ import absolute_import
from __future__ import print_function
import sys
import os
import yaml
from optparse import OptionParser
from util import *
from datetime import datetime 


from config import CONF
from preprocessing import preprocessing
from verification import verify
from counterexample_checking import runCounterexample
from invariant import initInvariant
from invariant import refineInvariant
from invariant import invariantSubset

## TODO
# 1. better error handling :-\



def microEquivCheck(srcObservations, invariant, stateInvariant, auxVars, metaVars, toexpandArray, filtertype):
    counter = 1
    basepass = False
    starttime = datetime.now() 
    while(invariant):
        logfile("\nBegin the {}th loop...\n".format(counter))
        logtimefile("\n\n\tTime for the {}th loop...".format(counter))
        counter+=1
        logfile("\tThe invariant for verification is:\n" + "".join(inv2str(invariant)))
        if not basepass: 
            # 1.1 verification_base
            print("Checking the base case")
            logfile("\n3.1. Checking the micro-equivalence relation...\n")
            logfile("\n3.1.1. Checking the base case...\n")
            verifStatus, cex, inv = verify(invariant, "base", filtertype)
            print(verifStatus)

            if verifStatus == "FAIL":
                diffInvList = runCounterexample(cex, inv, "base", filtertype)
                logfile("  The base step is not satisfied!\n" + "\tthe difference set of invariant is:\n------\n"+ "\n".join(diffInvList)+"\n------\n")
                print("The base case is not satisfied!")
                if diffInvList == []:
                    logfile("  Nothing learned from counterexample! The result is UNKNOWN!")
                    print("Nothing learned from counterexample!")
                    return False, None
                invariant = refineInvariant(invariant, diffInvList)
                continue
            else:
                basepass = True
                logfile("  The base case is satisfied!\n")
                basetime = datetime.now()
                continue
        else:
            # 1.2 verification_inductive
            print("  Checking the inductive step")
            logfile("\n\t Checking the inductive step...\n")
            verifStatus, cex, inv = verify(invariant, "inductive", filtertype)
            if verifStatus == "FAIL":
                print("The inductive step is not satisfied!")
                diffInvList = runCounterexample(cex, inv, "inductive", filtertype)
                logfile("\tThe inductive step is not satisfied!\n" + "\tthe difference set of invariant is:\n------\n"+ "\n".join(diffInvList)+"\n------\n")
                if diffInvList == []:
                    print("Nothing learned from counterexample!")
                    logfile("\tNothing learned from counterexample! The result is UNKNOWN!")
                    return False, None
                invariant = refineInvariant(invariant, diffInvList)
                continue
            else:
                logfile("\tThe inductive step is satisfied!\n")
                invtime = datetime.now()
                logfile("\tThe invariant learned is:\n" + "".join(inv2str(invariant)))
                print("The invariant learned is: \n",invariant)
                
                logfile("\n\n\tTime for base step: "+ str((basetime- starttime).seconds))
                logfile("\n\tTime for inductive step: "+ str((invtime - basetime).seconds))
                logtimefile("\n\n\tTime for base step: "+ str((basetime- starttime).seconds))
                logtimefile("\n\tTime for inductive step: "+ str((invtime - basetime).seconds))
                return True, invariant
    logfile("  \n\t No invariant found!\n")
    return False, None


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

    # run_process(["rm", "logfile"], CONF.verbose_preprocessing)
    # run_process(["rm", "logtimefile"], CONF.verbose_preprocessing)
    
    run_process(["rm", "-rf", CONF.outFolder], CONF.verbose_preprocessing)
    run_process(["mkdir", CONF.outFolder], CONF.verbose_preprocessing)
    logfile("1. Preparing the environment for verification....\n")
    '''
    logfile("\n2. Initializing for the leakage ordering check...\n")
    
    # initialize the invariants
    auxVars, to_expand, invariant = initInvariant("nondelayed")
    # generating toexpandArray
    toexpandArray = to_expand + CONF.expandArrays
    # normal pipeline invariant
    stateInvariant = CONF.stateInvariant
    # source observations
    srcObservations = CONF.filteredSrcObservations
    # target observations
    trgObservations = CONF.trgObservations + CONF.predicateRetire + CONF.predicatePI
    # meta variables
    metaVars = CONF.metaVars
    time1 = datetime.now() 
    logtimefile("\n1. Start the preprocessing...")
    preprocessing(toexpandArray, srcObservations, invariant, stateInvariant, auxVars, metaVars, "nondelayed")
    time2 = datetime.now() 

    logtimefile("\n\n2. Start the verification...")
    State, invariant = microEquivCheck(srcObservations, invariant, stateInvariant, auxVars, metaVars, toexpandArray, "nondelayed")
    if State:    
        logfile("\n4. Check the satisfaction based on learned strongest attacker.\n")
        if invariantSubset(invariant, trgObservations):
            logfile("\n\tThe CPU is SECURE under the attack w.r.t the contract!!")
        else:
            logfile("\n\tThe CPU is VULNERABLE under the attack w.r.t the contract!!")
    time3 = datetime.now()  
    logtimefile("\n\n\tTime for preprocessing: "+ str((time2- time1).seconds))
    logtimefile("\n\tTime for learning the strongest attacker: "+ str((time3- time2).seconds))
    exit(1)
    
    logfile("\n3. Start the leakage ordering check...\n")
    if microEquivCheck(srcObservations, trgObservations, invariant, stateInvariant, auxVars, metaVars, toexpandArray, "nondelayed"):
        logfile("\nThe contract checked is satisfied\n")
        exit(1)
        logfile("\n4. Initializing for the leakage ordering check for predicates...\n")
        # initialize the invariants
        auxVars, to_expand, invariant = initInvariant("one-cycle-delayed")#invariant = CONF.invariant
        # generating toexpandArray
        toexpandArray = to_expand + CONF.expandArrays
        # normal pipeline invariant
        stateInvariant = CONF.stateInvariant
        # source observations
        srcObservations = CONF.filteredSrcObservations
        # target observations
        trgObservations = CONF.predicatePI
        # meta variables
        metaVars = CONF.metaVars
        if microEquivCheck(srcObservations, trgObservations, invariant, stateInvariant, auxVars, metaVars, toexpandArray, "one-cycle-delayed"):
            logfile("\nThe leakage ordering check for predicates is satisfied\n")
            logfile("\nThe contract checked is satisfied\n")
            exit(1)
        else:
            logfile("\nThe leakage ordering check for predicates is not satisfied\n")
            logfile("\nThe contract checked is not satisfied\n")
            exit(1)
    else: 
        logfile("\nThe leakage ordering check is not satisfied\n")
        logfile("\nThe contract checked is not satisfied\n")
        exit(1)
    #'''

    # large-bound-check
    auxVars, to_expand, invariant = initInvariant("delayedcheck")#invariant = CONF.invariant
    # generating toexpandArray
    toexpandArray = to_expand + CONF.expandArrays
    # normal pipeline invariant
    stateInvariant = CONF.stateInvariant
    # source observations
    srcObservations = CONF.srcObservations
    # target observations
    trgObservations = CONF.trgObservations + CONF.predicateRetire
    # meta variables
    metaVars = CONF.metaVars

    invariant = invariant + CONF.predicateRetire

    time1 = datetime.now() 
    logfile("\n2. Start the delayed leakage ordering check...\n")
    logfile("\n\t2.1 Start the preprocessing...\n")
    logtimefile("1. Start the preprocessing...\n")    
    # print(invariant)
    # exit(1)
    preprocessing(toexpandArray, srcObservations, invariant, stateInvariant, auxVars, metaVars, "delayedcheck")
    time2 = datetime.now() 
    logtimefile("\n\n2. Start the verification...")
    State, invariant = microEquivCheck(srcObservations, invariant, stateInvariant, auxVars, metaVars, toexpandArray, "delayedcheck")
    if State:    
        logfile("\n\n3. Check the satisfaction based on learned strongest attacker.\n")
        if invariantSubset(invariant, CONF.trgObservations):
            logfile("\n\tThe CPU is SECURE under the attack w.r.t the contract!!")
        else:
            logfile("\n\tThe CPU is VULNERABLE under the attack w.r.t the contract!!")
    time3 = datetime.now()  
    logtimefile("\n\n\tTime for preprocessing: "+ str((time2- time1).seconds))
    logtimefile("\n\tTime for learning the strongest attacker: "+ str((time3- time2).seconds))






if __name__ == '__main__':
    main()
