#include "kernel/register.h"
#include "kernel/rtlil.h"
#include "kernel/log.h"
#include "kernel/yosys.h"
#include "kernel/sigtools.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN



struct AddModulePass : public Pass {
    AddModulePass() : Pass("addmodule", "Add module instance") { }
	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
        log_header(design, "Executing addModule pass (add module instance to existing design).\n");
        if (args.size() != 4){
            log("command argument error");
            exit(0);
        }
        RTLIL::IdString main = RTLIL::escape_id(args[1]);
	    RTLIL::IdString toInstantiate = RTLIL::escape_id(args[2]);
        if (design->module(main) == nullptr)
		    log_cmd_error("Can't find main module %s!\n", main.c_str());
	    if (design->module(toInstantiate) == nullptr)
		    log_cmd_error("Can't find toInstantiate module %s!\n", toInstantiate.c_str());

        RTLIL::Module *main_module = design->module(main);
	    RTLIL::Module *toInstantiate_module = design->module(toInstantiate);

        
        RTLIL::Cell *cell = main_module->addCell("\\"+ args[3], toInstantiate);

        for (auto wire : toInstantiate_module->wires())
        {
            // if (obs_wire->port_input)
            // {
            //     //set port for the observation module
            //     obs_cell->setPort(obs_wire->name, pipeline_module->wire(obs_wire->name));      
            // }
            if (wire->port_output)
            {
                //Create new wire and connect it to output port
                RTLIL::Wire *w = main_module->addWire("\\" + RTLIL::unescape_id(wire->name), wire->width);
                cell->setPort(wire->name, w);
            }
        }

	}
} AddModulePass;

PRIVATE_NAMESPACE_END
