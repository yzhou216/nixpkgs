#include <stdio.h>
#include "HsFFI.h"
#include "Exports_stub.h"

extern void __stginit_Exports(void);

int main(int argc, char *argv[])
{
	hs_init(&argc, &argv);
	hs_add_root(__stginit_Exports);
	printf("%d %d\n", (int)triple(14), (int)hs_concat_len(5));
	hs_exit();
	return 0;
}
