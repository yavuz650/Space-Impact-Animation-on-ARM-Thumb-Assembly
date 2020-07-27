/*
ARM CORTEX-M0 EMULATOR CODE
written by Yavuz Selim Tozlu.
*/

#include "emulib.h"

typedef struct {
    int32_t reg[16];
    int32_t cpsr;
}tCPU;

uint8_t rom[0x200000]; // 2,097,152 bytes
uint8_t ram[0x100000]; // 1,048,576 bytes 
tCPU cpu;

uint64_t count = 0;
//Fetches an instruction from ROM, decodes and executes it
int32_t execute(void)
{
    uint32_t pc;
    uint32_t sp;
	uint32_t inst;
	int32_t ra, rb, rc, imm;
	uint32_t rm, rd, rn, rs;
	uint32_t op;
	int32_t poff;
	uint16_t X;

	pc = cpu.reg[15];

	X = pc - 2;
	inst = rom[X] | rom[X+1] << 8;
	pc += 2;
	cpu.reg[15] = pc;
	
	count++;
	
	if((inst & 0xF000) == 0x0000) // LSL | LSR Rd, Rm, #<shift>
	{
		rd = inst & 0x7; rm = (inst >> 3) & 0x7;
		imm = (inst >> 6) & 0x1F;
		op = (inst >> 11) & 0x1;
		ra = cpu.reg[rm];
		if(op == 0) //LSL 
		{
			rc = ra << imm;
			cpu.reg[rd] = rc;
			//set flags
			cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
			cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
			if(imm != 0)
			{
				rc = rc << (imm-1); //shift the carry bit to MSB, so we can extract it.
				cpu.cpsr &= 0xDFFFFFFF; // set carry bit to 0
				cpu.cpsr |= (rc >> 2) & 0x20000000; // shift MSB of rc to the position of the carry bit, then set carry bit.	
			}
		}
		else // LSR
		{
			rc = (uint32_t)ra >> imm;
			cpu.reg[rd] = rc;
			//set flags
			cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
			cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
			if(imm != 0)
			{
				rc = rc >> (imm-1); //shift the carry bit to LSB, so we can extract it.
				cpu.cpsr &= 0xDFFFFFFF; // set carry bit to 0
				cpu.cpsr |= (rc << 29) & 0x20000000; // shift LSB of rc to the position of the carry bit, then set carry bit.	
			}
		}
		return 0;
	}
	
	if((inst & 0xF800) == 0x1000) // ASRS Rd, Rm, #<shift>
	{
			rd = inst & 0x7; rm = (inst >> 3) & 0x7;
			imm = (inst >> 6) & 0x1F;
			ra = cpu.reg[rd];
			
			rc = ra >> imm;
			cpu.reg[rd] = rc;
			
			//set flags
			cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
			cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
			
			rc = rc >> (imm-1); //shift the carry bit to LSB, so we can extract it.
			cpu.cpsr &= 0xDFFFFFFF; // set carry bit to 0
			cpu.cpsr |= (rc << 29) & 0x20000000; // shift LSB of rc to the position of the carry bit, then set carry bit.	

			return 0;
	}
	
	if((inst & 0xF000) == 0x2000) // MOV | CMP
	{
		imm = inst & 0x00FF; rd = (inst >> 8) & 0x7;
		op = (inst >> 11) & 0x1;
		
		if(op == 0) //MOVS Rd, #<imm>
		{
			cpu.reg[rd] = imm;
		}
		else //CMP Rn, #<imm>
		{
			ra = cpu.reg[rd];
			rc = ra - imm;
			//set flags
			cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
			cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
			cpu.cpsr = rc >= 0 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && imm > 0 && rc > 0) || (ra > 0 && imm < 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;
		
		}
		return 0;
	}
	
	if((inst & 0xFC00) == 0x1800) // ADDS | SUBS Rd, Rn, Rm
	{
		rd = inst & 0x7; rn = (inst >> 3) & 0x7; rm	= (inst >> 6) & 0x7;
		ra = cpu.reg[rn]; rb = cpu.reg[rm];
		op = (inst >> 9) & 0x1;
		
		if(op == 0) //ADDS Rd, Rn, Rm
		{
			rc = ra + rb;
			cpu.reg[rd] = rc;
			cpu.cpsr = ((uint64_t)ra+(uint64_t)rb) >= 42949672956 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb < 0 && rc > 0) || (ra > 0 && rb > 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;			
		}
		else //SUBS Rd, Rn, Rm
		{
			rc = ra - rb;
			cpu.reg[rd] = rc;
			//set flags
			cpu.cpsr = rc >= 0 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb > 0 && rc > 0) || (ra > 0 && rb < 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;
		}
		//set flags
		cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
		cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
		return 0;
	}
	
	if((inst & 0xFC00) == 0x1C00) // ADDS | SUBS Rd, Rn, #<imm3>
	{
		rd = inst & 0x7; rn = (inst >> 3) & 0x7; imm = (inst >> 6) & 0x7;
		ra = cpu.reg[rn]; rb = imm;
		op = (inst >> 9) & 0x1;
		
		if(op == 0) //ADDS Rd, Rn, #<imm3>
		{
			rc = ra + rb;
			cpu.reg[rd] = rc;
			//set flags
			cpu.cpsr = ((uint64_t)ra+(uint64_t)rb) >= 42949672956 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb < 0 && rc > 0) || (ra > 0 && rb > 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;			
		}
		else //SUBS Rd, Rn, #<imm3>
		{
			rc = ra - rb;
			cpu.reg[rd] = rc;
			//set flags
			cpu.cpsr = rc >= 0 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb > 0 && rc > 0) || (ra > 0 && rb < 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;			
		}
		//set flags
		cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
		cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z	
		return 0;
	}
	
	if((inst & 0xF000) == 0x3000) // ADDS | SUBS Rd, Rd, #<imm8>
	{
		imm = inst & 0xFF; rd = (inst >> 8) & 0x7;
		ra = cpu.reg[rd]; rb = imm;
		op = (inst >> 11) & 0x1;
		
		if(op == 0) //ADDS Rd, Rd, #<imm8>
		{
			rc = ra + rb;
			cpu.reg[rd] = rc;
			//set flags
			cpu.cpsr = ((uint64_t)ra+(uint64_t)rb) >= 42949672956 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb < 0 && rc > 0) || (ra > 0 && rb > 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;
		}
		else //SUBS Rd, Rd, #<imm8>
		{
			rc = ra - rb;
			cpu.reg[rd] = rc;
			//set flags
			cpu.cpsr = rc >= 0 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb > 0 && rc > 0) || (ra > 0 && rb < 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;				
		}
		//set flags
		cpu.cpsr = (rc < 0) ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
		cpu.cpsr = (rc == 0) ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
		
		return 0;
	}
	
	if((inst & 0xF000) == 0xA000) // ADD Ld, pc, #immed*4 | ADD Ld, sp, #immed*4
	{
		imm = inst & 0xFF; rd = (inst >> 8) & 0x7;
		if ((inst & 0x0800) == 0x0000) // ADD Ld, pc, #immed*4
		{
			ra = cpu.reg[15];
			rc = ra + imm;
			cpu.reg[rd] = rc;
		}
		else // ADD Ld, sp, #immed*4
		{
			ra = cpu.reg[13];
			rc = ra + imm;
			cpu.reg[rd] = rc;		
		}
		return 0;
	}
	
	if((inst & 0xFF00) == 0xB000) // ADD sp, #immed*4 | SUB sp, #immed*4
	{
		op = (inst >> 7) & 0x1;
		if(op == 0) // ADD sp, #immed*4
		{
			cpu.reg[13] += 4*(inst & 0x7F);
			return 0;
		}
		cpu.reg[13] -= 4*(inst & 0x7F); // SUB sp, #immed*4
		return 0;
	}
	
	if((inst & 0xFF00) == 0x4000) // AND | EOR | LSL | LSR
	{
		rd = inst & 0x7; rm = (inst >> 3) & 0x7; rs = (inst >> 3) & 0x7; 
		op = (inst >> 6) & 0x3;
		ra = cpu.reg[rd]; rb = cpu.reg[rm];
		if(op == 0) // ANDS Rd, Rd, Rm 
		{
			rc = ra & rb;
			cpu.reg[rd] = rc;
		}
		else if(op == 1) // EORS Rd, Rd, Rm
		{
			rc = ra ^ rb;
			cpu.reg[rd] = rc;
		}
		else if(op == 2) // LSLS Rd, Rd, Rs
		{
			uint8_t shamt = rb & 0x000000FF; //since shift amount is 8-bit by definition, uint8_t is used.
			rc = cpu.reg[rd] << shamt;
			cpu.reg[rd] = rc;
					
			if(shamt != 0)
			{
				rc = rc << (shamt-1); //shift the carry bit to MSB, so we can extract it.
				cpu.cpsr &= 0xDFFFFFFF; // set carry bit to 0
				cpu.cpsr |= (rc >> 2) & 0x20000000; // shift MSB of rc to the position of the carry bit, then set carry bit.
			}
		}
		else if(op == 3) // LSRS Rd, Rd, Rs
		{
			uint8_t shamt = rb & 0x000000FF; //since shift amount is 8-bit by definition, uint8_t is used.
			rc = (uint32_t)ra >> shamt;
			cpu.reg[rd] = rc;
					
			if(shamt != 0)
			{
				rc = rc >> (shamt-1); //shift the carry bit to LSB, so we can extract it.
				cpu.cpsr &= 0xDFFFFFFF; // set carry bit to 0
				cpu.cpsr |= (rc << 29) & 0x20000000; // shift LSB of rc to the position of the carry bit, then set carry bit.
			}
		}
		//set flags
		cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
		cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
		return 0;
	}
	
	if((inst & 0xFF00) == 0x4100) // ASR | ADC | SBC | ROR
	{
		rd = inst & 0x7; rm = (inst >> 3) & 0x7; rs = (inst >> 3) & 0x7; 
		op = (inst >> 6) & 0x3;
		ra = cpu.reg[rd]; rb = cpu.reg[rm];
		
		if(op == 0) // ASRS Rd, Rd, Rs
		{
			rc = ra >> (rb & 0x000000FF);
			cpu.reg[rd] = rc;
		}
		else if(op == 1) // ADCS Rd, Rd, Rm
		{
			uint32_t carry_bit = (cpu.cpsr >> 29) & 0x1;
			cpu.reg[rd] = ra + rb + carry_bit;
			//set flags
			cpu.cpsr = ((uint64_t)ra+(uint64_t)rb+carry_bit) > 42949672956 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb < 0 && rc > 0) || (ra > 0 && rb > 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;
		}
		else if(op == 2) // SBCS Rd, Rd, Rm
		{
			int32_t carry_bit = (cpu.cpsr >> 29) & 0x1;
			rc = ra - rb - (~carry_bit);
			cpu.reg[rd] = rc;
			//set flags
			cpu.cpsr = rc >= 0 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb > 0 && rc > 0) || (ra > 0 && rb < 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;		
		}
		else if(op == 3) // RORS Rd, Rd, Rs
		{
			int32_t shamt = rb & 0x000000FF;
			int32_t mask = ~((int32_t)0x80000000 >> (shamt-1));
			rc = ((ra >> shamt) & mask) | (ra  << (32-shamt));
			cpu.reg[rd] = rc;
			//set flags
			if((cpu.reg[rm] & 0x000000FF) != 0)
			{
				cpu.cpsr &= 0xDFFFFFFF; // set carry bit to 0
				cpu.cpsr |= (rc >> 2) & 0x20000000; // set carry bit to MSB of rc
			}
		}
		//set flags
		cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
		cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
		return 0;
	}
	
	if((inst & 0xFF00) == 0x4200) // TST | NEG | CMP | CMN (TST and NEG are not implemented)
	{
		rd = inst & 0x7; rn = inst & 0x7; rm = (inst >> 3) & 0x7;
		op = (inst >> 6) & 0x3;
		ra = cpu.reg[rd]; rb = cpu.reg[rm];
		
		if(op == 2) // CMP Rn, Rm (Lo to Lo)
		{
			rc = ra - rb;
			//set flags
			cpu.cpsr = rc >= 0 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb > 0 && rc > 0) || (ra > 0 && rb < 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;
		}
		
		if(op == 3) // CMN Rn, Rm (Lo to Lo)
		{
			rc = ra + rb;
			//set flags
			cpu.cpsr = ((uint32_t)ra+(uint32_t)rb) >= 42949672956 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
			if((ra < 0 && rb < 0 && rc > 0) || (ra > 0 && rb > 0 && rc < 0)) //V
				cpu.cpsr |= 0x10000000;
			else
				cpu.cpsr &= 0xE0000000;
		}
		//set flags
		cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
		cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
		return 0;
	}
	
	if((inst & 0xFF00) == 0x4300) // ORR | MUL | BIC | MVN (BIC and MVN are not implemented)
	{
		rd = inst & 0x7; rm = (inst >> 3) & 0x7;
		op = (inst >> 6) & 0x3;
		ra = cpu.reg[rd]; rb = cpu.reg[rm];
		
		if(op == 0) //ORRS Rd, Rd, Rm
		{
			rc = ra | rb;
			cpu.reg[rd] = rc;
			
		}
		else if(op == 1) //MULS Rd, Rd, Rm
		{
			rc = ra * rb;
			cpu.reg[rd] = rc;
		}
		//set flags
		cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
		cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
		return 0;
	}

	if((inst & 0xFDC0) == 0x4440) // ADD | MOV Ld, Hm
	{
		rd = inst & 0x7; rm = ((inst >> 3) & 0x7)+8; // +8 because rm is of Hi register.
		ra = cpu.reg[rd]; rb = cpu.reg[rm];
		op = (inst >> 9) & 0x1;
		
		if(op == 0) //ADD Rd, Rd, Rm (Hi to Lo)
		{
			rc = ra + rb;
			cpu.reg[rd] = rc;			
		}
		else // MOV Rd, Rm (Hi to Lo)
		{
			cpu.reg[rd] = cpu.reg[rm];
		}
		return 0;
	}
	
	if((inst & 0xFDC0) == 0x4480) // ADD | MOV Hd, Lm
	{
		rd = (inst & 0x7)+8; rm = (inst >> 3) & 0x7; // +8 because rm is of Hi register.
		ra = cpu.reg[rd]; rb = cpu.reg[rm];
		op = (inst >> 9) & 0x1;
		
		if(op == 0) //ADD Rd, Rd, Rm (Lo to Hi)
		{
			rc = ra + rb;
			cpu.reg[rd] = rc;			
		}
		else // MOV Rd, Rm (Lo to Hi)
		{
			cpu.reg[rd] = cpu.reg[rm];
		}
		return 0;
	}
	
	if((inst & 0xFDC0) == 0x44C0) // ADD | MOV Hd, Hm
	{
		rd = (inst & 0x7)+8; rm = ((inst >> 3) & 0x7)+8; // +8 because Hi registers.
		ra = cpu.reg[rd]; rb = cpu.reg[rm];
		op = (inst >> 9) & 0x1;
		
		if(op == 0) //ADD Rd, Rd, Rm (Hi to Hi)
		{
			rc = ra + rb;
			cpu.reg[rd] = rc;			
		}
		else // MOV Rd, Rm (Hi to Hi)
		{
			cpu.reg[rd] = cpu.reg[rm];
		}
		return 0;
	}	
	
	if((inst & 0xFF00) == 0x4500) // CMP
	{
		op = (inst >> 6) & 3;
		if(op == 1) // CMP Hm, Ln
		{
			rn = inst & 0x7; rm = ((inst >> 3) & 0x7)+8;		
			ra = cpu.reg[rn]; rb = cpu.reg[rm];
		}
		if(op == 2) // CMP Lm, Hn
		{
			rn = (inst & 0x7)+8; rm = (inst >> 3) & 0x7;
			ra = cpu.reg[rn]; rb = cpu.reg[rm];		
		}
		if(op == 3) // CMP Hm, Hn
		{
			rn = (inst & 0x7)+8; rm = ((inst >> 3) & 0x7)+8;		
			ra = cpu.reg[rn]; rb = cpu.reg[rm];			
		}
		rc = ra - rb;
		//set flags
		cpu.cpsr = rc < 0 ? (cpu.cpsr | 0x80000000) : (cpu.cpsr & 0x7FFFFFFF); //N
		cpu.cpsr = rc == 0 ? (cpu.cpsr | 0x40000000) : (cpu.cpsr & 0xBFFFFFFF); //Z
		cpu.cpsr = rc >= 0 ? (cpu.cpsr | 0x20000000) : (cpu.cpsr & 0xDFFFFFFF); //C
		if((ra < 0 && rb > 0 && rc > 0) || (ra > 0 && rb < 0 && rc < 0)) //V
			cpu.cpsr |= 0x10000000;
		else
			cpu.cpsr &= 0xE0000000;
				
		return 0;
	}

	if((inst & 0xFF00) == 0x4700) // BX | BLX
	{
		op = (inst >> 7) & 0x1;
		rm = (inst >> 3) & 0xF;
		ra = cpu.reg[rm];
		
		cpu.reg[15] = ra & 0xFFFFFFFE; // BX and BLX

		if(op == 1) // BLX only
			cpu.reg[14] = pc;
			
		return 0;
	}
	
	if((inst & 0xF800) == 0x4800) // LDR Ld, [pc, #immed*4]
	{
		imm = inst & 0xFF;
		rd = (inst >> 8) & 0x7;
		uint32_t addr = pc + 4*imm;
		addr = (addr % 4) == 0 ? addr : (addr-(addr % 4)); // word aligned
		if((addr < 0x20000000)) //rom
		{
			uint32_t value = rom[addr] | (rom[addr+1] << 8) | (rom[addr+2] << 16) | (rom[addr+3] << 24); //pc relative address means data is retrieved from rom.
			cpu.reg[rd] = value;
			return 0;
		}
		addr -= 0x20000000;
		cpu.reg[rd] = ram[addr] | (ram[addr+1] << 8) | (ram[addr+2] << 16) | (ram[addr+3] << 24);
		return 0;
	}
	
	if((inst & 0xFE00) == 0x5000) // STR Rd, [Rn, Rm] 
	{
		rd = inst & 0x7; rn = (inst >> 3) & 0x7; rm = (inst >> 6) & 0x7;
		ra = cpu.reg[rn]; rb = cpu.reg[rm]; rc = cpu.reg[rd];
		uint32_t addr = ra+rb;
		
		if(((ra + rb) & 0x40010000) == 0x40010000) //peripheral
		{
			if(peripheral_write(addr, (uint32_t) rc) != 0)	return 1;
			return 0;
		}
		else if((addr < 0x20000000)) //rom
		{
			rom[addr] = rc & 0xFF; rom[addr+1] = (rc >> 8) & 0xFF; rom[addr+2] = (rc >> 16) & 0xFF; rom[addr+3] = (rc >> 24) & 0xFF;
			return 0;
		}
		addr -= 0x20000000;
		ram[addr] = rc & 0xFF; ram[addr+1] = (rc >> 8) & 0xFF; ram[addr+2] = (rc >> 16) & 0xFF; ram[addr+3] = (rc >> 24) & 0xFF;
		return 0;
	}
	
	if((inst & 0xFE00) == 0x5800) // LDR Rd, [Rn, Rm]
	{
		rd = inst & 0x7; rn = (inst >> 3) & 0x7; rm = (inst >> 6) & 0x7;
		ra = cpu.reg[rn]; rb = cpu.reg[rm];
		uint32_t addr = ra+rb;
		
		if((addr & 0x40010000) == 0x40010000) //peripheral
		{
			if(peripheral_read(addr, (uint32_t*)rd) != 0) return 1;
			return 0;
		}
		else if((addr < 0x20000000)) //rom
		{
			cpu.reg[rd] = rom[addr] | (rom[addr+1] << 8) | (rom[addr+2] << 16) | (rom[addr+3] << 24);
			return 0;
		}
		addr -= 0x20000000;
		cpu.reg[rd] = ram[addr] | (ram[addr+1] << 8) | (ram[addr+2] << 16) | (ram[addr+3] << 24);
		return 0;
	}
	
	if((inst & 0xF000) == 0x6000) // STR | LDR Ld, [Ln, #immed*4]
	{
		rd = inst & 0x7; rn = (inst >> 3) & 0x7; imm = (inst >> 6) & 0x1F;
		op = (inst >> 11) & 0x1;
		ra = cpu.reg[rn]; rc = cpu.reg[rd];
		
		uint32_t addr = ra + 4*imm;
		if(op == 0) // STR Ld, [Ln, #immed*4]
		{
			if((addr & 0x40010000) == 0x40010000) //peripheral
			{	
				if(peripheral_write(addr, (uint32_t) rc) != 0)	return 1;
				
				return 0;
			}
			else if((addr < 0x20000000)) //rom
			{
				rom[addr] = rc & 0xFF; rom[addr+1] = (rc >> 8) & 0xFF; rom[addr+2] = (rc >> 16) & 0xFF; rom[addr+3] = (rc >> 24) & 0xFF;
				return 0;
			}
			addr -= 0x20000000;
			ram[addr] = rc & 0xFF; ram[addr+1] = (rc >> 8) & 0xFF; ram[addr+2] = (rc >> 16) & 0xFF; ram[addr+3] = (rc >> 24) & 0xFF;
			return 0;
		}
		else // LDR Ld, [Ln, #immed*4]
		{
			if((addr & 0x40010000) == 0x40010000) //peripheral
			{
				if(peripheral_read(addr, (uint32_t*)rc) != 0) return 1;
				cpu.reg[rd] = rc;
				return 0;
			}
			else if((addr < 0x20000000)) //rom
			{
				cpu.reg[rd] = rom[addr] | (rom[addr+1] << 8) | (rom[addr+2] << 16) | (rom[addr+3] << 24);
				return 0;
			}
			addr -= 0x20000000;
			cpu.reg[rd] = ram[addr] | (ram[addr+1] << 8) | (ram[addr+2] << 16) | (ram[addr+3] << 24);
			return 0;
		}
	}

	if((inst & 0xF000) == 0x9000) // STR | LDR Ld, [sp, #immed*4]
	{
		rd = (inst >> 8) & 0x7; imm = inst & 0x00FF;
		op = (inst >> 11) & 0x1;
		rc = cpu.reg[rd]; ra = cpu.reg[13];
		uint32_t addr = ra+4*imm;
		
		if(op == 0) // STR Ld, [sp, #immed*4]
		{
			if((addr & 0x40010000) == 0x40010000) //peripheral
			{	
				if(peripheral_write(addr, (uint32_t) rc) != 0) return 1;
			}
			else if((addr < 0x20000000)) //rom
			{
				rom[addr] = rc & 0xFF; rom[addr+1] = (rc >> 8) & 0xFF; rom[addr+2] = (rc >> 16) & 0xFF; rom[addr+3] = (rc >> 24) & 0xFF;
				return 0;
			}
			addr -= 0x20000000;
			ram[addr] = rc & 0xFF; ram[addr+1] = (rc >> 8) & 0xFF; ram[addr+2] = (rc >> 16) & 0xFF; ram[addr+3] = (rc >> 24) & 0xFF;
		}
		else // LDR Ld, [Ln, #immed*4]
		{
			if((addr & 0x40010000) == 0x40010000) //peripheral
			{
				if(peripheral_read(addr, (uint32_t*) rd) != 0) return 1;
			}
			else if((addr < 0x20000000)) //rom
			{
				cpu.reg[rd] = rom[addr] | (rom[addr+1] << 8) | (rom[addr+2] << 16) | (rom[addr+3] << 24);
				return 0;
			}
			addr -= 0x20000000;
			cpu.reg[rd] = ram[addr] | (ram[addr+1] << 8) | (ram[addr+2] << 16) | (ram[addr+3] << 24);			
		}
	}
	
	if((inst & 0xF600) == 0xB400) // PUSH | POP
	{
		uint8_t r = (inst >> 8) & 0x1;
		op = (inst >> 11) & 0x1;
		
		if(op == 0) //PUSH
		{	
			if(inst & 0x100) //lr
			{
				cpu.reg[13] -= 4; //make space
				sp = cpu.reg[13];
				sp -= 0x20000000;
				ram[sp] = cpu.reg[14] & 0xFF; ram[sp+1] = (cpu.reg[14] >> 8) & 0xFF; ram[sp+2] = (cpu.reg[14] >> 16) & 0xFF; ram[sp+3] = (cpu.reg[14] >> 24) & 0xFF; //store lr
			}
			if(inst & 0x80) //r7
			{
				cpu.reg[13] -= 4; //make space
				sp = cpu.reg[13];
				sp -= 0x20000000;
				ram[sp] = cpu.reg[7] & 0xFF; ram[sp+1] = (cpu.reg[7] >> 8) & 0xFF; ram[sp+2] = (cpu.reg[7] >> 16) & 0xFF; ram[sp+3] = (cpu.reg[7] >> 24) & 0xFF; //store r7
			}
			if(inst & 0x40) //r6
			{
				cpu.reg[13] -= 4; //make space
				sp = cpu.reg[13];
				sp -= 0x20000000;
				ram[sp] = cpu.reg[6] & 0xFF; ram[sp+1] = (cpu.reg[6] >> 8) & 0xFF; ram[sp+2] = (cpu.reg[6] >> 16) & 0xFF; ram[sp+3] = (cpu.reg[6] >> 24) & 0xFF; //store r6
			}
			if(inst & 0x20) //r5
			{
				cpu.reg[13] -= 4; //make space
				sp = cpu.reg[13];
				sp -= 0x20000000;
				ram[sp] = cpu.reg[5] & 0xFF; ram[sp+1] = (cpu.reg[5] >> 8) & 0xFF; ram[sp+2] = (cpu.reg[5] >> 16) & 0xFF; ram[sp+3] = (cpu.reg[5] >> 24) & 0xFF; //store r5
			}
			if(inst & 0x10) //r4
			{
				cpu.reg[13] -= 4; //make space
				sp = cpu.reg[13];
				sp -= 0x20000000;
				ram[sp] = cpu.reg[4] & 0xFF; ram[sp+1] = (cpu.reg[4] >> 8) & 0xFF; ram[sp+2] = (cpu.reg[4] >> 16) & 0xFF; ram[sp+3] = (cpu.reg[4] >> 24) & 0xFF; //store r4
			}
			if(inst & 0x8) //r3
			{
				cpu.reg[13] -= 4; //make space
				sp = cpu.reg[13];
				sp -= 0x20000000;
				ram[sp] = cpu.reg[3] & 0xFF; ram[sp+1] = (cpu.reg[3] >> 8) & 0xFF; ram[sp+2] = (cpu.reg[3] >> 16) & 0xFF; ram[sp+3] = (cpu.reg[3] >> 24) & 0xFF; //store r3
			}
			if(inst & 0x4) //r2
			{
				cpu.reg[13] -= 4; //make space
				sp = cpu.reg[13];
				sp -= 0x20000000;
				ram[sp] = cpu.reg[2] & 0xFF; ram[sp+1] = (cpu.reg[2] >> 8) & 0xFF; ram[sp+2] = (cpu.reg[2] >> 16) & 0xFF; ram[sp+3] = (cpu.reg[2] >> 24) & 0xFF; //store r2
			}
			if(inst & 0x2) //r1
			{
				cpu.reg[13] -= 4; //make space
				sp = cpu.reg[13];
				sp -= 0x20000000;
				ram[sp] = cpu.reg[1] & 0xFF; ram[sp+1] = (cpu.reg[1] >> 8) & 0xFF; ram[sp+2] = (cpu.reg[1] >> 16) & 0xFF; ram[sp+3] = (cpu.reg[1] >> 24) & 0xFF; //store r1 
			}
			if(inst & 0x1) //r0
			{
				cpu.reg[13] -= 4; //make space
				sp = cpu.reg[13];
				sp -= 0x20000000;
				ram[sp] = cpu.reg[0] & 0xFF; ram[sp+1] = (cpu.reg[0] >> 8) & 0xFF; ram[sp+2] = (cpu.reg[0] >> 16) & 0xFF; ram[sp+3] = (cpu.reg[0] >> 24) & 0xFF; //store r0 
			}
			return 0;
		}
		else //POP
		{	
			if(inst & 0x1) //r0
			{
				sp = cpu.reg[13];
				sp -= 0x20000000;
				cpu.reg[0] = ram[sp] | (ram[sp+1] << 8) | (ram[sp+2] << 16) | (ram[sp+3] << 24); //load r0 
				cpu.reg[13] += 4; //remove space
			}
			if(inst & 0x2) //r1
			{
				sp = cpu.reg[13];
				sp -= 0x20000000;
				cpu.reg[1] = ram[sp] | (ram[sp+1] << 8) | (ram[sp+2] << 16) | (ram[sp+3] << 24); //load r1 
				cpu.reg[13] += 4; //remove space	
			}
			
			if(inst & 0x4) //r2
			{
				sp = cpu.reg[13];
				sp -= 0x20000000;
				cpu.reg[2] = ram[sp] | (ram[sp+1] << 8) | (ram[sp+2] << 16) | (ram[sp+3] << 24); //load r2 
				cpu.reg[13] += 4; //remove space	
			}
			if(inst & 0x8) //r3
			{
				sp = cpu.reg[13];
				sp -= 0x20000000;
				cpu.reg[3] = ram[sp] | (ram[sp+1] << 8) | (ram[sp+2] << 16) | (ram[sp+3] << 24); //load r3
				cpu.reg[13] += 4; //remove space	
			}
			if(inst & 0x10) //r4
			{
				sp = cpu.reg[13];
				sp -= 0x20000000;
				cpu.reg[4] = ram[sp] | (ram[sp+1] << 8) | (ram[sp+2] << 16) | (ram[sp+3] << 24); //load r4
				cpu.reg[13] += 4; //remove space	
			}
			if(inst & 0x20) //r5
			{
				sp = cpu.reg[13];
				sp -= 0x20000000;
				cpu.reg[5] = ram[sp] | (ram[sp+1] << 8) | (ram[sp+2] << 16) | (ram[sp+3] << 24); //load r5
				cpu.reg[13] += 4; //remove space	
			}
			if(inst & 0x40) //r6
			{
				sp = cpu.reg[13];
				sp -= 0x20000000;
				cpu.reg[6] = ram[sp] | (ram[sp+1] << 8) | (ram[sp+2] << 16) | (ram[sp+3] << 24); //load r6
				cpu.reg[13] += 4; //remove space	
			}
			if(inst & 0x80) //r7
			{
				sp = cpu.reg[13];
				sp -= 0x20000000;
				cpu.reg[7] = ram[sp] | (ram[sp+1] << 8) | (ram[sp+2] << 16) | (ram[sp+3] << 24); //load r7
				cpu.reg[13] += 4; //remove space	
			}
			if(inst & 0x100) //lr, also branch
			{
				sp = cpu.reg[13];
				sp -= 0x20000000;
				cpu.reg[15] = ram[sp] | (ram[sp+1] << 8) | (ram[sp+2] << 16) | (ram[sp+3] << 24); //load pc
				cpu.reg[13] += 4; //remove space
			}
			return 0;
		}
	}
	   
    if((inst & 0xF000) == 0xD000) // B<cond> instruction_address+4+offset*2
	{
		imm = inst & 0xFF; op = (inst >> 8) & 0xF;
		int branch_flag = 0;
		
		if(imm & 0x0080) //sign extend the immediate
			imm |= 0xFFFFFF00;
			
		if(op == 0) // EQ
		{
			if((cpu.cpsr & 0x40000000) == 0x40000000)
				branch_flag = 1; //branch taken
		}
		else if(op == 1) // NE
		{
			if(!(cpu.cpsr & 0x40000000))
				branch_flag = 1; //branch taken
		}
		else if(op == 2) // CS or HS
		{
			if((cpu.cpsr & 0x20000000) == 0x20000000)
				branch_flag = 1; //branch taken
		}
		else if(op == 3) // CC or LO
		{
			if(!(cpu.cpsr & 0x20000000))
				branch_flag = 1; //branch taken
		}
		else if(op == 4) // MI
		{
			if((cpu.cpsr & 0x80000000) == 0x80000000)
				branch_flag = 1; //branch taken
		}
		else if(op == 5) // PL
		{
			if(!(cpu.cpsr & 0x80000000))
				branch_flag = 1; //branch taken
		}
		else if(op == 6) // VS
		{
			if((cpu.cpsr & 0x10000000) == 0x10000000)
				branch_flag = 1; //branch taken
		}			
		else if(op == 7) // VC
		{
			if(!(cpu.cpsr & 0x10000000))
				branch_flag = 1; //branch taken
		}
		else if(op == 8) // HI
		{
			if((cpu.cpsr & 0x60000000) == 0x20000000)
				branch_flag = 1; //branch taken
		}
		else if(op == 9) // LS
		{
			if((cpu.cpsr & 0x40000000) == 0x40000000 || (cpu.cpsr & 0x20000000) == 0x00000000 )
				branch_flag = 1; //branch taken
		}
		else if(op == 10) // GE
		{
			if((cpu.cpsr & 0x80000000) == (cpu.cpsr & 0x10000000))
				branch_flag = 1; //branch taken
		}
		else if(op == 11) // LT
		{
			if((cpu.cpsr & 0x80000000) != (cpu.cpsr & 0x10000000))
				branch_flag = 1; //branch taken
		}
		else if(op == 12) // GT
		{
			if(((cpu.cpsr & 0x80000000) == (cpu.cpsr & 0x10000000)) && !(cpu.cpsr & 0x40000000))
				branch_flag = 1; //branch taken
		}
		else if(op == 13) // LE
		{
			if(((cpu.cpsr & 0x80000000) != (cpu.cpsr & 0x10000000)) || (cpu.cpsr & 0x40000000))
				branch_flag = 1; //branch taken
		}
		if(branch_flag)
		{
			//take the branch
			cpu.reg[15] = cpu.reg[15] + 2 + 2*imm;
			return 0;			
		}
		return 0;
	}
	 
	if((inst & 0xF800) == 0xE000) // B instruction_address+4+offset*2 
	{
		imm = inst & 0x7FF;
		if(imm & 0x0400) //sign extend the immediate
			imm |= 0xFFFFF800;
			
		//take the branch
		cpu.reg[15] = cpu.reg[15] + 2 + 2*imm;
		return 0;
	}

	if((inst & 0xF800) == 0xF000) // BL | BLX prefix
	{
		poff = inst & 0x7FF;
		if(poff & 0x0400) //sign extend the immediate
			poff |= 0xFFFFF800;
			
		return 0;
	}
	
	if((inst & 0xF800) == 0xF800) // BL instruction+4+(poff<<12)+offset*2
	{
		uint32_t offset = inst & 0x7FF;
		
		cpu.reg[14] = pc; // save pc to lr
		//take the branch
		cpu.reg[15] = cpu.reg[15] + (poff << 12) + 2*offset;
		
		return 0;
	}
	
	if((inst & 0xFF00) == 0xBE00) // BKPT immed8 (debug purposes)
	{
		imm = inst & 0xFF;
		if(imm == 0) //indicates the end of animation.
		{
			printf("%ld thumb instructions executed. \n", count);
			return 1;
		}
		else if(imm == 1)
		{
			//debug
		}
		else if(imm == 2)
		{
			//debug
		}
		//more options can be added
		return 0;
	}
	
	fprintf(stderr, "invalid instruction 0x%08X 0x%04X\n", pc - 4, inst);
	return 1;
}

