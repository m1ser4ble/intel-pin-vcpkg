#include "pin.H"

KNOB<bool> ProfileCalls(KNOB_MODE_WRITEONCE, "pintool", "c", "0", "Profile function calls");
KNOB<bool> ProfileSyscalls(KNOB_MODE_WRITEONCE, "pintool", "s", "0", "Profile sys scalls");


std::map<ADDRINT, std::map<ADDRINT, unsigned long>> cflows;
std::map<ADDRINT, std::map<ADDRINT, unsigned long>> calls;
std::map<ADDRINT, unsigned long> syscalls;
std::map<ADDRINT, std::string> funcnames;

unsigned long insn_count =0 ;
unsigned long clfow_count = 0;
unsigned long call_count =0 ;
unsigned long syscall_count =0;

int
main(int argc, char* argv[])
{
  PIN_InitSymbols();

  if(PIN_Init(argc, argv)){
    print_usage();
    return 1;
  }

  IMG_AddInstrumentFunction(parse_funcsyms,NULL);
  IMG_AddInstrumentFunction(instrument_insn,NULL);
  TRACE_AddInstrumentFunction(instrument_trace, NULL);
  if(ProfileSyscalls.Value()) { 
    PIN_AddSyscallEntryFunction(log_syscall, NULL);
  }
  PIN_AddFiniFunction(print_results, NULL);

  PIN_StartProgram();
  return 0;

}
