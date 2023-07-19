from __future__ import absolute_import
from __future__ import print_function
import sys
import os
import yaml
from optparse import OptionParser
from lark import Lark, tree, Token, Visitor
import re
import math
from datetime import datetime 
from typing import List

from config import CONF
from util import *

ctr = 0

def log(msg):
    global ctr
    if CONF.verbose_verification:
        print(f">>> Verification {ctr}) {msg}")
        ctr += 1

## Parsing expressions

expr_grammar = r"""
    !expr: wire
        | concatexpr
        | uexpr
        | binexpr
        | parenexpr
        | (whitespace)? expr (whitespace)?
    !parenexpr:   "("  expr  ")"
    !uexpr: uop expr
    !binexpr: expr binop expr
    !concatexpr: "{"  expr ("," expr)+ "}"
    !uop: "!" | "~"
    !binop: "+" | "-" | "*" | "%"
        | "&&" | "||" | "==" | "!==" | "!="
    !wire: var
        | escapedvar 
        | value
        | var (whitespace)? "[" (whitespace)? NUMBER (whitespace)? "]"
        | escapedvar whitespace  "[" (whitespace)? NUMBER (whitespace)? "]"
        | var (whitespace)? "[" (whitespace)? NUMBER (whitespace)? ":" (whitespace)? NUMBER (whitespace)? "]"
        | escapedvar whitespace  "[" (whitespace)? NUMBER (whitespace)? ":" (whitespace)? NUMBER (whitespace)? "]"
        | "`" NAME
    !var: NAME
    !escapedvar: "\\" (NAME | NUMBER | "\\" | "{" | "}" | "." | "$" | "[" | "]")*
    !value: NUMBER
        | NUMBER "'b" ("0"|"1")+
        | NUMBER "'d" HEXDIGIT+
        | NUMBER "'h" HEXDIGIT+     
    !whitespace: (WS | WS_INLINE)+
    %import common.CNAME -> NAME
    %import common.NUMBER
    %import common.HEXDIGIT
    %import common.WS_INLINE
    %import common.WS
 """
# expr_grammar = r"""
#     !expr: wire
#         | concatexpr
#         | uexpr
#         | binexpr
#         | parenexpr
#     !parenexpr: "(" expr ")"
#     !uexpr: uop expr
#     !binexpr: expr binop expr
#     !concatexpr: "{" expr ("," expr)+ "}"
#     !uop: "!" | "~"
#     !binop: "+" | "-" | "*" | "%"
#         | "&&" | "||" | "==" | "!=="
#     !wire: var
#         | value
#         | var "[" NUMBER "]"
#         | var "[" NUMBER ":" NUMBER "]"
#         | "`" NAME
#     !var:  ("\\")? NAME ( "." ("\\")? NAME )*
#     !value: NUMBER
#         | NUMBER "'b" ("0"|"1")+
#         | NUMBER "'h" HEXDIGIT+     
#     %import common.CNAME -> NAME
#     %import common.NUMBER
#     %import common.HEXDIGIT
#     %import common.WS_INLINE
#     %import common.WS
#     %ignore WS
#     %ignore WS_INLINE
# """

parser = Lark(expr_grammar, start='expr', ambiguity='resolve') # ambiguity='explicit' blows up expansion

####
#### Helper functions for product circuit
####



def selfCompositionObservationEquivalence(wireId, obsDict, prefix):
    condition = ""
    for obsId in obsDict.keys():
        condition += "\t{}\n".format(selfCompositionEquivConstraint(obsId, obsDict[obsId], prefix))
    if len(obsDict.keys()) > 0:
        if wireId == "src_equiv":
            condition+="\twire {} = ( ! ( Retire_obs_trg_arg0_trg_right && Retire_obs_trg_arg0_trg_left ) ) || ( {} ) ;\n".format(wireId, " && ".join( ["{}_{}".format(obsId, prefix) for obsId in obsDict.keys() ] ))
        else:
            condition+="\twire {} = {} ;\n".format(wireId, " && ".join( ["{}_{}".format(obsId, prefix) for obsId in obsDict.keys() ] ))
    # if len(obsDict.keys()) > 0:
    #     condition+="\twire {} = {} ;\n".format(wireId, " && ".join( ["{}_{}".format(obsId, prefix) for obsId in obsDict.keys() ] ))
        return condition
    else:
        return ""

def selfCompositionStateInvariant(wireId, invVars, prefix):
    condition = ""
    for obsId in invVars.keys():
        condition += "\t{}\n".format(selfCompositionInvsConstraint(obsId, invVars[obsId], prefix))
    if len(invVars.keys()) > 0:
        condition+="\twire {} = {} ;\n".format(wireId, " && ".join( ["{}_{}".format(obsId, prefix) for obsId in invVars.keys() ] ))
        return condition
    else:
        return ""


def selfCompositionAssume(wireId):
    return f"\tassume property ({wireId});\n"

def selfCompositionAssert(wireId):
    return f"\tassert property ({wireId});\n"

def selfCompositionOnInit(wireId, init, var):
    return  f"\twire {wireId} = ({init} {CONF.selfCompositionInequality} 0) || ({var}) ;\n"

def selfCompositionOnCounter(wireId, counter, var1, var2):
    return  f"\twire {wireId} = ({counter} > 1) || ({var1} && {var2}) ;\n"

def selfCompositionVariableEquivalence(wireId, vars, prefix):
    args1 = []  # without init value
    args2 = []  # with init value
    val = {}
    for varId in vars.keys():
        for var in vars[varId]:
            if  var.get("val") == None or var.get("val") == "":
                args1.append(var.get("var"))
            else:
                args2.append(var.get("var"))
                val[var.get("var")] = var.get("val")

    if len(vars.keys()) > 0:
        constraint = ""
        constraint += "\twire {} =  {} ;\n".format(wireId, 
                    " && ".join(
                        [ "{} {} {}".format("{}_{}_right".format(arg,prefix), CONF.selfCompositionEquality, "{}_{}_left".format(arg,prefix)) for arg in args1 + args2]
                        +
                        [ "{} {} {}".format("{}_{}_right".format(arg,prefix), CONF.selfCompositionEquality, val[arg]) for arg in args2]
                        ) )
        return constraint
    else:
        return ""

