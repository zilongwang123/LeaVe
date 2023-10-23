from __future__ import absolute_import
from __future__ import print_function
import sys
import os
from cairo import TeeSurface
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
        | "&&" | "||" | "==" | "!=="
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

def srcToTrgMapping(wireId, mapping, srcVars, trgVars, prefix ):
    conditions = []
    for map in mapping:
        srcId = map.get("src")
        trgId = map.get("trg")
        srcVar = srcVars[srcId][0]
        trgVar = trgVars[trgId][0]
        if len(srcVars[srcId]) > 1 or len(trgVars[trgId]) > 1:
            print("Unsupported!!!")
            exit(1)

        conditions.append(f"{srcVar.get('var')}_{prefix} {CONF.selfCompositionEquality} {trgVar.get('var')}_{prefix}")

    if len(conditions) > 0:
        return "\twire {} = {} ;\n".format(wireId, " && ".join( conditions ))
    else:
        return ""

def selfCompositionObservationEquivalence(wireId, obsDict, prefix):
    condition = ""
    for obsId in obsDict.keys():
        condition += "\t{}\n".format(selfCompositionEquivConstraint(obsId, obsDict[obsId], prefix))
    if len(obsDict.keys()) > 0:
        condition+="\twire {} = {} ;\n".format(wireId, " && ".join( ["{}_{}".format(obsId, prefix) for obsId in obsDict.keys() ] ))
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

# def selfCompositionOnInit(regId, init, var): 
#     code = f"\treg {regId} = 1;\n"
#     code += f"\talways @ (posedge {CONF.clockInput}) begin\n"
#     code += f"\t\tif ({init} {CONF.selfCompositionInequality} 0) begin\n"
#     code += f"\t\t\t{regId} <= {regId} && {var};\n"
#     code += "\t\tend\n"
#     code += "\tend\n"
#     return  code

def selfCompositionOnCounter(wireId, counter, var1, var2):
    return  f"\twire {wireId} = ({counter} > 1) || ({var1} && {var2}) ;\n"

def selfCompositionAccumulator(regId,clock,var):
    code = f"\treg {regId} = 1;\n"
    code += f"\talways @ (posedge {clock}) begin\n"
    code += f"\t\t {regId} <= {regId} && {var};\n"
    code += "\tend\n"
    return code

def selfCompositionConditionalAcculumator (regId,clock,condition,var):
    code = f"\treg {regId} = 1;\n"
    code += f"\talways @ (posedge {clock}) begin\n"
    code += f"\t\tif ({condition} > 0) begin\n"
    code += f"\t\t\t{regId} <= {regId} && {var};\n"
    code += "\t\tend\n"
    code += "\tend\n"
    return code


def selfCompositionDiscloseAtEnd(wireId, counter, var):
    return f"\twire {wireId} = ({counter} > 1) || ({var}) ;\n"


def selfCompositionAccumulatorAtEnd(regId,clock, cycleCounter, var):
    code = f"\treg {regId}_0 = 1;\n"
    code += f"\talways @ (posedge {clock}) begin\n"
    code += f"\t\t {regId}_0 <= {regId}_0 && {var};\n"
    code += "\tend\n"
    code += selfCompositionOnInit(regId, cycleCounter, f"{regId}_0")
    return code

def selfCompositionVariableEquivalence(wireId, vars, prefix):
    args1 = []  # without init value
    args2 = []  # with init value
    val = {}
    for varId in vars.keys():
        for var in vars[varId]:
            if var.get('lowequivalent'):
                if  var.get("val") == None or var.get("val") == "":
                    args1.append(var.get("var"))
                else:
                    args2.append(var.get("var"))
                    val[var.get("var")] = var.get("val")

    if len(vars.keys()) > 0:
        constraint = ""
        constraint += "\twire {} =  {} ;\n".format(wireId, 
                    " && ".join(
                        [ "{} {} {}".format("{}_right".format(arg,prefix), CONF.selfCompositionEquality, "{}_left".format(arg,prefix)) for arg in args1 + args2]
                        +
                        [ "{} {} {}".format("{}_right".format(arg,prefix), CONF.selfCompositionEquality, val[arg]) for arg in args2]
                        ) )
        return constraint
    else:
        return ""

def selfCompositionAttrsConstraint(arg, cstrType):
    constraint = "" 
    
    constraint = "{} {} {}".format("{}_right".format(arg.get("var")), CONF.selfCompositionEquality, "{}_left".format(arg.get("var")))
    return constraint


def selfCompositionInvsAttrsConstraint(arg, cstrType):
    constraint = "" 
    if arg.get("init") == "1":
        constraint = "( (init != 0) || ( {} && {} ) )".format("{}_right".format(arg.get("var")), "{}_left".format(arg.get("var")))
    else:
        constraint = "( {} && {} )".format("{}_right".format(arg.get("var")), "{}_left".format(arg.get("var")))
    return constraint

