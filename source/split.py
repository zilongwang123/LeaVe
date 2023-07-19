from __future__ import absolute_import
from __future__ import print_function
import sys
import os
import yaml
from optparse import OptionParser
import re

def main():
    INFO = "Given a file xx.v containing multiple verilog modules m1, .. mn, the script generates one file per module renamed renamed m1.v, ... ,mn.v. NOTE: the script does not work if the verilog code contains nested modules!"
    VERSION = "0.0 :-|"
    USAGE = "Usage: python split.py file1 trgFolder"

    def showVersion():
        print(INFO)
        print(VERSION)
        print(USAGE)
        sys.exit()

    optparser = OptionParser()                      
    (options, args) = optparser.parse_args()

    filelist = args

    if len(filelist) != 2:
        showVersion()

    filename = filelist[0]
    if not os.path.exists(filename):
        raise IOError("File not found: " + filename)
    trgFolder = filelist[1]
    if not os.path.exists(trgFolder):
        raise IOError("Folder not found: " + trgFolder)

    # open file
    src = ""
    with open(filename, "r") as f:
        src = f.read()

    # identify all modules
    modules = re.findall('module(.*?)endmodule', src, flags=re.MULTILINE | re.DOTALL)

    for module in modules:
        res = re.findall('(.*?)\(', module) 
        
        module_name = ""
        if(len(res) > 0):
            module_name = re.sub(r"[\n\t\s]*", "", res[0])
        else:
            print(f"Cannot find module name in the following module:\n {module}")
            exit(1)

        print(f"Found module with id {module_name}")

        trg_file = f"{trgFolder}/{module_name}.v"
        if os.path.exists(trg_file):
            raise IOError(f"There is already a file named {trg_file}")

        print(f"Writing {module_name} to {trg_file}")
            
        with open(trg_file, "w") as f:
            code = f"module {module}\nendmodule"
            f.write(code)


   
  
if __name__ == '__main__':
    main()