def selfCompositionAttrsConstraint(arg, cstrType):
    constraint = "" 
    
    constraint = "{} {} {}".format("{}_{}_right".format(arg.get("var"), cstrType), CONF.selfCompositionEquality, "{}_{}_left".format(arg.get("var"), cstrType))
    return constraint


def selfCompositionInvsAttrsConstraint(arg, cstrType):
    constraint = "" 
    if arg.get("init") == "1":
        constraint = "( (init != 0) || ( {} && {} ) )".format("{}_{}_right".format(arg.get("var"), cstrType), "{}_{}_left".format(arg.get("var"), cstrType))
    else:
        constraint = "( {} && {} )".format("{}_{}_right".format(arg.get("var"), cstrType), "{}_{}_left".format(arg.get("var"), cstrType))
    return constraint

def selfCompositionEquivConstraint(obsId, observations, cstrType):
    args = []
    for obs in observations:
        if obs.get("var").endswith("_cond"):
            cond = obs.get("var")
        else:
            args.append(obs)
    if len(args) == 0:
        constraint = "wire {}_{} = {} {} {} ;".format( obsId, cstrType, "{}_{}_right".format(cond, cstrType), CONF.selfCompositionEquality, 
        "{}_{}_left".format(cond, cstrType) )
    else:
        constraint = "wire {}_{} = {} {} {} && (! {} || ( {} ) ) ;".format(obsId, cstrType, "{}_{}_right".format(cond, cstrType), CONF.selfCompositionEquality,
            "{}_{}_left".format(cond, cstrType), "{}_{}_right".format(cond, cstrType), 
            " && ".join([selfCompositionAttrsConstraint(arg, cstrType) for arg in args]) )
    return constraint

def selfCompositionInvsConstraint(obsId, observations, cstrType):
    args = []
    for obs in observations:
        if obs.get("var").endswith("_cond"):
            cond = obs.get("var")
        else:
            args.append(obs)

    constraint = "wire {}_{} = {} ;".format(obsId, cstrType, " && ".join([selfCompositionInvsAttrsConstraint(arg, cstrType) for arg in args]) )
    return constraint


def selfCompositionCycleDelayedCheck(clock, delay, cstrType):
    verificationConditions = ""
    verificationConditions += "\t// auxiliary register for Bound and Counter\n"
    if cstrType == "base":
        verificationConditions += f"\treg  [{ math.floor( math.log2(int(delay) + 1) ) + 1} : 0 ] bound = {delay};\n"
        verificationConditions += f"\treg  [{ math.floor( math.log2(int(delay) + 1) ) + 1} : 0 ] counter = 1;\n"
    elif cstrType == "inductive":
        verificationConditions += f"\treg  [{ math.floor( math.log2(int(delay) + 1) ) + 1} : 0 ] bound = {delay} + 1 ;\n"
        verificationConditions += f"\treg  [{ math.floor( math.log2(int(delay) + 1) ) + 1} : 0 ] counter = 2;\n"
    verificationConditions += "\talways @ (posedge {}) begin\n".format(clock)
    verificationConditions += f"\t\tif (counter > 0) begin\n"
    verificationConditions += f"\t\t\tcounter <= counter - 1;\n"
    verificationConditions += "\t\tend\n"
    verificationConditions += f"\t\tif (bound > 0) begin\n"
    verificationConditions += f"\t\t\tbound <= bound - 1;\n"
    verificationConditions += "\t\tend\n"
    verificationConditions += "\tend\n"

    verificationConditions += "\t// update the states for verification\n"
    verificationConditions += f"\treg state_trg_equiv = 1;\n"
    verificationConditions += f"\treg init_state_trg_equiv = 1;\n"
    verificationConditions += "\talways @ (posedge {}) begin\n".format(clock)
    verificationConditions += f"\t\tif (counter > 0) begin\n"
    verificationConditions += f"\t\t\tstate_trg_equiv <= state_trg_equiv && trg_equiv;\n"
    verificationConditions += "\t\tend\n"

    if cstrType == "inductive":
        verificationConditions += f"\t\tif (counter > 1) begin\n"
        verificationConditions += f"\t\t\tinit_state_trg_equiv <= init_state_trg_equiv && trg_equiv;\n"
        verificationConditions += "\t\tend\n"

    verificationConditions += "\tend\n\n"
    verificationConditions += "\twire fin_state_trg_equiv = ( bound > 0 ) ||  state_trg_equiv ;\n"
    
    if cstrType == "inductive":
        verificationConditions += selfCompositionAssume("init_state_trg_equiv")
    elif cstrType == "base":
        verificationConditions += selfCompositionAssume("init_state_equiv")
    verificationConditions += selfCompositionAssume("src_equiv")
    verificationConditions += selfCompositionAssume("state_invariant")
    verificationConditions += selfCompositionAssert("fin_state_trg_equiv")

    return verificationConditions



def selfCompositionPrefixCheck(clock, bound, filtertype = "nondelayed"):
    verificationConditions = ""
    verificationConditions += "\t// auxiliary register for Counter\n"
    verificationConditions += f"\treg  [{ math.floor( math.log2(int(bound)) ) + 1} : 0 ] counter = {bound};\n"
    verificationConditions += "\talways @ (posedge {}) begin\n".format(clock)
    verificationConditions += f"\t\tcounter <= counter - 1;\n"
    verificationConditions += "\tend\n"

    verificationConditions += "\t// update the states for verification\n"
    verificationConditions += f"\treg state_src_equiv = 1;\n"
    verificationConditions += f"\treg state_trg_equiv = 1;\n"
    verificationConditions += "\talways @ (posedge {}) begin\n".format(clock)
    verificationConditions += f"\t\tstate_src_equiv <= state_src_equiv && src_equiv;\n"
    verificationConditions += f"\t\tstate_trg_equiv <= state_trg_equiv && trg_equiv;\n"
    verificationConditions += "\tend\n\n"
    if filtertype =="nondelayed":
        verificationConditions += selfCompositionOnCounter("counter_state_src_equiv", "counter", "state_src_equiv", "src_equiv")
    else:
        verificationConditions += selfCompositionOnCounter("counter_state_src_equiv", "counter", "state_src_equiv", "1")
    verificationConditions += selfCompositionAssume("counter_state_src_equiv")
    verificationConditions += selfCompositionOnCounter("init_state_trg_equiv", "counter", "state_trg_equiv", "1")
    verificationConditions += selfCompositionAssume("init_state_trg_equiv")
    verificationConditions += selfCompositionOnCounter("counter_state_trg_equiv", "counter", "state_trg_equiv", "trg_equiv")
    verificationConditions += selfCompositionAssert("counter_state_trg_equiv")
    verificationConditions += "\n"
    return verificationConditions