def selfCompositionEquivConstraint(obsId, observations, cstrType):
    args = []
    for obs in observations:
        if obs.get("var").endswith("_cond"):
            cond = obs.get("var")
        else:
            args.append(obs)
    if len(args) == 0:
        constraint = "wire {}_{} = {} {} {} ;".format( obsId, cstrType, "{}_right".format(cond), CONF.selfCompositionEquality, 
        "{}_left".format(cond) )
    else:
        constraint = "wire {}_{} = {} {} {} && (! {} || ( {} ) ) ;".format(obsId, cstrType, "{}_right".format(cond), CONF.selfCompositionEquality,
            "{}_left".format(cond), "{}_right".format(cond), 
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
        verificationConditions += f"\treg  [{ math.floor( math.log2(int(delay)) ) + 1} : 0 ] bound = {delay};\n"
        verificationConditions += f"\treg  [{ math.floor( math.log2(int(delay)) ) + 1} : 0 ] counter = 1;\n"
    elif cstrType == "inductive":
        verificationConditions += f"\treg  [{ math.floor( math.log2(int(delay)) ) + 1} : 0 ] bound = {delay} + 1 ;\n"
        verificationConditions += f"\treg  [{ math.floor( math.log2(int(delay)) ) + 1} : 0 ] counter = 2;\n"
    verificationConditions += "\talways @ (posedge {}) begin\n".format(clock)
    verificationConditions += f"\t\tif (counter > 0) begin\n"
    verificationConditions += f"\t\t\tcounter <= counter - 1;\n"
    verificationConditions += "\t\tend\n"
    verificationConditions += f"\t\tif (bound > 0) begin\n"
    verificationConditions += f"\t\t\tbound <= bound - 1;\n"
    verificationConditions += "\t\tend\n"
    verificationConditions += "\tend\n"

    verificationConditions += "\t// update the states for verification\n"
    verificationConditions += f"\treg state_state_equiv = 1;\n"
    verificationConditions += f"\treg state_state_invariant = 1;\n"
    verificationConditions += f"\treg state_src_equiv = 1;\n"
    verificationConditions += f"\treg state_trg_equiv = 1;\n"
    verificationConditions += f"\treg init_state_trg_equiv = 1;\n"
    verificationConditions += f"\treg fin_state_trg_equiv = 1;\n"
    verificationConditions += f"\treg fin_init_state_trg_equiv = 1;\n"
    verificationConditions += "\talways @ (posedge {}) begin\n".format(clock)
    verificationConditions += f"\t\tstate_src_equiv <= state_src_equiv && src_equiv;\n"
    verificationConditions += f"\t\tstate_state_invariant <= state_state_invariant && state_invariant;\n"
    verificationConditions += f"\t\tif (counter > 0) begin\n"
    verificationConditions += f"\t\t\tstate_trg_equiv <= state_trg_equiv && trg_equiv;\n"
    verificationConditions += "\t\tend\n"

    
    if cstrType == "inductive":
        verificationConditions += f"\t\tif (counter > 1) begin\n"
        verificationConditions += f"\t\t\tinit_state_trg_equiv <= init_state_trg_equiv && trg_equiv;\n"
        verificationConditions += "\t\tend\n"
        verificationConditions += f"\t\tif (bound==1) begin\n"
        verificationConditions += f"\t\t\tfin_init_state_trg_equiv <= init_state_trg_equiv;\n"
        verificationConditions += "\t\tend\n"
    elif cstrType == "base":
        verificationConditions += f"\t\tif (counter > 0) begin\n"
        verificationConditions += f"\t\t\tstate_state_equiv <= state_state_equiv && init_state_equiv;\n"
        verificationConditions += "\t\tend\n"

    verificationConditions += f"\t\tif (bound==1) begin\n"   
    verificationConditions += f"\t\t\tfin_state_trg_equiv <= state_trg_equiv;\n"
    verificationConditions += f"\t\tend\n"


    verificationConditions += "\tend\n\n"

    if cstrType == "inductive":
        verificationConditions += selfCompositionAssume("fin_init_state_trg_equiv")
    elif cstrType == "base":
        verificationConditions += selfCompositionAssume("state_state_equiv")
    verificationConditions += selfCompositionAssume("state_src_equiv && src_equiv")
    verificationConditions += selfCompositionAssume("state_state_invariant && state_invariant")
    verificationConditions += selfCompositionAssert("fin_state_trg_equiv")

    return verificationConditions



def selfCompositionPrefixCheck(clock, bound, filtertype = "nondelayed", cstrType = "inductive"):
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
    if cstrType == "inductive":
        verificationConditions += selfCompositionOnCounter("init_state_trg_equiv", "counter", "state_trg_equiv", "1")
        verificationConditions += selfCompositionAssume("init_state_trg_equiv")
    verificationConditions += selfCompositionOnCounter("counter_state_trg_equiv", "counter", "state_trg_equiv", "trg_equiv")
    verificationConditions += selfCompositionAssert("counter_state_trg_equiv")
    verificationConditions += "\n"
    return verificationConditions

def selfCompositionDelayedCheck(clock, m):
    verificationConditions = ""
    verificationConditions += "\t// auxiliary registers for state\n"
    verificationConditions += f"\treg state_src_equiv = 1;\n"
    verificationConditions += f"\treg state_trg_equiv = 1;\n"
    for i in range(int(m)):
        verificationConditions += f"\treg state_trg_equiv_{i+1} = 1;\n"
    verificationConditions += "\talways @ (posedge {}) begin\n".format(clock)
    verificationConditions += f"\t\tstate_src_equiv <= state_src_equiv && src_equiv;\n"
    verificationConditions += f"\t\tstate_trg_equiv_{m} <= state_trg_equiv_{m} && trg_equiv;\n"
    verificationConditions += f"\t\tif ({CONF.retirepredicate}Left) begin\n"
    for i in range(int(m)-1):
        verificationConditions += f"\t\t\tstate_trg_equiv_{i+1} <= state_trg_equiv_{i+2};\n"
    verificationConditions += f"\t\t\tstate_trg_equiv <= state_trg_equiv_1;\n"
    verificationConditions += "\t\tend\n"
    verificationConditions += "\tend\n"

    return verificationConditions


def selfCompositionVariableDecl(obsDict):
    decls = ""
    for obsId in obsDict.keys():
        for obs in obsDict[obsId]:
            var = obs.get("var")
            if obs.get("width") == 1:
                decls += "\twire {}_left ;\n".format(var)
                decls += "\twire {}_right ;\n".format(var)
            else:
                decls += "\twire [{}:0] {}_left ;\n".format(obs.get("width")-1, var)  
                decls += "\twire [{}:0] {}_right ;\n".format(obs.get("width")-1, var) 
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


def constructProductCircuit(outFolder, srcObsVar, trgObsVar, state, invVars, clock, cstrtype, filtertype):

    WIRE_DECLARATION_PLACEHOLDER = "//**Wire declarations**//"
    MODULE_DECLARATION_PLACEHOLDER = "//**Self-composed modules**//"
    INITIAL_STATE_PLACEHOLDER = "//**Initial state**//"
    STATE_INVARIANT_PLACEHOLDER = "//**State invariants**//"
    INIT_REGISTER_PLACEHOLDER = "//**Init register**//"
    VERIFICATION_CONDITIONS_PLACEHOLDER = "//**Verification conditions**//"
    INVARIANT_ASSERTIONS_PLACEHOLDER = "//**Invariant**//"

    # 0. Read product circuit template
    productCircuit = ""
    with open("{}/{}".format(outFolder, CONF.prodCircuitTemplate) , 'r') as f:
        productCircuit = f.read()

    # 1. Create wire declarations
    if WIRE_DECLARATION_PLACEHOLDER in productCircuit:
        wireDeclaration = ""
        wireDeclaration += "\t// wire declaration\n"
        wireDeclaration += selfCompositionVariableDecl(trgObsVar)
        wireDeclaration += selfCompositionVariableDecl(srcObsVar)
        wireDeclaration += selfCompositionVariableDecl(state) 
        if invVars:
            wireDeclaration += selfCompositionVariableDecl(invVars)         
        wireDeclaration += "\n"
        productCircuit= productCircuit.replace(WIRE_DECLARATION_PLACEHOLDER, wireDeclaration)
    else:
        print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {WIRE_DECLARATION_PLACEHOLDER}")
        exit(1)

    # 2. Init register
    if INIT_REGISTER_PLACEHOLDER in productCircuit:
        init = CONF.selfCompositionInitVariable
        initRegister = ""
        initRegister += "\t// auxiliary register for initial state\n"
        initRegister += f"\treg {init} = 0;\n"
        initRegister += "\talways @ (posedge {}) begin\n".format(clock)
        initRegister += f"\t\tif ({init} == 0) begin\n"
        initRegister += f"\t\t\t{init} <= 1;\n"
        initRegister += "\t\tend\n"
        initRegister += "\tend\n"
        productCircuit= productCircuit.replace(INIT_REGISTER_PLACEHOLDER, initRegister)
    else:
        init = CONF.initRegister

    # 3. Instantiate modules
    if MODULE_DECLARATION_PLACEHOLDER in productCircuit:
        # 3.11 Read inputs
        leftVarMap, rightVarMap = parseInputs(CONF.trgInputs)

        # 3.2 Modules
        moduleDeclarations = "\t// self-composed modules\n"

        for obsId in trgObsVar:
            for obs in trgObsVar[obsId]:
                leftVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightVarMap[obs["var"]] = "{}_right".format(obs["var"])

        for obsId in srcObsVar:
            for obs in srcObsVar[obsId]:
                leftVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightVarMap[obs["var"]] = "{}_right".format(obs["var"])

        for obsId in state:
            for obs in state[obsId]:
                leftVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightVarMap[obs["var"]] = "{}_right".format(obs["var"])

        for obsId in invVars:
            for obs in invVars[obsId]:
                leftVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightVarMap[obs["var"]] = "{}_right".format(obs["var"])

        moduleDeclarations += selfCompositionModuleInstantiation(CONF.trgModule, "left", leftVarMap)
        moduleDeclarations += selfCompositionModuleInstantiation(CONF.trgModule, "right", rightVarMap)

        productCircuit= productCircuit.replace(MODULE_DECLARATION_PLACEHOLDER, moduleDeclarations)
    else:
        print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {MODULE_DECLARATION_PLACEHOLDER}")
        exit(1)



    if cstrtype == "base":
        # Verification for base case

        # 4. Low-equivalence constraints
        if INITIAL_STATE_PLACEHOLDER in productCircuit:
            initial_state = ""
            if len(state) > 0:
                initial_state += "\t// Initial state\n"
                initial_state += selfCompositionVariableEquivalence("state_equiv", state, "state")
                initial_state += selfCompositionOnInit("init_state_equiv", init, "state_equiv")
                #initial_state += selfCompositionAssume("init_state_equiv")
                initial_state += "\n"
            productCircuit = productCircuit.replace(INITIAL_STATE_PLACEHOLDER, initial_state)


        # 5. Pipeline invariants constraints
        if STATE_INVARIANT_PLACEHOLDER in productCircuit:
            state_invariant = ""
            if len(invVars) > 0:
                state_invariant += "\t// State invariant\n"
                state_invariant += selfCompositionStateInvariant("state_invariant", invVars, "inv")
                #state_invariant += selfCompositionAssume("state_invariant")
                state_invariant += "\n"
            productCircuit = productCircuit.replace(STATE_INVARIANT_PLACEHOLDER, state_invariant)
        
        if VERIFICATION_CONDITIONS_PLACEHOLDER in productCircuit:
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
                verificationConditions += selfCompositionAssume("init_state_equiv")
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

            productCircuit = productCircuit.replace(VERIFICATION_CONDITIONS_PLACEHOLDER, verificationConditions)
    
   
    elif cstrtype == "induction":
        # Verification for induction step
                # 5. Pipeline invariants constraints
        if STATE_INVARIANT_PLACEHOLDER in productCircuit:
            state_invariant = ""
            if len(invVars) > 0:
                state_invariant += "\t// Pipeline invariant\n"
                state_invariant += selfCompositionStateInvariant("state_invariant", invVars, "inv")
                #state_invariant += selfCompositionAssume("state_invariant")
                state_invariant += "\n"
            productCircuit = productCircuit.replace(STATE_INVARIANT_PLACEHOLDER, state_invariant)

        if VERIFICATION_CONDITIONS_PLACEHOLDER in productCircuit:
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
                verificationConditions += selfCompositionAssume("state_invariant")
                # 5. contract equivalence
                verificationConditions += "\t// contract-equivalence\n"
                verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVar, "src")
                verificationConditions += "\n"

                # 6. inductive check on target equivalence
                verificationConditions += "\t// inductive hypothesis and verification assertion\n"
                verificationConditions += selfCompositionObservationEquivalence("trg_equiv", trgObsVar, "trg")
                verificationConditions += "\n"

                if CONF.prefixCheck == "True":
                    # 7. prefixCheck 
                    verificationConditions += selfCompositionPrefixCheck(clock, CONF.inductiveyosysBMCBound, filtertype)
                else:
                    verificationConditions += selfCompositionAssume("src_equiv")
                    verificationConditions += selfCompositionAssert("trg_equiv")
                    verificationConditions += "\n"


            productCircuit= productCircuit.replace(VERIFICATION_CONDITIONS_PLACEHOLDER, verificationConditions)
        else:
            print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {VERIFICATION_CONDITIONS_PLACEHOLDER}")
            exit(1)
    
    elif cstrtype == "check":
        #4. Low-equivalence constraints
        if INITIAL_STATE_PLACEHOLDER in productCircuit:
            initial_state = ""
            if len(state) > 0:
                initial_state += "\t// Initial state\n"
                initial_state += selfCompositionVariableEquivalence("state_equiv", state, "state")
                initial_state += selfCompositionOnInit("init_state_equiv", init, "state_equiv")
                #initial_state += selfCompositionAssume("init_state_equiv")
                initial_state += "\n"
            productCircuit = productCircuit.replace(INITIAL_STATE_PLACEHOLDER, initial_state)

        if VERIFICATION_CONDITIONS_PLACEHOLDER in productCircuit:
            verificationConditions = ""
            # 4. contract equivalence
            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVar, "src")
            verificationConditions += "\n"
            # 5. inductive check on target equivalence
            verificationConditions += "\t// inductive hypothesis and verification assertion\n"
            verificationConditions += selfCompositionObservationEquivalence("trg_equiv", trgObsVar, "trg")
            verificationConditions += "\n"
            
            verificationConditions += selfCompositionAssume("src_equiv")
            verificationConditions += selfCompositionAssert("trg_equiv")

            productCircuit= productCircuit.replace(VERIFICATION_CONDITIONS_PLACEHOLDER, verificationConditions)
        else:
            print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {VERIFICATION_CONDITIONS_PLACEHOLDER}")
            exit(1)

    elif cstrtype == "directlycheck":
        #4. Low-equivalence constraints
        if INITIAL_STATE_PLACEHOLDER in productCircuit:
            initial_state = ""
            if len(state) > 0:
                initial_state += "\t// Initial state\n"
                initial_state += selfCompositionVariableEquivalence("state_equiv", state, "state")
                initial_state += selfCompositionOnInit("init_state_equiv", init, "state_equiv")
                initial_state += selfCompositionAssume("init_state_equiv")
                initial_state += "\n"
            productCircuit = productCircuit.replace(INITIAL_STATE_PLACEHOLDER, initial_state)

        if VERIFICATION_CONDITIONS_PLACEHOLDER in productCircuit:
            verificationConditions = ""
            # 5. contract equivalence
            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVar, "src")
            verificationConditions += "\n"
            # 6. inductive check on target equivalence
            verificationConditions += "\t// inductive hypothesis and verification assertion\n"
            verificationConditions += selfCompositionObservationEquivalence("trg_equiv", trgObsVar, "trg")
            verificationConditions += "\n"
            if filtertype == "one-cycle-delayed":
                # 7. prefixCheck 
                verificationConditions += selfCompositionPrefixCheck(clock, CONF.directlycheckyosysBMCBound, filtertype)
            else:
            # 8. delayed checking
                verificationConditions+= selfCompositionDelayedCheck(clock, CONF.maxinstruction)
            
                verificationConditions += selfCompositionAssume("src_equiv")
                verificationConditions += selfCompositionAssert("trg_equiv")
                verificationConditions += "\n"

            productCircuit= productCircuit.replace(VERIFICATION_CONDITIONS_PLACEHOLDER, verificationConditions)
        else:
            print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {VERIFICATION_CONDITIONS_PLACEHOLDER}")
            exit(1)

    with open("{}/{}".format(outFolder, CONF.prodCircuitTemplate) , 'w') as f:
        f.write(productCircuit)


