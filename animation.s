//Space Impact game animation
//written by Yavuz Selim Tozlu
//*************************************
//LINK TO THE PRESENTATION VIDEO BELOW*
//*************************************
//https://www.youtube.com/watch?v=wr3MxqReJxc
//**************************************************************************************************************

//loads registers with arguments, then stores them in the memory region
//r=row coordinate, m=movement data, nth = nth enemy object, f=insert or remove
//f=0 insert, f=1 remove. there is no column data because enemies always enter from the right side of screen.
.macro ins_rm_enemy r, m, nth, f // nth = 0-9 type1, 10-19 type-2, m = 0-127 moves up, 128-255 moves down
	//calculate actual memory address from "nth"
	mov		r3, #12
	mov		r4, #12
	mov		r5, #\nth
	mul		r4, r5
	add		r3, r4
	push	{r4}
	mov		r4, r9
	
	//calculate actual movement data value from "m"
	.if \m < 0 //move up
		.equ sym, -\m
		mov		r2, #0
		sub		r2, #sym
	.else //move down
		mov		r2, #\m
	.endif
	
	//calculate column coordinate value depending on the type of enemy.
	//also insert or remove depending on "f"
	mov		r1, #255
	.if \nth > 9 //type 2
		add		r1, #80 //r1=335
		.if \f == 0
			mov		r0, #\r
		.else
			ldr		r0, [r4,r3]
			add		r4, #4
			ldr		r1, [r4,r3]
			mov		r7, r11
			bl		p_en2
			mov		r0, #0
			mov		r2, #0
			pop		{r4}
		.endif
		
	.else //type 1
		add		r1, #71 //r1=326
		.if \f == 0
			mov		r0, #\r
		.else
			ldr		r0, [r4,r3]
			add		r4, #4
			ldr		r1, [r4,r3]
			mov		r7, r11
			bl		p_en1
			mov		r0, #0
			mov		r2, #0
			pop		{r4}
		.endif
	.endif

	bl		str_obj
.endm

