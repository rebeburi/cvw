#include <stdint.h>

extern uint32_t fpu_stress_test();

int main(){

	uint32_t checksum = fpu_stress_test();
	
	if(checksum == 0)
		return 1;

	return 0;
}
