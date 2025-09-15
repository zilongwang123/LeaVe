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

std::string id(RTLIL::IdString internal_id)
{
	const char *str = internal_id.c_str();
	bool do_escape = false;


	if (*str == '\\')
		str++;

	if ('0' <= *str && *str <= '9')
		do_escape = true;

	for (int i = 0; str[i]; i++)
	{
		if ('0' <= str[i] && str[i] <= '9')
			continue;
		if ('a' <= str[i] && str[i] <= 'z')
			continue;
		if ('A' <= str[i] && str[i] <= 'Z')
			continue;
		if (str[i] == '_')
			continue;
		do_escape = true;
		break;
	}

	static const pool<string> keywords = {
		// IEEE 1800-2017 Annex B
		"accept_on", "alias", "always", "always_comb", "always_ff", "always_latch", "and", "assert", "assign", "assume", "automatic", "before",
		"begin", "bind", "bins", "binsof", "bit", "break", "buf", "bufif0", "bufif1", "byte", "case", "casex", "casez", "cell", "chandle",
		"checker", "class", "clocking", "cmos", "config", "const", "constraint", "context", "continue", "cover", "covergroup", "coverpoint",
		"cross", "deassign", "default", "defparam", "design", "disable", "dist", "do", "edge", "else", "end", "endcase", "endchecker",
		"endclass", "endclocking", "endconfig", "endfunction", "endgenerate", "endgroup", "endinterface", "endmodule", "endpackage",
		"endprimitive", "endprogram", "endproperty", "endsequence", "endspecify", "endtable", "endtask", "enum", "event", "eventually",
		"expect", "export", "extends", "extern", "final", "first_match", "for", "force", "foreach", "forever", "fork", "forkjoin", "function",
		"generate", "genvar", "global", "highz0", "highz1", "if", "iff", "ifnone", "ignore_bins", "illegal_bins", "implements", "implies",
		"import", "incdir", "include", "initial", "inout", "input", "inside", "instance", "int", "integer", "interconnect", "interface",
		"intersect", "join", "join_any", "join_none", "large", "let", "liblist", "library", "local", "localparam", "logic", "longint",
		"macromodule", "matches", "medium", "modport", "module", "nand", "negedge", "nettype", "new", "nexttime", "nmos", "nor",
		"noshowcancelled", "not", "notif0", "notif1", "null", "or", "output", "package", "packed", "parameter", "pmos", "posedge", "primitive",
		"priority", "program", "property", "protected", "pull0", "pull1", "pulldown", "pullup", "pulsestyle_ondetect", "pulsestyle_onevent",
		"pure", "rand", "randc", "randcase", "randsequence", "rcmos", "real", "realtime", "ref", "reg", "reject_on", "release", "repeat",
		"restrict", "return", "rnmos", "rpmos", "rtran", "rtranif0", "rtranif1", "s_always", "s_eventually", "s_nexttime", "s_until",
		"s_until_with", "scalared", "sequence", "shortint", "shortreal", "showcancelled", "signed", "small", "soft", "solve", "specify",
		"specparam", "static", "string", "strong", "strong0", "strong1", "struct", "super", "supply0", "supply1", "sync_accept_on",
		"sync_reject_on", "table", "tagged", "task", "this", "throughout", "time", "timeprecision", "timeunit", "tran", "tranif0", "tranif1",
		"tri", "tri0", "tri1", "triand", "trior", "trireg", "type", "typedef", "union", "unique", "unique0", "unsigned", "until", "until_with",
		"untyped", "use", "uwire", "var", "vectored", "virtual", "void", "wait", "wait_order", "wand", "weak", "weak0", "weak1", "while",
		"wildcard", "wire", "with", "within", "wor", "xnor", "xor",
	};
	if (keywords.count(str))
		do_escape = true;

	if (do_escape)
		return "\\" + std::string(str) + " ";
	return std::string(str);
}