def selfCompositionVariableDecl(obsDict,  prodType):
    decls = ""
    for obsId in obsDict.keys():
        for obs in obsDict[obsId]:
            var = obs.get("var")
            if obs.get("width") == 1:
                decls += "\twire {}_{}_left ;\n".format(var,prodType)
                decls += "\twire {}_{}_right ;\n".format(var,prodType)
            else:
                decls += "\twire [{}:0] {}_{}_left ;\n".format(obs.get("width")-1, var,prodType)  
                decls += "\twire [{}:0] {}_{}_right ;\n".format(obs.get("width")-1, var,prodType) 
    return decls

def selfCompositionModuleInstantiation(moduleName, side, varsMap):
    moduleInst = "\t{} {} (\n".format(moduleName, side) 
    varsList = []
    for var in varsMap.keys():
            varsList += [ ".{} ( {} )".format(var, varsMap[var])  ]
    moduleInst += ' , \n'.join(["\t\t\t{}".format(var) for var in varsList])
    moduleInst += "\n\t\t);\n"
    return moduleInst

def parseInputs(inputList):
    leftDict = {}
    rightDict = {}
    for i in inputList:
        inputId = i.get("id")
        leftDict[inputId] = i.get("valueLeft")
        rightDict[inputId] = i.get("valueRight")
    return leftDict, rightDict