def constructProductCircuit4way(outFolder, srcObsVars, trgObsVars, srcStateVars, inductiveSrcStateVars, trgStateVars, invVars, clock, cstrtype, filtertype):


    WIRE_DECLARATION_PLACEHOLDER = "//**Wire declarations**//"
    MODULE_DECLARATION_PLACEHOLDER = "//**Self-composed modules**//"
    INITIAL_STATE_PLACEHOLDER = "//**Initial state**//"
    STATE_INVARIANT_PLACEHOLDER = "//**State invariants**//"
    SRC_TO_TRG_PLACEHOLDER = "//**Source to target mapping**//"
    INIT_REGISTER_PLACEHOLDER = "//**Init register**//"
    VERIFICATION_CONDITIONS_PLACEHOLDER = "//**Verification conditions**//"
    INVARIANT_ASSERTIONS_PLACEHOLDER = "//**Invariant**//"

    # 0. Read product circuit template
    productCircuit = ""
    with open("{}/{}".format(outFolder, CONF.prodCircuitTemplate) , 'r') as f:
        productCircuit = f.read()

    # 1. Create wire declarations
    if WIRE_DECLARATION_PLACEHOLDER in productCircuit:
        wireDeclaration = ""
        wireDeclaration += "\t// wire declaration\n"


        wireDeclaration += selfCompositionVariableDecl(trgObsVars)
        wireDeclaration += selfCompositionVariableDecl(srcObsVars)
        wireDeclaration += selfCompositionVariableDecl(trgStateVars) 
        wireDeclaration += selfCompositionVariableDecl(srcStateVars) 
        wireDeclaration += selfCompositionVariableDecl(inductiveSrcStateVars) 
        if invVars:
            wireDeclaration += selfCompositionVariableDecl(invVars)      
        wireDeclaration += "\n"
        productCircuit= productCircuit.replace(WIRE_DECLARATION_PLACEHOLDER, wireDeclaration)
    else:
        print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {WIRE_DECLARATION_PLACEHOLDER}")
        exit(1)

    # 2. Init register
    if INIT_REGISTER_PLACEHOLDER in productCircuit:
        init = CONF.selfCompositionInitVariable
        initRegister = ""
        initRegister += "\t// auxiliary register for initial state\n"
        initRegister += f"\treg {init} = 0;\n"
        initRegister += "\talways @ (posedge {}) begin\n".format(clock)
        initRegister += f"\t\tif ({init} == 0) begin\n"
        initRegister += f"\t\t\t{init} <= 1;\n"
        initRegister += "\t\tend\n"
        initRegister += "\tend\n"
        counter = "trg_counter"
        initRegister += "\t// auxiliary register for counter\n"
        initRegister += f"\treg [2:0] {counter} = 2;\n"
        initRegister += "\talways @ (posedge {}) begin\n".format(clock)
        initRegister += f"\t\tif ({counter} > 0) begin\n"
        initRegister += f"\t\t\t{counter} <= {counter} - 1;\n"
        initRegister += "\t\tend\n"
        initRegister += "\tend\n"
        cycle_counter = "cycle_counter"
        initRegister += "\t// auxiliary register for counting cycles\n"
        initRegister += f"\treg [{(CONF.srcBound+1).bit_length()}:0] {cycle_counter} = {CONF.srcBound + 1};\n"
        initRegister += "\talways @ (posedge {}) begin\n".format(clock)
        initRegister += f"\t\tif ({cycle_counter} > 0) begin\n"
        initRegister += f"\t\t\t{cycle_counter} <= {cycle_counter} - 1;\n"
        initRegister += "\t\tend\n"
        initRegister += "\tend\n"
        productCircuit= productCircuit.replace(INIT_REGISTER_PLACEHOLDER, initRegister)
    else:
        init = CONF.initRegister
        counter = "trg_counter"
        cycle_counter = "cycle_counter"

    # 3. Instantiate modules
    if MODULE_DECLARATION_PLACEHOLDER in productCircuit:
        # 3.11 Read inputs
        leftTrgVarMap, rightTrgVarMap = parseInputs(CONF.trgInputs)
        leftSrcVarMap, rightSrcVarMap = parseInputs(CONF.srcInputs)

        # 3.2 Modules
        moduleDeclarations = "\t// self-composed modules\n"

        for obsId in trgObsVars:
            for obs in trgObsVars[obsId]:
                leftTrgVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightTrgVarMap[obs["var"]] = "{}_right".format(obs["var"])

        for obsId in srcObsVars:
            for obs in srcObsVars[obsId]:
                leftSrcVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightSrcVarMap[obs["var"]] = "{}_right".format(obs["var"])

        for obsId in trgStateVars:
            for obs in trgStateVars[obsId]:
                leftTrgVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightTrgVarMap[obs["var"]] = "{}_right".format(obs["var"])

        for obsId in srcStateVars:
            for obs in srcStateVars[obsId]:
                leftSrcVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightSrcVarMap[obs["var"]] = "{}_right".format(obs["var"])
        
        for obsId in inductiveSrcStateVars:
            for obs in inductiveSrcStateVars[obsId]:
                leftSrcVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightSrcVarMap[obs["var"]] = "{}_right".format(obs["var"])

        for obsId in invVars:
            for obs in invVars[obsId]:
                leftTrgVarMap[obs["var"]] = "{}_left".format(obs["var"])
                rightTrgVarMap[obs["var"]] = "{}_right".format(obs["var"])

        moduleDeclarations += selfCompositionModuleInstantiation(CONF.srcModule, "left_src", leftSrcVarMap)
        moduleDeclarations += selfCompositionModuleInstantiation(CONF.srcModule, "right_src", rightSrcVarMap)
        moduleDeclarations += selfCompositionModuleInstantiation(CONF.trgModule, "left_trg", leftTrgVarMap)
        moduleDeclarations += selfCompositionModuleInstantiation(CONF.trgModule, "right_trg", rightTrgVarMap)

        productCircuit= productCircuit.replace(MODULE_DECLARATION_PLACEHOLDER, moduleDeclarations)
    else:
        print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {MODULE_DECLARATION_PLACEHOLDER}")
        exit(1)



    if cstrtype == "base":
        # Verification for base case

        # 4. Low-equivalence constraints
        if INITIAL_STATE_PLACEHOLDER in productCircuit:
            initial_state = ""
            if len(srcStateVars) > 0:
                initial_state += "\t// Initial state\n"
                initial_state += selfCompositionVariableEquivalence("state_src_equiv", srcStateVars, "")
                initial_state += selfCompositionOnInit("init_state_src_equiv", init, "state_src_equiv")
                #initial_state += selfCompositionAssume("init_state_equiv")
                initial_state += "\n"
            if len(trgStateVars) > 0:
                initial_state += selfCompositionVariableEquivalence("state_trg_equiv", trgStateVars, "")
                initial_state += selfCompositionOnInit("init_state_trg_equiv", init, "state_trg_equiv")
                #initial_state += selfCompositionAssume("init_state_equiv")
                initial_state += "\n"
            productCircuit = productCircuit.replace(INITIAL_STATE_PLACEHOLDER, initial_state)


        # 5. Pipeline invariants constraints
        if STATE_INVARIANT_PLACEHOLDER in productCircuit:
            state_invariant = ""
            if len(invVars) > 0:
                state_invariant += "\t// State invariant\n"
                state_invariant += selfCompositionStateInvariant("state_invariant", invVars, "inv")
                #state_invariant += selfCompositionAssume("state_invariant")
                state_invariant += "\n"
            productCircuit = productCircuit.replace(STATE_INVARIANT_PLACEHOLDER, state_invariant)

        
        if SRC_TO_TRG_PLACEHOLDER in productCircuit:
            src_to_target = ""
            if len(CONF.srcStateToTrgStateMap) > 0:
                src_to_target += srcToTrgMapping("left_mapping", CONF.srcStateToTrgStateMap, srcStateVars, trgStateVars, "left" )
                src_to_target += srcToTrgMapping("right_mapping", CONF.srcStateToTrgStateMap, srcStateVars, trgStateVars, "right" )
                src_to_target += selfCompositionOnInit("init_left_mapping", init, "left_mapping")
                src_to_target += selfCompositionOnInit("init_right_mapping", init, "right_mapping")
            productCircuit = productCircuit.replace(SRC_TO_TRG_PLACEHOLDER, src_to_target)



        if VERIFICATION_CONDITIONS_PLACEHOLDER in productCircuit:
            verificationConditions = ""

            ## Assume that state equivalence holds initially
            ## (base case)
            verificationConditions += selfCompositionAssume("init_state_src_equiv")
            verificationConditions += selfCompositionAssume("init_state_trg_equiv")
            verificationConditions += "\n"

            ## Assume that shared state between src and trg is in synch (for left and right sides)
            if len(CONF.srcStateToTrgStateMap) > 0:
                verificationConditions += "\t// mappings\n"
                verificationConditions += selfCompositionAssume("init_left_mapping")
                verificationConditions += selfCompositionAssume("init_right_mapping")
                verificationConditions += "\n"

            ## Assume that state invariants hold
            ## TODO: Is it correct? Why are we assuming the state invariant? Shouldn't we check it first?
            # if len(invVars) > 0:
            #     verificationConditions += selfCompositionAssume("state_invariant")
            #     verificationConditions += "\n"

            ## Assume src equivalence
            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVars, "src")
            # verificationConditions += selfCompositionAccumulator("src_equiv1",clock,"src_equiv0")
            verificationConditions += selfCompositionAssume("src_equiv")
            verificationConditions += "\n"

            ## Assert target equivalence
            verificationConditions += "\t// verification assertion\n"
            verificationConditions += selfCompositionObservationEquivalence("trg_equiv", trgObsVars, "trg")
            verificationConditions += "\n"
            verificationConditions += selfCompositionConditionalAcculumator("trg_equiv0", clock, counter, "trg_equiv")
            verificationConditions += selfCompositionDiscloseAtEnd("trg_equiv1", cycle_counter, "trg_equiv0")
            verificationConditions += selfCompositionAssert("trg_equiv1")
            verificationConditions += "\n"

            productCircuit = productCircuit.replace(VERIFICATION_CONDITIONS_PLACEHOLDER, verificationConditions)

        else:
            print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {VERIFICATION_CONDITIONS_PLACEHOLDER}")
            exit(1)

    elif cstrtype == "induction":
        # Verification for induction step
        # 4. Low-equivalence constraints
        if INITIAL_STATE_PLACEHOLDER in productCircuit:
            initial_state = ""
            if len(inductiveSrcStateVars) > 0:
                initial_state += "\t//Inductive initial state\n"
                initial_state += selfCompositionVariableEquivalence("state_src_equiv", inductiveSrcStateVars, "")
                initial_state += selfCompositionOnInit("init_state_src_equiv", init, "state_src_equiv")
                #initial_state += selfCompositionAssume("init_state_equiv")
                initial_state += "\n"
            productCircuit = productCircuit.replace(INITIAL_STATE_PLACEHOLDER, initial_state)


        # 5. Pipeline invariants constraints
        if STATE_INVARIANT_PLACEHOLDER in productCircuit:
            state_invariant = ""
            if len(invVars) > 0:
                state_invariant += "\t// State invariant\n"
                state_invariant += selfCompositionStateInvariant("state_invariant", invVars, "inv")
                #state_invariant += selfCompositionAssume("state_invariant")
                state_invariant += "\n"
            productCircuit = productCircuit.replace(STATE_INVARIANT_PLACEHOLDER, state_invariant)

        
        if SRC_TO_TRG_PLACEHOLDER in productCircuit:
            src_to_target = ""
            if len(CONF.srcStateToTrgStateMap) > 0:
                src_to_target += srcToTrgMapping("left_mapping", CONF.srcStateToTrgStateMap, srcStateVars, trgStateVars, "left" )
                src_to_target += srcToTrgMapping("right_mapping", CONF.srcStateToTrgStateMap, srcStateVars, trgStateVars, "right" )
                src_to_target += selfCompositionOnInit("init_left_mapping", init, "left_mapping")
                src_to_target += selfCompositionOnInit("init_right_mapping", init, "right_mapping")
            productCircuit = productCircuit.replace(SRC_TO_TRG_PLACEHOLDER, src_to_target)



        if VERIFICATION_CONDITIONS_PLACEHOLDER in productCircuit:
            verificationConditions = ""
            ## Assume that inductive state equivalence holds initially
            ## (inductive case)
            verificationConditions += selfCompositionAssume("init_state_src_equiv")
            verificationConditions += "\n"


            ## Assume that shared state between src and trg is in synch (for left and right sides)
            if len(CONF.srcStateToTrgStateMap) > 0:
                verificationConditions += "\t// mappings\n"
                verificationConditions += selfCompositionAssume("init_left_mapping")
                verificationConditions += selfCompositionAssume("init_right_mapping")
                verificationConditions += "\n"

            ## Assume that state invariants hold
            ## TODO: Is it correct? Why are we assuming the state invariant? Shouldn't we check it first?
            if len(invVars) > 0:
                verificationConditions += selfCompositionAssume("state_invariant")
                verificationConditions += "\n"

            ## Assume src equivalence
            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVars, "src")
            # verificationConditions += selfCompositionAccumulator("src_equiv",clock,"src_equiv0")
            verificationConditions += selfCompositionAssume("src_equiv")
            verificationConditions += "\n"

            ## target equivalence
            verificationConditions += "\t// target equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("trg_equiv2", trgObsVars, "trg")
            verificationConditions += "\n"

            ## Induction hypothesis on target equivalence
            verificationConditions += "\t// induction hypothesis on trg equivalence\n"
            verificationConditions += selfCompositionOnInit("trg_equiv0", init, "trg_equiv2")
            verificationConditions += selfCompositionAssume("trg_equiv0")

            ## Assert target equivalence at cycle 1 (but disclosed at the end)
            verificationConditions += "\t// assertion on trg equivalence\n"
            verificationConditions += selfCompositionConditionalAcculumator("trg_equiv1", clock, counter, "trg_equiv2")
            verificationConditions += selfCompositionDiscloseAtEnd("trg_equiv", cycle_counter, "trg_equiv1")
            verificationConditions += selfCompositionAssert("trg_equiv")
            verificationConditions += "\n"

            productCircuit = productCircuit.replace(VERIFICATION_CONDITIONS_PLACEHOLDER, verificationConditions)

        else:
            print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {VERIFICATION_CONDITIONS_PLACEHOLDER}")
            exit(1)
    
    elif cstrtype == "check":

        if VERIFICATION_CONDITIONS_PLACEHOLDER in productCircuit:
            verificationConditions = ""
            # 4. contract equivalence
            verificationConditions += "\t// contract-equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("src_equiv", srcObsVars, "src")
            verificationConditions += "\n"
            verificationConditions += selfCompositionAssume("src_equiv")
            verificationConditions += "\n"
            # 5. inductive check on target equivalence
            verificationConditions += "\t// target equivalence\n"
            verificationConditions += selfCompositionObservationEquivalence("trg_equiv", trgObsVars, "trg")
            verificationConditions += "\n"
            verificationConditions += selfCompositionAssert("trg_equiv")
            verificationConditions += "\n"
            productCircuit= productCircuit.replace(VERIFICATION_CONDITIONS_PLACEHOLDER, verificationConditions)
        else:
            print(f"The product circuit template at {CONF.prodCircuitTemplate} does not contain a placeholder {VERIFICATION_CONDITIONS_PLACEHOLDER}")
            exit(1)
    else:
        print("Unsupported product circuit mode")
        exit(1)
    
    with open("{}/{}".format(outFolder, CONF.prodCircuitTemplate) , 'w') as f:
        f.write(productCircuit)

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
        if var.get("lowequivalent") is None:
            lowequivalent = True
        else:
            lowequivalent = False
        var = { "var": "{}_{}".format(varId, prefix), "expr" : var.get("expr") , "width" : width, "val": var.get("val"), "lowequivalent": lowequivalent }
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
#### Helper functions for yosys comamnds
####