// getting information by phasing the signal
std::string sig_phase(RTLIL::SigSpec signal)
{
    std::string info = "";
    for (auto chunk = signal.chunks().begin(); chunk != signal.chunks().end(); chunk++) {
        if ((*chunk).wire == NULL) {
            info = info + "Const;";
        } else {
            if ((*chunk).width == (*chunk).wire->width && (*chunk).offset == 0) {
                info = info + id((*chunk).wire->name).c_str() + ":=" + std::to_string((*chunk).wire->width) + ";";
            } else if ((*chunk).width == 1) {
                if ((*chunk).wire->upto)
                    info = info + stringf("%s[%d]", id((*chunk).wire->name).c_str(), ((*chunk).wire->width - (*chunk).offset - 1) + (*chunk).wire->start_offset) + ":=" +  std::to_string((*chunk).width) +";";
                else
                    info = info + stringf("%s[%d]", id((*chunk).wire->name).c_str(), (*chunk).offset + (*chunk).wire->start_offset) + ":=" +  std::to_string((*chunk).width) +";";
            } else {
                if ((*chunk).wire->upto)
                    info = info + stringf("%s[%d:%d]", id((*chunk).wire->name).c_str(),
                            ((*chunk).wire->width - ((*chunk).offset + (*chunk).width - 1) - 1) + (*chunk).wire->start_offset,
                            ((*chunk).wire->width - (*chunk).offset - 1) + (*chunk).wire->start_offset) + ":=" +  std::to_string((*chunk).width) +";";
                else
                    info = info + stringf("%s[%d:%d]", id((*chunk).wire->name).c_str(),
                            ((*chunk).offset + (*chunk).width - 1) + (*chunk).wire->start_offset,
                            (*chunk).offset + (*chunk).wire->start_offset) + ":=" +  std::to_string((*chunk).width) +";";
            }
        }
    }
        
    return info;
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
		    log_cmd_error("Can't find the module to parse %s!\n", main.c_str());
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
            regs_mems << "Memories||" <<RTLIL::id2cstr(it.second->name) << "||" << it.second->width << "||" << it.second->size <<"||" << filename <<"\n";
        }

        // log("---------------------------------Original processes------------------------------------------\n");
        // for (auto it = main_module->processes.begin(); it != main_module->processes.end(); ++it)
		//     dump_proc(cout, "  ", it->second);


        // log("---------------------------------Original wires and registers------------------------------------------\n");
        for (auto it = main_module->wires().begin(); it != main_module->wires().end(); ++it) 
        {  
                //cout<<"WIRE\r\n"; 
                // log_wire(*it);
                regs_mems << "Variables||" << (RTLIL::id2cstr((*it)->name)) << "||" << (*it)->width << "\n";
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
                    regs_mems << "Registers||" << RTLIL::id2cstr(w_reg->name) << "||" << w_reg->width << "\n";
                }
            }      
        }

////////////////////// for updating invariants 

        log("---------------------------------$dffe cells------------------------------------------\n");
        for (auto &cell : main_module->cells_) {  
            if (cell.second->type.in(ID($dffe)))
            {
                // dump_cell(cout, "  ", cell.second);
                regs_mems << "$dffe||";
                regs_mems << sig_phase(cell.second->getPort(ID::EN)) << "||" ;
                regs_mems << sig_phase(cell.second->getPort(ID::D));

                regs_mems <<"\n";
                // log("\n");   
            }
        }

        log("---------------------------------$mux cells------------------------------------------\n");
        for (auto &cell : main_module->cells_) {  
            if (cell.second->type.in(ID($mux)))
            {
                // dump_cell(cout, "  ", cell.second);
                regs_mems << "$mux||";
                regs_mems << sig_phase(cell.second->getPort(ID::Y)) << "||" ;
                regs_mems << sig_phase(cell.second->getPort(ID::S)) << "||" ;

                regs_mems << sig_phase(cell.second->getPort(ID::B)) << "||" ;
                regs_mems << sig_phase(cell.second->getPort(ID::A)) ;
                regs_mems <<"\n";
                // log("\n");   
            }
        }
        regs_mems.close();
    }
        

} ShowRegsMemsPass;

PRIVATE_NAMESPACE_END