//moves "nth" enemy object by "m" amount.
.macro move_enemy nth, m
	//calculate actual memory address from "nth"
	mov		r3, #12
	mov		r4, #12
	mov		r5, #\nth
	mul		r4, r5
	add		r3, r4
	
	//calculate actual movement data value from "m"
	.if \m < 0 //move up
		.equ sym, -\m
		mov		r2, #0
		sub		r2, #sym
	.else //move down
		mov		r2, #\m
	.endif
	
	add		r3, r9
	str		r2, [r3, #8]
.endm

//inserts or removes bullet data from memory
.macro ins_rm_bullet nth, f //f=0 for insert, f=1 for remove
	//calculate actual address from "nth"
	mov		r3, #252
	mov		r4, #8
	push	{r5}
	mov		r5, #\nth
	mul		r4, r5
	pop		{r5}
	add		r3, r4
	//insert or remove depending of "f"
	.if \f == 0
		bl		insert_bullet
	.else
		bl		remove_bullet
	.endif
.endm

//stores ship movement data in memory. m=step amount s=step size. step size is passed as a parameter in r6
.macro move_ship_up m, s
	mov		r6, #\s
	mov		r2, #0
	sub		r2, #\m
	mov		r3, #0
	add		r3, r9
	str		r2, [r3, #8]
.endm

//similar to above
.macro move_ship_down m, s 
	mov		r6, #\s
	mov		r2, #\m
	mov		r3, #0
	add		r3, r9
	str		r2, [r3, #8]
.endm

//spawns boss by introducing him from the right side of screen. 
.macro spawn_boss 
	//initial coordinates r=90, c=376
	mov		r0, #90
	mov		r1, #255
	add		r1, #116
	//move left by 28 steps
	mov		r2, #0
	sub		r2, #28
	//store boss data in memory
	mov		r3, #12
	add		r3, r9
	str		r0, [r3]
	str		r1, [r3, #4]
	str		r2, [r3, #8]
	//initial boss step size
	mov		r5, #5
.endm

//removes boss from screen. used at the end of animation.
.macro kill_boss
	//load boss coordinates
	mov		r3, #12
	add		r3, r9
	ldr		r0, [r3]
	ldr		r1, [r3, #4]
	//flash boss, then remove him
	mov		r7, r11
	bl		p_boss
	push	{r0,r1} //form delay loop arguments (14x delay duration)
	mov		r0, #0
	mov		r1, r9 //r1=0x20000000
	lsr		r1, #5 //r1=0x01000000
	bl		delay
	mov		r7, r12
	bl		p_boss
	push	{r0,r1} //form delay loop arguments (14x delay duration)
	mov		r0, #0
	mov		r1, r9 //r1=0x20000000
	lsr		r1, #5 //r1=0x01000000
	bl		delay
	mov		r7, r11
	bl		p_boss
.endm

//boss movement macros. m=step amount, s=step size
//odd numbered movement data means vertical movement. negative sign means move up. positive sign means move down
//even numbered movement data means horizontal movement. negative sign means move left. positive sign means move right
//calculates appropriate movement data, then stores it in memory.
.macro move_boss_up m, s
	.equ sym, (2*\m)+1
	mov		r2, #0
	sub		r2, #sym
	mov		r3, #12
	add		r3, r9
	str		r2, [r3, #8]
	mov		r5, #\s
.endm
.macro move_boss_down m, s
	.equ sym, (2*\m)+1
	mov		r2, #sym
	mov		r3, #12
	add		r3, r9
	str		r2, [r3, #8]
	mov		r5, #\s
.endm
.macro move_boss_right m, s
	.equ sym, (2*\m)
	mov		r2, #sym
	mov		r3, #12
	add		r3, r9
	str		r2, [r3, #8]
	mov		r5, #\s
.endm
.macro move_boss_left m, s
	.equ sym, (2*\m)
	mov		r2, #0
	sub		r2, #sym
	mov		r3, #12
	add		r3, r9
	str		r2, [r3, #8]
	mov		r5, #\s
.endm

//similar to ins_rm_bullet
.macro ins_rm_boss_bullet nth, f
	mov		r3, #24
	mov		r4, #8
	mov		r2, #\nth
	mul		r2, r4
	add		r3, r2
	.if \f == 0
		bl	insert_boss_bullet
	.else
		bl	remove_bullet
	.endif
.endm

//executes movement data. r4 holds the number of iterations on memory.
//for instance, r4=3 means memory region is iterated through 3 times.
.macro do_move a
	mov		r4, #\a
	bl		mv_obj
.endm

initial_sp:	.word	0x20010000
reset_vector: .word _main
_main:	bl		load_constants
		mov		r9, r4  //r9 is reserved for ram offset value
		mov		r10, r5 //r10 is reserved for LCD row register
		mov		r11, r6 //r11 is reserved for background color
		mov		r12, r7 //r12 is reserved for black color
				
		//paint background
		mov		r7, r11
		mov		r6, #0
		mov		r0, #0 
		mov		r1, #0
		mov		r2, #240
		mov		r3, #255
		add		r3, #65 //r3=320
		
		bl 		p_rect
		
		//set memory to zeros. this is needed for proper movement operation, because the memory
		//is initialized to 0xFF at reset
		mov		r0, #0
		add		r0, r9
		mov		r1, #0
		mov		r3, #255
		add		r3, #157 //r3=412
		add		r3, r9
int_l:	cmp		r0, r3 //set memory to 0
		beq		start
		str		r1, [r0]
		add		r0, #4
		b		int_l


		
		//start animation. store spaceship data on memory.
start:	mov		r3, #0
		mov		r0, #110
		mov		r1, #15
		mov		r2, #1
		add		r3, r9
		str		r0, [r3]
		str		r1, [r3, #4]
		str		r2, [r3, #8]
		
		
		//rest of the main code is animation. there are no comments from now on until the end of main.
		//animation is just inserting, removing or moving objects. so there is nothing to comment about
		
		
		//scene 1----------------------------------------------------------------
		
		ins_rm_enemy 30, 0, 0, 0
		ins_rm_enemy 70, 0, 1, 0
		ins_rm_enemy 150, 0, 2, 0
		ins_rm_enemy 200, 0, 3, 0	
		//bkpt #1
		do_move 13
		
		ins_rm_enemy 50, 0, 10, 0
		ins_rm_enemy 110, 0, 11, 0
		ins_rm_enemy 175, 0, 12, 0
		
		move_ship_up 9, 10
		do_move 9
		
		ins_rm_bullet 0,0
		move_ship_down 2, 9
		do_move 2
		
		ins_rm_bullet 1, 0
		move_ship_down 3, 9
		do_move 3
		
		ins_rm_bullet 2, 0
		move_ship_down 4, 9
		do_move 4
		
		ins_rm_bullet 3, 0
		move_ship_down 4, 9
		do_move 4
		
		ins_rm_bullet 4, 0
		do_move 16
		ins_rm_bullet 0, 1
		ins_rm_enemy 0, 0, 0, 1
		do_move 3
		
		ins_rm_bullet 2, 1
		ins_rm_enemy 0, 0, 1, 1
		do_move 2
		
		move_ship_down 3, 9
		do_move 1
		
		ins_rm_bullet 4, 1
		ins_rm_enemy 0, 0, 2, 1
		do_move 2
		
		ins_rm_bullet 1, 1
		ins_rm_enemy 0, 0, 10, 1
		ins_rm_bullet 0, 0
		move_ship_down 3, 9
		do_move 3
		
		ins_rm_bullet 1, 0
		ins_rm_bullet 3, 1
		ins_rm_enemy 0, 0, 11, 1
		do_move	8
		
		ins_rm_bullet 1, 1
		ins_rm_enemy 0, 0, 3, 1
		do_move 6
		
		ins_rm_bullet 0, 1
		ins_rm_enemy 0, 0, 12, 1
		
		move_ship_up 10, 9
		do_move 10
		
		move_ship_down 5, 9
		do_move 5
		
		move_ship_up 7, 9
		do_move 15
		
		//scene 2----------------------------------------------------------------
		ins_rm_enemy 50, -10, 0, 0
		do_move	10
		
		ins_rm_enemy 80, -10, 1, 0
		move_enemy 0, 20
		do_move	8
		
		move_enemy 1, 20
		move_enemy 0, -10
		move_ship_up 12, 6
		do_move 12
		
		ins_rm_bullet 0, 0
		do_move 5
		
		ins_rm_bullet 1, 0
		do_move 4
		
		ins_rm_bullet 2, 0
		do_move 4
		
		move_ship_down 10, 10
		do_move	10
		
		ins_rm_bullet 3, 0
		do_move 2
		
		ins_rm_enemy 110, -10, 10, 0
		do_move 1
		
		ins_rm_bullet 0, 1
		ins_rm_enemy 0,0,0,1
		do_move 15
		
		ins_rm_bullet 3,1
		ins_rm_enemy 0,0,1,1
		ins_rm_enemy 170, -20, 11, 0
		do_move 4
		
		move_enemy 10, 15
		do_move 10
		
		move_enemy 10, 10
		move_enemy 11, -10
		ins_rm_enemy 45, 10, 0, 0	
		ins_rm_bullet 0,0
		do_move 4
		
		ins_rm_bullet 3,0
		do_move 6
		
		move_enemy 10, 10
		move_enemy 11, -10
		move_enemy 0, 20
		move_ship_up 3, 4
		do_move 3
		
		ins_rm_bullet 4, 0
		move_ship_up 2, 4
		do_move 2
		
		ins_rm_bullet 5,0
		do_move 7
		
		move_enemy 10, -24
		move_enemy 11, 20
		do_move 10
		
		ins_rm_enemy 60, 0, 12, 0
		do_move 4
		
		ins_rm_bullet 6,0
		ins_rm_bullet 0,1
		ins_rm_enemy 0,0,11,1
		move_ship_down 6,7
		do_move 7
		
		ins_rm_enemy 0,0,10,1
		ins_rm_bullet 6,1
		ins_rm_bullet 1,0
		do_move 7
		
		move_ship_up 7,11
		do_move 6
		
		ins_rm_bullet 6,0
		do_move 2
		
		ins_rm_bullet 0,0
		do_move 4
		
		ins_rm_enemy 0,0,0,1
		ins_rm_bullet 1,1
		do_move 10
		
		move_ship_down 7,5
		do_move 13
		
		ins_rm_bullet 0,1
		ins_rm_enemy 0,0,12,1
		move_ship_down 19,1
		do_move 60
		
		
		//scene 3----------------------------------------------------------------
		ins_rm_enemy 10,0,0,0
		ins_rm_enemy 40,0,1,0
		ins_rm_enemy 70,0,2,0
		ins_rm_enemy 100,0,3,0
		ins_rm_enemy 130,0,4,0
		ins_rm_enemy 160,0,5,0
		ins_rm_enemy 190,0,6,0
		ins_rm_enemy 220,0,7,0
		do_move	10
		
		ins_rm_enemy 10,0,10,0
		ins_rm_enemy 40,0,11,0
		ins_rm_enemy 70,0,12,0
		ins_rm_enemy 100,0,13,0
		ins_rm_enemy 130,0,14,0
		ins_rm_enemy 160,0,15,0
		ins_rm_enemy 190,0,16,0
		ins_rm_enemy 220,0,17,0
		do_move	1
		
		move_ship_up 27,4
		ins_rm_bullet 0,0
		do_move 3
		
		ins_rm_bullet 1,0
		do_move 3
		
		ins_rm_bullet 2,0
		do_move 3
		
		ins_rm_bullet 3,0
		do_move 3
		
		ins_rm_bullet 4,0
		do_move 3
		
		ins_rm_bullet 5,0
		do_move 3
		
		ins_rm_bullet 6,0
		do_move 3
		
		ins_rm_bullet 7,0
		do_move 3
		
		ins_rm_bullet 8,0
		do_move 3
		
		ins_rm_bullet 9,0
		do_move 4
		
		ins_rm_bullet 10,0
		move_ship_down 60,5
		do_move 3
		
		ins_rm_bullet 11,0
		do_move 2
		
		ins_rm_enemy 0,0,4,1
		ins_rm_bullet 0,1
		do_move 1
		
		ins_rm_enemy 0,0,3,1
		ins_rm_bullet 1,1		
		do_move 2
		
		ins_rm_bullet 12,0
		do_move 1
		
		ins_rm_enemy 0,0,2,1
		ins_rm_bullet 4,1
		do_move 2
		
		ins_rm_bullet 13,0
		move_ship_down 16,9
		do_move 1
		
		ins_rm_enemy 0,0,13,1
		ins_rm_bullet 2,1
		do_move 1
		
		ins_rm_enemy 0,0,1,1
		ins_rm_bullet 6,1
		do_move 4
		
		ins_rm_enemy 0,0,0,1
		ins_rm_bullet 9,1
		do_move 1
		
		ins_rm_bullet 14,0
		do_move 1
		
		ins_rm_enemy 0,0,11,1
		ins_rm_bullet 7,1
		do_move 2
		
		ins_rm_bullet 15,0
		do_move 1
		
		ins_rm_bullet 16,0
		do_move 2
		
		ins_rm_enemy 0,0,10,1
		ins_rm_bullet 10,1
		do_move 5
		
		move_ship_down 1,4
		do_move 1
		
		ins_rm_enemy 0,0,5,1
		ins_rm_bullet 15,1
		ins_rm_enemy 0,0,12,1
		ins_rm_bullet 13,1
		do_move 1
		
		move_ship_up 3,6
		ins_rm_bullet 18,0
		do_move 3
		
		ins_rm_bullet 19,0
		ins_rm_enemy 0,0,14,1
		ins_rm_bullet 14,1
		do_move 1
		
		ins_rm_bullet 18,1
		ins_rm_enemy 0,0,7,1
		move_ship_down 3,6
		ins_rm_bullet 18,0
		do_move 1
		
		ins_rm_enemy 0,0,15,1
		ins_rm_bullet 18,1
		do_move 1
		
		ins_rm_enemy 0,0,6,1
		ins_rm_bullet 19,1
		do_move 1
		
		ins_rm_bullet 18,0
		move_ship_up 3,6
		do_move 3
		
		ins_rm_bullet 19,0
		do_move 3
		
		ins_rm_bullet 18,1
		ins_rm_enemy 0,0,17,1
		do_move 2
		
		ins_rm_bullet 19,1
		ins_rm_enemy 0,0,16,1
		move_ship_up 15, 6
		do_move 15
		move_ship_down 2,6
		do_move 3
		move_ship_down 1,1 
		do_move 70
		
		//scene 4 (boss scene)----------------------------------------------------------------
		spawn_boss
		//switch to memory mode 1
		mov		r0, #1
		mov		r8, r0
		do_move 40

		ins_rm_boss_bullet 0,0
		do_move 4
		
		ins_rm_boss_bullet 1,0
		do_move 15
		
		move_ship_down 1,4
		do_move 1
		
		ins_rm_bullet 0,0
		do_move 4
		
		ins_rm_bullet 1,0
		do_move 4
		
		ins_rm_bullet 2,0
		do_move 4
		
		ins_rm_bullet 3,0
		do_move 4
		
		ins_rm_boss_bullet 0,1
		ins_rm_bullet 0,1
		do_move 4
		
		ins_rm_boss_bullet 1,1
		ins_rm_bullet 1,1
		do_move 42
		
		ins_rm_bullet 2,1
		do_move 4
		ins_rm_bullet 3,1
		move_boss_up 10,7
		do_move 3
		
		move_ship_up 10,6
		do_move 4
		
		ins_rm_bullet 0,0
		do_move 6
		
		ins_rm_bullet 1,0
		move_boss_down 13,7
		do_move 5
		
		move_ship_down 10,7
		do_move 10
		
		move_boss_left 20,10
		do_move 10
		
		move_ship_up 9,6
		do_move 14
		
		move_boss_right 35,6
		do_move 10
		
		move_ship_down 7,7
		do_move 7
		
		ins_rm_bullet 2,0
		do_move 4
		
		ins_rm_bullet 3,0
		do_move 54
		
		ins_rm_bullet 2,1
		do_move 4
		
		ins_rm_bullet 3,1
		do_move 4
		
		move_boss_up 20,5
		ins_rm_boss_bullet 0,0
		do_move 3
		
		ins_rm_boss_bullet 1,0
		do_move 3
		
		move_ship_up 15,5
		ins_rm_boss_bullet 2,0
		do_move 3
		
		ins_rm_bullet 0,0
		do_move 3
		ins_rm_boss_bullet 3,0
		do_move 1
		ins_rm_bullet 1,0
		do_move 8
		
		ins_rm_bullet 2,0
		do_move 3
		
		move_boss_left 22,10
		do_move 7
		
		ins_rm_bullet 3,0
		move_ship_down 21,7
		do_move 5
		
		ins_rm_bullet 0,1
		ins_rm_boss_bullet 2,1
		do_move 1
		
		ins_rm_bullet 2,1
		do_move 2
		ins_rm_bullet 3,1
		do_move 11
		
		move_boss_right 31,7
		do_move 31
		
		move_ship_up 23,4
		do_move 5
		move_boss_down 15,5
		do_move 15
		
		ins_rm_bullet 0,0
		do_move 4
		ins_rm_bullet 1,0
		do_move 4
		move_ship_down 2,3
		do_move 2
		ins_rm_bullet 2,0
		ins_rm_boss_bullet 0,0
		move_ship_up 2,3
		do_move 4
		ins_rm_bullet 3,0
		ins_rm_boss_bullet 1,0
		do_move 5
		
		ins_rm_bullet 4,0
		do_move 4
		ins_rm_bullet 5,0
		do_move 4
		ins_rm_bullet 6,0
		do_move 4
		move_ship_down 3,3
		do_move 2
		ins_rm_bullet 0,1
		ins_rm_boss_bullet 0,1
		do_move 2
		ins_rm_bullet 7,0
		do_move 5
		ins_rm_bullet 2,1
		ins_rm_boss_bullet 1,1
		do_move 20
		ins_rm_bullet 1,1
		do_move 11
		ins_rm_bullet 3,1
		do_move 5
		ins_rm_bullet 4,1
		do_move 5
		ins_rm_bullet 5,1
		do_move 4
		ins_rm_bullet 6,1
		do_move 8
		ins_rm_bullet 7,1
		do_move 3
		
		kill_boss
		
		bkpt 	#0
//end:	b		end		

//inserts new spaceship bullet data. bullets are spawned at the tip of the spaceship, and are moved horizontally.
//inputs r0=row coordinate, r1=column coordinate, r3=memory address
insert_bullet:
		push	{r3}
		//load spaceship coordinates
		mov		r3, #0
		add		r3, r9
		ldr		r0, [r3]
		ldr		r1, [r3, #4]
		//move to the tip
		add		r1, #50
		add		r0, #15
		//store coordinates into given bullet memory region
		pop		{r3}
		add		r3, r9
		str		r0, [r3]
		str		r1, [r3, #4]
		bx		lr
		
//removes a bullet from the memory region. first loads the bullet coordinates, then erases it from the screen.
//then removes its data from the memory region.
remove_bullet:
		push	{lr}
		mov		r4, r3
		add		r3, r9
		//load bullet coordinates
		ldr		r0, [r3]
		ldr		r1, [r3, #4]
		//erase it from screen
		mov		r2, #5
		mov		r3, #10
		mov		r7, r11
		bl		p_rect
		//erase its data from memory
		mov		r0, #0
		add		r4, r9
		str		r0, [r4]
		str		r0, [r4, #4]
		pop		{pc}
		
//inserts a bullet at the mouth of the boss, similar to "insert_bullet"
insert_boss_bullet:
		push	{r3}
		//load boss location
		mov		r3, #12
		add		r3, r9
		ldr		r0, [r3]
		ldr		r1, [r3, #4]
		//move to the mouth
		sub		r1, #70
		add		r0, #39
		//store coordinates into given bullet memory region
		pop		{r3}
		add		r3, r9
		str		r0, [r3]
		str		r1, [r3, #4]
		bx		lr
		
//delay function.
delay:	add		r0, #1
		cmp		r1, r0
		bcs		delay
		pop		{r0,r1}
		bx		lr
//-------------------------end------------------------------------------------------------

		
//move object function. step size=3 for enemies and bullets. r6 holds the step size for the ship.
//r5 holds the step size for the boss.
//iterates through the memory region. loads objects, then checks if they need to be moved.
//memory regions are explained in the video presentation.
mv_obj: push	{lr}
load_ship:
//bkpt	#2
		push	{r0,r1}
		mov		r0, #0 //form delay loop arguments
		mov		r1, r9 //r1=0x20000000
		lsr		r1, #9 //r1=0x00100000
		bl		delay
		cmp		r4, #0 //check if we completed moving all objects
		beq		done_mv
		sub		r4, #1
		mov		r3, #0
		push	{r4}
		mov		r4, r9
		ldr		r0, [r4,r3] //spaceship data
		add		r4, #4
		ldr		r1, [r4, r3]
		add		r4, #4
		ldr		r2, [r4, r3]
		pop		{r4}
//bkpt	#2
		cmp		r2, #0
		beq		load_next_enemy  //spaceship is not moving
		bgt		mv_ship_down  //move spaceship down
		blt		mv_ship_up	 //move spaceship up
		
//move spaceship up
mv_ship_up:
		mov		r7, r11 
		bl		p_ship
		sub		r0, r6
		add		r2, #1 //decrement move count
		mov		r7, r12
		bl		p_ship
		bl		str_obj
		b		load_next_enemy
		
//move spaceship down		
mv_ship_down:
		mov		r7, r11 
		bl		p_ship
		add		r0, r6
		sub		r2, #1 //decrement move count
		mov		r7, r12
		bl		p_ship
		bl		str_obj
		b		load_next_enemy
		
//check the type of memory operation. r8=0 means mode 0, r8=1 means mode 1.
load_next_enemy: //bkpt #3
		mov		r0, r8
		cmp		r0, #0
		beq		load_enemy1
		b		load_boss

//loads boss data from memory and executes movement if necessary.
load_boss: 
		push	{r4}
		mov		r4, r9
		add		r4, #8
		add		r3, #12
		ldr		r2, [r4,r3] //load boss movement data
		pop		{r4}
		cmp		r2, #0 //check if boss is moving
		beq		load_boss_bullet_ //boss is not moving, load bullets
		cmp		r2, #1 //check if r2 is 1
		beq		load_boss_bullet_ //boss is not moving, load bullets
		mov		r0, #1
		cmn		r2, r0 //check if r2 is -1
		beq		load_boss_bullet_ //boss is not moving, load bullets
		
		//boss is moving, load its data
		push	{r4}
		mov		r4, r9
		ldr		r0, [r4,r3] //row data
		add		r4, #4
		ldr		r1, [r4,r3] //column data
		pop		{r4}
		
		//erase boss
		mov		r7, r11 //background color
		bl		p_boss
		mov		r7, r12 //black color
		
		//check if boss is moving vertically or horizontally. if r2 is even move horizontally
		//if r2 is odd, move vertically
		push	{r5}
		mov		r5, #1
		and		r5, r2
		cmp		r5, #0
		pop		{r5}
		beq		move_boss_horizontally //r2 is even
		b		move_boss_vertically //r2 is odd
		
move_boss_horizontally:
		//determine the direction of movement. if r2 is negative, move left. if r2 is positive move right
		cmp		r2, #0
		blt		move_boss_left //r2 is negative, move left
		b		move_boss_right //r2 is positive, move right
		
move_boss_vertically:
		//determine the direction of movement. if r2 is negative, move up. if r2 is positive move down
		cmp		r2, #0
		blt		move_boss_up //r2 is negative, move up
		b		move_boss_down //r2 is positive, move down		

move_boss_left:
		sub		r1, r5 //decrement column
		bl		p_boss
		add		r2, #2 //decrement move count
		b		str_boss
		
move_boss_right:
		add		r1, r5 //increment column
		bl		p_boss
		sub		r2, #2 //decrement move count
		b		str_boss
		
move_boss_up:
		sub		r0, r5 //decrement row
		bl		p_boss
		add		r2, #2 //decrement move count
		b		str_boss
		
move_boss_down:
		add		r0, r5 //increment row
		bl		p_boss
		sub		r2, #2 //decrement move count
		b		str_boss
		
done_mv:b	done_mv_

//stores boss data in its memory region
str_boss:
		push	{r4}
		mov		r4, r9
		str		r0, [r4,r3]
		add		r4, #4
		str		r1, [r4,r3]
		add		r4, #4
		str		r2, [r4,r3]
		pop		{r4}
		b		load_boss_bullet_

load_boss_bullet_:
		add		r3, #12
load_boss_bullet: 
		cmp		r3, #248 //check if reached the end of boss bullet region
		beq		load_bullet__
		push	{r4}
		mov		r4, r9
		ldr		r0, [r4,r3] //load bullet data
		pop		{r4}
		cmp		r0, #0 //check if bullet exists
		bne		move_boss_bullet //bullet exists
		add		r3, #8
		b		load_boss_bullet
		
	
move_boss_bullet:
		push	{r4}
		mov		r4, r9
		add		r4, #4
		ldr		r1, [r4, r3]
		pop		{r4}
		cmp		r1, #3 //check if the bullet is out of bounds
		blt		remove_boss_bullet_bounds
		//erase bullet
		mov		r7, r11
		bl		p_bllt
		sub		r1, #3 //decrement column
		//paint bullet
		mov		r7, r12
		bl		p_bllt
		//store bullet data
		push	{r4}
		mov		r4, r9
		str		r0, [r4,r3]
		add		r4, #4
		str		r1, [r4,r3]
		pop		{r4}
		add		r3, #8
		b		load_boss_bullet
		
//intermediate points for very long branches.
load_ship_: b	load_ship
load_bullet__: b load_bullet_	
		
//this function is called when a boss bullet needs to be removed upon reaching the end of the screen.
remove_boss_bullet_bounds:
		push 	{r4,r5}
		mov		r4, r3
		mov		r2, #5
		mov		r3, #10
		mov		r7, r11
		bl		p_rect
		mov		r0, #0
		mov		r5, r9
		str		r0, [r4,r5]
		add		r5, #4
		str		r0, [r4, r5]
		mov		r3, r4
		add		r3, #8
		pop		{r4,r5}
		b		load_boss_bullet
		
//loads enemy type 1 data from its reserved memory region. if row coordinate of the loaded enemy is 0
//then no enemy exists. else, enemy exists and is moved if necessary.
//positive movement data means moving down, negative means moving up.
//upon reaching the end of the reserved memory region, branches to loading enemy type 2.
load_enemy1: 

		add		r3, #12
		cmp		r3, #132 //check if we reached the end of type 1 enemy memory region
		beq		load_enemy2 //load type 2 enemy
		push	{r4}
		//bkpt #2
		mov		r4, r9
		ldr		r0, [r4,r3] //enemy data
		add		r4, #4
		ldr		r1, [r4,r3]
		add		r4, #4
		ldr		r2, [r4,r3]
		pop		{r4}
		//bkpt #2
		cmp		r0, #0
		bne		mv_enemy1 //enemy exists
		b		load_enemy1 //load next enemy

mv_enemy1:
		mov		r7, r11 //erase enemy
		bl		p_en1
		sub		r1, #3 //enemies constantly move horizontally.
		cmp		r2, #0 //check if there is vertical movement
		beq		mv_enemy1_horiz
		bgt		mv_enemy1_down
		blt		mv_enemy1_up
		
mv_enemy1_up:
		sub		r0, #3 //move enemy up
		add		r2, #1 //decrement move count
		mov		r7, r12
		bl		p_en1
		bl		str_obj
		b		load_enemy1
		
mv_enemy1_down:
		add		r0, #3 //move enemy down
		sub		r2, #1 //decrement move count
		mov		r7, r12
		bl		p_en1
		bl		str_obj
		b		load_enemy1
		
mv_enemy1_horiz:	
		mov		r7, r12
		bl		p_en1
		bl		str_obj
		b		load_enemy1
		
		
//loads enemy type 2 data from its reserved memory region. if row coordinate of the loaded enemy is 0
//then no enemy exists. else, enemy exists and is moved if necessary.
//positive movement data means moving down, negative means moving up.
//upon reaching the end of the reserved memory region, branches to loading bullets.
load_enemy2: 
		cmp		r3, #252 //check if we reached the end of type 2 enemy memory region
		beq		load_bullet //load bullets
		push	{r4}
		mov		r4, r9
		ldr		r0, [r4,r3] //enemy data
		add		r4, #4
		ldr		r1, [r4,r3]
		add		r4, #4
		ldr		r2, [r4,r3]
		pop		{r4}
		cmp		r0, #0
		bne		mv_enemy2 //enemy exists
		add		r3, #12
		b		load_enemy2 //load next enemy

mv_enemy2:
		mov		r7, r11 //erase enemy
		bl		p_en2
		sub		r1, #3 //enemies constantly move horizontally.
		cmp		r2, #0 //check if there is vertical movement
		beq		mv_enemy2_horiz
		bgt		mv_enemy2_down
		blt		mv_enemy2_up
		
mv_enemy2_up:
		sub		r0, #3 //move enemy up
		add		r2, #1 //decrement move count
		mov		r7, r12
		bl		p_en2
		bl		str_obj
		add		r3, #12
		b		load_enemy2
		
mv_enemy2_down:
		add		r0, #3 //move enemy down
		sub		r2, #1 //decrement move count
		mov		r7, r12
		bl		p_en2
		bl		str_obj
		add		r3, #12
		b		load_enemy2
		
mv_enemy2_horiz:	
		mov		r7, r12
		bl		p_en2
		bl		str_obj
		add		r3, #12
		b		load_enemy2
		
//loads bullet data from the reserved memory region. calls mv_bullet if there exists a bullet. if row coordinate
//of a bullet is 0, then no bullet exists. else, bullet exists and it is moved. upon reaching the end of the
//memory region, returns to loading ship data.
load_bullet_:
		add		r3, #4
load_bullet:
		push	{r5}
		mov		r5, #255
		add		r5, #157 //r5=412
		cmp		r3, r5 //check if we reached the end of bullet memory region
		pop		{r5}
		beq		load_ship_
		push	{r4}
		mov		r4, r9
		ldr		r0, [r4,r3] //bullet data
		add		r4, #4
		ldr		r1, [r4,r3]
		pop		{r4}
		cmp		r0, #0
		bne		mv_bullet	//bullet exists
		add		r3, #8
		b		load_bullet
		
//moves the bullet horizontally by 3 columns. checks if the bullet is out of bounds at the beginning.
//removes if it is out of bounds.
mv_bullet:
		mov		r2, #255
		add		r2, #52
		cmp		r1, r2
		bcs		remove_bullet_
		mov		r7, r11
		bl		p_bllt
		add		r1, #3 //increment column
		mov		r7, r12
		bl		p_bllt
		push	{r4}
		mov		r4, r9
		str		r0, [r4,r3]
		add		r4, #4
		str		r1, [r4,r3]
		pop		{r4}
		add		r3, #8
		b		load_bullet

//erases the bullet from screen. also removes its data from memory. r3 contains the address of the bullet.
remove_bullet_:
		push 	{r4,r5}
		mov		r4, r3
		mov		r2, #5
		mov		r3, #10
		mov		r7, r11
		bl		p_rect
		mov		r0, #0
		mov		r5, r9
		str		r0, [r5,r4]
		add		r5, #4
		str		r0, [r5,r4]
		mov		r3, r4
		add		r3, #8
		pop		{r4,r5}
		b		load_bullet
		
//stores row, column and movement data wherever the r3 register points at.
str_obj:
		
		push	{r4}
		mov		r4, r9
		str		r0, [r4,r3]
		add		r4, #4
		str		r1, [r4,r3]
		add		r4, #4
		str		r2,	[r4,r3]
		pop		{r4}
		bx		lr
		
done_mv_:
		pop		{pc}
		
//-------------------------end------------------------------------------------------------

		
//paints type 1 enemy. parameters are r0=row coordinate, r1=column coordinate, r7=color
//the passed coordinates refer to the top right black square of the enemy
//function checks the column coordinates at the beginning and draws an appropriate amount of columns
//this is because the enemies move into the screen from the right side gradually, they dont appear out of nowhere
p_en1:  push	{r0-r6,lr}
//bkpt #3
		mov		r2, #3
		mov		r3, #3
		mov		r4, r0
		mov		r5, #255 //r5=317
		add		r5, #62  //paint all columns
		cmp		r1, r5
		//bkpt #2
		bls		en1_6
		//bkpt #3
		add		r5, #3 //paint five columns, r5=320
		cmp		r1, r5
		beq		en1_5
		add		r5, #3 //paint four columns, r5=323
		mov		r6, r1
		sub		r1, #3
		cmp		r6, r5
		beq		en1_4
		add		r1, #3
		add		r5, #3 //paint three columns, r5=326
		mov		r6, r1
		sub		r1, #6
		cmp		r6, r5
		beq		en1_3
		
en1_6:	bl		p_rect  //sixth column
		add		r0, #6
		bl		p_rect
		add		r0, #6
		bl		p_rect
		mov		r0, r4
		
en1_5:	sub		r0, #3  //fifth column
		sub		r1, #3
		bl		p_rect
		add		r0, #6
		bl		p_rect
		add		r0, #6
		bl		p_rect
		add		r0, #6
		bl		p_rect
		mov		r0, r4
		
en1_4:	sub		r1, #3  //fourth column
		bl		p_rect
		add		r0, #6
		bl		p_rect
		add		r0, #6
		bl		p_rect
		mov		r0, r4
		
en1_3:	sub		r1, #3  //third column
		add		r0, #3
		mov		r2, #9
		mov		r3, #3
		bl		p_rect
		mov		r0, r4
		
en1_2:	sub		r1, #3  //second column
		add		r0, #3
		mov		r2, #9
		mov		r3, #3
		bl		p_rect		
		mov		r0, r4
		
en1_1:	sub		r1, #3  //first column
		add		r0, #6
		mov		r2, #3
		mov		r3, #3
		bl		p_rect
//bkpt #3
		pop		{r0-r6,pc}
//-------------------------end------------------------------------------------------------


//paints type 2 enemy. parameters are r0=row coordinate, r1=column coordinate, r7=color
//the passed coordinates refer to the top right black square of the enemy
//function checks the column coordinates at the beginning and draws an appropriate amount of columns
//this is because the enemies move into the screen from the right side gradually, they dont appear out of nowhere
p_en2:  push	{r0-r5,lr}
		mov		r5, #255 //r5=317
		add		r5, #62  //paint all parts
		cmp		r1, r5
		bls		p_en2_t
		mov		r2, r1
		sub		r1, #12
		add		r5, #9 //paint nose and body
		cmp		r2, r5
		bls		p_en2_b
		sub		r1, #6
		add		r0, #3
		add		r5, #9 //paint nose only
		cmp		r2, r5
		bls		p_en2_n
		
p_en2_t:sub		r1, #3 //paints tail
		mov		r2, #3
		mov		r3, #6
		bl		p_rect
		add		r0, #6
		bl		p_rect
		add		r0, #6
		bl		p_rect
		mov		r3, #3
		sub		r0, #3
		sub		r1, #3
		bl		p_rect
		sub		r0, #6
		bl		p_rect
		
		sub		r0, #3
		sub		r1, #6
p_en2_b:mov		r2, #15 //paints body
		mov		r3, #6
		bl		p_rect
		sub		r1, #3
		mov		r2, #3
		mov		r3, #3
		bl		p_rect
		add		r0, #6
		bl		p_rect
		add		r0, #6
		bl		p_rect
		
		sub		r0, #9
		sub		r1, #3
p_en2_n:mov		r2, #3 //paints nose
		mov		r3, #3
		bl		p_rect
		add		r0, #6
		bl		p_rect
		sub		r0, #3
		sub		r1, #3
		bl		p_rect

		pop		{r0-r5,pc}
		
//-------------------------end------------------------------------------------------------

//as the code size is too big, the constant pool in rom is inaccesible from the beginning of the program,
//thus we branch here to load the constants. 
load_constants:
		ldr		r4, =0x20000000 //ram offset value
		ldr		r5, =0x40010000 //LCD row register
		ldr		r6, =0xFF73A582 //background color
		ldr		r7, =0xFF000000 //black color
		bx		lr
//-------------------------end------------------------------------------------------------

//paints the spaceship. parameters are r0=row coordinate, r1=column coordinate, r7=color
//the passed coordinates refer to the top left corner of the spaceship
p_ship:	push	{r0-r3,lr}
		mov		r2, #5
		mov		r3, #10
		bl		p_rect
		
		add		r0, #5 //second row
		add		r1, #5
		bl		p_rect
		add		r1, #15
		mov		r3, #15
		bl		p_rect
		
		add		r0, #5 //third row
		sub		r1, #10
		mov		r3, #5
		bl		p_rect
		add		r1, #10
		mov		r3, #10
		bl		p_rect
		add		r1, #15
		mov		r3, #5
		bl		p_rect
		
		add		r0, #5 //fourth row
		sub		r1, #30
		bl		p_rect
		add		r1, #10
		mov		r3, #20
		bl		p_rect
		add		r1, #25
		mov		r3, #10
		bl		p_rect
		
		add		r0, #5 //fifth row
		sub		r1, #30
		mov		r3, #5
		bl		p_rect
		add		r1, #10
		mov		r3, #10
		bl		p_rect
		add		r1, #15
		mov		r3, #5
		bl		p_rect
		
		add		r0, #5 //sixth row
		sub		r1, #30
		mov		r3, #10
		bl		p_rect
		add		r1, #15
		mov		r3, #15
		bl		p_rect
		
		add		r0, #5 //seventh row
		sub		r1, #20
		mov		r3, #10
		bl		p_rect
		
		pop		{r0-r3,pc}
//-------------------------end------------------------------------------------------------

//paints a bullet. 5x10 fixed size. r0=row r1=column. top left coordinates
p_bllt: push	{r2,r3,lr}
		mov		r2, #5
		mov		r3, #10
		bl		p_rect
		pop		{r2,r3,pc}
//-------------------------end------------------------------------------------------------
	
//paints a rectangle. parameters are r0=row coordinate, r1=column coordinate, r2=row size, r3=column size
//r10=LCD row register, r7=color
//the passed coordinates refer to the top left corner of the rectangle. 
//returns to the instruction address at link register.
p_rect:	push	{r0-r6}
		mov		r6, r10
begin:	mov		r4, r1
		mov		r5, r3
		cmp 	r2, #0
		beq		paint
		str		r0, [r6] // row
loop1:	
		str		r4, [r6, #4] // column
		str		r7, [r6, #8] // color
		sub		r5, r5, #1
		cmp		r5, #0
		beq		nxt_rw
		add		r4, r4, #1
		b 		loop1
		
nxt_rw: add		r0, r0, #1
		sub		r2, r2, #1
		b 		begin
		
paint:	str		r0, [r6, #12]
		pop		{r0-r6}
		bx		lr	
//-------------------------end------------------------------------------------------------
		
//function which paints the boss figure by using p_rect function
//inputs r0 = row coordinate and r1 = column coordinate (top left point (LCD pixel) of the top right figure pixel)
//uses registers r0-r7
//returns to LR
		
p_boss: push	{r0-r7, lr}
	
		mov 	r4, r0
		mov		r3, #3				//Every column is 3 LCD pixels
		
		mov		r5, #255
		add		r5, #62				//paints all parts
		cmp		r1, r5
		bls		p_boss4
	
		mov		r5, #255			
		add		r5, #80				//paints first 3 parts		
		mov 	r6, r1
		mov		r1, #255
		add		r1, #65
		cmp 	r6, r5
		bls		p_boss3
		
		mov		r5, #255			
		add		r5, #98				//paints first 2 parts			
		cmp 	r6, r5
		bls 	go_p_boss2
		b		cmp_p_boss_1
		
go_p_boss2:
		bl 		p_boss2
		
cmp_p_boss_1:						//paints first part
		mov		r5, #255			
		add		r5, #116	
		cmp 	r6, r5
		bls 	go_p_boss1
		
go_p_boss1:
		bl 		p_boss1
	
p_boss4:							//last part
		add 	r0, #21				//6th column
		mov		r2, #12
		bl		p_rect
		
		sub		r1, #3				//5th column
		add		r0, #3
		mov		r2, #3
		bl 		p_rect
		add		r0, #6
		mov		r2, #6
		bl		p_rect
		
		sub		r1, #3				//4th column
		sub		r0, #3
		mov		r2, #3
		bl		p_rect
		add		r0, #6
		mov		r2, #6
		bl 		p_rect
		
		sub		r1, #3				//3rd column
		sub		r0, #30
		mov		r2, #3
		bl		p_rect
		add 	r0, #21
		mov		r2, #6
		bl		p_rect
		add 	r0, #12
		bl		p_rect
		add		r0, #18
		bl		p_rect
		
		sub		r1, #3				//2nd column
		sub		r0, #51
		bl		p_rect
		add		r0, #15
		bl		p_rect
		add 	r0, #12
		mov		r2, #12
		bl		p_rect
		add		r0, #18
		mov		r2, #6
		bl		p_rect
		add 	r0, #9
		mov		r2, #3
		bl		p_rect
		
		sub		r1, #3				//1st column
		sub		r0, #54
		bl		p_rect
		add		r0, #6
		mov		r2, #12
		bl		p_rect
		add		r0, #21
		mov		r2, #3
		bl		p_rect
		add 	r0, #9
		mov 	r2, #9
		bl 		p_rect
		add		r0, #18
		mov		r2, #3
		bl		p_rect
		mov		r0, r4
		
p_boss3:							//3rd part
		sub 	r1, #3				//6th column
		add 	r0, #3
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #12
		bl 		p_rect
		add 	r0, #6
		bl		p_rect
		add 	r0, #6
		bl		p_rect
		add 	r0, #12
		bl 		p_rect
		add 	r0, #6
		bl		p_rect
		add 	r0, #9
		mov 	r2, #6
		bl 		p_rect
		
		sub 	r1, #3				//5th column
		sub 	r0, #48
		mov		r2, #3
		bl 		p_rect
		add 	r0, #9
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #21
		mov 	r2, #3
		bl 		p_rect
		add  	r0, #9
		mov 	r2, #12
		bl 		p_rect
		
		sub 	r1, #3				//4th column
		sub 	r0, #36
		mov		r2, #6
		bl 		p_rect
		add 	r0, #33
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #9
		bl 		p_rect
		
		sub 	r1, #3				//3rd column
		sub 	r0, #51
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #9
		bl 		p_rect
		add 	r0, #24
		mov 	r2, #6
		bl 		p_rect
		
		sub 	r1, #3				//2nd column
		sub 	r0, #48
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #9
		mov 	r2, #15
		bl 		p_rect
		add 	r0, #24
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #9
		bl 	 	p_rect
		
		sub 	r1, #3				//1st column
		mov 	r0, r4
		bl 		p_rect
		add 	r0, #6
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #9
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #6
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #18
		bl 		p_rect
		add 	r0, #6
		bl 		p_rect
		mov 	r0, r4

p_boss2:							//2nd part
		sub 	r1, #3				//6th column
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #9
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #12
		bl 		p_rect
		add 	r0, #24
		bl 		p_rect
		
		sub 	r1, #3				//5th column
		sub 	r0, #54
		bl 		p_rect
		add 	r0, #6
		bl 		p_rect
		add 	r0, #6
		bl 		p_rect
		add 	r0, #6
		bl 		p_rect
		add 	r0, #6
		mov 	r2, #9
		bl 		p_rect
		add 	r0, #15
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #12
		bl 		p_rect
	
		sub 	r1, #3				//4th column
		sub 	r0, #48
		mov 	r2, #9
		bl 		p_rect
		add 	r0, #18
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #6
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #9
		mov 	r2, #3
		bl 		p_rect
		add 	r0, #6
		bl 		p_rect
		add 	r0, #12
		bl 		p_rect
		
		sub 	r1, #3				//3rd column
		sub 	r0, #48
		bl 		p_rect
		add 	r0, #6
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #9
		bl 		p_rect
		add 	r0, #18
		mov 	r2, #3
		bl 		p_rect
			
		sub 	r1, #3				//2nd column
		sub 	r0, #45
		bl 		p_rect
		add 	r0, #6
		bl 		p_rect
		add 	r0, #21
		bl 		p_rect
		add 	r0, #6
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #3
		bl 		p_rect
	
		sub 	r1, #3				//1st column
		sub 	r0, #45
		mov 	r2, #9
		bl 		p_rect
		add 	r0, #27
		bl 		p_rect
		add 	r0, #15
		mov 	r2, #3
		bl 		p_rect
		mov 	r0, r4
	
p_boss1:							//first part
		sub 	r1, #3				//4th column
		add 	r0, #12
		mov 	r2, #3
		bl		p_rect
		add 	r0, #9
		bl 		p_rect
		add 	r0, #15
		bl 		p_rect
		add 	r0, #12
		bl 		p_rect
		add 	r0, #6
		bl 		p_rect

		sub 	r1, #3				//3rd column
		sub 	r0, #45
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #18
		mov 	r2, #9
		bl 		p_rect
		add 	r0, #15
		mov 	r2, #3
		bl 		p_rect
		
		sub 	r1, #3				//2nd column
		sub 	r0, #45
		bl 		p_rect
		add 	r0, #6
		mov 	r2, #6
		bl 		p_rect
		add 	r0, #12
		mov 	r2, #27
		bl 		p_rect
			
		sub 	r1, #3				//1st column
		sub 	r0, #18
		mov 	r2, #6
		bl 		p_rect
		
		pop		{r0-r7, pc}
		
		
		
		