def flatten(folder, filename, module):
    yosysScript = ""
    yosysScript += "read_verilog -sv {}/*.v\n".format(folder)
    yosysScript += "hierarchy -top {}\n".format(module)
    yosysScript += "proc\n"
    yosysScript += "flatten\n"
    yosysScript += "select {}\n".format(module)
    return yosysScript

def linkModule(outFolder, module, obsDict, auxVars, suffix):
    yosysScript = ""
    yosysScript += "read_verilog -sv {}/{}_{}.v\n".format(outFolder, module, suffix)
    yosysScript += "select {}\n".format(module)
    yosysScript += "proc\n"
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
    yosysScript += "opt\n"
    yosysScript += "write_verilog -selected {}/{}.v\n".format(outFolder, module)

    with open("{}/{}_yosys.script".format(outFolder,suffix) , 'w') as f:
        f.write(yosysScript)
    # cmd = [CONF.yosysPath]
    # for m in CONF.yosysAdditionalModules:
    #     cmd.append(f"-m{m}")
    # cmd.append("-s{}/{}_yosys.script".format(outFolder,suffix))
    # run_process(cmd, CONF.verbose_verification)
    run_yosys("{}/{}_yosys.script".format(outFolder,suffix), CONF.verbose_verification, CONF.yosys_strictness)


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

