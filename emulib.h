#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>

/*
   Loads and assembles the source file into given ROM memory 
   path: Path to ARM assembly file
   rom: Pointer to rom that will be populated with assembled file contents
   
   Return: code size if successful, -1 if there is an error
      On return with success, the function returns 0 and memory pointed by rom 
	  is filled with assembled file contents
*/
int32_t load_program(char *path, uint8_t *rom);

/* Initializes the system
   Return: 0 if successful, -1 if there is an error
*/
int32_t system_init();

/* De-initializes the system */
void system_deinit();

/*
   Writes to peripheral register at the given memory-mapped address
   addr: Address to write to
   value: Value to write   
   
   Return: 0 if successful, -1 if there is an error
*/
int32_t peripheral_write(uint32_t addr, uint32_t value);

/*
   Reads from peripheral register at the given memory-mapped address
   addr: Address to read from
   value: Read value is written here   
   
   Return: 0 if successful, -1 if there is an error
*/
int32_t peripheral_read(uint32_t addr, uint32_t *value);

/*
   Enables/disables system debug logs
   enable: If 1, debug logs enabled. If 0, debug logs disabled
*/
void set_debug(int32_t enable);