#include <stdio.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"

int main (void)
{
	 int i = 0;
	
	while(1){
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, 0x3FF);
		for(i=0; i<1000000; i++);
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, 0x000);
		for(i=0; i<1000000; i++);
	}
	
	return 0;
}