def verify(srcObservations, trgObservations, stateInvariant, auxVars, metaVars, cstrtype, filtertype):
    state = CONF.state
    module = CONF.trgModule
    outFolder = CONF.outFolder + "/" + filtertype + "_" + cstrtype

    # construct yosys script
    yosysScript = ""

    log("START")

    time1 = datetime.now()

    ## 1. flatten source and target code
    log(f"Flattening {module}")
    yosysScript += flatten(outFolder, CONF.trgModule, CONF.trgModule)
    time2 = datetime.now()
    logtimefile("\n\tTime for flatten the source code: "+ str((time2- time1).seconds))

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
    constructProductCircuit(outFolder, srcObsVar, trgObsVar, trgStateVars, srcInvsVars, CONF.clockInput, cstrtype, filtertype)
    run_process(["mv", "{}/prod.v".format(outFolder), "{}/prod.temp".format(outFolder)])

    ## 7. Finalize
    log("Finalize target module changes")
    finalizeModuleChanges(outFolder, module, yosysScript, "trg")
    time3 = datetime.now()
    logtimefile("\n\tTime for inline observations: "+ str((time3- time2).seconds))


    ## 8. verify contract satisfaction
    log("Verification")
    run_process(["cp", "{}/prod.temp".format(outFolder), "{}/prod.v".format(outFolder)])
    verifMode="yosys-smt"
    targetName = CONF.prodCircuitTemplate.replace(".v", "")
    avrPath = CONF.avrPath
    if verifMode == "yosys-smt":
        log(f"Verification with {verifMode}")
        log("SMTLib encoding")

        ## Create smtlib encoding with yosys
        yosysScript = ""
        yosysScript += "read_verilog -sv {}/*.v\n".format(outFolder, targetName)
        yosysScript += "hierarchy -top {}\n".format(targetName)
        yosysScript += "proc\n"
        yosysScript += "flatten\n".format(targetName)
        yosysScript += "opt\n"
        yosysScript += "write_verilog {}/{}.v\n".format(outFolder, targetName)
        for o in CONF.yosysSMTPreprocessing:
            yosysScript += f"{o}\n"
        # yosysScript += "async2sync\n"
        # yosysScript += "dffunmap\n"
        # yosysScript += "clk2fflogic\n"
        yosysScript += "write_smt2 -wires {}/{}.smt\n".format(outFolder, targetName)

        with open("{}/yosys-verification.script".format(outFolder) , 'w') as f:
            f.write(yosysScript)
        # cmd = [CONF.yosysPath]
        # cmd.append("-s{}/yosys-verification.script".format(outFolder))
        # run_process(cmd, CONF.verbose_verification)
        run_yosys("{}/yosys-verification.script".format(outFolder), CONF.verbose_verification, CONF.yosys_strictness)

        log("Bounded model checking")
        time4 = datetime.now()
        logtimefile("\n\tTime for generating prod.smt: "+ str((time4- time3).seconds))
        ## run yosys smt bounded model checker
        # cmd = [CONF.yosysBMCPath, "-s", "z3"]
        cmd = [CONF.yosysBMCPath, "-s", CONF.yosysBMCSolver]
        if cstrtype == "base":
            if filtertype == "delayedcheck":
                cmd += ["-t", str(int(CONF.cycleDelayed)+1)]
            else: 
                cmd += ["-t", "1"]
        elif cstrtype == "induction":
            if filtertype == "delayedcheck":
                cmd += ["-t", str(int(CONF.cycleDelayed)+2)]
            else: 
                cmd += ["-t", CONF.inductiveyosysBMCBound]
        elif cstrtype == "check":
            cmd += ["-t", CONF.checkyosysBMCBound]
        elif cstrtype == "directlycheck":
            cmd += ["-t", CONF.directlycheckyosysBMCBound]
        
        cmd +=["--dump-vlogtb" , "{}/{}_tb.v".format(outFolder, targetName)] 
        cmd += ["--dump-smtc", "{}/{}_smtc".format(outFolder, targetName)]
        cmd += ["--dump-vcd", "{}/{}_trace.vcd".format(outFolder, targetName)]
        cmd += ["--noincr"]
        cmd += ["{}/{}.smt".format(outFolder, targetName)]
        output = run_process(cmd, CONF.verbose_verification)
        time5 = datetime.now()
        logtimefile("\n\tTime for BMC: "+ str((time5- time4).seconds))

        if "Status: FAILED" in output:
            log("Verification FAILED")
            return "FAIL","{}/{}_tb.v".format(outFolder, targetName), srcObsVar, trgObsVar

        elif "Status: PASSED" in output:
            log("Verification PASSED")
            return "PASS", None, srcObsVar, trgObsVar
        else:
            print("Unknown verification result")
            exit(1)

    if verifMode == "avr":
        ## run AVR 
        log("Verification with {verifMode}")
        run_process(["python3", avrPath,  os.path.abspath("{}/{}.v\n".format(outFolder, targetName)) ])
        
    log("END")



