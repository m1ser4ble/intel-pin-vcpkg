#include "pin.H"
#include <iostream>

KNOB<bool> ProfileCalls(KNOB_MODE_WRITEONCE, "pintool", "c", "0", "Profile function calls");
KNOB<bool> ProfileSyscalls(KNOB_MODE_WRITEONCE, "pintool", "s", "0", "Profile sys scalls");


std::map<ADDRINT, std::map<ADDRINT, unsigned long>> cflows;
std::map<ADDRINT, std::map<ADDRINT, unsigned long>> calls;
std::map<ADDRINT, unsigned long> syscalls;
std::map<ADDRINT, std::string> funcnames;

unsigned long insn_count =0 ;
unsigned long cflow_count = 0;
unsigned long call_count =0 ;
unsigned long syscall_count =0;

static void
count_bb_insns(UINT32 n)
{
	insn_count += n;
}

static void
count_cflow(ADDRINT ip, ADDRINT target)
{

	cflows[target][ip]++;
	cflow_count++;
}

static void
count_call(ADDRINT ip, ADDRINT target)
{
	calls[target][ip]++;
	call_count++;
}
void print_usage(){
	std::cout<<"test"<<std::endl;
}

static void 
parse_funcsyms(IMG img, void* v){
	if(!IMG_Valid(img)) return;
	for(SEC sec = IMG_SecHead(img); SEC_Valid(sec); sec = SEC_Next(sec)) {
		for(RTN rtn = SEC_RtnHead(sec) ; RTN_Valid(rtn); rtn = RTN_Next(rtn)){
			funcnames[RTN_Address(rtn)] = RTN_Name(rtn);
		}
	}

}

static void
instrument_bb(BBL bb){
	BBL_InsertCall(
			bb, IPOINT_ANYWHERE, (AFUNPTR)count_bb_insns,
			IARG_UINT32, BBL_NumIns(bb),
			IARG_END);
}

static void
instrument_trace(TRACE trace, void* v)
{
	IMG img = IMG_FindByAddress(TRACE_Address(trace));
	if(!IMG_Valid(img) || !IMG_IsMainExecutable(img)) return;
	for(BBL bb = TRACE_BblHead(trace); BBL_Valid(bb); bb=BBL_Next(bb)){
		instrument_bb(bb);
	}
}

static void
instrument_insn(INS ins, void* v)
{
	if(!INS_IsBranchOrCall(ins)) return;

	IMG img = IMG_FindByAddress(INS_Address(ins));
	if(!IMG_Valid(img) || !IMG_IsMainExecutable(img)) return;

	INS_InsertPredicatedCall(
			ins, IPOINT_TAKEN_BRANCH , (AFUNPTR)count_cflow,
			IARG_INST_PTR, IARG_BRANCH_TARGET_ADDR,
			IARG_END);

	if(INS_HasFallThrough(ins)){
		INS_InsertPredicatedCall(
				ins, IPOINT_AFTER, (AFUNPTR)count_cflow,
				IARG_INST_PTR, IARG_FALLTHROUGH_ADDR,
				IARG_END);
	}

	if(INS_IsCall(ins)){
		if(ProfileCalls.Value()){
			INS_InsertCall(
					ins, IPOINT_BEFORE, (AFUNPTR)count_call,
					IARG_INST_PTR, IARG_BRANCH_TARGET_ADDR,
					IARG_END);
		}
	}

}



static void
log_syscall(THREADID tid, CONTEXT* ctxt, SYSCALL_STANDARD std, VOID *v)
{
	syscalls[PIN_GetSyscallNumber(ctxt, std)]++;
	syscall_count++;
}

void print_results(int , void*){
}

int
main(int argc, char* argv[])
{
  PIN_InitSymbols();

  if(PIN_Init(argc, argv)){
    print_usage();
    return 1;
  }

  IMG_AddInstrumentFunction(parse_funcsyms,NULL);
  INS_AddInstrumentFunction(instrument_insn,NULL);
  TRACE_AddInstrumentFunction(instrument_trace, NULL);
  if(ProfileSyscalls.Value()) { 
    PIN_AddSyscallEntryFunction(log_syscall, NULL);
  }
  PIN_AddFiniFunction(print_results, NULL);

  PIN_StartProgram();
  return 0;

}