def constructProductCircuit(outFolder, srcObsVar, trgObsVar, state, invVars, clock, filtertype):

    WIRE_DECLARATION_PLACEHOLDER = "//**Wire declarations**//"
    MODULE_DECLARATION_PLACEHOLDER = "//**Self-composed modules**//"
    INITIAL_STATE_PLACEHOLDER = "//**Initial state**//"
    STATE_INVARIANT_PLACEHOLDER = "//**State invariants**//"
    INIT_REGISTER_PLACEHOLDER = "//**Init register**//"
    STUTTERING_SIGNAL_PLACEHOLDER = "//**Stuttering Signal**//"
    VERIFICATION_CONDITIONS_PLACEHOLDER = "//**Verification conditions**//"
    INVARIANT_ASSERTIONS_PLACEHOLDER = "//**Invariant**//"

    # 0. Read product circuit template
    productCircuit_base = ""
    productCircuit_inductive = ""

    with open("{}/{}".format(outFolder, CONF.prodCircuitTemplate) , 'r') as f:
        productCircuit_base = f.read()
        productCircuit_inductive = productCircuit_base


    # 1. Create wire declarations
    if WIRE_DECLARATION_PLACEHOLDER in productCircuit_base:
        wireDeclaration = ""
        wireDeclaration += "\t// wire declaration\n"
        wireDeclaration += selfCompositionVariableDecl(trgObsVar,  "trg")
        wireDeclaration += selfCompositionVariableDecl(srcObsVar,  "src")
        wireDeclaration += selfCompositionVariableDecl(state,  "state") 
        if invVars:
            wireDeclaration += selfCompositionVariableDecl(invVars,  "inv")         
        wireDeclaration += "\n"
        productCircuit_base = productCircuit_base.replace(WIRE_DECLARATION_PLACEHOLDER, wireDeclaration)
        productCircuit_inductive = productCircuit_inductive.replace(WIRE_DECLARATION_PLACEHOLDER, wireDeclaration)
    else:
        print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {WIRE_DECLARATION_PLACEHOLDER}")
        exit(1)

    # 2. Init register
    if INIT_REGISTER_PLACEHOLDER in productCircuit_base:
        init = CONF.selfCompositionInitVariable
        initRegister = ""
        initRegister += "\t// auxiliary register for initial state\n"
        initRegister += f"\treg {init} = 0;\n"
        initRegister += "\talways @ (posedge {}) begin\n".format(clock)
        initRegister += f"\t\tif ({init} == 0) begin\n"
        initRegister += f"\t\t\t{init} <= 1;\n"
        initRegister += "\t\tend\n"
        initRegister += "\tend\n"
        productCircuit_base = productCircuit_base.replace(INIT_REGISTER_PLACEHOLDER, initRegister)
        productCircuit_inductive = productCircuit_inductive.replace(INIT_REGISTER_PLACEHOLDER, initRegister)
    else:
        init = CONF.initRegister

    # # 3.  stuttering clock
    # if STUTTERING_CLOCK_PLACEHOLDER in productCircuit_base:
    #     stutteringClock = ""
    #     stutteringClock += "\t// Stuttering clock\n"
    #     stutteringClock += f"\treg clk_left = 1 ;\n"
    #     stutteringClock += f"\treg clk_right = 1 ;\n"
    #     stutteringClock += f"\talways @ (clk) begin\n"
    #     stutteringClock += f"\t\t clk_left <= ( Retire_obs_trg_arg0_trg_left && ( ! Retire_obs_trg_arg0_trg_right ) ) ? clk_left : clk ;\n"
    #     stutteringClock += f"\t\t clk_right <= ( Retire_obs_trg_arg0_trg_right && ( ! Retire_obs_trg_arg0_trg_left ) ) ? clk_right : clk ;\n"
    #     stutteringClock += f"\tend\n"
    #     productCircuit_base = productCircuit_base.replace(STUTTERING_CLOCK_PLACEHOLDER, stutteringClock)
    #     productCircuit_inductive = productCircuit_inductive.replace(STUTTERING_CLOCK_PLACEHOLDER, stutteringClock)

    # 3.  stuttering signal
    if STUTTERING_SIGNAL_PLACEHOLDER in productCircuit_base:
        stutteringSignal = ""
        stutteringSignal += "\t// Stuttering signal\n"
        stutteringSignal += f"\twire stuttering_left ;\n"
        stutteringSignal += f"\twire stuttering_right ;\n"
        stutteringSignal += f"\tassign stuttering_left = ( Retire_obs_trg_arg0_trg_left && ( ! Retire_obs_trg_arg0_trg_right ) ) ;\n"
        stutteringSignal += f"\tassign stuttering_right = ( Retire_obs_trg_arg0_trg_right && ( ! Retire_obs_trg_arg0_trg_left ) ) ;\n"
        productCircuit_base = productCircuit_base.replace(STUTTERING_SIGNAL_PLACEHOLDER, stutteringSignal)
        productCircuit_inductive = productCircuit_inductive.replace(STUTTERING_SIGNAL_PLACEHOLDER, stutteringSignal)


    # 3. Instantiate modules
    if MODULE_DECLARATION_PLACEHOLDER in productCircuit_base:
        # 3.11 Read inputs
        leftVarMap, rightVarMap = parseInputs(CONF.inputs)

        # 3.2 Modules
        moduleDeclarations = "\t// self-composed modules\n"

        for obsId in trgObsVar:
            for obs in trgObsVar[obsId]:
                leftVarMap[obs["var"]] = "{}_trg_left".format(obs["var"])
                rightVarMap[obs["var"]] = "{}_trg_right".format(obs["var"])

        for obsId in srcObsVar:
            for obs in srcObsVar[obsId]:
                leftVarMap[obs["var"]] = "{}_src_left".format(obs["var"])
                rightVarMap[obs["var"]] = "{}_src_right".format(obs["var"])

        for obsId in state:
            for obs in state[obsId]:
                leftVarMap[obs["var"]] = "{}_state_left".format(obs["var"])
                rightVarMap[obs["var"]] = "{}_state_right".format(obs["var"])

        for obsId in invVars:
            for obs in invVars[obsId]:
                leftVarMap[obs["var"]] = "{}_inv_left".format(obs["var"])
                rightVarMap[obs["var"]] = "{}_inv_right".format(obs["var"])

        moduleDeclarations += selfCompositionModuleInstantiation(CONF.module, "left", leftVarMap)
        moduleDeclarations += selfCompositionModuleInstantiation(CONF.module, "right", rightVarMap)
        productCircuit_base = productCircuit_base.replace(MODULE_DECLARATION_PLACEHOLDER, moduleDeclarations)
        productCircuit_inductive = productCircuit_inductive.replace(MODULE_DECLARATION_PLACEHOLDER, moduleDeclarations)
    else:
        print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {MODULE_DECLARATION_PLACEHOLDER}")
        exit(1)


    # Verification for base case
    # 4. Low-equivalence constraints
    if INITIAL_STATE_PLACEHOLDER in productCircuit_base:
        initial_state = ""
        if len(state) > 0:
            initial_state += "\t// Initial state\n"
            initial_state += selfCompositionVariableEquivalence("state_equiv", state, "state")
            initial_state += selfCompositionOnInit("init_state_equiv", init, "state_equiv")
            #initial_state += selfCompositionAssume("init_state_equiv")
            initial_state += "\n"
        productCircuit_base = productCircuit_base.replace(INITIAL_STATE_PLACEHOLDER, initial_state)


    # 5. State invariants constraints
    if STATE_INVARIANT_PLACEHOLDER in productCircuit_base:
        state_invariant = ""
        if len(invVars) > 0:
            state_invariant += "\t// State invariant\n"
            state_invariant += selfCompositionStateInvariant("state_invariant", invVars, "inv")
            #state_invariant += selfCompositionAssume("state_invariant")
            state_invariant += "\n"
        productCircuit_base = productCircuit_base.replace(STATE_INVARIANT_PLACEHOLDER, state_invariant)
    

    if VERIFICATION_CONDITIONS_PLACEHOLDER in productCircuit_base:
        verificationConditions = ""
        if filtertype == "delayedcheck":
            # 5. contract equivalence
            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVar, "src")
            verificationConditions += "\n"
            # 6. target equivalence
            verificationConditions += "\t// verification assertion\n"
            verificationConditions += selfCompositionObservationEquivalence("trg_equiv", trgObsVar, "trg")
            verificationConditions += "\n"

            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionCycleDelayedCheck(clock, CONF.cycleDelayed, "base")
            verificationConditions += "\n"
        else:
            if len(state) > 0:
                verificationConditions += selfCompositionAssume("init_state_equiv")
            if len(invVars) > 0:
                verificationConditions += selfCompositionAssume("state_invariant")
            if filtertype == "nondelayed":
                # 5. contract equivalence
                verificationConditions += "\t// contract-equivalence\n"
                verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVar, "src")
                verificationConditions += selfCompositionAssume("src_equiv")
                verificationConditions += "\n"

            # 6. target equivalence
            verificationConditions += "\t// verification assertion\n"
            verificationConditions += selfCompositionObservationEquivalence("trg_equiv", trgObsVar, "trg")
            verificationConditions += "\n"
            verificationConditions += selfCompositionAssert("trg_equiv")
            verificationConditions += "\n"

        productCircuit_base = productCircuit_base.replace(VERIFICATION_CONDITIONS_PLACEHOLDER, verificationConditions)


    # Verification for inductive step
            # 5. Pipeline invariants constraints
    if STATE_INVARIANT_PLACEHOLDER in productCircuit_inductive:
        state_invariant = ""
        if len(invVars) > 0:
            state_invariant += "\t// Pipeline invariant\n"
            state_invariant += selfCompositionStateInvariant("state_invariant", invVars, "inv")
            #state_invariant += selfCompositionAssume("state_invariant")
            state_invariant += "\n"
        productCircuit_inductive = productCircuit_inductive.replace(STATE_INVARIANT_PLACEHOLDER, state_invariant)

    if VERIFICATION_CONDITIONS_PLACEHOLDER in productCircuit_inductive:
        verificationConditions = ""
        if filtertype == "delayedcheck":
            # 5. contract equivalence
            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVar, "src")
            verificationConditions += "\n"
            # 6. target equivalence
            verificationConditions += "\t// verification assertion\n"
            verificationConditions += selfCompositionObservationEquivalence("trg_equiv", trgObsVar, "trg")
            verificationConditions += "\n"

            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionCycleDelayedCheck(clock, CONF.cycleDelayed, "inductive")
            verificationConditions += "\n"

        else :

            # 5. contract equivalence
            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVar, "src")
            verificationConditions += "\n"

            # 6. inductive check on target equivalence
            verificationConditions += "\t// inductive hypothesis and verification assertion\n"
            verificationConditions += selfCompositionObservationEquivalence("trg_equiv", trgObsVar, "trg")
            verificationConditions += "\n"

            verificationConditions += selfCompositionOnInit("init_trg_equiv", init, "trg_equiv")
            
            if len(invVars) > 0:
                verificationConditions += selfCompositionAssume("state_invariant")
            verificationConditions += selfCompositionAssume("src_equiv")
            verificationConditions += selfCompositionAssume("init_trg_equiv")
            verificationConditions += selfCompositionAssert("trg_equiv")
            verificationConditions += "\n"
        productCircuit_inductive = productCircuit_inductive.replace(VERIFICATION_CONDITIONS_PLACEHOLDER, verificationConditions)
    else:
        print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {VERIFICATION_CONDITIONS_PLACEHOLDER}")
        exit(1)

    with open("{}/{}".format(outFolder, CONF.prodCircuitTemplate.replace(".v", "_base.v")) , 'w') as f:
        f.write(productCircuit_base)
    with open("{}/{}".format(outFolder, CONF.prodCircuitTemplate.replace(".v", "_inductive.v")) , 'w') as f:
        f.write(productCircuit_inductive)

