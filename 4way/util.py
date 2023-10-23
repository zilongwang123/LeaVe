
from config import CONF
import subprocess 
import re
from subprocess import run, PIPE, STDOUT


def run_yosys(script, verbose = True, strict = False):
    cmd = [CONF.yosysPath]
    for m in CONF.yosysAdditionalModules:
        cmd.append(f"-m{m}")
    cmd.append(f"-s{script}")
    output = run_process(cmd, verbose)
    if False:
        errors = re.findall('warning', output)
        errors += re.findall('Warning', output)
        errors += re.findall('Error',  output)
        errors += re.findall('error', output)
        if len(errors) != 0:
            print("Yosis' output contains errors/warnings!!!")
            exit(1)
    return output

def run_process(cmd, verbose = True):
    if verbose and CONF.verbose_external_processes:
        print("Execute {}".format(" ".join(cmd) ))
    o_ = run(cmd, stdout=PIPE, stderr=STDOUT)
    output  = o_.stdout.decode("utf-8")
    if verbose and CONF.verbose_external_processes:
        print(output )
    return output

def getIndexMetaVariables(expr:str):
    return set(re.findall('\$\$(.*?)\$\$', expr))

def replaceIndexMetaVariable(expr:str, metavar:str, value:str):
    return re.sub(f'\$\${metavar}\$\$', value, expr)


def logfile(content):
    with open("logfile", "a") as lf:
        lf.write(content)

def logtimefile(content):
    with open("logtimefile", "a") as lf:
        lf.write(content)

def inv2str(invariant):
    if len(invariant) == 0:
        return ["empty"]
    else:
        inv_str = []
        for inv in invariant:
            if inv.get("attrs")[0].get("initval") == None or inv.get("attrs")[0].get("initval") == "none":
                inv_str.append("\t- {{ id: {0}, cond: {1}, attrs: [ {{ value: {2}, width: {3} }} ]}}\n"
                .format(inv.get("id"), str(inv.get("cond")), inv.get("attrs")[0].get("value"), str(inv.get("attrs")[0].get("width"))))
            else:
                inv_str.append("\t- {{ id: {0}, cond: {1}, attrs: [ {{ value: {2}, width: {3}, initval: {4} }} ]}}\n"
                .format(inv.get("id"), str(inv.get("cond")), inv.get("attrs")[0].get("value"), str(inv.get("attrs")[0].get("width")), str(inv.get("attrs")[0].get("initval"))))
        return inv_str