def verify4way(srcObservations, trgObservations, stateInvariant, auxVars, metaVars, cstrtype, filtertype):
    state = CONF.state
    module = CONF.module
    outFolder = CONF.outFolder + "/" + filtertype + "_" + cstrtype

    # construct yosys script
    yosysScript = ""

    log("START")

    ## 1. flatten source  code
    log(f"Flattening {CONF.srcModule}")
    ts = datetime.now()
    yosysScript += flatten(outFolder, CONF.srcModuleFile, CONF.srcModule)
    logtimefile("\n\tTime for flattening the source code: "+ str((datetime.now()- ts).seconds))
    ts = datetime.now()


    ## 3. inline source observations
    log("Inline src observations")
    srcObsVar, script = inlineObservations(outFolder, metaVars, auxVars, srcObservations, CONF.srcModule, "obs_src")
    yosysScript += script

    ## 4. inline state variables
    log("Inline state variables")
    srcStateVars, script = inlineStateVars(outFolder, metaVars, auxVars, CONF.srcState, CONF.srcModule, "state_src")
    yosysScript += script 

    # ## 5. inline inductive state variables
    log("Inline state variables")
    inductiveSrcStateVars, script = inlineStateVars(outFolder, metaVars, auxVars, CONF.inductiveSrcState, CONF.srcModule, "inductive_state_src")
    yosysScript += script 

    ## 7. Finalize
    log("Finalize target module changes")
    finalizeModuleChanges(outFolder, CONF.srcModule, yosysScript, "src")
    logtimefile("\n\tTime for inline observations: "+ str((datetime.now()- ts).seconds))
    ts = datetime.now()
    yosysScript = ""

    log(f"Flattening {CONF.trgModule}")
    ts = datetime.now()
    yosysScript += flatten(outFolder, CONF.trgModuleFile, CONF.trgModule)
    logtimefile("\n\tTime for flattening the source code: "+ str((datetime.now()- ts).seconds))
    ts = datetime.now()


    ## 2. inline target observations
    log("Inline target observations")
    trgObsVar, script = inlineObservations(outFolder, metaVars, auxVars, trgObservations, CONF.trgModule, "obs_trg")
    yosysScript += script

    ## 4. inline state variables
    log("Inline state variables")
    trgStateVars, script = inlineStateVars(outFolder, metaVars, auxVars, CONF.trgState, CONF.trgModule, "state_trg")
    yosysScript += script

    ## 5. inline state invariants
    trgInvsVars = []
    if stateInvariant:
        log("Inline state invariants")
        trgInvsVars, script = inlinePipelineInvs(outFolder, metaVars, auxVars, stateInvariant, CONF.trgModule, "invariant")
        yosysScript += script

    ## 7. Finalize
    log("Finalize target module changes")
    finalizeModuleChanges(outFolder, CONF.trgModule, yosysScript, "trg")
    logtimefile("\n\tTime for inline observations: "+ str((datetime.now()- ts).seconds))
    ts = datetime.now()

    ## 6. Create product circuit    
    log("Create product circuit")
    constructProductCircuit4way(outFolder, srcObsVar, trgObsVar, srcStateVars, inductiveSrcStateVars, trgStateVars, trgInvsVars, CONF.clockInput, cstrtype, filtertype)
    # run_process(["mv", "{}/prod.v".format(outFolder), "{}/prod.temp".format(outFolder)])
    run_process(["cp", "{}/prod.v".format(outFolder), "{}/prod.temp".format(outFolder)])

    ## 8. verify contract satisfaction
    log("Verification")
    run_process(["cp", "{}/prod.temp".format(outFolder), "{}/prod.v".format(outFolder)])
    verifMode="yosys-smt"
    targetName = CONF.prodCircuitTemplate.replace(".v", "")
    avrPath = CONF.avrPath
    if verifMode == "yosys-smt":
        log(f"Verification with {verifMode}")
        log("SMTLib encoding")

        ## Create smtlib encoding with yosys
        yosysScript = ""
        yosysScript += "read_verilog -sv {}/*.v\n".format(outFolder, targetName)
        yosysScript += "hierarchy -top {}\n".format(targetName)
        yosysScript += "proc\n"
        yosysScript += "opt\n"
        yosysScript += "flatten\n"
        yosysScript += "opt\n"
        yosysScript += "write_verilog {}/{}.v\n".format(outFolder, targetName)
        # yosysScript += "delete {}\n".format(targetName)
        # yosysScript += "read_verilog -sv {}/{}.v\n".format(outFolder, targetName)
        # yosysScript += "proc\n"
        # yosysScript += "opt\n"
        # yosysScript += "scc\n"
        for o in CONF.yosysSMTPreprocessing:
            yosysScript += f"{o}\n"
        # yosysScript += "async2sync\n"
        # yosysScript += "dffunmap\n"
        # yosysScript += "clk2fflogic\n"
        yosysScript += "scc\n"
        yosysScript += "write_smt2 -wires {}/{}.smt\n".format(outFolder, targetName)

        with open("{}/yosys-verification.script".format(outFolder) , 'w') as f:
            f.write(yosysScript)
        

        # cmd = [CONF.yosysPath]
        # cmd.append("-s{}/yosys-verification.script".format(outFolder))
        # run_process(cmd, CONF.verbose_verification)

        run_yosys("{}/yosys-verification.script".format(outFolder), CONF.verbose_verification, CONF.yosys_strictness)

        log("Bounded model checking")
        logtimefile("\n\tTime for generating prod.smt: "+ str(( datetime.now()- ts).seconds))
        ts = datetime.now()
        ## run yosys smt bounded model checker
        # cmd = [CONF.yosysBMCPath, "-s", "z3"]
        cmd = [CONF.yosysBMCPath, "-s", CONF.yosysBMCSolver]
        if cstrtype == "base":
            cmd += ["-t",  str(CONF.srcBound+1)]
        elif cstrtype == "induction":
            cmd += ["-t", str(CONF.srcBound+1)]
        elif cstrtype == "check":
            cmd += ["-t", "2"]
        elif cstrtype == "directlycheck":
            cmd += ["-t", CONF.directlycheckyosysBMCBound]
        
        cmd +=["--dump-vlogtb" , "{}/{}_tb.v".format(outFolder, targetName)] 
        cmd += ["--dump-smtc", "{}/{}_smtc".format(outFolder, targetName)]
        cmd += ["--dump-vcd", "{}/{}_trace.vcd".format(outFolder, targetName)]
        cmd += ["--noincr"]
        cmd += ["{}/{}.smt".format(outFolder, targetName)]
        output = run_process(cmd, CONF.verbose_verification)
        logtimefile("\n\tTime for BMC: "+ str((datetime.now()- ts).seconds))
        ts =  datetime.now()
        if "Status: FAILED" in output:
            log("Verification FAILED")
            return "FAIL","{}/{}_tb.v".format(outFolder, targetName), srcObsVar, trgObsVar

        elif "Status: PASSED" in output:
            log("Verification PASSED")
            return "PASS", None, srcObsVar, trgObsVar
        else:
            print("Unknown verification result")
            exit(1)

    if verifMode == "avr":
        ## run AVR 
        log("Verification with {verifMode}")
        run_process(["python3", avrPath,  os.path.abspath("{}/{}.v\n".format(outFolder, targetName)) ])
        
    log("END")