#### 
#### Helper functions for metavariables
#### 

def initMetaVars(metavars):
    idx_dict = {}
    for idx in metavars:
        idx_id = idx.get("id")
        if idx_id is not None:
            if idx_id not in idx_dict.keys():
                if idx.get("range") is None:
                    print(f"Missing range for index meta-variables {idx_id}")
                    exit(1)
                idx_dict[idx_id] = idx.get("range")
            else:
                print(f"Duplicated index meta-variable {idx_id}")
                exit(1)
        else:
            print(f"Missing identifier in index meta-variable {idx}")
            exit(1)
    return idx_dict

def expandMetaVariable(var: str, rng: int, dict_):
    newDict = {}
    for in_ in dict_.keys():
        in_idxs = getIndexMetaVariables(in_)
        if var in in_idxs:
            for i in range(rng):
                in_new = replaceIndexMetaVariable(in_, var, str(i))
                if in_new in dict_.keys():
                    print(f"Duplicated identifier {in_new} resulting from expansion process")
                    exit(1)
                if isinstance(dict_[in_], list):
                    l = []
                    for o in dict_[in_]:
                        val_new = {}
                        for k in o.keys():
                            if type(o[k]) is str:
                                val_new[k] = replaceIndexMetaVariable(o[k], var, str(i))
                            else:
                                val_new[k] = o[k]
                        l.append(val_new)
                    newDict[in_new] = l
                elif isinstance(dict_[in_], dict):
                    val_new = {}
                    for k in dict_[in_].keys():
                        if type(dict_[in_][k]) is str:
                            val_new[k] = replaceIndexMetaVariable(dict_[in_][k], var, str(i))
                        else:
                            val_new[k] = dict_[in_][k]
                    newDict[in_new] = val_new
                else:
                    print(f"The values in dictionary {dict_} can only be other dictionaries or lists of dictionaries")
                    exit(1)
        else:
            newDict[in_] = dict_[in_]
    return newDict

####
#### Helper functions for constructing observations and state variables
####

def collectVars(expr):
    varsSet = set()
    # if expr.startswith("\\") and expr.count("["):
    #     print("xxxxxxxxxx",expr)
    #     varsSet.add(expr)
    # else:
    tree = parser.parse(expr)
    for varNode in tree.find_data("var"):
        ## construct varName
        varName = ""
        for child in varNode.children:
            varName += child.value
        varsSet.add(varName)
    for varNode in tree.find_data("escapedvar"):
        ## construct varName
        varName = ""
        for child in varNode.children:
            varName += child.value
        varsSet.add(varName)
    return varsSet

def initAuxVars(auxvars, idx_dict):
    ## auxVar --> {width, value}
    auxVars_dict = {}
    for in_ in auxvars:
        var_id =  in_.get("id")
        if var_id is not None:
            if var_id not in auxVars_dict.keys():
                var_dict = {}

                var_width = in_.get("width")
                if var_width is None:
                    var_dict["width"] = 1
                else:
                    var_dict["width"] = var_width
                
                var_value = in_.get("value")
                if var_value is None:
                    var_dict["value"] = var_id
                else:
                    var_dict["value"] = var_value
                
                auxVars_dict[var_id] = var_dict
            else:
                print(f"Duplicated identifier {var_id}")
                exit(1)
        else:
            print(f"Auxiliary variable {in_} without identifier")
            exit(1)

    ##### 1. Collect meta-variables
    idxs = idx_dict.keys()

    ##### 2. Expand meta-variables
    for idx in idxs:
        auxVars_dict = expandMetaVariable(idx, idx_dict[idx], auxVars_dict)

    ##### 3. Check that values of aux variables are wires/vars
    for var in auxVars_dict.keys():
        tree = parser.parse(auxVars_dict[var]["value"])
        wires = tree.find_data("wire")
        flag = False
        for w in wires:
            if flag:
                print("The value {} of variable {} is not a wire!".format(auxVars_dict[var]["value"], var))
                exit(1)
            flag = True
            break

    return auxVars_dict



