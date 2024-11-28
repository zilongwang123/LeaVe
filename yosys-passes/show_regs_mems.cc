#include "kernel/register.h"
#include "kernel/rtlil.h"
#include "kernel/log.h"
#include "kernel/yosys.h"
#include "kernel/sigtools.h"
#include "kernel/mem.h"
#include "stdio.h"
#include "backends/rtlil/rtlil_backend.h"
#include "backends/rtlil/rtlil_backend.h"
#include "list"
#include <iostream>

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN
using namespace RTLIL_BACKEND;
using namespace std;

vector<string> split(const string &str, const string &pattern)
{
    vector<string> res;
    if(str == "")
        return res;
    string strs = str + pattern;
    size_t pos = strs.find(pattern);

    while(pos != strs.npos)
    {
        string temp = strs.substr(0, pos);
        res.push_back(temp);
        strs = strs.substr(pos+1, strs.size());
        pos = strs.find(pattern);
    }

    return res;
}

struct ShowRegsMemsPass : public Pass {
    ShowRegsMemsPass() : Pass("show_regs_mems", "Show the list of the registers and the memorys in the design") { }
	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
        log_header(design, "Executing show_regs_mems pass (Show the list of the registers and the memorys in the design).\n");
        std::string outFolder = "";
        for (size_t i = 1;i<args.size()-1;i++ ){
            if (args[i] == "-o"){
                i += 1;
                outFolder = args[i] + "/";
                i += 1;
            }
        }

        RTLIL::IdString main = RTLIL::escape_id(args[args.size()-1]);
        if (design->module(main) == nullptr)
		    log_cmd_error("Can't find the module to be tainted %s!\n", main.c_str());
        /* 
        std::list< RTLIL::IdString > mem_list;                              
        if (args.size() != 2)
            if (args[2] == "-m") { 
                for (size_t i=3;i<args.size();i++)
                mem_list.push_back(RTLIL::escape_id(args[i]));
        }
        */

        RTLIL::Module *main_module = design->module(main);

        ofstream regs_mems;
        std::string outFile = outFolder+"regs_mems.dat";
        regs_mems.open(outFile);


        // log("---------------------------------Original memorys------------------------------------------\n");
        for (auto &it : main_module->memories) {
            // dump_memory(cout, "  ", it.second);
            std::string attr = (it.second->attributes["\\src"]).decode_string();
            //cout << attr;
            std::vector<string> attr_v = split(attr, "|");
            std::string filename;
            if ((attr_v).size() == 1 )
                filename = (split(attr_v[0],".v"))[0] + ".v";
            else
                filename = (split(attr_v[1],".v"))[0] + ".v";
            regs_mems << "Memories " <<RTLIL::id2cstr(it.second->name) << " " << it.second->width << " " << it.second->size <<" " << filename <<"\n";
        }

        // log("---------------------------------Original processes------------------------------------------\n");
        // for (auto it = main_module->processes.begin(); it != main_module->processes.end(); ++it)
		//     dump_proc(cout, "  ", it->second);


        // log("---------------------------------Original wires and registers------------------------------------------\n");
        for (auto it = main_module->wires().begin(); it != main_module->wires().end(); ++it) 
        {  
                //cout<<"WIRE\r\n"; 
                // log_wire(*it);
                regs_mems << "Variables " << (RTLIL::id2cstr((*it)->name)) << " " << (*it)->width << "\n";
        }

        // log("---------------------------------Original connections------------------------------------------\n");
        // std::list<std::pair<RTLIL::SigSpec,RTLIL::SigSpec>  > taintedConns;
        // for (auto it = main_module->connections().begin(); it != main_module->connections().end(); ++it) {
		//     dump_conn(cout, "  ", it->first, it->second);
        // }
      
        

        // log("---------------------------------Original registers------------------------------------------\n");
        for (auto &cell : main_module->cells_) {
            //Creat taint register
            if (RTLIL::builtin_ff_cell_types().count(cell.second->type)){
                //Show the original register 
                // dump_cell(cout, "  ", cell.second);
                if (((cell.second)->getPort(ID::Q)).is_wire()) {

                    Wire *w_reg = ((cell.second)->getPort(ID::Q)).as_wire();
                    regs_mems << "Registers " << RTLIL::id2cstr(w_reg->name) << " " << w_reg->width << "\n";
                }
            }      
        }


        // log("---------------------------------Original memory access cells------------------------------------------\n");
        // for (auto &cell : main_module->cells_) {  
        //     if (cell.second->type.in(ID($memrd),ID($memwr))) {
        //         dump_cell(cout, "  ", cell.second);
        //         log("\n");   
        //     }
        // }
        regs_mems.close();
    }
        

} ShowRegsMemsPass;

PRIVATE_NAMESPACE_END