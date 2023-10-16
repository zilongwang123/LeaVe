
from config import CONF
import subprocess 
import re
from subprocess import run, PIPE, STDOUT

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
    with open( CONF.outFolder + "/logfile", "a") as lf:
        lf.write(content)

def logtimefile(content):
    print("--------------------------")
    with open( CONF.outFolder + "/logtimefile", "a") as lf:
        lf.write(content)
        print("--------------------------")

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