def initObservations(observations, auxVars_dict, idx_dict, prefix):
    ##### 1. Parse observations 
    obs_dict = {} ## obsId -> [ condObs, argObs ]
    for obs in observations:
        obsId = obs.get("id")
        if obsId in obs_dict.keys():
            print(f"Duplicated observation id {obsId}")
            exit(1)
        condObs = { "var" : "{}_{}_cond".format(obsId, prefix) , "expr" : obs.get("cond") , "width" : 1 }
        obs_dict[obsId] = [condObs] 
        idx=0
        for attr in obs.get("attrs"):
            if attr.get("width") is None:
                width = 1 
            else:
                width = attr.get("width")
            if attr.get("init") is None:
                init = "none"
            else:
                init = attr.get("init")
            argObs = { "var" : "{}_{}_arg{}".format(obs.get("id"), prefix, idx) , "expr" : attr.get("value") , "width" : width, "init": init}
            obs_dict[obsId].append(argObs)
            idx=idx+1

    ##### 2. Expand observations (instantiate meta-vars)
    idxs = idx_dict.keys()
    for idx in idxs:
        obs_dict = expandMetaVariable(idx, idx_dict[idx], obs_dict)

    ##### 3. Update auxVars dictionary
    for obsId in obs_dict.keys():
        for obs in obs_dict[obsId]:
            for var in collectVars(obs["expr"]):
                if var not in auxVars_dict.keys():
                    var_dict = {"width": 1, "value": var}
                    auxVars_dict[var] = var_dict

    return obs_dict, auxVars_dict

def initStateVars(variables, auxVars_dict, idx_dict, prefix):
    ##### 1. Parse state variables 
    vars_dict = {} ## varId -> [ expr, width, level ]
    for var in variables:
        varId = var.get("id")
        if varId in vars_dict.keys():
            print(f"Duplicated variable id {varId}")
            exit(1)
        if var.get("width") is None:
            width = 1 
        else:
            width = var.get("width")
        var = { "var": "{}_{}".format(varId, prefix), "expr" : var.get("expr") , "width" : width, "val": var.get("val") }
        vars_dict[varId] = [var] 

    ##### 2. Expand observations (instantiate meta-vars)
    idxs = idx_dict.keys()
    for idx in idxs:
        vars_dict = expandMetaVariable(idx, idx_dict[idx], vars_dict)

    ##### 3. Update auxVars dictionary
    for varId in vars_dict.keys():
        for var_ in vars_dict[varId]:
            for var in collectVars(var_["expr"]):
                if var not in auxVars_dict.keys():
                    var_dict = {"width": 1, "value": var}
                    auxVars_dict[var] = var_dict
    return vars_dict, auxVars_dict


def createModule(outFolder, module, obsDict, inputsDict, suffix):
    inputVars = set()
    outputVars = set()

    for obsId in obsDict.keys():
        for obs in obsDict[obsId]:

            for v in collectVars(obs.get("expr")):
                if v in inputsDict.keys():
                    varWidth = int(inputsDict[v]["width"])
                    if varWidth == 1:
                        inputVars.add(v)
                    else:
                        inputVars.add("[{}:0] {}".format(varWidth-1, v))
                else:
                    print(f"Variable {v} not in dictionary of auxiliary variables")
                    exit(1)

            var = obs.get("var")
            if obs.get("width") == 1:
                outputVars.add(var)
            else:
                outputVars.add("[{}:0] {}".format(obs.get("width")-1, var))

    moduleSrc = "module {} ".format("{}_{}".format(module, suffix))
    moduleSrc += "( "
    moduleSrc += ' , '.join(["input {}".format(var) for var in inputVars] + ["output {}".format(var) for var in outputVars])
    moduleSrc += " );\n"
    for obsId in obsDict.keys():
        for obs in obsDict[obsId]:
            moduleSrc += "\tassign {} = {} ;\n".format(obs.get("var"), obs.get("expr"))
    moduleSrc += "endmodule"

    with open("{}/{}_{}.v".format(outFolder, module, suffix) , 'w') as f:
        f.write(moduleSrc)

####
#### Helper variabels for yosys comamnds
####

def flatten(folder, filename, module):
    yosysScript = ""
    yosysScript += "read_verilog -sv {}/*.v\n".format(folder)
    yosysScript += "hierarchy -top {}\n".format(module)
    yosysScript += "proc -norom\n"
    yosysScript += "flatten\n"
    yosysScript += "select {}\n".format(module)
    # yosysScript += "write_verilog -selected {}/{}.temp\n".format(folder, module)
    return yosysScript


def linkModule(outFolder, module, obsDict, auxVars, suffix):
    yosysScript = ""
    yosysScript += "read_verilog -sv {}/{}_{}.v\n".format(outFolder, module, suffix)
    yosysScript += "select {}\n".format(module)
    yosysScript += "proc -norom\n"
    yosysScript += "addmodule {} {}_{} {}\n".format(module, module, suffix, suffix)
    
    vars_ = set()
    for obsId in obsDict.keys():
        for obs in obsDict[obsId]:
            vars_ = vars_.union( collectVars(obs.get("expr")) )
    for v in vars_:
        yosysScript += "connect -port {} {} {}\n".format(suffix, v, auxVars[v]["value"])

    yosysScript += "expose ".format(module,obs.get("var"))
    for obsId in obsDict.keys():
        for obs in obsDict[obsId]:
            yosysScript += " {}/{}".format(module,obs.get("var"))
    yosysScript += "\n"

    return yosysScript



def finalizeModuleChanges(outFolder, module, script, suffix):
    yosysScript = script
    yosysScript += "hierarchy -top {}\n".format(module)
    yosysScript += "proc -norom\n"
    yosysScript += "flatten\n"
    yosysScript += "add -input stuttering_signal 1\n"
    yosysScript += "stuttering {} stuttering_signal\n".format(module)
    yosysScript += "opt\n"
    yosysScript += "write_verilog -selected {}/{}.v\n".format(outFolder, module)

    with open("{}/{}_yosys.script".format(outFolder,suffix) , 'w') as f:
        f.write(yosysScript)
    cmd = [CONF.yosysPath]
    for m in CONF.yosysAdditionalModules:
        cmd.append(f"-m{m}")
    cmd.append("-s{}/{}_yosys.script".format(outFolder,suffix))
    print(cmd)
    run_process(cmd, CONF.verbose_verification)


####
#### Helper functions for verification
#### 

