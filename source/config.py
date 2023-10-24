## Config
class ConfCls:
    # input/output information
    codeFolder: str = "" # folder with Verilog sources
    outFolder: str = "" # target folder for intermediate data
    prodCircuitTemplate: str = ""
    clockInput: str = ""
    initRegister: str = ""
    lookAhead: str = ""
    cycleDelayedBound: str = ""

    # Backends
    yosysPath: str = ""
    avrPath: str = ""
    yosysBMCPath : str = ""
    yosysAdditionalModules = []
    inductiveyosysBMCBound : str = ""
    checkyosysBMCBound : str = ""
    directlycheckyosysBMCBound : str = ""
    prefixCheck: str = ""
    yosysBMCSolver: str = "yices"
    yosysSMTPreprocessing  = ["async2sync","dffunmap"] 
    ## alternatives can be ["clk2fflogic"] or ["dffunmap"] or ["async2sync", "dffunmap"]

    yosysCtxCycle = "cycle"
    yosysCtxClock = "clock"
    yosysCtxUUT = "UUT"
    yosysCtxDisplayAtEdge : bool = True

    # iverilog and vpp
    iverilogPath: str = ""
    vvpPath: str = ""

    # product circuit
    selfCompositionInitVariable: str = "init"
    selfCompositionEquality: str = "=="
    selfCompositionInequality: str = "!="

    # root module for analysis
    module: str = ""
    moduleFile: str = ""
    maxinstruction: str = ""
    retirepredicate: str = ""
    memoryList = []

    # output
    outputformat = ""

    #invariant
    invariant = []
    stateInvariant = []

    # observations
    srcObservations = []
    trgObservations = []
    filteredSrcObservations = []

    #predicates
    predicateRetire = []
    predicatePI = []
    
    # visible state
    state = []
    extrastate = []

    # inputs
    inputs = []

    # auxiliary variables
    auxiliaryVariables = []

    # index metavariables
    metaVars = []

    # preprocessing
    expandArrays = []

    verbose_preprocessing = True
    verbose_verification = True
    verbose_counterexample_checking = True
    verbose_external_processes = True

    def set(self, name, value):
        options = {
            'selfCompositionEquality': ['==', '==='],
            'selfCompositionInequality': ['!=', '!==']
        }

        if self.__getattribute__(name) is None:
            print(f"Error: Unknown configuration variable {name}.\n"
                  f"It's likely a typo in the configuration file.")
            exit(1)
        if type(self.__getattribute__(name)) != type(value):
            print(f"Error: Wrong type of the configuration variable {name}.\n"
                  f"It's likely a typo in the configuration file.")
            exit(1)

        # value checks
        # TODO: would be great to have more of these
        if options.get(name, '') != '' and value not in options[name]:
            print(f"Error: Unknown value '{value}' of configuration variable '{name}'")
            exit(1)

        self.__setattr__(name, value)



CONF = ConfCls()