//Resets the CPU and initializes the registers
int32_t reset(void)
{
	memset(ram, 0xFF, sizeof(ram));

	cpu.cpsr = 0;

	cpu.reg[14] = 0xFFFFFFFF;
	//First 4 bytes in ROM specifies initializes the stack pointer
	cpu.reg[13] = rom[0] | rom[1] << 8 | rom[2] << 16 | rom[3] << 24;
	//Following 4 bytes in ROM initializes the PC
	cpu.reg[15] = rom[4] | rom[5] << 8 | rom[6] << 16 | rom[7] << 24;
	cpu.reg[15] += 2;
	return 0;
}

//Emulator loop
int32_t run(void)
{
	reset();
	while (1)
	{
		if (execute())
		{	
			break;
		}
	}
	return 0;
}

//Emulator main function
int32_t main(int32_t argc, char* argv[])
{
	if (argc < 2)
	{
		fprintf(stderr, "input assembly file not specified\n");
		return(1);
	}

	memset(rom, 0xFF, sizeof(rom));

	system_init();

	if (load_program(argv[1], rom) < 0)
	{
		return(1);
	}

	memset(ram, 0x00, sizeof(ram));
	run();

	printf("Animation is over. Press enter to exit.\n");
	char btn;
	scanf("%c",&btn);
	system_deinit();
	return 0;
}