def inlineObservations(outFolder, metavars, auxvars, observations, module, prefix):
    ### 1. Get meta-variables for indexes
    idx_dict = initMetaVars(metavars)
    ### 2. Get auxiliary variable dictionary
    auxVars_dict = initAuxVars(auxvars, idx_dict)
    ### 3. Build observation dictionary and update auxVars dictionary
    obs_dict, auxVars_dict = initObservations(observations, auxVars_dict, idx_dict, prefix)
    yosysScript = ""
    if len(obs_dict) > 0:
        ### 4. Create observation module
        createModule(outFolder, module, obs_dict, auxVars_dict, "{}".format(prefix))
        ### 5. Link observation module, connect inputs, expose outputs
        yosysScript = linkModule(outFolder, module, obs_dict, auxVars_dict, "{}".format(prefix))
    return obs_dict, yosysScript

def inlineStateVars(outFolder, metavars, auxvars, variables, module, prefix):
    ### 1. Get meta-variables for indexes
    idx_dict = initMetaVars(metavars)
    ### 2. Get auxiliary variable dictionary
    auxVars_dict = initAuxVars(auxvars, idx_dict)
    ### 3. Build observation dictionary and update auxVars dictionary
    vars_dict, auxVars_dict = initStateVars(variables, auxVars_dict, idx_dict, prefix)
    
    yosysScript = ""
    if len(vars_dict) > 0:
        ### 4. Create observation module 
        createModule(outFolder, module, vars_dict, auxVars_dict, "{}".format(prefix))
        ### 5. Link observation module, connect inputs, expose outputs
        yosysScript = linkModule(outFolder, module, vars_dict, auxVars_dict, "{}".format(prefix))
    return vars_dict, yosysScript

def inlinePipelineInvs(outFolder, metavars, auxvars, invariants, module, prefix):
    ### 1. Get meta-variables for indexes
    idx_dict = initMetaVars(metavars)
    ### 2. Get auxiliary variable dictionary
    auxVars_dict = initAuxVars(auxvars, idx_dict)
    ### 3. Build observation dictionary and update auxVars dictionary
    invs_dict, auxVars_dict = initObservations(invariants, auxVars_dict, idx_dict, prefix)
    
    yosysScript = ""
    if len(invs_dict) > 0:
        ### 4. Create observation module 
        createModule(outFolder, module, invs_dict, auxVars_dict, "{}".format(prefix))
        ### 5. Link observation module, connect inputs, expose outputs
        yosysScript = linkModule(outFolder, module, invs_dict, auxVars_dict, "{}".format(prefix))
    return invs_dict, yosysScript


####
#### Main verification routine
####

def precomputing(srcObservations, trgObservations, stateInvariant, auxVars, metaVars, filtertype):
    state = CONF.state
    module = CONF.module
    outFolder = CONF.outFolder


    # construct yosys script
    yosysScript = ""

    log("START")

    time1 = datetime.now()

    ## 1. flatten source and target code
    log(f"Flattening {CONF.module}")
    yosysScript += flatten(outFolder, CONF.moduleFile, CONF.module)
    time2 = datetime.now()
    logtimefile("\n\t\tTime for flatten the source code: "+ str((time2- time1).seconds))

    ## 2. inline target observations
    log("Inline target observations")
    trgObsVar, script = inlineObservations(outFolder, metaVars, auxVars, trgObservations, module, "obs_trg")
    yosysScript += script

    ## 3. inline source observations
    log("Inline src observations")
    srcObsVar, script = inlineObservations(outFolder, metaVars, auxVars, srcObservations, module, "obs_src")
    yosysScript += script

    ## 4. inline state variables
    log("Inline state variables")
    trgStateVars, script = inlineStateVars(outFolder, metaVars, auxVars, state, module, "state_trg")
    yosysScript += script

    ## 5. inline state invariants
    srcInvsVars = []
    if stateInvariant:
        log("Inline state invariants")
        srcInvsVars, script = inlinePipelineInvs(outFolder, metaVars, auxVars, stateInvariant, module, "invariant_src")
        yosysScript += script

    ## 6. Create product circuit
    log("Create product circuit")
    constructProductCircuit(outFolder, srcObsVar, trgObsVar, trgStateVars, srcInvsVars, CONF.clockInput, filtertype)
    run_process(["rm", "{}/{}".format(outFolder, CONF.prodCircuitTemplate)])
    run_process(["mv", "{}/prod_base.v".format(outFolder), "{}/prod_base.temp".format(outFolder)])
    run_process(["mv", "{}/prod_inductive.v".format(outFolder), "{}/prod_inductive.temp".format(outFolder)])
    time25 = datetime.now()
    logtimefile("\n\t\tTime for create observation circuits and prod circuit: "+ str((time25- time2).seconds))
    ## 7. Finalize
    log("Finalize target module changes")
    finalizeModuleChanges(outFolder, module, yosysScript, "trg")
    time3 = datetime.now()
    logtimefile("\n\t\tTime for inline observations: "+ str((time3- time25).seconds))

    ## 8. verify contract satisfaction

    log(f"Generate the product circuit for base step")
    outFolder_base = outFolder + "/" + filtertype +"_base"
    run_process(["cp", "{}/prod_base.temp".format(outFolder), "{}/prod.v".format(outFolder)])
    run_process(["mkdir", "{}".format(outFolder_base)])
    targetName = CONF.prodCircuitTemplate.replace(".v", "")
    yosysScript = ""
    yosysScript += "read_verilog -sv {}/*.v\n".format(outFolder)
    yosysScript += "hierarchy -top {}\n".format(targetName)
    yosysScript += "proc -norom\n"
    yosysScript += "flatten\n".format(targetName)
    yosysScript += "opt\n"
    yosysScript += "write_verilog {}/{}_renamed.temp\n".format(outFolder_base, targetName)
    with open("{}/yosys-verification_base.script".format(outFolder) , 'w') as f:
        f.write(yosysScript)
    cmd = [CONF.yosysPath]
    cmd.append("-s{}/yosys-verification_base.script".format(outFolder))
    run_process(cmd, CONF.verbose_verification)
    run_process(["rm", "{}/prod.v".format(outFolder)])
            
    log(f"Generate the product circuit for inductive step")
    outFolder_inductive = outFolder + "/" + filtertype +"_inductive"
    run_process(["cp", "{}/prod_inductive.temp".format(outFolder), "{}/prod.v".format(outFolder)])
    run_process(["mkdir", "{}".format(outFolder_inductive)])
    targetName = CONF.prodCircuitTemplate.replace(".v", "")
    yosysScript = ""
    yosysScript += "read_verilog -sv {}/*.v\n".format(outFolder)
    yosysScript += "hierarchy -top {}\n".format(targetName)
    yosysScript += "proc -norom\n"
    yosysScript += "flatten\n".format(targetName)
    yosysScript += "opt\n"
    yosysScript += "write_verilog {}/{}_renamed.temp\n".format(outFolder_inductive, targetName)
    with open("{}/yosys-verification_inductive.script".format(outFolder) , 'w') as f:
        f.write(yosysScript)
    cmd = [CONF.yosysPath]
    cmd.append("-s{}/yosys-verification_inductive.script".format(outFolder))
    run_process(cmd, CONF.verbose_verification)
    run_process(["rm", "{}/prod.v".format(outFolder)])
    time4 = datetime.now()
    logtimefile("\n\t\tTime for generating flattened product circuits: "+ str((time4- time3).seconds))


