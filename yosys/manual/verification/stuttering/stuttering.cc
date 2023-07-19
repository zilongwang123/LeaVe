#include "kernel/register.h"
#include "kernel/rtlil.h"
#include "kernel/log.h"
#include "kernel/yosys.h"
#include "kernel/sigtools.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN
using namespace std;


struct AddModulePass : public Pass {
    AddModulePass() : Pass("stuttering", "stuttering the module based on the stuttering signal") { }
	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
        log_header(design, "Executing stuttering pass (stuttering the module based on the stuttering signal).\n");
        if (args.size() != 3){
            log("command argument error");
            exit(0);
        }
        RTLIL::IdString main = RTLIL::escape_id(args[1]);
	    RTLIL::IdString stuttering_signal = RTLIL::escape_id(args[2]);
        if (design->module(main) == nullptr)
		    log_cmd_error("Can't find main module %s!\n", main.c_str());

        RTLIL::Module *main_module = design->module(main);

        for (auto &cell : main_module->cells_) {
            //stuttering registers
            if (RTLIL::builtin_ff_cell_types().count(cell.second->type)){
                log("---------------------------------stuttering register cells------------------------------------------\n");
                RTLIL::SigSpec APort = cell.second->getPort(ID::D);
                RTLIL::SigSpec BPort = cell.second->getPort(ID::Q);
                int width = (cell.second->parameters["\\WIDTH"]).as_int();
                log_cell(cell.second);  
                
                std::string intermedia_signal_name = RTLIL::escape_id(RTLIL::id2cstr((cell.second->name)) + std::string("_intermedia_signal"));
                std::string stuttering_cell_name = RTLIL::escape_id(RTLIL::id2cstr((cell.second->name)) + std::string("_stuttering_cell"));
                cout << intermedia_signal_name << "\n";
                cout << stuttering_cell_name << "\n";
                // intermedia_signal_wire
                RTLIL::Wire *intermedia_signal = main_module->addWire(intermedia_signal_name, width);
                
                // update the register cell with the intermedia signal
                cell.second->setPort(ID::D, intermedia_signal);
                log_cell(cell.second);

                // generate an conditional assignment base on the stuttering signal
                RTLIL::Cell *stuttering_assignment = main_module->addCell(stuttering_cell_name, ID($mux));
                log("---------------------------------Width------------------------------------------\n");
                stuttering_assignment->parameters["\\WIDTH"] = width;
                log("---------------------------------Y------------------------------------------\n");
                stuttering_assignment->setPort(ID::Y, intermedia_signal);
                log("---------------------------------S------------------------------------------\n");
                stuttering_assignment->setPort(ID::S, main_module->wire(stuttering_signal));
                log("---------------------------------A------------------------------------------\n");
                stuttering_assignment->setPort(ID::A, APort);
                log("---------------------------------B------------------------------------------\n"); 
                stuttering_assignment->setPort(ID::B, BPort);

                log_cell(stuttering_assignment);              
                
                
            }      
        }

	}
} AddModulePass;

PRIVATE_NAMESPACE_END