def verify(trgObservations, cstrtype, filtertype):
    state = CONF.state
    module = CONF.module

    outFolder = CONF.outFolder + "/" + filtertype + "_" + cstrtype

    # 1. replace the right trg_equiv in the prod.v
    run_process(["cp", "{}/prod.temp".format(outFolder), "{}/prod.v".format(outFolder)])
 
    trg_obs_dict, auxVars_dict = initObservations(trgObservations, {}, {}, "obs_trg")
 
    new_trg_equiv = ""
    if len(trg_obs_dict.keys()) > 0:
        new_trg_equiv += "\twire trg_equiv = {} ;\n".format( " && ".join( ["{}_trg".format(obsId) for obsId in trg_obs_dict.keys() ] ))
    # print(new_trg_equiv)

    prod = ""
    with open("{}/{}".format(outFolder,CONF.prodCircuitTemplate), "r") as f:
        lines = f.readlines()   
        for line in lines:
            if "wire trg_equiv" in line:
                prod += new_trg_equiv 
            else: 
                prod += line
    with open("{}/{}".format(outFolder,CONF.prodCircuitTemplate), "w+") as f:
        f.write(prod)   


    # 2. run the BMC to get a ctx or pass
    log("Verification")
    verifMode="yosys-smt"
    targetName = CONF.prodCircuitTemplate.replace(".v", "")
    avrPath = CONF.avrPath
    if verifMode == "yosys-smt":
        log(f"Verification with {verifMode}")
        log("SMTLib encoding")
        ## Create smtlib encoding with yosys
        time3 = datetime.now()
        yosysScript = ""
        yosysScript += "read_verilog -sv {}/{}\n".format(outFolder, CONF.prodCircuitTemplate)
        yosysScript += "read_verilog -sv {}/{}\n".format(outFolder, CONF.moduleFile)
        yosysScript += "hierarchy -top {}\n".format(targetName)
        yosysScript += "proc -norom\n"
        yosysScript += "flatten\n".format(targetName)
        yosysScript += "opt\n"
        
        for o in CONF.yosysSMTPreprocessing:
            yosysScript += f"{o}\n"
        # yosysScript += "async2sync\n"
        # yosysScript += "dffunmap\n"
        # yosysScript += "clk2fflogic\n"
        # yosysScript += "scc\n"
        # yosysScript += "write_verilog {}/test.v\n".format(outFolder)
        yosysScript += "write_smt2 -wires {}/{}.smt\n".format(outFolder, targetName)

        with open("{}/yosys-verification.script".format(outFolder) , 'w') as f:
            f.write(yosysScript)
        
        cmd = [CONF.yosysPath]
        cmd.append("-s{}/yosys-verification.script".format(outFolder))

        run_process(cmd, CONF.verbose_verification)
        run_process(["rm", "{}/prod.v".format(outFolder)])
 
        time4 = datetime.now()
        logtimefile("\n\t\tTime for generating prod.smt: "+ str((time4- time3).seconds))
        ## run yosys smt bounded model checker
        # cmd = [CONF.yosysBMCPath, "-s", "z3"]
        log("Bounded model checking")
        cmd = [CONF.yosysBMCPath, "-s", CONF.yosysBMCSolver]
        if cstrtype == "base":
            if filtertype == "delayedcheck":
                cmd += ["-t", str(int(CONF.cycleDelayed)+1)]
            else: 
                cmd += ["-t", str(int(CONF.inductiveyosysBMCBound)-1)]
        elif cstrtype == "inductive":
            if filtertype == "delayedcheck":
                cmd += ["-t", str(int(CONF.cycleDelayed)+2)]
            else: 
                cmd += ["-t", CONF.inductiveyosysBMCBound]
        elif cstrtype == "check":
            cmd += ["-t", CONF.checkyosysBMCBound]
        
        cmd +=["--dump-vlogtb" , "{}/{}_tb.v".format(outFolder, targetName)] 
        cmd += ["--dump-smtc", "{}/{}_smtc".format(outFolder, targetName)]
        cmd += ["--dump-vcd", "{}/{}_trace.vcd".format(outFolder, targetName)]
        cmd += ["--noincr"]
        cmd += ["{}/{}.smt".format(outFolder, targetName)]
        output = run_process(cmd, CONF.verbose_verification)
        time5 = datetime.now()
        logtimefile("\n\t\tTime for BMC: "+ str((time5- time4).seconds))

        if "Status: FAILED" in output:
            log("Verification FAILED")
            return "FAIL","{}/{}_tb.v".format(outFolder, targetName), trg_obs_dict

        elif "Status: PASSED" in output:
            log("Verification PASSED")
            return "PASS", None, trg_obs_dict
        else:
            print("Unknown verification result")
            exit(1)

    if verifMode == "avr":
        ## run AVR 
        log("Verification with {verifMode}")
        run_process(["python3", avrPath,  os.path.abspath("{}/{}.v\n".format(outFolder, targetName)) ])
        



